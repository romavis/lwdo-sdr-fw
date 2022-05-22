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
    output o_mreq_wr,
    output [1:0] o_mreq_wsize,
    output o_mreq_aincr,
    output [7:0] o_mreq_size,
    output [31:0] o_mreq_addr
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
    localparam ST_RECV_OP = 4'd1;
    localparam ST_RECV_WCOUNT = 4'd2;
    localparam ST_RECV_A0 = 4'd3;
    localparam ST_RECV_A1 = 4'd4;
    localparam ST_RECV_A2 = 4'd5;
    localparam ST_RECV_A3 = 4'd6;
    localparam ST_RECV_CRC = 4'd7;
    localparam ST_ISSUE_MREQ = 4'd8;
    localparam ST_STALL = 4'd9;

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
            state_next = (i_rx_valid && i_rx_data == CMD_RX_START) ? ST_RECV_OP : state;
        ST_RECV_OP:
            state_next = i_rx_valid ? ST_RECV_WCOUNT : state;
        ST_RECV_WCOUNT:
            state_next = i_rx_valid ? ST_RECV_A0 : state;
        ST_RECV_A0:
            state_next = i_rx_valid ? ST_RECV_A1 : state;
        ST_RECV_A1:
            state_next = i_rx_valid ? ST_RECV_A2 : state;
        ST_RECV_A2:
            state_next = i_rx_valid ? ST_RECV_A3 : state;
        ST_RECV_A3:
            state_next = i_rx_valid ? ST_RECV_CRC : state;
        ST_RECV_CRC:
            if (i_rx_valid) begin
                state_next = ST_RECV_START;
                if (crc == 8'h00) begin
                    case(op)
                    CMD_OP_MREAD, CMD_OP_MWRITE:
                        state_next = ST_ISSUE_MREQ;
                    CMD_OP_STALL:
                        state_next = ST_STALL;
                    endcase
                end
            end
        ST_ISSUE_MREQ:
            state_next = i_mreq_ready ? ST_RECV_START : state;
        ST_STALL:
            ;   // do nothing, we'll sit here till we're reset
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
    // MREQ parameters cache
    //

    reg [2:0] op;
    reg mreq_aincr;
    reg [1:0] mreq_wsize;
    reg [7:0] mreq_size;
    reg [31:0] mreq_addr;

    //
    // Packet fields parser
    //

    always @(posedge i_clk) begin
        if (rx_ack) begin
            case (state)
            ST_RECV_OP: begin
                op <= i_rx_data[2:0];
                mreq_aincr <= i_rx_data[3];
                mreq_wsize <= i_rx_data[5:4];
            end
            ST_RECV_WCOUNT:
                mreq_size <= i_rx_data;
            ST_RECV_A0:
                mreq_addr[7:0] <= i_rx_data;
            ST_RECV_A1:
                mreq_addr[15:8] <= i_rx_data;
            ST_RECV_A2:
                mreq_addr[23:16] <= i_rx_data;
            ST_RECV_A3:
                mreq_addr[31:24] <= i_rx_data;
            endcase
        end
    end

    //
    // MREQ output
    //
    assign o_mreq_valid = (state == ST_ISSUE_MREQ) ? 1'b1 : 1'b0;
    assign o_mreq_wr = (op == CMD_OP_MWRITE) ? 1'b1 : 1'b0;
    assign o_mreq_wsize = mreq_wsize;
    assign o_mreq_aincr = mreq_aincr;
    assign o_mreq_size = mreq_size;
    assign o_mreq_addr = mreq_addr;

    //
    // Rx ready generator
    //
    assign o_rx_ready = (state != ST_ISSUE_MREQ && state != ST_STALL) ? 1'b1 : 1'b0;

    //
    // CRC error flag
    //
    assign o_err_crc = (state == ST_RECV_CRC && rx_ack && crc != 8'h00) ? 1'b1 : 1'b0;

endmodule