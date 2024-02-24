module wbcon_exec #(
    parameter WB_ADDR_WIDTH = 24,   // WB word address width
    parameter WB_DATA_WIDTH = 32,
    parameter WB_SEL_WIDTH = (WB_DATA_WIDTH + 7) / 8,
    // Number of address bits necessary to addres byte within a word
    parameter BYTE_ADDR_WIDTH = $clog2((WB_DATA_WIDTH + 7) / 8),
    // Number of address bits sent over serial protocol
    parameter SERIAL_ADDR_WIDTH = WB_ADDR_WIDTH + BYTE_ADDR_WIDTH
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
    input i_wb_err,
    input i_wb_rty,
    output o_wb_we,
    output [WB_ADDR_WIDTH-1:0] o_wb_adr,
    output [WB_DATA_WIDTH-1:0] o_wb_dat,
    output [WB_SEL_WIDTH-1:0] o_wb_sel,
    input [WB_DATA_WIDTH-1:0] i_wb_dat,
    // Decoded command from wbcon_rx
    input i_cmd_tvalid,
    output o_cmd_tready,
    input i_cmd_op_null,
    input i_cmd_op_set_address,
    input i_cmd_op_write_word,
    input i_cmd_op_read_word,
    input [SERIAL_ADDR_WIDTH-1:0] i_cmd_hw_addr,
    input [WB_DATA_WIDTH-1:0] i_cmd_hw_data,
    // Command result for wbcon_tx
    output o_cres_tvalid,
    input i_cres_tready,
    output o_cres_op_null,
    output o_cres_op_set_address,
    output o_cres_op_write_word,
    output o_cres_op_read_word,
    output [WB_DATA_WIDTH-1:0] o_cres_hw_data,
    output o_cres_bus_err,
    output o_cres_bus_rty //
);

    // SysCon
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // Wishbone handshake
    wire wb_req_ack;
    wire wb_resp_ack;
    assign wb_req_ack = o_wb_cyc && o_wb_stb && (!i_wb_stall);
    assign wb_resp_ack = o_wb_cyc && (i_wb_ack | i_wb_err | i_wb_rty);

    // wbcon_rx / tx handshakes
    wire cmd_ack = i_cmd_tvalid && o_cmd_tready;
    wire cres_ack = o_cres_tvalid && i_cres_tready;

    // State machine
    reg [1:0] state;
    reg [1:0] state_next;

    localparam STATE_IDLE = 2'd0;
    localparam STATE_AWAIT_WB_REQ = 2'd1;
    localparam STATE_AWAIT_WB_RESP = 2'd2;
    localparam STATE_AWAIT_CRES_ACK = 2'd3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        case (state)
            // Idle: wait for incoming CMD and process it when it comes
            STATE_IDLE: begin
                if (i_cmd_tvalid) begin
                    if (i_cmd_op_write_word || o_cres_op_read_word) begin
                        state_next = STATE_AWAIT_WB_REQ;
                    end else begin
                        state_next = STATE_AWAIT_CRES_ACK;
                    end
                end
            end

            // Wait till WB request is acknowledged (CYC=STB=1, STALL=0)
            STATE_AWAIT_WB_REQ: begin
                if (wb_req_ack) begin
                    state_next = STATE_AWAIT_WB_RESP;
                end
            end

            // Wait till WB provides a response (can be one of ACK, ERR, RTY)
            STATE_AWAIT_WB_RESP: begin
                if (wb_resp_ack) begin
                    state_next = STATE_AWAIT_CRES_ACK; 
                end
            end

            // Wait till CRES is acknowledged (wbcon_tx completes Tx)
            STATE_AWAIT_CRES_ACK: begin
                if (cres_ack) begin
                    state_next = STATE_IDLE;
                end
            end
        endcase
    end

    // WB handshake drivers
    reg wb_cyc_reg;
    reg wb_stb_reg;

    always @(*) begin
        wb_cyc_reg = 1'b0;
        wb_stb_reg = 1'b0;
        case (state)
            STATE_AWAIT_WB_REQ: begin
                wb_cyc_reg = 1'b1;
                wb_stb_reg = 1'b1;
            end

            STATE_AWAIT_WB_RESP: begin
                wb_cyc_reg = 1'b1;
                wb_stb_reg = 1'b0;
            end
        endcase
    end

    // CRES and CMD handshake drivers
    reg cres_tvalid_reg;
    reg cmd_tready_reg;

    always @(*) begin
        cres_tvalid_reg = 1'b0;
        cmd_tready_reg = 1'b0;
        case (state)
            STATE_AWAIT_CRES_ACK: begin
                cres_tvalid_reg = 1'b1;
                cmd_tready_reg = i_cres_tready;
            end
        endcase
    end

    // WB addr driver
    reg [WB_ADDR_WIDTH-1:0] wb_addr_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            wb_addr_reg <= 1'd0;
        end else begin
            if (i_cmd_op_set_address && i_cmd_tvalid) begin
                // Only word-aligned accesses. Address LSBs are discarded.
                wb_addr_reg <= i_cmd_hw_addr >> BYTE_ADDR_WIDTH;
            end
        end
    end

    // WB sel driver
    reg [WB_SEL_WIDTH-1:0] wb_sel_reg;

    always @(*) begin
        // only full-word accesses for now
        wb_sel_reg = {WB_SEL_WIDTH{1'b1}};
    end

    // WB write data & we driver
    reg [WB_DATA_WIDTH-1:0] wb_wdata_reg;
    reg wb_we_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            wb_wdata_reg <= 1'b0;
            wb_we_reg <= 1'b0;
        end else begin
            if (i_cmd_tvalid) begin
                wb_wdata_reg <= i_cmd_hw_data;
                wb_we_reg <= i_cmd_op_write_word;
            end
        end
    end

    // WB read data & status cache
    reg [WB_DATA_WIDTH-1:0] wb_rdata_reg;
    reg wb_err_reg;
    reg wb_rty_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            wb_rdata_reg <= 1'b0;
        end else begin
            if (wb_resp_ack) begin
                wb_rdata_reg <= i_wb_dat;
                wb_err_reg <= i_wb_err;
                wb_rty_reg <= i_wb_rty;
            end
        end
    end

    // Register op_* signals to improve timings
    reg cmd_op_null_q;
    reg cmd_op_set_address_q;
    reg cmd_op_write_word_q;
    reg cmd_op_read_word_q;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cmd_op_null_q <= 1'b0;
            cmd_op_set_address_q <= 1'b0;
            cmd_op_write_word_q <= 1'b0;
            cmd_op_read_word_q <= 1'b0;
        end else begin
            if (i_cmd_tvalid) begin
                cmd_op_null_q <= i_cmd_op_null;
                cmd_op_set_address_q <= i_cmd_op_set_address;
                cmd_op_write_word_q <= i_cmd_op_write_word;
                cmd_op_read_word_q <= i_cmd_op_read_word;
            end
        end
    end

    // Wiring
    assign o_wb_cyc = wb_cyc_reg;
    assign o_wb_stb = wb_stb_reg;
    assign o_wb_we = wb_we_reg;
    assign o_wb_adr = wb_addr_reg;
    assign o_wb_dat = wb_wdata_reg;
    assign o_wb_sel = wb_sel_reg;

    assign o_cmd_tready = cmd_tready_reg;

    assign o_cres_tvalid = cres_tvalid_reg;
    assign o_cres_op_null = cmd_op_null_q;
    assign o_cres_op_set_address = cmd_op_set_address_q;
    assign o_cres_op_write_word = cmd_op_write_word_q;
    assign o_cres_op_read_word = cmd_op_read_word_q;
    assign o_cres_hw_data = wb_rdata_reg;
    assign o_cres_bus_err = wb_err_reg;
    assign o_cres_bus_rty = wb_rty_reg;

endmodule
