/****************************************************************************

                        ---- cdc_reset_bridge ----

Clock domain crossing: reset bridge with asynchronous assertion and
synchronous de-assertion.

****************************************************************************/

module cdc_reset_bridge #(
    // Is reset initially asserted or de-asserted
    parameter INIT = 1'b1
) (
    input i_clk,    // clock
    input i_rst,    // async reset input
    output o_rst,   // cleaned up async-assert sync-deassert reset output
    output o_rst_q  // same as 'o_rst' but active for 1 more clock cycle
);

    reg [2:0] r = {3{INIT}};

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r <= {3{1'b1}};
        end else begin
            r <= {r[1:0], 1'b0};
        end
    end

    assign o_rst = r[1];
    assign o_rst_q = r[2];

endmodule
