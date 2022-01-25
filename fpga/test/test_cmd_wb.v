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

module test_cmd_wb;
    
    localparam WB_ADDR_WIDTH = 6;

    `include "cmd_defines.vh"

    wb_mem #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH)
        // .STALL_WS(0),
        // .ACK_WS(0)
    ) mem (
        .i_clk(clk),
        .i_rst(rst),
        // wb
        .i_wb_cyc(wb_cyc),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wb_stall),
        .o_wb_ack(wb_ack),
        .i_wb_we(wb_we),
        .i_wb_addr(wb_addr),
        .i_wb_data(wb_data_w),
        .i_wb_sel(wb_sel),
        .o_wb_data(wb_data_r)
    );

    // wb_dummy dummy (
    //     .i_clk(clk),
    //     // wb
    //     .i_wb_cyc(wb_cyc),
    //     .i_wb_stb(wb_stb),
    //     .o_wb_stall(wb_stall),
    //     .o_wb_ack(wb_ack),
    //     .o_wb_data(wb_data_r)
    // );

    stream_gen rx_stream (
        .i_clk(clk),
        .i_enable(1'b1),
        .i_ready(rx_ready),
        .o_data(rx_data),
        .o_valid(rx_valid)
    );

    cmd_wb #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        // wb
        .o_wb_cyc(wb_cyc),
        .o_wb_stb(wb_stb),
        .i_wb_stall(wb_stall),
        .i_wb_ack(wb_ack),
        .o_wb_we(wb_we),
        .o_wb_addr(wb_addr),
        .o_wb_data(wb_data_w),
        .o_wb_sel(wb_sel),
        .i_wb_data(wb_data_r),
        // mreq
        .i_mreq_valid(mreq_valid),
        .o_mreq_ready(mreq_ready),
        .i_mreq_wr(mreq_wr),
        .i_mreq_wsize(mreq_wsize),
        .i_mreq_aincr(mreq_aincr),
        .i_mreq_size(mreq_size),
        .i_mreq_addr(mreq_addr),
        // rx
        .o_rx_ready(rx_ready),
        .i_rx_data(rx_data),
        .i_rx_valid(rx_valid),
        // tx
        .i_tx_ready(tx_ready),
        .o_tx_data(tx_data),
        .o_tx_valid(tx_valid)
    );

    reg clk = 0;
    reg rst = 0;
    // wb
    wire wb_cyc;
    wire wb_stb;
    wire wb_stall;
    wire wb_ack;
    wire wb_we;
    wire [WB_ADDR_WIDTH-1:0] wb_addr;
    wire [31:0] wb_data_w;
    wire [3:0] wb_sel;
    wire [31:0] wb_data_r;
    // mreq
    reg mreq_valid = 0;
    wire mreq_ready;
    reg mreq_wr = 0;
    reg [1:0] mreq_wsize = 0;
    reg mreq_aincr = 0;
    reg [7:0] mreq_size = 0;
    reg [31:0] mreq_addr = 0;
    // rx stream
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_ready;
    // tx stream
    wire [7:0] tx_data;
    wire tx_valid;
    reg tx_ready = 0;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rx_valid && rx_ready) begin
            $display("Rx: CMD_WB consumed byte 0x%02x", rx_data);
        end
        if (tx_valid && tx_ready) begin
            $display("Tx: CMD_WB produced byte 0x%02x", tx_data);
        end
        if (mreq_valid && mreq_ready) begin
            $display("MREQ: CMD_WB accepted new request: %s wsize=%1d addr=0x%08x aincr=%b size=%1d",
                mreq_wr ? "WRITE" : "READ",
                mreq_wsize == CMD_WSIZE_4BYTE ? 4 : mreq_wsize == CMD_WSIZE_2BYTE ? 2 : mreq_wsize == CMD_WSIZE_1BYTE ? 1 : 0,
                mreq_addr,
                mreq_aincr,
                mreq_size
            );
        end
    end

    initial begin
        $dumpfile("test_cmd_wb.vcd");
        $dumpvars(0);

        
        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (5) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);

        // --REQ-- Write something
        mreq_wr <= 1'b1;
        mreq_addr <= 32'h0C;    // Byte address: 0xC, WB word address will be 0x3
        mreq_aincr <= 1'b1; 
        mreq_wsize <= CMD_WSIZE_2BYTE;
        mreq_size <= 8'd2;  // 2 words

        mreq_valid <= 1'b1;
        repeat (1) @(posedge clk);
        mreq_valid <= 1'b0;

        repeat (20) @(posedge clk);

        // --REQ-- Write something
        mreq_wr <= 1'b1;
        mreq_addr <= 32'h10;    // Byte address: 0x10, WB word address will be 0x4
        mreq_aincr <= 1'b1; 
        mreq_wsize <= CMD_WSIZE_4BYTE;
        mreq_size <= 8'd2;  // 2 words

        mreq_valid <= 1'b1;
        repeat (1) @(posedge clk);
        mreq_valid <= 1'b0;

        repeat (25) @(posedge clk);

        // --REQ-- Read something
        mreq_wr <= 1'b0;
        mreq_wsize <= CMD_WSIZE_1BYTE;

        mreq_valid <= 1'b1;
        repeat (1) @(posedge clk);
        mreq_valid <= 1'b0;

        repeat (10) @(posedge clk);
        // unblock tx
        tx_ready <= 1'b1;
        repeat (20) @(posedge clk);

        // --REQ-- Read something
        mreq_wr <= 1'b0;
        mreq_wsize <= CMD_WSIZE_2BYTE;

        mreq_valid <= 1'b1;
        repeat (1) @(posedge clk);
        mreq_valid <= 1'b0;

        repeat (10) @(posedge clk);
        // unblock tx
        tx_ready <= 1'b1;
        repeat (20) @(posedge clk);

        // --REQ-- Read something
        mreq_wr <= 1'b0;
        mreq_wsize <= CMD_WSIZE_4BYTE;

        mreq_valid <= 1'b1;
        repeat (1) @(posedge clk);
        mreq_valid <= 1'b0;

        repeat (20) @(posedge clk);



        $finish;
    end

endmodule