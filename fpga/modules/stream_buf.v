// Skid buffer with simple interface
module stream_buf #(
    parameter DATA_WIDTH = 8
) (
    input i_clk,
    input i_rst,
    // Upstream
    input [DATA_WIDTH-1:0] i_data,
    input i_valid,
    output o_ready,
    // Downstream
    output [DATA_WIDTH-1:0] o_data,
    output o_valid,
    input i_ready
);

    axis_register #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(0),
        .LAST_ENABLE(0),
        .USER_ENABLE(0),
        .REG_TYPE(2)    // skid
    ) u_skid (
        .clk(i_clk),
        .rst(i_rst),
        .s_axis_tdata(i_data),
        .s_axis_tvalid(i_valid),
        .s_axis_tready(o_ready),
        .m_axis_tdata(o_data),
        .m_axis_tvalid(o_valid),
        .m_axis_tready(i_ready)
    );

endmodule
