
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_wbcon_tx;

    reg clk = 0;
    reg rst = 0;

    reg mreq_valid = 0;
    wire mreq_ready;
    wire exec_mreq_valid;
    wire exec_mreq_ready;
    reg exec_mreq_done = 0;
    //
    wire [7:0] tx_data;
    wire tx_valid;
    reg tx_ready = 1;
    //
    reg [7:0] body_data = 8'hAA;
    reg body_valid = 1;
    wire body_ready;

    wbcon_tx dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_tx_data(tx_data),
        .o_tx_valid(tx_valid),
        .i_tx_ready(tx_ready),
        //
        .i_body_data(body_data),
        .i_body_valid(body_valid),
        .o_body_ready(body_ready),
        //
        .i_mreq_valid(mreq_valid),
        .o_mreq_ready(mreq_ready),
        //
        .o_mreq_valid(exec_mreq_valid),
        .i_mreq_ready(exec_mreq_ready)
    );

    assign exec_mreq_ready = exec_mreq_valid & exec_mreq_done;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (tx_valid && tx_ready)
            $display("TX:       %02x", tx_data);
        if (mreq_valid && mreq_ready)
            $display(">>> MREQ UP ACK");
        if (exec_mreq_valid && exec_mreq_ready)
            $display(">>> MREQ DOWN ACK");
        if (body_valid && body_ready)
            $display("BODY:             %02x", body_data);
    end

    initial begin
        $dumpfile("test_wbcon_tx.vcd");
        $dumpvars(0);

        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (1) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);

        // Long confirmation
        mreq_valid <= 1;
        repeat (5) @(posedge clk);
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        mreq_valid <= 0;

        repeat (10) @(posedge clk);

        // Immediate confirmation
        mreq_valid <= 1;
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        mreq_valid <= 0;

        repeat (10) @(posedge clk);

        // Short confirmation 1
        mreq_valid <= 1;
        repeat (1) @(posedge clk);
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        mreq_valid <= 0;

        repeat (10) @(posedge clk);

        // Short confirmation 2
        mreq_valid <= 1;
        repeat (2) @(posedge clk);
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        mreq_valid <= 0;

        repeat (10) @(posedge clk);

        // Short confirmation 3
        mreq_valid <= 1;
        repeat (3) @(posedge clk);
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        mreq_valid <= 0;

        repeat (10) @(posedge clk);

        // Immediate restart with immediate confirmation (x2)
        mreq_valid <= 1;
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        mreq_valid <= 0;

        repeat (10) @(posedge clk);

        // Immediate restart with short confirmation (x2)
        mreq_valid <= 1;
        //
        @(posedge clk); while(!exec_mreq_valid) @(posedge clk);
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        //
        @(posedge clk); while(!exec_mreq_valid) @(posedge clk);
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        //
        @(posedge clk); while(!exec_mreq_valid) @(posedge clk);
        exec_mreq_done <= 1;
        @(posedge clk); while(!mreq_ready) @(posedge clk);
        exec_mreq_done <= 0;
        //
        mreq_valid <= 0;

        repeat (10) @(posedge clk);
        $finish;
    end

endmodule
