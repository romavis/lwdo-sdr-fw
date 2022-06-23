`timescale 1 ns/100 ps  // time-unit = 1 ns, precision = 10 ps

module test_fastclkdiv;

    localparam NBITS = 9;
    localparam NBITS_STAGE = 4;

    reg clk = 0;
    reg en = 0;
    reg load = 0;
    reg [NBITS-1:0] load_q = 0;
    reg auto_reload = 0;
    wire [NBITS-1:0] q;
    wire zero;

    fastclkdiv #(
        .NBITS(NBITS),
        .NBITS_STAGE(NBITS_STAGE)
    ) dut (
        .i_clk(clk),
        .i_en(en),
        .i_load(load || (zero && auto_reload)),
        .i_load_q(load_q),
        .o_q(q),
        .o_zero(zero)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test_fastclkdiv.vcd");
        $dumpvars;

        // Load
        load_q <= 100;
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Idle
        repeat(15) @(posedge clk);
        // Enable
        en <= 1;
        // Count
        repeat(150) @(posedge clk);
        // Enable auto reload
        auto_reload <= 1;
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Count
        repeat(150) @(posedge clk);
        // Set reload to 1
        load_q <= 1;
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Count
        repeat(30) @(posedge clk);
        // Set reload to 0
        load_q <= 0;
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Count
        repeat(30) @(posedge clk);

        $finish;
    end
endmodule