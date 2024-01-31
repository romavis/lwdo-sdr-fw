`include "rggen_rtl_macros.vh"
module lwdo_regs #(
  parameter ADDRESS_WIDTH = 9,
  parameter PRE_DECODE = 0,
  parameter [ADDRESS_WIDTH-1:0] BASE_ADDRESS = 0,
  parameter ERROR_STATUS = 0,
  parameter [15:0] DEFAULT_READ_DATA = 0,
  parameter INSERT_SLICER = 0,
  parameter USE_STALL = 1,
  parameter [3:0] SYS_PLL_DIVR_INITIAL_VALUE = 4'h0,
  parameter [6:0] SYS_PLL_DIVF_INITIAL_VALUE = 7'h00,
  parameter [2:0] SYS_PLL_DIVQ_INITIAL_VALUE = 3'h0,
  parameter [31:0] PDET_N1_VAL_INITIAL_VALUE = 32'h00000000,
  parameter [31:0] PDET_N2_VAL_INITIAL_VALUE = 32'h00000000
)(
  input i_clk,
  input i_rst_n,
  input i_wb_cyc,
  input i_wb_stb,
  output o_wb_stall,
  input [ADDRESS_WIDTH-1:0] i_wb_adr,
  input i_wb_we,
  input [15:0] i_wb_dat,
  input [1:0] i_wb_sel,
  output o_wb_ack,
  output o_wb_err,
  output o_wb_rty,
  output [15:0] o_wb_dat,
  output o_sys_con_sys_rst,
  output o_pdet_con_en,
  output o_pdet_con_eclk2_slow,
  output o_adct_con_srate1_en,
  output o_adct_con_srate2_en,
  output o_adct_con_puls1_en,
  output o_adct_con_puls2_en,
  output [7:0] o_adct_srate1_psc_div_val,
  output [7:0] o_adct_srate2_psc_div_val,
  output [22:0] o_adct_puls1_psc_div_val,
  output [22:0] o_adct_puls2_psc_div_val,
  output [8:0] o_adct_puls1_dly_val,
  output [8:0] o_adct_puls2_dly_val,
  output [15:0] o_adct_puls1_pwidth_val,
  output [15:0] o_adct_puls2_pwidth_val,
  output o_adc_con_adc1_en,
  output o_adc_con_adc2_en,
  input i_adc_fifo1_sts_empty,
  input i_adc_fifo1_sts_full,
  input i_adc_fifo1_sts_hfull,
  input i_adc_fifo1_sts_ovfl,
  output o_adc_fifo1_sts_ovfl_read_trigger,
  input i_adc_fifo1_sts_udfl,
  output o_adc_fifo1_sts_udfl_read_trigger,
  input i_adc_fifo2_sts_empty,
  input i_adc_fifo2_sts_full,
  input i_adc_fifo2_sts_hfull,
  input i_adc_fifo2_sts_ovfl,
  output o_adc_fifo2_sts_ovfl_read_trigger,
  input i_adc_fifo2_sts_udfl,
  output o_adc_fifo2_sts_udfl_read_trigger,
  output [15:0] o_ftun_vtune_set_val,
  output o_ftun_vtune_set_val_write_trigger,
  output o_ftun_vtune_set_val_read_trigger,
  output [15:0] o_test_rw1_val
);
  wire w_register_valid;
  wire [1:0] w_register_access;
  wire [8:0] w_register_address;
  wire [15:0] w_register_write_data;
  wire [15:0] w_register_strobe;
  wire [24:0] w_register_active;
  wire [24:0] w_register_ready;
  wire [49:0] w_register_status;
  wire [399:0] w_register_read_data;
  wire [799:0] w_register_value;
  rggen_wishbone_adapter #(
    .ADDRESS_WIDTH        (ADDRESS_WIDTH),
    .LOCAL_ADDRESS_WIDTH  (9),
    .BUS_WIDTH            (16),
    .REGISTERS            (25),
    .PRE_DECODE           (PRE_DECODE),
    .BASE_ADDRESS         (BASE_ADDRESS),
    .BYTE_SIZE            (512),
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
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h000),
        .BUS_WIDTH      (16),
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
        .o_register_read_data   (w_register_read_data[0+:16]),
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
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h004),
        .BUS_WIDTH      (16),
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
        .o_register_read_data   (w_register_read_data[16+:16]),
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
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h0001, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h008),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[32+:16]),
        .o_register_value       (w_register_value[64+:16]),
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
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h3fff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h00a),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[48+:16]),
        .o_register_value       (w_register_value[96+:16]),
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
  generate if (1) begin : g_pdet
    if (1) begin : g_con
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h0003, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h020),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[64+:16]),
        .o_register_value       (w_register_value[128+:16]),
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
          .o_value            (o_pdet_con_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_eclk2_slow
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
          .o_value            (o_pdet_con_eclk2_slow),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_n1
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
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h022),
        .BUS_WIDTH      (16),
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
        .o_register_read_data   (w_register_read_data[80+:16]),
        .o_register_value       (w_register_value[160+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
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
          .i_value            (PDET_N1_VAL_INITIAL_VALUE),
          .i_mask             ({32{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_n2
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
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h026),
        .BUS_WIDTH      (16),
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
        .o_register_read_data   (w_register_read_data[96+:16]),
        .o_register_value       (w_register_value[192+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
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
          .i_value            (PDET_N2_VAL_INITIAL_VALUE),
          .i_mask             ({32{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_adct
    if (1) begin : g_con
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h000f, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h040),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[112+:16]),
        .o_register_value       (w_register_value[224+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_srate1_en
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
          .o_value            (o_adct_con_srate1_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_srate2_en
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
          .o_value            (o_adct_con_srate2_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_puls1_en
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
          .o_value            (o_adct_con_puls1_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_puls2_en
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
          .o_value            (o_adct_con_puls2_en),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_srate1_psc_div
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h00ff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h042),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[128+:16]),
        .o_register_value       (w_register_value[256+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (8),
          .INITIAL_VALUE  (8'hc7),
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
          .o_value            (o_adct_srate1_psc_div_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_srate2_psc_div
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h00ff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h044),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[144+:16]),
        .o_register_value       (w_register_value[288+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (8),
          .INITIAL_VALUE  (8'hc7),
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
          .o_value            (o_adct_srate2_psc_div_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls1_psc_div
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h007fffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h046),
        .BUS_WIDTH      (16),
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
        .o_register_read_data   (w_register_read_data[160+:16]),
        .o_register_value       (w_register_value[320+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (23),
          .INITIAL_VALUE  (23'h000000),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:23]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:23]),
          .i_sw_write_data    (w_bit_field_write_data[0+:23]),
          .o_sw_read_data     (w_bit_field_read_data[0+:23]),
          .o_sw_value         (w_bit_field_value[0+:23]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({23{1'b0}}),
          .i_hw_set           ({23{1'b0}}),
          .i_hw_clear         ({23{1'b0}}),
          .i_value            ({23{1'b0}}),
          .i_mask             ({23{1'b1}}),
          .o_value            (o_adct_puls1_psc_div_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls2_psc_div
      wire w_bit_field_valid;
      wire [31:0] w_bit_field_read_mask;
      wire [31:0] w_bit_field_write_mask;
      wire [31:0] w_bit_field_write_data;
      wire [31:0] w_bit_field_read_data;
      wire [31:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(32, 32'h007fffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h04a),
        .BUS_WIDTH      (16),
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
        .o_register_read_data   (w_register_read_data[176+:16]),
        .o_register_value       (w_register_value[352+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (23),
          .INITIAL_VALUE  (23'h000000),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:23]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:23]),
          .i_sw_write_data    (w_bit_field_write_data[0+:23]),
          .o_sw_read_data     (w_bit_field_read_data[0+:23]),
          .o_sw_value         (w_bit_field_value[0+:23]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({23{1'b0}}),
          .i_hw_set           ({23{1'b0}}),
          .i_hw_clear         ({23{1'b0}}),
          .i_value            ({23{1'b0}}),
          .i_mask             ({23{1'b1}}),
          .o_value            (o_adct_puls2_psc_div_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls1_dly
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h01ff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h04e),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[192+:16]),
        .o_register_value       (w_register_value[384+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (9),
          .INITIAL_VALUE  (9'h000),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:9]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:9]),
          .i_sw_write_data    (w_bit_field_write_data[0+:9]),
          .o_sw_read_data     (w_bit_field_read_data[0+:9]),
          .o_sw_value         (w_bit_field_value[0+:9]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({9{1'b0}}),
          .i_hw_set           ({9{1'b0}}),
          .i_hw_clear         ({9{1'b0}}),
          .i_value            ({9{1'b0}}),
          .i_mask             ({9{1'b1}}),
          .o_value            (o_adct_puls1_dly_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls2_dly
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h01ff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h050),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[208+:16]),
        .o_register_value       (w_register_value[416+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (9),
          .INITIAL_VALUE  (9'h000),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:9]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:9]),
          .i_sw_write_data    (w_bit_field_write_data[0+:9]),
          .o_sw_read_data     (w_bit_field_read_data[0+:9]),
          .o_sw_value         (w_bit_field_value[0+:9]),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({9{1'b0}}),
          .i_hw_set           ({9{1'b0}}),
          .i_hw_clear         ({9{1'b0}}),
          .i_value            ({9{1'b0}}),
          .i_mask             ({9{1'b1}}),
          .o_value            (o_adct_puls2_dly_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls1_pwidth
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'hffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h052),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[224+:16]),
        .o_register_value       (w_register_value[448+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (16'h0001),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:16]),
          .i_sw_write_enable  (1'b1),
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
          .i_value            ({16{1'b0}}),
          .i_mask             ({16{1'b1}}),
          .o_value            (o_adct_puls1_pwidth_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls2_pwidth
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'hffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h054),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[240+:16]),
        .o_register_value       (w_register_value[480+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (16'h0001),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:16]),
          .i_sw_write_enable  (1'b1),
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
          .i_value            ({16{1'b0}}),
          .i_mask             ({16{1'b1}}),
          .o_value            (o_adct_puls2_pwidth_val),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_adc
    if (1) begin : g_con
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h0003, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h080),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
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
        .o_register_read_data   (w_register_read_data[256+:16]),
        .o_register_value       (w_register_value[512+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_adc1_en
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
          .o_value            (o_adc_con_adc1_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_adc2_en
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
          .o_value            (o_adc_con_adc2_en),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_fifo1_sts
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h001f, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h082),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[17+:1]),
        .o_register_ready       (w_register_ready[17+:1]),
        .o_register_status      (w_register_status[34+:2]),
        .o_register_read_data   (w_register_read_data[272+:16]),
        .o_register_value       (w_register_value[544+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_empty
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:1]),
          .i_sw_write_enable  (1'b0),
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
          .i_value            (i_adc_fifo1_sts_empty),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_full
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[1+:1]),
          .i_sw_write_enable  (1'b0),
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
          .i_value            (i_adc_fifo1_sts_full),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_hfull
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[2+:1]),
          .i_sw_write_enable  (1'b0),
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
          .i_value            (i_adc_fifo1_sts_hfull),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_ovfl
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[3+:1]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[3+:1]),
          .i_sw_write_data    (w_bit_field_write_data[3+:1]),
          .o_sw_read_data     (w_bit_field_read_data[3+:1]),
          .o_sw_value         (w_bit_field_value[3+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (o_adc_fifo1_sts_ovfl_read_trigger),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            (i_adc_fifo1_sts_ovfl),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_udfl
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[4+:1]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[4+:1]),
          .i_sw_write_data    (w_bit_field_write_data[4+:1]),
          .o_sw_read_data     (w_bit_field_read_data[4+:1]),
          .o_sw_value         (w_bit_field_value[4+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (o_adc_fifo1_sts_udfl_read_trigger),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            (i_adc_fifo1_sts_udfl),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_fifo2_sts
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'h001f, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h084),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[18+:1]),
        .o_register_ready       (w_register_ready[18+:1]),
        .o_register_status      (w_register_status[36+:2]),
        .o_register_read_data   (w_register_read_data[288+:16]),
        .o_register_value       (w_register_value[576+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_empty
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:1]),
          .i_sw_write_enable  (1'b0),
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
          .i_value            (i_adc_fifo2_sts_empty),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_full
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[1+:1]),
          .i_sw_write_enable  (1'b0),
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
          .i_value            (i_adc_fifo2_sts_full),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_hfull
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[2+:1]),
          .i_sw_write_enable  (1'b0),
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
          .i_value            (i_adc_fifo2_sts_hfull),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_ovfl
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[3+:1]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[3+:1]),
          .i_sw_write_data    (w_bit_field_write_data[3+:1]),
          .o_sw_read_data     (w_bit_field_read_data[3+:1]),
          .o_sw_value         (w_bit_field_value[3+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (o_adc_fifo2_sts_ovfl_read_trigger),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            (i_adc_fifo2_sts_ovfl),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_udfl
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[4+:1]),
          .i_sw_write_enable  (1'b0),
          .i_sw_write_mask    (w_bit_field_write_mask[4+:1]),
          .i_sw_write_data    (w_bit_field_write_data[4+:1]),
          .o_sw_read_data     (w_bit_field_read_data[4+:1]),
          .o_sw_value         (w_bit_field_value[4+:1]),
          .o_write_trigger    (),
          .o_read_trigger     (o_adc_fifo2_sts_udfl_read_trigger),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({1{1'b0}}),
          .i_hw_set           ({1{1'b0}}),
          .i_hw_clear         ({1{1'b0}}),
          .i_value            (i_adc_fifo2_sts_udfl),
          .i_mask             ({1{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_ftun
    if (1) begin : g_vtune_set
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'hffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h0a0),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[19+:1]),
        .o_register_ready       (w_register_ready[19+:1]),
        .o_register_status      (w_register_status[38+:2]),
        .o_register_read_data   (w_register_read_data[304+:16]),
        .o_register_value       (w_register_value[608+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (16'h8000),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:16]),
          .i_sw_write_enable  (1'b1),
          .i_sw_write_mask    (w_bit_field_write_mask[0+:16]),
          .i_sw_write_data    (w_bit_field_write_data[0+:16]),
          .o_sw_read_data     (w_bit_field_read_data[0+:16]),
          .o_sw_value         (w_bit_field_value[0+:16]),
          .o_write_trigger    (o_ftun_vtune_set_val_write_trigger),
          .o_read_trigger     (o_ftun_vtune_set_val_read_trigger),
          .i_hw_write_enable  (1'b0),
          .i_hw_write_data    ({16{1'b0}}),
          .i_hw_set           ({16{1'b0}}),
          .i_hw_clear         ({16{1'b0}}),
          .i_value            ({16{1'b0}}),
          .i_mask             ({16{1'b1}}),
          .o_value            (o_ftun_vtune_set_val),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_test
    if (1) begin : g_rw1
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'hffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1f0),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[20+:1]),
        .o_register_ready       (w_register_ready[20+:1]),
        .o_register_status      (w_register_status[40+:2]),
        .o_register_read_data   (w_register_read_data[320+:16]),
        .o_register_value       (w_register_value[640+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (16'h0000),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .i_sw_valid         (w_bit_field_valid),
          .i_sw_read_mask     (w_bit_field_read_mask[0+:16]),
          .i_sw_write_enable  (1'b1),
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
          .i_value            ({16{1'b0}}),
          .i_mask             ({16{1'b1}}),
          .o_value            (o_test_rw1_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ro1
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'hffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1f2),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[21+:1]),
        .o_register_ready       (w_register_ready[21+:1]),
        .o_register_status      (w_register_status[42+:2]),
        .o_register_read_data   (w_register_read_data[336+:16]),
        .o_register_value       (w_register_value[672+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
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
          .i_value            (16'hffff),
          .i_mask             ({16{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ro2
      wire w_bit_field_valid;
      wire [15:0] w_bit_field_read_mask;
      wire [15:0] w_bit_field_write_mask;
      wire [15:0] w_bit_field_write_data;
      wire [15:0] w_bit_field_read_data;
      wire [15:0] w_bit_field_value;
      `rggen_tie_off_unused_signals(16, 16'hffff, w_bit_field_read_data, w_bit_field_value)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1f4),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[22+:1]),
        .o_register_ready       (w_register_ready[22+:1]),
        .o_register_status      (w_register_status[44+:2]),
        .o_register_read_data   (w_register_read_data[352+:16]),
        .o_register_value       (w_register_value[704+:16]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
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
          .i_value            (16'h0000),
          .i_mask             ({16{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ro3
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
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1f6),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[23+:1]),
        .o_register_ready       (w_register_ready[23+:1]),
        .o_register_status      (w_register_status[46+:2]),
        .o_register_read_data   (w_register_read_data[368+:16]),
        .o_register_value       (w_register_value[736+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
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
          .i_value            (32'haaaaaa55),
          .i_mask             ({32{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ro4
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
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1fa),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32)
      ) u_register (
        .i_clk                  (i_clk),
        .i_rst_n                (i_rst_n),
        .i_register_valid       (w_register_valid),
        .i_register_access      (w_register_access),
        .i_register_address     (w_register_address),
        .i_register_write_data  (w_register_write_data),
        .i_register_strobe      (w_register_strobe),
        .o_register_active      (w_register_active[24+:1]),
        .o_register_ready       (w_register_ready[24+:1]),
        .o_register_status      (w_register_status[48+:2]),
        .o_register_read_data   (w_register_read_data[384+:16]),
        .o_register_value       (w_register_value[768+:32]),
        .o_bit_field_valid      (w_bit_field_valid),
        .o_bit_field_read_mask  (w_bit_field_read_mask),
        .o_bit_field_write_mask (w_bit_field_write_mask),
        .o_bit_field_write_data (w_bit_field_write_data),
        .i_bit_field_read_data  (w_bit_field_read_data),
        .i_bit_field_value      (w_bit_field_value)
      );
      if (1) begin : g_val
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
          .i_value            (32'h55aa5555),
          .i_mask             ({32{1'b1}}),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
endmodule
