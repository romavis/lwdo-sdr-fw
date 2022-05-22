
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
        // CRC error
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        // Write: addr=0x12345678, asize=1byte, incr=1, bytes=5
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'b001001;
        test_vector[i++] = 8'h05;
        test_vector[i++] = 8'h78;
        test_vector[i++] = 8'h56;
        test_vector[i++] = 8'h34;
        test_vector[i++] = 8'h12;
        test_vector[i++] = 8'hCE; //crc
        // Read: addr=0x87654321, asize=2byte, incr=1, bytes=5
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'b011000;
        test_vector[i++] = 8'h05;
        test_vector[i++] = 8'h21;
        test_vector[i++] = 8'h43;
        test_vector[i++] = 8'h65;
        test_vector[i++] = 8'h87;
        test_vector[i++] = 8'hBA; //crc
        // Read: addr=0x87654321, asize=2byte, incr=1, bytes=5
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'b011000;
        test_vector[i++] = 8'h05;
        test_vector[i++] = 8'h21;
        test_vector[i++] = 8'h43;
        test_vector[i++] = 8'h65;
        test_vector[i++] = 8'h87;
        test_vector[i++] = 8'hBA; //crc
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

module test_cmd_rx;
    reg clk = 0;
    reg rst = 0;
    reg en = 0;
  
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_ready;

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test_cmd_rx.vcd");
        $dumpvars(0);

        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (1) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);
        en <= 1;
        repeat (10) @(posedge clk);
        mreq_ready = 0;
        repeat (30) @(posedge clk);
        mreq_ready = 1;
        repeat (50) @(posedge clk);

        $finish;
    end
  
    stream_gen gen (
        .i_clk(clk),
        .i_enable(en),
        .i_ready(rx_ready),
        .o_data(rx_data),
        .o_valid(rx_valid)
    );

    wire crc_err;

    wire mreq_valid;
    reg mreq_ready = 1;
    wire mreq_wr;
    wire [1:0] mreq_wsize;
    wire mreq_aincr;
    wire [7:0] mreq_wcount;
    wire [31:0] mreq_addr;

    cmd_rx dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_err_crc(crc_err),
        //
        .i_rx_valid(rx_valid),
        .i_rx_data(rx_data),
        .o_rx_ready(rx_ready),
        //
        .o_mreq_valid(mreq_valid),
        .i_mreq_ready(mreq_ready),
        .o_mreq_wr(mreq_wr),
        .o_mreq_wsize(mreq_wsize),
        .o_mreq_wcount(mreq_wcount),
        .o_mreq_addr(mreq_addr)
    );

endmodule
