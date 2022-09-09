/*
 * Control Port Stream Escaper
 *
 * Module passes through a byte stream, except for:
 * - If it encounters ESC_CHAR byte, two ESC_CHAR are emitted in a row
 * - When i_emit is set to 1, the module emits ESC_CHAR followed by byte
 *   picked up from i_emit_data bus
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
    input i_emit_valid,
    input [7:0] i_emit_data,
    output o_emit_ready
);

    wire clk, rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // completion detection
    wire sent;
    assign sent = o_valid & i_ready;

    // State machine
    reg [1:0] state;
    reg [1:0] state_next;

    localparam ST_PASS = 2'd0;
    localparam ST_DUP = 2'd1;
    localparam ST_SEND_EMIT1 = 2'd2;
    localparam ST_SEND_EMIT2 = 2'd3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_PASS;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        case (state)
        ST_PASS:
            if (i_valid && i_data == ESC_CHAR) state_next = ST_DUP;
            else if (i_emit_valid) state_next = ST_SEND_EMIT1;
        ST_DUP:
            if (sent) begin
                state_next = ST_PASS;
                // to avoid starvation when stream contains only ESC_CHARs
                if (i_emit_valid) state_next = ST_SEND_EMIT1;
            end
        ST_SEND_EMIT1:
            if (sent) state_next = ST_SEND_EMIT2;
        ST_SEND_EMIT2:
            if (sent) state_next = ST_PASS;
        endcase
    end

    // Emit endpoint (ready generation)
    reg emit_ready;
    assign o_emit_ready = emit_ready;

    always @(*) begin
        emit_ready = 1'b0;
        if (state == ST_SEND_EMIT2 && sent) emit_ready = 1'b1;
    end

    // Input endpoint (o_ready generation)
    reg recv_ready;
    assign o_ready = recv_ready;

    always @(*) begin
        if (state == ST_PASS)
            recv_ready = i_ready;
        else
            recv_ready = 1'b0;
    end

    // Output endpoint (o_data and o_valid generation)
    reg [7:0] send_data;
    reg send_valid;
    assign o_data = send_data;
    assign o_valid = send_valid;

    always @(*) begin
        case (state)
        ST_PASS: begin
            send_data = i_data;
            send_valid = i_valid;
        end
        ST_DUP, ST_SEND_EMIT1: begin
            send_data = ESC_CHAR;
            send_valid = 1'b1;
        end
        ST_SEND_EMIT2: begin
            send_data = i_emit_data;
            send_valid = 1'b1;
        end
        endcase
    end

endmodule
