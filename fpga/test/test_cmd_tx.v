
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module stream_gen (
    input i_clk,
    input i_enable,

    input i_ready,
    output [7:0] o_data,
    output o_valid
);

    reg [7:0] d;

    assign o_valid = i_enable;
    assign o_data = d;

    initial begin
        d <= 8'd0;
    end

    always @(posedge i_clk) begin
        if (o_valid && i_ready) begin
            // Transaction happens, increment data
            d <= d + 8'd1;
        end
    end

endmodule


module test_cmd_tx;

    `include "cmd_defines.vh"

    reg clk = 0;
    reg rst = 0;
    reg en = 0;

    reg mreq_valid = 0;
    reg mreq_ready = 0;
    reg mreq_wr = 0;
    reg [1:0] mreq_wsize = 0;
    reg mreq_aincr = 0;
    reg [7:0] mreq_size = 0;
    reg [31:0] mreq_addr = 0;

    always #5 clk = ~clk;

    integer i = 0;

    initial begin
        $dumpfile("test_cmd_tx.vcd");
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
        repeat (5) @(posedge clk);
        mreq_valid <= 1;
        mreq_wsize <= CMD_WSIZE_2BYTE;
        mreq_aincr <= 1;
        mreq_size <= 8'd5;
        mreq_addr <= 32'h12345678;

        fork : wait_or_timeout1
        begin
            repeat (100) @(posedge clk);
            disable wait_or_timeout1;
        end
        begin
            @(posedge mreq_valid_post);
            disable wait_or_timeout1;
        end
        join

        // Send 5 bytes
        repeat (5) @(posedge clk);

        mreq_ready <= 1;
        @(posedge clk);
        mreq_valid <= 0;
        mreq_ready <= 0;

        repeat (5) @(posedge clk);

        // New MREQ, no data
        mreq_wr <= 1;
        mreq_valid <= 1;
        mreq_wsize <= CMD_WSIZE_2BYTE;
        mreq_aincr <= 1;
        mreq_size <= 8'd5;
        mreq_addr <= 32'h43211234;

        fork : wait_or_timeout2
        begin
            repeat (100) @(posedge clk);
            disable wait_or_timeout2;
        end
        begin
            @(posedge mreq_valid_post);
            disable wait_or_timeout2;
        end
        join

        // Send no data
        en <= 0;
        @(posedge clk);

        mreq_ready <= 1;
        @(posedge clk);
        mreq_valid <= 0;
        mreq_ready <= 0;

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

    wire [7:0] st_data;
    wire st_valid;
    // wire st_ready;
    wire mreq_valid_post;
    wire tx_data_valid;
    wire [7:0] tx_data;
    wire tx_data_ready;
  
    // assign st_ready = st_valid;

    stream_gen tx_data_gen (
        .i_clk(clk),
        .i_enable(en),
        .i_ready(tx_data_ready),
        .o_data(tx_data),
        .o_valid(tx_data_valid)
    );

    cmd_tx dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_st_data(st_data),
        .o_st_valid(st_valid),
        .i_st_ready(1'b1),
        //
        .i_mreq_valid(mreq_valid),
        .i_mreq_ready(mreq_ready),
        .i_mreq_wr(mreq_wr),
        .i_mreq_wsize(mreq_wsize),
        .i_mreq_aincr(mreq_aincr),
        .i_mreq_size(mreq_size),
        .i_mreq_addr(mreq_addr),
        .o_mreq_valid(mreq_valid_post),
        //
        .i_tx_data_valid(tx_data_valid),
        .i_tx_data(tx_data),
        .o_tx_data_ready(tx_data_ready)
    );

endmodule
