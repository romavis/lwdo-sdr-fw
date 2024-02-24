/****************************************************************************

                        ---- slip_escaper ----

Stream escaper inspired by SLIP protocol.
See: https://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol

The idea is that we define 4 symbols:
    SYMBOL_END
    SYMBOL_ESC
    SYMBOL_ESC_END
    SYMBOL_ESC_ESC

The input to the module is an AXIS-like stream of symbols, where data is
augmented with an extra 'i_end' bit. The output is an AXIS-like stream of
symbols same width as at the input, but without 'i_end' bit.

Working of the module can be summarized by the table:
    +-------------------+-----------+-------------------------------+
    |   Input symbol    |   i_end   |   Emitted symbols             |
    +-------------------+-----------+-------------------------------+
    |       ignored     |     1     |       SYMBOL_END              |
    +-------------------+-----------+-------------------------------+
    |   SYMBOL_END      |           | SYMBOL_ESC, SYMBOL_ESC_END    |
    |   SYMBOL_ESC      |     0     | SYMBOL_ESC, SYMBOL_ESC_ESC    |
    |    any other      |           |    input symbol as-is         |
    +-------------------+-----------+-------------------------------+

Care should be taken when defining SYMBOL_* values. In general, all four
symbols should be different, e.g.:
    SYMBOL_END     = 0xAA
    SYMBOL_ESC      = 0xBB
    SYMBOL_ESC_END = 0x01
    SYMBOL_ESC_ESC  = 0x02

With such choice of values the outgoing stream will have a nice property:
SYMBOL_END can be observed in it if and only if it corresponds to a
transmission of a ender (i_end=1). This allows SYMBOL_END to also be used
for a secondary purpose of receiver synchronization when the stream
is used to transmit framed data (e.g. resynchronization that occurs after
losing an unknown number of symbols from the stream).

Stream escaped by this module can be un-escaped by a complementary
'slip_unescaper' module.

****************************************************************************/

module slip_escaper #(
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
    input i_end,
    input i_valid,
    output o_ready,
    //
    output [SYMBOL_WIDTH-1:0] o_data,
    output o_valid,
    input i_ready
);

    // xfer completion detection
    wire sent;
    assign sent = o_valid && i_ready;

    // Output stream routing FSM
    reg [1:0] route;
    reg [1:0] route_next;

    // send symbol from input stream either as-is,
    // or substitute it with END or ESC
    localparam ROUTE_NORMAL = 2'd0;
    // pause input stream, send ESC_ESC symbol
    localparam ROUTE_ESC_ESC = 2'd1;
    // pause input stream, send ESC_END symbol
    localparam ROUTE_ESC_END = 2'd2;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            route <= ROUTE_NORMAL;
        end else begin
            route <= route_next;
        end
    end

    always @(*) begin
        route_next = route;

        case (route)
            ROUTE_NORMAL: begin
                // if s_end_i==1, then input stream data is simply discarded,
                // even when it specifies escapable symbol
                if (sent && !i_end) begin
                    case (i_data)
                        SYMBOL_ESC: route_next = ROUTE_ESC_ESC;
                        SYMBOL_END: route_next = ROUTE_ESC_END;
                    endcase
                end
            end

            ROUTE_ESC_ESC,
            ROUTE_ESC_END: begin
                // after sending any of those escape codes, return to normal
                if (sent) begin
                    route_next = ROUTE_NORMAL;
                end
            end
        endcase
    end

    // Stream handling
    reg s_ready_reg;
    reg [SYMBOL_WIDTH-1:0] m_data_reg;
    reg m_valid_reg;

    always @(*) begin
        s_ready_reg = 1'b0;
        m_data_reg = {SYMBOL_WIDTH{1'b0}};
        m_valid_reg = 1'b0;

        case(route)
            ROUTE_NORMAL: begin
                s_ready_reg = i_ready;
                m_valid_reg = i_valid;
                // Send incoming symbol as-is or substitute it
                m_data_reg = i_data;
                if (i_end) begin
                    m_data_reg = SYMBOL_END;
                end
                else
                if (i_data == SYMBOL_ESC|| i_data == SYMBOL_END) begin
                    m_data_reg = SYMBOL_ESC;
                end
            end

            ROUTE_ESC_ESC: begin
                m_valid_reg = 1'b1;
                m_data_reg = SYMBOL_ESC_ESC;
            end

            ROUTE_ESC_END: begin
                m_valid_reg = 1'b1;
                m_data_reg = SYMBOL_ESC_END;
            end
        endcase
    end

    assign o_data = m_data_reg;
    assign o_valid = m_valid_reg;
    assign o_ready = s_ready_reg;

endmodule
