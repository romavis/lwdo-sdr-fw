module cmd_tx (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Output byte stream
    output [7:0] o_tx_data,
    output o_tx_valid,
    input i_tx_ready,
    // MREQ bus
    input i_mreq_valid,
    output o_mreq_ready,
    input [MREQ_NBIT-1:0] i_mreq
);

    `include "cmd_defines.vh"
    `include "mreq_defines.vh"

    //  ----------------
    //  Response message
    //  ----------------
    //
    //  Header [Data] Header [Data] ... Header [Data] ...
    //
    //  Header is always 5 bytes:
    //      byte 0 - START  - constant 0xA5
    //      byte 1 - DSC    - see below
    //      byte 2 - TAG    - specifies transaction tag
    //      byte 3 - WCOUNT - word_count
    //      byte 4 - CRC    - CRC8 computed over previous 7 bytes of header
    //
    //  DSC byte encoding:
    //      DSC[7:2] - not used, should be ignored by client
    //      DSC[1:0] - wsz, data word size indicator
    //
    //      wsz has following values:
    //          0b00 - no data payload
    //          0b01 - 8-bit words. Number of data bytes: WCOUNT+1
    //          0b10 - 16-bit words. Number of data bytes: 2*(WCOUNT+1)
    //          0b11 - 32-bit words. Number of data bytes: 4*(WCOUNT+1)


    //
    // SysCon
    //
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    //
    // Tx stream success flag
    //
    wire tx_ack;
    assign tx_ack = i_tx_ready && o_tx_valid;

    //
    // State machine
    //
    reg [2:0] state;
    reg [2:0] state_next;
    wire state_change;
    assign state_change = (state != state_next) ? 1'b1 : 1'b0;

    localparam ST_IDLE = 3'd0;
    localparam ST_SEND_START = 3'd1;
    localparam ST_SEND_DSC = 3'd2;
    localparam ST_SEND_TAG = 3'd3;
    localparam ST_SEND_WCNT = 3'd4;
    localparam ST_SEND_CRC = 3'd5;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;

        case (state)
        ST_IDLE:
            state_next = i_mreq_valid ? ST_SEND_START : state;
        ST_SEND_START:
            state_next = tx_ack ? ST_SEND_DSC : state;
        ST_SEND_DSC:
            state_next = tx_ack ? ST_SEND_TAG : state;
        ST_SEND_TAG:
            state_next = tx_ack ? ST_SEND_WCNT : state;
        ST_SEND_WCNT:
            state_next = tx_ack ? ST_SEND_CRC : state;
        ST_SEND_CRC:
            state_next = tx_ack ? ST_IDLE : state;
        default:
            state_next = ST_IDLE;
        endcase
    end

    //
    // CRC engine
    //
    reg [7:0] crc_prev;
    wire [7:0] crc_in;
    wire [7:0] crc;

    crc8 crc_eng (
        .i_data(tx_data),
        .i_crc(crc_in),
        .o_crc(crc)
    );

    always @(posedge clk) begin
        if (tx_ack) begin
            crc_prev <= crc;
        end
    end

    assign crc_in = (state == ST_SEND_START) ? 8'd0 : crc_prev;

    //
    // MREQ parameters cache
    //

    reg [7:0] r_mreq_tag;
    reg r_mreq_wr;
    reg r_mreq_aincr;
    reg [2:0] r_mreq_wfmt;
    reg [7:0] r_mreq_wcnt;
    reg [23:0] r_mreq_addr;

    always @(posedge i_clk) begin
        if (state == ST_IDLE && state_change) begin
            unpack_mreq(
                i_mreq,
                r_mreq_tag, r_mreq_wr, r_mreq_aincr, r_mreq_wfmt, r_mreq_wcnt, r_mreq_addr
                );
        end
    end

    //
    // Encode WSZ field
    //
    reg [1:0] wsz;
    always @(*) begin
        wsz = 2'b00;
        if (!r_mreq_wr) begin
            case (r_mreq_wfmt)
            MREQ_WFMT_32S0: wsz = 2'b11;

            MREQ_WFMT_16S0,
            MREQ_WFMT_16S1: wsz = 2'b10;

            MREQ_WFMT_8S0,
            MREQ_WFMT_8S1,
            MREQ_WFMT_8S2,
            MREQ_WFMT_8S3: wsz = 2'b01;
            endcase
        end
    end

    //
    // Tx data & valid driver
    //
    reg [7:0] tx_data;
    reg tx_valid;

    assign o_tx_data = tx_data;
    assign o_tx_valid = tx_valid;

    always @(*) begin
        tx_valid = 1'b1;

        case (state)
        ST_SEND_START:
            tx_data = CMD_TX_START;
        ST_SEND_DSC: begin
            tx_data = 8'd0;
            tx_data[1:0] = wsz;
        end
        ST_SEND_TAG:
            tx_data = r_mreq_tag;
        ST_SEND_WCNT:
            tx_data = r_mreq_wcnt;
        ST_SEND_CRC:
            tx_data = crc_in;
        default: begin
            tx_data = 8'd0;
            tx_valid = 1'b0;
        end
        endcase
    end

    //
    // MREQ READY driver
    //
    assign o_mreq_ready = (state == ST_SEND_CRC && state_next == ST_IDLE && tx_ack) ? 1'b1 : 1'b0;

endmodule
