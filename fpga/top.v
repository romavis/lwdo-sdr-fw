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
    // ADC
    output p_adc_sclk,
    input [3:0] p_adc_sdata,
    output [1:0] p_adc_cs_n,
    // External I/O,
    inout [8:1] p_extio,
    // SPI DAC,
    output p_spi_dac_mosi,
    output p_spi_dac_sclk,
    output p_spi_dac_sync_n,
    // System clocks
    input p_clk_20mhz_gbin1,    // VCTCXO clock, drives SB_PLL40_PAD
    input p_clk_20mhz_gbin2,    // same VCTCXO clock for non-PLL use
    input p_clk_ref_in,
    output p_clk_out_sel,
    output p_clk_out,
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

    // // SDATA DDR clk generator
    // // Clock can be delayed by a few ns wrt SCLK to delay latching of SDATA.
    // // This is needed to compensate for a long SCLK->SDATA delay of AD7357,
    // // as well as delays of FPGA SCLK output and SDATA input cells.
    // generate
    //     genvar i;
    //     for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
    //         lut_delay #(
    //             .DELAY(SDATA_LATCH_DELAY[32*i+31:32*i])
    //         ) u_sdata_ddr_clk_delay (
    //             .d(i_ctl_ddr_clk),
    //             .q(o_adc_sdata_ddr_clk[i])
    //         );
    //     end
    // endgenerate

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
    // (determined by parameters below)
    // ------------------------------------------

    // PLL params configured here & made available via read-only CSRs
    localparam [3:0] SYS_PLL_DIVR = 4'd0;
    localparam [6:0] SYS_PLL_DIVF = 7'd31;
    localparam [2:0] SYS_PLL_DIVQ = 3'd3;
    localparam [2:0] SYS_PLL_FILTER_RANGE = 3'd3;

    wire sys_pll_out;
    wire sys_pll_lock;

    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
		.DIVR(SYS_PLL_DIVR),
		.DIVF(SYS_PLL_DIVF),
		.DIVQ(SYS_PLL_DIVQ),
		.FILTER_RANGE(SYS_PLL_FILTER_RANGE),
        .PLLOUT_SELECT("GENCLK")
    ) sys_pll (
        .PACKAGEPIN(p_clk_20mhz_gbin1),  // 20 MHz
        .PLLOUTCORE(sys_pll_out),
        .LOCK(sys_pll_lock),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );


    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                      SYSTEM CLOCK DOMAIN                    =========================
    // =========================                       @(posedge sys_clk)                    =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    wire sys_clk = sys_pll_out;

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
        .NBITS(26)
    ) adct_srate1_psc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        // .i_en(csr_adct_srate1_en),
            .i_en(1'b1),
        .i_load(1'b0),
        // .i_load_q(csr_adct_srate1_psc_div),
            .i_load_q(26'hFFFFFF),
        .o_carry_dly(adct_srate1)
    );

    // fastcounter #(
    //     .NBITS(8)
    // ) adct_srate2_psc (
    //     .i_clk(sys_clk),
    //     .i_rst(sys_rst),
    //     .i_mode(2'd0),      // AUTORELOAD
    //     .i_dir(1'b0),       // DOWN
    //     .i_en(csr_adct_srate2_en),
    //     .i_load(1'b0),
    //     .i_load_q(csr_adct_srate2_psc_div),
    //     .o_carry_dly(adct_srate2)
    // );

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
        // .i_en(adct_srate1 & csr_adct_puls1_en),
            .i_en(adct_srate1),
        .i_load(1'b0),
        // .i_load_q(csr_adct_puls1_psc_div),
            .i_load_q(23'd9),
        .o_carry_dly(adct_puls1)
    );

    // fastcounter #(
    //     .NBITS(23)
    // ) adct_puls2_psc (
    //     .i_clk(sys_clk),
    //     .i_rst(sys_rst),
    //     .i_mode(2'd0),      // AUTORELOAD
    //     .i_dir(1'b0),       // DOWN
    //     .i_en(adct_srate2 & csr_adct_puls2_en),
    //     .i_load(1'b0),
    //     .i_load_q(csr_adct_puls2_psc_div),
    //     .o_carry_dly(adct_puls2)
    // );

    // // Pulse micro-delay (delay is in adc_clk periods, max delay is up to 2x adc_srate periods)
    // fastcounter #(
    //     .NBITS(9)
    // ) adct_puls1_dly (
    //     .i_clk(sys_clk),
    //     .i_rst(sys_rst),
    //     .i_mode(2'd1),      // ONESHOT
    //     .i_dir(1'b0),       // DOWN
    //     .i_en(1'b1),
    //     .i_load(adct_puls1),
    //     .i_load_q(csr_adct_puls1_dly),
    //     .o_epulse(adct_puls1_d)
    // );

    // fastcounter #(
    //     .NBITS(9)
    // ) adct_puls2_dly (
    //     .i_clk(sys_clk),
    //     .i_rst(sys_rst),
    //     .i_mode(2'd1),      // ONESHOT
    //     .i_dir(1'b0),       // DOWN
    //     .i_en(1'b1),
    //     .i_load(adct_puls2),
    //     .i_load_q(csr_adct_puls2_dly),
    //     .o_epulse(adct_puls2_d)
    // );

    // // Pulse width formers (width specified in adc_srate periods)
    // fastcounter #(
    //     .NBITS(16)  // enough for 16ms pulse @ adc_srate=4MHz
    // ) adct_puls1_fmr (
    //     .i_clk(sys_clk),
    //     .i_rst(sys_rst),
    //     .i_mode(2'd1),      // ONESHOT
    //     .i_dir(1'b0),       // DOWN
    //     .i_en(adct_srate1),
    //     .i_load(adct_puls1_d),
    //     .i_load_q(csr_adct_puls1_pwidth),
    //     .o_nend(adct_puls1_w)
    // );

    // fastcounter #(
    //     .NBITS(16)
    // ) adct_puls2_fmr (
    //     .i_clk(sys_clk),
    //     .i_rst(sys_rst),
    //     .i_mode(2'd1),      // ONESHOT
    //     .i_dir(1'b0),       // DOWN
    //     .i_en(adct_srate2),
    //     .i_load(adct_puls2_d),
    //     .i_load_q(csr_adct_puls2_pwidth),
    //     .o_nend(adct_puls2_w)
    // );

    // --------------------------------------------------
    //                  Timestamp counter
    // --------------------------------------------------

    reg [31:0] cyccnt;
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst) begin
            cyccnt <= 1'd0;
        end else begin
            cyccnt <= cyccnt + 1'd1;
        end
    end

    // --------------------------------------------------
    //     ADC - Analog-to-digital converters
    // --------------------------------------------------

    wire adc_ddr_clk;
    wire adc_sclk_ddr_h;
    wire adc_sclk_ddr_l;
    wire adc_cs_n;
    wire [3:0] adc_sdata_ddr_h;
    wire [3:0] adc_sdata_ddr_l;
    //
    wire [7:0] axis_adc_tdata;
    wire axis_adc_tkeep;
    wire axis_adc_tvalid;
    wire axis_adc_tready;
    wire axis_adc_tlast;
    //
    wire [7:0] axis_adc_ts_tdata;
    wire axis_adc_ts_tkeep;
    wire axis_adc_ts_tvalid;
    wire axis_adc_ts_tready;
    wire axis_adc_ts_tlast;

    adc_pipeline #(
        .ADC_NUM_CHANNELS(4),
        .ADC_CHN_WIDTH(14),
        .ADC_CHN_BYTES(2),
        .TIMESTAMP_WIDTH(32),
        .TIMESTAMP_BYTES(4),
        .FIFO_DEPTH(512)
    ) u_adc_pipeline (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .o_adc_ddr_clk(adc_ddr_clk),
        .o_adc_sclk_ddr_h(adc_sclk_ddr_h),
        .o_adc_sclk_ddr_l(adc_sclk_ddr_l),
        .o_adc_cs_n(adc_cs_n),
        .i_adc_sdata_ddr_h(adc_sdata_ddr_h),
        .i_adc_sdata_ddr_l(adc_sdata_ddr_l),
        //
        .i_timestamp(cyccnt),
        //
        .i_chn_en(4'b1011),
        //
        .i_sync_acq(adct_srate1),
        .i_sync_ts(adct_puls1),
        //
        .o_m_axis_adc_tdata(axis_adc_tdata),
        .o_m_axis_adc_tkeep(axis_adc_tkeep),
        .o_m_axis_adc_tvalid(axis_adc_tvalid),
        .i_m_axis_adc_tready(axis_adc_tready),
        .o_m_axis_adc_tlast(axis_adc_tlast),
        //
        .o_m_axis_ts_tdata(axis_adc_ts_tdata),
        .o_m_axis_ts_tkeep(axis_adc_ts_tkeep),
        .o_m_axis_ts_tvalid(axis_adc_ts_tvalid),
        .i_m_axis_ts_tready(axis_adc_ts_tready),
        .o_m_axis_ts_tlast(axis_adc_ts_tlast)
    );

    // --------------------------------------------------
    //     ADC I/O cells
    // --------------------------------------------------

    assign p_adc_cs_n = {2{adc_cs_n}};

    // SCLK
    SB_IO #(
        .PIN_TYPE(6'b 0100_00)  // DDR O
    ) u_adc_sclk_io (
        .PACKAGE_PIN(p_adc_sclk),
        // .CLOCK_ENABLE(1'b1),
        .INPUT_CLK(adc_ddr_clk),
        .OUTPUT_CLK(adc_ddr_clk),
        // .OUTPUT_ENABLE(1'b1),
        .D_OUT_0(adc_sclk_ddr_h),   // latch @ posedge clk, out if clk=1
        .D_OUT_1(adc_sclk_ddr_l)    // latch @ negedge clk, out if clk=0
    );

    // SDATA
    genvar iiadc;
    generate
        for (iiadc = 0; iiadc < 4; iiadc = iiadc + 1) begin
            SB_IO #(
                .PIN_TYPE(6'b 0000_00)  // DDR I
            ) u_adc_sdata_io (
                .PACKAGE_PIN(p_adc_sdata[iiadc]),
                // .CLOCK_ENABLE(1'b1),
                .INPUT_CLK(adc_ddr_clk),
                .OUTPUT_CLK(adc_ddr_clk),
                .D_IN_0(adc_sdata_ddr_l[iiadc]),    // latch @ posedge clk
                .D_IN_1(adc_sdata_ddr_h[iiadc])     // latch @ negedge clk
            );
        end
    endgenerate

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
    // TDC (phase detector)
    // ------------------------

    wire [7:0] axis_tdc_tdata;
    wire axis_tdc_tkeep;
    wire axis_tdc_tvalid;
    wire axis_tdc_tready;
    wire axis_tdc_tlast;

    tdc_pipeline #(
        .COUNTER_WIDTH(32),
        .DIV_GATE(2000000),         // 20 MHz -> 10 Hz
        .DIV_MEAS_FAST(100000)      // 1 MHz -> 10 Hz
    ) u_tdc_pipeline (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .o_m_axis_tdata(axis_tdc_tdata),
        .o_m_axis_tkeep(axis_tdc_tkeep),
        .o_m_axis_tvalid(axis_tdc_tvalid),
        .i_m_axis_tready(axis_tdc_tready),
        .o_m_axis_tlast(axis_tdc_tlast),
        //
        .i_clk_gate(p_clk_20mhz_gbin2),
        .i_clk_meas(p_clk_ref_in),
        //
        .i_meas_fast(1'b1)
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
    wire wbm_cp_err;
    wire wbm_cp_rty;
    wire wbm_cp_we;
    wire [WB_ADDR_WIDTH-1:0] wbm_cp_adr;
    wire [WB_DATA_WIDTH-1:0] wbm_cp_wdat;
    wire [WB_SEL_WIDTH-1:0] wbm_cp_sel;
    wire [WB_DATA_WIDTH-1:0] wbm_cp_rdat;

    // Wishbone port Tx command stream (outgoing data)
    wire axis_wbcon_tx_tvalid;
    wire axis_wbcon_tx_tready;
    wire [7:0] axis_wbcon_tx_tdata;
    wire axis_wbcon_tx_tkeep;
    wire axis_wbcon_tx_tlast;

    // --------------------------------------
    // Wishbone master: control port
    // --------------------------------------
    wbcon #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .WB_DATA_WIDTH(WB_DATA_WIDTH),
        .WB_SEL_WIDTH(WB_SEL_WIDTH)
    ) wbcon_i (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        // wb
        .o_wb_cyc(wbm_cp_cyc),
        .o_wb_stb(wbm_cp_stb),
        .i_wb_stall(wbm_cp_stall),
        .i_wb_ack(wbm_cp_ack),
        .i_wb_err(wbm_cp_err),
        .i_wb_rty(wbm_cp_rty),
        .o_wb_we(wbm_cp_we),
        .o_wb_adr(wbm_cp_adr),
        .o_wb_dat(wbm_cp_wdat),
        .o_wb_sel(wbm_cp_sel),
        .i_wb_dat(wbm_cp_rdat),
        // rx
        .i_rx_axis_tvalid(axis_cp_rx_tvalid),
        .o_rx_axis_tready(axis_cp_rx_tready),
        .i_rx_axis_tdata(axis_cp_rx_tdata),
        .i_rx_axis_tkeep(axis_cp_rx_tkeep),
        .i_rx_axis_tlast(axis_cp_rx_tlast),
        // tx
        .o_tx_axis_tvalid(axis_wbcon_tx_tvalid),
        .i_tx_axis_tready(axis_wbcon_tx_tready),
        .o_tx_axis_tdata(axis_wbcon_tx_tdata),
        .o_tx_axis_tkeep(axis_wbcon_tx_tkeep),
        .o_tx_axis_tlast(axis_wbcon_tx_tlast)
    );

    // --------------------------------------
    // Control and status registers
    // --------------------------------------

    lwdo_regs #(
        .ADDRESS_WIDTH(WB_ADDR_WIDTH+WB_BYTE_ADDR_BITS),
        .DEFAULT_READ_DATA(16'hDEAD),
        .ERROR_STATUS(1),
        .SYS_PLL_DIVR_INITIAL_VALUE(SYS_PLL_DIVR),
        .SYS_PLL_DIVF_INITIAL_VALUE(SYS_PLL_DIVF),
        .SYS_PLL_DIVQ_INITIAL_VALUE(SYS_PLL_DIVQ),
        .PDET_N1_VAL_INITIAL_VALUE(1),
        .PDET_N2_VAL_INITIAL_VALUE(1)
    ) lwdo_regs_i (
        // SYSCON
        .i_clk(sys_clk),
        .i_rst_n(~sys_rst),

        // WISHBONE
        .i_wb_cyc(wbm_cp_cyc),
        .i_wb_stb(wbm_cp_stb),
        .o_wb_stall(wbm_cp_stall),
        .i_wb_adr({wbm_cp_adr, {WB_BYTE_ADDR_BITS{1'b0}}}),
        .i_wb_we(wbm_cp_we),
        .i_wb_dat(wbm_cp_wdat),
        .i_wb_sel(wbm_cp_sel),
        .o_wb_ack(wbm_cp_ack),
        .o_wb_err(wbm_cp_err),
        .o_wb_rty(wbm_cp_rty),
        .o_wb_dat(wbm_cp_rdat),

        // REGS: SYS
        .o_sys_con_sys_rst(csr_sys_rst),
        // REGS: PDET
        // .o_pdet_con_en(csr_pdet_en),
        // .o_pdet_con_eclk2_slow(csr_pdet_eclk2_slow),
        // REGS: ADCT
        // .o_adct_con_srate1_en(csr_adct_srate1_en),
        // .o_adct_con_srate2_en(csr_adct_srate2_en),
        // .o_adct_con_puls1_en(csr_adct_puls1_en),
        // .o_adct_con_puls2_en(csr_adct_puls2_en),
        // .o_adct_srate1_psc_div_val(csr_adct_srate1_psc_div),
        // .o_adct_srate2_psc_div_val(csr_adct_srate2_psc_div),
        // .o_adct_puls1_psc_div_val(csr_adct_puls1_psc_div),
        // .o_adct_puls2_psc_div_val(csr_adct_puls2_psc_div),
        // .o_adct_puls1_dly_val(csr_adct_puls1_dly),
        // .o_adct_puls2_dly_val(csr_adct_puls2_dly),
        // .o_adct_puls1_pwidth_val(csr_adct_puls1_pwidth),
        // .o_adct_puls2_pwidth_val(csr_adct_puls2_pwidth),
        // // REGS: ADC CON
        // .o_adc_con_adc1_en(csr_adc_adc1_en),
        // .o_adc_con_adc2_en(csr_adc_adc2_en),
        // REGS: ADC FIFO1
        .i_adc_fifo1_sts_empty(1'b0),
        .i_adc_fifo1_sts_full(1'b0),
        .i_adc_fifo1_sts_hfull(1'b0),
        .i_adc_fifo1_sts_ovfl(1'b0),
        // .o_adc_fifo1_sts_ovfl_read_trigger(adc1_fifo_ovfl_lclr),
        .i_adc_fifo1_sts_udfl(1'b0),
        // .o_adc_fifo1_sts_udfl_read_trigger(adc1_fifo_udfl_lclr),
        // REGS: ADC FIFO2
        .i_adc_fifo2_sts_empty(1'b0),
        .i_adc_fifo2_sts_full(1'b0),
        .i_adc_fifo2_sts_hfull(1'b0),
        .i_adc_fifo2_sts_ovfl(1'b0),
        // .o_adc_fifo2_sts_ovfl_read_trigger(adc2_fifo_ovfl_lclr),
        .i_adc_fifo2_sts_udfl(1'b0),
        // .o_adc_fifo2_sts_udfl_read_trigger(adc2_fifo_udfl_lclr),
        // REGS: FTUN
        .o_ftun_vtune_set_val(csr_ftun_vtune_val),
        .o_ftun_vtune_set_val_write_trigger(csr_ftun_vtune_write)
    );

    // ----------------------------------
    // Control port Tx AXI-S multiplexer
    // ----------------------------------
    axis_arb_mux #(
        .S_COUNT(4),
        .DATA_WIDTH(8),
        .KEEP_ENABLE(1),
        .KEEP_WIDTH(1),
        .ID_ENABLE(1),
        .S_ID_WIDTH(8),
        .M_ID_WIDTH(8),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .LAST_ENABLE(1),
        .UPDATE_TID(0),
        .ARB_TYPE_ROUND_ROBIN(1),
        .ARB_LSB_HIGH_PRIORITY(1)
    ) u_cp_tx_mux (
        .clk(sys_clk),
        .rst(sys_rst),
        //
        .s_axis_tdata({
            axis_adc_tdata,
            axis_adc_ts_tdata,
            axis_tdc_tdata,
            axis_wbcon_tx_tdata
            }),
        .s_axis_tkeep({
            axis_adc_tkeep,
            axis_adc_ts_tkeep,
            axis_tdc_tkeep,
            axis_wbcon_tx_tkeep
            }),
        .s_axis_tvalid({
            axis_adc_tvalid,
            axis_adc_ts_tvalid,
            axis_tdc_tvalid,
            axis_wbcon_tx_tvalid
            }),
        .s_axis_tready({
            axis_adc_tready,
            axis_adc_ts_tready,
            axis_tdc_tready,
            axis_wbcon_tx_tready
            }),
        .s_axis_tlast({
            axis_adc_tlast,
            axis_adc_ts_tlast,
            axis_tdc_tlast,
            axis_wbcon_tx_tlast
            }),
        .s_axis_tid({
            8'h02,  // ADC
            8'h03,  // ADC TS
            8'h04,  // TDC
            8'h01   // WBCON
            }),
        //
        .m_axis_tdata(axis_cp_tx_tdata),
        .m_axis_tkeep(axis_cp_tx_tkeep),
        .m_axis_tvalid(axis_cp_tx_tvalid),
        .m_axis_tready(axis_cp_tx_tready),
        .m_axis_tlast(axis_cp_tx_tlast),
        .m_axis_tid(axis_cp_tx_tid)
    );


    // ----------------------------------
    // Control port SLIP / AXI-S streams
    // ----------------------------------

    // Rx
    wire axis_cp_rx_tvalid;
    wire axis_cp_rx_tready;
    wire [7:0] axis_cp_rx_tdata;
    wire axis_cp_rx_tkeep;
    wire axis_cp_rx_tlast;
    // Tx
    wire axis_cp_tx_tvalid;
    wire axis_cp_tx_tready;
    wire [7:0] axis_cp_tx_tdata;
    wire axis_cp_tx_tkeep;
    wire axis_cp_tx_tlast;
    wire [7:0] axis_cp_tx_tid;

    slip_axis_decoder_noid #(
    ) u_slip_axis_dec (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_s_axis_tvalid(sys_ft_rx_valid),
        .o_s_axis_tready(sys_ft_rx_ready),
        .i_s_axis_tdata(sys_ft_rx_data),
        //
        .o_m_axis_tvalid(axis_cp_rx_tvalid),
        .i_m_axis_tready(axis_cp_rx_tready),
        .o_m_axis_tdata(axis_cp_rx_tdata),
        .o_m_axis_tkeep(axis_cp_rx_tkeep),
        .o_m_axis_tlast(axis_cp_rx_tlast)
    );

    slip_axis_encoder #(
    ) u_slip_axis_enc (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_s_axis_tvalid(axis_cp_tx_tvalid),
        .o_s_axis_tready(axis_cp_tx_tready),
        .i_s_axis_tdata(axis_cp_tx_tdata),
        .i_s_axis_tkeep(axis_cp_tx_tkeep),
        .i_s_axis_tlast(axis_cp_tx_tlast),
        .i_s_axis_tid(axis_cp_tx_tid),
        //
        .o_m_axis_tvalid(sys_ft_tx_valid),
        .i_m_axis_tready(sys_ft_tx_ready),
        .o_m_axis_tdata(sys_ft_tx_data)
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

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                   FTDI SyncFIFO CLOCK DOMAIN                =========================
    // =========================                       @(posedge ft_clk)                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // Clock is generated by FT(2)232H itself. Clock is available only when FT232H is switched to
    // SyncFIFO mode and not in reset. Thus, FPGA must account for the fact that this clock domain
    // is NOT always running when other FPGA clocks are running.

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

    ft245sync u_ft245sync (
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
    localparam FT_AFIFO_DEPTH = 256;

    axis_async_fifo #(
        .DEPTH(FT_AFIFO_DEPTH),
        .DATA_WIDTH(8),
        .KEEP_ENABLE(0),
        .LAST_ENABLE(0),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .RAM_PIPELINE(1),
        .OUTPUT_FIFO_ENABLE(0),
        .FRAME_FIFO(0),
        .PAUSE_ENABLE(0)
    ) u_ft_afifo_rx (
        // FTDI domain - slave
        .s_clk(ft_clk),
        .s_rst(ft_rst),
        .s_axis_tdata(ft_rx_data),
        .s_axis_tvalid(ft_rx_valid),
        .s_axis_tready(ft_rx_ready),
        .s_axis_tlast(1'b1),
        // SYS domain - master
        .m_clk(sys_clk),
        .m_rst(sys_rst),
        .m_axis_tdata(sys_ft_rx_data),
        .m_axis_tvalid(sys_ft_rx_valid),
        .m_axis_tready(sys_ft_rx_ready)
    );

    axis_async_fifo #(
        .DEPTH(FT_AFIFO_DEPTH),
        .DATA_WIDTH(8),
        .KEEP_ENABLE(0),
        .LAST_ENABLE(0),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .RAM_PIPELINE(1),
        .OUTPUT_FIFO_ENABLE(0),
        .FRAME_FIFO(0),
        .PAUSE_ENABLE(0)
    ) u_ft_afifo_tx (
        // SYS domain - slave
        .s_clk(sys_clk),
        .s_rst(sys_rst),
        .s_axis_tdata(sys_ft_tx_data),
        .s_axis_tvalid(sys_ft_tx_valid),
        .s_axis_tready(sys_ft_tx_ready),
        .s_axis_tlast(1'b1),
        // FTDI domain - master
        .m_clk(ft_clk),
        .m_rst(ft_rst),
        .m_axis_tdata(ft_tx_data),
        .m_axis_tvalid(ft_tx_valid),
        .m_axis_tready(ft_tx_ready)
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
    assign p_clk_out = adct_srate1;

    // ------------------------
    // LEDs
    // ------------------------
    assign p_led_sts_r = sys_ft_rx_valid;
    assign p_led_sts_g = ft_rst;
    //
    assign p_led_in1_r = ft_tx_valid;
    assign p_led_in1_g = 0;
    assign p_led_in2_r = ft_tx_ready;
    assign p_led_in2_g = 0;
    assign p_led_in3_r = ft_rx_valid;
    assign p_led_in3_g = 0;
    assign p_led_in4_r = ft_rx_ready;
    assign p_led_in4_g = 0;


endmodule
