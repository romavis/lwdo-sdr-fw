/****************************************************************************

                             ---- wbcon ----

Wishbone master providing command-controlled access to Wishbone bus via
serial stream protocol.

For more info see internal modules: wbcon_rx, wbcon_tx, wbcon_exec.

****************************************************************************/

module wbcon #(
    parameter WB_ADDR_WIDTH = 24,
    parameter COUNT_WIDTH = 8
)
(
    input i_clk,
    input i_rst,
    // Rx command stream
    input [7:0] i_rx_data,
    input i_rx_valid,
    output o_rx_ready,
    // Tx command stream
    output [7:0] o_tx_data,
    output o_tx_valid,
    input i_tx_ready,
    // Wishbone master
    output o_wb_cyc,
    output o_wb_stb,
    input i_wb_stall,
    input i_wb_ack,
    output o_wb_we,
    output [WB_ADDR_WIDTH-1:0] o_wb_addr,
    output [31:0] o_wb_data,
    output [3:0] o_wb_sel,
    input [31:0] i_wb_data
);
    // SYSCON
    wire rst;
    wire clk;
    assign rst = i_rst;
    assign clk = i_clk;

    // WIRING
    wire [7:0] rx_body_data;
    wire rx_body_valid;
    wire rx_body_ready;

    wire [7:0] tx_body_data;
    wire tx_body_valid;
    wire tx_body_ready;

    wire [WB_ADDR_WIDTH-1:0] mreq_addr;
    wire [COUNT_WIDTH-1:0] mreq_cnt;
    wire mreq_wr;
    wire mreq_aincr;

    wire mreq_valid;
    wire mreq_ready;
    wire exec_mreq_valid;
    wire exec_mreq_ready;

    // wbcon_rx
    wbcon_rx #(
        .ADDR_WIDTH(WB_ADDR_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH)
    ) wbcon_rx (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_rx_data(i_rx_data),
        .i_rx_valid(i_rx_valid),
        .o_rx_ready(o_rx_ready),
        //
        .o_body_data(rx_body_data),
        .o_body_valid(rx_body_valid),
        .i_body_ready(rx_body_ready),
        //
        .o_mreq_valid(mreq_valid),
        .i_mreq_ready(mreq_ready),
        .o_mreq_addr(mreq_addr),
        .o_mreq_cnt(mreq_cnt),
        .o_mreq_wr(mreq_wr),
        .o_mreq_aincr(mreq_aincr)
    );

    // wbcon_tx
    wbcon_tx wbcon_tx (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_tx_data(o_tx_data),
        .o_tx_valid(o_tx_valid),
        .i_tx_ready(i_tx_ready),
        //
        .i_body_data(tx_body_data),
        .i_body_valid(tx_body_valid),
        .o_body_ready(tx_body_ready),
        //
        .i_mreq_valid(mreq_valid),
        .o_mreq_ready(mreq_ready),
        //
        .o_mreq_valid(exec_mreq_valid),
        .i_mreq_ready(exec_mreq_ready)
    );

    // wbcon_exec
    wbcon_exec #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH)
    ) wbcon_exec (
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
        .i_mreq_valid(exec_mreq_valid),
        .o_mreq_ready(exec_mreq_ready),
        .i_mreq_addr(mreq_addr),
        .i_mreq_cnt(mreq_cnt),
        .i_mreq_wr(mreq_wr),
        .i_mreq_aincr(mreq_aincr),
        // rx
        .i_rx_data(rx_body_data),
        .i_rx_valid(rx_body_valid),
        .o_rx_ready(rx_body_ready),
        // tx
        .o_tx_data(tx_body_data),
        .i_tx_ready(tx_body_ready),
        .o_tx_valid(tx_body_valid)
    );

endmodule
