module ft245sync (
    // Main clock of SyncFIFO clock domain.
    // ---
    // FTDI SyncFIFO interface is fully synchronized to CLKOUT pin driven by FTDI itself.
    // This necessitates having a separate clock domain within FPGA to handle all SyncFIFO-related tasks.
    // Signals are sampled/driven on the rising edge of CLKOUT, so this clock domain uses `@(posedge i_clk)`

    // FTDI interface pins
    input i_pin_clkout,
    output o_pin_oe_n,
    output o_pin_siwu,
    output o_pin_wr_n,
    output o_pin_rd_n,
    input i_pin_txe_n, // if nTXE = 0, there is space available in TX buffer
    input i_pin_rxf_n, // if nRXF = 0, there is unread data in RX buffer
    input [7:0] i_pin_data,
    output [7:0] o_pin_data,
    output o_pin_data_oe,   // tristate data bus

    // FPGA interface
    output o_clk,   // system clock for this clock domain
    // Synchronous reset
    input i_rst,
    
    // Data output (FPGA->FTDI)
    // Stream protocol, transfer happens when both valid and ready are 1'b1 @(posedge o_clk)
    input [7:0] i_tx_data,
    input i_tx_valid,
    output o_tx_ready,

    // Data input (FTDI->FPGA)
    // Stream protocol, transfer happens when both valid and ready are 1'b1 @(posedge o_clk)
    output [7:0] o_rx_data,
    output o_rx_valid,
    input i_rx_ready,

    // Debug
    output [3:0] o_dbg
);

    //
    // SysCon
    //
    wire clk;
    wire rst;
    assign clk = i_pin_clkout;
    assign rst = i_rst;
    assign o_clk = clk;

    //
    // Register RXFn, TXEn FIFO status signals from FTDI (to break long combinatorial path)
    //
    reg r_pin_txe_n;
    reg r_pin_rxf_n;
    always @(posedge clk) begin
        r_pin_txe_n <= i_pin_txe_n;
        r_pin_rxf_n <= i_pin_rxf_n;
    end

    //
    // State machine
    //
    reg [1:0] state;
    reg [1:0] state_next;
    wire state_change;
    assign state_change = (state != state_next) ? 1'b1 : 1'b0;

    localparam ST_RX = 2'd0;
    localparam ST_TX = 2'd1;
    localparam ST_SWITCH_RX2TX = 2'd2;
    localparam ST_SWITCH_TX2RX = 2'd3;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_SWITCH_RX2TX;   // initialize to transmit mode
        end else begin
            state <= state_next;
        end
    end

    wire rx_possible;
    wire tx_possible;
    assign rx_possible = ftdi_rx_ready && !i_pin_rxf_n;
    assign tx_possible = ftdi_tx_valid && !i_pin_txe_n;

    always @(*) begin
        state_next = state;
        case (state)

        ST_RX: begin
            // If we're not ready to receive data, we want to send some data, and FTDI is ready to receive it, switch to TX
            if (!rx_possible && tx_possible) begin
                state_next = ST_SWITCH_RX2TX;
            end
        end

        ST_TX: begin
            // If we're ready to receive data, FTDI has some data for us, switch to RX
            if (rx_possible) begin
                state_next = ST_SWITCH_TX2RX;
            end
        end

        ST_SWITCH_RX2TX: state_next = ST_TX;
        ST_SWITCH_TX2RX: state_next = ST_RX;
        
        endcase
    end

    //
    // FPGA OE, FTDI OE, RD, WR, DATA drivers
    //
    assign o_pin_data_oe = (state == ST_TX) ? 1'b1 : 1'b0;
    assign o_pin_oe_n = (state == ST_RX) ? 1'b0 : 1'b1;
    assign o_pin_rd_n = ((state == ST_RX) && ftdi_rx_ready && (r_pin_rxf_n == 1'b0)) ? 1'b0 : 1'b1;
    assign o_pin_wr_n = ((state == ST_TX) && ftdi_tx_valid && (r_pin_txe_n == 1'b0)) ? 1'b0 : 1'b1;
    assign o_pin_data = ftdi_tx_data;

    //
    // FTDI status decoding
    //
    wire ftdi_tx_ready;
    wire ftdi_rx_valid;
    // note: unlike o_pin_rd/wr decoding, this uses unregistered TXEn/RXFn signals
    assign ftdi_tx_ready = (state == ST_TX) && (i_pin_txe_n == 1'b0) && (r_pin_txe_n == 1'b0);
    assign ftdi_rx_valid = (state == ST_RX) && (i_pin_rxf_n == 1'b0) && (r_pin_rxf_n == 1'b0);

    //
    // SIWU: TBD
    //
    assign o_pin_siwu = 1'b1;

    // debug
    assign o_dbg[0] = state[0];
    assign o_dbg[1] = state[1];
    assign o_dbg[2] = r_pin_rxf_n;
    assign o_dbg[3] = r_pin_txe_n;

    //
    // FTDI Tx data buffer
    //
    wire [7:0] ftdi_tx_data;
    wire ftdi_tx_valid;

    stream_buf tx_buf (
        .i_clk(clk),
        .i_rst(i_rst),
        // uplink (FPGA)
        .i_data(i_tx_data),
        .i_valid(i_tx_valid),
        .o_ready(o_tx_ready),
        // downlink (FTDI)
        .o_data(ftdi_tx_data),
        .o_valid(ftdi_tx_valid),
        .i_ready(ftdi_tx_ready)
    );

    //
    // FTDI Rx data buffer
    //
    wire [7:0] ftdi_rx_data;
    wire ftdi_rx_ready;
    assign ftdi_rx_data = i_pin_data;

    stream_buf rx_buf (
        .i_clk(clk),
        .i_rst(i_rst),
        // uplink (FTDI)
        .i_data(ftdi_rx_data),
        .i_valid(ftdi_rx_valid),
        .o_ready(ftdi_rx_ready),
        // downlink (FPGA)
        .o_data(o_rx_data),
        .o_valid(o_rx_valid),
        .i_ready(i_rx_ready)
    );

endmodule
