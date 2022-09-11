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

module test_wbcon_exec;

    localparam WB_ADDR_WIDTH = 6;
    localparam COUNT_WIDTH = 8;

    wb_mem_dly #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .STALL_WS(0),
        .ACK_WS(0)
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

    stream_gen rx_stream (
        .i_clk(clk),
        .i_enable(1'b1),
        .i_ready(rx_ready),
        .o_data(rx_data),
        .o_valid(rx_valid)
    );

    wbcon_exec #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH)
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
        .i_mreq_addr(mreq_addr),
        .i_mreq_cnt(mreq_cnt),
        .i_mreq_wr(mreq_wr),
        .i_mreq_aincr(mreq_aincr),
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
    // mreq control
    reg mreq_valid = 0;
    wire mreq_ready;
    // mreq descriptor
    reg mreq_wr = 0;
    reg mreq_aincr = 0;
    reg [COUNT_WIDTH-1:0] mreq_cnt = 0;
    reg [WB_ADDR_WIDTH-1:0] mreq_addr = 0;
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
            $display("Rx:       0x%02x", rx_data);
        end
        if (tx_valid && tx_ready) begin
            $display("Tx:           0x%02x", tx_data);
        end
        if (wb_cyc && wb_stb && !wb_stall) begin
            $display("WB: req addr=0x%0x sel=%4b we=%b wdata=0x%08x",
                wb_addr,
                wb_sel,
                wb_we,
                wb_data_w
            );
        end
        if (wb_cyc && wb_ack) begin
            $display("WB: ack rdata=0x%08x", wb_data_r);
        end
        if (mreq_valid && mreq_ready) begin
            $display(">>>> MREQ ack: addr=%x cnt=%x wr=%d aincr=%d",
                mreq_addr, mreq_cnt, mreq_wr, mreq_aincr);
        end
    end

    initial begin
        $dumpfile("test_wbcon_exec.vcd");
        $dumpvars(0);


        rst <= 1;
        @(posedge clk);
        rst <= 0;

        // --REQ-- Write something
        mreq_wr <= 1;
        mreq_aincr <= 1;
        mreq_addr <= 3;
        mreq_cnt <= 4-1;

        mreq_valid <= 1'b1;
        while(!mreq_ready) @(posedge clk);
        mreq_valid <= 1'b0;
        @(posedge clk);

        // --REQ-- Write something
        mreq_wr <= 1;
        mreq_aincr <= 1;
        mreq_addr <= 0;
        mreq_cnt <= 4-1;

        mreq_valid <= 1'b1;
        while(!mreq_ready) @(posedge clk);
        mreq_valid <= 1'b0;
        @(posedge clk);

        // --REQ-- Write something
        mreq_wr <= 1;
        mreq_aincr <= 0;
        mreq_addr <= 1;
        mreq_cnt <= 4-1;

        mreq_valid <= 1'b1;
        while(!mreq_ready) @(posedge clk);
        mreq_valid <= 1'b0;
        @(posedge clk);

        // --REQ-- Read something
        mreq_wr <= 0;
        mreq_aincr <= 1;
        mreq_addr <= 0;
        mreq_cnt <= 16-1;

        mreq_valid <= 1'b1;

        repeat (10) @(posedge clk);
        // unblock tx
        tx_ready <= 1'b1;
        while(!mreq_ready) @(posedge clk);
        mreq_valid <= 1'b0;

        repeat(10) @(posedge clk);

        // --REQ-- Read something
        mreq_wr <= 0;
        mreq_aincr <= 0;
        mreq_addr <= 0;
        mreq_cnt <= 4-1;

        mreq_valid <= 1'b1;
        while(!mreq_ready) @(posedge clk);
        mreq_valid <= 1'b0;
        @(posedge clk);

        // --REQ-- Read something
        mreq_wr <= 0;
        mreq_aincr <= 0;
        mreq_addr <= 8;
        mreq_cnt <= 4-1;

        mreq_valid <= 1'b1;
        while(!mreq_ready) @(posedge clk);
        mreq_valid <= 1'b0;
        @(posedge clk);

        repeat (20) @(posedge clk);

        $finish;
    end

endmodule
