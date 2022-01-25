// vim: ts=4 sw=4 expandtab

// THIS IS GENERATED VERILOG CODE.
// https://bues.ch/h/crcgen
// 
// This code is Public Domain.
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted.
// 
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
// RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
// NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE
// USE OR PERFORMANCE OF THIS SOFTWARE.

`ifndef CRC8_V_
`define CRC8_V_

// CRC polynomial coefficients: x^8 + x^2 + x + 1
//                              0x7 (hex)
// CRC width:                   8 bits
// CRC shift direction:         left (big endian)
// Input word width:            8 bits

module crc8 (
    input [7:0] i_crc,
    input [7:0] i_data,
    output [7:0] o_crc
);
    assign o_crc[0] = (i_crc[0] ^ i_crc[6] ^ i_crc[7] ^ i_data[0] ^ i_data[6] ^ i_data[7]);
    assign o_crc[1] = (i_crc[0] ^ i_crc[1] ^ i_crc[6] ^ i_data[0] ^ i_data[1] ^ i_data[6]);
    assign o_crc[2] = (i_crc[0] ^ i_crc[1] ^ i_crc[2] ^ i_crc[6] ^ i_data[0] ^ i_data[1] ^ i_data[2] ^ i_data[6]);
    assign o_crc[3] = (i_crc[1] ^ i_crc[2] ^ i_crc[3] ^ i_crc[7] ^ i_data[1] ^ i_data[2] ^ i_data[3] ^ i_data[7]);
    assign o_crc[4] = (i_crc[2] ^ i_crc[3] ^ i_crc[4] ^ i_data[2] ^ i_data[3] ^ i_data[4]);
    assign o_crc[5] = (i_crc[3] ^ i_crc[4] ^ i_crc[5] ^ i_data[3] ^ i_data[4] ^ i_data[5]);
    assign o_crc[6] = (i_crc[4] ^ i_crc[5] ^ i_crc[6] ^ i_data[4] ^ i_data[5] ^ i_data[6]);
    assign o_crc[7] = (i_crc[5] ^ i_crc[6] ^ i_crc[7] ^ i_data[5] ^ i_data[6] ^ i_data[7]);
endmodule

`endif // CRC8_V_