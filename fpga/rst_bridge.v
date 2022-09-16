/****************************************************************************

                        ---- rst_bridge ----

    Reset bridge with asynchronous assertion and synchronous de-assertion.

****************************************************************************/

module rst_bridge #(
    // Is reset initially asserted or de-asserted
    parameter INITIAL_VAL = 1'b1
) (
    input clk,  // clock
    input rst,  // 'dirty' asynchronous reset (async assert, async de-assert)
    output out  // 'clean' asynchronous reset (async assert, sync de-assert)
);

    reg [1:0] r = {INITIAL_VAL, INITIAL_VAL};

    always @(posedge clk or posedge rst)
        if (rst)
            {r[1], r[0]} <= {1'b1, 1'b1};
        else
            {r[1], r[0]} <= {r[0], 1'b0};

    assign out = r[1];

endmodule
