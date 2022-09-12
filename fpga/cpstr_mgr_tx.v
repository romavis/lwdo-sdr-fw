module cpstr_mgr_tx #(
    parameter NUM_STREAMS = 2,
    parameter MAX_BURST = 127
) (
    // syscon
    input i_clk,
    input i_rst,
    // input streams
    input [8*NUM_STREAMS-1:0] i_data,
    input [NUM_STREAMS-1:0] i_valid,
    output [NUM_STREAMS-1:0] o_ready,
    // output (multiplexed) stream
    output [7:0] o_data,
    output o_valid,
    input i_ready,
    // request to send stream index
    input i_send_stridx
);

    integer ii;

    wire clk, rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // States
    wire mux_ack = mux_valid && mux_ready;
    wire other_avail = |(i_valid & ~grant);

    // Arbiter driver state machine
    // To reduce critical path length, arbitration and submission of selected
    // stream index is governed by a state machine, not by arbiter itself.
    localparam ST_REQ_ARBITRATION = 2'd0;
    localparam ST_SEND_STREAM_IDX = 2'd1;
    localparam ST_ROUTE = 2'd2;

    reg [1:0] state;
    reg [1:0] state_next;

    always @(posedge clk or posedge rst)
        if (rst) state <= ST_REQ_ARBITRATION;
        else state <= state_next;

    always @(*) begin
        state_next = state;
        case(state)
        ST_REQ_ARBITRATION:
            if (arb_grant)
                state_next = ST_SEND_STREAM_IDX;
        ST_SEND_STREAM_IDX:
            if (stridx_ready)
                state_next = ST_ROUTE;
        ST_ROUTE:
            if (other_avail &&
                (!mux_valid || (!burst_rem && mux_ack)))
                state_next = ST_REQ_ARBITRATION;
            else if (i_send_stridx)
                state_next = ST_SEND_STREAM_IDX;
        endcase
    end

    // selected stream
    reg [NUM_STREAMS-1:0] grant;
    reg [$clog2(NUM_STREAMS)-1:0] grant_idx;

    always @(posedge clk or posedge rst)
        if (rst) begin
            grant <= 0;
            grant_idx <= 0;
        end
        else
        if (state == ST_REQ_ARBITRATION &&
                state_next == ST_SEND_STREAM_IDX) begin
            grant <= arb_grant;
            grant_idx <= arb_grant_idx;
        end

    // multiplexed stream
    reg [7:0] mux_data;
    wire mux_valid = (state == ST_ROUTE) && |(i_valid & grant);
    wire mux_ready;

    always @(*) begin
        mux_data = 8'd0;
        for (ii = 0; ii < NUM_STREAMS; ii=ii+1)
            if (grant[ii])
                mux_data = mux_data | i_data[8*ii +: 8];
    end

    // upstream ready - same gating logic as for mux_valid
    assign o_ready = grant & {NUM_STREAMS{(state == ST_ROUTE) && mux_ready}};

    // burst byte counter
    reg [$clog2(MAX_BURST)-1:0] burst_rem;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            burst_rem <= MAX_BURST - 1;
        end else begin
            if (state != ST_ROUTE)
                burst_rem <= MAX_BURST - 1;
            else if (burst_rem && mux_ack)
                // decrement for each byte transmitted over 'muxed' stream
                burst_rem <= burst_rem - 1'd1;
        end
    end

    // masking (used to terminate burst)
    reg [NUM_STREAMS-1:0] burst_mask;

    always @(posedge clk or posedge rst)
        if (rst)
            burst_mask <= 0;
        else if (state != ST_ROUTE)
            burst_mask <= 0;
        else
            burst_mask <= grant;

    // arbiter module (from verilog-wishbone)
    wire [NUM_STREAMS-1:0] arb_req;
    wire [NUM_STREAMS-1:0] arb_grant;
    wire [$clog2(NUM_STREAMS)-1:0] arb_grant_idx;

    assign arb_req = i_valid & ~burst_mask;

    rr_arbiter #(
        .NUM_PORTS(NUM_STREAMS)
    ) arbiter (
        .clk(i_clk),
        .rst(i_rst),
        //
        .request(arb_req),
        .grant(arb_grant),
        .select(arb_grant_idx)
    );

    // stream index sender
    wire [7:0] stridx_val = grant_idx;
    wire stridx_valid = (state == ST_SEND_STREAM_IDX);
    wire stridx_ready;

    // stream escaper
    // via 'esc' mechanism it sends stream idx that was selected by arbiter
    cpstr_esc cpstr_esc (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_data(mux_data),
        .i_valid(mux_valid),
        .o_ready(mux_ready),
        //
        .o_data(o_data),
        .o_valid(o_valid),
        .i_ready(i_ready),
        //
        .i_esc_data(stridx_val),
        .i_esc_valid(stridx_valid),
        .o_esc_ready(stridx_ready)
    );

endmodule
