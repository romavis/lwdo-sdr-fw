/****************************************************************************

                        ---- word_ser ----

Module that receives words via AXIStream-like interface and serializes them
into bytes transmitted over AXIStream-like interface.

****************************************************************************/

module word_ser #(
    parameter WORD_BITS = 32
) (
    input i_clk,
    input i_rst,
    //
    input [WORD_BITS-1:0] i_data,
    input i_valid,
    output o_ready,
    //
    output [7:0] o_data,
    output o_valid,
    input i_ready
);

    localparam NBYTES = (WORD_BITS + 7) / 8;
    localparam NBYTES_BITS = $clog2(NBYTES);

    wire clk = i_clk;
    wire rst = i_rst;

    wire in_ack = i_valid & o_ready;
    wire out_ack = o_valid & i_ready;

    reg [NBYTES_BITS-1:0] byte_idx;
    reg contains;
    reg [8*NBYTES-1:0] data;

    always @(posedge clk or posedge rst)
        if (rst) begin
            byte_idx <= 0;
            contains <= 1'b0;
        end else begin
            if (out_ack) begin
                // Send in little-endian order
                data <= data >> 8;
                if (byte_idx)
                    byte_idx <= byte_idx - 1'b1;
                else
                    contains <= 1'b0;
            end
            if (in_ack) begin
                byte_idx <= NBYTES - 1;
                contains <= 1'b1;
                data <= i_data;
            end
        end

    // control signals
    assign o_valid = contains;
    assign o_ready = contains ? (i_ready && !byte_idx) : 1'b1;
    assign o_data = data[7:0];

endmodule
