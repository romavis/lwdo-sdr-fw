
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module stream_gen (
    input i_clk,
    input i_enable,

    input i_ready,
    output [7:0] o_data,
    output o_valid
);

    reg [9:0] test_vector_idx = 0;
    reg [7:0] test_vector [0:1023];

    integer i;
    initial begin
        i = 0;
        // Zero bytes
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        // Garbage
        test_vector[i++] = 8'h23;
        test_vector[i++] = 8'hFE;
        test_vector[i++] = 8'h01;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'hFA;
        test_vector[i++] = 8'h77;
        // Command 1
        test_vector[i++] = 8'hA1;   // CMD
        test_vector[i++] = 8'hAA;   // CNT
        test_vector[i++] = 8'hBB;   // CNT
        test_vector[i++] = 8'hCC;   // ADDR
        test_vector[i++] = 8'hDD;   // ADDR
        test_vector[i++] = 8'h80;   // DATA
        test_vector[i++] = 8'h90;   // DATA
        // Command 2
        test_vector[i++] = 8'hA2;   // CMD
        test_vector[i++] = 8'hAA;   // CNT
        test_vector[i++] = 8'hBB;   // CNT
        test_vector[i++] = 8'hCC;   // ADDR
        test_vector[i++] = 8'hDD;   // ADDR
        // Command 3
        test_vector[i++] = 8'hA3;   // CMD
        test_vector[i++] = 8'hAA;   // CNT
        test_vector[i++] = 8'hBB;   // CNT
        test_vector[i++] = 8'hCC;   // ADDR
        test_vector[i++] = 8'hDD;   // ADDR
        test_vector[i++] = 8'h80;   // DATA
        test_vector[i++] = 8'h90;   // DATA
        // Command 4
        test_vector[i++] = 8'hA4;   // CMD
        test_vector[i++] = 8'hAA;   // CNT
        test_vector[i++] = 8'hBB;   // CNT
        test_vector[i++] = 8'hCC;   // ADDR
        test_vector[i++] = 8'hDD;   // ADDR
        // Garbage
        test_vector[i++] = 8'h23;
        test_vector[i++] = 8'hFE;
        test_vector[i++] = 8'h01;
        //
        for (i = i; i < 1024; i = i + 1) begin
            test_vector[i] = 8'b0;
        end
    end

    assign o_valid = i_enable;
    assign o_data = test_vector[test_vector_idx];

    always @(posedge i_clk) begin
        if (o_valid && i_ready) begin
            // Transaction happens, increment idx
            test_vector_idx <= test_vector_idx + 10'd1;
        end
    end

endmodule

module test_wbcon_rx;
    reg clk = 0;
    reg rst = 0;
    reg en = 0;

    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_ready;

    wire [7:0] body_data;
    wire body_valid;
    reg body_ready = 0;

    wire mreq_valid;
    reg mreq_ready = 0;
    wire [9:0] mreq_cnt;
    wire [11:0] mreq_addr;
    wire mreq_wr;
    wire mreq_aincr;

    stream_gen gen (
        .i_clk(clk),
        .i_enable(en),
        .i_ready(rx_ready),
        .o_data(rx_data),
        .o_valid(rx_valid)
    );

    wbcon_rx #(
        .ADDR_WIDTH(12),
        .COUNT_WIDTH(10)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_rx_data(rx_data),
        .i_rx_valid(rx_valid),
        .o_rx_ready(rx_ready),
        //
        .o_body_data(body_data),
        .o_body_valid(body_valid),
        .i_body_ready(body_ready),
        //
        .o_mreq_valid(mreq_valid),
        .i_mreq_ready(mreq_ready),
        .o_mreq_addr(mreq_addr),
        .o_mreq_cnt(mreq_cnt),
        .o_mreq_wr(mreq_wr),
        .o_mreq_aincr(mreq_aincr)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rx_valid && rx_ready)
            $display("RX:       %02x", rx_data);
        if (mreq_valid && mreq_ready)
            $display("MREQ: addr=%x cnt=%x wr=%d aincr=%d",
                mreq_addr, mreq_cnt, mreq_wr, mreq_aincr);
        if (body_valid && body_ready)
            $display("BODY:             %02x", body_data);
    end

    initial begin
        $dumpfile("test_wbcon_rx.vcd");
        $dumpvars;

        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (1) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);
        en <= 1;
        // Wait, receive data, ack
        while(!mreq_valid) @(posedge clk);
        if (mreq_wr) begin
            body_ready <= 1;
            repeat(2) @(posedge clk);
            body_ready <= 0;
        end
        mreq_ready <= 1; @(posedge clk); mreq_ready <= 0;
        @(posedge clk);
        // Wait, receive data, ack
        while(!mreq_valid) @(posedge clk);
        if (mreq_wr) begin
            body_ready <= 1;
            repeat(2) @(posedge clk);
            body_ready <= 0;
        end
        mreq_ready <= 1; @(posedge clk); mreq_ready <= 0;
        @(posedge clk);
        // Wait, receive data, ack
        while(!mreq_valid) @(posedge clk);
        if (mreq_wr) begin
            body_ready <= 1;
            repeat(2) @(posedge clk);
            body_ready <= 0;
        end
        mreq_ready <= 1; @(posedge clk); mreq_ready <= 0;
        @(posedge clk);
        // Wait, receive data, ack
        while(!mreq_valid) @(posedge clk);
        if (mreq_wr) begin
            body_ready <= 1;
            repeat(2) @(posedge clk);
            body_ready <= 0;
        end
        mreq_ready <= 1; @(posedge clk); mreq_ready <= 0;
        @(posedge clk);

        repeat (10) @(posedge clk);

        $finish;
    end

endmodule
