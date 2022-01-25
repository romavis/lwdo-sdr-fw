
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
        // 5 bytes follow
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'hA2;
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'hA2;
        test_vector[i++] = 8'hA3;
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

module mreq_executor (
    input i_clk,
    input i_rst,
    // Decoded memory request (MREAD, MWRITE)
    input i_mreq_valid,
    output o_mreq_ready,
    input i_mreq_wr,
    input [1:0] i_mreq_wsize,
    input i_mreq_aincr,
    input [7:0] i_mreq_size,
    input [31:0] i_mreq_addr,
    // Data stream
    input i_rx_data_valid,
    input [7:0] i_rx_data,
    output o_rx_data_ready
);

    reg [10:0] r_bytes_remaining;
    reg r_mreq_ready;
    reg r_mreq_in_progress;

    assign o_rx_data_ready = i_rx_data_valid && r_mreq_in_progress && (r_bytes_remaining != 'd0);
    assign o_mreq_ready = r_mreq_ready;

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_bytes_remaining <= 'd0;
            r_mreq_ready <= 1'b0;
            r_mreq_in_progress <= 1'b0;
        end else begin
            r_mreq_ready <= 1'b0;

            if (r_mreq_in_progress) begin
                if (r_bytes_remaining) begin
                    if (i_rx_data_valid) begin
                        r_bytes_remaining <= r_bytes_remaining - 1;
                    end
                end else begin
                    r_mreq_in_progress <= 1'b0;
                    r_mreq_ready <= 1'b1;
                end
            end else begin
                if (i_mreq_valid && !r_mreq_ready) begin
                    r_mreq_in_progress <= 1'b1;
                    if (i_mreq_wr) begin
                        r_bytes_remaining <= ({3'd0, i_mreq_size} << i_mreq_wsize) + (3'b1 << i_mreq_wsize) - 1;
                    end else begin
                        r_bytes_remaining <= 'd0;
                    end
                end
            end
        end
    end

endmodule

module test_cmd_rx;
    reg clk = 0;
    reg rst = 0;
    reg en = 0;
  
    wire [7:0] st_data;
    wire st_valid;
    wire st_ready;

    always #5 clk = ~clk;

    initial begin
        $dumpfile("test_cmd_rx.vcd");
        $dumpvars(0);

        // $monitor(,$time,"  en=%b,valid_in=%b,ready_out=%b,valid_out=%b,ready_in=%b",en,valid_in,ready_out,valid_out,ready_in);

        repeat (5) @(posedge clk);
        #3
        rst <= 1;
        repeat (1) @(posedge clk);
        #3
        rst <= 0;
        repeat (5) @(posedge clk);
        #3
        en <= 1;
        repeat (100) @(posedge clk);
        // #3
        // ready_in <= 1;
        // repeat (5) @(posedge clk);
        // #3
        // ready_in <= 0;
        // repeat (5) @(posedge clk);
        // #3
        // ready_in <= 1;
        // repeat (5) @(posedge clk);
        // #3
        // ready_in <= 0;
        // repeat (5) @(posedge clk);
        // #3
        // ready_in <= 1;
        // repeat (5) @(posedge clk);
        // #3
        // en <= 0;
        // repeat (5) @(posedge clk);
        // #3
        // ready_in <= 0;
        // repeat (5) @(posedge clk);
        // #3
        // en <= 1;
        // repeat (5) @(posedge clk);
        // #3
        // ready_in <= 1;
        // repeat (5) @(posedge clk);
        // #3
        // ready_in <= 0;
        // repeat (5) @(posedge clk);
        // #3
        // en <= 0;
        // ready_in <= 1;
        // repeat (5) @(posedge clk);
        $finish;
    end
  
    stream_gen gen (
        .i_clk(clk),
        .i_enable(en),
        .i_ready(st_ready),
        .o_data(st_data),
        .o_valid(st_valid)
    );

    wire mreq_valid;
    wire mreq_ready;
    wire mreq_wr;
    wire [1:0] mreq_wsize;
    wire mreq_aincr;
    wire [7:0] mreq_size;
    wire [31:0] mreq_addr;
    wire rx_data_valid;
    wire [7:0] rx_data;
    wire rx_data_ready;

    mreq_executor mreq_exe (
        .i_clk(clk),
        .i_rst(rst),
        .i_mreq_valid(mreq_valid),
        .o_mreq_ready(mreq_ready),
        .i_mreq_wr(mreq_wr),
        .i_mreq_wsize(mreq_wsize),
        .i_mreq_size(mreq_size),
        .i_mreq_addr(mreq_addr),
        .i_rx_data_valid(rx_data_valid),
        .i_rx_data(rx_data),
        .o_rx_data_ready(rx_data_ready)
    );

    cmd_rx dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_st_valid(st_valid),
        .i_st_data(st_data),
        .o_st_ready(st_ready),
        //
        .o_mreq_valid(mreq_valid),
        .i_mreq_ready(mreq_ready),
        .o_mreq_wr(mreq_wr),
        .o_mreq_wsize(mreq_wsize),
        .o_mreq_size(mreq_size),
        .o_mreq_addr(mreq_addr),
        //
        .o_rx_data_valid(rx_data_valid),
        .o_rx_data(rx_data),
        .i_rx_data_ready(rx_data_ready)
    );

endmodule
