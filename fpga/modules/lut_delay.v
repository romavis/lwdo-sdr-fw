/****************************************************************************

                        ---- lut_delay ----

A primitive & imprecise signal delay using LUTs (or DFFs... we'll see).

Implementation relies on FPGA tech lib.

****************************************************************************/

module lut_delay #(
    parameter DELAY = 32'd1,
) (
    input d,
    output q    //
);
    generate
        if (DELAY >= 32'd1) begin
            genvar i;
            wire [DELAY:0] dly;
            for (i = 0; i < DELAY; i = i + 1) begin
                // See:
                // https://www.latticesemi.com/-/media/LatticeSemi/Documents/TechnicalBriefs/iCETechnologyLibrary.ashx?document_id=44572
                SC_LUT4 #(
                    // Logical OR of I[3:0]
                    .LUT_INIT(16'hFFFE)
                ) u_lut (
                    .I0(dly[i]),
                    .I1(1'b0),
                    .I2(1'b0),
                    .I3(1'b0),
                    .O(dly[i+1])
                );
            end
            assign dly[0] = d;
            assign q = dly[DELAY];
        end else begin
            // No delay
            assign q = d;
        end
    endgenerate
endmodule
