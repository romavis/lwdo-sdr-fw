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
    // =========================                        ADC CLOCK DOMAIN                     =========================
    // =========================                       @(negedge adc_clk)                    =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    wire adc_clk;
    // Rebuffer ADC clock through a p_adc_sclk_gbin pin (connected externally to p_adc_sclk)
    assign adc_clk = p_adc_sclk_gbin;

    // PON reset generator
    reg adc_rst = 0;
    reg adc_rst_done = 0;
    always @(negedge adc_clk) begin
        adc_rst <= 0;
        if (!adc_rst_done) begin
            adc_rst <= 1;
            adc_rst_done <= 1;
        end
    end

    // ADC sample rate generator
    reg [4:0] adc_srate_div_ctr;
    wire adc_srate_div_out;

    assign adc_srate_div_out = (adc_srate_div_ctr == 'd0);

    always @(negedge adc_clk) begin
        if (adc_rst) begin
            adc_srate_div_ctr <= 'd0;
        end else begin
            if (adc_srate_div_ctr == 'd0) begin
                adc_srate_div_ctr <= 'd19;  // ratio = value + 1
            end else begin
                adc_srate_div_ctr <= adc_srate_div_ctr - 'd1;
            end
        end
    end

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
        .i_if_sclk(adc_clk),
        .o_if_cs_n(p_adc1_cs_n),
        .i_if_sdata_a(p_adc1_sda),
        .i_if_sdata_b(p_adc1_sdb),
        // Control
        .i_rst(adc_rst),
        .i_sync(adc_srate_div_out),
        // Data
        .o_ready(adc1_rdy),
        .o_sample_a(adc1_data_a),
        .o_sample_b(adc1_data_b)
    );

    ad7357if adc2 (
        // interface
        .i_if_sclk(adc_clk),
        .o_if_cs_n(p_adc2_cs_n),
        .i_if_sdata_a(p_adc2_sda),
        .i_if_sdata_b(p_adc2_sdb),
        // Control
        .i_rst(adc_rst),
        .i_sync(adc_srate_div_out),
        // Data
        .o_ready(adc2_rdy),
        .o_sample_a(adc2_data_a),
        .o_sample_b(adc2_data_b)
    );

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                    CLOCK DOMAIN CROSSING                    =========================
    // =========================            @(negedge adc_clk) / @(posedge sys_clk)          =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    localparam ADCSTR_AFIFO_ASIZE = 3;

    wire adcstr1_ready, adcstr1_valid_n;
    wire [31:0] adcstr1_data;
    wire adcstr2_ready, adcstr2_valid_n;
    wire [31:0] adcstr2_data;

    async_fifo #(
        .DSIZE(32),
        .ASIZE(ADCSTR_AFIFO_ASIZE),
        .FALLTHROUGH("FALSE")
    ) adcstr1_afifo (
        //
        .wclk(~adc_clk),
        .wrst_n(!adc_rst),
        //
        .winc(adc1_rdy),
        .wdata({adc1_data_b, 2'b0, adc1_data_a, 2'b0}),
        //
        .rclk(sys_clk),
        .rrst_n(!sys_rst),
        //
        .rinc(adcstr1_ready && !adcstr1_valid_n),
        .rdata(adcstr1_data),
        .rempty(adcstr1_valid_n)
    );

    async_fifo #(
        .DSIZE(32),
        .ASIZE(ADCSTR_AFIFO_ASIZE),
        .FALLTHROUGH("FALSE")
    ) adcstr2_afifo (
        //
        .wclk(~adc_clk),
        .wrst_n(!adc_rst),
        //
        .winc(adc2_rdy),
        .wdata({adc2_data_b, 2'b0, adc2_data_a, 2'b0}),
        //
        .rclk(sys_clk),
        .rrst_n(!sys_rst),
        //
        .rinc(adcstr2_ready && !adcstr2_valid_n),
        .rdata(adcstr2_data),
        .rempty(adcstr2_valid_n)
    );

    // ===============================================================================================================
    // =========================                                                             =========================
    // =========================                   FTDI SyncFIFO CLOCK DOMAIN                =========================
    // =========================                       @(posedge ft_clk)                     =========================
    // =========================                                                             =========================
    // ===============================================================================================================
    wire ft_clk;

    // PON reset generator
    reg ft_rst = 0;
    reg ft_rst_done = 0;
    always @(posedge ft_clk) begin
        ft_rst <= 0;
        if (!ft_rst_done) begin
            ft_rst <= 1;
            ft_rst_done <= 1;
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
    // FTDI SyncFIFO
    // ------------------------

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
    // =========================                      SYSTEM CLOCK DOMAIN                    =========================
    // =========================                       @(posedge sys_clk)                    =========================
    // =========================                                                             =========================
    // ===============================================================================================================

    wire sys_clk;
    // For now, use FTDI clock as sys_clk
    // TODO: move FTDI to a separate clock domain, place asyncfifo between sys_clk and ft_fifo_clk
    assign sys_clk = ft_clk;

    // PON reset generator
    reg sys_rst = 0;
    reg sys_rst_done = 0;
    always @(posedge sys_clk) begin
        sys_rst <= 0;
        if (!sys_rst_done) begin
            sys_rst <= 1;
            sys_rst_done <= 1;
        end
    end

    // ------------------------
    // Wishbone bus
    // ------------------------

    localparam WB_ADDR_WIDTH = 8;

    wire wbm_cyc;
    wire wb_stb;
    reg wbm_stall;
    reg wbm_ack;
    wire wb_we;
    wire [WB_ADDR_WIDTH-1:0] wb_addr;
    wire [31:0] wb_wdata;
    wire [3:0] wb_sel;
    reg [31:0] wbm_rdata;

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
        .o_wb_cyc(wbm_cyc),
        .o_wb_stb(wb_stb),
        .i_wb_stall(wbm_stall),
        .i_wb_ack(wbm_ack),
        .o_wb_we(wb_we),
        .o_wb_addr(wb_addr),
        .o_wb_data(wb_wdata),
        .o_wb_sel(wb_sel),
        .i_wb_data(wbm_rdata),
        // rx
        .o_rx_ready(ft_rx_ready),
        .i_rx_data(ft_rx_data),
        .i_rx_valid(ft_rx_valid),
        // tx
        .i_tx_ready(ft_tx_ready),
        .o_tx_data(ft_tx_data),
        .o_tx_valid(ft_tx_valid),
        // TODO: EMREQs
        .i_emreqs_valid(adcstr1_emreq_valid),
        .o_emreqs_ready(adcstr1_emreq_ready),
        .i_emreqs(pack_mreq(1'b0, 1'b0, MREQ_WSIZE_VAL_4BYTE, 8'hFF, 32'h00000080))
    );


    // -----------------------------------
    // Wishbone bus switch
    // -----------------------------------

    reg wbs_cyc_dummy, wbs_cyc_mem, wbs_cyc_adcstr1, wbs_cyc_adcstr2;
    wire wbs_stall_dummy, wbs_stall_mem, wbs_stall_adcstr1, wbs_stall_adcstr2;
    wire wbs_ack_dummy, wbs_ack_mem, wbs_ack_adcstr1, wbs_ack_adcstr2;
    wire [31:0] wbs_rdata_dummy, wbs_rdata_mem, wbs_rdata_adcstr1, wbs_rdata_adcstr2;

    localparam WBS_ID_DUMMY = 0;
    localparam WBS_ID_MEM = 1;
    localparam WBS_ID_ADCSTR1 = 2;
    localparam WBS_ID_ADCSTR2 = 3;
    //
    localparam WBS_ID_COUNT = 4;
    //
    localparam WBS_ID_NBITS = $clog2(WBS_ID_COUNT);

    reg [WBS_ID_NBITS-1:0] wbs_id_sel_c;
    reg [WBS_ID_NBITS-1:0] wbs_id_sel_r;

    wire [WBS_ID_NBITS-1:0] wbs_id_sel;
    assign wbs_id_sel = (wbm_cyc && wb_stb) ? wbs_id_sel_c : wbs_id_sel_r;

    always @(*) begin
        if (wb_addr < 8'h10) begin
            wbs_id_sel_c = WBS_ID_MEM;
        end else if (wb_addr == 8'h20) begin
            wbs_id_sel_c = WBS_ID_ADCSTR1;
        end else if (wb_addr == 8'h21) begin
            wbs_id_sel_c = WBS_ID_ADCSTR2;
        end else begin
            wbs_id_sel_c = WBS_ID_DUMMY;
        end
    end

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            wbs_id_sel_r <= WBS_ID_DUMMY;
        end else begin
            if (wbm_cyc && wb_stb) begin
                wbs_id_sel_r <= wbs_id_sel_c;
            end
        end
    end

    always @(*) begin
        wbs_cyc_dummy = 1'b0;
        wbs_cyc_mem = 1'b0;
        wbs_cyc_adcstr1 = 1'b0;
        wbs_cyc_adcstr2 = 1'b0;

        if (wbs_id_sel == WBS_ID_MEM) begin
            wbs_cyc_mem = wbm_cyc;
            wbm_rdata = wbs_rdata_mem;
            wbm_stall = wbs_stall_mem;
            wbm_ack = wbs_ack_mem;
        end else if (wbs_id_sel == WBS_ID_ADCSTR1) begin
            wbs_cyc_adcstr1 = wbm_cyc;
            wbm_rdata = wbs_rdata_adcstr1;
            wbm_stall = wbs_stall_adcstr1;
            wbm_ack = wbs_ack_adcstr1;
        end else if (wbs_id_sel == WBS_ID_ADCSTR2) begin
            wbs_cyc_adcstr2 = wbm_cyc;
            wbm_rdata = wbs_rdata_adcstr2;
            wbm_stall = wbs_stall_adcstr2;
            wbm_ack = wbs_ack_adcstr2;
        end else begin
            // DUMMY
            wbs_cyc_dummy = wbm_cyc;
            wbm_rdata = wbs_rdata_dummy;
            wbm_stall = wbs_stall_dummy;
            wbm_ack = wbs_ack_dummy;
        end
    end

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
        .i_wb_cyc(wbs_cyc_adcstr1),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wbs_stall_adcstr1),
        .o_wb_ack(wbs_ack_adcstr1),
        .i_wb_we(wb_we),
        .o_wb_data(wbs_rdata_adcstr1),
        // rx stream
        .i_rx_valid(!adcstr1_valid_n),
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
        .i_wb_cyc(wbs_cyc_adcstr2),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wbs_stall_adcstr2),
        .o_wb_ack(wbs_ack_adcstr2),
        .i_wb_we(wb_we),
        .o_wb_data(wbs_rdata_adcstr2),
        // rx stream
        .i_rx_valid(!adcstr2_valid_n),
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
        .i_wb_cyc(wbs_cyc_dummy),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wbs_stall_dummy),
        .o_wb_ack(wbs_ack_dummy),
        .o_wb_data(wbs_rdata_dummy)
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
        .i_wb_cyc(wbs_cyc_mem),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wbs_stall_mem),
        .o_wb_ack(wbs_ack_mem),
        .i_wb_we(wb_we),
        .i_wb_addr(wb_addr[3:0]),
        .i_wb_data(wb_wdata),
        .i_wb_sel(wb_sel),
        .o_wb_data(wbs_rdata_mem)
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
    assign p_led_in3_g = 0;
    assign p_led_in4_r = adcstr1_emreq_ready;
    assign p_led_in4_g = 0;
endmodule