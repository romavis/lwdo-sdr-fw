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

    // 1-byte buffer
    reg [7:0] reg_data;
    reg reg_used;
    // output
    wire reg_ovalid = reg_used;
    reg reg_iready;
    // input
    assign o_ready = !reg_used || reg_iready;

    always @(posedge clk or posedge rst)
        if (rst) begin
            reg_data <= 8'd0;
            reg_used <= 1'b0;
        end else begin
            if (i_valid && o_ready) begin
                reg_data <= i_data;
                reg_used <= 1'b1;
            end else if (reg_ovalid && reg_iready)
                reg_used <= 1'b0;
        end

    // State machine
    reg [1:0] route;
    reg [1:0] route_next;

    localparam ROUTE_MAIN = 2'd0;
    localparam ROUTE_ESC = 2'd1;
    localparam ROUTE_DROP = 2'd2;

    always @(posedge clk or posedge rst)
        if (rst)
            route <= ROUTE_MAIN;
        else
            route <= route_next;

    always @(*) begin
        route_next = route;
        case (route)

        ROUTE_MAIN, ROUTE_ESC:
            if (byte_recv) begin
                if(i_data == ESC_CHAR)
                    route_next = ROUTE_DROP;
                else
                    route_next = ROUTE_MAIN;
            end

        ROUTE_DROP:
            if (byte_recv) begin
                if(i_data == ESC_CHAR)
                    route_next = ROUTE_MAIN;
                else
                    route_next = ROUTE_ESC;
            end

        endcase
    end

    // Stream routing
    reg main_valid;
    reg esc_valid;

    always @(*) begin
        main_valid = 1'b0;
        esc_valid = 1'b0;
        reg_iready = 1'b0;
        case(route)
        ROUTE_MAIN: begin
            main_valid = reg_ovalid;
            reg_iready = i_ready;
        end

        ROUTE_ESC: begin
            esc_valid = reg_ovalid;
            reg_iready = i_esc_ready;
        end

        ROUTE_DROP: begin
            reg_iready = 1'b1;
        end
        endcase
    end

    assign o_data = reg_data;
    assign o_valid = main_valid;
    assign o_esc_data = reg_data;
    assign o_esc_valid = esc_valid;

endmodule
