/****************************************************************************

                        ---- ice40_sspll ----

DIY spread-spectrum PLL for ICE40.

Uses LFSR PRNG to modulate the feedback divider of ICE40 PLL.

****************************************************************************/

module ice40_sspll #(
    // Normal ICE40 PLL params
    parameter [3:0] DIVR = 4'd0,
    parameter [31:0] DIVF = 32'd0,
    parameter [2:0] DIVQ = 3'd0,
    parameter [2:0] FILTER_RANGE = 3'd1,
    // Spread-spectrum params:
    // DIVF span during SS operation (higher -> wider spread)
    parameter [31:0] SS_DIVFSPAN = 32'd1,
    // DIVF update clock divider (higher -> wider spread)
    parameter [31:0] SS_UDIV = 32'd0,
) (
    input   REFERENCECLK,
    output  PLLOUTCORE,
    output  LOCK,
    input   RESETB    //
);

    // LFSR PRNG
    // see https://www.analog.com/en/resources/design-notes/random-number-generation-using-lfsr.html
    localparam LFSR_WIDTH = 19;
    localparam [LFSR_WIDTH-1:0] LFSR_POLY = 19'h593CA;
    // External PLL divider
    localparam EDIV_WIDTH = $clog2(DIVF + 1 + (SS_DIVFSPAN + 1) / 2);
    localparam EDIV_HI = DIVF + (SS_DIVFSPAN + 1) / 2;
    localparam EDIV_LO = DIVF - SS_DIVFSPAN / 2;
    // LFSR clock divider
    localparam UDIV_WIDTH = $clog2((SS_UDIV >= 2) ? SS_UDIV : 2);

    // PLL output clock domain
    wire pll_clk;
    wire pll_rst;
    // LFSR
    reg [LFSR_WIDTH-1:0] lfsr;
    // EDIV (external divider)
    reg [EDIV_WIDTH-1:0] ediv;
    // UDIV (LFSR update clock divider)
    reg [UDIV_WIDTH-1:0] udiv;

    // PLL
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("EXTERNAL"),
		.DIVR(DIVR),
		.DIVF(7'd0),    // all division is done by external divider
		.DIVQ(DIVQ),
		.FILTER_RANGE(FILTER_RANGE),
        .PLLOUT_SELECT("GENCLK")
    ) u_sb_pll40 (
        .REFERENCECLK(REFERENCECLK),
        .PLLOUTCORE(pll_clk),
        .EXTFEEDBACK(!ediv),
        .LOCK(LOCK),
        .RESETB(RESETB),
        .BYPASS(1'b0)
    );

    // Reset bridge for 'pll_clk' domain (all our DFFs are clocked by that)
    cdc_reset_bridge u_pll_out_rst_bridge (
        .i_clk(pll_clk),
        .i_rst(~RESETB),
        .o_rst(pll_rst)
    );

    // LFSR
    always @(posedge pll_clk or posedge pll_rst) begin
        if (pll_rst) begin
            lfsr <= 1'd1;   // seed
        end else begin
            // Clock LFSR when UDIV underflows
            if (!udiv) begin
                if (lfsr[0]) begin
                    lfsr <= (lfsr >> 1) ^ LFSR_POLY;
                end else begin
                    lfsr <= lfsr >> 1;
                end
            end
        end
    end

    // EDIV
    always @(posedge pll_clk or posedge pll_rst) begin
        if (pll_rst) begin
            ediv <= 1'd0;
        end else begin
            if (ediv) begin
                ediv <= ediv - 1'd1;
            end else begin
                // Switch between hi/lo dividers depending on LFSR output
                if (lfsr[0]) begin
                    ediv <= EDIV_HI;
                end else begin
                    ediv <= EDIV_LO;
                end
            end
        end
    end

    // UDIV
    always @(posedge pll_clk or posedge pll_rst) begin
        if (pll_rst) begin
            udiv <= 1'd0;
        end else begin
            // Clock UDIV when EDIV underflows
            // This way LFSR is clocked once per SPREAD_CLK_DIV EDIV overflows
            // The higher the SPREAD_CLK_DIV, the slower the LFSR updates,
            // the lower is the spread-spectrum sample rate, the wider is the
            // spread.
            if (!ediv) begin
                if (udiv) begin
                    udiv <= udiv - 1'd1;
                end else begin
                    udiv <= SS_UDIV;
                end
            end
        end
    end

    // Output
    assign PLLOUTCORE = pll_clk;

endmodule
