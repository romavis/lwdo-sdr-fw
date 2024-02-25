/****************************************************************************

                            ---- ff_sync ----

Flip-flop synchronizer for clock domain crossing.

****************************************************************************/

module ff_sync #(
    parameter DEPTH = 2,
    parameter INITIAL_VAL = 1'b0,
) (
    input i_clk,
    input i_rst,
    input i_d,
    output o_q
);

    reg [DEPTH-1:0] q;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            q <= {DEPTH{INITIAL_VAL[0]}};
        end else begin
            q <= {i_d, q[DEPTH-1:1]};
        end
    end

    assign o_q = q[0];

endmodule
