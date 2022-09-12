/****************************************************************************

                        ---- wbcon_tx ----

Module that transmits responses to commands parsed by wbcon_rx and executed
by wbcon_tx.

Technically it spies on MREQ communication between wbcon_rx and wbcon_exec
and depending on what happens there transmits different things.

Module also handles Tx data stream from wbcon_exec that contains data from
read transactions, transmitting those data bytes at correct positions within
response parcel.

Response parcel format:

  +----+---------+--------+
  | OP | BODY... | STATUS |
  +----+---------+--------+

OP is:
  0xB1 - response to read / write command

BODY
  Contains data bytes generated by wbcon_exec.
  For read transactions, that will be 4*(COUNT+1) bytes, representing
  complete little-endian 32-bit words read from the Wishbone bus.
  Write transactions do not generate BODY bytes.

STATUS
  0xFE - transaction completed successfully

****************************************************************************/

module wbcon_tx (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Output byte stream
    output [7:0] o_tx_data,
    output o_tx_valid,
    input i_tx_ready,
    // Packet body stream
    input [7:0] i_body_data,
    input i_body_valid,
    output o_body_ready,
    // MREQ handshake to wbcon_rx
    input i_mreq_valid,
    output o_mreq_ready,
    // MREQ handshake to wbcon_exec
    output o_mreq_valid,
    input i_mreq_ready
);

    // SysCon
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // Tx stream success flag
    wire tx_ack;
    assign tx_ack = i_tx_ready && o_tx_valid;

    // State machine
    reg [1:0] state;
    reg [1:0] state_next;
    wire state_change;
    assign state_change = (state != state_next) ? 1'b1 : 1'b0;

    localparam ST_IDLE = 2'd0;
    localparam ST_SEND_START = 2'd1;
    localparam ST_SEND_BODY = 2'd2;
    localparam ST_SEND_STATUS = 2'd3;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= ST_IDLE;
        else
            state <= state_next;
    end

    always @(*) begin
        state_next = state;

        case (state)
        ST_IDLE:
            if (i_mreq_valid) state_next = ST_SEND_START;
        ST_SEND_START:
            if (tx_ack) begin
                if (mreq_wait || (o_mreq_valid && i_mreq_ready))
                    state_next = ST_SEND_STATUS;
                else
                    state_next = ST_SEND_BODY;
            end
        ST_SEND_BODY:
            if (mreq_wait || (o_mreq_valid && i_mreq_ready))
                state_next = ST_SEND_STATUS;
        ST_SEND_STATUS:
            if (tx_ack) state_next = ST_IDLE;
        endcase
    end

    // MREQ handshake logic

    // pass i_mreq_valid to o_mreq_valid, i_mreq_ready to o_mreq_ready
    // except when mreq has been acknowledged already and it has to wait
    // till we finish sending all our bytes
    assign o_mreq_valid = i_mreq_valid && !mreq_wait;
    assign o_mreq_ready = i_mreq_ready && !mreq_wait;

    // MREQ wait logic
    // Once MREQ has been acknowledged, we block further MREQs till we
    // finish sending all the bytes of this one
    reg mreq_wait;

    always @(posedge clk or posedge rst) begin
        if (rst)
            mreq_wait <= 1'b0;
        else begin
            if (state_change && state_next == ST_IDLE)
                mreq_wait <= 1'b0;
            else if (o_mreq_valid && i_mreq_ready)
                mreq_wait <= 1'b1;
        end
    end

    // Tx & body streams
    reg [7:0] tx_data;
    reg tx_valid;
    reg body_ready;

    assign o_tx_data = tx_data;
    assign o_tx_valid = tx_valid;
    assign o_body_ready = body_ready;

    always @(*) begin
        tx_data = 0;
        tx_valid = 0;
        body_ready = 0;

        case (state)
        ST_SEND_START: begin
            tx_data = 8'hB1;
            tx_valid = 1'b1;
        end
        ST_SEND_BODY: begin
            tx_data = i_body_data;
            tx_valid = i_body_valid;
            body_ready = i_tx_ready;
        end
        ST_SEND_STATUS: begin
            tx_data = 8'hFE;
            tx_valid = 1'b1;
        end
        endcase
    end

endmodule