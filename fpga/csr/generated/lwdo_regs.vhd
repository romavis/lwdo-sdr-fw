library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.rggen_rtl.all;

entity lwdo_regs is
  generic (
    ADDRESS_WIDTH: positive := 9;
    PRE_DECODE: boolean := false;
    BASE_ADDRESS: unsigned := x"0";
    ERROR_STATUS: boolean := false;
    INSERT_SLICER: boolean := false;
    USE_STALL: boolean := true;
    SYS_PLL_DIVR_INITIAL_VALUE: unsigned(3 downto 0) := repeat(x"0", 4, 1);
    SYS_PLL_DIVF_INITIAL_VALUE: unsigned(6 downto 0) := repeat(x"00", 7, 1);
    SYS_PLL_DIVQ_INITIAL_VALUE: unsigned(2 downto 0) := repeat(x"0", 3, 1);
    PDET_N1_VAL_INITIAL_VALUE: unsigned(31 downto 0) := repeat(x"00000000", 32, 1);
    PDET_N2_VAL_INITIAL_VALUE: unsigned(31 downto 0) := repeat(x"00000000", 32, 1)
  );
  port (
    i_clk: in std_logic;
    i_rst_n: in std_logic;
    i_wb_cyc: in std_logic;
    i_wb_stb: in std_logic;
    o_wb_stall: out std_logic;
    i_wb_adr: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    i_wb_we: in std_logic;
    i_wb_dat: in std_logic_vector(15 downto 0);
    i_wb_sel: in std_logic_vector(1 downto 0);
    o_wb_ack: out std_logic;
    o_wb_err: out std_logic;
    o_wb_rty: out std_logic;
    o_wb_dat: out std_logic_vector(15 downto 0);
    o_sys_con_sys_rst: out std_logic_vector(0 downto 0);
    o_pdet_con_en: out std_logic_vector(0 downto 0);
    o_pdet_con_eclk2_slow: out std_logic_vector(0 downto 0);
    o_adct_con_srate1_en: out std_logic_vector(0 downto 0);
    o_adct_con_srate2_en: out std_logic_vector(0 downto 0);
    o_adct_con_puls1_en: out std_logic_vector(0 downto 0);
    o_adct_con_puls2_en: out std_logic_vector(0 downto 0);
    o_adct_srate1_psc_div_val: out std_logic_vector(7 downto 0);
    o_adct_srate2_psc_div_val: out std_logic_vector(7 downto 0);
    o_adct_puls1_psc_div_val: out std_logic_vector(22 downto 0);
    o_adct_puls2_psc_div_val: out std_logic_vector(22 downto 0);
    o_adct_puls1_dly_val: out std_logic_vector(8 downto 0);
    o_adct_puls2_dly_val: out std_logic_vector(8 downto 0);
    o_adct_puls1_pwidth_val: out std_logic_vector(15 downto 0);
    o_adct_puls2_pwidth_val: out std_logic_vector(15 downto 0);
    o_adc_con_adc1_en: out std_logic_vector(0 downto 0);
    o_adc_con_adc2_en: out std_logic_vector(0 downto 0);
    i_adc_fifo1_sts_empty: in std_logic_vector(0 downto 0);
    i_adc_fifo1_sts_full: in std_logic_vector(0 downto 0);
    i_adc_fifo1_sts_hfull: in std_logic_vector(0 downto 0);
    i_adc_fifo1_sts_ovfl: in std_logic_vector(0 downto 0);
    o_adc_fifo1_sts_ovfl_read_trigger: out std_logic_vector(0 downto 0);
    i_adc_fifo1_sts_udfl: in std_logic_vector(0 downto 0);
    o_adc_fifo1_sts_udfl_read_trigger: out std_logic_vector(0 downto 0);
    i_adc_fifo2_sts_empty: in std_logic_vector(0 downto 0);
    i_adc_fifo2_sts_full: in std_logic_vector(0 downto 0);
    i_adc_fifo2_sts_hfull: in std_logic_vector(0 downto 0);
    i_adc_fifo2_sts_ovfl: in std_logic_vector(0 downto 0);
    o_adc_fifo2_sts_ovfl_read_trigger: out std_logic_vector(0 downto 0);
    i_adc_fifo2_sts_udfl: in std_logic_vector(0 downto 0);
    o_adc_fifo2_sts_udfl_read_trigger: out std_logic_vector(0 downto 0);
    o_ftun_vtune_set_val: out std_logic_vector(15 downto 0);
    o_ftun_vtune_set_val_write_trigger: out std_logic_vector(0 downto 0);
    o_ftun_vtune_set_val_read_trigger: out std_logic_vector(0 downto 0);
    o_test_rw1_val: out std_logic_vector(15 downto 0)
  );
