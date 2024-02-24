/****************************************************************************

                        ---- slip_axis_encoder ----

Takes an input AXI-S symbol stream and encodes it as a SLIP-encoded symbol
stream.

Following signals from incoming stream are encoded in the outgoing stream:
- TLAST
- TID

Following signals are not supported:
- TSTRB
- TKEEP - very limited support (see below)
- TDEST
- TUSER

== Format of outgoing data ==

Outgoing data is a stream of packets encoded in the spirit of SLIP protocol.
The end of the packet is signaled by the SLIP END token. After the END token,
the new packet begins. Everything that is not an END token is considered to
be part of packet body. A packet body consists of two parts:
1. ID: a single symbol that contains value of TID for the data that
    follows.
2. Data: multiple symbols that convey TDATA values that were transmitted over
    AXI-S with the same TID.

Both parts are transmitted SLIP-escaped, so that if some data symbol matches
the value of the END token, it is escaped. As a result, END token can be
observed only on boundaries of the packets.

== TID handling ==

Whenever AXI-S channel contains interleaved packets, so that TID changes in
the middle of the packet, without synchronizing TID change to TLAST=1, this
module treats such TID changes as TLAST=1. Thus:
- if transfer N had TLAST=0 and TID=x,
- while the next transfer N+1 has TID!=x,
- the module will behave as though transfer N had TLAST=1

This means that if the incoming AXI-S channel uses interleaved packets, it
won't be possible to restore their boundaries from the stream output by this
module.

== TLAST / TKEEP handling ==

- If a transfer has TKEEP=1, TLAST=0, TDATA is escaped and emitted as-is.
- If a transfer has TKEEP=0, TLAST=0, the transfer is acknowledged and no
    symbols are emitted, except if TID change was detected – then it is
    treated as TKEEP=0, TLAST=1.
- If a transfer has TKEEP=1, TLAST=1, TDATA is escaped and emitted as-is,
    and end-of-packet is signaled.
- If a trnasfer has TKEEP=0, TLAST=1, an end-of-packet is signaled.

== End-of-packet signaling ==

Whenever end-of-packet is signaled, SLIP END token is emitted. For the
first incoming AXI-S transfer that is acknowledged after signaling the
end-of-packet, the transfer's TID is emitted, followed by TDATA (if TKEEP
was set). The module can emit 
next AXI-S transfer that 

****************************************************************************/

module slip_axis_encoder #(
    parameter SYMBOL_WIDTH = 32'd8,
    //
    parameter SYMBOL_END = 8'hC0,
    parameter SYMBOL_ESC = 8'hDB,
    parameter SYMBOL_ESC_END = 8'hDC,
    parameter SYMBOL_ESC_ESC = 8'hDD,
) (
    input i_clk,
    input i_rst,
    // Input AXI stream
    input i_s_axis_tvalid,
    output o_s_axis_tready,
    input [SYMBOL_WIDTH-1:0] i_s_axis_tdata,
    input i_s_axis_tkeep,
    input i_s_axis_tlast,
    input [SYMBOL_WIDTH-1:0] i_s_axis_tid,
    // Output SLIP-encoded AXI stream
    output o_m_axis_tvalid,
    input i_m_axis_tready,
    output [SYMBOL_WIDTH-1:0] o_m_axis_tdata
);

    // FSM
    localparam STATE_PASSTHRU = 2'd0;
    localparam STATE_EMIT_END = 2'd1;
    localparam STATE_EMIT_ID = 2'd2;

    reg [1:0] state;
    reg [1:0] state_next;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= STATE_EMIT_END;
        end else begin
            state <= state_next;
        end
    end

    // Remember last emitted ID
    reg [SYMBOL_WIDTH-1:0] cur_id;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cur_id <= {SYMBOL_WIDTH{1'b1}};
        end else begin
            if (state == STATE_EMIT_ID && state_next != state) begin
                // remember TID
                cur_id <= i_s_axis_tid;
            end
        end
    end

    wire esc_ready;
    reg [SYMBOL_WIDTH-1:0] esc_data;
    reg esc_end;
    reg esc_valid;
    reg s_axis_tready;

    // ACKs
    wire esc_ack;
    assign esc_ack = esc_valid && esc_ready;

    always @(*) begin
        state_next = state;
        esc_data = {SYMBOL_WIDTH{1'b0}};
        esc_end = 1'b0;
        esc_valid = 1'b0;
        s_axis_tready = 1'b0;

        case (state)
            STATE_PASSTHRU: begin
                if (i_s_axis_tvalid) begin
                    if (i_s_axis_tid == cur_id) begin
                        // Same TID
                        if (i_s_axis_tkeep) begin
                            // TKEEP=1 ? ACK, emit TDATA, emit END/ID if TLAST=1
                            esc_data = i_s_axis_tdata;
                            esc_valid = 1'b1;
                            s_axis_tready = esc_ready;
                            if (i_s_axis_tlast && esc_ack) begin
                                state_next = STATE_EMIT_END;
                            end
                        end else begin
                            if (i_s_axis_tlast) begin
                                // TKEEP=0, TLAST==1 ? ACK, emit END, emit ID
                                esc_end = 1'b1;
                                esc_valid = 1'b1;
                                s_axis_tready = esc_ready;
                                if (esc_ack) begin
                                    state_next = STATE_EMIT_ID;
                                end
                            end else begin
                                // TKEEP=0, TLAST=0 -> ACK (discard transfer)
                                s_axis_tready = 1'b1;
                            end
                        end
                    end else begin
                        // TID change ? don't ACK, emit END, emit ID
                        // NOTE: this won't happen if we encounter TLAST in the
                        // previous transfer, since then we will already have
                        // up-to-date cur_id value.
                        esc_end = 1'b1;
                        esc_valid = 1'b1;

                        if (esc_ack) begin
                            state_next = STATE_EMIT_ID;
                        end
                    end
                end
            end

            STATE_EMIT_END: begin
                // don't ACK, emit END irrespective of input TVALID
                esc_end = 1'b1;
                esc_valid = 1'b1;

                if (esc_ack) begin
                    state_next = STATE_EMIT_ID;
                end
            end

            STATE_EMIT_ID: begin
                // don't ACK, emit ID
                if (i_s_axis_tvalid) begin
                    esc_data = i_s_axis_tid;
                    esc_valid = 1'b1;

                    if (esc_ack) begin
                        state_next = STATE_PASSTHRU;
                    end
                end
            end
        endcase
    end

    slip_escaper #(
        .SYMBOL_WIDTH(SYMBOL_WIDTH),
        .SYMBOL_END(SYMBOL_END),
        .SYMBOL_ESC(SYMBOL_ESC),
        .SYMBOL_ESC_END(SYMBOL_ESC_END),
        .SYMBOL_ESC_ESC(SYMBOL_ESC_ESC)
    ) u_escaper (
        .i_clk(i_clk),
        .i_rst(i_rst),
        //
        .i_data(esc_data),
        .i_end(esc_end),
        .i_valid(esc_valid),
        .o_ready(esc_ready),
        //
        .o_data(o_m_axis_tdata),
        .o_valid(o_m_axis_tvalid),
        .i_ready(i_m_axis_tready)
    );

    assign o_s_axis_tready = s_axis_tready;

endmodule
