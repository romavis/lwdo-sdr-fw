module cmd_tx (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Output command stream
    output [7:0] o_st_data,
    output o_st_valid,
    input i_st_ready,
    // Memory request input (MREAD, MWRITE)
    input i_mreq_valid,
    input i_mreq_ready,
    input i_mreq_wr,
    input [1:0] i_mreq_wsize,
    input i_mreq_aincr,
    input [7:0] i_mreq_size,
    input [31:0] i_mreq_addr,
    // Passing mreq_valid through cmd_tx stalls MREQ execution till cmd_tx is ready to accept tx_data
    output o_mreq_valid,
    // Tx data stream interface - transfers data bytes for MREAD requests
    // NOTE: it is responsibility of request handling block to always provide expected number of data bytes. `cmd_tx` module itself does not count data bytes.
    input i_tx_data_valid,
    input [7:0] i_tx_data,
    output o_tx_data_ready
);

    `include "cmd_defines.vh"

    crc8 crc (
        .i_data(r_st_data),
        .i_crc(r_crc_in),
        .o_crc(crc_out)
    );

    // State machine states
    localparam ST_WAITFORSTART = 2'd0;
    localparam ST_SEND_HEADER = 2'd1;
    localparam ST_HANDLE_MREQ = 2'd2;

    // Command parser state machine
    reg [1:0] r_state;
    reg [7:0] r_crc_in;
    wire [7:0] crc_out;
    reg [2:0] r_header_bidx;
    // Output FIFO data
    reg [7:0] r_st_data;
    reg r_st_valid;

    // Transfer success flag on i_st, o_mreq
    wire st_completed;
    assign st_completed = i_st_ready && o_st_valid;
    wire mreq_completed;
    assign mreq_completed = i_mreq_valid && i_mreq_ready;

    wire mreq_active;
    assign mreq_active = (r_state == ST_HANDLE_MREQ);

    // -----
    // Output signals
    // -----

    assign o_mreq_valid = i_mreq_valid && mreq_active;

    // Direct combinational link from i_st to o_wr_data
    // mreq_active=0: o_st_data is controlled by internal logic, i_tx_data is not ready
    // mreq_active=1: o_st_data is controlled by i_tx_data, o_tx_data_ready is i_st_ready
    assign o_tx_data_ready = mreq_active ? i_st_ready : 1'b0;
    assign o_st_data = mreq_active ? i_tx_data : r_st_data;
    assign o_st_valid = mreq_active ? i_tx_data_valid : r_st_valid;

    always @(posedge i_clk) begin
        if (i_rst) begin

            r_state <= ST_WAITFORSTART;
            r_crc_in <= 8'd0;
            r_header_bidx <= 3'd0;
            r_st_data <= 8'd0;
            r_st_valid <= 8'd0;

        end else begin

            r_st_valid <= 1'b0;

            case (r_state)

                ST_WAITFORSTART: begin
                    // Initialize state machine registers
                    r_header_bidx <= 3'd0;
                    r_crc_in <= 8'h00;

                    if (i_mreq_valid) begin
                        r_state <= ST_SEND_HEADER;
                        // Already feed first byte of data
                        r_st_valid <= 1'b1;
                        r_st_data <= CMD_TX_START;
                    end
                end

                ST_SEND_HEADER: begin
                    r_st_valid <= 1'b1;
                    if (st_completed) begin
                        r_header_bidx <= r_header_bidx + 3'd1;
                        r_crc_in <= crc_out;

                        case (r_header_bidx)
                            CMD_TX_BIDX_OP: begin
                                r_st_data <= 8'd0;
                                r_st_data[0] <= i_mreq_wr;
                                r_st_data[3] <= i_mreq_aincr;
                                r_st_data[5:3] <= i_mreq_wsize;
                            end

                            CMD_TX_BIDX_SZ: r_st_data <= i_mreq_size;

                            CMD_TX_BIDX_A0: r_st_data <= i_mreq_addr[7:0];
                            CMD_TX_BIDX_A1: r_st_data <= i_mreq_addr[15:8];
                            CMD_TX_BIDX_A2: r_st_data <= i_mreq_addr[23:16];
                            CMD_TX_BIDX_A3: r_st_data <= i_mreq_addr[31:24];

                            CMD_TX_BIDX_CRC: r_st_data <= crc_out;

                            CMD_TX_BIDX_LAST: begin
                                r_state <= ST_HANDLE_MREQ;
                                r_st_valid <= 1'b0;
                            end
                            
                            default: r_state <= ST_WAITFORSTART;
                        endcase
                    end
                end

                ST_HANDLE_MREQ: begin
                    r_st_valid <= 1'b0;
                    if (mreq_completed) begin
                        // Finish request handling
                        r_state <= ST_WAITFORSTART;
                    end
                end
                
                // All other states are invalid -> reset state machine
                default: r_state <= ST_WAITFORSTART;
            endcase

        end
    end

endmodule