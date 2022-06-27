/*

Based on code by Alex Forencich:

Copyright (c) 2015-2016 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

module wb_mux #
(
    parameter NUM_SLAVES = 3,                       // number of slave ports
    parameter DATA_WIDTH = 32,                      // width of data bus in bits (8, 16, 32, or 64)
    parameter ADDR_WIDTH = 32,                      // width of address bus in bits
    parameter SELECT_WIDTH = (DATA_WIDTH/8)         // width of word select bus (1, 2, 4, or 8)
)
(
    input  wire                    clk,
    input  wire                    rst,

    /*
     * Wishbone master input
     */
    input  wire [ADDR_WIDTH-1:0]   wbm_adr_i,       // ADR_I() address input
    input  wire [DATA_WIDTH-1:0]   wbm_dat_i,       // DAT_I() data in
    output reg  [DATA_WIDTH-1:0]   wbm_dat_o,       // DAT_O() data out
    input  wire                    wbm_we_i,        // WE_I write enable input
    input  wire [SELECT_WIDTH-1:0] wbm_sel_i,       // SEL_I() select input
    input  wire                    wbm_stb_i,       // STB_I strobe input
    output wire                    wbm_ack_o,       // ACK_O acknowledge output
    output wire                    wbm_err_o,       // ERR_O error output
    output wire                    wbm_rty_o,       // RTY_O retry output
    input  wire                    wbm_cyc_i,       // CYC_I cycle input

    /*
     * Wishbone slave output
     */
    output wire [NUM_SLAVES*ADDR_WIDTH-1:0]     wbs_adr_o,       // ADR_O() address output
    input  wire [NUM_SLAVES*DATA_WIDTH-1:0]     wbs_dat_i,       // DAT_I() data in
    output wire [NUM_SLAVES*DATA_WIDTH-1:0]     wbs_dat_o,       // DAT_O() data out
    output wire [NUM_SLAVES-1:0]                wbs_we_o,        // WE_O write enable output
    output wire [NUM_SLAVES*SELECT_WIDTH-1:0]   wbs_sel_o,       // SEL_O() select output
    output wire [NUM_SLAVES-1:0]                wbs_stb_o,       // STB_O strobe output
    input  wire [NUM_SLAVES-1:0]                wbs_ack_i,       // ACK_I acknowledge input
    input  wire [NUM_SLAVES-1:0]                wbs_err_i,       // ERR_I error input
    input  wire [NUM_SLAVES-1:0]                wbs_rty_i,       // RTY_I retry input
    output wire [NUM_SLAVES-1:0]                wbs_cyc_o,       // CYC_O cycle output

    /*
     * Wishbone slave address configuration
     */
    input  wire [NUM_SLAVES*ADDR_WIDTH-1:0]     wbs_addr,        // Slave address prefix
    input  wire [NUM_SLAVES*ADDR_WIDTH-1:0]     wbs_addr_msk     // Slave address prefix mask
);

wire [NUM_SLAVES-1:0] wbs_match;
wire [NUM_SLAVES-1:0] wbs_prevmatch;
wire [NUM_SLAVES-1:0] wbs_sel;

genvar ii;
generate
    for (ii = 0; ii < NUM_SLAVES; ii=ii+1) begin
        assign wbs_match[ii] = ~|((wbm_adr_i ^ wbs_addr[(ii+1)*ADDR_WIDTH-1:ii*ADDR_WIDTH]) &
                                           wbs_addr_msk[(ii+1)*ADDR_WIDTH-1:ii*ADDR_WIDTH]);
        if (ii == 0) begin
            assign wbs_prevmatch[ii] = 1'b0;
        end else begin
            assign wbs_prevmatch[ii] = wbs_prevmatch[ii-1] | wbs_match[ii-1];
        end
        assign wbs_sel[ii] = wbs_match[ii] & ~wbs_prevmatch[ii];
    end
endgenerate

wire master_cycle = wbm_cyc_i & wbm_stb_i;

wire select_error = (~|wbs_sel) & master_cycle;

// master
integer i;
always @(*) begin
    wbm_dat_o = {DATA_WIDTH{1'b0}};
    for (i = NUM_SLAVES-1; i >= 0; i=i-1)
        if (wbs_sel[i])
            wbm_dat_o = wbs_dat_i[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
end

assign wbm_ack_o = |wbs_ack_i;

assign wbm_err_o = |wbs_err_i | select_error;

assign wbm_rty_o = |wbs_rty_i;

// slave
assign wbs_adr_o = {NUM_SLAVES{wbm_adr_i}};
assign wbs_dat_o = {NUM_SLAVES{wbm_dat_i}};
assign wbs_sel_o = {NUM_SLAVES{wbm_sel_i}};
assign wbs_we_o = {NUM_SLAVES{wbm_we_i}} & wbs_sel;
assign wbs_stb_o = {NUM_SLAVES{wbm_stb_i}} & wbs_sel;
assign wbs_cyc_o = {NUM_SLAVES{wbm_cyc_i}} & wbs_sel;

// always @(*) begin
//     for (i = 0; i < NUM_SLAVES; i=i+1) begin
//         wbs_adr_o[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH] = wbm_adr_i;
//         wbs_dat_o[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = wbm_dat_i;
//         wbs_sel_o[(i+1)*SELECT_WIDTH-1:i*SELECT_WIDTH] = wbm_sel_i;
//     end
// end

endmodule
