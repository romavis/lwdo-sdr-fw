/****************************************************************************

                        ---- slip_framer ----

Stream framer inspired by SLIP protocol.
See: https://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol

Allows to multiplex output stream between two input streams:
- Data symbols stream
- Header symbols stream
and feed their data to the output stream using 'slip_escaper'. Beginning
of header transmissions is indicated by SYMBOL_MARK.

This module normally forwards input data to the output through a
'slip_escaper'. However, whenever there is data available from the header
input, the module tells 'slip_escaper' to emit SYMBOL_MARK, after which
it begins transmitting data from the header input stream. It continues
so until header stream indicates the last symbol of the header using 'last'
flag. When the last symbol of the header is transmitted, the module returns
to transmitting data symbols. The module supports following corner cases:
- Transmission of empty header. This is indicated via a 'null' flag - in
  this case 'last' flag is ignored.
- Transmission of a header immediately following another header without
  in-between data.

Output stream thus may look like follows:

 --DATA-DATA-DATA-MARK-HDR----HDR------MARK-HDR-HDR-HDR-DATA-DATA-DATA-DATA
                  ^           ^        ^            ^
            hdr_vld      hdr_last   hdr_vld    hdr_last

****************************************************************************/

module slip_framer #(
    parameter SYMBOL_WIDTH = 32'd8,
    //
    parameter SYMBOL_MARK = 8'hC0,
    parameter SYMBOL_ESC = 8'hDB,
    parameter SYMBOL_ESC_MARK = 8'hDC,
    parameter SYMBOL_ESC_ESC = 8'hDD,
) (
    input clk,
    input rst,
    // data input
    input [SYMBOL_WIDTH-1:0] i_dat_data,
    input i_dat_valid,
    output o_dat_ready,
    // header input with framing
    input [SYMBOL_WIDTH-1:0] i_hdr_data,
    input i_hdr_null,
    input i_hdr_last,
    input i_hdr_valid,
    output o_hdr_ready,
    //
    output [SYMBOL_WIDTH-1:0] o_data,
    output o_valid,
    input i_ready
);

    // xfer completion detection
    wire sent;
    assign sent = o_valid && i_ready;

    reg [SYMBOL_WIDTH-1:0] tx_data;
    reg tx_mark;
    reg tx_valid;
    wire tx_ready;
    reg dat_ready;
    reg hdr_ready;

    // Whether we're currently transmitting symbols of header
    reg in_header;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_header <= 1'b0;
        end else if (sent) begin
            if (in_header) begin
                // Header's last symbol is transmitted.
                // NOTE: it may be immediately followed by a new header
                // symbol - we will then transmit MARK, and that mechanism
                // does not need in_header to be set (it will be set if needed
                // while transmitting MARK).
                if (i_hdr_last) begin
                    in_header <= 1'b0;
                end
            end else begin
                // Beginning transmission of non-null header. This means that
                // in this cycle we've transmitted MARK, and now we'll
                // begin transmitting actual symbols.
                if (i_hdr_valid && !i_hdr_null) begin
                    in_header <= 1'b1;
                end
            end
        end
    end

    always @(*) begin
        dat_ready = 1'b0;
        hdr_ready = 1'b0;
        tx_valid = 1'b0;
        tx_mark = 1'b0;
        tx_data = {SYMBOL_WIDTH{1'b0}};

        if (in_header) begin
            // Transmitting header bytes
            hdr_ready = tx_ready;
            tx_valid = i_hdr_valid;
            tx_data = i_hdr_data;
        end else if (i_hdr_valid) begin
            // Transmit MARK (beginning of header)
            tx_valid = 1'b1;
            tx_mark = 1'b1;
            // If the header is empty, acknowledge transmission just with MARK
            // since there will be no symbols besides MARK transmitted for
            // this header. 'in_header' won't be set either.
            if (i_hdr_null) begin
                hdr_ready = tx_ready;
            end
        end else begin
            // Transmit normal data
            dat_ready = tx_ready;
            tx_valid = i_dat_valid;
            tx_data = i_dat_data;
        end
    end

    assign o_dat_ready = dat_ready;
    assign o_hdr_ready = hdr_ready;

    slip_escaper #(
        .SYMBOL_WIDTH(SYMBOL_WIDTH),
        .SYMBOL_MARK(SYMBOL_MARK),
        .SYMBOL_ESC(SYMBOL_ESC),
        .SYMBOL_ESC_MARK(SYMBOL_ESC_MARK),
        .SYMBOL_ESC_ESC(SYMBOL_ESC_ESC)
    ) u_escaper (
        .clk(clk),
        .rst(rst),
        //
        .i_data(tx_data),
        .i_mark(tx_mark),
        .i_valid(tx_valid),
        .o_ready(tx_ready),
        //
        .o_data(o_data),
        .o_valid(o_valid),
        .i_ready(i_ready)
    );

endmodule
