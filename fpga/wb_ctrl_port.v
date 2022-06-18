module wb_ctrl_port #(
    parameter WB_ADDR_WIDTH = 30,
    parameter NUM_EMREQS = 1
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
    input [31:0] i_wb_data,
    // Error / debug
    output o_err_crc,
    // EMREQ - External MREQ input to the MREQ arbiter
    input [NUM_EMREQS-1:0] i_emreqs_valid,
    output [NUM_EMREQS-1:0] o_emreqs_ready,
    input [NUM_EMREQS*MREQ_NBIT-1:0] i_emreqs
);
    `include "mreq_defines.vh"

    // SYSCON
    wire rst;
    wire clk;
    assign rst = i_rst;
    assign clk = i_clk;

    // CMD_RX stream
    wire [7:0] crx_data;
    wire crx_valid;
    wire crx_ready;

    // CMD_RX MREQ bus
    wire crx_mreq_valid;
    wire crx_mreq_ready;
    wire [MREQ_NBIT-1:0] crx_mreq;

    // MREQ selected for execution
    wire exec_mreq_valid;
    wire exec_mreq_ready;
    wire [MREQ_NBIT-1:0] exec_mreq;

    // CMD_WB Rx and Tx streams
    wire [7:0] cwb_tx_data;
    wire cwb_tx_valid;
    wire cwb_tx_ready;
    wire [7:0] cwb_rx_data;
    wire cwb_rx_valid;
    wire cwb_rx_ready;

    // CMD_WB MREQ control
    wire cwb_mreq_valid;
    wire cwb_mreq_ready;

    // CMD_TX stream
    wire [7:0] ctx_data;
    wire ctx_valid;
    wire ctx_ready;

    // CMD_TX MREQ control
    wire ctx_mreq_valid;
    wire ctx_mreq_ready;

    // CMD_RX
    cmd_rx crx (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_err_crc(o_err_crc),
        //
        .i_rx_data(crx_data),
        .i_rx_valid(crx_valid),
        .o_rx_ready(crx_ready),
        //
        .o_mreq_valid(crx_mreq_valid),
        .i_mreq_ready(crx_mreq_ready),
        .o_mreq(crx_mreq)
    );

    // CMD_TX
    cmd_tx ctx (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_tx_data(ctx_data),
        .o_tx_valid(ctx_valid),
        .i_tx_ready(ctx_ready),
        //
        .i_mreq_valid(ctx_mreq_valid),
        .o_mreq_ready(ctx_mreq_ready),
        .i_mreq(exec_mreq)
    );

    // CMD_WB
    cmd_wb #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH)
    ) cwb (
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
        .i_mreq_valid(cwb_mreq_valid),
        .o_mreq_ready(cwb_mreq_ready),
        .i_mreq(exec_mreq),
        // rx
        .o_rx_ready(cwb_rx_ready),
        .i_rx_data(cwb_rx_data),
        .i_rx_valid(cwb_rx_valid),
        // tx
        .i_tx_ready(cwb_tx_ready),
        .o_tx_data(cwb_tx_data),
        .o_tx_valid(cwb_tx_valid)
    );

    // EMREQ / MREQ arbiter
    wire [NUM_EMREQS:0] arb_mreqs_valid;
    wire [NUM_EMREQS:0] arb_mreqs_ready;
    wire [MREQ_NBIT*(1+NUM_EMREQS)-1:0] arb_mreqs;

    mreq_arbiter #(
        .NUM_REQS(1 + NUM_EMREQS)
    ) arb (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_mreqs_valid(arb_mreqs_valid),
        .o_mreqs_ready(arb_mreqs_ready),
        .i_mreqs(arb_mreqs),
        //
        .o_mreq_valid(exec_mreq_valid),
        .i_mreq_ready(exec_mreq_ready),
        .o_mreq(exec_mreq)
    );

    // Route arbiter MREQ inputs:
    //  MREQ index 0~NUM_EMREQS-1 are EMREQs from outside
    //  MREQ index NUM_EMREQS is our own MREQ from CMD_RX
    assign arb_mreqs_valid = {crx_mreq_valid, i_emreqs_valid};
    assign arb_mreqs = {crx_mreq, i_emreqs};
    assign o_emreqs_ready = arb_mreqs_ready[NUM_EMREQS-1:0];
    assign crx_mreq_ready = arb_mreqs_ready[NUM_EMREQS];
    
    // Rx stream to CRX / CWB switch
    wire rx_conn_cwb;
    assign rx_conn_cwb = crx_mreq_valid;

    assign crx_data = i_rx_data;
    assign crx_valid = rx_conn_cwb ? 1'b0 : i_rx_valid;
    assign cwb_rx_data = i_rx_data;
    assign cwb_rx_valid = rx_conn_cwb ? i_rx_valid : 1'b0;
    assign o_rx_ready = rx_conn_cwb ? cwb_rx_ready : crx_ready;

    // EXEC MREQ is sequenced through two slaves: CMD_WB and CMD_TX
    // Which one is first depends on whether its read or write MREQ
    wire exec1_mreq_valid;
    wire exec1_mreq_ready;
    wire exec2_mreq_valid;
    wire exec2_mreq_ready;
    
    mreq_seq2 mreq_seq2_i(
        .i_clk(clk),
        .i_rst(rst),
        .i_valid(exec_mreq_valid),
        .o_ready(exec_mreq_ready),
        .o_valid1(exec1_mreq_valid),
        .i_ready1(exec1_mreq_ready),
        .o_valid2(exec2_mreq_valid),
        .i_ready2(exec2_mreq_ready)
    );

    // Connect MREQ to CMD_WB and CMD_TX
    wire exec_cwb_then_ctx;
    assign exec_cwb_then_ctx = exec_mreq[MREQ_WR_OFS];

    assign cwb_mreq_valid = exec_cwb_then_ctx ? exec1_mreq_valid : exec2_mreq_valid;
    assign ctx_mreq_valid = exec_cwb_then_ctx ? exec2_mreq_valid : exec1_mreq_valid;
    assign exec1_mreq_ready = exec_cwb_then_ctx ? cwb_mreq_ready : ctx_mreq_ready;
    assign exec2_mreq_ready = exec_cwb_then_ctx ? ctx_mreq_ready : cwb_mreq_ready;

    // CTX / CWB to Tx stream switch
    wire tx_conn_cwb;
    assign tx_conn_cwb = cwb_mreq_valid;

    assign o_tx_data = tx_conn_cwb ? cwb_tx_data : ctx_data;
    assign o_tx_valid = tx_conn_cwb ? cwb_tx_valid : ctx_valid;
    assign ctx_ready = tx_conn_cwb ? 1'b0 : i_tx_ready;
    assign cwb_tx_ready = tx_conn_cwb ? i_tx_ready : 1'b0;

endmodule