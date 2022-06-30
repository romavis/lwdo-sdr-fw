module top (
    // LEDs
    output p_led_sts_r,
    output p_led_sts_g,
    output p_led_in1_r,
    output p_led_in1_g,
    output p_led_in2_r,
    output p_led_in2_g,
    output p_led_in3_r,
    output p_led_in3_g,
    output p_led_in4_r,
    output p_led_in4_g,
    // ADC clocks: on pin 15 we have output, on pin 20 we have input
    output p_adc_sclk,
    input p_adc_sclk_gbin,
    // ADC data and sync
    input p_adc1_sda,
    input p_adc1_sdb,
    output p_adc1_cs_n,
    input p_adc2_sda,
    input p_adc2_sdb,
    output p_adc2_cs_n,
    // External I/O,
    inout [8:1] p_extio,
    // SPI DAC,
    output p_spi_dac_mosi,
    output p_spi_dac_sclk,
    output p_spi_dac_sync_n,
    // System clocks
    input p_clk_20mhz_gbin1,
    input p_clk_20mhz_gbin2,
    output p_clk_out,
    input p_clk_ref_in,
    output p_clk_out_sel,
    // FTDI GPIO
    input p_ft_io1,
    input p_ft_io2,
    // FTDI FIFO
    input p_ft_fifo_clkout,
    output p_ft_fifo_oe_n,
    output p_ft_fifo_siwu,
    output p_ft_fifo_wr_n,
    output p_ft_fifo_rd_n,
    input p_ft_fifo_txe_n,
    input p_ft_fifo_rxf_n,
    inout [7:0] p_ft_fifo_d
);

    `include "mreq_defines.vh"

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                        CLOCK GENERATION                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ------------------------------------------
    //                  ADC PLL
    //
    // input: 20MHz
    // output: 80MHz
    // ------------------------------------------
    wire adc_pll_out;
    wire adc_pll_lock;

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'd0),
		.DIVF(7'd31),
		.DIVQ(3'd3),
		.FILTER_RANGE(3'd2),
        .PLLOUT_SELECT("GENCLK")
    ) adc_pll (
        .REFERENCECLK (p_clk_20mhz_gbin1),  // 20 MHz
        .PLLOUTCORE (adc_pll_out),
        .LOCK (adc_pll_lock),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );

    // Output PLL clock on the pin
    assign p_adc_sclk = adc_pll_out;


    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                      SYSTEM CLOCK DOMAIN                    =========================
    // =========================                       @(posedge sys_clk)                    =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ADC controller is clocked from (negedge p_adc_sclk_gbin)
    wire sys_clk_neg = p_adc_sclk_gbin;
    // System clock domain is clocked from (posedge sys_clk)
    // Because we want it to be exactly the same clock as ADC's, we set sys_clk=~p_adc_sclk_gbin
    wire sys_clk = ~p_adc_sclk_gbin;

    // ----------------------------
    // System reset generator
    // ----------------------------

    // Reset asserted on:
    //  - FPGA reconfiguration (power on)
    //  - Asynchronously when sys_rst_req goes high
    // Reset deasserted on:
    //  - First sys_clk cycle when sys_rst_req is low
    reg sys_rst = 1'b1;
    wire sys_rst_req;

    // TODO: use this request line
    assign sys_rst_req = 1'b0;

    always @(posedge sys_clk or posedge sys_rst_req) begin
        sys_rst <= 1'b0;
        if (sys_rst_req) begin
            sys_rst <= 1'b1;
        end
    end

    // ----------------------------------------
    //      ADC1,2 sample rate generators
    //
    //                      +----> [adc_srate1_div] ----> adc_srate1 ----> [ADC1]
    //  sys_clk (80MHz) ->--+
    //                      +----> [adc_srate2_div] ----> adc_srate2 ----> [ADC2]
    //
    wire adc_srate1, adc_srate2;

    fastcounter #(
        .NBITS(8)
    ) adc_srate1_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(1'b0),      // AUTORELOAD
        .i_en(1'b1),
        .i_load(1'b0),
        .i_load_q(8'd19),   // 80M/(1+19)=4M
        .o_carry(adc_srate1)
    );

    fastcounter #(
        .NBITS(8)
    ) adc_srate2_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(1'b0),      // AUTORELOAD
        .i_en(1'b1),
        .i_load(1'b0),
        .i_load_q(8'd79),   // 80M/(1+79)=1M
        .o_carry(adc_srate2)
    );

    // ----------------------------------------
    //      Timing pulse generators
    //
    //  adc_srate1 --> [adc_puls1_psc] --> adc_puls1 --> [adc_puls1_dly] --> adc_puls1_d --> [adc_puls1_fmr] --> adc_puls1_w
    //  adc_srate2 --> [adc_puls2_psc] --> adc_puls2 --> [adc_puls2_dly] --> adc_puls2_d --> [adc_puls2_fmr] --> adc_puls2_w
    //

    wire adc_puls1, adc_puls2, adc_puls1_d, adc_puls2_d, adc_puls1_w, adc_puls2_w;

    // Pulse frequency prescalers
    fastcounter #(
        .NBITS(23)
    ) adc_puls1_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(1'b0),      // AUTORELOAD
        .i_en(adc_srate1),
        .i_load(1'b0),
        .i_load_q(23'd4_000_000),
        .o_carry(adc_puls1)
    );

    fastcounter #(
        .NBITS(23)
    ) adc_puls2_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(1'b0),      // AUTORELOAD
        .i_en(adc_srate2),
        .i_load(1'b0),
        .i_load_q(23'd1_000_000),
        .o_carry(adc_puls2)
    );

    // Pulse micro-delay (delay is in adc_clk periods, max delay is up to 2x adc_srate periods)
    fastcounter #(
        .NBITS(9)
    ) adc_puls1_dly (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(1'b1),      // ONESHOT
        .i_en(1'b1),
        .i_load(adc_puls1),
        .i_load_q(9'd18),
        .o_zpulse(adc_puls1_d)
    );

    fastcounter #(
        .NBITS(9)
    ) adc_puls2_dly (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(1'b1),      // ONESHOT
        .i_en(1'b1),
        .i_load(adc_puls2),
        .i_load_q(9'd78),
        .o_zpulse(adc_puls2_d)
    );

    // Pulse width formers (width specified in adc_srate periods)
    fastcounter #(
        .NBITS(16)  // enough for 16ms pulse @ adc_srate=4MHz
    ) adc_puls1_fmr (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(1'b1),      // ONESHOT
        .i_en(adc_srate1),
        .i_load(adc_puls1_d),
        .i_load_q(16'd40000),
        .o_nzero(adc_puls1_w)
    );

    fastcounter #(
        .NBITS(16)
    ) adc_puls2_fmr (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(1'b1),      // ONESHOT
        .i_en(adc_srate2),
        .i_load(adc_puls2_d),
        .i_load_q(16'd10000),
        .o_nzero(adc_puls2_w)
    );

    // ------------------
    // ADCs
    // ------------------

    wire adc1_rdy;
    wire adc2_rdy;
    wire [13:0] adc1_data_a;
    wire [13:0] adc1_data_b;
    wire [13:0] adc2_data_a;
    wire [13:0] adc2_data_b;

    ad7357if adc1 (
        // interface
        .i_if_sclk(sys_clk_neg),
        .o_if_cs_n(p_adc1_cs_n),
        .i_if_sdata_a(p_adc1_sda),
        .i_if_sdata_b(p_adc1_sdb),
        // Control
        .i_rst(sys_rst),
        .i_sync(adc_srate1),
        // Data
        .o_ready(adc1_rdy),
        .o_sample_a(adc1_data_a),
        .o_sample_b(adc1_data_b)
    );

    ad7357if adc2 (
        // interface
        .i_if_sclk(sys_clk_neg),
        .o_if_cs_n(p_adc2_cs_n),
        .i_if_sdata_a(p_adc2_sda),
        .i_if_sdata_b(p_adc2_sdb),
        // Control
        .i_rst(sys_rst),
        .i_sync(adc_srate2),
        // Data
        .o_ready(adc2_rdy),
        .o_sample_a(adc2_data_a),
        .o_sample_b(adc2_data_b)
    );

    // -------------------------
    // ADC timing pulse latches
    // -------------------------

    // Here we latch adc_puls1/2 on adc_srate1/2 pulse (start of conversion),
    // so that it can be read later on adc1/2_rdy pulse (end of conversion)
    reg adc_puls1_lat, adc_puls2_lat;
    always @(posedge sys_clk) begin
        if (sys_rst) begin
            adc_puls1_lat <= 1'b0;
            adc_puls2_lat <= 1'b0;
        end else begin
            if (adc_srate1)
                adc_puls1_lat <= adc_puls1;
            if (adc_srate2)
                adc_puls2_lat <= adc_puls2;
        end
    end

    // ------------------
    // ADC data streams
    // ------------------

    // Here we latch ADC data when ADC controller gives a RDY pulse and provide the usual
    // data+ready+valid stream interface for downstream consumers

    // Stream 1 serves ADC1 and is synchronized by ADC1 srate
    // Stream 2 serves ADC2 and is synchronized by ADC2 srate
    // Each stream produces 32-bit data words with following layout:
    // MSB
    //  31      - 0
    //  30      - adc_puls1(2)_lat
    //  29:16   - adc1/2_data_b
    //  15      - 0
    //  14      - adc_puls1(2)_lat
    //  13:0    - adc1(2)_data_a
    // LSB
    //
    // Thus, bits 14 and 30 contain timing pulses which can be used to precisely synchronize hardware
    // adc_puls pulse generators to the data stream

    // ADC1
    reg [31:0] adcstr1_data;
    reg adcstr1_valid;
    wire adcstr1_ready;

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            adcstr1_data <= 32'b0;
            adcstr1_valid <= 1'b0;
        end else begin
            if (adc1_rdy) begin
                adcstr1_valid <= 1'b1;
                adcstr1_data <= {1'b0, adc_puls1_lat, adc1_data_b, 1'b0, adc_puls1_lat, adc1_data_a};
            end else begin
                if (adcstr1_ready) begin
                    adcstr1_valid <= 1'b0;
                end
            end
        end
    end

    // ADC2
    reg [31:0] adcstr2_data;
    reg adcstr2_valid;
    wire adcstr2_ready;

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            adcstr2_data <= 32'b0;
            adcstr2_valid <= 1'b0;
        end else begin
            if (adc2_rdy) begin
                adcstr2_valid <= 1'b1;
                adcstr2_data <= {1'b0, adc_puls2_lat, adc2_data_b, 1'b0, adc_puls2_lat, adc2_data_a};
            end else begin
                if (adcstr2_ready) begin
                    adcstr2_valid <= 1'b0;
                end
            end
        end
    end

    // -------------------------------------------
    // FTDI SyncFIFO streams (in sys_clk domain)
    // -------------------------------------------

    wire [7:0] sys_ft_rx_data;
    wire sys_ft_rx_valid;
    wire sys_ft_rx_ready;
    wire [7:0] sys_ft_tx_data;
    wire sys_ft_tx_valid;
    wire sys_ft_tx_ready;

    // ------------------------
    // Wishbone bus
    // ------------------------

    localparam WB_ADDR_WIDTH = 8;

    // Wishbone master - control port - bus
    wire wbm_cp_cyc;
    wire wbm_cp_stb;
    wire wbm_cp_stall;
    wire wbm_cp_ack;
    wire wbm_cp_we;
    wire [WB_ADDR_WIDTH-1:0] wbm_cp_addr;
    wire [31:0] wbm_cp_wdata;
    wire [3:0] wbm_cp_sel;
    wire [31:0] wbm_cp_rdata;

    // ------------------------
    // Wishbone master: control port
    // ------------------------
    wb_ctrl_port #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .NUM_EMREQS(1)
    ) wb_ctrl_port_i (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        // status
        // .o_err_crc(err_crc),
        // wb
        .o_wb_cyc(wbm_cp_cyc),
        .o_wb_stb(wbm_cp_stb),
        .i_wb_stall(1'b0),  // TODO
        .i_wb_ack(wbm_cp_ack),
        .o_wb_we(wbm_cp_we),
        .o_wb_addr(wbm_cp_addr),
        .o_wb_data(wbm_cp_wdata),
        .o_wb_sel(wbm_cp_sel),
        .i_wb_data(wbm_cp_rdata),
        // rx
        .o_rx_ready(sys_ft_rx_ready),
        .i_rx_data(sys_ft_rx_data),
        .i_rx_valid(sys_ft_rx_valid),
        // tx
        .i_tx_ready(sys_ft_tx_ready),
        .o_tx_data(sys_ft_tx_data),
        .o_tx_valid(sys_ft_tx_valid),
        // TODO: EMREQs
        .i_emreqs_valid(adcstr1_emreq_valid),
        .o_emreqs_ready(adcstr1_emreq_ready),
        .i_emreqs(pack_mreq(1'b0, 1'b0, MREQ_WSIZE_VAL_4BYTE, 8'hFF, 32'h00000080))
    );


    // --------------------------------------
    // Wishbone bus register
    // (this increases fmax and wb latency)
    // --------------------------------------

    // Wishbone master - registered - bus
    wire wbm_reg_cyc;
    wire wbm_reg_stb;
    wire wbm_reg_stall;
    wire wbm_reg_ack;
    wire wbm_reg_we;
    wire [WB_ADDR_WIDTH-1:0] wbm_reg_addr;
    wire [31:0] wbm_reg_wdata;
    wire [3:0] wbm_reg_sel;
    wire [31:0] wbm_reg_rdata;

    wb_reg #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(WB_ADDR_WIDTH)
    ) wb_reg_i (
        .clk(sys_clk),
        .rst(sys_rst),
        //
        .wbm_adr_i(wbm_cp_addr),
        .wbm_dat_i(wbm_cp_wdata),
        .wbm_dat_o(wbm_cp_rdata),
        .wbm_we_i(wbm_cp_we),
        .wbm_sel_i(wbm_cp_sel),
        .wbm_stb_i(wbm_cp_stb),
        .wbm_ack_o(wbm_cp_ack),
        // .wbm_err_o()
        // .wbm_rty_o()
        .wbm_cyc_i(wbm_cp_cyc),
        //
        .wbs_adr_o(wbm_reg_addr),
        .wbs_dat_i(wbm_reg_rdata),
        .wbs_dat_o(wbm_reg_wdata),
        .wbs_we_o(wbm_reg_we),
        .wbs_sel_o(wbm_reg_sel),
        .wbs_stb_o(wbm_reg_stb),
        .wbs_ack_i(wbm_reg_ack),
        .wbs_err_i(1'b0),
        .wbs_rty_i(1'b0),
        .wbs_cyc_o(wbm_reg_cyc)
    );

    // -----------------------------------
    // Wishbone bus switch
    // -----------------------------------

    // Slave IDs
    localparam WBS_ID_MEM = 0;
    localparam WBS_ID_ADCSTR1 = 1;
    localparam WBS_ID_ADCSTR2 = 2;
    localparam WBS_ID_DUMMY = 3;    // dummy always the last one, since it handles all unmapped addresses
    //
    localparam WBS_NUM = 4;

    // Wishbone signals for each slave, flattened
    wire [WBS_NUM-1:0] wbs_cyc;
    wire [WBS_NUM-1:0] wbs_stb;
    wire [WBS_NUM-1:0] wbs_stall;
    wire [WBS_NUM-1:0] wbs_ack;
    wire [WBS_NUM-1:0] wbs_we;
    wire [4*WBS_NUM-1:0] wbs_sel;
    wire [WB_ADDR_WIDTH*WBS_NUM-1:0] wbs_addr;
    wire [32*WBS_NUM-1:0] wbs_wdata;
    wire [32*WBS_NUM-1:0] wbs_rdata;

    // Multiplexer
    wb_mux #(
        .NUM_SLAVES(WBS_NUM),
        .ADDR_WIDTH(WB_ADDR_WIDTH),
        .DATA_WIDTH(32)
    ) wb_mux_i (
        .clk(sys_clk),
        .rst(sys_rst),
        //
        .wbm_adr_i(wbm_reg_addr),
        .wbm_dat_i(wbm_reg_wdata),
        .wbm_dat_o(wbm_reg_rdata),
        .wbm_we_i(wbm_reg_we),
        .wbm_sel_i(wbm_reg_sel),
        .wbm_stb_i(wbm_reg_stb),
        .wbm_ack_o(wbm_reg_ack),
        // .wbm_err_o()
        // .wbm_rty_o()
        .wbm_cyc_i(wbm_reg_cyc),
        //
        .wbs_adr_o(wbs_addr),
        .wbs_dat_i(wbs_rdata),
        .wbs_dat_o(wbs_wdata),
        .wbs_we_o(wbs_we),
        .wbs_sel_o(wbs_sel),
        .wbs_stb_o(wbs_stb),
        .wbs_ack_i(wbs_ack),
        .wbs_err_i({WBS_NUM{1'b0}}),
        .wbs_rty_i({WBS_NUM{1'b0}}),
        .wbs_cyc_o(wbs_cyc),
        // Address map
        // NOTE: it is reversed!! In verilog concatenation is MSB->LSB, and bit indexing is LSB->MSB
        .wbs_addr({
            8'h00,  // 3 - DUMMY - handle all addresses
            8'h22,  // 2 - ADCSTR2
            8'h21,  // 1 - ADCSTR1
            8'h10   // 0 - MEM
        }),
        .wbs_addr_msk({
            8'h00,  // 3
            8'hFF,  // 2
            8'hFF,  // 1
            8'hF0   // 0
        })
    );

    // ---------------------------
    // Wishbone syncFIFOs for ADC
    // ---------------------------
    localparam ADCSTR_SFIFO_ASIZE = 9;

    wire adcstr1_sfifo_full, adcstr2_sfifo_full;
    wire adcstr1_sfifo_half_full, adcstr2_sfifo_half_full;

    wb_rxfifo #(
        .FIFO_ADDR_WIDTH(ADCSTR_SFIFO_ASIZE)
    ) adcstr1_sfifo (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        // wb
        .i_wb_cyc(wbs_cyc[WBS_ID_ADCSTR1]),
        .i_wb_stb(wbs_stb[WBS_ID_ADCSTR1]),
        .o_wb_stall(wbs_stall[WBS_ID_ADCSTR1]),
        .o_wb_ack(wbs_ack[WBS_ID_ADCSTR1]),
        .i_wb_we(wbs_we[WBS_ID_ADCSTR1]),
        .o_wb_data(wbs_rdata[32*(WBS_ID_ADCSTR1+1)-1:32*WBS_ID_ADCSTR1]),
        // rx stream
        .i_rx_valid(adcstr1_valid),
        .o_rx_ready(adcstr1_ready),
        .i_rx_data(adcstr1_data),
        // fifo status
        // .o_fifo_count(fifo_count),
        // .o_fifo_empty(fifo_empty),
        .o_fifo_full(adcstr1_sfifo_full),
        .o_fifo_half_full(adcstr1_sfifo_half_full)
        // .o_fifo_overflow(fifo_overflow),
        // .o_fifo_underflow(fifo_underflow)
    );

    wb_rxfifo #(
        .FIFO_ADDR_WIDTH(ADCSTR_SFIFO_ASIZE)
    ) adcstr2_sfifo (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        // wb
        .i_wb_cyc(wbs_cyc[WBS_ID_ADCSTR2]),
        .i_wb_stb(wbs_stb[WBS_ID_ADCSTR2]),
        .o_wb_stall(wbs_stall[WBS_ID_ADCSTR2]),
        .o_wb_ack(wbs_ack[WBS_ID_ADCSTR2]),
        .i_wb_we(wbs_we[WBS_ID_ADCSTR2]),
        .o_wb_data(wbs_rdata[32*(WBS_ID_ADCSTR2+1)-1:32*WBS_ID_ADCSTR2]),
        // rx stream
        .i_rx_valid(adcstr2_valid),
        .o_rx_ready(adcstr2_ready),
        .i_rx_data(adcstr2_data),
        // fifo status
        // .o_fifo_count(fifo_count),
        // .o_fifo_empty(fifo_empty),
        .o_fifo_full(adcstr2_sfifo_full),
        .o_fifo_half_full(adcstr2_sfifo_half_full)
        // .o_fifo_overflow(fifo_overflow),
        // .o_fifo_underflow(fifo_underflow)
    );

    // -----------------------------------------------
    // EMREQ valid/ready state machine for ADC fifos
    // -----------------------------------------------
    reg adcstr1_emreq_valid, adcstr2_emreq_valid;
    wire adcstr1_emreq_ready, adcstr2_emreq_ready;

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            adcstr1_emreq_valid <= 1'b0;
            adcstr2_emreq_valid <= 1'b0;
        end else begin
            // adc1
            if (adcstr1_sfifo_half_full) begin
                adcstr1_emreq_valid <= 1'b1;
            end else begin
                if (adcstr1_emreq_ready) begin
                    adcstr1_emreq_valid <= 1'b0;
                end
            end
            // adc2
            if (adcstr2_sfifo_half_full) begin
                adcstr2_emreq_valid <= 1'b1;
            end else begin
                if (adcstr2_emreq_ready) begin
                    adcstr2_emreq_valid <= 1'b0;
                end
            end
        end
    end

    // ------------------------
    // Wishbone dummy slave
    // ------------------------
    wb_dummy wb_dummy_i (
        .i_clk(sys_clk),
        // wb
        .i_wb_cyc(wbs_cyc[WBS_ID_DUMMY]),
        .i_wb_stb(wbs_stb[WBS_ID_DUMMY]),
        .o_wb_stall(wbs_stall[WBS_ID_DUMMY]),
        .o_wb_ack(wbs_ack[WBS_ID_DUMMY]),
        .o_wb_data(wbs_rdata[32*(WBS_ID_DUMMY+1)-1:32*WBS_ID_DUMMY])
    );

    // ------------------------
    // Wishbone RAM
    // ------------------------
    wb_mem #(
        .WB_ADDR_WIDTH(4)
    ) wb_mem_i (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        // wb
        .i_wb_cyc(wbs_cyc[WBS_ID_MEM]),
        .i_wb_stb(wbs_stb[WBS_ID_MEM]),
        .o_wb_stall(wbs_stall[WBS_ID_MEM]),
        .o_wb_ack(wbs_ack[WBS_ID_MEM]),
        .i_wb_we(wbs_we[WBS_ID_MEM]),
        .i_wb_addr(wbs_addr[WB_ADDR_WIDTH*WBS_ID_MEM+4-1:WB_ADDR_WIDTH*WBS_ID_MEM]),
        .i_wb_data(wbs_wdata[32*(WBS_ID_MEM+1)-1:32*WBS_ID_MEM]),
        .i_wb_sel(wbs_sel[4*(WBS_ID_MEM+1)-1:4*WBS_ID_MEM]),
        .o_wb_data(wbs_rdata[32*(WBS_ID_MEM+1)-1:32*WBS_ID_MEM])
    );

    // ------------------------
    // DAC driver
    // ------------------------

    dac8551 #(
        .CLK_DIV(10)
    ) dac8551_i (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_wr(1'b1),
        .i_wr_data(24'h007F22),
        .o_dac_sclk(p_spi_dac_sclk),
        .o_dac_sync_n(p_spi_dac_sync_n),
        .o_dac_mosi(p_spi_dac_mosi)
    );


    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                   FTDI SyncFIFO CLOCK DOMAIN                =========================
    // =========================                       @(posedge ft_clk)                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // Clock is generated by FT(2)232H itself. Clock is available only when FT232H is switched to
    // SyncFIFO mode and not in reset. Thus, FPGA must account for the fact that this clock domain
    // is NOT always running when the other FPGA clocks are running

    wire ft_clk;

    // ----------------------------
    // FTDI domain reset generator
    // ----------------------------

    // Reset asserted on:
    //  - FPGA reconfiguration (power on)
    //  - Asynchronously when ft_rst_req goes high
    // Reset deasserted on:
    //  - First ft_clk cycle when ft_rst_req is low
    reg ft_rst = 1'b1;
    wire ft_rst_req;

    // Asynchronously assert FT reset when sys_rst is asserted
    assign ft_rst_req = sys_rst;

    always @(posedge ft_clk or posedge ft_rst_req) begin
        ft_rst <= 1'b0;
        if (ft_rst_req) begin
            ft_rst <= 1'b1;
        end
    end

    // ------------------------
    // FTDI SyncFIFO bidirectional data bus
    // ------------------------
    wire [7:0] ft_fifo_d_in;
    wire [7:0] ft_fifo_d_out;
    wire ft_fifo_d_oe;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01)
    ) ft_fifo_data_pins [7:0] (
        .PACKAGE_PIN(p_ft_fifo_d),
        .OUTPUT_ENABLE(ft_fifo_d_oe),
        .D_OUT_0(ft_fifo_d_out),
        .D_IN_0(ft_fifo_d_in)
    );

    // ------------------------
    // FTDI SyncFIFO port
    // ------------------------

    // Side A:
    //      FT(2)232H SyncFIFO bus
    // Side B:
    //      Data-ready-valid Rx & Tx byte streams

    wire [7:0] ft_tx_data;
    wire ft_tx_valid;
    wire ft_tx_ready;
    wire [7:0] ft_rx_data;
    wire ft_rx_valid;
    wire ft_rx_ready;
    wire [3:0] ft_dbg;

    ft245sync ft245sync_i (
        // SYSCON
        .o_clk(ft_clk),
        .i_rst(ft_rst),
        // pins
        .i_pin_clkout(p_ft_fifo_clkout),
        .o_pin_oe_n(p_ft_fifo_oe_n),
        .o_pin_siwu(p_ft_fifo_siwu),
        .o_pin_wr_n(p_ft_fifo_wr_n),
        .o_pin_rd_n(p_ft_fifo_rd_n),
        .i_pin_rxf_n(p_ft_fifo_rxf_n),
        .i_pin_txe_n(p_ft_fifo_txe_n),
        .i_pin_data(ft_fifo_d_in),
        .o_pin_data(ft_fifo_d_out),
        .o_pin_data_oe(ft_fifo_d_oe),
        // Streams
        .i_tx_data(ft_tx_data),
        .i_tx_valid(ft_tx_valid),
        .o_tx_ready(ft_tx_ready),
        .o_rx_data(ft_rx_data),
        .o_rx_valid(ft_rx_valid),
        .i_rx_ready(ft_rx_ready),
        // debug
        .o_dbg(ft_dbg)
    );

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                    CLOCK DOMAIN CROSSING                    =========================
    // =========================            @(posedge sys_clk) / @(posedge ft_clk)           =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    localparam FT_AFIFO_ASIZE = 9;  // 9 bit address -> 512 bytes, 1x ICE40 4K BRAM block

    // Two asynchronous FIFOs: one for Rx stream, one for Tx stream
    // To fit nicely on iCE40, each FIFO uses one whole 4K BRAM block
    // NOTE: resets here are asynchronous assert -> synchronous release

    // ft_clk domain
    wire ft_afifo_rx_wfull;
    wire ft_afifo_tx_rempty;
    assign ft_rx_ready = !ft_afifo_rx_wfull;
    assign ft_tx_valid = !ft_afifo_tx_rempty;
    // sys_clk domain
    wire ft_afifo_rx_rempty;
    wire ft_afifo_tx_wfull;
    assign sys_ft_rx_valid = !ft_afifo_rx_rempty;
    assign sys_ft_tx_ready = !ft_afifo_tx_wfull;

    async_fifo #(
        .DSIZE(8),
        .ASIZE(FT_AFIFO_ASIZE),
        .FALLTHROUGH("FALSE")
    ) ft_afifo_rx (
        //
        .wclk(ft_clk),
        .wrst_n(!ft_rst),
        //
        .winc(ft_rx_valid && ft_rx_ready),
        .wdata(ft_rx_data),
        .wfull(ft_afifo_rx_wfull),
        //
        .rclk(sys_clk),
        .rrst_n(!sys_rst),
        //
        .rinc(sys_ft_rx_valid && sys_ft_rx_ready),
        .rdata(sys_ft_rx_data),
        .rempty(ft_afifo_rx_rempty)
    );

    async_fifo #(
        .DSIZE(8),
        .ASIZE(FT_AFIFO_ASIZE),
        .FALLTHROUGH("FALSE")
    ) ft_afifo_tx (
        //
        .wclk(sys_clk),
        .wrst_n(!sys_rst),
        //
        .winc(sys_ft_tx_valid && sys_ft_tx_ready),
        .wdata(sys_ft_tx_data),
        .wfull(ft_afifo_tx_wfull),
        //
        .rclk(ft_clk),
        .rrst_n(!ft_rst),
        //
        .rinc(ft_tx_valid && ft_tx_ready),
        .rdata(ft_tx_data),
        .rempty(ft_afifo_tx_rempty)
    );

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                    OUTPUT PIN DRIVERS                       =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ------------------------
    // CLK OUT
    // ------------------------
    assign p_clk_out_sel = 1'b1;
    assign p_clk_out = ~adcstr1_sfifo_full;

    // ------------------------
    // LEDs
    // ------------------------
    assign p_led_sts_r = ft_dbg[0];
    assign p_led_sts_g = ft_dbg[1];
    //
    assign p_led_in1_r = ft_tx_valid;   // 0
    assign p_led_in1_g = ft_tx_ready;   // 1
    assign p_led_in2_r = ft_rx_valid;   // 1
    assign p_led_in2_g = ft_rx_ready;   // 0
    // assign p_led_in3_r = ~p_ft_fifo_rxf_n;
    // assign p_led_in3_g = 0;
    // assign p_led_in4_r = ~p_ft_fifo_txe_n;
    // assign p_led_in4_g = 0;
    assign p_led_in3_r = adcstr1_emreq_valid;
    assign p_led_in3_g = adc_puls1_w;
    assign p_led_in4_r = adcstr1_emreq_ready;
    assign p_led_in4_g = adc_puls2_w;


endmodule
