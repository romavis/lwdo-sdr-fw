module cpstr_mgr_rx (
    input i_clk,
    input i_rst,
    //
    input [7:0] i_data,
    input i_valid,
    output o_ready,
    //
    output [7:0] o_data,
    output o_valid,
    input i_ready,
    //
    output o_send_stridx
);
    wire clk, rst;
    assign clk = i_clk;
    assign rst = i_rst;

    wire [7:0] esc_data;
    wire esc_valid;

    cpstr_desc cpstr_desc (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_data(i_data),
        .i_valid(i_valid),
        .o_ready(o_ready),
        //
        .o_data(o_data),
        .o_valid(o_valid),
        .i_ready(i_ready),
        //
        .o_esc_data(esc_data),
        .o_esc_valid(esc_valid),
        .i_esc_ready(1'b1)
    );

    // Host should send {1B, FF} to request currently selected stream idx
    assign o_send_stridx = esc_valid && (esc_data == 8'hFF);

endmodule