end lwdo_regs;

architecture rtl of lwdo_regs is
  signal register_valid: std_logic;
  signal register_access: std_logic_vector(1 downto 0);
  signal register_address: std_logic_vector(8 downto 0);
  signal register_write_data: std_logic_vector(15 downto 0);
  signal register_strobe: std_logic_vector(15 downto 0);
  signal register_active: std_logic_vector(24 downto 0);
  signal register_ready: std_logic_vector(24 downto 0);
  signal register_status: std_logic_vector(49 downto 0);
  signal register_read_data: std_logic_vector(399 downto 0);
  signal register_value: std_logic_vector(799 downto 0);
begin
  u_adapter: entity work.rggen_wishbone_adapter
    generic map (
      ADDRESS_WIDTH       => ADDRESS_WIDTH,
      LOCAL_ADDRESS_WIDTH => 9,
      BUS_WIDTH           => 16,
      REGISTERS           => 25,
      PRE_DECODE          => PRE_DECODE,
      BASE_ADDRESS        => BASE_ADDRESS,
      BYTE_SIZE           => 512,
      ERROR_STATUS        => ERROR_STATUS,
      INSERT_SLICER       => INSERT_SLICER,
      USE_STALL           => USE_STALL
    )
    port map (
      i_clk                 => i_clk,
      i_rst_n               => i_rst_n,
      i_wb_cyc              => i_wb_cyc,
      i_wb_stb              => i_wb_stb,
      o_wb_stall            => o_wb_stall,
      i_wb_adr              => i_wb_adr,
      i_wb_we               => i_wb_we,
      i_wb_dat              => i_wb_dat,
      i_wb_sel              => i_wb_sel,
      o_wb_ack              => o_wb_ack,
      o_wb_err              => o_wb_err,
      o_wb_rty              => o_wb_rty,
      o_wb_dat              => o_wb_dat,
      o_register_valid      => register_valid,
      o_register_access     => register_access,
      o_register_address    => register_address,
      o_register_write_data => register_write_data,
      o_register_strobe     => register_strobe,
      i_register_active     => register_active,
      i_register_ready      => register_ready,
      i_register_status     => register_status,
      i_register_read_data  => register_read_data
    );
  g_sys: block
  begin
    g_magic: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_data: std_logic_vector(31 downto 0);
      signal bit_field_read_data: std_logic_vector(31 downto 0);
      signal bit_field_value: std_logic_vector(31 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 31 generate
        g: if (bit_slice(x"ffffffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"000",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 32
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(0),
          o_register_ready        => register_ready(0),
          o_register_status       => register_status(1 downto 0),
          o_register_read_data    => register_read_data(15 downto 0),
          o_register_value        => register_value(31 downto 0),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_magic: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 32,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(31 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(31 downto 0),
            i_sw_write_data   => bit_field_write_data(31 downto 0),
            o_sw_read_data    => bit_field_read_data(31 downto 0),
            o_sw_value        => bit_field_value(31 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(x"4544574c", 32, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_version: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_data: std_logic_vector(31 downto 0);
      signal bit_field_read_data: std_logic_vector(31 downto 0);
      signal bit_field_value: std_logic_vector(31 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 31 generate
        g: if (bit_slice(x"ffffffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"004",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 32
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(1),
          o_register_ready        => register_ready(1),
          o_register_status       => register_status(3 downto 2),
          o_register_read_data    => register_read_data(31 downto 16),
          o_register_value        => register_value(63 downto 32),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_major: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 16,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(15 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(15 downto 0),
            i_sw_write_data   => bit_field_write_data(15 downto 0),
            o_sw_read_data    => bit_field_read_data(15 downto 0),
            o_sw_value        => bit_field_value(15 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(x"0001", 16, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_minor: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 16,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(31 downto 16),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(31 downto 16),
            i_sw_write_data   => bit_field_write_data(31 downto 16),
            o_sw_read_data    => bit_field_read_data(31 downto 16),
            o_sw_value        => bit_field_value(31 downto 16),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(x"0001", 16, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_con: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"0001", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"008",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(2),
          o_register_ready        => register_ready(2),
          o_register_status       => register_status(5 downto 4),
          o_register_read_data    => register_read_data(47 downto 32),
          o_register_value        => register_value(79 downto 64),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_sys_rst: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => true,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(0 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(0 downto 0),
            i_sw_write_data   => bit_field_write_data(0 downto 0),
            o_sw_read_data    => bit_field_read_data(0 downto 0),
            o_sw_value        => bit_field_value(0 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_sys_con_sys_rst,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_pll: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"3fff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"00a",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(3),
          o_register_ready        => register_ready(3),
          o_register_status       => register_status(7 downto 6),
          o_register_read_data    => register_read_data(63 downto 48),
          o_register_value        => register_value(111 downto 96),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_divr: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 4,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(3 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(3 downto 0),
            i_sw_write_data   => bit_field_write_data(3 downto 0),
            o_sw_read_data    => bit_field_read_data(3 downto 0),
            o_sw_value        => bit_field_value(3 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(SYS_PLL_DIVR_INITIAL_VALUE, 4, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_divf: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 7,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(10 downto 4),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(10 downto 4),
            i_sw_write_data   => bit_field_write_data(10 downto 4),
            o_sw_read_data    => bit_field_read_data(10 downto 4),
            o_sw_value        => bit_field_value(10 downto 4),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(SYS_PLL_DIVF_INITIAL_VALUE, 7, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_divq: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 3,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(13 downto 11),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(13 downto 11),
            i_sw_write_data   => bit_field_write_data(13 downto 11),
            o_sw_read_data    => bit_field_read_data(13 downto 11),
            o_sw_value        => bit_field_value(13 downto 11),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(SYS_PLL_DIVQ_INITIAL_VALUE, 3, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
  end block;
  g_pdet: block
  begin
    g_con: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"0003", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"020",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(4),
          o_register_ready        => register_ready(4),
          o_register_status       => register_status(9 downto 8),
          o_register_read_data    => register_read_data(79 downto 64),
          o_register_value        => register_value(143 downto 128),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_en: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(0 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(0 downto 0),
            i_sw_write_data   => bit_field_write_data(0 downto 0),
            o_sw_read_data    => bit_field_read_data(0 downto 0),
            o_sw_value        => bit_field_value(0 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_pdet_con_en,
            o_value_unmasked  => open
          );
      end block;
      g_eclk2_slow: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(1 downto 1),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(1 downto 1),
            i_sw_write_data   => bit_field_write_data(1 downto 1),
            o_sw_read_data    => bit_field_read_data(1 downto 1),
            o_sw_value        => bit_field_value(1 downto 1),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_pdet_con_eclk2_slow,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_n1: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_data: std_logic_vector(31 downto 0);
      signal bit_field_read_data: std_logic_vector(31 downto 0);
      signal bit_field_value: std_logic_vector(31 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 31 generate
        g: if (bit_slice(x"ffffffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"022",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 32
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(5),
          o_register_ready        => register_ready(5),
          o_register_status       => register_status(11 downto 10),
          o_register_read_data    => register_read_data(95 downto 80),
          o_register_value        => register_value(191 downto 160),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 32,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(31 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(31 downto 0),
            i_sw_write_data   => bit_field_write_data(31 downto 0),
            o_sw_read_data    => bit_field_read_data(31 downto 0),
            o_sw_value        => bit_field_value(31 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(PDET_N1_VAL_INITIAL_VALUE, 32, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_n2: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_data: std_logic_vector(31 downto 0);
      signal bit_field_read_data: std_logic_vector(31 downto 0);
      signal bit_field_value: std_logic_vector(31 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 31 generate
        g: if (bit_slice(x"ffffffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"026",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 32
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(6),
          o_register_ready        => register_ready(6),
          o_register_status       => register_status(13 downto 12),
          o_register_read_data    => register_read_data(111 downto 96),
          o_register_value        => register_value(223 downto 192),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 32,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(31 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(31 downto 0),
            i_sw_write_data   => bit_field_write_data(31 downto 0),
            o_sw_read_data    => bit_field_read_data(31 downto 0),
            o_sw_value        => bit_field_value(31 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(PDET_N2_VAL_INITIAL_VALUE, 32, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
  end block;
  g_adct: block
  begin
    g_con: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"000f", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"040",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(7),
          o_register_ready        => register_ready(7),
          o_register_status       => register_status(15 downto 14),
          o_register_read_data    => register_read_data(127 downto 112),
          o_register_value        => register_value(239 downto 224),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_srate1_en: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(0 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(0 downto 0),
            i_sw_write_data   => bit_field_write_data(0 downto 0),
            o_sw_read_data    => bit_field_read_data(0 downto 0),
            o_sw_value        => bit_field_value(0 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_con_srate1_en,
            o_value_unmasked  => open
          );
      end block;
      g_srate2_en: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(1 downto 1),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(1 downto 1),
            i_sw_write_data   => bit_field_write_data(1 downto 1),
            o_sw_read_data    => bit_field_read_data(1 downto 1),
            o_sw_value        => bit_field_value(1 downto 1),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_con_srate2_en,
            o_value_unmasked  => open
          );
      end block;
      g_puls1_en: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(2 downto 2),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(2 downto 2),
            i_sw_write_data   => bit_field_write_data(2 downto 2),
            o_sw_read_data    => bit_field_read_data(2 downto 2),
            o_sw_value        => bit_field_value(2 downto 2),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_con_puls1_en,
            o_value_unmasked  => open
          );
      end block;
      g_puls2_en: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(3 downto 3),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(3 downto 3),
            i_sw_write_data   => bit_field_write_data(3 downto 3),
            o_sw_read_data    => bit_field_read_data(3 downto 3),
            o_sw_value        => bit_field_value(3 downto 3),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_con_puls2_en,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_srate1_psc_div: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"00ff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"042",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(8),
          o_register_ready        => register_ready(8),
          o_register_status       => register_status(17 downto 16),
          o_register_read_data    => register_read_data(143 downto 128),
          o_register_value        => register_value(271 downto 256),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 8,
            INITIAL_VALUE   => slice(x"c7", 8, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(7 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(7 downto 0),
            i_sw_write_data   => bit_field_write_data(7 downto 0),
            o_sw_read_data    => bit_field_read_data(7 downto 0),
            o_sw_value        => bit_field_value(7 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_srate1_psc_div_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_srate2_psc_div: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"00ff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"044",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(9),
          o_register_ready        => register_ready(9),
          o_register_status       => register_status(19 downto 18),
          o_register_read_data    => register_read_data(159 downto 144),
          o_register_value        => register_value(303 downto 288),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 8,
            INITIAL_VALUE   => slice(x"c7", 8, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(7 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(7 downto 0),
            i_sw_write_data   => bit_field_write_data(7 downto 0),
            o_sw_read_data    => bit_field_read_data(7 downto 0),
            o_sw_value        => bit_field_value(7 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_srate2_psc_div_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_puls1_psc_div: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_data: std_logic_vector(31 downto 0);
      signal bit_field_read_data: std_logic_vector(31 downto 0);
      signal bit_field_value: std_logic_vector(31 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 31 generate
        g: if (bit_slice(x"007fffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"046",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 32
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(10),
          o_register_ready        => register_ready(10),
          o_register_status       => register_status(21 downto 20),
          o_register_read_data    => register_read_data(175 downto 160),
          o_register_value        => register_value(351 downto 320),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 23,
            INITIAL_VALUE   => slice(x"000000", 23, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(22 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(22 downto 0),
            i_sw_write_data   => bit_field_write_data(22 downto 0),
            o_sw_read_data    => bit_field_read_data(22 downto 0),
            o_sw_value        => bit_field_value(22 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_puls1_psc_div_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_puls2_psc_div: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_data: std_logic_vector(31 downto 0);
      signal bit_field_read_data: std_logic_vector(31 downto 0);
      signal bit_field_value: std_logic_vector(31 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 31 generate
        g: if (bit_slice(x"007fffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"04a",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 32
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(11),
          o_register_ready        => register_ready(11),
          o_register_status       => register_status(23 downto 22),
          o_register_read_data    => register_read_data(191 downto 176),
          o_register_value        => register_value(383 downto 352),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 23,
            INITIAL_VALUE   => slice(x"000000", 23, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(22 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(22 downto 0),
            i_sw_write_data   => bit_field_write_data(22 downto 0),
            o_sw_read_data    => bit_field_read_data(22 downto 0),
            o_sw_value        => bit_field_value(22 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_puls2_psc_div_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_puls1_dly: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"01ff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"04e",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(12),
          o_register_ready        => register_ready(12),
          o_register_status       => register_status(25 downto 24),
          o_register_read_data    => register_read_data(207 downto 192),
          o_register_value        => register_value(399 downto 384),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 9,
            INITIAL_VALUE   => slice(x"000", 9, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(8 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(8 downto 0),
            i_sw_write_data   => bit_field_write_data(8 downto 0),
            o_sw_read_data    => bit_field_read_data(8 downto 0),
            o_sw_value        => bit_field_value(8 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_puls1_dly_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_puls2_dly: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"01ff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"050",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(13),
          o_register_ready        => register_ready(13),
          o_register_status       => register_status(27 downto 26),
          o_register_read_data    => register_read_data(223 downto 208),
          o_register_value        => register_value(431 downto 416),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 9,
            INITIAL_VALUE   => slice(x"000", 9, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(8 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(8 downto 0),
            i_sw_write_data   => bit_field_write_data(8 downto 0),
            o_sw_read_data    => bit_field_read_data(8 downto 0),
            o_sw_value        => bit_field_value(8 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_puls2_dly_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_puls1_pwidth: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"ffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"052",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(14),
          o_register_ready        => register_ready(14),
          o_register_status       => register_status(29 downto 28),
          o_register_read_data    => register_read_data(239 downto 224),
          o_register_value        => register_value(463 downto 448),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 16,
            INITIAL_VALUE   => slice(x"0001", 16, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(15 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(15 downto 0),
            i_sw_write_data   => bit_field_write_data(15 downto 0),
            o_sw_read_data    => bit_field_read_data(15 downto 0),
            o_sw_value        => bit_field_value(15 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_puls1_pwidth_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_puls2_pwidth: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"ffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"054",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(15),
          o_register_ready        => register_ready(15),
          o_register_status       => register_status(31 downto 30),
          o_register_read_data    => register_read_data(255 downto 240),
          o_register_value        => register_value(495 downto 480),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 16,
            INITIAL_VALUE   => slice(x"0001", 16, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(15 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(15 downto 0),
            i_sw_write_data   => bit_field_write_data(15 downto 0),
            o_sw_read_data    => bit_field_read_data(15 downto 0),
            o_sw_value        => bit_field_value(15 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adct_puls2_pwidth_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
  end block;
  g_adc: block
  begin
    g_con: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"0003", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"080",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(16),
          o_register_ready        => register_ready(16),
          o_register_status       => register_status(33 downto 32),
          o_register_read_data    => register_read_data(271 downto 256),
          o_register_value        => register_value(527 downto 512),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_adc1_en: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(0 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(0 downto 0),
            i_sw_write_data   => bit_field_write_data(0 downto 0),
            o_sw_read_data    => bit_field_read_data(0 downto 0),
            o_sw_value        => bit_field_value(0 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adc_con_adc1_en,
            o_value_unmasked  => open
          );
      end block;
      g_adc2_en: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 1,
            INITIAL_VALUE   => slice(x"0", 1, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(1 downto 1),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(1 downto 1),
            i_sw_write_data   => bit_field_write_data(1 downto 1),
            o_sw_read_data    => bit_field_read_data(1 downto 1),
            o_sw_value        => bit_field_value(1 downto 1),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_adc_con_adc2_en,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_fifo1_sts: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"001f", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"082",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(17),
          o_register_ready        => register_ready(17),
          o_register_status       => register_status(35 downto 34),
          o_register_read_data    => register_read_data(287 downto 272),
          o_register_value        => register_value(559 downto 544),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_empty: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(0 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(0 downto 0),
            i_sw_write_data   => bit_field_write_data(0 downto 0),
            o_sw_read_data    => bit_field_read_data(0 downto 0),
            o_sw_value        => bit_field_value(0 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo1_sts_empty,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_full: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(1 downto 1),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(1 downto 1),
            i_sw_write_data   => bit_field_write_data(1 downto 1),
            o_sw_read_data    => bit_field_read_data(1 downto 1),
            o_sw_value        => bit_field_value(1 downto 1),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo1_sts_full,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_hfull: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(2 downto 2),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(2 downto 2),
            i_sw_write_data   => bit_field_write_data(2 downto 2),
            o_sw_read_data    => bit_field_read_data(2 downto 2),
            o_sw_value        => bit_field_value(2 downto 2),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo1_sts_hfull,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_ovfl: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => true
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(3 downto 3),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(3 downto 3),
            i_sw_write_data   => bit_field_write_data(3 downto 3),
            o_sw_read_data    => bit_field_read_data(3 downto 3),
            o_sw_value        => bit_field_value(3 downto 3),
            o_write_trigger   => open,
            o_read_trigger    => o_adc_fifo1_sts_ovfl_read_trigger,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo1_sts_ovfl,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_udfl: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => true
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(4 downto 4),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(4 downto 4),
            i_sw_write_data   => bit_field_write_data(4 downto 4),
            o_sw_read_data    => bit_field_read_data(4 downto 4),
            o_sw_value        => bit_field_value(4 downto 4),
            o_write_trigger   => open,
            o_read_trigger    => o_adc_fifo1_sts_udfl_read_trigger,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo1_sts_udfl,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_fifo2_sts: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"001f", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"084",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(18),
          o_register_ready        => register_ready(18),
          o_register_status       => register_status(37 downto 36),
          o_register_read_data    => register_read_data(303 downto 288),
          o_register_value        => register_value(591 downto 576),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_empty: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(0 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(0 downto 0),
            i_sw_write_data   => bit_field_write_data(0 downto 0),
            o_sw_read_data    => bit_field_read_data(0 downto 0),
            o_sw_value        => bit_field_value(0 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo2_sts_empty,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_full: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(1 downto 1),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(1 downto 1),
            i_sw_write_data   => bit_field_write_data(1 downto 1),
            o_sw_read_data    => bit_field_read_data(1 downto 1),
            o_sw_value        => bit_field_value(1 downto 1),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo2_sts_full,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_hfull: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(2 downto 2),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(2 downto 2),
            i_sw_write_data   => bit_field_write_data(2 downto 2),
            o_sw_read_data    => bit_field_read_data(2 downto 2),
            o_sw_value        => bit_field_value(2 downto 2),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo2_sts_hfull,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_ovfl: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => true
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(3 downto 3),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(3 downto 3),
            i_sw_write_data   => bit_field_write_data(3 downto 3),
            o_sw_read_data    => bit_field_read_data(3 downto 3),
            o_sw_value        => bit_field_value(3 downto 3),
            o_write_trigger   => open,
            o_read_trigger    => o_adc_fifo2_sts_ovfl_read_trigger,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo2_sts_ovfl,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
      g_udfl: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 1,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true,
            TRIGGER             => true
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(4 downto 4),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(4 downto 4),
            i_sw_write_data   => bit_field_write_data(4 downto 4),
            o_sw_read_data    => bit_field_read_data(4 downto 4),
            o_sw_value        => bit_field_value(4 downto 4),
            o_write_trigger   => open,
            o_read_trigger    => o_adc_fifo2_sts_udfl_read_trigger,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => i_adc_fifo2_sts_udfl,
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
  end block;
  g_ftun: block
  begin
    g_vtune_set: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"ffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"0a0",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(19),
          o_register_ready        => register_ready(19),
          o_register_status       => register_status(39 downto 38),
          o_register_read_data    => register_read_data(319 downto 304),
          o_register_value        => register_value(623 downto 608),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 16,
            INITIAL_VALUE   => slice(x"8000", 16, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => true
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(15 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(15 downto 0),
            i_sw_write_data   => bit_field_write_data(15 downto 0),
            o_sw_read_data    => bit_field_read_data(15 downto 0),
            o_sw_value        => bit_field_value(15 downto 0),
            o_write_trigger   => o_ftun_vtune_set_val_write_trigger,
            o_read_trigger    => o_ftun_vtune_set_val_read_trigger,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_ftun_vtune_set_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
  end block;
  g_test: block
  begin
    g_rw1: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"ffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => true,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"1f0",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(20),
          o_register_ready        => register_ready(20),
          o_register_status       => register_status(41 downto 40),
          o_register_read_data    => register_read_data(335 downto 320),
          o_register_value        => register_value(655 downto 640),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH           => 16,
            INITIAL_VALUE   => slice(x"0000", 16, 0),
            SW_WRITE_ONCE   => false,
            TRIGGER         => false
          )
          port map (
            i_clk             => i_clk,
            i_rst_n           => i_rst_n,
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(15 downto 0),
            i_sw_write_enable => "1",
            i_sw_write_mask   => bit_field_write_mask(15 downto 0),
            i_sw_write_data   => bit_field_write_data(15 downto 0),
            o_sw_read_data    => bit_field_read_data(15 downto 0),
            o_sw_value        => bit_field_value(15 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => (others => '0'),
            i_mask            => (others => '1'),
            o_value           => o_test_rw1_val,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_ro1: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"ffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"1f2",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(21),
          o_register_ready        => register_ready(21),
          o_register_status       => register_status(43 downto 42),
          o_register_read_data    => register_read_data(351 downto 336),
          o_register_value        => register_value(687 downto 672),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 16,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(15 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(15 downto 0),
            i_sw_write_data   => bit_field_write_data(15 downto 0),
            o_sw_read_data    => bit_field_read_data(15 downto 0),
            o_sw_value        => bit_field_value(15 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(x"ffff", 16, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_ro2: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_mask: std_logic_vector(15 downto 0);
      signal bit_field_write_data: std_logic_vector(15 downto 0);
      signal bit_field_read_data: std_logic_vector(15 downto 0);
      signal bit_field_value: std_logic_vector(15 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 15 generate
        g: if (bit_slice(x"ffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"1f4",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 16
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(22),
          o_register_ready        => register_ready(22),
          o_register_status       => register_status(45 downto 44),
          o_register_read_data    => register_read_data(367 downto 352),
          o_register_value        => register_value(719 downto 704),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 16,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(15 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(15 downto 0),
            i_sw_write_data   => bit_field_write_data(15 downto 0),
            o_sw_read_data    => bit_field_read_data(15 downto 0),
            o_sw_value        => bit_field_value(15 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(x"0000", 16, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_ro3: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_data: std_logic_vector(31 downto 0);
      signal bit_field_read_data: std_logic_vector(31 downto 0);
      signal bit_field_value: std_logic_vector(31 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 31 generate
        g: if (bit_slice(x"ffffffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"1f6",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 32
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(23),
          o_register_ready        => register_ready(23),
          o_register_status       => register_status(47 downto 46),
          o_register_read_data    => register_read_data(383 downto 368),
          o_register_value        => register_value(767 downto 736),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 32,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(31 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(31 downto 0),
            i_sw_write_data   => bit_field_write_data(31 downto 0),
            o_sw_read_data    => bit_field_read_data(31 downto 0),
            o_sw_value        => bit_field_value(31 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(x"aaaaaa55", 32, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
    g_ro4: block
      signal bit_field_valid: std_logic;
      signal bit_field_read_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_mask: std_logic_vector(31 downto 0);
      signal bit_field_write_data: std_logic_vector(31 downto 0);
      signal bit_field_read_data: std_logic_vector(31 downto 0);
      signal bit_field_value: std_logic_vector(31 downto 0);
    begin
      \g_tie_off\: for \__i\ in 0 to 31 generate
        g: if (bit_slice(x"ffffffff", \__i\) = '0') generate
          bit_field_read_data(\__i\) <= '0';
          bit_field_value(\__i\) <= '0';
        end generate;
      end generate;
      u_register: entity work.rggen_default_register
        generic map (
          READABLE        => true,
          WRITABLE        => false,
          ADDRESS_WIDTH   => 9,
          OFFSET_ADDRESS  => x"1fa",
          BUS_WIDTH       => 16,
          DATA_WIDTH      => 32
        )
        port map (
          i_clk                   => i_clk,
          i_rst_n                 => i_rst_n,
          i_register_valid        => register_valid,
          i_register_access       => register_access,
          i_register_address      => register_address,
          i_register_write_data   => register_write_data,
          i_register_strobe       => register_strobe,
          o_register_active       => register_active(24),
          o_register_ready        => register_ready(24),
          o_register_status       => register_status(49 downto 48),
          o_register_read_data    => register_read_data(399 downto 384),
          o_register_value        => register_value(799 downto 768),
          o_bit_field_valid       => bit_field_valid,
          o_bit_field_read_mask   => bit_field_read_mask,
          o_bit_field_write_mask  => bit_field_write_mask,
          o_bit_field_write_data  => bit_field_write_data,
          i_bit_field_read_data   => bit_field_read_data,
          i_bit_field_value       => bit_field_value
        );
      g_val: block
      begin
        u_bit_field: entity work.rggen_bit_field
          generic map (
            WIDTH               => 32,
            STORAGE             => false,
            EXTERNAL_READ_DATA  => true
          )
          port map (
            i_clk             => '0',
            i_rst_n           => '0',
            i_sw_valid        => bit_field_valid,
            i_sw_read_mask    => bit_field_read_mask(31 downto 0),
            i_sw_write_enable => "0",
            i_sw_write_mask   => bit_field_write_mask(31 downto 0),
            i_sw_write_data   => bit_field_write_data(31 downto 0),
            o_sw_read_data    => bit_field_read_data(31 downto 0),
            o_sw_value        => bit_field_value(31 downto 0),
            o_write_trigger   => open,
            o_read_trigger    => open,
            i_hw_write_enable => "0",
            i_hw_write_data   => (others => '0'),
            i_hw_set          => (others => '0'),
            i_hw_clear        => (others => '0'),
            i_value           => slice(x"55aa5555", 32, 0),
            i_mask            => (others => '1'),
            o_value           => open,
            o_value_unmasked  => open
          );
      end block;
    end block;
  end block;
end rtl;
