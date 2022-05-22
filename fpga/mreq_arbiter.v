module mreq_arbiter #(
    parameter REQS_NUM = 3,
    parameter REQS_IBITS = 4
)
(
    input i_clk,
    input i_rst,
    // Input MREQ control
    input [REQS_NUM-1:0] i_mreqs_valid,
    output [REQS_NUM-1:0] o_mreqs_ready,
    // Input MREQ data
    output [REQS_IBITS-1:0] o_mreq_sel,
    input i_mreq_wr,
    input i_mreq_aincr,
    input [1:0] i_mreq_wsize,
    input [7:0] i_mreq_wcount,
    input [31:0] i_mreq_addr,
    // MREQ (output)
    output o_mreq_valid,
    input i_mreq_ready,
    output o_mreq_wr,
    output o_mreq_aincr,
    output [1:0] o_mreq_wsize,
    output [7:0] o_mreq_wcount,
    output [31:0] o_mreq_addr
);

    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    reg [REQS_IBITS-1:0] sel;

    always @(posedge clk) begin
        if (rst) begin
            sel <= 'd0;
        end else begin
            if (!o_mreq_valid || i_mreq_ready)
                sel <= sel ? (sel - {{REQS_IBITS-1{1'b0}}, 1'b1}) : REQS_NUM - 1;
        end
    end

    // Output multiplexers
    assign o_mreq_sel = sel;
    assign o_mreq_valid = i_mreqs_valid[sel];
    assign o_mreqs_ready = mreqs_ready;
    assign o_mreq_wr = i_mreq_wr;
    assign o_mreq_aincr = i_mreq_aincr;
    assign o_mreq_wsize = i_mreq_wsize;
    assign o_mreq_wcount = i_mreq_wcount;
    assign o_mreq_addr = i_mreq_addr;

    reg [REQS_NUM-1:0] mreqs_ready;
    always @(*) begin
        mreqs_ready = 'd0;
        mreqs_ready[sel] = i_mreq_ready;
    end

endmodule