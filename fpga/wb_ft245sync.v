module wb_ft245sync #(
    parameter WB_ADDR_WIDTH = 30
)
(
    output o_clk,   // Clock _output_, because this module is synced with FT245 which provides us clock
    input i_rst,
    // FTDI pins
    input i_pin_clkout,
    output o_pin_oe_n,
    output o_pin_siwu,
    output o_pin_wr_n,
    output o_pin_rd_n,
    input i_pin_txe_n,
    input i_pin_rxf_n,
    input [7:0] i_pin_data,
    output [7:0] o_pin_data,
    output o_pin_data_oe,
    // Wishbone master
    output o_wb_cyc,
    output o_wb_stb,
    input i_wb_stall,
    input i_wb_ack,
    output o_wb_we,
    output [WB_ADDR_WIDTH-1:0] o_wb_addr,
    output [31:0] o_wb_data,
    output [3:0] o_wb_sel,
    input [31:0] i_wb_data,
    // DEBUG
    output [7:0] o_dbg,
    output [1:0] o_dbg1
);

    // SYSCON
    wire rst;
    wire clk;
    assign rst = i_rst;
    assign o_clk = clk;

    // FTDI Tx & Rx command+data byte streams
    wire [7:0] ft_tx_data;
    wire ft_tx_valid;
    wire ft_tx_ready;
    wire [7:0] ft_rx_data;
    wire ft_rx_valid;
    wire ft_rx_ready;

    // Tx & Rx data byte streams
    wire [7:0] tx_data;
    wire tx_valid;
    wire tx_ready;
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_ready;

    // MREQ bus
    wire mreq_valid;
    wire mreq_ready;
    wire mreq_wr;
    wire [1:0] mreq_wsize;
    wire mreq_aincr;
    wire [7:0] mreq_size;
    wire [31:0] mreq_addr;

    // DEBUG bits
    wire [3:0] ft_debug;
    wire cmd_rx_err_crc;
    wire cmd_rx_dbg;

    // FT245SYNC
    // Side A: FTDI chip pins
    // Side B: Rx & Tx byte stream interface
    ft245sync ft245sync_i (
        .i_pin_clkout(i_pin_clkout),
        .o_pin_oe_n(o_pin_oe_n),
        .o_pin_siwu(o_pin_siwu),
        .o_pin_wr_n(o_pin_wr_n),
        .o_pin_rd_n(o_pin_rd_n),
        .i_pin_txe_n(i_pin_txe_n),
        .i_pin_rxf_n(i_pin_rxf_n),
        .i_pin_data(i_pin_data),
        .o_pin_data(o_pin_data),
        .o_pin_data_oe(o_pin_data_oe),
        //
        .o_clk(clk),
        .i_rst(rst),
        //
        .i_tx_data(ft_tx_data),
        .i_tx_valid(ft_tx_valid),
        .o_tx_ready(ft_tx_ready),
        .o_rx_data(ft_rx_data),
        .o_rx_valid(ft_rx_valid),
        .i_rx_ready(ft_rx_ready),
        // .o_rx_data(dbg_ft_rx_data),
        // .o_rx_valid(dbg_ft_rx_valid),
        // .i_rx_ready(dbg_ft_rx_ready),
        //
        .o_dbg(ft_debug)
    );

    // CMD_RX
    // Side A: FTDI Rx byte stream (command + data)
    // Side B: MREQ source, Rx byte stream (data)
    cmd_rx cmd_rx_i (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_st_data(ft_rx_data),
        .i_st_valid(ft_rx_valid),
        .o_st_ready(ft_rx_ready),
        // 
        .o_err_crc (cmd_rx_err_crc),
        //
        .o_mreq_valid(mreq_valid),
        .i_mreq_ready(mreq_ready),
        .o_mreq_wr(mreq_wr),
        .o_mreq_wsize(mreq_wsize),
        .o_mreq_aincr(mreq_aincr),
        .o_mreq_size(mreq_size),
        .o_mreq_addr(mreq_addr),
        //
        .o_rx_data(rx_data),
        .o_rx_valid(rx_valid),
        .i_rx_ready(rx_ready),
        //
        .o_dbg(cmd_rx_dbg)
    );

    // CMD_WB
    cmd_wb #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH)
    ) cmd_wb_i (
        .i_clk(clk),
        .i_rst(rst),
        // wb
        .o_wb_cyc(o_wb_cyc),
        .o_wb_stb(o_wb_stb),
        .i_wb_stall(i_wb_stall),
        .i_wb_ack(i_wb_ack),
        .o_wb_we(o_wb_we),
        .o_wb_addr(o_wb_addr),
        .o_wb_data(o_wb_data),
        .o_wb_sel(o_wb_sel),
        .i_wb_data(i_wb_data),
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
        .i_tx_ready(ft_tx_ready), // TODO: add CMD_TX!
        .o_tx_data(ft_tx_data),
        .o_tx_valid(ft_tx_valid)
    );

    assign o_dbg[0] = cmd_rx_err_crc;
    assign o_dbg[1] = (o_pin_oe_n == 1'b0) && (i_pin_data == 8'hA3);
    assign o_dbg[2] = o_wb_stb;
    assign o_dbg[3] = o_wb_ack;
    assign o_dbg[4] = mreq_valid;
    assign o_dbg[5] = mreq_ready;
    assign o_dbg[6] = 1'b0;
    assign o_dbg[7] = 1'b0;

    assign o_dbg1[0] = ~i_pin_rxf_n;
    assign o_dbg1[1] = 1'b0;
    

endmodule