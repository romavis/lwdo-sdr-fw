/****************************************************************************

                             ---- wbcon ----

Wishbone master providing command-controlled access to Wishbone bus via
serial stream protocol.

For more info see internal modules: wbcon_rx, wbcon_tx, wbcon_exec.

****************************************************************************/

module wbcon #(
    parameter WB_ADDR_WIDTH = 24,
    parameter WB_DATA_WIDTH = 32,
    parameter WB_SEL_WIDTH = (WB_DATA_WIDTH + 7) / 8
)
(
    input i_clk,
    input i_rst,
    // Rx command stream
    input i_rx_axis_tvalid,
    output o_rx_axis_tready,
    input [7:0] i_rx_axis_tdata,
    input i_rx_axis_tkeep,
    input i_rx_axis_tlast,
    // Tx command stream
    output o_tx_axis_tvalid,
    input i_tx_axis_tready,
    output [7:0] o_tx_axis_tdata,
    output o_tx_axis_tlast,
    // Wishbone master
    output o_wb_cyc,
    output o_wb_stb,
    input i_wb_stall,
    input i_wb_ack,
    input i_wb_err,
    input i_wb_rty,
    output o_wb_we,
    output [WB_ADDR_WIDTH-1:0] o_wb_adr,
    output [WB_DATA_WIDTH-1:0] o_wb_dat,
    output [WB_SEL_WIDTH-1:0] o_wb_sel,
    input [WB_DATA_WIDTH-1:0] i_wb_dat
);

    localparam BYTE_ADDR_WIDTH = $clog2((WB_DATA_WIDTH + 7) / 8);
    localparam SERIAL_ADDR_WIDTH = WB_ADDR_WIDTH + BYTE_ADDR_WIDTH;

    // CMD wires
    wire cmd_tvalid;
    wire cmd_tready;
    wire cmd_op_set_address;
    wire cmd_op_write_word;
    wire cmd_op_read_word;
    wire [SERIAL_ADDR_WIDTH-1:0] cmd_hw_addr;
    wire [WB_DATA_WIDTH-1:0] cmd_hw_data;

    // CRES wires
    wire cres_tvalid;
    wire cres_tready;
    wire cres_op_set_address;
    wire cres_op_write_word;
    wire cres_op_read_word;
    wire [WB_DATA_WIDTH-1:0] cres_hw_data;
    wire cres_bus_err;
    wire cres_bus_rty;

    wbcon_rx #(
        .HW_ADDR_WIDTH(SERIAL_ADDR_WIDTH),
        .HW_DATA_WIDTH(WB_DATA_WIDTH)
    ) u_wbcon_rx (
        .i_clk(i_clk),
        .i_rst(i_rst),
        //
        .i_rx_axis_tvalid(i_rx_axis_tvalid),
        .o_rx_axis_tready(o_rx_axis_tready),
        .i_rx_axis_tdata(i_rx_axis_tdata),
        .i_rx_axis_tkeep(i_rx_axis_tkeep),
        .i_rx_axis_tlast(i_rx_axis_tlast),
        //
        .o_cmd_tvalid(cmd_tvalid),
        .i_cmd_tready(cmd_tready),
        .o_cmd_op_set_address(cmd_op_set_address),
        .o_cmd_op_write_word(cmd_op_write_word),
        .o_cmd_op_read_word(cmd_op_read_word),
        .o_cmd_hw_addr(cmd_hw_addr),
        .o_cmd_hw_data(cmd_hw_data)
    );

    wbcon_tx #(
        .HW_DATA_WIDTH(WB_DATA_WIDTH)
    ) u_wbcon_tx (
        .i_clk(i_clk),
        .i_rst(i_rst),
        //
        .i_cres_tvalid(cres_tvalid),
        .o_cres_tready(cres_tready),
        .i_cres_op_set_address(cres_op_set_address),
        .i_cres_op_write_word(cres_op_write_word),
        .i_cres_op_read_word(cres_op_read_word),
        .i_cres_hw_data(cres_hw_data),
        .i_cres_bus_err(cres_bus_err),
        .i_cres_bus_rty(cres_bus_rty),
        //
        .o_tx_axis_tvalid(o_tx_axis_tvalid),
        .i_tx_axis_tready(i_tx_axis_tready),
        .o_tx_axis_tdata(o_tx_axis_tdata),
        .o_tx_axis_tlast(o_tx_axis_tlast)
    );

    wbcon_exec #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .WB_DATA_WIDTH(WB_DATA_WIDTH),
        .WB_SEL_WIDTH(WB_SEL_WIDTH),
        .BYTE_ADDR_WIDTH(BYTE_ADDR_WIDTH),
        .SERIAL_ADDR_WIDTH(SERIAL_ADDR_WIDTH)
    ) u_wbcon_exec (
        .i_clk(i_clk),
        .i_rst(i_rst),
        //
        .o_wb_cyc(o_wb_cyc),
        .o_wb_stb(o_wb_stb),
        .i_wb_stall(i_wb_stall),
        .i_wb_ack(i_wb_ack),
        .i_wb_err(i_wb_err),
        .i_wb_rty(i_wb_rty),
        .o_wb_we(o_wb_we),
        .o_wb_adr(o_wb_adr),
        .o_wb_dat(o_wb_dat),
        .o_wb_sel(o_wb_sel),
        .i_wb_dat(i_wb_dat),
        //
        .i_cmd_tvalid(cmd_tvalid),
        .o_cmd_tready(cmd_tready),
        .i_cmd_op_set_address(cmd_op_set_address),
        .i_cmd_op_write_word(cmd_op_write_word),
        .i_cmd_op_read_word(cmd_op_read_word),
        .i_cmd_hw_addr(cmd_hw_addr),
        .i_cmd_hw_data(cmd_hw_data),
        //
        .o_cres_tvalid(cres_tvalid),
        .i_cres_tready(cres_tready),
        .o_cres_op_set_address(cres_op_set_address),
        .o_cres_op_write_word(cres_op_write_word),
        .o_cres_op_read_word(cres_op_read_word),
        .o_cres_hw_data(cres_hw_data),
        .o_cres_bus_err(cres_bus_err),
        .o_cres_bus_rty(cres_bus_rty)
    );

endmodule
