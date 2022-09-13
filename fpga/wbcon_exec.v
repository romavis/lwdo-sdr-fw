module wbcon_exec #(
    parameter COUNT_WIDTH = 8,      // MREQ word count width
    parameter WB_ADDR_WIDTH = 24,   // WB word address width
    parameter WB_DATA_WIDTH = 32,
    parameter WB_SEL_WIDTH = (WB_DATA_WIDTH + 7) / 8
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
    output [WB_DATA_WIDTH-1:0] o_wb_data,
    output [WB_SEL_WIDTH-1:0] o_wb_sel,
    input [WB_DATA_WIDTH-1:0] i_wb_data,
    // Rx data stream (for write requests)
    input i_rx_valid,
    input [7:0] i_rx_data,
    output o_rx_ready,
    // Tx data stream (for read requests)
    output o_tx_valid,
    output [7:0] o_tx_data,
    input i_tx_ready,
    // MREQ bus
    input i_mreq_valid,
    output o_mreq_ready,
    input [WB_ADDR_WIDTH-1:0] i_mreq_addr,
    input [COUNT_WIDTH-1:0] i_mreq_cnt,
    input i_mreq_wr,
    input i_mreq_aincr
);

    localparam WORD_SIZE = (WB_DATA_WIDTH + 7) / 8;
    localparam BYTE_CNT_BITS = (WORD_SIZE >= 2) ? $clog2(WORD_SIZE) : 1;

    // SysCon
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // Wishbone transfer status
    wire wb_req_ack;
    wire wb_resp_ack;
    assign wb_req_ack = o_wb_cyc && o_wb_stb && (!i_wb_stall);
    assign wb_resp_ack = o_wb_cyc && i_wb_ack;

    // Tx and Rx byte streams status
    wire tx_ack;
    wire rx_ack;
    assign tx_ack = o_tx_valid && i_tx_ready;
    assign rx_ack = i_rx_valid && o_rx_ready;

    // State machine
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

    always @(posedge clk or posedge rst) begin
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
            state_next = mreq_wr ? ST_CONSTRUCT_WORD : ST_WB_REQ_WAIT;

        // When the word has been constructed, generate WB write request
        ST_CONSTRUCT_WORD:
            if (wb_last_byte && rx_ack) begin
                state_next = ST_WB_REQ_WAIT;
            end

        // When the word has been deconstructed, generate a new WB read request if there are bytes to transfer, else go to idle
        ST_DECONSTRUCT_WORD:
            if (wb_last_byte && tx_ack) begin
                // Make new WB request
                state_next = words_rem ? ST_WB_REQ_WAIT : ST_IDLE;
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
                if (mreq_wr) begin
                    state_next = words_rem ? ST_CONSTRUCT_WORD : ST_IDLE;
                    word_completed = 1'b1;
                end else begin
                    state_next = ST_DECONSTRUCT_WORD;
                end
            end

        endcase
    end

    // WB data construction and deconstruction
    reg [BYTE_CNT_BITS-1:0] wb_byte_ctr;
    reg [WB_DATA_WIDTH-1:0] wb_data;

    wire wb_last_byte;
    assign wb_last_byte = (wb_byte_ctr == (WORD_SIZE-1));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_byte_ctr <= 0;
            wb_data <= 0;
        end else begin
            // Init word construction: reset counters, clear data register
            if (state_change && (state_next == ST_CONSTRUCT_WORD)) begin
                wb_byte_ctr <= 0;
                // (WB write) zero-fill data word
                wb_data <= 0;
            end
            // Init word deconstruction: reset counters, capture data word into data register
            if (state_change && (state_next == ST_DECONSTRUCT_WORD)) begin
                wb_byte_ctr <= 0;
                // (WB read) capture data bus
                wb_data <= i_wb_data;
            end
            // Word construction
            if (state == ST_CONSTRUCT_WORD && rx_ack) begin
                // Capture byte from Rx stream
                wb_data[8*wb_byte_ctr+:8] <= i_rx_data;
                wb_byte_ctr <= wb_byte_ctr + 1'd1;
            end
            // Word deconstruction
            if (state == ST_DECONSTRUCT_WORD && tx_ack) begin
                wb_byte_ctr <= wb_byte_ctr + 1'd1;
            end

        end
    end

    // WB address
    reg [WB_ADDR_WIDTH-1:0] wb_addr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_addr <= 0;
        end else begin
            // Load address from MREQ during init
            // Increment address immediately after WB request has been sent
            if (state == ST_REG_REQ)
                wb_addr <= mreq_addr;
            else if (mreq_aincr && wb_req_ack)
                wb_addr <= wb_addr + 1'd1;
        end
    end

    // Word counter
    reg [COUNT_WIDTH-1:0] words_rem;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            words_rem <= 0;
        end else begin
            // Capture word count from MREQ during init
            // Decrement word count just after we've finished processing a word
            if (state == ST_REG_REQ) words_rem <= mreq_cnt;
            else if (word_completed) words_rem <= words_rem - 1'd1;
        end
    end

    // Register MREQ
    reg [WB_ADDR_WIDTH-1:0] mreq_addr;
    reg [COUNT_WIDTH-1:0] mreq_cnt;
    reg mreq_wr;
    reg mreq_aincr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mreq_addr <= 0;
            mreq_cnt <= 0;
            mreq_wr <= 0;
            mreq_aincr <= 0;
        end else if (state_next == ST_REG_REQ) begin
            mreq_addr <= i_mreq_addr;
            mreq_cnt <= i_mreq_cnt;
            mreq_wr <= i_mreq_wr;
            mreq_aincr <= i_mreq_aincr;
        end
    end

    // WB outputs
    assign o_wb_cyc = (state == ST_WB_REQ_WAIT || state == ST_WB_WAIT_ACK);
    assign o_wb_stb = (state == ST_WB_REQ_WAIT);
    assign o_wb_we = mreq_wr;
    assign o_wb_addr = wb_addr;
    assign o_wb_data = wb_data;
    assign o_wb_sel = {WORD_SIZE{1'b1}};    // our module always writes full words
    // MREQ ready
    assign o_mreq_ready = (state_next == ST_IDLE && state_change);
    // Rx ready
    assign o_rx_ready = (state == ST_CONSTRUCT_WORD);
    // Tx stream
    assign o_tx_valid = (state == ST_DECONSTRUCT_WORD);
    assign o_tx_data = wb_data[8*wb_byte_ctr+:8];

endmodule
