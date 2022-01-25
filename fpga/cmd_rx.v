module cmd_rx (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Input command stream
    input [7:0] i_st_data,
    input i_st_valid,
    output o_st_ready,
    // Error flags
    output o_err_crc,
    // Decoded memory request (MREAD, MWRITE)
    output o_mreq_valid,        // 1 if valid memory access request is present on the output (request has been decoded successfully)
    input i_mreq_ready,         // 1 if request has been completed. `req_valid` is held at 1 till `req_ready` becomes 1,
                                //  after that module switches to receiving a new request
    output o_mreq_wr,           // 1 if write request, 0 if read
    output [1:0] o_mreq_wsize,  // Access (word) size which should be used for the request
    output o_mreq_aincr,        // 1 if address should be incremented after transfer of each word, 0 if not
    output [7:0] o_mreq_size,   // Size of data: number of words _minus one_ (size==0 means 1 word is transferred, size==1 means 2 words are transferred)
    output [31:0] o_mreq_addr,  // Request address. Should be aligned to `wsize`.
    // Rx data stream interface - transfers data bytes for MWRITE requests
    // NOTE: it is responsibility of request handling block to always consume expected number of data bytes. `cmd_rx` module itself does not count data bytes.
    output o_rx_valid,
    output [7:0] o_rx_data,
    input i_rx_ready,
    // debug bits
    output o_dbg
);

    `include "cmd_defines.vh"

    /*
     * Packet format:
     *  - CMD header: see CMD_RX_BIDX_ macros
     *  - [optional] data bytes
     *
     * OP byte bit meaning:
     *  bits 7:6 - unused, should be set to 0
     *  bits 5:4 - WSIZE - see CMD_WSIZE_
     *  bit 3 - AINCR - 0 if no address auto-increment, 1 if address auto-increment
     *  bits 2:1 - should be set to 0
     *  bit 0 - WR - 0 if read (MREAD) command, 1 if write (MWRITE) command
     *
     * For MREAD commands, only CMD header is present, and can be followed immediately by another CMD header.
     * For MWRITE commands, CMD header is followed by N data bytes, where N = WSIZE * (SIZE + 1).
     */

    crc8 crc (
        .i_data(i_st_data),
        .i_crc(r_crc_in),
        .o_crc(crc_out)
    );

    // State machine states
    localparam ST_WAITFORSTART = 2'd0;
    localparam ST_READ_HEADER = 2'd1;
    localparam ST_HANDLE_MREQ = 2'd2;

    // Command parser state machine
    reg [2:0] r_state;
    reg [7:0] r_crc_in;
    wire [7:0] crc_out;
    reg [2:0] r_header_bidx;
    // Error flags
    reg r_err_crc;
    // Parsed command fields
    reg r_mreq_wr;   // 1 if write command, 0 if read
    reg r_mreq_aincr;
    reg [1:0] r_mreq_wsize;
    reg [7:0] r_mreq_size;
    reg [31:0] r_mreq_addr; // full 32-bit address of a byte

    // Ready flag for command stream
    reg r_st_ready;
    // Valid flag for MREQ bus
    reg r_mreq_valid;

    // Transfer success flag on i_st, o_mreq
    wire st_completed;
    assign st_completed = o_st_ready && i_st_valid;
    wire mreq_completed;
    assign mreq_completed = o_mreq_valid && i_mreq_ready;

    wire mreq_active;
    assign mreq_active = (r_state == ST_HANDLE_MREQ);

    // -----
    // Output signals
    // -----

    assign o_err_crc = r_err_crc;
    assign o_mreq_valid = r_mreq_valid;
    assign o_mreq_wr = r_mreq_wr;
    assign o_mreq_wsize = r_mreq_wsize;
    assign o_mreq_aincr = r_mreq_aincr;
    assign o_mreq_addr = r_mreq_addr;
    assign o_mreq_size = r_mreq_size;
    // Direct combinational link from i_st to o_rx_data
    // mreq_active=0: o_rx_data is not valid, o_st_ready is controlled by r_st_ready (driven by command parser state machine)
    // mreq_active=1: o_rx_data is driven by i_st, o_st_ready is driven by i_rx_ready
    assign o_rx_valid = mreq_active ? i_st_valid : 1'b0;
    assign o_rx_data = i_st_data;
    assign o_st_ready = mreq_active ? i_rx_ready : r_st_ready;
    // Debug
    assign o_dbg = (i_st_data == 8'hA3);

    always @(posedge i_clk) begin
        if (i_rst) begin

            r_state <= ST_WAITFORSTART;
            r_crc_in <= 8'd0;
            r_header_bidx <= 3'd0;
            r_err_crc <= 1'b0;
            r_mreq_wr <= 1'd0;
            r_mreq_aincr <= 2'd0;
            r_mreq_wsize <= 2'd0;
            r_mreq_size <= 8'd0;
            r_mreq_addr <= 32'd0;

            r_st_ready <= 1'b0;
            r_mreq_valid <= 1'b0;

        end else begin

            // Except in some cases, we're ready to accept new byte from command stream
            r_st_ready <= 1'b1;
            // Except in some cases, we're not outputting anything
            r_mreq_valid <= 1'b0;

            case (r_state)

                ST_WAITFORSTART: begin
                    // Initialize state machine registers
                    r_header_bidx <= 3'd0;
                    r_crc_in <= 8'h00;
                    r_err_crc <= 1'b0;

                    if (st_completed && (i_st_data == CMD_RX_START)) begin
                        // Start byte spotted, read the command
                        r_state <= ST_READ_HEADER;
                        r_crc_in <= crc_out;
                    end
                end

                ST_READ_HEADER: begin
                    if (st_completed) begin
                        r_header_bidx <= r_header_bidx + 3'd1;
                        r_crc_in <= crc_out;

                        case (r_header_bidx)
                            CMD_RX_BIDX_OP: begin
                                r_mreq_wr <= i_st_data[0];
                                r_mreq_aincr <= i_st_data[3];
                                r_mreq_wsize <= i_st_data[5:4];
                            end

                            CMD_RX_BIDX_SZ: r_mreq_size <= i_st_data;

                            CMD_RX_BIDX_A0: r_mreq_addr[7:0] <= i_st_data;
                            CMD_RX_BIDX_A1: r_mreq_addr[15:8] <= i_st_data;
                            CMD_RX_BIDX_A2: r_mreq_addr[23:16] <= i_st_data;
                            CMD_RX_BIDX_A3: r_mreq_addr[31:24] <= i_st_data;

                            CMD_RX_BIDX_CRC: begin
                                // Check if CRC is valid
                                if (crc_out == 8'h00) begin
                                    // Truncate address LSBs for multibyte accesses
                                    case (r_mreq_wsize)
                                        CMD_WSIZE_4BYTE: r_mreq_addr[1:0] <= 2'b00;
                                        CMD_WSIZE_2BYTE: r_mreq_addr[0] <= 1'b0;
                                    endcase

                                    r_state <= ST_HANDLE_MREQ;
                                    r_mreq_valid <= 1'b1;
                                    r_st_ready <= 1'b0;

                                end else begin
                                    // CRC invalid, skip command
                                    r_err_crc <= 1'b1;
                                    r_state <= ST_WAITFORSTART;
                                end
                                // Reset CRC
                                r_crc_in <= 8'h00;
                            end
                            
                            default: r_state <= ST_WAITFORSTART;
                        endcase
                    end
                end

                ST_HANDLE_MREQ: begin
                    r_st_ready <= 1'b0;
                    r_mreq_valid <= 1'b0;
                    // TODO: this needs to be improved, quick&dirty logic for now
                    if (!r_mreq_valid && i_mreq_ready) begin
                        r_state <= ST_WAITFORSTART;
                        r_st_ready <= 1'b1;
                    end
                end
                
                // All other states are invalid -> reset state machine
                default: r_state <= ST_WAITFORSTART;
            endcase

        end
    end

endmodule