/****************************************************************************

                        ---- wbcon_rx ----

Receives incoming AXI-S packets and translates them into WBCON commands.
Outputs the command via command bus and waits for it to be acknowledged
before receiving the next command.

====================== General packet format ======================

Command packet format:

  +-----+----------+
  | CMD | BODY...  |
  +-----+----------+

CMD is one of:
    0x21 - SET_ADDRESS
    0x22 - WRITE_WORD
    0x23 - READ_WORD

For each command packet, WBCON responds with a reply packet.

Reply packet format:

  +-----+----------+----------+
  | HDR | BODY...  | [STATUS] |
  +-----+----------+----------+

HDR is one of:
    0x80 - invalid command, command packet discarded
    0x81 - reply to SET_ADDRESS
    0x82 - reply to WRITE_WORD
    0x83 - reply to READ_WORD

STATUS is optional and can be one of:
    0x01 - successful execution
    0x02 - bus error
    0x03 - transaction aborted, retry

====================== SET_ADDRESS ======================

Command:

  +------+---------+---------+---------+---------+
  | 0x21 | ADDR[0] | ADDR[1] |   ...   | ADDR[n] |
  +------+---------+---------+---------+---------+

The width of HW_ADDR is fixed by the Wishbone bus. The width of ADDR
transmitted in the packet is variable.
The receiver begins with HW_ADDR equal to zero, and then fills its bytes with
ADDR bytes from the command, starting with the least-significant one. If some
byte of address has not been filled, it remains zero. If too many bytes are
present in the command, extra bytes are silently discarded.

Reply:

  +------+
  | 0x81 |
  +------+

====================== WRITE_WORD ======================

Command:

  +------+---------+---------+---------+---------+
  | 0x22 | DATA[0] | DATA[1] |   ...   | DATA[n] |
  +------+---------+---------+---------+---------+

The width of HW_DATA is fixed by the Wishbone bus. The width of DATA
transmitted in the packet is variable.
The receiver begins with HW_DATA equal to zero, and then fills its bytes with
DATA bytes from the command, starting with the least-significant one. If some
byte of word has not been filled, it remains zero. If too many bytes are
present in the command, extra bytes are silently discarded.

Reply:

  +------+--------+
  | 0x82 | STATUS |
  +------+--------+

WRITE_WORD reports status of bus transaction (according to ERR_I signal).

====================== READ_WORD ======================

Command:

  +------+
  | 0x23 |
  +------+

Reply:

  +------+---------+---------+---------+---------+--------+
  | 0x83 | DATA[0] | DATA[1] |   ...   | DATA[n] | STATUS |
  +------+---------+---------+---------+---------+--------+

The amount of DATA bytes is determined by the hardware and corresponds
to the bus width. In case of a failed bus transaction, the number of DATA
bytes can be different from that in the case of a normal bus transaction.

READ_WORD always reports status of the bus transaction.

====================== INVALID COMMAND ======================

Whenever an invalid command is received, all packet bytes are skipped, and
following reply is generated:

  +------+
  | 0x80 |
  +------+

****************************************************************************/

