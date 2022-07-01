
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_cmd_tx;

    `include "cmd_defines.vh"
    `include "mreq_defines.vh"

    reg clk = 0;
    reg rst = 0;

    reg mreq_valid = 0;
    wire mreq_ready;
    //
    reg [7:0] mreq_tag = 0;
    reg mreq_wr = 0;
    reg mreq_aincr = 0;
    reg [2:0] mreq_wfmt = 0;
    reg [7:0] mreq_wcnt = 0;
    reg [23:0] mreq_addr = 0;
    //
    wire [7:0] tx_data;
    wire tx_valid;
    reg tx_ready = 1;

    cmd_tx dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_tx_data(tx_data),
        .o_tx_valid(tx_valid),
        .i_tx_ready(tx_ready),
        //
        .i_mreq_valid(mreq_valid),
        .o_mreq_ready(mreq_ready),
        .i_mreq(pack_mreq(mreq_tag, mreq_wr, mreq_aincr, mreq_wfmt, mreq_wcnt, mreq_addr))
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (tx_valid && tx_ready) begin
            $display("Tx: %02x", tx_data);
        end
    end

    initial begin
        $dumpfile("test_cmd_tx.vcd");
        $dumpvars(0);

        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (1) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);

        mreq_tag <= 8'hAB;
        mreq_wr <= 1;
        mreq_aincr <= 1;
        mreq_wfmt <= MREQ_WFMT_16S1;
        mreq_wcnt <= 8'hEC;
        mreq_addr <= 23'h123456;

        // STROBE
        mreq_valid <= 1;
        @(posedge clk); wait(mreq_ready) @(posedge clk);
        mreq_valid <= 0;

        mreq_tag <= 8'h33;
        mreq_wr <= 0;
        mreq_aincr <= 1;
        mreq_wfmt <= MREQ_WFMT_32S0;
        mreq_wcnt <= 8'h76;
        mreq_addr <= 23'hAABBCC;

        // STROBE
        mreq_valid <= 1;
        repeat (2) @(posedge clk);
        tx_ready <= 0;
        repeat (10) @(posedge clk);
        tx_ready <= 1;

        @(posedge clk); wait(mreq_ready) @(posedge clk);
        mreq_valid <= 0;

        tx_ready <= 0;
        // Strobe
        mreq_valid <= 1;
        repeat (12) @(posedge clk);
        tx_ready <= 1;
        @(posedge clk); wait(mreq_ready) @(posedge clk);
        mreq_valid <= 0;

        repeat (10) @(posedge clk);

        $finish;
    end

endmodule
