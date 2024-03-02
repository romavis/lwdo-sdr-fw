`include "rggen_rtl_macros.vh"
module lwdo_regs #(
  parameter ADDRESS_WIDTH = 10,
  parameter PRE_DECODE = 0,
  parameter [ADDRESS_WIDTH-1:0] BASE_ADDRESS = 0,
  parameter ERROR_STATUS = 0,
  parameter [31:0] DEFAULT_READ_DATA = 0,
  parameter INSERT_SLICER = 0,
  parameter USE_STALL = 1,
  parameter [3:0] SYS_PLL_DIVR_INITIAL_VALUE = 4'h0,
  parameter [6:0] SYS_PLL_DIVF_INITIAL_VALUE = 7'h00,
  parameter [2:0] SYS_PLL_DIVQ_INITIAL_VALUE = 3'h0,
  parameter [3:0] TDC_PLL_DIVR_INITIAL_VALUE = 4'h0,
  parameter [6:0] TDC_PLL_DIVF_INITIAL_VALUE = 7'h00,
  parameter [2:0] TDC_PLL_DIVQ_INITIAL_VALUE = 3'h0,
  parameter [6:0] TDC_PLL_SS_DIVFSPAN_INITIAL_VALUE = 7'h00,
  parameter [31:0] TDC_DIV_GATE_INITIAL_VALUE = 32'h00000000,
  parameter [31:0] TDC_DIV_MEAS_FAST_INITIAL_VALUE = 32'h00000000
)(
  input i_clk,
  input i_rst_n,
  input i_wb_cyc,
  input i_wb_stb,
  output o_wb_stall,
  input [ADDRESS_WIDTH-1:0] i_wb_adr,
  input i_wb_we,
  input [31:0] i_wb_dat,
  input [3:0] i_wb_sel,
  output o_wb_ack,
  output o_wb_err,
  output o_wb_rty,
  output [31:0] o_wb_dat,
  output o_sys_con_sys_rst,
  input [31:0] i_hwtime_cnt,
  output o_tdc_con_en,
  output o_tdc_con_clk_meas_fast,
  output o_tdc_con_gate_fdec,
  output o_tdc_con_gate_finc,
  output [3:0] o_adc_con_adc_en,
  output [23:0] o_adc_sample_rate_div,
  output [7:0] o_adc_ts_rate_div,
  output [7:0] o_ftun_vtune_set_dac_low,
  output [15:0] o_ftun_vtune_set_dac_high,
  output o_ftun_vtune_set_dac_high_write_trigger,
  output o_ftun_vtune_set_dac_high_read_trigger,
  output o_pps_con_en,
  output [27:0] o_pps_rate_div,
  output [27:0] o_pps_pulse_width,
  output [31:0] o_test_rw_val
);
  wire w_register_valid;
  wire [1:0] w_register_access;
  wire [9:0] w_register_address;
  wire [31:0] w_register_write_data;
  wire [31:0] w_register_strobe;
  wire [16:0] w_register_active;
  wire [16:0] w_register_ready;
  wire [33:0] w_register_status;
  wire [543:0] w_register_read_data;
  wire [543:0] w_register_value;
  rggen_wishbone_adapter #(
    .ADDRESS_WIDTH        (ADDRESS_WIDTH),
    .LOCAL_ADDRESS_WIDTH  (10),
    .BUS_WIDTH            (32),
    .REGISTERS            (17),
    .PRE_DECODE           (PRE_DECODE),
    .BASE_ADDRESS         (BASE_ADDRESS),
    .BYTE_SIZE            (1024),
    .ERROR_STATUS         (ERROR_STATUS),
    .DEFAULT_READ_DATA    (DEFAULT_READ_DATA),
    .INSERT_SLICER        (INSERT_SLICER),
    .USE_STALL            (USE_STALL)
  ) u_adapter (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),
    .i_wb_cyc               (i_wb_cyc),
    .i_wb_stb               (i_wb_stb),
    .o_wb_stall             (o_wb_stall),
    .i_wb_adr               (i_wb_adr),
    .i_wb_we                (i_wb_we),
    .i_wb_dat               (i_wb_dat),
    .i_wb_sel               (i_wb_sel),
    .o_wb_ack               (o_wb_ack),
    .o_wb_err               (o_wb_err),
    .o_wb_rty               (o_wb_rty),
    .o_wb_dat               (o_wb_dat),
    .o_register_valid       (w_register_valid),
    .o_register_access      (w_register_access),
    .o_register_address     (w_register_address),
    .o_register_write_data  (w_register_write_data),
    .o_register_strobe      (w_register_strobe),
    .i_register_active      (w_register_active),
    .i_register_ready       (w_register_ready),
    .i_register_status      (w_register_status),
    .i_register_read_data   (w_register_read_data)
  );
  generate if (1) begin : g_sys
    if (1) begin : g_magic
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'hffffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h000),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[0+:1]),
        .o_register_ready       (w_register_ready[0+:1]),
        .o_register_status      (w_register_status[0+:2]),
        .o_register_read_data   (w_register_read_data[0+:32]),
        .o_register_value       (w_register_value[0+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_magic
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:32]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:32]),
          .i_sw_write_data    (w_bit_field_write_data[0+:32]),
          .o_sw_read_data     (w_bit_field_read_data[0+:32]),
          .o_sw_value         (w_bit_field_value[0+:32]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({32{1'b0}}),
          .i_hw_set           ({32{1'b0}}),
          .i_hw_clear         ({32{1'b0}}),
          .i_value            (32'h4544574c),
          .i_mask             ({32{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_version
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'hffffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h004),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[1+:1]),
        .o_register_ready       (w_register_ready[1+:1]),
        .o_register_status      (w_register_status[2+:2]),
        .o_register_read_data   (w_register_read_data[32+:32]),
        .o_register_value       (w_register_value[32+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_major
        rggen_bit_field #(
          .WIDTH              (16),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:16]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:16]),
          .i_sw_write_data    (w_bit_field_write_data[0+:16]),
          .o_sw_read_data     (w_bit_field_read_data[0+:16]),
          .o_sw_value         (w_bit_field_value[0+:16]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({16{1'b0}}),
          .i_hw_set           ({16{1'b0}}),
          .i_hw_clear         ({16{1'b0}}),
          .i_value            (16'h0001),
          .i_mask             ({16{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_minor
        rggen_bit_field #(
          .WIDTH              (16),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[16+:16]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[16+:16]),
          .i_sw_write_data    (w_bit_field_write_data[16+:16]),
          .o_sw_read_data     (w_bit_field_read_data[16+:16]),
          .o_sw_value         (w_bit_field_value[16+:16]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({16{1'b0}}),
          .i_hw_set           ({16{1'b0}}),
          .i_hw_clear         ({16{1'b0}}),
          .i_value            (16'h0001),
          .i_mask             ({16{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_con
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h00000001, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h008),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[2+:1]),
        .o_register_ready       (w_register_ready[2+:1]),
        .o_register_status      (w_register_status[4+:2]),
        .o_register_read_data   (w_register_read_data[64+:32]),
        .o_register_value       (w_register_value[64+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_sys_rst
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (1'h0),
          .SW_WRITE_ONCE  (1),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:1]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:1]),
          .i_sw_write_data    (w_bit_field_write_data[0+:1]),
          .o_sw_read_data     (w_bit_field_read_data[0+:1]),
          .o_sw_value         (w_bit_field_value[0+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            ({1{1'b0}}),
          .i_mask             ({1{1'b1}}),
          .o_value            (o_sys_con_sys_rst),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_pll
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h00003fff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h00c),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[3+:1]),
        .o_register_ready       (w_register_ready[3+:1]),
        .o_register_status      (w_register_status[6+:2]),
        .o_register_read_data   (w_register_read_data[96+:32]),
        .o_register_value       (w_register_value[96+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_divr
        rggen_bit_field #(
          .WIDTH              (4),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:4]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:4]),
          .i_sw_write_data    (w_bit_field_write_data[0+:4]),
          .o_sw_read_data     (w_bit_field_read_data[0+:4]),
          .o_sw_value         (w_bit_field_value[0+:4]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({4{1'b0}}),
          .i_hw_set           ({4{1'b0}}),
          .i_hw_clear         ({4{1'b0}}),
          .i_value            (SYS_PLL_DIVR_INITIAL_VALUE),
          .i_mask             ({4{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_divf
        rggen_bit_field #(
          .WIDTH              (7),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[4+:7]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[4+:7]),
          .i_sw_write_data    (w_bit_field_write_data[4+:7]),
          .o_sw_read_data     (w_bit_field_read_data[4+:7]),
          .o_sw_value         (w_bit_field_value[4+:7]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({7{1'b0}}),
          .i_hw_set           ({7{1'b0}}),
          .i_hw_clear         ({7{1'b0}}),
          .i_value            (SYS_PLL_DIVF_INITIAL_VALUE),
          .i_mask             ({7{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_divq
        rggen_bit_field #(
          .WIDTH              (3),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[11+:3]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[11+:3]),
          .i_sw_write_data    (w_bit_field_write_data[11+:3]),
          .o_sw_read_data     (w_bit_field_read_data[11+:3]),
          .o_sw_value         (w_bit_field_value[11+:3]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({3{1'b0}}),
          .i_hw_set           ({3{1'b0}}),
          .i_hw_clear         ({3{1'b0}}),
          .i_value            (SYS_PLL_DIVQ_INITIAL_VALUE),
          .i_mask             ({3{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_hwtime
    if (1) begin : g_cnt
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'hffffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h020),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[4+:1]),
        .o_register_ready       (w_register_ready[4+:1]),
        .o_register_status      (w_register_status[8+:2]),
        .o_register_read_data   (w_register_read_data[128+:32]),
        .o_register_value       (w_register_value[128+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_cnt
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:32]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:32]),
          .i_sw_write_data    (w_bit_field_write_data[0+:32]),
          .o_sw_read_data     (w_bit_field_read_data[0+:32]),
          .o_sw_value         (w_bit_field_value[0+:32]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({32{1'b0}}),
          .i_hw_set           ({32{1'b0}}),
          .i_hw_clear         ({32{1'b0}}),
          .i_value            (i_hwtime_cnt),
          .i_mask             ({32{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_tdc
    if (1) begin : g_con
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h0000000f, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h040),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[5+:1]),
        .o_register_ready       (w_register_ready[5+:1]),
        .o_register_status      (w_register_status[10+:2]),
        .o_register_read_data   (w_register_read_data[160+:32]),
        .o_register_value       (w_register_value[160+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_en
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (1'h0),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:1]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:1]),
          .i_sw_write_data    (w_bit_field_write_data[0+:1]),
          .o_sw_read_data     (w_bit_field_read_data[0+:1]),
          .o_sw_value         (w_bit_field_value[0+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            ({1{1'b0}}),
          .i_mask             ({1{1'b1}}),
          .o_value            (o_tdc_con_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_clk_meas_fast
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (1'h0),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[1+:1]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[1+:1]),
          .i_sw_write_data    (w_bit_field_write_data[1+:1]),
          .o_sw_read_data     (w_bit_field_read_data[1+:1]),
          .o_sw_value         (w_bit_field_value[1+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            ({1{1'b0}}),
          .i_mask             ({1{1'b1}}),
          .o_value            (o_tdc_con_clk_meas_fast),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_gate_fdec
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (1'h0),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[2+:1]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[2+:1]),
          .i_sw_write_data    (w_bit_field_write_data[2+:1]),
          .o_sw_read_data     (w_bit_field_read_data[2+:1]),
          .o_sw_value         (w_bit_field_value[2+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            ({1{1'b0}}),
          .i_mask             ({1{1'b1}}),
          .o_value            (o_tdc_con_gate_fdec),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_gate_finc
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (1'h0),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[3+:1]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[3+:1]),
          .i_sw_write_data    (w_bit_field_write_data[3+:1]),
          .o_sw_read_data     (w_bit_field_read_data[3+:1]),
          .o_sw_value         (w_bit_field_value[3+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            ({1{1'b0}}),
          .i_mask             ({1{1'b1}}),
          .o_value            (o_tdc_con_gate_finc),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_pll
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h001fffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h044),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[6+:1]),
        .o_register_ready       (w_register_ready[6+:1]),
        .o_register_status      (w_register_status[12+:2]),
        .o_register_read_data   (w_register_read_data[192+:32]),
        .o_register_value       (w_register_value[192+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_divr
        rggen_bit_field #(
          .WIDTH              (4),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:4]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:4]),
          .i_sw_write_data    (w_bit_field_write_data[0+:4]),
          .o_sw_read_data     (w_bit_field_read_data[0+:4]),
          .o_sw_value         (w_bit_field_value[0+:4]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({4{1'b0}}),
          .i_hw_set           ({4{1'b0}}),
          .i_hw_clear         ({4{1'b0}}),
          .i_value            (TDC_PLL_DIVR_INITIAL_VALUE),
          .i_mask             ({4{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_divf
        rggen_bit_field #(
          .WIDTH              (7),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[4+:7]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[4+:7]),
          .i_sw_write_data    (w_bit_field_write_data[4+:7]),
          .o_sw_read_data     (w_bit_field_read_data[4+:7]),
          .o_sw_value         (w_bit_field_value[4+:7]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({7{1'b0}}),
          .i_hw_set           ({7{1'b0}}),
          .i_hw_clear         ({7{1'b0}}),
          .i_value            (TDC_PLL_DIVF_INITIAL_VALUE),
          .i_mask             ({7{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_divq
        rggen_bit_field #(
          .WIDTH              (3),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[11+:3]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[11+:3]),
          .i_sw_write_data    (w_bit_field_write_data[11+:3]),
          .o_sw_read_data     (w_bit_field_read_data[11+:3]),
          .o_sw_value         (w_bit_field_value[11+:3]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({3{1'b0}}),
          .i_hw_set           ({3{1'b0}}),
          .i_hw_clear         ({3{1'b0}}),
          .i_value            (TDC_PLL_DIVQ_INITIAL_VALUE),
          .i_mask             ({3{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_ss_divfspan
        rggen_bit_field #(
          .WIDTH              (7),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[14+:7]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[14+:7]),
          .i_sw_write_data    (w_bit_field_write_data[14+:7]),
          .o_sw_read_data     (w_bit_field_read_data[14+:7]),
          .o_sw_value         (w_bit_field_value[14+:7]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({7{1'b0}}),
          .i_hw_set           ({7{1'b0}}),
          .i_hw_clear         ({7{1'b0}}),
          .i_value            (TDC_PLL_SS_DIVFSPAN_INITIAL_VALUE),
          .i_mask             ({7{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_div_gate
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'hffffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h048),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[7+:1]),
        .o_register_ready       (w_register_ready[7+:1]),
        .o_register_status      (w_register_status[14+:2]),
        .o_register_read_data   (w_register_read_data[224+:32]),
        .o_register_value       (w_register_value[224+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_div_gate
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:32]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:32]),
          .i_sw_write_data    (w_bit_field_write_data[0+:32]),
          .o_sw_read_data     (w_bit_field_read_data[0+:32]),
          .o_sw_value         (w_bit_field_value[0+:32]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({32{1'b0}}),
          .i_hw_set           ({32{1'b0}}),
          .i_hw_clear         ({32{1'b0}}),
          .i_value            (TDC_DIV_GATE_INITIAL_VALUE),
          .i_mask             ({32{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_div_meas_fast
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'hffffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h04c),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[8+:1]),
        .o_register_ready       (w_register_ready[8+:1]),
        .o_register_status      (w_register_status[16+:2]),
        .o_register_read_data   (w_register_read_data[256+:32]),
        .o_register_value       (w_register_value[256+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_div_meas_fast
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              (1'b0),
          .i_rst_n            (1'b0),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:32]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:32]),
          .i_sw_write_data    (w_bit_field_write_data[0+:32]),
          .o_sw_read_data     (w_bit_field_read_data[0+:32]),
          .o_sw_value         (w_bit_field_value[0+:32]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({32{1'b0}}),
          .i_hw_set           ({32{1'b0}}),
          .i_hw_clear         ({32{1'b0}}),
          .i_value            (TDC_DIV_MEAS_FAST_INITIAL_VALUE),
          .i_mask             ({32{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_adc
    if (1) begin : g_con
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h0000000f, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h060),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[9+:1]),
        .o_register_ready       (w_register_ready[9+:1]),
        .o_register_status      (w_register_status[18+:2]),
        .o_register_read_data   (w_register_read_data[288+:32]),
        .o_register_value       (w_register_value[288+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_adc_en
        rggen_bit_field #(
          .WIDTH          (4),
          .INITIAL_VALUE  (4'h0),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:4]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:4]),
          .i_sw_write_data    (w_bit_field_write_data[0+:4]),
          .o_sw_read_data     (w_bit_field_read_data[0+:4]),
          .o_sw_value         (w_bit_field_value[0+:4]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({4{1'b0}}),
          .i_hw_set           ({4{1'b0}}),
          .i_hw_clear         ({4{1'b0}}),
          .i_value            ({4{1'b0}}),
          .i_mask             ({4{1'b1}}),
          .o_value            (o_adc_con_adc_en),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_sample_rate_div
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h00ffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h064),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[10+:1]),
        .o_register_ready       (w_register_ready[10+:1]),
        .o_register_status      (w_register_status[20+:2]),
        .o_register_read_data   (w_register_read_data[320+:32]),
        .o_register_value       (w_register_value[320+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_sample_rate_div
        rggen_bit_field #(
          .WIDTH          (24),
          .INITIAL_VALUE  (24'hffffff),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:24]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:24]),
          .i_sw_write_data    (w_bit_field_write_data[0+:24]),
          .o_sw_read_data     (w_bit_field_read_data[0+:24]),
          .o_sw_value         (w_bit_field_value[0+:24]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({24{1'b0}}),
          .i_hw_set           ({24{1'b0}}),
          .i_hw_clear         ({24{1'b0}}),
          .i_value            ({24{1'b0}}),
          .i_mask             ({24{1'b1}}),
          .o_value            (o_adc_sample_rate_div),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ts_rate_div
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h000000ff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h068),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[11+:1]),
        .o_register_ready       (w_register_ready[11+:1]),
        .o_register_status      (w_register_status[22+:2]),
        .o_register_read_data   (w_register_read_data[352+:32]),
        .o_register_value       (w_register_value[352+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_ts_rate_div
        rggen_bit_field #(
          .WIDTH          (8),
          .INITIAL_VALUE  (8'hff),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:8]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:8]),
          .i_sw_write_data    (w_bit_field_write_data[0+:8]),
          .o_sw_read_data     (w_bit_field_read_data[0+:8]),
          .o_sw_value         (w_bit_field_value[0+:8]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({8{1'b0}}),
          .i_hw_set           ({8{1'b0}}),
          .i_hw_clear         ({8{1'b0}}),
          .i_value            ({8{1'b0}}),
          .i_mask             ({8{1'b1}}),
          .o_value            (o_adc_ts_rate_div),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_ftun
    if (1) begin : g_vtune_set
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h00ffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h080),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[12+:1]),
        .o_register_ready       (w_register_ready[12+:1]),
        .o_register_status      (w_register_status[24+:2]),
        .o_register_read_data   (w_register_read_data[384+:32]),
        .o_register_value       (w_register_value[384+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_dac_low
        rggen_bit_field #(
          .WIDTH          (8),
          .INITIAL_VALUE  (8'h00),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:8]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:8]),
          .i_sw_write_data    (w_bit_field_write_data[0+:8]),
          .o_sw_read_data     (w_bit_field_read_data[0+:8]),
          .o_sw_value         (w_bit_field_value[0+:8]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({8{1'b0}}),
          .i_hw_set           ({8{1'b0}}),
          .i_hw_clear         ({8{1'b0}}),
          .i_value            ({8{1'b0}}),
          .i_mask             ({8{1'b1}}),
          .o_value            (o_ftun_vtune_set_dac_low),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_dac_high
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (16'h8000),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[8+:16]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[8+:16]),
          .i_sw_write_data    (w_bit_field_write_data[8+:16]),
          .o_sw_read_data     (w_bit_field_read_data[8+:16]),
          .o_sw_value         (w_bit_field_value[8+:16]),
          .o_write_trigger    (o_ftun_vtune_set_dac_high_write_trigger),
          .o_read_trigger     (o_ftun_vtune_set_dac_high_read_trigger),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({16{1'b0}}),
          .i_hw_set           ({16{1'b0}}),
          .i_hw_clear         ({16{1'b0}}),
          .i_value            ({16{1'b0}}),
          .i_mask             ({16{1'b1}}),
          .o_value            (o_ftun_vtune_set_dac_high),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_pps
    if (1) begin : g_con
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h00000001, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h0a0),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[13+:1]),
        .o_register_ready       (w_register_ready[13+:1]),
        .o_register_status      (w_register_status[26+:2]),
        .o_register_read_data   (w_register_read_data[416+:32]),
        .o_register_value       (w_register_value[416+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_en
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (1'h0),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:1]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:1]),
          .i_sw_write_data    (w_bit_field_write_data[0+:1]),
          .o_sw_read_data     (w_bit_field_read_data[0+:1]),
          .o_sw_value         (w_bit_field_value[0+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            ({1{1'b0}}),
          .i_mask             ({1{1'b1}}),
          .o_value            (o_pps_con_en),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_rate_div
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h0fffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h0a4),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[14+:1]),
        .o_register_ready       (w_register_ready[14+:1]),
        .o_register_status      (w_register_status[28+:2]),
        .o_register_read_data   (w_register_read_data[448+:32]),
        .o_register_value       (w_register_value[448+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_rate_div
        rggen_bit_field #(
          .WIDTH          (28),
          .INITIAL_VALUE  (28'hfffffff),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:28]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:28]),
          .i_sw_write_data    (w_bit_field_write_data[0+:28]),
          .o_sw_read_data     (w_bit_field_read_data[0+:28]),
          .o_sw_value         (w_bit_field_value[0+:28]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({28{1'b0}}),
          .i_hw_set           ({28{1'b0}}),
          .i_hw_clear         ({28{1'b0}}),
          .i_value            ({28{1'b0}}),
          .i_mask             ({28{1'b1}}),
          .o_value            (o_pps_rate_div),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_pulse_width
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h0fffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h0a8),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[15+:1]),
        .o_register_ready       (w_register_ready[15+:1]),
        .o_register_status      (w_register_status[30+:2]),
        .o_register_read_data   (w_register_read_data[480+:32]),
        .o_register_value       (w_register_value[480+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_pulse_width
        rggen_bit_field #(
          .WIDTH          (28),
          .INITIAL_VALUE  (28'h0010000),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:28]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:28]),
          .i_sw_write_data    (w_bit_field_write_data[0+:28]),
          .o_sw_read_data     (w_bit_field_read_data[0+:28]),
          .o_sw_value         (w_bit_field_value[0+:28]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({28{1'b0}}),
          .i_hw_set           ({28{1'b0}}),
          .i_hw_clear         ({28{1'b0}}),
          .i_value            ({28{1'b0}}),
          .i_mask             ({28{1'b1}}),
          .o_value            (o_pps_pulse_width),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_test
    if (1) begin : g_rw
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'hffffffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (10),
        .OFFSET_ADDRESS (10'h3e0),
        .BUS_WIDTH      (32),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[16+:1]),
        .o_register_ready       (w_register_ready[16+:1]),
        .o_register_status      (w_register_status[32+:2]),
        .o_register_read_data   (w_register_read_data[512+:32]),
        .o_register_value       (w_register_value[512+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (32),
          .INITIAL_VALUE  (32'haaa5555b),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:32]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:32]),
          .i_sw_write_data    (w_bit_field_write_data[0+:32]),
          .o_sw_read_data     (w_bit_field_read_data[0+:32]),
          .o_sw_value         (w_bit_field_value[0+:32]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({32{1'b0}}),
          .i_hw_set           ({32{1'b0}}),
          .i_hw_clear         ({32{1'b0}}),
          .i_value            ({32{1'b0}}),
          .i_mask             ({32{1'b1}}),
          .o_value            (o_test_rw_val),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
endmodule
