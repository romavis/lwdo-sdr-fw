`ifndef rggen_connect_bit_field_if
  `define rggen_connect_bit_field_if(RIF, FIF, LSB, WIDTH) \
  assign  FIF.valid                 = RIF.valid; \
  assign  FIF.read_mask             = RIF.read_mask[LSB+:WIDTH]; \
  assign  FIF.write_mask            = RIF.write_mask[LSB+:WIDTH]; \
  assign  FIF.write_data            = RIF.write_data[LSB+:WIDTH]; \
  assign  RIF.read_data[LSB+:WIDTH] = FIF.read_data; \
  assign  RIF.value[LSB+:WIDTH]     = FIF.value;
`endif
`ifndef rggen_tie_off_unused_signals
  `define rggen_tie_off_unused_signals(WIDTH, VALID_BITS, RIF) \
  if (1) begin : __g_tie_off \
    genvar  __i; \
    for (__i = 0;__i < WIDTH;++__i) begin : g \
      if ((((VALID_BITS) >> __i) % 2) == 0) begin : g \
        assign  RIF.read_data[__i]  = 1'b0; \
        assign  RIF.value[__i]      = 1'b0; \
      end \
    end \
  end
`endif
module lwdo_regs
  import rggen_rtl_pkg::*;
#(
  parameter int ADDRESS_WIDTH = 9,
  parameter bit PRE_DECODE = 0,
  parameter bit [ADDRESS_WIDTH-1:0] BASE_ADDRESS = '0,
  parameter bit ERROR_STATUS = 0,
  parameter bit [15:0] DEFAULT_READ_DATA = '0,
  parameter bit INSERT_SLICER = 0,
  parameter bit USE_STALL = 1,
  parameter bit [3:0] SYS_PLL_DIVR_INITIAL_VALUE = 4'h0,
  parameter bit [6:0] SYS_PLL_DIVF_INITIAL_VALUE = 7'h00,
  parameter bit [2:0] SYS_PLL_DIVQ_INITIAL_VALUE = 3'h0,
  parameter bit [31:0] PDET_N1_VAL_INITIAL_VALUE = 32'h00000000,
  parameter bit [31:0] PDET_N2_VAL_INITIAL_VALUE = 32'h00000000
)(
  input logic i_clk,
  input logic i_rst_n,
  rggen_wishbone_if.slave wishbone_if,
  output logic o_sys_con_sys_rst,
  output logic o_pdet_con_en,
  output logic o_pdet_con_eclk2_slow,
  output logic o_adct_con_srate1_en,
  output logic o_adct_con_srate2_en,
  output logic o_adct_con_puls1_en,
  output logic o_adct_con_puls2_en,
  output logic [7:0] o_adct_srate1_psc_div_val,
  output logic [7:0] o_adct_srate2_psc_div_val,
  output logic [22:0] o_adct_puls1_psc_div_val,
  output logic [22:0] o_adct_puls2_psc_div_val,
  output logic [8:0] o_adct_puls1_dly_val,
  output logic [8:0] o_adct_puls2_dly_val,
  output logic [15:0] o_adct_puls1_pwidth_val,
  output logic [15:0] o_adct_puls2_pwidth_val,
  output logic o_adc_con_adc1_en,
  output logic o_adc_con_adc2_en,
  input logic i_adc_fifo1_sts_empty,
  input logic i_adc_fifo1_sts_full,
  input logic i_adc_fifo1_sts_hfull,
  input logic i_adc_fifo1_sts_ovfl,
  output logic o_adc_fifo1_sts_ovfl_read_trigger,
  input logic i_adc_fifo1_sts_udfl,
  output logic o_adc_fifo1_sts_udfl_read_trigger,
  input logic i_adc_fifo2_sts_empty,
  input logic i_adc_fifo2_sts_full,
  input logic i_adc_fifo2_sts_hfull,
  input logic i_adc_fifo2_sts_ovfl,
  output logic o_adc_fifo2_sts_ovfl_read_trigger,
  input logic i_adc_fifo2_sts_udfl,
  output logic o_adc_fifo2_sts_udfl_read_trigger,
  output logic [15:0] o_ftun_vtune_set_val,
  output logic o_ftun_vtune_set_val_write_trigger,
  output logic o_ftun_vtune_set_val_read_trigger,
  output logic [15:0] o_test_rw1_val
);
  rggen_register_if #(9, 16, 32) register_if[25]();
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
    .i_clk        (i_clk),
    .i_rst_n      (i_rst_n),
    .wishbone_if  (wishbone_if),
    .register_if  (register_if)
  );
  generate if (1) begin : g_sys
    if (1) begin : g_magic
      rggen_bit_field_if #(32) bit_field_if();
      `rggen_tie_off_unused_signals(32, 32'hffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h000),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[0]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_magic
        localparam bit [31:0] INITIAL_VALUE = 32'h4544574c;
        rggen_bit_field_if #(32) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_version
      rggen_bit_field_if #(32) bit_field_if();
      `rggen_tie_off_unused_signals(32, 32'hffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h004),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[1]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_major
        localparam bit [15:0] INITIAL_VALUE = 16'h0001;
        rggen_bit_field_if #(16) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 16)
        rggen_bit_field #(
          .WIDTH              (16),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_minor
        localparam bit [15:0] INITIAL_VALUE = 16'h0001;
        rggen_bit_field_if #(16) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 16, 16)
        rggen_bit_field #(
          .WIDTH              (16),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_con
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h0001, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h008),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[2]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_sys_rst
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (1),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_sys_con_sys_rst),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_pll
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h3fff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h00a),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[3]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_divr
        rggen_bit_field_if #(4) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 4)
        rggen_bit_field #(
          .WIDTH              (4),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (SYS_PLL_DIVR_INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_divf
        rggen_bit_field_if #(7) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 4, 7)
        rggen_bit_field #(
          .WIDTH              (7),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (SYS_PLL_DIVF_INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_divq
        rggen_bit_field_if #(3) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 11, 3)
        rggen_bit_field #(
          .WIDTH              (3),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (SYS_PLL_DIVQ_INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_pdet
    if (1) begin : g_con
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h0003, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h020),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[4]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_en
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_pdet_con_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_eclk2_slow
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 1, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_pdet_con_eclk2_slow),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_n1
      rggen_bit_field_if #(32) bit_field_if();
      `rggen_tie_off_unused_signals(32, 32'hffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h022),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[5]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        rggen_bit_field_if #(32) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (PDET_N1_VAL_INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_n2
      rggen_bit_field_if #(32) bit_field_if();
      `rggen_tie_off_unused_signals(32, 32'hffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h026),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[6]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        rggen_bit_field_if #(32) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (PDET_N2_VAL_INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_adct
    if (1) begin : g_con
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h000f, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h040),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[7]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_srate1_en
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_con_srate1_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_srate2_en
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 1, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_con_srate2_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_puls1_en
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 2, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_con_puls1_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_puls2_en
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 3, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_con_puls2_en),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_srate1_psc_div
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h00ff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h042),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[8]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [7:0] INITIAL_VALUE = 8'hc7;
        rggen_bit_field_if #(8) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 8)
        rggen_bit_field #(
          .WIDTH          (8),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_srate1_psc_div_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_srate2_psc_div
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h00ff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h044),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[9]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [7:0] INITIAL_VALUE = 8'hc7;
        rggen_bit_field_if #(8) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 8)
        rggen_bit_field #(
          .WIDTH          (8),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_srate2_psc_div_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls1_psc_div
      rggen_bit_field_if #(32) bit_field_if();
      `rggen_tie_off_unused_signals(32, 32'h007fffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h046),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[10]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [22:0] INITIAL_VALUE = 23'h000000;
        rggen_bit_field_if #(23) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 23)
        rggen_bit_field #(
          .WIDTH          (23),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_puls1_psc_div_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls2_psc_div
      rggen_bit_field_if #(32) bit_field_if();
      `rggen_tie_off_unused_signals(32, 32'h007fffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h04a),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[11]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [22:0] INITIAL_VALUE = 23'h000000;
        rggen_bit_field_if #(23) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 23)
        rggen_bit_field #(
          .WIDTH          (23),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_puls2_psc_div_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls1_dly
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h01ff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h04e),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[12]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [8:0] INITIAL_VALUE = 9'h000;
        rggen_bit_field_if #(9) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 9)
        rggen_bit_field #(
          .WIDTH          (9),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_puls1_dly_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls2_dly
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h01ff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h050),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[13]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [8:0] INITIAL_VALUE = 9'h000;
        rggen_bit_field_if #(9) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 9)
        rggen_bit_field #(
          .WIDTH          (9),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_puls2_dly_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls1_pwidth
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'hffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h052),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[14]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [15:0] INITIAL_VALUE = 16'h0001;
        rggen_bit_field_if #(16) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 16)
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_puls1_pwidth_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_puls2_pwidth
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'hffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h054),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[15]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [15:0] INITIAL_VALUE = 16'h0001;
        rggen_bit_field_if #(16) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 16)
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adct_puls2_pwidth_val),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_adc
    if (1) begin : g_con
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h0003, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h080),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[16]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_adc1_en
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adc_con_adc1_en),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_adc2_en
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 1, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_adc_con_adc2_en),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_fifo1_sts
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h001f, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h082),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[17]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_empty
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo1_sts_empty),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_full
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 1, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo1_sts_full),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_hfull
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 2, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo1_sts_hfull),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_ovfl
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 3, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (o_adc_fifo1_sts_ovfl_read_trigger),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo1_sts_ovfl),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_udfl
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 4, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (o_adc_fifo1_sts_udfl_read_trigger),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo1_sts_udfl),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_fifo2_sts
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'h001f, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h084),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[18]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_empty
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo2_sts_empty),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_full
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 1, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo2_sts_full),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_hfull
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 2, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo2_sts_hfull),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_ovfl
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 3, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (o_adc_fifo2_sts_ovfl_read_trigger),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo2_sts_ovfl),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_udfl
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 4, 1)
        rggen_bit_field #(
          .WIDTH              (1),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1),
          .TRIGGER            (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (o_adc_fifo2_sts_udfl_read_trigger),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (i_adc_fifo2_sts_udfl),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_ftun
    if (1) begin : g_vtune_set
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'hffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h0a0),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[19]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [15:0] INITIAL_VALUE = 16'h8000;
        rggen_bit_field_if #(16) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 16)
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (1)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (o_ftun_vtune_set_val_write_trigger),
          .o_read_trigger     (o_ftun_vtune_set_val_read_trigger),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_ftun_vtune_set_val),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_test
    if (1) begin : g_rw1
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'hffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1f0),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[20]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [15:0] INITIAL_VALUE = 16'h0000;
        rggen_bit_field_if #(16) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 16)
        rggen_bit_field #(
          .WIDTH          (16),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_test_rw1_val),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ro1
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'hffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1f2),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[21]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [15:0] INITIAL_VALUE = 16'hffff;
        rggen_bit_field_if #(16) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 16)
        rggen_bit_field #(
          .WIDTH              (16),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ro2
      rggen_bit_field_if #(16) bit_field_if();
      `rggen_tie_off_unused_signals(16, 16'hffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1f4),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (16),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[22]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [15:0] INITIAL_VALUE = 16'h0000;
        rggen_bit_field_if #(16) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 16)
        rggen_bit_field #(
          .WIDTH              (16),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ro3
      rggen_bit_field_if #(32) bit_field_if();
      `rggen_tie_off_unused_signals(32, 32'hffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1f6),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[23]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [31:0] INITIAL_VALUE = 32'haaaaaa55;
        rggen_bit_field_if #(32) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
    if (1) begin : g_ro4
      rggen_bit_field_if #(32) bit_field_if();
      `rggen_tie_off_unused_signals(32, 32'hffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (0),
        .ADDRESS_WIDTH  (9),
        .OFFSET_ADDRESS (9'h1fa),
        .BUS_WIDTH      (16),
        .DATA_WIDTH     (32),
        .VALUE_WIDTH    (32)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[24]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_val
        localparam bit [31:0] INITIAL_VALUE = 32'h55aa5555;
        rggen_bit_field_if #(32) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
        rggen_bit_field #(
          .WIDTH              (32),
          .STORAGE            (0),
          .EXTERNAL_READ_DATA (1)
        ) u_bit_field (
          .i_clk              ('0),
          .i_rst_n            ('0),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('0),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            (INITIAL_VALUE),
          .i_mask             ('1),
          .o_value            (),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
endmodule
