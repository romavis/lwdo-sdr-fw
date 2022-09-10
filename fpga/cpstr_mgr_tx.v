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

    // burst termination signal
    wire terminate_burst;
    assign terminate_burst = !burst_rem && mux_valid && mux_ready;

    // arbiter module (from verilog-wishbone)
    wire [NUM_STREAMS-1:0] req_others;
    wire [NUM_STREAMS-1:0] req;
    wire [NUM_STREAMS-1:0] grant;
    wire [NUM_STREAMS-1:0] grant_ack;
    wire [$clog2(NUM_STREAMS)-1:0] grant_idx;

    assign req_others = i_valid & ~grant;
    // normally request follows `i_valid`, but if burst counter signals end
    // of the burst, it switches to `req_others` to make arbiter switch
    assign req = terminate_burst ? req_others : i_valid;

    /*
     * Some notes:
     *  grant[i]==1 means stream `i` is selected
     *  grant is one-hot, only a single bit can be 1
     *  grant_idx is equal to `i` or `0` if grant==0
     * With ARB_BLOCK=1, ARB_BLOCK_ACK=0 arbiter arbitrates whenever request
     * is _de-asserted_. That's how we trigger arbitration when burst counter
     * signals end of burst.
     */
    arbiter #(
        .PORTS(NUM_STREAMS),
        .ARB_BLOCK(1),
        .ARB_BLOCK_ACK(0),
        .ARB_TYPE_ROUND_ROBIN(1)
    ) arbiter (
        .clk(i_clk),
        .rst(i_rst),
        //
        .request(req),
        .grant(grant),
        .grant_encoded(grant_idx)
    );

    // multiplexed stream
    // valid and ready are gated by stridx_confirmed, so that mux stream
    // becomes active only when stridx has been confirmed
    reg [7:0] mux_data;
    wire mux_valid;
    wire mux_ready;

    assign mux_valid = stridx_confirmed && |(i_valid & grant);

    always @(*) begin
        mux_data = 8'd0;
        for (ii = 0; ii < NUM_STREAMS; ii=ii+1)
            if (grant[ii])
                mux_data = mux_data | i_data[8*ii +: 8];
    end

    // upstream ready - same gating logic as for mux_valid
    assign o_ready = grant &
                    {NUM_STREAMS{mux_ready && stridx_confirmed}};

    // burst byte counter
    reg [$clog2(MAX_BURST)-1:0] burst_rem;

    always @(posedge clk or posedge rst) begin
        if (rst || !req_others || terminate_burst)
            // initialize counter to MAX_BURST on reset or when there are no
            // competing streams (thus no burst limitation if only one stream
            // wants to transmit data)
            burst_rem <= MAX_BURST - 1;
        else if (mux_valid && mux_ready)
            // decrement for each byte transmitted over 'muxed' stream
            burst_rem <= burst_rem - 1'd1;
    end

    // Stream idx confirmation state machine
    // When arbiter selects a new stream, we use cpstr_esc's 'esc' mechanism
    // to send {ESC_CHAR, grant_idx} to the host. While that pair of bytes is
    // in process of being sent, incoming streams are blocked.
    // This machine reacts to any change in grant_idx on arbiter's output.
    wire [7:0] stridx_grant;    // index selected by arbiter
    reg [7:0] stridx_cfrm;      // confirmed index
    reg [7:0] stridx_send;      // index to send
    reg stridx_send_valid;
    wire stridx_send_ready;

    assign stridx_grant = grant_idx;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stridx_cfrm <= 8'd0;
            stridx_send <= 8'd0;
            stridx_send_valid <= 1'b1;
        end else begin
            if (stridx_send_valid) begin
                if (stridx_send_ready) begin
                    // record confirmed index, clr valid for at least 1 cycle
                    stridx_cfrm <= stridx_send;
                    stridx_send_valid <= 1'b0;
                end
            end else begin
                if ((!stridx_confirmed && grant) || i_send_stridx) begin
                    // send stridx to the host
                    stridx_send <= stridx_grant;
                    stridx_send_valid <= 1'b1;
                end
            end
        end
    end

    // when stridx is not confirmed, mux stream should be gated so that no
    // data passes till the correct stridx is sent to host
    wire stridx_confirmed;
    assign stridx_confirmed = (stridx_grant == stridx_cfrm) &&
                              !stridx_send_valid;

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
        .i_esc_data(stridx_send),
        .i_esc_valid(stridx_send_valid),
        .o_esc_ready(stridx_send_ready)
    );

endmodule
