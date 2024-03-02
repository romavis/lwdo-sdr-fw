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

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                           PARAMETERS                        =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // SYS PLL
    // Input: 20 MHz (VCTCXO)
    // Output: 80 MHz
    localparam [3:0] SYS_PLL_DIVR = 4'd0;
    localparam [6:0] SYS_PLL_DIVF = 7'd31;
    localparam [2:0] SYS_PLL_DIVQ = 3'd3;
    localparam [2:0] SYS_PLL_FILTER_RANGE = 3'd2;

    // TDC Spread-Spectrum PLL
    // Input: 80 MHz (SYS PLL)
    // Output: 80 MHz
    localparam [3:0] TDC_PLL_DIVR = 4'd6;
    localparam [6:0] TDC_PLL_DIVF = 7'd6;
    localparam [2:0] TDC_PLL_DIVQ = 3'd3;
    localparam [2:0] TDC_PLL_FILTER_RANGE = 3'd1;
    localparam TDC_PLL_SS_DIVFSPAN = 0; // 1;
    localparam TDC_PLL_SS_UDIV = 0;

    // HW TIME counter
    localparam HWTIME_WIDTH = 32;
    localparam HWTIME_BYTES = 4;

    // DAC8551 SPI DAC
    localparam DAC_CLK_DIV = 20;

    // ADC
    localparam ADC_SAMPLE_RATE_DIV_WIDTH = 24;
    localparam ADC_TS_RATE_DIV_WIDTH = 8;

    // TDC
    // GATE:
    //  gate frequency set to 100 Hz
    // MEAS:
    //  divider is tuned so that 1 MHz input results in 100 Hz MEAS frequency
    //  as a result, when used with 5 MHz reference, we'll have 500 Hz,
    //  with 10 MHz reference we'll measure 1000 Hz, etc.
    localparam TDC_COUNTER_WIDTH = 28;
    localparam TDC_GATE_DIV = 200_000;
    localparam TDC_MEAS_DIV = 10_000;

    // PPS
    localparam PPS_RATE_DIV_WIDTH = 28;
    localparam PPS_PWIDTH_WIDTH = 28;

    // Wishbone bus
    localparam WB_ADDR_WIDTH = 8;
    localparam WB_DATA_WIDTH = 32;
    localparam WB_SEL_WIDTH = 4;
    localparam WB_BYTE_ADDR_BITS = $clog2((WB_DATA_WIDTH + 7) / 8);

    // Control port stream IDs
    localparam CP_TID_WBCON = 8'h01;
    localparam CP_TID_ADC = 8'h02;
    localparam CP_TID_ADC_TS = 8'h03;
    localparam CP_TID_TDC = 8'h04;
    localparam CP_TID_PPS_TS = 8'h05;

    // FTDI control port AsyncFIFO depth (bytes)
    localparam FT_AFIFO_DEPTH = 256;

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                     WIRES AND REGISTERS                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ----------------------------------------------- async  signals -----------------------------------------------
    wire sys_pll_lock;
    wire tdc_pll_lock;

    // Wire "interesting" clocks here to be able to output them later via muxes
    reg [31:0] clocks;


    // ----------------------------------------------- sys_clk domain -----------------------------------------------
    wire sys_clk;
    wire sys_rst;
    wire sys_rstd;  // Held for 1 clock cycle after sys_rst is deasserted

    // HWTIME counter
    reg [HWTIME_WIDTH-1:0] hwtime_q;
    reg [HWTIME_WIDTH-1:0] hwtime_q1;   // delayed version, improves timings

    // ADC SB_IO signals
    wire adc_sclk_ddr_h;
    wire adc_sclk_ddr_l;
    wire adc_cs_n;
    wire [3:0] adc_sdata_ddr_h;
    wire [3:0] adc_sdata_ddr_l;

    // ADC
    wire adc_sample;

    // PPS
    wire pps_sample;
    wire pps_formed;

    // CSRs: sys
    wire csr_sys_con_sys_rst;
    // CSRs: tdc
    wire csr_tdc_con_en;
    wire csr_tdc_con_meas_div_en;
    wire csr_tdc_con_gate_fdec;
    wire csr_tdc_con_gate_finc;
    // CSRs: adc
    wire [3:0] csr_adc_con_adc_en;
    wire [ADC_SAMPLE_RATE_DIV_WIDTH-1:0] csr_adc_sample_rate_div;
    wire [ADC_TS_RATE_DIV_WIDTH-1:0] csr_adc_ts_rate_div;
    // CSRs: ftun
    wire [7:0] csr_ftun_vtune_set_dac_low;
    wire [15:0] csr_ftun_vtune_set_dac_high;
    wire csr_ftun_vtune_set_dac_high_write_trigger;
    // CSRs: pps
    wire csr_pps_con_en;
    wire [PPS_RATE_DIV_WIDTH-1:0] csr_pps_rate_div;
    wire [PPS_PWIDTH_WIDTH-1:0] csr_pps_pulse_width;
    // CSRs: io
    wire [4:0] csr_io_clkout_source;
    wire csr_io_clkout_inv;
    wire csr_io_clkout_mode;

    // Wishbone bus (master: control port)
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

    // AXI-S: serialized ADC data
    wire [7:0] axis_adc_tdata;
    wire axis_adc_tkeep;
    wire axis_adc_tvalid;
    wire axis_adc_tready;
    wire axis_adc_tlast;

    // AXI-S: serialized ADC TS data
    wire [7:0] axis_adc_ts_tdata;
    wire axis_adc_ts_tkeep;
    wire axis_adc_ts_tvalid;
    wire axis_adc_ts_tready;
    wire axis_adc_ts_tlast;

    // AXI-S: serialized TDC data
    wire [7:0] axis_tdc_tdata;
    wire axis_tdc_tkeep;
    wire axis_tdc_tvalid;
    wire axis_tdc_tready;
    wire axis_tdc_tlast;

    // AXI-S: serialized PPS TS data
    wire [7:0] axis_pps_ts_tdata;
    wire axis_pps_ts_tkeep;
    wire axis_pps_ts_tvalid;
    wire axis_pps_ts_tready;
    wire axis_pps_ts_tlast;

    // AXI-S: wbcon Tx stream
    wire axis_wbcon_tx_tvalid;
    wire axis_wbcon_tx_tready;
    wire [7:0] axis_wbcon_tx_tdata;
    wire axis_wbcon_tx_tkeep;
    wire axis_wbcon_tx_tlast;

    // AXI-S: control port Rx stream
    wire axis_cp_rx_tvalid;
    wire axis_cp_rx_tready;
    wire [7:0] axis_cp_rx_tdata;
    wire axis_cp_rx_tkeep;
    wire axis_cp_rx_tlast;

    // AXI-S: control port Tx stream
    wire axis_cp_tx_tvalid;
    wire axis_cp_tx_tready;
    wire [7:0] axis_cp_tx_tdata;
    wire axis_cp_tx_tkeep;
    wire axis_cp_tx_tlast;
    wire [7:0] axis_cp_tx_tid;

    // AXI-S: control port Rx stream (SLIP encoded)
    wire [7:0] axis_cp_rx_slip_tdata;
    wire axis_cp_rx_slip_tvalid;
    wire axis_cp_rx_slip_tready;

    // AXI-S: control port Tx stream (SLIP encoded)
    wire [7:0] axis_cp_tx_slip_tdata;
    wire axis_cp_tx_slip_tvalid;
    wire axis_cp_tx_slip_tready;


    // ----------------------------------------------- tdc_clk domain -----------------------------------------------
    wire tdc_clk;


    // ----------------------------------------------- ft_clk  domain -----------------------------------------------

    // Clock is generated by FT(2)232H itself. Clock is available only when FT232H is switched to
    // SyncFIFO mode and not in reset. Thus, FPGA must account for the fact that this clock domain
    // is NOT always running when other FPGA clocks are running.
    wire ft_clk;
    wire ft_rst;

    // FTDI data bus SB_IO signals
    wire [7:0] ft_fifo_d_in;
    wire [7:0] ft_fifo_d_out;
    wire ft_fifo_d_oe;

    // AXI-S: control port Tx stream (FTDI side)
    wire [7:0] axis_ft_tx_tdata;
    wire axis_ft_tx_tvalid;
    wire axis_ft_tx_tready;

    // AXI-S: control port Rx stream (FTDI side)
    wire [7:0] axis_ft_rx_tdata;
    wire axis_ft_rx_tvalid;
    wire axis_ft_rx_tready;

    // FTDI debug status
    wire [3:0] ft_dbg;



    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                        CLOCK GENERATION                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ----------------------------------------------------------------------
    //                              SYS PLL
    //
    // ----------------------------------------------------------------------

    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
		.DIVR(SYS_PLL_DIVR),
		.DIVF(SYS_PLL_DIVF),
		.DIVQ(SYS_PLL_DIVQ),
		.FILTER_RANGE(SYS_PLL_FILTER_RANGE),
        .PLLOUT_SELECT("GENCLK")
    ) u_sys_pll (
        .PACKAGEPIN(p_clk_20mhz_gbin1),
        .PLLOUTCORE(sys_clk),
        .LOCK(sys_pll_lock),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );


    // ----------------------------------------------------------------------
    //                  TDC COUNTER SPREAD-SPECTRUM PLL
    //
    // Spread-spectrum is used for the purpose of TDC dithering and reducing
    // the width of a dead zone of a VCTCXO DPLL (implemented on the host)
    // which uses TDC as a phase detector.
    //
    // ----------------------------------------------------------------------

    ice40_sspll #(
		.DIVR(TDC_PLL_DIVR),
		.DIVF(TDC_PLL_DIVF),
		.DIVQ(TDC_PLL_DIVQ),
		.FILTER_RANGE(TDC_PLL_FILTER_RANGE),
        .SS_DIVFSPAN(TDC_PLL_SS_DIVFSPAN),
        .SS_UDIV(TDC_PLL_SS_UDIV)
    ) u_tdc_pll (
        .REFERENCECLK(sys_clk),
        .PLLOUTCORE(tdc_clk),
        .LOCK(tdc_pll_lock),
        .RESETB(1'b1)
    );


    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                        CUSTOM I/O CELLS                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================


    // -----------------------------------------------      ADC        -----------------------------------------------

    // SCLK
    SB_IO #(
        .PIN_TYPE(6'b 0100_00)  // DDR O
    ) u_adc_sclk_io (
        .PACKAGE_PIN(p_adc_sclk),
        // .CLOCK_ENABLE(1'b1),
        .INPUT_CLK(sys_clk),
        .OUTPUT_CLK(sys_clk),
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
                .INPUT_CLK(sys_clk),
                .OUTPUT_CLK(sys_clk),
                .D_IN_0(adc_sdata_ddr_l[iiadc]),    // latch @ posedge clk
                .D_IN_1(adc_sdata_ddr_h[iiadc])     // latch @ negedge clk
            );
        end
    endgenerate


    // -----------------------------------------------      FTDI       -----------------------------------------------

    SB_IO #(
        .PIN_TYPE(6'b 1010_01)
    ) ft_fifo_data_pins [7:0] (
        .PACKAGE_PIN(p_ft_fifo_d),
        .OUTPUT_ENABLE(ft_fifo_d_oe),
        .D_OUT_0(ft_fifo_d_out),
        .D_IN_0(ft_fifo_d_in)
    );


    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                      SYSTEM CLOCK DOMAIN                    =========================
    // =========================                       @(posedge sys_clk)                    =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ----------------------------------------------------------------------
    // System reset generator
    // ----------------------------------------------------------------------

    // sys_rst is async assert, sync de-assert
    // Asserted on / by:
    //  1. FPGA initialization
    //  2. PLL "not locked" condition
    //  3. csr_sys_rst CSR bit
    cdc_reset_bridge sys_rst_gen (
        .i_clk(sys_clk),
        .i_rst((~sys_pll_lock) | csr_sys_con_sys_rst),
        .o_rst(sys_rst),
        .o_rst_q(sys_rstd)
    );

    // ----------------------------------------------------------------------
    //                  HWTIME counter
    // ----------------------------------------------------------------------

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst) begin
            hwtime_q <= 1'd0;
            hwtime_q1 <= 1'd0;
        end else begin
            hwtime_q <= hwtime_q + 1'd1;
            hwtime_q1 <= hwtime_q;
        end
    end

    // ----------------------------------------------------------------------
    //     ADC - Analog-to-digital converters
    // ----------------------------------------------------------------------

    adc_pipeline #(
        .SAMPLE_RATE_DIV_WIDTH(ADC_SAMPLE_RATE_DIV_WIDTH),
        .ADC_NUM_CHANNELS(4),
        .ADC_CHN_WIDTH(14),
        .ADC_CHN_BYTES(2),
        .TS_RATE_DIV_WIDTH(ADC_TS_RATE_DIV_WIDTH),
        .TS_WIDTH(HWTIME_WIDTH),
        .TS_BYTES(HWTIME_BYTES),
        .FIFO_DEPTH(512)
    ) u_adc_pipeline (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .o_adc_sclk_ddr_h(adc_sclk_ddr_h),
        .o_adc_sclk_ddr_l(adc_sclk_ddr_l),
        .o_adc_cs_n(adc_cs_n),
        .i_adc_sdata_ddr_h(adc_sdata_ddr_h),
        .i_adc_sdata_ddr_l(adc_sdata_ddr_l),
        //
        .i_chn_en(csr_adc_con_adc_en),
        .i_sample_rate_div(csr_adc_sample_rate_div),
        .i_ts(hwtime_q1),
        .i_ts_rate_div(csr_adc_ts_rate_div),
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
        .o_m_axis_ts_tlast(axis_adc_ts_tlast),
        //
        .o_adc_sample(adc_sample)
    );

    // ----------------------------------------------------------------------
    // DAC driver
    // ----------------------------------------------------------------------

    dac8551 #(
        .CLK_DIV(DAC_CLK_DIV)
    ) u_dac (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        .i_wr(sys_rstd || csr_ftun_vtune_set_dac_high_write_trigger),
        .i_wr_data({8'b0, csr_ftun_vtune_set_dac_high}),
        .o_dac_sclk(p_spi_dac_sclk),
        .o_dac_sync_n(p_spi_dac_sync_n),
        .o_dac_mosi(p_spi_dac_mosi)
    );

    // ----------------------------------------------------------------------
    // TDC (phase detector)
    // ----------------------------------------------------------------------

    tdc_pipeline #(
        .COUNTER_WIDTH(TDC_COUNTER_WIDTH),
        .DIV_GATE(TDC_GATE_DIV),
        .DIV_MEAS(TDC_MEAS_DIV)
    ) u_tdc_pipeline (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_clk_tdc(tdc_clk),
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
        .i_ctl_en(csr_tdc_con_en),
        .i_ctl_meas_div_en(csr_tdc_con_meas_div_en),
        .i_ctl_gate_fdec(csr_tdc_con_gate_fdec),
        .i_ctl_gate_finc(csr_tdc_con_gate_finc)
    );


    // ----------------------------------------------------------------------
    // PPS (pulse-per-second generator)
    // ----------------------------------------------------------------------

    pps_generator #(
        .RATE_DIV_WIDTH(PPS_RATE_DIV_WIDTH),
        .PULSE_WIDTH_WIDTH(PPS_PWIDTH_WIDTH),
        .TS_WIDTH(HWTIME_WIDTH),
        .TS_BYTES(HWTIME_BYTES)
    ) u_pps_generator (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_en(csr_pps_con_en),
        .i_rate_div(csr_pps_rate_div),
        .i_pulse_width(csr_pps_pulse_width),
        //
        .i_ts(hwtime_q1),
        //
        .o_m_axis_ts_tdata(axis_pps_ts_tdata),
        .o_m_axis_ts_tkeep(axis_pps_ts_tkeep),
        .o_m_axis_ts_tvalid(axis_pps_ts_tvalid),
        .i_m_axis_ts_tready(axis_pps_ts_tready),
        .o_m_axis_ts_tlast(axis_pps_ts_tlast),
        //
        .o_pps_sample(pps_sample),
        .o_pps_formed(pps_formed)
    );


    // ----------------------------------------------------------------------
    // Wishbone master: control port
    // ----------------------------------------------------------------------
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

    // ----------------------------------------------------------------------
    // Control and status registers
    // ----------------------------------------------------------------------

    lwdo_regs #(
        .ADDRESS_WIDTH(WB_ADDR_WIDTH+WB_BYTE_ADDR_BITS),
        .DEFAULT_READ_DATA(32'hDEADDEAD),
        .ERROR_STATUS(1),
        .SYS_PLL_DIVR_INITIAL_VALUE(SYS_PLL_DIVR),
        .SYS_PLL_DIVF_INITIAL_VALUE(SYS_PLL_DIVF),
        .SYS_PLL_DIVQ_INITIAL_VALUE(SYS_PLL_DIVQ),
        .TDC_PLL_DIVR_INITIAL_VALUE(TDC_PLL_DIVR),
        .TDC_PLL_DIVF_INITIAL_VALUE(TDC_PLL_DIVF),
        .TDC_PLL_DIVQ_INITIAL_VALUE(TDC_PLL_DIVQ),
        .TDC_PLL_SS_DIVFSPAN_INITIAL_VALUE(TDC_PLL_SS_DIVFSPAN),
        .TDC_DIV_GATE_INITIAL_VALUE(TDC_GATE_DIV),
        .TDC_DIV_MEAS_INITIAL_VALUE(TDC_MEAS_DIV)
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

        // SYS
        .o_sys_con_sys_rst(csr_sys_con_sys_rst),
        // HWTIME
        .i_hwtime_cnt(hwtime_q1),
        // TDC
        .o_tdc_con_en(csr_tdc_con_en),
        .o_tdc_con_meas_div_en(csr_tdc_con_meas_div_en),
        .o_tdc_con_gate_fdec(csr_tdc_con_gate_fdec),
        .o_tdc_con_gate_finc(csr_tdc_con_gate_finc),
        // ADC
        .o_adc_con_adc_en(csr_adc_con_adc_en),
        .o_adc_sample_rate_div(csr_adc_sample_rate_div),
        .o_adc_ts_rate_div(csr_adc_ts_rate_div),
        // FTUN
        .o_ftun_vtune_set_dac_high(csr_ftun_vtune_set_dac_high),
        .o_ftun_vtune_set_dac_high_write_trigger(csr_ftun_vtune_set_dac_high_write_trigger),
        // PPS
        .o_pps_con_en(csr_pps_con_en),
        .o_pps_rate_div(csr_pps_rate_div),
        .o_pps_pulse_width(csr_pps_pulse_width),
        // IO
        .o_io_clkout_source(csr_io_clkout_source),
        .o_io_clkout_inv(csr_io_clkout_inv),
        .o_io_clkout_mode(csr_io_clkout_mode)
    );

    // ----------------------------------------------------------------------
    // Control port Tx AXI-S multiplexer
    // ----------------------------------------------------------------------
    axis_arb_mux #(
        .S_COUNT(5),
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
            axis_pps_ts_tdata,
            axis_wbcon_tx_tdata
            }),
        .s_axis_tkeep({
            axis_adc_tkeep,
            axis_adc_ts_tkeep,
            axis_tdc_tkeep,
            axis_pps_ts_tkeep,
            axis_wbcon_tx_tkeep
            }),
        .s_axis_tvalid({
            axis_adc_tvalid,
            axis_adc_ts_tvalid,
            axis_tdc_tvalid,
            axis_pps_ts_tvalid,
            axis_wbcon_tx_tvalid
            }),
        .s_axis_tready({
            axis_adc_tready,
            axis_adc_ts_tready,
            axis_tdc_tready,
            axis_pps_ts_tready,
            axis_wbcon_tx_tready
            }),
        .s_axis_tlast({
            axis_adc_tlast,
            axis_adc_ts_tlast,
            axis_tdc_tlast,
            axis_pps_ts_tlast,
            axis_wbcon_tx_tlast
            }),
        .s_axis_tid({
            CP_TID_ADC,
            CP_TID_ADC_TS,
            CP_TID_TDC,
            CP_TID_PPS_TS,
            CP_TID_WBCON
            }),
        //
        .m_axis_tdata(axis_cp_tx_tdata),
        .m_axis_tkeep(axis_cp_tx_tkeep),
        .m_axis_tvalid(axis_cp_tx_tvalid),
        .m_axis_tready(axis_cp_tx_tready),
        .m_axis_tlast(axis_cp_tx_tlast),
        .m_axis_tid(axis_cp_tx_tid)
    );


    // ----------------------------------------------------------------------
    // Control port SLIP / AXI-S streams
    // ----------------------------------------------------------------------

    slip_axis_decoder_noid #(
    ) u_slip_axis_dec (
        .i_clk(sys_clk),
        .i_rst(sys_rst),
        //
        .i_s_axis_tvalid(axis_cp_rx_slip_tvalid),
        .o_s_axis_tready(axis_cp_rx_slip_tready),
        .i_s_axis_tdata(axis_cp_rx_slip_tdata),
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
        .o_m_axis_tvalid(axis_cp_tx_slip_tvalid),
        .i_m_axis_tready(axis_cp_tx_slip_tready),
        .o_m_axis_tdata(axis_cp_tx_slip_tdata)
    );

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                   FTDI SyncFIFO CLOCK DOMAIN                =========================
    // =========================                       @(posedge ft_clk)                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ----------------------------
    // FTDI domain reset generator
    // ----------------------------

    // ft_rst is async assert, sync de-assert
    // Asserted on / by:
    //  1. FPGA initialization
    //  2. sys_rst

    cdc_reset_bridge ft_rst_gen (
        .i_clk(ft_clk),
        .i_rst(sys_rst),
        .o_rst(ft_rst)
    );

    // ------------------------
    // FTDI SyncFIFO port
    // ------------------------

    // Side A:
    //      FT(2)232H SyncFIFO bus
    // Side B:
    //      Data-ready-valid Rx & Tx byte streams

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
        .i_tx_data(axis_ft_tx_tdata),
        .i_tx_valid(axis_ft_tx_tvalid),
        .o_tx_ready(axis_ft_tx_tready),
        .o_rx_data(axis_ft_rx_tdata),
        .o_rx_valid(axis_ft_rx_tvalid),
        .i_rx_ready(axis_ft_rx_tready),
        // debug
        .o_dbg(ft_dbg)
    );

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                    CLOCK DOMAIN CROSSING                    =========================
    // =========================            @(posedge sys_clk) / @(posedge ft_clk)           =========================
    // =========================                                                             =========================
    // ===============================================================================================================

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
        .s_axis_tdata(axis_ft_rx_tdata),
        .s_axis_tvalid(axis_ft_rx_tvalid),
        .s_axis_tready(axis_ft_rx_tready),
        .s_axis_tlast(1'b1),
        // SYS domain - master
        .m_clk(sys_clk),
        .m_rst(sys_rst),
        .m_axis_tdata(axis_cp_rx_slip_tdata),
        .m_axis_tvalid(axis_cp_rx_slip_tvalid),
        .m_axis_tready(axis_cp_rx_slip_tready)
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
        .s_axis_tdata(axis_cp_tx_slip_tdata),
        .s_axis_tvalid(axis_cp_tx_slip_tvalid),
        .s_axis_tready(axis_cp_tx_slip_tready),
        .s_axis_tlast(1'b1),
        // FTDI domain - master
        .m_clk(ft_clk),
        .m_rst(ft_rst),
        .m_axis_tdata(axis_ft_tx_tdata),
        .m_axis_tvalid(axis_ft_tx_tvalid),
        .m_axis_tready(axis_ft_tx_tready)
    );

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                     CLOCKS REGISTER                         =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    always @* begin
        clocks = 1'd0;

        // fixed
        clocks[0] = 1'b0;   // logic 0
        clocks[1] = p_clk_20mhz_gbin2;
        clocks[2] = p_clk_ref_in;
        clocks[3] = pps_formed;
        // experimental
        clocks[27] = pps_sample;
        clocks[28] = adc_sample;
        clocks[29] = tdc_clk;
        clocks[30] = ft_clk;
        clocks[31] = sys_clk;
    end

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                    OUTPUT PIN DRIVERS                       =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    // ------------------------
    // ADC
    // ------------------------
    assign p_adc_cs_n = {2{adc_cs_n}};

    // ------------------------
    // CLK OUT
    // ------------------------

    // sel controls external LVCMOS mux:
    // sel=0 - output clock from VCTCXO; sel=1 - output ~p_clk_out
    assign p_clk_out_sel = ~csr_io_clkout_mode;
    assign p_clk_out =
        (~csr_io_clkout_mode)
        & ~(csr_io_clkout_inv ^ clocks[csr_io_clkout_source]);

    // ------------------------
    // LEDs
    // ------------------------
    assign p_led_sts_r = 0;
    assign p_led_sts_g = ft_rst;
    //
    assign p_led_in1_r = axis_ft_tx_tvalid;
    assign p_led_in1_g = 0;
    assign p_led_in2_r = axis_ft_tx_tready;
    assign p_led_in2_g = 0;
    assign p_led_in3_r = axis_ft_rx_tvalid;
    assign p_led_in3_g = 0;
    assign p_led_in4_r = axis_ft_rx_tready;
    assign p_led_in4_g = 0;


endmodule
