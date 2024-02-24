/****************************************************************************

                        ---- slip_unescaper ----

Stream un-escaper inspired by SLIP protocol.
See: https://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol

The idea is that we define 4 symbols:
    SYMBOL_END
    SYMBOL_ESC
    SYMBOL_ESC_END
    SYMBOL_ESC_ESC

The input to the module is an AXIS-like stream of symbols. The output is also
an AXIS-like stream of symbols same width as at the input, but augmented with
an extra 'o_end' bit.

Working of the module can be summarized by the table:
    +-------------------------------+-----------+-------------------+
    |   Input symbols               |   o_end   |   Emitted symbol  |
    +-------------------------------+-----------+-------------------+
    | SYMBOL_ESC                    |     -     |       -           |
    | SYMBOL_ESC + SYMBOL_ESC_END   |     0     |   SYMBOL_END      |
    | SYMBOL_ESC + SYMBOL_ESC_ESC   |     0     |   SYMBOL_ESC      |
    | SYMBOL_END                    |     1     |       'b0         |
    | any other                     |     0     |   input symbol    |
    +-------------------------------+-----------+-------------------+

NOTE: when the module sees SYMBOL_ESC, it consumes it without emitting any
symbol and enables a special un-escape mode for the next symbol. If the
next symbol is ESC_END or ESC_ESC, the module emits END or ESC and
terminates the un-escape mode. If the symbol is not one of those two, the
module processes it normally as though un-escape mode was not enabled.
The consequence of this is a peculiar way of handling erroneous escapes,
e.g. SYMBOL_ESC + SYMBOL_ESC + SYMBOL_ESC + SYMBOL_ESC is treated as a single
SYMBOL_ESC. While SYMBOL_ESC + SYMBOL_END is treated as SYMBOL_END. This
also ensures that whenever SYMBOL_END occurs in the stream, it always
generates o_end, irrespective of preceding symbols.

This module is supposed to be used with streams produced by a complimentary
'slip_escaper' module.

****************************************************************************/

module slip_unescaper #(
    parameter SYMBOL_WIDTH = 32'd8,
    //
    parameter SYMBOL_END = 8'hC0,
    parameter SYMBOL_ESC = 8'hDB,
    parameter SYMBOL_ESC_END = 8'hDC,
    parameter SYMBOL_ESC_ESC = 8'hDD,
) (
    input i_clk,
    input i_rst,
    //
    input [SYMBOL_WIDTH-1:0] i_data,
    input i_valid,
    output o_ready,
    //
    output [SYMBOL_WIDTH-1:0] o_data,
    output o_end,
    output o_valid,
    input i_ready
);

    // xfer completion detection
    wire rx_ack;
    assign rx_ack = i_valid && o_ready;

    // Un-escape mode flag
    reg unescape;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            unescape <= 1'b0;
        end else begin
            if (rx_ack) begin
                // Unescape is set/kept only if we receive ESC.
                if (i_data == SYMBOL_ESC) begin
                    unescape <= 1'b1;
                end else begin
                    unescape <= 1'b0;
                end
            end
        end
    end

    // Stream handling
    reg rx_ready;
    reg [SYMBOL_WIDTH-1:0] tx_data;
    reg tx_valid;
    reg tx_end;

    always @(*) begin
        // Default handling - input connected to output, o_end=0
        rx_ready = i_ready;
        tx_data = i_data;
        tx_valid = i_valid;
        tx_end = 1'b0;

        // All other situations override parts of default logic
        if (unescape && i_data == SYMBOL_ESC_ESC) begin
            tx_data = SYMBOL_ESC;
        end else if (unescape && i_data == SYMBOL_ESC_END) begin
            tx_data = SYMBOL_END;
        end else if (i_data == SYMBOL_END) begin
            // Produce end
            tx_data = {SYMBOL_WIDTH{1'b0}};
            tx_end = 1'b1;
        end else if (i_data == SYMBOL_ESC) begin
            // Consume input, produce no output
            rx_ready = 1'b1;
            tx_valid = 1'b0;
        end
    end

    assign o_data = tx_data;
    assign o_valid = tx_valid;
    assign o_ready = rx_ready;
    assign o_end = tx_end;

endmodule
