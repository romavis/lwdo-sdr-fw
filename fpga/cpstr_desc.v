/*
 * Control Port Stream De-escaper
 *
 * Module passes through a byte stream, except that when it encounters
 * ESC_CHAR byte, it discards it and looks at the following byte:
 * - If it is ESC_CHAR, the byte is passed through
 * - If it is not ESC_CHAR, the byte is emitted via 'esc' stream
 */

module cpstr_desc #(
    parameter ESC_CHAR = 8'd27
) (
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
    output [7:0] o_esc_data,
    output o_esc_valid,
    input i_esc_ready
);

    wire clk, rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // Completion detection
    wire byte_recv;
    assign byte_recv = i_valid & o_ready;

    // Whether we're handling byte after ESC right now
    reg esc_recv;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            esc_recv <= 1'b0;
        end else begin
            if (esc_recv && byte_recv)
                esc_recv <= 1'b0;
            else if (i_data == ESC_CHAR && byte_recv)
                esc_recv <= 1'b1;
        end
    end

    // Where incoming bytes are routed
    reg [1:0] route;

    localparam ROUTE_MAIN = 2'd0;
    localparam ROUTE_ESC = 2'd1;
    localparam ROUTE_DROP = 2'd2;

    always @(*) begin
        if (esc_recv)
            route = (i_data == ESC_CHAR) ? ROUTE_MAIN : ROUTE_ESC;
        else
            route = (i_data == ESC_CHAR) ? ROUTE_DROP : ROUTE_MAIN;
    end

    // Stream routing
    reg main_valid;
    reg esc_valid;
    reg recv_ready;

    always @(*) begin
        main_valid = 1'b0;
        esc_valid = 1'b0;
        recv_ready = 1'b0;
        case(route)
        ROUTE_MAIN: begin
            main_valid = i_valid;
            recv_ready = i_ready;
        end

        ROUTE_ESC: begin
            esc_valid = i_valid;
            recv_ready = i_esc_ready;
        end

        ROUTE_DROP: begin
            recv_ready = 1'b1;
        end
        endcase
    end

    assign o_data = i_data;
    assign o_valid = main_valid;
    assign o_esc_data = i_data;
    assign o_esc_valid = esc_valid;
    assign o_ready = recv_ready;

endmodule
