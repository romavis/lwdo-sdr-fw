/****************************************************************************

                        ---- wbcon_rx ----

Module that looks for command sequences in incoming byte stream,
parses them and outputs parsed information as a "memory request" (MREQ),
which provides parameters to wbcon_exec for performing Wishbone transaction.

Command parcel format:

  +-----+----------+----+----------+---------+-----+---------+---------+
  | CMD | COUNT[0] | .. | COUNT[m] | ADDR[0] | ... | ADDR[n] | BODY... |
  +-----+----------+----+----------+---------+-----+---------+---------+

CMD is one of:
  0xA1 - write, fixed address
  0xA2 - read, fixed address
  0xA3 - write, address is auto-incremented
  0xA4 - read, address is auto-incremented

COUNT
  Little-endian, specifies number of _words_ in transaction minus 1. Thus:
    COUNT=0 means transfer 1 word,
    COUNT=5 means transfer 6 words, etc.

ADDR
  Little-endian, specifies starting _word address_ of a transaction. With
  32-bit data Wishbone bus, that's an "index" of a 32-bit _word_, and a
  "usual" byte address is (ADDR*4). Thus:
    ADDR=0 means read/write bytes with addresses 0,1,2,3...
    ADDR=3 means read/write bytes with addresses 12,13,14,15...

  NOTE: wbcon_exec can perform only aligned full-word transfers.

BODY
  All the bytes of incoming stream following header and prior to MREQ
  acknowledgment are made available via o_body_data stream.
  For write transactions, wbcon_exec uses those bytes as data to be written
  on the Wishbone bus. The number of bytes consumed is 4*(COUNT+1), they
  represent bus words stored in little-endian order.
  Read transactions consume no BODY bytes.

****************************************************************************/

module wbcon_rx #(
    parameter ADDR_WIDTH = 10, // address field width
    parameter COUNT_WIDTH = 8  // count field width
) (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Rx command byte stream
    input [7:0] i_rx_data,
    input i_rx_valid,
    output o_rx_ready,
    // Packet body stream
    output [7:0] o_body_data,
    output o_body_valid,
    input i_body_ready,
    // Memory request output
    output o_mreq_valid,
    input i_mreq_ready,
    output [ADDR_WIDTH-1:0] o_mreq_addr,
    output [COUNT_WIDTH-1:0] o_mreq_cnt,
    output o_mreq_wr,
    output o_mreq_aincr
);

    // Numbers of bytes in the header (count & addr fields)
    localparam NBYTES_CNT = (COUNT_WIDTH + 7) / 8;
    localparam NBYTES_ADDR = (ADDR_WIDTH + 7) / 8;
    localparam BCNT_WIDTH = $clog2(NBYTES_CNT > NBYTES_ADDR ? NBYTES_CNT :
                                                              NBYTES_ADDR);

    // Start bytes (commands) that generate MREQ
    localparam CMD_WR_FIXED = 8'hA1;    // write with fixed address
    localparam CMD_RD_FIXED = 8'hA2;    // read with fixed address
    localparam CMD_WR_AINCR = 8'hA3;    // write with address auto-increment
    localparam CMD_RD_AINCR = 8'hA4;    // read with address auto-increment

    // SysCon
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // Stream completion flags
    wire rx_ack, mreq_ack;
    assign rx_ack = i_rx_valid && o_rx_ready;
    assign mreq_ack = o_mreq_valid && i_mreq_ready;

    // State machine
    reg [1:0] state;
    reg [1:0] state_next;
    wire state_change;
    assign state_change = (state != state_next);

    localparam ST_RECV_CMD = 2'd0;
    localparam ST_RECV_CNT = 2'd1;
    localparam ST_RECV_ADDR = 2'd2;
    localparam ST_ISSUE_MREQ = 2'd3;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= ST_RECV_CMD;
        else
            state <= state_next;
    end

    always @(*) begin
        state_next = state;

        case (state)
        ST_RECV_CMD:
            if (rx_ack) case (i_rx_data)
            CMD_WR_FIXED, CMD_WR_AINCR, CMD_RD_FIXED, CMD_RD_AINCR:
                state_next = ST_RECV_CNT;
            endcase
        ST_RECV_CNT:
            if (rx_ack && !bcnt) state_next = ST_RECV_ADDR;
        ST_RECV_ADDR:
            if (rx_ack && !bcnt) state_next = ST_ISSUE_MREQ;
        ST_ISSUE_MREQ:
            if (mreq_ack) state_next = ST_RECV_CMD;
        endcase
    end

    // Byte counter & byte index (for cnt & addr command fields)
    reg [BCNT_WIDTH-1:0] bcnt;
    reg [BCNT_WIDTH-1:0] bidx;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bcnt <= 0;
            bidx <= 0;
        end else begin
            if (state_change && state_next == ST_RECV_CNT) begin
                bcnt <= NBYTES_CNT - 1;
                bidx <= 0;
            end else if (state_change && state_next == ST_RECV_ADDR) begin
                bcnt <= NBYTES_ADDR - 1;
                bidx <= 0;
            end else if (bcnt && rx_ack) begin
                bcnt <= bcnt - 1'b1;
                bidx <= bidx + 1'b1;
            end
        end
    end

    // Store MREQ parameters
    reg [ADDR_WIDTH-1:0] mreq_addr;
    reg [COUNT_WIDTH-1:0] mreq_cnt;
    reg mreq_wr;
    reg mreq_aincr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mreq_addr <= 0;
            mreq_cnt <= 0;
            mreq_wr <= 0;
            mreq_aincr <= 0;
        end else if (rx_ack) case (state)
        ST_RECV_CMD:
            case (i_rx_data)
            CMD_WR_FIXED: begin
                mreq_wr <= 1'b1;
                mreq_aincr <= 1'b0;
            end
            CMD_WR_AINCR: begin
                mreq_wr <= 1'b1;
                mreq_aincr <= 1'b1;
            end
            CMD_RD_FIXED: begin
                mreq_wr <= 1'b0;
                mreq_aincr <= 1'b0;
            end
            CMD_RD_AINCR: begin
                mreq_wr <= 1'b0;
                mreq_aincr <= 1'b1;
            end
            endcase
        ST_RECV_CNT:
            mreq_cnt[8*bidx +: 8] <= i_rx_data;
        ST_RECV_ADDR:
            mreq_addr[8*bidx +: 8] <= i_rx_data;
        endcase
    end

    // MREQ output
    assign o_mreq_valid = (state == ST_ISSUE_MREQ);
    assign o_mreq_addr = mreq_addr;
    assign o_mreq_cnt = mreq_cnt;
    assign o_mreq_aincr = mreq_aincr;
    assign o_mreq_wr = mreq_wr;

    // Packet body stream output
    assign o_body_data = i_rx_data;
    assign o_body_valid = (state == ST_ISSUE_MREQ) && i_rx_valid;

    // Rx stream
    assign o_rx_ready = (state == ST_ISSUE_MREQ) ? i_body_ready : 1'b1;

endmodule
