/*
 * Control Port Stream Escaper
 *
 * Module passes through a byte stream, except for:
 * - If it encounters ESC_CHAR byte, two ESC_CHAR are escted in a row
 * - When i_esc stream has data, it takes priority over main stream,
 *   and each byte from it is forwarded to the output after prepending
 *   ESC_CHAR
 */


module cpstr_esc #(
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
    input i_esc_valid,
    input [7:0] i_esc_data,
    output o_esc_ready
);

    wire clk, rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // completion detection
    wire byte_sent;
    assign byte_sent = o_valid & i_ready;

    // Stream routing state machine
    reg [1:0] route;
    reg [1:0] route_prev;

    localparam ROUTE_MAIN = 2'd0;
    localparam ROUTE_ESC = 2'd1;
    localparam ROUTE_ESC_GEN_MAIN = 2'd2;
    localparam ROUTE_ESC_GEN_ESC = 2'd3;

    always @(*) begin
        route = ROUTE_MAIN;
        if (route_prev == ROUTE_ESC_GEN_ESC)
            route = ROUTE_ESC;
        else if (route_prev == ROUTE_ESC_GEN_MAIN)
            route = ROUTE_MAIN;
        else if (i_esc_valid)
            route = ROUTE_ESC_GEN_ESC;
        else if (i_data == ESC_CHAR && i_valid)
            route = ROUTE_ESC_GEN_MAIN;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            route_prev <= ROUTE_MAIN;
        else if(byte_sent)
            route_prev <= route;
    end

    // Stream routing
    reg main_ready;
    reg esc_ready;
    reg [7:0] send_data;
    reg send_valid;

    always @(*) begin
        main_ready = 1'b0;
        esc_ready = 1'b0;
        send_data = 8'd0;
        send_valid = 1'b0;
        case(route)
        ROUTE_MAIN: begin
            main_ready = i_ready;
            send_data = i_data;
            send_valid = i_valid;
        end

        ROUTE_ESC: begin
            esc_ready = i_ready;
            send_data = i_esc_data;
            send_valid = i_esc_valid;
        end

        ROUTE_ESC_GEN_MAIN, ROUTE_ESC_GEN_ESC: begin
            send_data = ESC_CHAR;
            send_valid = 1'b1;
        end
        endcase
    end

    assign o_data = send_data;
    assign o_valid = send_valid;
    assign o_ready = main_ready;
    assign o_esc_ready = esc_ready;

endmodule
