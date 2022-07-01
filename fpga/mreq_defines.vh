// MREQ - memory request descriptor.
// Represented in HW as a bitfield, structured as follows:
//  +------------+-------------+------------+-------+----+----------+
//  | ADDR[23:0] |  WCNT[7:0]  |  WFMT[2:0] | AINCR | WR | TAG[7:0] |
//  +------------+-------------+------------+-------+----+----------+
//

// TAG byte - arbitrary tag to identify transaction
localparam MREQ_TAG_OFS =       0;
localparam MREQ_TAG_NBIT =      8;
// WR bit - write/read selection
localparam MREQ_WR_OFS =        8;
localparam MREQ_WR_NBIT =       1;
// AINCR bit - enable automatic address increment
localparam MREQ_AINCR_OFS =     9;
localparam MREQ_AINCR_NBIT =    1;
// WFMT field - word format (see MREQ_WFMT_VAL_* for values)
localparam MREQ_WFMT_OFS =      10;
localparam MREQ_WFMT_NBIT =     3;
// WCNT field - word count (0 means 1 word, 255 means 256 words)
localparam MREQ_WCNT_OFS =      13;
localparam MREQ_WCNT_NBIT =     8;
// 24-bit ADDR field - starting bus address
localparam MREQ_ADDR_OFS =      21;
localparam MREQ_ADDR_NBIT =     24;
// total number of bits
localparam MREQ_NBIT =          45;

localparam MREQ_WFMT_ZERO = 3'b000;
localparam MREQ_WFMT_32S0 = 3'b001;
localparam MREQ_WFMT_16S0 = 3'b010;
localparam MREQ_WFMT_16S1 = 3'b011;
localparam MREQ_WFMT_8S0 =  3'b100;
localparam MREQ_WFMT_8S1 =  3'b101;
localparam MREQ_WFMT_8S2 =  3'b110;
localparam MREQ_WFMT_8S3 =  3'b111;


task unpack_mreq (
    //
    input [MREQ_NBIT-1:0] mreq,
    //
    output [MREQ_TAG_NBIT-1:0] tag,
    output wr,
    output aincr,
    output [MREQ_WFMT_NBIT-1:0] wfmt,
    output [MREQ_WCNT_NBIT-1:0] wcnt,
    output [MREQ_ADDR_NBIT-1:0] addr
);

    begin
        tag = mreq[MREQ_TAG_OFS+:MREQ_TAG_NBIT];
        wr = mreq[MREQ_WR_OFS];
        aincr = mreq[MREQ_AINCR_OFS];
        wfmt = mreq[MREQ_WFMT_OFS+:MREQ_WFMT_NBIT];
        wcnt = mreq[MREQ_WCNT_OFS+:MREQ_WCNT_NBIT];
        addr = mreq[MREQ_ADDR_OFS+:MREQ_ADDR_NBIT];
    end
endtask

function [MREQ_NBIT-1:0] pack_mreq(
    input [MREQ_TAG_NBIT-1:0] tag,
    input wr,
    input aincr,
    input [MREQ_WFMT_NBIT-1:0] wfmt,
    input [MREQ_WCNT_NBIT-1:0] wcnt,
    input [MREQ_ADDR_NBIT-1:0] addr
);

    begin
        pack_mreq[MREQ_TAG_OFS+:MREQ_TAG_NBIT] = tag;
        pack_mreq[MREQ_WR_OFS] = wr;
        pack_mreq[MREQ_AINCR_OFS] = aincr;
        pack_mreq[MREQ_WFMT_OFS+:MREQ_WFMT_NBIT] = wfmt;
        pack_mreq[MREQ_WCNT_OFS+:MREQ_WCNT_NBIT] = wcnt;
        pack_mreq[MREQ_ADDR_OFS+:MREQ_ADDR_NBIT] = addr;
    end
endfunction
