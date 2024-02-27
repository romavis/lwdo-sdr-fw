/****************************************************************************

                        ---- ad7357_clk_gen ----

AD7357 SCLK generator.
Allows SCLK to be shared between several AD7357 ADCs while having different
timings between them.

To be used with 'ad7357_driver' module.

****************************************************************************/


module ad7357_clk_gen (
    input i_clk,
    input i_rst,
    // Signaling to ad7357_driver module
    input i_ctl_cken,   // OR drivers' 'cken' signals here
    // SCLK pin driven via DDR output buffer
    output o_adc_sclk_ddr_h,    // To output when i_clk: L->H
    output o_adc_sclk_ddr_l     // To output when i_clk: H->L
);

    reg sclk_ddr_h_reg;
    reg sclk_ddr_l_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            // Fix SCLK at 1
            sclk_ddr_h_reg <= 1'b1;
            sclk_ddr_l_reg <= 1'b1;
        end else begin
            // NOTE:
            // ddr_h_reg change is active from the next posedge i_clk
            // ddr_l_reg change can be active from the next _negedge_ i_clk
            // Thus ddr_l change may kick in quicker than ddr_h
            if (i_ctl_cken) begin
                // Kick off SCLK generation (SCLK = ~i_clk)
                sclk_ddr_h_reg <= 1'b0;
                sclk_ddr_l_reg <= 1'b1;
            end else begin
                // Stop clock generation
                sclk_ddr_h_reg <= 1'b1;
                sclk_ddr_l_reg <= 1'b1;
            end
        end
    end

    assign o_adc_sclk_ddr_h = sclk_ddr_h_reg;
    assign o_adc_sclk_ddr_l = sclk_ddr_l_reg;

endmodule
