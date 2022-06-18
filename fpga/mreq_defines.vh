// `ifndef MREQ_DEFINES_VH_
// `define MREQ_DEFINES_VH_

// MREQ - memory request descriptor.
// Represented in HW as a 44-bit wide bitfield, structured as follows:
//  +------------+-------------+------------+-------+----+
//  | ADDR[31:0] | WCOUNT[7:0] | WSIZE[1:0] | AINCR | WR |
//  +------------+-------------+------------+-------+----+
//

// WR bit - write/read selection
localparam MREQ_WR_OFS =        0;
localparam MREQ_WR_NBIT =       1;
// AINCR bit - enable automatic address increment
localparam MREQ_AINCR_OFS =     1;
localparam MREQ_AINCR_NBIT =    1;
// WSIZE field - word size (see MREQ_WSIZE_VAL_* for encoding)
localparam MREQ_WSIZE_OFS =     2;
localparam MREQ_WSIZE_NBIT =    2;
// WCOUNT field - word count (0 means 1 word, 255 means 256 words)
localparam MREQ_WCOUNT_OFS =    4;
localparam MREQ_WCOUNT_NBIT =   8;
// 32-bit ADDR field - starting bus address
localparam MREQ_ADDR_OFS =      12;
localparam MREQ_ADDR_NBIT =     32;
// total number of bits
localparam MREQ_NBIT =          44;

localparam MREQ_WSIZE_VAL_1BYTE =    2'd0;
localparam MREQ_WSIZE_VAL_2BYTE =    2'd1;
localparam MREQ_WSIZE_VAL_4BYTE =    2'd2;


task unpack_mreq (
    //
    input [MREQ_NBIT-1:0] mreq,
    //
    output wr,
    output aincr,
    output [MREQ_WSIZE_NBIT-1:0] wsize,
    output [MREQ_WCOUNT_NBIT-1:0] wcount,
    output [MREQ_ADDR_NBIT-1:0] addr
);

    begin
        wr = mreq[MREQ_WR_OFS];
        aincr = mreq[MREQ_AINCR_OFS];
        wsize = mreq[MREQ_WSIZE_OFS+MREQ_WSIZE_NBIT-1:MREQ_WSIZE_OFS];
        wcount = mreq[MREQ_WCOUNT_OFS+MREQ_WCOUNT_NBIT-1:MREQ_WCOUNT_OFS];
        addr = mreq[MREQ_ADDR_OFS+MREQ_ADDR_NBIT-1:MREQ_ADDR_OFS];
    end
endtask

// task pack_mreq (
//     //
//     output [MREQ_NBIT-1:0] mreq,
//     //
//     input wr,
//     input aincr,
//     input [MREQ_WSIZE_NBIT-1:0] wsize,
//     input [MREQ_WCOUNT_NBIT-1:0] wcount,
//     input [MREQ_ADDR_NBIT-1:0] addr
// );

//     begin
//         mreq[MREQ_WR_OFS] = wr;
//         mreq[MREQ_AINCR_OFS] = aincr;
//         mreq[MREQ_WSIZE_OFS+MREQ_WSIZE_NBIT-1:MREQ_WSIZE_OFS] = wsize;
//         mreq[MREQ_WCOUNT_OFS+MREQ_WCOUNT_NBIT-1:MREQ_WCOUNT_OFS] = wcount;
//         mreq[MREQ_ADDR_OFS+MREQ_ADDR_NBIT-1:MREQ_ADDR_OFS] = addr;
//     end
// endtask

function [MREQ_NBIT-1:0] pack_mreq(
    input wr,
    input aincr,
    input [MREQ_WSIZE_NBIT-1:0] wsize,
    input [MREQ_WCOUNT_NBIT-1:0] wcount,
    input [MREQ_ADDR_NBIT-1:0] addr
);

    begin
        pack_mreq[MREQ_WR_OFS] = wr;
        pack_mreq[MREQ_AINCR_OFS] = aincr;
        pack_mreq[MREQ_WSIZE_OFS+MREQ_WSIZE_NBIT-1:MREQ_WSIZE_OFS] = wsize;
        pack_mreq[MREQ_WCOUNT_OFS+MREQ_WCOUNT_NBIT-1:MREQ_WCOUNT_OFS] = wcount;
        pack_mreq[MREQ_ADDR_OFS+MREQ_ADDR_NBIT-1:MREQ_ADDR_OFS] = addr;
    end
endfunction
// `endif  // MREQ_DEFINES_VH_
