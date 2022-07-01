module cmd_rx (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Rx byte stream
    input [7:0] i_rx_data,
    input i_rx_valid,
    output o_rx_ready,
    // Error flags
    output o_err_crc,
    // MREQ output
    output o_mreq_valid,
    input i_mreq_ready,
    output [MREQ_NBIT-1:0] o_mreq
);

    `include "cmd_defines.vh"
    `include "mreq_defines.vh"

    // cmd_rx processes request packets.
    //
    //  Request stream format:
    //      Header [Data] Header [Data] ... Header [Data] ...
    //
    //  Header is always 8 bytes:
    //      byte 0 - START  - constant 0xA3
    //      byte 1 - DSC    - controls operation (see below)
    //      byte 2 - TAG    - specifies transaction tag
    //      byte 3 - WCNT   - word count
    //      byte 4 - A0     - bus_addr[7:0]
    //      byte 5 - A1     - bus_addr[15:8]
    //      byte 6 - A2     - bus_addr[23:16]
    //      byte 7 - CRC    - CRC8 computed over previous 7 bytes of header
    //
    //  DSC byte encoding:
    //      DSC[7]   - not used, should be 0
    //      DSC[6:4] - wfmt - word format
    //      DSC[3]   - aincr - enables address auto-increment
    //      DSC[2:1] - not used, should be 0
    //      DSC[0]   - wr_en - R/W selector
    //
    //      wfmt takes following values:
    //          WFMT_ZERO - 0b000 - invalid, do not use
    //          WFMT_32S0 - 0b001 - transfer 32 bit words,  byte mask: (3) ++++ (0)
    //          WFMT_16S0 - 0b010 - transfer 16 bit words,  byte mask: (3) --++ (0)
    //          WFMT_16S1 - 0b011 - transfer 16 bit words,  byte mask: (3) ++-- (0)
    //          WFMT_8S0 -  0b100 - transfer 8 bit words,   byte mask: (3) ---+ (0)
    //          WFMT_8S1 -  0b101 - transfer 8 bit words,   byte mask: (3) --+- (0)
    //          WFMT_8S2 -  0b110 - transfer 8 bit words,   byte mask: (3) -+-- (0)
    //          WFMT_8S3 -  0b111 - transfer 8 bit words,   byte mask: (3) +--- (0)
    //      (note: wishbone bus read is _always_ 32 bit, write accesses have byte select mask)
    //
    //      aincr:
    //          0 - transaction repeats specified number of word transfers to the same address
    //          1 - _bus_ address is incremented by 1 after each transfer
    //
    //      wr_en:
    //          0 - transaction is reading data from bus to control port, packet contains no data
    //          1 - transaction is writing data from control port to the bus, packet contains data
    //
    //  TAG:
    //      Arbitrary value provided by control host, it will be repeated by control port in the
    //      response header.
    //
    //  WCNT:
    //      Specifies number of _bus accesses_, minus 1. So WCNT=0 means 1 word,
    //      WCNT=1 means 2 words, .. WCNT=255 means 256 words.
    //      Size of the word is determined by wfmt.
    //
    //  A0,A1,A2:
    //      Specifies starting _bus address_ for transaction. This is the address of 32-bit word on the
    //      wishbone bus.
    //
    //  CRC:
    //      CRC8 computed over previous 7 bytes of header. For details, see `crc8.v` module
    //
    //  DATA:
    //      Data payload. Present only for write transactions.
    //      Number of data bytes is (WCOUNT+1)*WSIZE, where WSIZE is 1,2 or 4 depending on wfmt.
    //      Follows little-endian ordering within words.
    //

    //
    // SysCon
    //
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    //
    // Success flags
    //
    wire rx_ack;
    assign rx_ack = i_rx_valid && o_rx_ready;

    //
    // State machine
    //

    reg [3:0] state;
    reg [3:0] state_next;
    wire state_change;
    assign state_change = (state != state_next) ? 1'b1 : 1'b0;

    localparam ST_RECV_START = 4'd0;
    localparam ST_RECV_DSC = 4'd1;
    localparam ST_RECV_TAG = 4'd2;
    localparam ST_RECV_WCNT = 4'd3;
    localparam ST_RECV_A0 = 4'd4;
    localparam ST_RECV_A1 = 4'd5;
    localparam ST_RECV_A2 = 4'd6;
    localparam ST_RECV_CRC = 4'd7;
    localparam ST_ISSUE_MREQ = 4'd8;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_RECV_START;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;

        case (state)
        ST_RECV_START:
            state_next = (i_rx_valid && i_rx_data == CMD_RX_START) ? ST_RECV_DSC : state;
        ST_RECV_DSC:
            state_next = i_rx_valid ? ST_RECV_TAG : state;
        ST_RECV_TAG:
            state_next = i_rx_valid ? ST_RECV_WCNT : state;
        ST_RECV_WCNT:
            state_next = i_rx_valid ? ST_RECV_A0 : state;
        ST_RECV_A0:
            state_next = i_rx_valid ? ST_RECV_A1 : state;
        ST_RECV_A1:
            state_next = i_rx_valid ? ST_RECV_A2 : state;
        ST_RECV_A2:
            state_next = i_rx_valid ? ST_RECV_CRC : state;
        ST_RECV_CRC:
            if (i_rx_valid) begin
                state_next = ST_RECV_START;
                if (crc == 8'h00) state_next = ST_ISSUE_MREQ;
            end
        ST_ISSUE_MREQ:
            state_next = i_mreq_ready ? ST_RECV_START : state;
        default:
            state_next = ST_RECV_START;
        endcase
    end

    //
    // CRC engine
    //
    reg [7:0] crc_prev;
    wire [7:0] crc_in;
    wire [7:0] crc;

    crc8 crc_eng (
        .i_data(i_rx_data),
        .i_crc(crc_in),
        .o_crc(crc)
    );

    always @(posedge clk) begin
        if (rx_ack) begin
            crc_prev <= crc;
        end
    end

    assign crc_in = (state == ST_RECV_START) ? 8'd0 : crc_prev;

    //
    // Store header values
    //

    reg [7:0] hdr_dsc;
    reg [7:0] hdr_tag;
    reg [7:0] hdr_wcnt;
    reg [23:0] hdr_addr;

    always @(posedge i_clk) begin
        if (rx_ack) begin
            case (state)
            ST_RECV_DSC:
                hdr_dsc <= i_rx_data;
            ST_RECV_TAG:
                hdr_tag <= i_rx_data;
            ST_RECV_WCNT:
                hdr_wcnt <= i_rx_data;
            ST_RECV_A0:
                hdr_addr[7:0] <= i_rx_data;
            ST_RECV_A1:
                hdr_addr[15:8] <= i_rx_data;
            ST_RECV_A2:
                hdr_addr[23:16] <= i_rx_data;
            endcase
        end
    end

    //
    // MREQ output
    //
    assign o_mreq_valid = (state == ST_ISSUE_MREQ) ? 1'b1 : 1'b0;
    reg [MREQ_NBIT-1:0] mreq;
    assign o_mreq = mreq;

    always @(*) begin
        mreq = pack_mreq(
            hdr_tag,        // TAG
            hdr_dsc[0],     // WR
            hdr_dsc[3],     // AINCR
            hdr_dsc[6:4],   // WFMT
            hdr_wcnt,       // WCNT
            hdr_addr        // ADDR
        );
    end

    //
    // Rx ready generator
    //
    assign o_rx_ready = (state != ST_ISSUE_MREQ) ? 1'b1 : 1'b0;

    //
    // CRC error flag
    //
    assign o_err_crc = (state == ST_RECV_CRC && rx_ack && crc != 8'h00) ? 1'b1 : 1'b0;

endmodule
