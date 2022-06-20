`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_dac8551;

    reg clk = 0;
    reg rst = 0;
    reg wr = 0;
    reg [23:0] wr_data = 0;
    wire dac_sclk, dac_mosi, dac_sync_n, busy;

    dac8551 #(
        .CLK_DIV(2)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_wr(wr),
        .i_wr_data(wr_data),
        .o_dac_sclk(dac_sclk),
        .o_dac_mosi(dac_mosi),
        .o_dac_sync_n(dac_sync_n),
        .o_busy(busy)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test_dac8551.vcd");
        $dumpvars;

        // Reset
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        // Idle
        repeat(5) @(posedge clk);
        // Send data
        wr_data <= 24'h876543;
        wr <= 1;
        @(posedge clk);
        wr <= 0;
        repeat(147) @(posedge clk);
        // Send data back to back
        wr_data <= 24'h777777;
        wr <= 1;
        @(posedge clk);
        wr <= 0;
        repeat(20) @(posedge clk);
        wr_data <= 24'hCCCCCC;
        wr <= 1;
        @(posedge clk);
        wr <= 0;
        repeat(20) @(posedge clk);
        wr_data <= 24'h666666;
        wr <= 1;
        @(posedge clk);
        wr <= 0;
        repeat(300) @(posedge clk);

        $finish;
    end
endmodule