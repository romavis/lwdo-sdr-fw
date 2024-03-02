#ifndef LWDO_REGS_H
#define LWDO_REGS_H
#include "stdint.h"
#define LWDO_REGS_SYS_MAGIC_BIT_WIDTH 32
#define LWDO_REGS_SYS_MAGIC_BIT_MASK 0xffffffff
#define LWDO_REGS_SYS_MAGIC_BIT_OFFSET 0
#define LWDO_REGS_SYS_MAGIC_BYTE_WIDTH 4
#define LWDO_REGS_SYS_MAGIC_BYTE_SIZE 4
#define LWDO_REGS_SYS_MAGIC_BYTE_OFFSET 0x0
#define LWDO_REGS_SYS_VERSION_MAJOR_BIT_WIDTH 16
#define LWDO_REGS_SYS_VERSION_MAJOR_BIT_MASK 0xffff
#define LWDO_REGS_SYS_VERSION_MAJOR_BIT_OFFSET 0
#define LWDO_REGS_SYS_VERSION_MINOR_BIT_WIDTH 16
#define LWDO_REGS_SYS_VERSION_MINOR_BIT_MASK 0xffff
#define LWDO_REGS_SYS_VERSION_MINOR_BIT_OFFSET 16
#define LWDO_REGS_SYS_VERSION_BYTE_WIDTH 4
#define LWDO_REGS_SYS_VERSION_BYTE_SIZE 4
#define LWDO_REGS_SYS_VERSION_BYTE_OFFSET 0x4
#define LWDO_REGS_SYS_CON_SYS_RST_BIT_WIDTH 1
#define LWDO_REGS_SYS_CON_SYS_RST_BIT_MASK 0x1
#define LWDO_REGS_SYS_CON_SYS_RST_BIT_OFFSET 0
#define LWDO_REGS_SYS_CON_BYTE_WIDTH 4
#define LWDO_REGS_SYS_CON_BYTE_SIZE 4
#define LWDO_REGS_SYS_CON_BYTE_OFFSET 0x8
#define LWDO_REGS_SYS_PLL_DIVR_BIT_WIDTH 4
#define LWDO_REGS_SYS_PLL_DIVR_BIT_MASK 0xf
#define LWDO_REGS_SYS_PLL_DIVR_BIT_OFFSET 0
#define LWDO_REGS_SYS_PLL_DIVF_BIT_WIDTH 7
#define LWDO_REGS_SYS_PLL_DIVF_BIT_MASK 0x7f
#define LWDO_REGS_SYS_PLL_DIVF_BIT_OFFSET 4
#define LWDO_REGS_SYS_PLL_DIVQ_BIT_WIDTH 3
#define LWDO_REGS_SYS_PLL_DIVQ_BIT_MASK 0x7
#define LWDO_REGS_SYS_PLL_DIVQ_BIT_OFFSET 11
#define LWDO_REGS_SYS_PLL_BYTE_WIDTH 4
#define LWDO_REGS_SYS_PLL_BYTE_SIZE 4
#define LWDO_REGS_SYS_PLL_BYTE_OFFSET 0xc
#define LWDO_REGS_HWTIME_CNT_BIT_WIDTH 32
#define LWDO_REGS_HWTIME_CNT_BIT_MASK 0xffffffff
#define LWDO_REGS_HWTIME_CNT_BIT_OFFSET 0
#define LWDO_REGS_HWTIME_CNT_BYTE_WIDTH 4
#define LWDO_REGS_HWTIME_CNT_BYTE_SIZE 4
#define LWDO_REGS_HWTIME_CNT_BYTE_OFFSET 0x20
#define LWDO_REGS_TDC_CON_EN_BIT_WIDTH 1
#define LWDO_REGS_TDC_CON_EN_BIT_MASK 0x1
#define LWDO_REGS_TDC_CON_EN_BIT_OFFSET 0
#define LWDO_REGS_TDC_CON_MEAS_DIV_EN_BIT_WIDTH 1
#define LWDO_REGS_TDC_CON_MEAS_DIV_EN_BIT_MASK 0x1
#define LWDO_REGS_TDC_CON_MEAS_DIV_EN_BIT_OFFSET 1
#define LWDO_REGS_TDC_CON_GATE_FDEC_BIT_WIDTH 1
#define LWDO_REGS_TDC_CON_GATE_FDEC_BIT_MASK 0x1
#define LWDO_REGS_TDC_CON_GATE_FDEC_BIT_OFFSET 2
#define LWDO_REGS_TDC_CON_GATE_FINC_BIT_WIDTH 1
#define LWDO_REGS_TDC_CON_GATE_FINC_BIT_MASK 0x1
#define LWDO_REGS_TDC_CON_GATE_FINC_BIT_OFFSET 3
#define LWDO_REGS_TDC_CON_BYTE_WIDTH 4
#define LWDO_REGS_TDC_CON_BYTE_SIZE 4
#define LWDO_REGS_TDC_CON_BYTE_OFFSET 0x40
#define LWDO_REGS_TDC_PLL_DIVR_BIT_WIDTH 4
#define LWDO_REGS_TDC_PLL_DIVR_BIT_MASK 0xf
#define LWDO_REGS_TDC_PLL_DIVR_BIT_OFFSET 0
#define LWDO_REGS_TDC_PLL_DIVF_BIT_WIDTH 7
#define LWDO_REGS_TDC_PLL_DIVF_BIT_MASK 0x7f
#define LWDO_REGS_TDC_PLL_DIVF_BIT_OFFSET 4
#define LWDO_REGS_TDC_PLL_DIVQ_BIT_WIDTH 3
#define LWDO_REGS_TDC_PLL_DIVQ_BIT_MASK 0x7
#define LWDO_REGS_TDC_PLL_DIVQ_BIT_OFFSET 11
#define LWDO_REGS_TDC_PLL_SS_DIVFSPAN_BIT_WIDTH 7
#define LWDO_REGS_TDC_PLL_SS_DIVFSPAN_BIT_MASK 0x7f
#define LWDO_REGS_TDC_PLL_SS_DIVFSPAN_BIT_OFFSET 14
#define LWDO_REGS_TDC_PLL_BYTE_WIDTH 4
#define LWDO_REGS_TDC_PLL_BYTE_SIZE 4
#define LWDO_REGS_TDC_PLL_BYTE_OFFSET 0x44
#define LWDO_REGS_TDC_DIV_GATE_BIT_WIDTH 32
#define LWDO_REGS_TDC_DIV_GATE_BIT_MASK 0xffffffff
#define LWDO_REGS_TDC_DIV_GATE_BIT_OFFSET 0
#define LWDO_REGS_TDC_DIV_GATE_BYTE_WIDTH 4
#define LWDO_REGS_TDC_DIV_GATE_BYTE_SIZE 4
#define LWDO_REGS_TDC_DIV_GATE_BYTE_OFFSET 0x48
#define LWDO_REGS_TDC_DIV_MEAS_BIT_WIDTH 32
#define LWDO_REGS_TDC_DIV_MEAS_BIT_MASK 0xffffffff
#define LWDO_REGS_TDC_DIV_MEAS_BIT_OFFSET 0
#define LWDO_REGS_TDC_DIV_MEAS_BYTE_WIDTH 4
#define LWDO_REGS_TDC_DIV_MEAS_BYTE_SIZE 4
#define LWDO_REGS_TDC_DIV_MEAS_BYTE_OFFSET 0x4c
#define LWDO_REGS_ADC_CON_ADC_EN_BIT_WIDTH 4
#define LWDO_REGS_ADC_CON_ADC_EN_BIT_MASK 0xf
#define LWDO_REGS_ADC_CON_ADC_EN_BIT_OFFSET 0
#define LWDO_REGS_ADC_CON_BYTE_WIDTH 4
#define LWDO_REGS_ADC_CON_BYTE_SIZE 4
#define LWDO_REGS_ADC_CON_BYTE_OFFSET 0x60
#define LWDO_REGS_ADC_SAMPLE_RATE_DIV_BIT_WIDTH 24
#define LWDO_REGS_ADC_SAMPLE_RATE_DIV_BIT_MASK 0xffffff
#define LWDO_REGS_ADC_SAMPLE_RATE_DIV_BIT_OFFSET 0
#define LWDO_REGS_ADC_SAMPLE_RATE_DIV_BYTE_WIDTH 4
#define LWDO_REGS_ADC_SAMPLE_RATE_DIV_BYTE_SIZE 4
#define LWDO_REGS_ADC_SAMPLE_RATE_DIV_BYTE_OFFSET 0x64
#define LWDO_REGS_ADC_TS_RATE_DIV_BIT_WIDTH 8
#define LWDO_REGS_ADC_TS_RATE_DIV_BIT_MASK 0xff
#define LWDO_REGS_ADC_TS_RATE_DIV_BIT_OFFSET 0
#define LWDO_REGS_ADC_TS_RATE_DIV_BYTE_WIDTH 4
#define LWDO_REGS_ADC_TS_RATE_DIV_BYTE_SIZE 4
#define LWDO_REGS_ADC_TS_RATE_DIV_BYTE_OFFSET 0x68
#define LWDO_REGS_FTUN_VTUNE_SET_DAC_LOW_BIT_WIDTH 8
#define LWDO_REGS_FTUN_VTUNE_SET_DAC_LOW_BIT_MASK 0xff
#define LWDO_REGS_FTUN_VTUNE_SET_DAC_LOW_BIT_OFFSET 0
#define LWDO_REGS_FTUN_VTUNE_SET_DAC_HIGH_BIT_WIDTH 16
#define LWDO_REGS_FTUN_VTUNE_SET_DAC_HIGH_BIT_MASK 0xffff
#define LWDO_REGS_FTUN_VTUNE_SET_DAC_HIGH_BIT_OFFSET 8
#define LWDO_REGS_FTUN_VTUNE_SET_BYTE_WIDTH 4
#define LWDO_REGS_FTUN_VTUNE_SET_BYTE_SIZE 4
#define LWDO_REGS_FTUN_VTUNE_SET_BYTE_OFFSET 0x80
#define LWDO_REGS_PPS_CON_EN_BIT_WIDTH 1
#define LWDO_REGS_PPS_CON_EN_BIT_MASK 0x1
#define LWDO_REGS_PPS_CON_EN_BIT_OFFSET 0
#define LWDO_REGS_PPS_CON_BYTE_WIDTH 4
#define LWDO_REGS_PPS_CON_BYTE_SIZE 4
#define LWDO_REGS_PPS_CON_BYTE_OFFSET 0xa0
#define LWDO_REGS_PPS_RATE_DIV_BIT_WIDTH 28
#define LWDO_REGS_PPS_RATE_DIV_BIT_MASK 0xfffffff
#define LWDO_REGS_PPS_RATE_DIV_BIT_OFFSET 0
#define LWDO_REGS_PPS_RATE_DIV_BYTE_WIDTH 4
#define LWDO_REGS_PPS_RATE_DIV_BYTE_SIZE 4
#define LWDO_REGS_PPS_RATE_DIV_BYTE_OFFSET 0xa4
#define LWDO_REGS_PPS_PULSE_WIDTH_BIT_WIDTH 28
#define LWDO_REGS_PPS_PULSE_WIDTH_BIT_MASK 0xfffffff
#define LWDO_REGS_PPS_PULSE_WIDTH_BIT_OFFSET 0
#define LWDO_REGS_PPS_PULSE_WIDTH_BYTE_WIDTH 4
#define LWDO_REGS_PPS_PULSE_WIDTH_BYTE_SIZE 4
#define LWDO_REGS_PPS_PULSE_WIDTH_BYTE_OFFSET 0xa8
#define LWDO_REGS_IO_CLKOUT_SOURCE_BIT_WIDTH 5
#define LWDO_REGS_IO_CLKOUT_SOURCE_BIT_MASK 0x1f
#define LWDO_REGS_IO_CLKOUT_SOURCE_BIT_OFFSET 0
#define LWDO_REGS_IO_CLKOUT_INV_BIT_WIDTH 1
#define LWDO_REGS_IO_CLKOUT_INV_BIT_MASK 0x1
#define LWDO_REGS_IO_CLKOUT_INV_BIT_OFFSET 30
#define LWDO_REGS_IO_CLKOUT_MODE_BIT_WIDTH 1
#define LWDO_REGS_IO_CLKOUT_MODE_BIT_MASK 0x1
#define LWDO_REGS_IO_CLKOUT_MODE_BIT_OFFSET 31
#define LWDO_REGS_IO_CLKOUT_BYTE_WIDTH 4
#define LWDO_REGS_IO_CLKOUT_BYTE_SIZE 4
#define LWDO_REGS_IO_CLKOUT_BYTE_OFFSET 0xc0
#define LWDO_REGS_TEST_RW_VAL_BIT_WIDTH 32
#define LWDO_REGS_TEST_RW_VAL_BIT_MASK 0xffffffff
#define LWDO_REGS_TEST_RW_VAL_BIT_OFFSET 0
#define LWDO_REGS_TEST_RW_BYTE_WIDTH 4
#define LWDO_REGS_TEST_RW_BYTE_SIZE 4
#define LWDO_REGS_TEST_RW_BYTE_OFFSET 0x3e0
typedef struct {
  uint32_t magic;
  uint32_t version;
  uint32_t con;
  uint32_t pll;
} lwdo_regs_sys_t;
typedef struct {
  uint32_t cnt;
} lwdo_regs_hwtime_t;
typedef struct {
  uint32_t con;
  uint32_t pll;
  uint32_t div_gate;
  uint32_t div_meas;
} lwdo_regs_tdc_t;
typedef struct {
  uint32_t con;
  uint32_t sample_rate_div;
  uint32_t ts_rate_div;
} lwdo_regs_adc_t;
typedef struct {
  uint32_t vtune_set;
} lwdo_regs_ftun_t;
typedef struct {
  uint32_t con;
  uint32_t rate_div;
  uint32_t pulse_width;
} lwdo_regs_pps_t;
typedef struct {
  uint32_t clkout;
} lwdo_regs_io_t;
typedef struct {
  uint32_t rw;
} lwdo_regs_test_t;
typedef struct {
  lwdo_regs_sys_t sys;
  uint32_t __reserved_0x010;
  uint32_t __reserved_0x014;
  uint32_t __reserved_0x018;
  uint32_t __reserved_0x01c;
  lwdo_regs_hwtime_t hwtime;
  uint32_t __reserved_0x024;
  uint32_t __reserved_0x028;
  uint32_t __reserved_0x02c;
  uint32_t __reserved_0x030;
  uint32_t __reserved_0x034;
  uint32_t __reserved_0x038;
  uint32_t __reserved_0x03c;
  lwdo_regs_tdc_t tdc;
  uint32_t __reserved_0x050;
  uint32_t __reserved_0x054;
  uint32_t __reserved_0x058;
  uint32_t __reserved_0x05c;
  lwdo_regs_adc_t adc;
  uint32_t __reserved_0x06c;
  uint32_t __reserved_0x070;
  uint32_t __reserved_0x074;
  uint32_t __reserved_0x078;
  uint32_t __reserved_0x07c;
  lwdo_regs_ftun_t ftun;
  uint32_t __reserved_0x084;
  uint32_t __reserved_0x088;
  uint32_t __reserved_0x08c;
  uint32_t __reserved_0x090;
  uint32_t __reserved_0x094;
  uint32_t __reserved_0x098;
  uint32_t __reserved_0x09c;
  lwdo_regs_pps_t pps;
  uint32_t __reserved_0x0ac;
  uint32_t __reserved_0x0b0;
  uint32_t __reserved_0x0b4;
  uint32_t __reserved_0x0b8;
  uint32_t __reserved_0x0bc;
  lwdo_regs_io_t io;
  uint32_t __reserved_0x0c4;
  uint32_t __reserved_0x0c8;
  uint32_t __reserved_0x0cc;
  uint32_t __reserved_0x0d0;
  uint32_t __reserved_0x0d4;
  uint32_t __reserved_0x0d8;
  uint32_t __reserved_0x0dc;
  uint32_t __reserved_0x0e0;
  uint32_t __reserved_0x0e4;
  uint32_t __reserved_0x0e8;
  uint32_t __reserved_0x0ec;
  uint32_t __reserved_0x0f0;
  uint32_t __reserved_0x0f4;
  uint32_t __reserved_0x0f8;
  uint32_t __reserved_0x0fc;
  uint32_t __reserved_0x100;
  uint32_t __reserved_0x104;
  uint32_t __reserved_0x108;
  uint32_t __reserved_0x10c;
  uint32_t __reserved_0x110;
  uint32_t __reserved_0x114;
  uint32_t __reserved_0x118;
  uint32_t __reserved_0x11c;
  uint32_t __reserved_0x120;
  uint32_t __reserved_0x124;
  uint32_t __reserved_0x128;
  uint32_t __reserved_0x12c;
  uint32_t __reserved_0x130;
  uint32_t __reserved_0x134;
  uint32_t __reserved_0x138;
  uint32_t __reserved_0x13c;
  uint32_t __reserved_0x140;
  uint32_t __reserved_0x144;
  uint32_t __reserved_0x148;
  uint32_t __reserved_0x14c;
  uint32_t __reserved_0x150;
  uint32_t __reserved_0x154;
  uint32_t __reserved_0x158;
  uint32_t __reserved_0x15c;
  uint32_t __reserved_0x160;
  uint32_t __reserved_0x164;
  uint32_t __reserved_0x168;
  uint32_t __reserved_0x16c;
  uint32_t __reserved_0x170;
  uint32_t __reserved_0x174;
  uint32_t __reserved_0x178;
  uint32_t __reserved_0x17c;
  uint32_t __reserved_0x180;
  uint32_t __reserved_0x184;
  uint32_t __reserved_0x188;
  uint32_t __reserved_0x18c;
  uint32_t __reserved_0x190;
  uint32_t __reserved_0x194;
  uint32_t __reserved_0x198;
  uint32_t __reserved_0x19c;
  uint32_t __reserved_0x1a0;
  uint32_t __reserved_0x1a4;
  uint32_t __reserved_0x1a8;
  uint32_t __reserved_0x1ac;
  uint32_t __reserved_0x1b0;
  uint32_t __reserved_0x1b4;
  uint32_t __reserved_0x1b8;
  uint32_t __reserved_0x1bc;
  uint32_t __reserved_0x1c0;
  uint32_t __reserved_0x1c4;
  uint32_t __reserved_0x1c8;
  uint32_t __reserved_0x1cc;
  uint32_t __reserved_0x1d0;
  uint32_t __reserved_0x1d4;
  uint32_t __reserved_0x1d8;
  uint32_t __reserved_0x1dc;
  uint32_t __reserved_0x1e0;
  uint32_t __reserved_0x1e4;
  uint32_t __reserved_0x1e8;
  uint32_t __reserved_0x1ec;
  uint32_t __reserved_0x1f0;
  uint32_t __reserved_0x1f4;
  uint32_t __reserved_0x1f8;
  uint32_t __reserved_0x1fc;
  uint32_t __reserved_0x200;
  uint32_t __reserved_0x204;
  uint32_t __reserved_0x208;
  uint32_t __reserved_0x20c;
  uint32_t __reserved_0x210;
  uint32_t __reserved_0x214;
  uint32_t __reserved_0x218;
  uint32_t __reserved_0x21c;
  uint32_t __reserved_0x220;
  uint32_t __reserved_0x224;
  uint32_t __reserved_0x228;
  uint32_t __reserved_0x22c;
  uint32_t __reserved_0x230;
  uint32_t __reserved_0x234;
  uint32_t __reserved_0x238;
  uint32_t __reserved_0x23c;
  uint32_t __reserved_0x240;
  uint32_t __reserved_0x244;
  uint32_t __reserved_0x248;
  uint32_t __reserved_0x24c;
  uint32_t __reserved_0x250;
  uint32_t __reserved_0x254;
  uint32_t __reserved_0x258;
  uint32_t __reserved_0x25c;
  uint32_t __reserved_0x260;
  uint32_t __reserved_0x264;
  uint32_t __reserved_0x268;
  uint32_t __reserved_0x26c;
  uint32_t __reserved_0x270;
  uint32_t __reserved_0x274;
  uint32_t __reserved_0x278;
  uint32_t __reserved_0x27c;
  uint32_t __reserved_0x280;
  uint32_t __reserved_0x284;
  uint32_t __reserved_0x288;
  uint32_t __reserved_0x28c;
  uint32_t __reserved_0x290;
  uint32_t __reserved_0x294;
  uint32_t __reserved_0x298;
  uint32_t __reserved_0x29c;
  uint32_t __reserved_0x2a0;
  uint32_t __reserved_0x2a4;
  uint32_t __reserved_0x2a8;
  uint32_t __reserved_0x2ac;
  uint32_t __reserved_0x2b0;
  uint32_t __reserved_0x2b4;
  uint32_t __reserved_0x2b8;
  uint32_t __reserved_0x2bc;
  uint32_t __reserved_0x2c0;
  uint32_t __reserved_0x2c4;
  uint32_t __reserved_0x2c8;
  uint32_t __reserved_0x2cc;
  uint32_t __reserved_0x2d0;
  uint32_t __reserved_0x2d4;
  uint32_t __reserved_0x2d8;
  uint32_t __reserved_0x2dc;
  uint32_t __reserved_0x2e0;
  uint32_t __reserved_0x2e4;
  uint32_t __reserved_0x2e8;
  uint32_t __reserved_0x2ec;
  uint32_t __reserved_0x2f0;
  uint32_t __reserved_0x2f4;
  uint32_t __reserved_0x2f8;
  uint32_t __reserved_0x2fc;
  uint32_t __reserved_0x300;
  uint32_t __reserved_0x304;
  uint32_t __reserved_0x308;
  uint32_t __reserved_0x30c;
  uint32_t __reserved_0x310;
  uint32_t __reserved_0x314;
  uint32_t __reserved_0x318;
  uint32_t __reserved_0x31c;
  uint32_t __reserved_0x320;
  uint32_t __reserved_0x324;
  uint32_t __reserved_0x328;
  uint32_t __reserved_0x32c;
  uint32_t __reserved_0x330;
  uint32_t __reserved_0x334;
  uint32_t __reserved_0x338;
  uint32_t __reserved_0x33c;
  uint32_t __reserved_0x340;
  uint32_t __reserved_0x344;
  uint32_t __reserved_0x348;
  uint32_t __reserved_0x34c;
  uint32_t __reserved_0x350;
  uint32_t __reserved_0x354;
  uint32_t __reserved_0x358;
  uint32_t __reserved_0x35c;
  uint32_t __reserved_0x360;
  uint32_t __reserved_0x364;
  uint32_t __reserved_0x368;
  uint32_t __reserved_0x36c;
  uint32_t __reserved_0x370;
  uint32_t __reserved_0x374;
  uint32_t __reserved_0x378;
  uint32_t __reserved_0x37c;
  uint32_t __reserved_0x380;
  uint32_t __reserved_0x384;
  uint32_t __reserved_0x388;
  uint32_t __reserved_0x38c;
  uint32_t __reserved_0x390;
  uint32_t __reserved_0x394;
  uint32_t __reserved_0x398;
  uint32_t __reserved_0x39c;
  uint32_t __reserved_0x3a0;
  uint32_t __reserved_0x3a4;
  uint32_t __reserved_0x3a8;
  uint32_t __reserved_0x3ac;
  uint32_t __reserved_0x3b0;
  uint32_t __reserved_0x3b4;
  uint32_t __reserved_0x3b8;
  uint32_t __reserved_0x3bc;
  uint32_t __reserved_0x3c0;
  uint32_t __reserved_0x3c4;
  uint32_t __reserved_0x3c8;
  uint32_t __reserved_0x3cc;
  uint32_t __reserved_0x3d0;
  uint32_t __reserved_0x3d4;
  uint32_t __reserved_0x3d8;
  uint32_t __reserved_0x3dc;
  lwdo_regs_test_t test;
  uint32_t __reserved_0x3e4;
  uint32_t __reserved_0x3e8;
  uint32_t __reserved_0x3ec;
  uint32_t __reserved_0x3f0;
  uint32_t __reserved_0x3f4;
  uint32_t __reserved_0x3f8;
  uint32_t __reserved_0x3fc;
} lwdo_regs_t;
#endif
