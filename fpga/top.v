module top (
    // LEDs
    output led_sts_r,
    output led_sts_g,
    output led_in1_r,
    output led_in1_g,
    output led_in2_r,
    output led_in2_g,
    output led_in3_r,
    output led_in3_g,
    output led_in4_r,
    output led_in4_g,
    // ADC clocks: on pin 15 we have output, on pin 20 we have input
    output adc_sclk,
    input adc_sclk_gbin,
    // ADC data and sync
    input adc1_sda,
    input adc1_sdb,
    output adc1_cs_n,
    input adc2_sda,
    input adc2_sdb,
    output adc2_cs_n,
    // External I/O,
    inout [8:1] extio,
    // SPI DAC,
    output spi_dac_mosi,
    output spi_dac_sclk,
    output spi_dac_sync_n,
    // System clocks
    input clk_20mhz_gbin1,
    input clk_20mhz_gbin2,
    output clk_out,
    input clk_ref_in,
    output clk_out_sel,
    // FTDI GPIO
    input ftdi_io1,
    input ftdi_io2,
    // FTDI FIFO
    input ftdi_fifo_clkout,
    output ftdi_fifo_oe_n,
    output ftdi_fifo_siwu,
    output ftdi_fifo_wr_n,
    output ftdi_fifo_rd_n,
    input ftdi_fifo_txe_n,
    input ftdi_fifo_rxf_n,
    inout [7:0] ftdi_fifo_d
);

    localparam WB_ADDR_WIDTH = 10;

    // ------------------------
    // Main system clock
    // ------------------------
    wire sysclk = clk_20mhz_gbin1;

    // ------------------------
    // Reset generator - issues reset pulse 1 sysclk wide
    // ------------------------
    reg rst = 0;
    reg rst_done = 0;
    always @(posedge sysclk) begin
        if (!rst_done) begin
            rst <= 1;
            rst_done <= 1;
        end else begin
            rst <= 0;
        end
    end

    // ------------------------
    // DAC driver
    // ------------------------
    reg [23:0] dac_word = 23'h007F22;
    
    reg [23:0] dac_reg;
    reg [4:0] dac_cycle;
    reg [3:0] dac_div;
    reg dac_spi_clk;
    reg dac_spi_sync_n;

    always @(posedge sysclk) begin
        if (dac_div < 10) begin
            dac_div <= dac_div + 1;
        end else begin
            dac_div <= 0;
            dac_spi_clk <= ~dac_spi_clk;
            if (!dac_spi_clk) begin
                // clock dac state machine on the positive SPI CLK edge
                if (dac_cycle == 0) begin
                    // Load word to shift, assert nSYNC
                    dac_reg <= dac_word;
                    dac_spi_sync_n <= 1'b0;
                    dac_cycle <= dac_cycle + 1;
                end else if(dac_cycle <= 24) begin
                    // shift
                    dac_reg[23:0] <= {dac_reg[22:0], 1'b0};
                    dac_cycle <= dac_cycle + 1;
                end else if(dac_cycle < 30) begin 
                    // Deassert nSYNC
                    dac_spi_sync_n <= 1'b1;
                    dac_cycle <= dac_cycle + 1;
                end else begin
                    // Reset dac_cycle
                    dac_cycle <= 0;
                end
            end 
        end
    end

    assign spi_dac_mosi = dac_reg[23];
    assign spi_dac_sync_n = dac_spi_sync_n;
    assign spi_dac_sclk = dac_spi_clk;

    // ------------------------
    // ADC CLOCKING DOMAIN
    // ------------------------

    // Generate ADC clock with PLL
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
        .REFERENCECLK (sysclk),
        .PLLOUTCORE (adc_pll_out),
        .LOCK (adc_pll_lock),
        .RESETB(~rst),
        .BYPASS(1'b0)
    );

    // Generate clock on the pin
    assign adc_sclk = adc_pll_out;
    // Rebuffer clock via another I/O pin (and put it onto global net)
    wire clk_adc;
    assign clk_adc = adc_sclk_gbin;

    // ------------------------
    // ADC reset generator
    // ------------------------
    reg adc_rst = 0;
    reg adc_rst_done = 0;
    always @(negedge clk_adc) begin
        if (!adc_rst_done) begin
            adc_rst <= 1;
            adc_rst_done <= 1;
        end else begin
            adc_rst <= 0;
        end
    end

    // ------------------
    // ADC sample rate generator
    // ------------------
    reg [4:0] adc_srate_div_ctr;
    wire adc_srate_div_out;

    assign adc_srate_div_out = (adc_srate_div_ctr == 'd0);

    always @(negedge clk_adc) begin
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
    wire [13:0] adc1_data_a_imm;
    wire [13:0] adc1_data_b_imm;
    wire [13:0] adc2_data_a_imm;
    wire [13:0] adc2_data_b_imm;

    ad7357if adc1 (
        // interface
        .i_if_sclk(clk_adc),
        .o_if_cs_n(adc1_cs_n),
        .i_if_sdata_a(adc1_sda),
        .i_if_sdata_b(adc1_sdb),
        // Control
        .i_rst(adc_rst),
        .i_sync(adc_srate_div_out),
        // Data
        .o_ready(adc1_rdy),
        .o_sample_a(adc1_data_a_imm),
        .o_sample_b(adc1_data_b_imm)
    );

    ad7357if adc2 (
        // interface
        .i_if_sclk(clk_adc),
        .o_if_cs_n(adc2_cs_n),
        .i_if_sdata_a(adc2_sda),
        .i_if_sdata_b(adc2_sdb),
        // Control
        .i_rst(adc_rst),
        .i_sync(adc_srate_div_out),
        // Data
        .o_ready(adc2_rdy),
        .o_sample_a(adc2_data_a_imm),
        .o_sample_b(adc2_data_b_imm)
    );

    // ------------------
    // Register data captured by ADC
    // ------------------
    reg [13:0] adc_sample[0:3];

    always @(negedge clk_adc) begin
        if (adc1_rdy) begin
            adc_sample[0] <= adc1_data_a_imm;
            adc_sample[1] <= adc1_data_b_imm;
        end
        if (adc2_rdy) begin
            adc_sample[2] <= adc2_data_a_imm;
            adc_sample[3] <= adc2_data_b_imm;
        end
    end

    // ------------------------
    // Wishbone bus
    // ------------------------
    wire wb_cyc;
    wire wb_stb;
    wire wb_stall;
    wire wb_ack;
    wire wb_we;
    wire [WB_ADDR_WIDTH-1:0] wb_addr;
    wire [31:0] wb_data_w;
    wire [3:0] wb_sel;
    wire [31:0] wb_data_r;

    // ------------------------
    // FTDI SyncFIFO bidirectional data bus
    // ------------------------
    wire [7:0] ftdi_fifo_d_in;
    wire [7:0] ftdi_fifo_d_out;
    wire ftdi_fifo_d_oe;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01)
    ) ftdi_fifo_data_pins [7:0] (
        .PACKAGE_PIN(ftdi_fifo_d),
        .OUTPUT_ENABLE(ftdi_fifo_d_oe),
        .D_OUT_0(ftdi_fifo_d_out),
        .D_IN_0(ftdi_fifo_d_in)
    );

    // ------------------------
    // FTDI SyncFIFO
    // ------------------------
    wire ftdi_clk;

    reg [7:0] ftdi_tx_data;
    // reg ftdi_tx_valid;
    wire ftdi_tx_ready;

    wire [7:0] ftdi_rx_data;
    wire ftdi_rx_valid;
    // reg ftdi_rx_ready;

    wire [7:0] ftdi_dbg;
    wire [1:0] ftdi_dbg1;

    wb_ft245sync #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH)
    ) wb_ft245sync_i (
        // SYSCON
        .o_clk(ftdi_clk),
        .i_rst(ftdi_rst),
        // pins
        .i_pin_clkout(ftdi_fifo_clkout),
        .o_pin_oe_n(ftdi_fifo_oe_n),
        .o_pin_siwu(ftdi_fifo_siwu),
        .o_pin_wr_n(ftdi_fifo_wr_n),
        .o_pin_rd_n(ftdi_fifo_rd_n),
        .i_pin_rxf_n(ftdi_fifo_rxf_n),
        .i_pin_txe_n(ftdi_fifo_txe_n),
        .i_pin_data(ftdi_fifo_d_in),
        .o_pin_data(ftdi_fifo_d_out),
        .o_pin_data_oe(ftdi_fifo_d_oe),
        // Wishbone master
        .o_wb_cyc(wb_cyc),
        .o_wb_stb(wb_stb),
        .i_wb_stall(wb_stall),
        .i_wb_ack(wb_ack),
        .o_wb_we(wb_we),
        .o_wb_addr(wb_addr),
        .o_wb_data(wb_data_w),
        .o_wb_sel(wb_sel),
        .i_wb_data(wb_data_r),
        // dbg
        .o_dbg(ftdi_dbg),
        .o_dbg1(ftdi_dbg1)
    );

    // ------------------------
    // FTDI clock domain reset
    // ------------------------
    reg ftdi_rst = 0;
    reg ftdi_rst_done = 0;
    always @(posedge ftdi_clk) begin
        if (!ftdi_rst_done) begin
            ftdi_rst <= 1;
            ftdi_rst_done <= 1;
        end else begin
            ftdi_rst <= 0;
        end
    end

    // // ------------------------
    // // Wishbone dummy slave
    // // ------------------------
    // wb_dummy wb_dummy_i (
    //     .i_clk(ftdi_clk),
    //     // wb
    //     .i_wb_cyc(wb_cyc),
    //     .i_wb_stb(wb_stb),
    //     .o_wb_stall(wb_stall),
    //     .o_wb_ack(wb_ack),
    //     .o_wb_data(wb_data_r)
    // );

    // ------------------------
    // Wishbone RAM
    // ------------------------
    wb_mem #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH)
    ) wb_mem_i (
        .i_clk(ftdi_clk),
        .i_rst(rst),
        // wb
        .i_wb_cyc(wb_cyc),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wb_stall),
        .o_wb_ack(wb_ack),
        .i_wb_we(wb_we),
        .i_wb_addr(wb_addr),
        .i_wb_data(wb_data_w),
        .i_wb_sel(wb_sel),
        .o_wb_data(wb_data_r)
    );

    // ------------------------
    // CLK OUT
    // ------------------------
    assign clk_out_sel = 1'b1;
    assign clk_out = ~ftdi_dbg[5];

    // ------------------------
    // LEDs
    // ------------------------
    assign led_sts_r = ftdi_dbg1[0];
    assign led_sts_g = ftdi_dbg1[1];
    //
    assign led_in1_r = ftdi_dbg[0];
    assign led_in1_g = ftdi_dbg[1];
    assign led_in2_r = ftdi_dbg[2];
    assign led_in2_g = ftdi_dbg[3];
    assign led_in3_r = ftdi_dbg[4];
    assign led_in3_g = ftdi_dbg[5];
    assign led_in4_r = ftdi_dbg[6];
    assign led_in4_g = ftdi_dbg[7];

endmodule