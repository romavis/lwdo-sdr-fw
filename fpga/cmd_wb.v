module cmd_wb #(
    parameter WB_ADDR_WIDTH = 24
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
    // MREQ bus
    input i_mreq_valid,
    output o_mreq_ready,
    input [MREQ_NBIT-1:0] i_mreq,
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
    `include "mreq_defines.vh"

    //
    // SysCon
    //
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

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
    reg word_completed;
    wire state_change;
    assign state_change = (state_next != state) ? 1'b1 : 1'b0;

    localparam ST_IDLE = 3'd0;
    localparam ST_REG_REQ = 3'd1;
    localparam ST_CONSTRUCT_WORD = 3'd2;
    localparam ST_DECONSTRUCT_WORD = 3'd3;
    localparam ST_WB_REQ_WAIT = 3'd4;
    localparam ST_WB_WAIT_ACK = 3'd5;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        word_completed = 1'b0;

        case (state)

        // Idle: wait for incoming MREQ and process it when it comes
        ST_IDLE:
            if (i_mreq_valid) begin
                state_next = ST_REG_REQ;
            end

        ST_REG_REQ:
            state_next = r_mreq_wr ? ST_CONSTRUCT_WORD : ST_WB_REQ_WAIT;

        // When the word has been constructed, generate WB write request
        ST_CONSTRUCT_WORD:
            if (wbio_last_byte && rx_ack) begin
                state_next = ST_WB_REQ_WAIT;
            end

        // When the word has been deconstructed, generate a new WB read request if there are bytes to transfer, else go to idle
        ST_DECONSTRUCT_WORD:
            if (wbio_last_byte && tx_ack) begin
                // Make new WB request
                state_next = (!last_word) ? ST_WB_REQ_WAIT : ST_IDLE;
                word_completed = 1'b1;
            end

        // Wait till WB request is acknowledged (CYC=STB=1, STALL=0),
        // then wait for WB response
        ST_WB_REQ_WAIT:
            if (wb_req_ack) begin
                state_next = ST_WB_WAIT_ACK;
            end

        // Wait for WB response, then:
        // if read transfer -> proceed with word deconstruction
        // if write transfer -> construct another word or idle
        ST_WB_WAIT_ACK:
            if (wb_resp_ack) begin
                if (r_mreq_wr) begin
                    state_next = (!last_word) ? ST_CONSTRUCT_WORD : ST_IDLE;
                    word_completed = 1'b1;
                end else begin
                    state_next = ST_DECONSTRUCT_WORD;
                end
            end

        endcase
    end

    //
    // MREQ READY generator
    //
    assign o_mreq_ready = (state_next == ST_IDLE && state_change) ? 1'b1 : 1'b0;

    //
    // Drive outputs
    //
    assign o_wb_cyc = (state == ST_WB_REQ_WAIT || state == ST_WB_WAIT_ACK) ? 1'b1 : 1'b0;
    assign o_wb_stb = (state == ST_WB_REQ_WAIT) ? 1'b1 : 1'b0;
    assign o_wb_we = r_mreq_wr;
    assign o_wb_addr = wb_addr;
    assign o_wb_data = wbio_data;
    assign o_wb_sel = wbio_byte_sel;
    assign o_rx_ready = (state == ST_CONSTRUCT_WORD) ? 1'b1 : 1'b0;
    assign o_tx_valid = (state == ST_DECONSTRUCT_WORD) ? 1'b1 : 1'b0;
    assign o_tx_data = wbio_data[8*wbio_byte_ctr+:8];

    //
    // WB data, byte selection, construction and deconstruction
    //
    reg [1:0] wbio_byte_ctr;
    reg [1:0] wbio_byte_max;
    reg [3:0] wbio_byte_sel;
    reg [31:0] wbio_data;

    function [1:0] wfmt_to_byte_ofs (
        input [2:0] wfmt
    );
        wfmt_to_byte_ofs = 2'd0;
        case (wfmt)
        MREQ_WFMT_8S0,
        MREQ_WFMT_16S0,
        MREQ_WFMT_32S0:
            wfmt_to_byte_ofs = 2'd0;
        MREQ_WFMT_8S1:
            wfmt_to_byte_ofs = 2'd1;
        MREQ_WFMT_8S2,
        MREQ_WFMT_16S1:
            wfmt_to_byte_ofs = 2'd2;
        MREQ_WFMT_8S3:
            wfmt_to_byte_ofs = 2'd3;
        endcase
    endfunction

    function [1:0] wfmt_to_byte_max (
        input [2:0] wfmt
    );
        wfmt_to_byte_max = 2'd0;
        case (wfmt)
        MREQ_WFMT_8S0:
            wfmt_to_byte_max = 2'd0;
        MREQ_WFMT_8S1,
        MREQ_WFMT_16S0:
            wfmt_to_byte_max = 2'd1;
        MREQ_WFMT_8S2:
            wfmt_to_byte_max = 2'd2;
        MREQ_WFMT_8S3,
        MREQ_WFMT_16S1,
        MREQ_WFMT_32S0:
            wfmt_to_byte_max = 2'd3;
        endcase
    endfunction

    wire wbio_last_byte = (wbio_byte_ctr == wbio_byte_max);

    always @(posedge clk) begin
        // Initialize counters and data register
        if (rst) begin

            wbio_byte_ctr <= 2'd0;
            wbio_byte_max <= 2'd0;
            wbio_byte_sel <= 4'b0;
            wbio_data <= 32'd0;

        end else begin

            // Init word construction: reset counters, clear data register
            if (state_change && (state_next == ST_CONSTRUCT_WORD)) begin
                wbio_byte_ctr <= wfmt_to_byte_ofs(r_mreq_wfmt);
                wbio_byte_max <= wfmt_to_byte_max(r_mreq_wfmt);
                wbio_byte_sel <= 4'b0;
                // (WB write) zero-fill data word
                wbio_data <= 32'd0;
            end
            // Init word deconstruction: reset counters, capture data word into data register
            if (state_change && (state_next == ST_DECONSTRUCT_WORD)) begin
                wbio_byte_ctr <= wfmt_to_byte_ofs(r_mreq_wfmt);
                wbio_byte_max <= wfmt_to_byte_max(r_mreq_wfmt);
                // (WB read) capture data bus
                wbio_data <= i_wb_data;
            end
            // Word construction
            if (state == ST_CONSTRUCT_WORD && rx_ack) begin
                // Capture byte from Rx stream
                wbio_data[8*wbio_byte_ctr+:8] <= i_rx_data;
                wbio_byte_sel[wbio_byte_ctr] <= 1'b1;
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

    always @(posedge clk) begin
        if (rst) begin
            wb_addr <= {WB_ADDR_WIDTH{1'b0}};
        end else begin
            // Load address from MREQ during init
            // Increment address immediately after WB request has been sent
            if (state == ST_REG_REQ)
                wb_addr <= r_mreq_addr[WB_ADDR_WIDTH-1:0];
            else if (r_mreq_aincr && wb_req_ack)
                wb_addr <= wb_addr + {{WB_ADDR_WIDTH-1{1'b0}}, 1'b1};
        end
    end

    //
    // Word counter
    //
    reg [7:0] words_remaining;
    wire last_word;
    assign last_word = (words_remaining == 8'd0) ? 1'b1 : 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            words_remaining <= 8'd0;
        end else begin
            // Capture word count from MREQ during init
            // Decrement word count just after we've finished processing a word
            if (state == ST_REG_REQ) words_remaining <= r_mreq_wcnt;
            else if (word_completed) words_remaining <= words_remaining - 8'd1;
        end
    end

    //
    // Register and decode MREQ
    //

    reg [MREQ_NBIT-1:0] r_mreq;

    always @(posedge clk) begin
        if (rst) begin
            r_mreq <= {MREQ_NBIT{1'b0}};
        end else begin
            if (state_next == ST_REG_REQ) r_mreq <= i_mreq;
        end
    end

    reg [7:0] r_mreq_tag;
    reg r_mreq_wr;
    reg r_mreq_aincr;
    reg [2:0] r_mreq_wfmt;
    reg [7:0] r_mreq_wcnt;
    reg [23:0] r_mreq_addr;

    always @(*) begin
        unpack_mreq(
            r_mreq,
            r_mreq_tag, r_mreq_wr, r_mreq_aincr, r_mreq_wfmt, r_mreq_wcnt, r_mreq_addr);
    end

endmodule
