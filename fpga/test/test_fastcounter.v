`timescale 1 ns/100 ps  // time-unit = 1 ns, precision = 10 ps

module test_fastcounter;

    localparam NBITS = 9;
    localparam NBITS_STAGE = 4;

    reg clk = 0;
    reg rst = 0;
    reg [1:0] mode = 0;
    reg dir = 0;
    reg en = 0;
    reg load = 0;
    reg [NBITS-1:0] load_q = 0;
    wire pend, nend, carry, carry_dly, epulse;
    wire [NBITS-1:0] q;
    reg en_gated = 0;

    always @(posedge clk) begin
        en_gated <= en_gated ? 1'b0 : en;
    end

    fastcounter #(
        .NBITS(NBITS),
        .NBITS_STAGE(NBITS_STAGE)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_mode(mode),
        .i_dir(dir),
        .i_en(en_gated),
        .i_load(load),
        .i_load_q(load_q),
        //
        .o_end(pend),
        .o_nend(nend),
        .o_carry(carry),
        .o_carry_dly(carry_dly),
        .o_epulse(epulse),
        //
        .o_q(q)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test_fastcounter.vcd");
        $dumpvars;

        // Reset
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        //
        // OVERFLOW
        //

        mode <= 2;
        // Load
        load_q <= 'h33;
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Idle
        repeat(15) @(posedge clk);
        // Enable
        en <= 1;
        // Count
        repeat(600) @(posedge clk);
        // Change direction
        dir <= 1;
        // Count
        repeat(600) @(posedge clk);
        // Change direction
        dir <= 0;
        // Count
        repeat(600) @(posedge clk);

        //
        // AUTORELOAD
        //

        mode <= 0;

        // Load
        load_q <= 'h33;
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Idle
        repeat(15) @(posedge clk);
        // Enable
        en <= 1;
        // Count
        repeat(150) @(posedge clk);
        // Set reload to 1
        load_q <= 1;
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Count
        repeat(10) @(posedge clk);
        // Set reload to 0
        load_q <= 0;
        // Count
        repeat(10) @(posedge clk);


        //
        // ONESHOT
        //

        mode <= 1;
        en <= 0;

        // Load
        load_q <= 'h3F;
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Idle
        repeat(15) @(posedge clk);
        // Enable
        en <= 1;
        // Count
        repeat(150) @(posedge clk);

        // Set reload to 5
        load_q <= 5;
        // Trigger
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Wait
        repeat(20) @(posedge clk);
        // Trigger
        load <= 1;
        repeat(10) @(posedge clk);
        load <= 0;
        // Wait
        repeat(20) @(posedge clk);

        // Set reload to 1
        load_q <= 1;
        // Trigger
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Wait
        repeat(20) @(posedge clk);
        // Trigger
        load <= 1;
        repeat(10) @(posedge clk);
        load <= 0;
        // Wait
        repeat(20) @(posedge clk);

        // Set reload to 0
        load_q <= 0;
        // Trigger
        load <= 1;
        @(posedge clk);
        load <= 0;
        // Wait
        repeat(20) @(posedge clk);
        // Trigger
        load <= 1;
        repeat(10) @(posedge clk);
        load <= 0;
        // Wait
        repeat(20) @(posedge clk);

        $finish;
    end
endmodule
