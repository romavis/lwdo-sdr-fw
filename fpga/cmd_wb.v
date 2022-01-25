module cmd_wb #(
    parameter WB_ADDR_WIDTH = 30
)
(
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Wishbone bus master
    output o_wb_cyc,
    output o_wb_stb,
    input i_wb_stall,
    input i_wb_ack,
    output o_wb_we,
    output [WB_ADDR_WIDTH-1:0] o_wb_addr,
    output [31:0] o_wb_data,
    output [3:0] o_wb_sel,
    input [31:0] i_wb_data,
    // MREQ input
    input i_mreq_valid,
    output o_mreq_ready,
    input i_mreq_wr,
    input [1:0] i_mreq_wsize,
    input i_mreq_aincr,
    input [7:0] i_mreq_size,
    input [31:0] i_mreq_addr,
    // Rx data stream (for write requests)
    input i_rx_valid,
    input [7:0] i_rx_data,
    output o_rx_ready,
    // Tx data stream (for read requests)
    output o_tx_valid,
    output [7:0] o_tx_data,
    input i_tx_ready
);
    
    `include "cmd_defines.vh"

    //
    // Wishbone transfer status
    //
    wire wb_req_ack;
    wire wb_resp_ack;
    assign wb_req_ack = o_wb_cyc && o_wb_stb && (!i_wb_stall);
    assign wb_resp_ack = o_wb_cyc && i_wb_ack;

    //
    // Tx and Rx byte streams status
    //
    wire tx_ack;
    wire rx_ack;
    assign tx_ack = o_tx_valid && i_tx_ready;
    assign rx_ack = i_rx_valid && o_rx_ready;

    //
    // State machine
    //
    reg [2:0] state;
    reg [2:0] state_next;
    wire state_change;
    assign state_change = (state_next != state) ? 1'b1 : 1'b0;

    localparam ST_IDLE = 3'd0;
    localparam ST_CONSTRUCT_WORD = 3'd1;
    localparam ST_DECONSTRUCT_WORD = 3'd2;
    localparam ST_WB_REQ_WAIT = 3'd3;
    localparam ST_WB_WAIT_ACK = 3'd4;

    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= ST_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;

        case (state)
        
        // Idle: wait for incoming MREQ and process it when it comes
        ST_IDLE: begin
            if (i_mreq_valid) begin
                state_next = i_mreq_wr ? ST_CONSTRUCT_WORD : ST_WB_REQ_WAIT;
            end
        end

        // When the word has been constructed, generate WB write request
        ST_CONSTRUCT_WORD: begin
            if (wbio_last_byte && rx_ack) begin
                state_next = ST_WB_REQ_WAIT;
            end
        end

        // When the word has been deconstructed, generate a new WB read request if there are bytes to transfer, else go to idle
        ST_DECONSTRUCT_WORD: begin
            if (wbio_last_byte && tx_ack) begin
                // Make new WB request
                state_next = (!last_word) ? ST_WB_REQ_WAIT : ST_IDLE;
            end
        end

        // Wait till WB request is acknowledged (CYC=STB=1, STALL=0),
        // then wait for WB response
        ST_WB_REQ_WAIT: begin
            if (wb_req_ack) begin
                state_next = ST_WB_WAIT_ACK;
            end
        end

        // Wait for WB response, then:
        // if read transfer -> proceed with word deconstruction
        // if write transfer -> construct another word or idle
        ST_WB_WAIT_ACK: begin
            if (wb_resp_ack) begin
                if (r_mreq_wr) begin
                    state_next = (!last_word) ? ST_CONSTRUCT_WORD : ST_IDLE;
                end else begin
                    state_next = ST_DECONSTRUCT_WORD;
                end
            end
        end
        
        endcase
    end

    //
    // Drive outputs
    //
    assign o_wb_cyc = (state == ST_WB_REQ_WAIT || state == ST_WB_WAIT_ACK) ? 1'b1 : 1'b0;
    assign o_wb_stb = (state == ST_WB_REQ_WAIT) ? 1'b1 : 1'b0;
    assign o_wb_we = r_mreq_wr;
    assign o_wb_addr = wb_addr;
    assign o_wb_data = {wbio_data[3], wbio_data[2], wbio_data[1], wbio_data[0]};
    assign o_wb_sel = ~wbio_byte_sel_n;
    assign o_mreq_ready = (state == ST_IDLE) ? 1'b1 : 1'b0;
    assign o_rx_ready = (state == ST_CONSTRUCT_WORD) ? 1'b1 : 1'b0;
    assign o_tx_valid = (state == ST_DECONSTRUCT_WORD) ? 1'b1 : 1'b0;
    assign o_tx_data = wbio_data[wbio_byte_ctr];

    //
    // WB data, byte selection, construction and deconstruction
    //
    reg [1:0] wbio_byte_ctr;
    reg [3:0] wbio_byte_sel_n;
    reg [7:0] wbio_data [0:3];

    reg wbio_last_byte;
    always @(*) begin
        case (r_mreq_wsize)
        CMD_WSIZE_4BYTE: wbio_last_byte = (wbio_byte_ctr == 2'd3) ? 1'b1 : 1'b0;
        CMD_WSIZE_2BYTE: wbio_last_byte = (wbio_byte_ctr == 2'd1) ? 1'b1 : 1'b0;
        default: wbio_last_byte = 1'b1;
        endcase
    end

    always @(posedge i_clk) begin
        // Initialize counters and data register
        if (i_rst) begin

            wbio_byte_ctr <= 2'd0;
            wbio_byte_sel_n <= 4'b1111;
            wbio_data[0] <= 8'd0;
            wbio_data[1] <= 8'd0;
            wbio_data[2] <= 8'd0;
            wbio_data[3] <= 8'd0;

        end else begin

            // Init word construction: reset counters, clear data register
            if (state_change && (state_next == ST_CONSTRUCT_WORD)) begin
                wbio_byte_ctr <= 2'd0;
                wbio_byte_sel_n <= 4'b1111;
                // (WB write) zero-fill data word
                wbio_data[0] <= 8'd0;
                wbio_data[1] <= 8'd0;
                wbio_data[2] <= 8'd0;
                wbio_data[3] <= 8'd0;
            end
            // Init word deconstruction: reset counters, capture data word into data register
            if (state_change && (state_next == ST_DECONSTRUCT_WORD)) begin
                wbio_byte_ctr <= 2'd0;
                // (WB read) capture data bus
                wbio_data[0] <= i_wb_data[7:0];
                wbio_data[1] <= i_wb_data[15:8];
                wbio_data[2] <= i_wb_data[23:16];
                wbio_data[3] <= i_wb_data[31:24];
            end
            // Word construction
            if (state == ST_CONSTRUCT_WORD && rx_ack) begin
                // Capture byte from Rx stream
                wbio_data[wbio_byte_ctr] <= i_rx_data;
                wbio_byte_sel_n <= wbio_byte_sel_n << 1;
                wbio_byte_ctr <= wbio_byte_ctr + 2'd1;
            end
            // Word deconstruction
            if (state == ST_DECONSTRUCT_WORD && tx_ack) begin
                wbio_byte_ctr <= wbio_byte_ctr + 2'd1;
            end

        end
    end

    //
    // WB address
    //
    reg [WB_ADDR_WIDTH-1:0] wb_addr;

    always @(posedge i_clk) begin
        if (i_rst) begin
            wb_addr <= 30'd0;
        end else begin
            // Load address from MREQ
            if (state == ST_IDLE && state_next != ST_IDLE) begin
                wb_addr <= i_mreq_addr[WB_ADDR_WIDTH+1:2];
            end
            // Increment address immediately after WB request has been sent
            if (r_mreq_aincr && wb_req_ack) begin
                wb_addr <= wb_addr + {{WB_ADDR_WIDTH-1{1'b0}}, 1'b1};
            end
        end
    end

    //
    // Word counter
    //
    reg [7:0] words_remaining;
    wire last_word;
    assign last_word = (words_remaining == 8'd0) ? 1'b1 : 1'b0;

    always @(posedge i_clk) begin
        if (i_rst) begin
            words_remaining <= 8'd0;
        end else begin
            // Capture word count when idling
            if (state == ST_IDLE) begin
                words_remaining <= i_mreq_size;
            end
            // Decrement word count when WB req is accepted and it's not the last word
            if (wb_req_ack && !last_word) begin
                words_remaining <= words_remaining - 8'd1;
            end
        end
    end

    //
    // Registering other MREQ fields
    //
    reg r_mreq_wr;
    reg r_mreq_aincr;
    reg [1:0] r_mreq_wsize;

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_mreq_wr <= 1'b0;
            r_mreq_aincr <= 1'b0;
            r_mreq_wsize <= 2'b0;
        end else begin
            if (state == ST_IDLE) begin
                r_mreq_wr <= i_mreq_wr;
                r_mreq_aincr <= i_mreq_aincr;
                r_mreq_wsize <= i_mreq_wsize;
            end
        end
    end

endmodule