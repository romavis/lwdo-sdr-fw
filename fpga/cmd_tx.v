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
    input i_mreq_wr,
    input [1:0] i_mreq_wsize,
    input i_mreq_aincr,
    input [7:0] i_mreq_wcount,
    input [31:0] i_mreq_addr
);

    `include "cmd_defines.vh"

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
    reg [3:0] state;
    reg [3:0] state_next;
    wire state_change;
    assign state_change = (state != state_next) ? 1'b1 : 1'b0;

    localparam ST_IDLE = 4'd0;
    localparam ST_SEND_START = 4'd1;
    localparam ST_SEND_OP = 4'd2;
    localparam ST_SEND_WCOUNT = 4'd3;
    localparam ST_SEND_A0 = 4'd4;
    localparam ST_SEND_A1 = 4'd5;
    localparam ST_SEND_A2 = 4'd6;
    localparam ST_SEND_A3 = 4'd7;
    localparam ST_SEND_CRC = 4'd8;

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
            state_next = tx_ack ? ST_SEND_OP : state;
        ST_SEND_OP:
            state_next = tx_ack ? ST_SEND_WCOUNT : state;
        ST_SEND_WCOUNT:
            state_next = tx_ack ? ST_SEND_A0 : state;
        ST_SEND_A0:
            state_next = tx_ack ? ST_SEND_A1 : state;
        ST_SEND_A1:
            state_next = tx_ack ? ST_SEND_A2 : state;
        ST_SEND_A2:
            state_next = tx_ack ? ST_SEND_A3 : state;
        ST_SEND_A3:
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

    reg r_mreq_wr;
    reg r_mreq_aincr;
    reg [1:0] r_mreq_wsize;
    reg [7:0] r_mreq_wcount;
    reg [31:0] r_mreq_addr;

    always @(posedge i_clk) begin
        if (state == ST_IDLE && state_change) begin
            r_mreq_wr <= i_mreq_wr;
            r_mreq_aincr <= i_mreq_aincr;
            r_mreq_wsize <= i_mreq_wsize;
            r_mreq_wcount <= i_mreq_wcount;
            r_mreq_addr <= i_mreq_addr;
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
        ST_SEND_OP: begin
            tx_data = 8'd0;
            tx_data[2:0] = r_mreq_wr ? CMD_OP_MWRITE : CMD_OP_MREAD;
            tx_data[3] = r_mreq_aincr;
            tx_data[5:4] = r_mreq_wsize;
        end
        ST_SEND_WCOUNT:
            tx_data = r_mreq_wcount;
        ST_SEND_A0:
            tx_data = r_mreq_addr[7:0];
        ST_SEND_A1:
            tx_data = r_mreq_addr[15:8];
        ST_SEND_A2:
            tx_data = r_mreq_addr[23:16];
        ST_SEND_A3:
            tx_data = r_mreq_addr[31:24];
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