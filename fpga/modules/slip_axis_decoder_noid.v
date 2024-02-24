/****************************************************************************

                        ---- slip_axis_decoder_noid ----

Takes a SLIP-encoded symbol stream and outputs AXI-S stream.

This is a simple decoder: TID is not supported, it just converts
SLIP packet boundaries into TKEEP+TLAST AXI-S framing signals.

****************************************************************************/

module slip_axis_decoder_noid #(
    parameter SYMBOL_WIDTH = 32'd8,
    //
    parameter SYMBOL_END = 8'hC0,
    parameter SYMBOL_ESC = 8'hDB,
    parameter SYMBOL_ESC_END = 8'hDC,
    parameter SYMBOL_ESC_ESC = 8'hDD,
) (
    input i_clk,
    input i_rst,
    // Input SLIP-encoded AXI stream
    input i_s_axis_tvalid,
    output o_s_axis_tready,
    input [SYMBOL_WIDTH-1:0] i_s_axis_tdata,
    // Output AXI stream
    output o_m_axis_tvalid,
    input i_m_axis_tready,
    output [SYMBOL_WIDTH-1:0] o_m_axis_tdata,
    output o_m_axis_tkeep,
    output o_m_axis_tlast   //
);

    wire unesc_end;

    slip_unescaper #(
        .SYMBOL_WIDTH(SYMBOL_WIDTH),
        .SYMBOL_END(SYMBOL_END),
        .SYMBOL_ESC(SYMBOL_ESC),
        .SYMBOL_ESC_END(SYMBOL_ESC_END),
        .SYMBOL_ESC_ESC(SYMBOL_ESC_ESC)
    ) u_escaper (
        .i_clk(i_clk),
        .i_rst(i_rst),
        //
        .i_data(i_s_axis_tdata),
        .i_valid(i_s_axis_tvalid),
        .o_ready(o_s_axis_tready),
        //
        .o_data(o_m_axis_tdata),
        .o_end(unesc_end),
        .o_valid(o_m_axis_tvalid),
        .i_ready(i_m_axis_tready)
    );

    // very simple END -> TKEEP+TLAST conversion
    // however it requires downstream modules to support TKEEP
    assign o_m_axis_tkeep = !unesc_end;
    assign o_m_axis_tlast = unesc_end;

endmodule
