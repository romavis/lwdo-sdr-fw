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
    output out, // 'clean' asynchronous reset (async assert, sync de-assert)
    output outd // same as 'out' but is held for 1 clock cycle longer
);

    reg [2:0] r = {3{INITIAL_VAL}};

    always @(posedge clk or posedge rst)
        if (rst)
            r <= {3{1'b1}};
        else
            r <= {r[1:0], 1'b0};

    assign out = r[1];
    assign outd = r[2];

endmodule
