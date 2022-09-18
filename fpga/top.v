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
    output p_ft_fifo_siwu_n,
    output p_ft_fifo_wr_n,
    output p_ft_fifo_rd_n,
    input p_ft_fifo_txe_n,
    input p_ft_fifo_rxf_n,
    inout [7:0] p_ft_fifo_d
);

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                        CLOCK GENERATION                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ------------------------------------------
    //                  SYS PLL
    //
    // input: 20MHz
    // output: 80MHz
    // ------------------------------------------
    wire sys_pll_out;
    wire sys_pll_lock;

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'd0),
		.DIVF(7'd63),
		.DIVQ(3'd3),
		.FILTER_RANGE(3'd3),
        .PLLOUT_SELECT("GENCLK")
    ) sys_pll (
        //.REFERENCECLK (p_clk_20mhz_gbin1),  // 20 MHz
        .REFERENCECLK (p_clk_ref_in),  // CLK_IN SMA
        .PLLOUTCORE (sys_pll_out),
        .LOCK (sys_pll_lock),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );

    // Output PLL clock on the pin
    assign p_adc_sclk = sys_pll_out;


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

    // --------------------------------------------------
    // System reset generator
    // --------------------------------------------------

    // sys_rst is async assert, sync de-assert
    // Asserted on / by:
    //  1. FPGA initialization
    //  2. PLL "not locked" condition
    //  3. csr_sys_rst CSR bit

    wire sys_rst;
    wire csr_sys_rst;

    rst_bridge #(
        .INITIAL_VAL(1'b1)
    ) sys_rst_gen (
        .clk(sys_clk),
        .rst((~sys_pll_lock) | csr_sys_rst),
        .out(sys_rst)
    );

    // --------------------------------------------------
    //      ADCT - ADC timing generators
    // --------------------------------------------------


    // Sample rate generators (SRATE pulses)
    //
    //                      +----> [adct_srate1_psc] ----> adct_srate1 ----> [ADC1]
    //  sys_clk (80MHz) ->--+
    //                      +----> [adct_srate2_psc] ----> adct_srate2 ----> [ADC2]
    //
    wire adct_srate1, adct_srate2;

    // CSR (control & status register) values
    wire csr_adct_srate1_en, csr_adct_srate2_en;
    wire [7:0] csr_adct_srate1_psc_div, csr_adct_srate2_psc_div;

    fastcounter #(
        .NBITS(8)
    ) adct_srate1_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(csr_adct_srate1_en),
        .i_load(1'b0),
        .i_load_q(csr_adct_srate1_psc_div),
        .o_carry_dly(adct_srate1)
    );

    fastcounter #(
        .NBITS(8)
    ) adct_srate2_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(csr_adct_srate2_en),
        .i_load(1'b0),
        .i_load_q(csr_adct_srate2_psc_div),
        .o_carry_dly(adct_srate2)
    );

    //  Timing pulse generators
    //
    //  adct_srate1 --> [adct_puls1_psc] --> adct_puls1 --> [adct_puls1_dly] --> adct_puls1_d --> [adct_puls1_fmr] --> adct_puls1_w
    //  adct_srate2 --> [adct_puls2_psc] --> adct_puls2 --> [adct_puls2_dly] --> adct_puls2_d --> [adct_puls2_fmr] --> adct_puls2_w
    //

    wire adct_puls1, adct_puls2;        // single-cycle pulses synced with adct_srate*
    wire adct_puls1_d, adct_puls2_d;    // single-cycle pulses delayed w.r.t adct_puls*
    wire adct_puls1_w, adct_puls2_w;    // width-controlled version of adct_puls*_d

    // CSR values
    wire csr_adct_puls1_en, csr_adct_puls2_en;
    wire [22:0] csr_adct_puls1_psc_div, csr_adct_puls2_psc_div;
    wire [8:0] csr_adct_puls1_dly, csr_adct_puls2_dly;
    wire [15:0] csr_adct_puls1_pwidth, csr_adct_puls2_pwidth;

    // Pulse frequency prescalers
    fastcounter #(
        .NBITS(23)
    ) adct_puls1_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(adct_srate1 & csr_adct_puls1_en),
        .i_load(1'b0),
        .i_load_q(csr_adct_puls1_psc_div),
        .o_carry_dly(adct_puls1)
    );

    fastcounter #(
        .NBITS(23)
    ) adct_puls2_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(adct_srate2 & csr_adct_puls2_en),
        .i_load(1'b0),
        .i_load_q(csr_adct_puls2_psc_div),
        .o_carry_dly(adct_puls2)
    );

    // Pulse micro-delay (delay is in adc_clk periods, max delay is up to 2x adc_srate periods)
    fastcounter #(
        .NBITS(9)
    ) adct_puls1_dly (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd1),      // ONESHOT
        .i_dir(1'b0),       // DOWN
        .i_en(1'b1),
        .i_load(adct_puls1),
        .i_load_q(csr_adct_puls1_dly),
        .o_epulse(adct_puls1_d)
    );

    fastcounter #(
        .NBITS(9)
    ) adct_puls2_dly (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd1),      // ONESHOT
        .i_dir(1'b0),       // DOWN
        .i_en(1'b1),
        .i_load(adct_puls2),
        .i_load_q(csr_adct_puls2_dly),
        .o_epulse(adct_puls2_d)
    );

    // Pulse width formers (width specified in adc_srate periods)
    fastcounter #(
        .NBITS(16)  // enough for 16ms pulse @ adc_srate=4MHz
    ) adct_puls1_fmr (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd1),      // ONESHOT
        .i_dir(1'b0),       // DOWN
        .i_en(adct_srate1),
        .i_load(adct_puls1_d),
        .i_load_q(csr_adct_puls1_pwidth),
        .o_nend(adct_puls1_w)
    );

    fastcounter #(
        .NBITS(16)
    ) adct_puls2_fmr (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd1),      // ONESHOT
        .i_dir(1'b0),       // DOWN
        .i_en(adct_srate2),
        .i_load(adct_puls2_d),
        .i_load_q(csr_adct_puls2_pwidth),
        .o_nend(adct_puls2_w)
    );

    // --------------------------------------------------
    //     ADC - Analog-to-digital converters
    // --------------------------------------------------

    wire csr_adc_adc1_en, csr_adc_adc2_en;

    wire adc1_start = adct_srate1 & csr_adc_adc1_en;
    wire adc2_start = adct_srate2 & csr_adc_adc2_en;
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
        .i_sync(adc1_start),
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
        .i_sync(adc2_start),
        // Data
        .o_ready(adc2_rdy),
        .o_sample_a(adc2_data_a),
        .o_sample_b(adc2_data_b)
    );

    // -------------------------
    // ADC timing pulse latches
    // -------------------------

    // This synchronizes adct_puls1/2 with adc1/2_rdy
    reg adc1_puls, adc2_puls;
    always @(posedge sys_clk or posedge sys_rst)
        if (sys_rst) begin
            adc1_puls <= 1'b0;
            adc2_puls <= 1'b0;
        end else begin
            if (adc1_rdy)
                adc1_puls <= 1'b0;
            else if (adct_puls1)
                adc1_puls <= 1'b1;
            //
            if (adc2_rdy)
                adc2_puls <= 1'b0;
            else if (adct_puls2)
                adc2_puls <= 1'b1;
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
    //  30      - adc1(2)_puls
    //  29:16   - adc1(2)_data_b
    //  15      - 0
    //  14      - adc1(2)_puls
    //  13:0    - adc1(2)_data_a
    // LSB
    //
    // Thus, bits 14 and 30 contain timing pulses which can be used to precisely synchronize hardware
    // adc_puls pulse generators to the data stream

    // ADC1
    reg [31:0] adc1_str_data;
    reg adc1_str_valid;
    wire adc1_str_ready;

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            adc1_str_data <= 32'b0;
            adc1_str_valid <= 1'b0;
        end else begin
            if (adc1_rdy) begin
                adc1_str_valid <= 1'b1;
                adc1_str_data <= {1'b0, adc1_puls, adc1_data_b, 1'b0, adc1_puls, adc1_data_a};
            end else begin
                if (adc1_str_ready) begin
                    adc1_str_valid <= 1'b0;
                end
            end
        end
    end

    // ADC2
    reg [31:0] adc2_str_data;
    reg adc2_str_valid;
    wire adc2_str_ready;

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            adc2_str_data <= 32'b0;
            adc2_str_valid <= 1'b0;
        end else begin
            if (adc2_rdy) begin
                adc2_str_valid <= 1'b1;
                adc2_str_data <= {1'b0, adc2_puls, adc2_data_b, 1'b0, adc2_puls, adc2_data_a};
            end else begin
                if (adc2_str_ready) begin
                    adc2_str_valid <= 1'b0;
                end
            end
        end
    end

    // ---------------------------
    //          ADC FIFOs
    // ---------------------------
    localparam ADC_FIFO_ASIZE = 9;

    // ADC1
    wire adc1_fifo_empty, adc1_fifo_full, adc1_fifo_hfull, adc1_fifo_ovfl, adc1_fifo_udfl;
    // in stream: adc1_str
    assign adc1_str_ready = !adc1_fifo_full;
    // out stream: adc1_wstr
    wire [31:0] adc1_wstr_data;
    wire adc1_wstr_valid = !adc1_fifo_empty;
    wire adc1_wstr_ready;

    syncfifo #(
        .ADDR_WIDTH(ADC_FIFO_ASIZE),
        .DATA_WIDTH(32)
    ) adc1_fifo (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        // data
        .i_data(adc1_str_data),
        .o_data(adc1_wstr_data),
        // control
        .i_wr(adc1_str_valid & adc1_str_ready),
        .i_rd(adc1_wstr_valid & adc1_wstr_ready),
        // status
        .o_empty(adc1_fifo_empty),
        .o_full(adc1_fifo_full),
        .o_half_full(adc1_fifo_hfull),
        .o_overflow(adc1_fifo_ovfl),
        .o_underflow(adc1_fifo_udfl)
    );

    // OVFL/UDFL flags latch
    wire adc1_fifo_ovfl_lclr, adc1_fifo_udfl_lclr;
    reg adc1_fifo_ovfl_lval, adc1_fifo_udfl_lval;
    always @(posedge sys_clk) begin
        if (sys_rst) begin
            adc1_fifo_ovfl_lval <= 1'b0;
            adc1_fifo_udfl_lval <= 1'b0;
        end else begin
            adc1_fifo_ovfl_lval <= adc1_fifo_ovfl | (adc1_fifo_ovfl_lval & ~adc1_fifo_ovfl_lclr);
            adc1_fifo_udfl_lval <= adc1_fifo_udfl | (adc1_fifo_udfl_lval & ~adc1_fifo_udfl_lclr);
        end
    end

    // ADC2
    wire adc2_fifo_empty, adc2_fifo_full, adc2_fifo_hfull, adc2_fifo_ovfl, adc2_fifo_udfl;
    // in stream: adc2_str
    assign adc2_str_ready = !adc2_fifo_full;
    // out stream: adc2_wstr
    wire [31:0] adc2_wstr_data;
    wire adc2_wstr_valid = !adc2_fifo_empty;
    wire adc2_wstr_ready;

    syncfifo #(
        .ADDR_WIDTH(ADC_FIFO_ASIZE),
        .DATA_WIDTH(32)
    ) adc2_fifo (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        // data
        .i_data(adc2_str_data),
        .o_data(adc2_wstr_data),
        // control
        .i_wr(adc2_str_valid & adc2_str_ready),
        .i_rd(adc2_wstr_valid & adc2_wstr_ready),
        // status
        .o_empty(adc2_fifo_empty),
        .o_full(adc2_fifo_full),
        .o_half_full(adc2_fifo_hfull),
        .o_overflow(adc2_fifo_ovfl),
        .o_underflow(adc2_fifo_udfl)
    );

    // OVFL/UDFL flags latch
    wire adc2_fifo_ovfl_lclr, adc2_fifo_udfl_lclr;
    reg adc2_fifo_ovfl_lval, adc2_fifo_udfl_lval;
    always @(posedge sys_clk) begin
        if (sys_rst) begin
            adc2_fifo_ovfl_lval <= 1'b0;
            adc2_fifo_udfl_lval <= 1'b0;
        end else begin
            adc2_fifo_ovfl_lval <= adc2_fifo_ovfl | (adc2_fifo_ovfl_lval & ~adc2_fifo_ovfl_lclr);
            adc2_fifo_udfl_lval <= adc2_fifo_udfl | (adc2_fifo_udfl_lval & ~adc2_fifo_udfl_lclr);
        end
    end

    // -----------------------------------------------
    // Word-to-byte ADC stream converters
    // -----------------------------------------------

    // ADC1 byte stream
    wire [7:0] adc1_bstr_data;
    wire adc1_bstr_valid;
    wire adc1_bstr_ready;

    word_ser #(
        .WORD_BITS(32)
    ) adc1_word_ser (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_data(adc1_wstr_data),
        .i_valid(adc1_wstr_valid),
        .o_ready(adc1_wstr_ready),
        //
        .o_data(adc1_bstr_data),
        .o_valid(adc1_bstr_valid),
        .i_ready(adc1_bstr_ready)
    );

    // ADC2 byte stream
    wire [7:0] adc2_bstr_data;
    wire adc2_bstr_valid;
    wire adc2_bstr_ready;

    word_ser #(
        .WORD_BITS(32)
    ) adc2_word_ser (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_data(adc2_wstr_data),
        .i_valid(adc2_wstr_valid),
        .o_ready(adc2_wstr_ready),
        //
        .o_data(adc2_bstr_data),
        .o_valid(adc2_bstr_valid),
        .i_ready(adc2_bstr_ready)
    );

    // ------------------------
    // DAC driver
    // ------------------------

    wire csr_ftun_vtune_write;
    wire [15:0] csr_ftun_vtune_val;

    // Initiate DAC write upon reset
    reg dac_init;
    always @(posedge sys_clk or posedge sys_rst)
        if (sys_rst)
            dac_init <= 1'b1;
        else
            dac_init <= 1'b0;

    dac8551 #(
        .CLK_DIV(20)
    ) dac8551_i (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_wr(csr_ftun_vtune_write || dac_init),
        .i_wr_data({8'b0, csr_ftun_vtune_val}),
        .o_dac_sclk(p_spi_dac_sclk),
        .o_dac_sync_n(p_spi_dac_sync_n),
        .o_dac_mosi(p_spi_dac_mosi)
    );

    // ------------------------
    // Phase detector
    // ------------------------

    // ECLK1: 20 MHz onboard clock
    // ECLK2: CLK_IN connector
    // CLK: sys_clk (80MHz)

    // N1=99999 results in max comparison frequency of 100 Hz
    // Returned measurement range is 0 to 800000 ( f(sys_clk)/100 )
    // 20 bits is enough for that range
    //
    // N2=49999 allows best performance with 10MHz external reference,
    // while 1,2,5,20 MHz can also be used

    localparam PDET_BITS = 20;
    localparam PDET_N1 = 99_999;
    localparam PDET_N2 = 49_999;

    wire csr_pdet_en;
    wire csr_pdet_eclk2_slow;
    wire [PDET_BITS-1:0] pdet_count;
    wire pdet_count_rdy;

    phase_det #(
        .TIC_BITS(PDET_BITS),
        .DIV_N1(PDET_N1),
        .DIV_N2(PDET_N2)
    ) pdet (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_en(csr_pdet_en),
        .i_eclk2_slow(csr_pdet_eclk2_slow),
        //
        .o_count(pdet_count),
        .o_count_rdy(pdet_count_rdy),
        //
        .i_eclk1(p_clk_20mhz_gbin1),
        .i_eclk2(p_clk_ref_in)
    );

    // Stream interface
    reg [31:0] pdet_wstr_data;
    reg pdet_wstr_valid;
    wire pdet_wstr_ready;

    always @(posedge sys_clk or posedge sys_rst)
        if (sys_rst) begin
            pdet_wstr_data <= 32'b0;
            pdet_wstr_valid <= 1'b0;
        end else begin
            if (pdet_count_rdy) begin
                pdet_wstr_valid <= 1'b1;
                pdet_wstr_data <= 32'd0;
                pdet_wstr_data[PDET_BITS-1:0] <= pdet_count;
            end else if (pdet_wstr_ready) begin
                pdet_wstr_valid <= 1'b0;
            end
        end

    // Byte serializer
    wire [7:0] pdet_bstr_data;
    wire pdet_bstr_valid;
    wire pdet_bstr_ready;

    word_ser #(
        .WORD_BITS(32)
    ) pdet_word_ser (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_data(pdet_wstr_data),
        .i_valid(pdet_wstr_valid),
        .o_ready(pdet_wstr_ready),
        //
        .o_data(pdet_bstr_data),
        .o_valid(pdet_bstr_valid),
        .i_ready(pdet_bstr_ready)
    );

    // ------------------------
    // Wishbone bus
    // ------------------------

    localparam WB_ADDR_WIDTH = 8;
    localparam WB_DATA_WIDTH = 16;
    localparam WB_SEL_WIDTH = 2;
    localparam WB_BYTE_ADDR_BITS = $clog2((WB_DATA_WIDTH + 7) / 8);

    // Wishbone master - control port - bus
    wire wbm_cp_cyc;
    wire wbm_cp_stb;
    wire wbm_cp_stall;
    wire wbm_cp_ack;
    wire wbm_cp_we;
    wire [WB_ADDR_WIDTH-1:0] wbm_cp_addr;
    wire [WB_DATA_WIDTH-1:0] wbm_cp_wdata;
    wire [WB_SEL_WIDTH-1:0] wbm_cp_sel;
    wire [WB_DATA_WIDTH-1:0] wbm_cp_rdata;

    // Wishbone port Rx command stream (incoming data)
    wire [7:0] wbcon_rx_data;
    wire wbcon_rx_valid;
    wire wbcon_rx_ready;
    // Wishbone port Tx command stream (outgoing data)
    wire [7:0] wbcon_tx_data;
    wire wbcon_tx_valid;
    wire wbcon_tx_ready;

    // ------------------------
    // Wishbone master: control port
    // ------------------------
    wbcon #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .WB_DATA_WIDTH(WB_DATA_WIDTH),
        .WB_SEL_WIDTH(WB_SEL_WIDTH),
        .COUNT_WIDTH(8)
    ) wbcon_i (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        // wb
        .o_wb_cyc(wbm_cp_cyc),
        .o_wb_stb(wbm_cp_stb),
        .i_wb_stall(wbm_cp_stall),
        .i_wb_ack(wbm_cp_ack),
        .o_wb_we(wbm_cp_we),
        .o_wb_addr(wbm_cp_addr),
        .o_wb_data(wbm_cp_wdata),
        .o_wb_sel(wbm_cp_sel),
        .i_wb_data(wbm_cp_rdata),
        // rx
        .i_rx_data(wbcon_rx_data),
        .i_rx_valid(wbcon_rx_valid),
        .o_rx_ready(wbcon_rx_ready),
        // tx
        .o_tx_data(wbcon_tx_data),
        .o_tx_valid(wbcon_tx_valid),
        .i_tx_ready(wbcon_tx_ready)
    );

    // --------------------------------------
    // Control and status registers
    // --------------------------------------

    lwdo_regs #(
        .ADDRESS_WIDTH(WB_ADDR_WIDTH+WB_BYTE_ADDR_BITS),
        .DEFAULT_READ_DATA(16'hDEAD),
        .PDET_N1_VAL_INITIAL_VALUE(PDET_N1),
        .PDET_N2_VAL_INITIAL_VALUE(PDET_N2)
    ) lwdo_regs_i (
        // SYSCON
        .i_clk(sys_clk),
        .i_rst_n(~sys_rst),

        // WISHBONE
        .i_wb_cyc(wbm_cp_cyc),
        .i_wb_stb(wbm_cp_stb),
        .o_wb_stall(wbm_cp_stall),
        .i_wb_adr({wbm_cp_addr, {WB_BYTE_ADDR_BITS{1'b0}}}),
        .i_wb_we(wbm_cp_we),
        .i_wb_dat(wbm_cp_wdata),
        .i_wb_sel(wbm_cp_sel),
        .o_wb_ack(wbm_cp_ack),
        .o_wb_dat(wbm_cp_rdata),

        // REGS: SYS
        .o_sys_con_sys_rst(csr_sys_rst),
        // REGS: PDET
        .o_pdet_con_en(csr_pdet_en),
        .o_pdet_con_eclk2_slow(csr_pdet_eclk2_slow),
        // REGS: ADCT
        .o_adct_con_srate1_en(csr_adct_srate1_en),
        .o_adct_con_srate2_en(csr_adct_srate2_en),
        .o_adct_con_puls1_en(csr_adct_puls1_en),
        .o_adct_con_puls2_en(csr_adct_puls2_en),
        .o_adct_srate1_psc_div_val(csr_adct_srate1_psc_div),
        .o_adct_srate2_psc_div_val(csr_adct_srate2_psc_div),
        .o_adct_puls1_psc_div_val(csr_adct_puls1_psc_div),
        .o_adct_puls2_psc_div_val(csr_adct_puls2_psc_div),
        .o_adct_puls1_dly_val(csr_adct_puls1_dly),
        .o_adct_puls2_dly_val(csr_adct_puls2_dly),
        .o_adct_puls1_pwidth_val(csr_adct_puls1_pwidth),
        .o_adct_puls2_pwidth_val(csr_adct_puls2_pwidth),
        // REGS: ADC CON
        .o_adc_con_adc1_en(csr_adc_adc1_en),
        .o_adc_con_adc2_en(csr_adc_adc2_en),
        // REGS: ADC FIFO1
        .i_adc_fifo1_sts_empty(adc1_fifo_empty),
        .i_adc_fifo1_sts_full(adc1_fifo_full),
        .i_adc_fifo1_sts_hfull(adc1_fifo_hfull),
        .i_adc_fifo1_sts_ovfl(adc1_fifo_ovfl_lval),
        .o_adc_fifo1_sts_ovfl_read_trigger(adc1_fifo_ovfl_lclr),
        .i_adc_fifo1_sts_udfl(adc1_fifo_udfl_lval),
        .o_adc_fifo1_sts_udfl_read_trigger(adc1_fifo_udfl_lclr),
        // REGS: ADC FIFO2
        .i_adc_fifo2_sts_empty(adc2_fifo_empty),
        .i_adc_fifo2_sts_full(adc2_fifo_full),
        .i_adc_fifo2_sts_hfull(adc2_fifo_hfull),
        .i_adc_fifo2_sts_ovfl(adc2_fifo_ovfl_lval),
        .o_adc_fifo2_sts_ovfl_read_trigger(adc2_fifo_ovfl_lclr),
        .i_adc_fifo2_sts_udfl(adc2_fifo_udfl_lval),
        .o_adc_fifo2_sts_udfl_read_trigger(adc2_fifo_udfl_lclr),
        // REGS: FTUN
        .o_ftun_vtune_set_val(csr_ftun_vtune_val),
        .o_ftun_vtune_set_val_write_trigger(csr_ftun_vtune_write)
    );

    // -------------------------------------------
    // FTDI SyncFIFO streams (in sys_clk domain)
    // -------------------------------------------

    wire [7:0] sys_ft_rx_data;
    wire sys_ft_rx_valid;
    wire sys_ft_rx_ready;
    wire [7:0] sys_ft_tx_data;
    wire sys_ft_tx_valid;
    wire sys_ft_tx_ready;

    // ----------------------------------
    // Control port stream management
    // ----------------------------------

    wire cpstr_send_stridx;

    cpstr_mgr_rx cpstr_mgr_rx (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_data(sys_ft_rx_data),
        .i_valid(sys_ft_rx_valid),
        .o_ready(sys_ft_rx_ready),
        //
        .o_data(wbcon_rx_data),
        .o_valid(wbcon_rx_valid),
        .i_ready(wbcon_rx_ready),
        //
        .o_send_stridx(cpstr_send_stridx)
    );


    // Index allocation for multiplexed Tx streams:
    //  0 - control port (wbcon_tx)
    //  1 - ADC1 data stream
    //  2 - ADC2 data stream
    //  3 - Phase detector measurement

    cpstr_mgr_tx #(
        .NUM_STREAMS(4),
        .MAX_BURST(32)
    ) cpstr_mgr_tx (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .o_data(cpstr_tx_buf_data),
        .o_valid(cpstr_tx_buf_valid),
        .i_ready(cpstr_tx_buf_ready),
        //
        .i_data({
            pdet_bstr_data,
            adc2_bstr_data,
            adc1_bstr_data,
            wbcon_tx_data}),
        .i_valid({
            pdet_bstr_valid,
            adc2_bstr_valid,
            adc1_bstr_valid,
            wbcon_tx_valid}),
        .o_ready({
            pdet_bstr_ready,
            adc2_bstr_ready,
            adc1_bstr_ready,
            wbcon_tx_ready}),
        //
        .i_send_stridx(cpstr_send_stridx)
    );

    // ---------------------------------------
    // Buffer Tx stream to improve timing
    // ---------------------------------------

    wire [7:0] cpstr_tx_buf_data;
    wire cpstr_tx_buf_valid;
    wire cpstr_tx_buf_ready;

    stream_buf cpstr_tx_buf (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .o_data(sys_ft_tx_data),
        .o_valid(sys_ft_tx_valid),
        .i_ready(sys_ft_tx_ready),
        //
        .i_data(cpstr_tx_buf_data),
        .i_valid(cpstr_tx_buf_valid),
        .o_ready(cpstr_tx_buf_ready)
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

    // ft_rst is async assert, sync de-assert
    // Asserted on / by:
    //  1. FPGA initialization
    //  2. sys_rst

    wire ft_rst;

    rst_bridge #(
        .INITIAL_VAL(1'b1)
    ) ft_rst_gen (
        .clk(ft_clk),
        .rst(sys_rst),
        .out(ft_rst)
    );

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
        .o_pin_siwu_n(p_ft_fifo_siwu_n),
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

    // FIFO size: 256 bytes. That's half of ICE40 4K BRAM, but it improves timing compared to 512.
    localparam FT_AFIFO_ASIZE = 8;

    // Two asynchronous FIFOs: one for Rx stream, one for Tx stream
    // NOTE: resets here are asynchronous assert, synchronous release

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
    assign p_clk_out = ~(adc1_fifo_full | adc2_fifo_full); //sys_clk;

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
    assign p_led_in3_r = sys_pll_lock;
    assign p_led_in3_g = 0;
    assign p_led_in4_r = adct_puls1_w;
    assign p_led_in4_g = adct_puls2_w;


endmodule
