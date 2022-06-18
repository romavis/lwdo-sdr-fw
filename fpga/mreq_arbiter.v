module mreq_arbiter #(
    parameter NUM_REQS = 3
)
(
    input i_clk,
    input i_rst,
    // MREQ inputs
    input [NUM_REQS-1:0] i_mreqs_valid,
    output [NUM_REQS-1:0] o_mreqs_ready,
    input [MREQ_NBIT*NUM_REQS-1:0] i_mreqs,
    // Selected MREQ output
    output o_mreq_valid,
    input i_mreq_ready,
    output [MREQ_NBIT-1:0] o_mreq
);

    `include "mreq_defines.vh"

    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    localparam IBITS = $clog2(NUM_REQS);

    reg [IBITS-1:0] sel;

    always @(posedge clk) begin
        if (rst) begin
            sel <= 'd0;
        end else begin
            if (!o_mreq_valid || i_mreq_ready)
                sel <= sel ? (sel - {{IBITS-1{1'b0}}, 1'b1}) : NUM_REQS - 1;
        end
    end

    // Output multiplexers
    // reg [MREQ_NBIT-1:0] r_o_mreq;
    // always @(*) begin
    //     r_o_mreq = i_mreqs[(1+sel)*MREQ_NBIT-1 : sel*MREQ_NBIT];
    // end
    wire [MREQ_NBIT*NUM_REQS-1:0] t_mreq;
    assign t_mreq = i_mreqs >> (sel * MREQ_NBIT); 
    assign o_mreq = t_mreq[MREQ_NBIT-1:0];
    assign o_mreq_valid = i_mreqs_valid[sel];
    assign o_mreqs_ready = mreqs_ready;

    reg [NUM_REQS-1:0] mreqs_ready;
    always @(*) begin
        mreqs_ready = 'd0;
        mreqs_ready[sel] = i_mreq_ready;
    end

endmodule