
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_phase_det;

    localparam TIC_BITS = 9;

    reg clk = 0;
    reg eclk1 = 0;
    reg eclk2 = 0;
    reg rst = 0;
    //
    reg en = 0;
    reg eclk2_slow = 0;
    //
    wire [TIC_BITS-1:0] count;
    wire count_rdy;

    phase_det #(
        .TIC_BITS(TIC_BITS),
        .DIV_N1(100),
        .DIV_N2(100)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_en(en),
        .i_eclk2_slow(eclk2_slow),
        //
        .o_count(count),
        .o_count_rdy(count_rdy),
        //
        .i_eclk1(eclk1),
        .i_eclk2(eclk2)
    );

    // Clock gen
    always #2 clk = ~clk;
    always #11 eclk1 = ~eclk1;
    always #10 eclk2 = ~eclk2;

    always @(posedge clk) begin
        if (count_rdy) begin
            $display("Measured: %d", count);
        end
    end

    initial begin
        $dumpfile("test_phase_det.vcd");
        $dumpvars(0);

        repeat (1) @(posedge clk);
        rst <= 1;
        repeat (1) @(posedge clk);
        rst <= 0;
        //
        repeat (5) @(posedge clk);
        en <= 1;
        // Let it run
        repeat (10000) @(posedge eclk1);
        // Switch to slow clock mode
        eclk2_slow <= 1;
        // Let it run
        repeat (10000) @(posedge eclk1);

        repeat (5) @(posedge clk);
        $finish;
    end

endmodule
