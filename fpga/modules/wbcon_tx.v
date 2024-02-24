/****************************************************************************

                        ---- wbcon_tx ----

Module that transmits responses to commands parsed by wbcon_rx and executed
by wbcon_exec.

See wbcon_rx for protocol description

****************************************************************************/

module wbcon_tx #(
    parameter HW_DATA_WIDTH = 32'd16
) (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Command execution result input
    input i_cres_tvalid,
    output o_cres_tready,
    input i_cres_op_set_address,
    input i_cres_op_write_word,
    input i_cres_op_read_word,
    input [HW_DATA_WIDTH-1:0] i_cres_hw_data,
    input i_cres_bus_err,
    input i_cres_bus_rty,
    // AXI-S stream that carries encoded response packets
    output o_tx_axis_tvalid,
    input i_tx_axis_tready,
    output [7:0] o_tx_axis_tdata,
    output o_tx_axis_tlast  //
);

    // Protocol bits
    localparam HDR_INVALID_OP = 8'h80;
    localparam HDR_SET_ADDRESS = 8'h81;
    localparam HDR_WRITE_WORD = 8'h82;
    localparam HDR_READ_WORD = 8'h83;

    localparam STS_OK = 8'h01;
    localparam STS_BUS_ERR = 8'h02;
    localparam STS_BUS_RTY = 8'h03;

    // Widths
    localparam HW_DATA_NBYTES = (HW_DATA_WIDTH + 7) / 8;
    localparam HW_DATA_BCNT_WIDTH = $clog2(HW_DATA_NBYTES);

    // ACKs
    wire tx_ack;
    assign tx_ack = o_tx_axis_tvalid && i_tx_axis_tready;

    // FSM
    localparam STATE_SEND_HDR = 2'd0;
    localparam STATE_SEND_DATA = 2'd1;
    localparam STATE_SEND_STATUS = 2'd2;

    reg [1:0] state;
    reg [1:0] state_next;
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= STATE_SEND_HDR;
        end else begin
            state <= state_next;
        end
    end

    // Response type identifier
    reg has_data;
    reg has_status;

    always @(*) begin
        has_data = 1'b0;
        has_status = 1'b0;
        if (i_cres_tvalid) begin
            if (i_cres_op_read_word) begin
                has_data = 1'b1;
                has_status = 1'b1;
            end
            if (i_cres_op_write_word) begin
                has_status = 1'b1;
            end
        end
    end

    // FSM logic
    always @(*) begin
        state_next = state;

        case (state)
            STATE_SEND_HDR: begin
                if (tx_ack) begin
                    if (has_data) begin
                        state_next = STATE_SEND_DATA;
                    end else if (has_status) begin
                        state_next = STATE_SEND_STATUS;
                    end else begin
                        state_next = STATE_SEND_HDR;
                    end
                end
            end

            STATE_SEND_DATA: begin
                if (tx_ack) begin
                    if (hw_data_nbyte == (HW_DATA_NBYTES - 1)) begin
                        if (has_status) begin
                            state_next = STATE_SEND_STATUS;
                        end else begin
                            // has_data=1 has_status=0 is unused
                            // present only for completeness
                            state_next = STATE_SEND_HDR;
                        end
                    end
                end
            end

            STATE_SEND_STATUS: begin
                if (tx_ack) begin
                    state_next = STATE_SEND_HDR;
                end
            end
        endcase
    end

    // TLAST
    reg tx_axis_tlast_reg;

    always @(*) begin
        tx_axis_tlast_reg = 1'b0;
        case (state)
            STATE_SEND_HDR: begin
                if (!has_data && !has_status) begin
                    tx_axis_tlast_reg = 1'b1;
                end
            end

            STATE_SEND_DATA: begin
                if (!has_status) begin
                    tx_axis_tlast_reg = 1'b1;
                end
            end

            STATE_SEND_STATUS: begin
                tx_axis_tlast_reg = 1'b1;
            end
        endcase
    end

    // Stream flow control
    reg tx_axis_tvalid_reg;
    reg cres_tready_reg;

    always @(*) begin
        tx_axis_tvalid_reg = 1'b0;
        case (state)
            STATE_SEND_HDR: begin
                tx_axis_tvalid_reg = i_cres_tvalid;
            end
            STATE_SEND_DATA: begin
                tx_axis_tvalid_reg = 1'b1;
            end
            STATE_SEND_STATUS: begin
                tx_axis_tvalid_reg = 1'b1;
            end
        endcase
        // CRES TREADY: follow TLAST
        cres_tready_reg = tx_axis_tlast_reg && tx_ack;
    end

    // HW_DATA shift-out
    reg [HW_DATA_WIDTH-1:0] hw_data_reg;
    reg [HW_DATA_BCNT_WIDTH-1:0] hw_data_nbyte;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            hw_data_reg <= 1'd0;
            hw_data_nbyte <= 1'd0;
        end else begin
            case (state)
                STATE_SEND_HDR: begin
                    if (i_cres_tvalid) begin
                        // capture
                        hw_data_reg <= i_cres_hw_data;
                        hw_data_nbyte <= 1'd0;
                    end
                end
                STATE_SEND_DATA: begin
                    if (tx_ack) begin
                        hw_data_reg <= hw_data_reg >> 32'd8;
                        hw_data_nbyte <= hw_data_nbyte + 1'd1;
                    end
                end
            endcase
        end
    end

    // Tx data
    reg [7:0] tx_axis_tdata_reg;

    always @(*) begin
        tx_axis_tdata_reg = 8'b0;
        case (state)
            STATE_SEND_HDR: begin
                tx_axis_tdata_reg = HDR_INVALID_OP;
                if (i_cres_op_set_address) begin
                    tx_axis_tdata_reg = HDR_SET_ADDRESS;
                end
                if (i_cres_op_read_word) begin
                    tx_axis_tdata_reg = HDR_READ_WORD;
                end
                if (i_cres_op_write_word) begin
                    tx_axis_tdata_reg = HDR_WRITE_WORD;
                end
            end

            STATE_SEND_DATA: begin
                tx_axis_tdata_reg = hw_data_reg[7:0];
            end

            STATE_SEND_STATUS: begin
                tx_axis_tdata_reg = STS_OK;
                if (i_cres_bus_err) begin
                    tx_axis_tdata_reg = STS_BUS_ERR;
                end
                if (i_cres_bus_rty) begin
                    tx_axis_tdata_reg = STS_BUS_RTY;
                end
            end
        endcase
    end

    assign o_cres_tready = cres_tready_reg;
    assign o_tx_axis_tvalid = tx_axis_tvalid_reg;
    assign o_tx_axis_tdata = tx_axis_tdata_reg;
    assign o_tx_axis_tlast = tx_axis_tlast_reg;

endmodule