module wbcon_rx #(
    parameter HW_ADDR_WIDTH = 32'd16,
    parameter HW_DATA_WIDTH = 32'd16
) (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // AXI-S stream that carries encoded command packets
    input i_rx_axis_tvalid,
    output o_rx_axis_tready,
    input [7:0] i_rx_axis_tdata,
    input i_rx_axis_tkeep,
    input i_rx_axis_tlast,
    // Decoded command output with handshake
    output o_cmd_tvalid,
    input i_cmd_tready,
    output o_cmd_op_set_address,
    output o_cmd_op_write_word,
    output o_cmd_op_read_word,
    output [HW_ADDR_WIDTH-1:0] o_cmd_hw_addr,   // valid for op_set_address
    output [HW_DATA_WIDTH-1:0] o_cmd_hw_data    // valid for op_write_word
);

    localparam CMD_SET_ADDRESS = 8'h21;
    localparam CMD_WRITE_WORD = 8'h22;
    localparam CMD_READ_WORD = 8'h23;

    // Widths
    localparam HW_ADDR_NBYTES = (HW_ADDR_WIDTH + 7) / 8;
    localparam HW_DATA_NBYTES = (HW_DATA_WIDTH + 7) / 8;

    // ACKs
    wire rx_ack;
    wire cmd_ack;
    assign rx_ack = i_rx_axis_tvalid && o_rx_axis_tready;
    assign cmd_ack = o_cmd_tvalid && i_cmd_tready;

    // FSM
    localparam STATE_RECV_CMD = 3'd0;
    localparam STATE_SKIP_PACKET = 3'd1;
    localparam STATE_RECV_ADDR = 3'd2;
    localparam STATE_RECV_DATA = 3'd3;
    localparam STATE_AWAIT_COMPLETION = 3'd4;

    reg [2:0] state;
    reg [2:0] state_next;
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= STATE_RECV_CMD;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;

        case(state)
            STATE_RECV_CMD: begin
                if (rx_ack) begin
                    if (i_rx_axis_tkeep) begin
                        case(i_rx_axis_tdata)
                            CMD_SET_ADDRESS: begin
                                state_next = STATE_RECV_ADDR;
                            end
                            CMD_WRITE_WORD: begin
                                state_next = STATE_RECV_DATA;
                            end
                            CMD_READ_WORD: begin
                                state_next = STATE_SKIP_PACKET;
                            end
                            default: begin
                                state_next = STATE_SKIP_PACKET;
                            end
                        endcase
                    end
                    if (i_rx_axis_tlast) begin
                        if (i_rx_axis_tkeep) begin
                            // Received command code -> process it
                            state_next = STATE_AWAIT_COMPLETION;
                        end else begin
                            // Received empty packet -> discard it
                            state_next = STATE_RECV_CMD;
                        end
                    end
                    // If TLAST==TKEEP==0 then simply discard the symbol
                end
            end

            STATE_SKIP_PACKET,
            STATE_RECV_ADDR,
            STATE_RECV_DATA: begin
                if (rx_ack) begin
                    if (i_rx_axis_tlast) begin
                        state_next = STATE_AWAIT_COMPLETION;
                    end
                end
            end

            STATE_AWAIT_COMPLETION: begin
                if (cmd_ack) begin
                    state_next = STATE_RECV_CMD;
                end
            end
        endcase
    end

    // HW_ADDR
    reg [HW_ADDR_WIDTH-1:0] hw_addr_reg;
    reg [HW_ADDR_WIDTH-1:0] hw_addr_setmask_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            hw_addr_reg <= 1'b0;
            hw_addr_setmask_reg <= 8'hFF;
        end else begin
            if (state == STATE_RECV_CMD) begin
                hw_addr_reg <= 1'b0;
                hw_addr_setmask_reg <= 8'hFF;
            end else if (state == STATE_RECV_ADDR && rx_ack && i_rx_axis_tkeep) begin
                hw_addr_reg <= hw_addr_reg | (hw_addr_setmask_reg & {HW_ADDR_NBYTES{i_rx_axis_tdata}});
                hw_addr_setmask_reg <= hw_addr_setmask_reg << 32'd8;
            end
        end
    end

    // HW_DATA
    reg [HW_DATA_WIDTH-1:0] hw_data_reg;
    reg [HW_DATA_WIDTH-1:0] hw_data_setmask_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            hw_data_reg <= 1'b0;
            hw_data_setmask_reg <= 8'hFF;
        end else begin
            if (state == STATE_RECV_CMD) begin
                hw_data_reg <= 1'b0;
                hw_data_setmask_reg <= 8'hFF;
            end else if (state == STATE_RECV_DATA && rx_ack && i_rx_axis_tkeep) begin
                hw_data_reg <= hw_data_reg | (hw_data_setmask_reg & {HW_DATA_NBYTES{i_rx_axis_tdata}});
                hw_data_setmask_reg <= hw_data_setmask_reg << 32'd8;
            end
        end
    end

    // Operation selector decoding
    reg cmd_op_set_address_reg;
    reg cmd_op_read_word_reg;
    reg cmd_op_write_word_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cmd_op_set_address_reg <= 1'b0;
            cmd_op_read_word_reg <= 1'b0;
            cmd_op_write_word_reg <= 1'b0;
        end else begin
            if (state == STATE_RECV_CMD && rx_ack && i_rx_axis_tkeep) begin
                cmd_op_set_address_reg <= 1'b0;
                cmd_op_read_word_reg <= 1'b0;
                cmd_op_write_word_reg <= 1'b0;
                case(i_rx_axis_tdata)
                    CMD_SET_ADDRESS: begin
                        cmd_op_set_address_reg <= 1'b1;
                    end
                    CMD_WRITE_WORD: begin
                        cmd_op_write_word_reg <= 1'b1;
                    end
                    CMD_READ_WORD: begin
                        cmd_op_read_word_reg <= 1'b1;
                    end
                    // No default case, since if none of selectors is set,
                    // executor should consider it as an "invalid operation"
                endcase
            end
        end
    end

    // Stream flow control
    reg rx_axis_tready_reg;
    reg cmd_tvalid_reg;

    always @(*) begin
        rx_axis_tready_reg = 1'b0;
        cmd_tvalid_reg = 1'b0;
        case (state)
            STATE_AWAIT_COMPLETION: begin
                rx_axis_tready_reg = 1'b0;
                cmd_tvalid_reg = 1'b1;
            end

            default: begin
                rx_axis_tready_reg = 1'b1;
                cmd_tvalid_reg = 1'b0;
            end
        endcase
    end

    // Outputs
    assign o_rx_axis_tready = rx_axis_tready_reg;
    assign o_cmd_tvalid = cmd_tvalid_reg;
    assign o_cmd_op_set_address = cmd_op_set_address_reg;
    assign o_cmd_op_write_word = cmd_op_write_word_reg;
    assign o_cmd_op_read_word = cmd_op_read_word_reg;
    assign o_cmd_hw_addr = hw_addr_reg;
    assign o_cmd_hw_data = hw_data_reg;

endmodule
