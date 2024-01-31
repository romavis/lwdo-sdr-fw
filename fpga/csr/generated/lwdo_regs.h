#ifndef LWDO_REGS_H
#define LWDO_REGS_H
#include "stdint.h"
#define LWDO_REGS_SYS_MAGIC_MAGIC_BIT_WIDTH 32
#define LWDO_REGS_SYS_MAGIC_MAGIC_BIT_MASK 0xffffffff
#define LWDO_REGS_SYS_MAGIC_MAGIC_BIT_OFFSET 0
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
#define LWDO_REGS_SYS_CON_BYTE_WIDTH 2
#define LWDO_REGS_SYS_CON_BYTE_SIZE 2
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
#define LWDO_REGS_SYS_PLL_BYTE_WIDTH 2
#define LWDO_REGS_SYS_PLL_BYTE_SIZE 2
#define LWDO_REGS_SYS_PLL_BYTE_OFFSET 0xa
#define LWDO_REGS_PDET_CON_EN_BIT_WIDTH 1
#define LWDO_REGS_PDET_CON_EN_BIT_MASK 0x1
#define LWDO_REGS_PDET_CON_EN_BIT_OFFSET 0
#define LWDO_REGS_PDET_CON_ECLK2_SLOW_BIT_WIDTH 1
#define LWDO_REGS_PDET_CON_ECLK2_SLOW_BIT_MASK 0x1
#define LWDO_REGS_PDET_CON_ECLK2_SLOW_BIT_OFFSET 1
#define LWDO_REGS_PDET_CON_BYTE_WIDTH 2
#define LWDO_REGS_PDET_CON_BYTE_SIZE 2
#define LWDO_REGS_PDET_CON_BYTE_OFFSET 0x20
#define LWDO_REGS_PDET_N1_VAL_BIT_WIDTH 32
#define LWDO_REGS_PDET_N1_VAL_BIT_MASK 0xffffffff
#define LWDO_REGS_PDET_N1_VAL_BIT_OFFSET 0
#define LWDO_REGS_PDET_N1_BYTE_WIDTH 4
#define LWDO_REGS_PDET_N1_BYTE_SIZE 4
#define LWDO_REGS_PDET_N1_BYTE_OFFSET 0x22
#define LWDO_REGS_PDET_N2_VAL_BIT_WIDTH 32
#define LWDO_REGS_PDET_N2_VAL_BIT_MASK 0xffffffff
#define LWDO_REGS_PDET_N2_VAL_BIT_OFFSET 0
#define LWDO_REGS_PDET_N2_BYTE_WIDTH 4
#define LWDO_REGS_PDET_N2_BYTE_SIZE 4
#define LWDO_REGS_PDET_N2_BYTE_OFFSET 0x26
#define LWDO_REGS_ADCT_CON_SRATE1_EN_BIT_WIDTH 1
#define LWDO_REGS_ADCT_CON_SRATE1_EN_BIT_MASK 0x1
#define LWDO_REGS_ADCT_CON_SRATE1_EN_BIT_OFFSET 0
#define LWDO_REGS_ADCT_CON_SRATE2_EN_BIT_WIDTH 1
#define LWDO_REGS_ADCT_CON_SRATE2_EN_BIT_MASK 0x1
#define LWDO_REGS_ADCT_CON_SRATE2_EN_BIT_OFFSET 1
#define LWDO_REGS_ADCT_CON_PULS1_EN_BIT_WIDTH 1
#define LWDO_REGS_ADCT_CON_PULS1_EN_BIT_MASK 0x1
#define LWDO_REGS_ADCT_CON_PULS1_EN_BIT_OFFSET 2
#define LWDO_REGS_ADCT_CON_PULS2_EN_BIT_WIDTH 1
#define LWDO_REGS_ADCT_CON_PULS2_EN_BIT_MASK 0x1
#define LWDO_REGS_ADCT_CON_PULS2_EN_BIT_OFFSET 3
#define LWDO_REGS_ADCT_CON_BYTE_WIDTH 2
#define LWDO_REGS_ADCT_CON_BYTE_SIZE 2
#define LWDO_REGS_ADCT_CON_BYTE_OFFSET 0x40
#define LWDO_REGS_ADCT_SRATE1_PSC_DIV_VAL_BIT_WIDTH 8
#define LWDO_REGS_ADCT_SRATE1_PSC_DIV_VAL_BIT_MASK 0xff
#define LWDO_REGS_ADCT_SRATE1_PSC_DIV_VAL_BIT_OFFSET 0
#define LWDO_REGS_ADCT_SRATE1_PSC_DIV_BYTE_WIDTH 2
#define LWDO_REGS_ADCT_SRATE1_PSC_DIV_BYTE_SIZE 2
#define LWDO_REGS_ADCT_SRATE1_PSC_DIV_BYTE_OFFSET 0x42
#define LWDO_REGS_ADCT_SRATE2_PSC_DIV_VAL_BIT_WIDTH 8
#define LWDO_REGS_ADCT_SRATE2_PSC_DIV_VAL_BIT_MASK 0xff
#define LWDO_REGS_ADCT_SRATE2_PSC_DIV_VAL_BIT_OFFSET 0
#define LWDO_REGS_ADCT_SRATE2_PSC_DIV_BYTE_WIDTH 2
#define LWDO_REGS_ADCT_SRATE2_PSC_DIV_BYTE_SIZE 2
#define LWDO_REGS_ADCT_SRATE2_PSC_DIV_BYTE_OFFSET 0x44
#define LWDO_REGS_ADCT_PULS1_PSC_DIV_VAL_BIT_WIDTH 23
#define LWDO_REGS_ADCT_PULS1_PSC_DIV_VAL_BIT_MASK 0x7fffff
#define LWDO_REGS_ADCT_PULS1_PSC_DIV_VAL_BIT_OFFSET 0
#define LWDO_REGS_ADCT_PULS1_PSC_DIV_BYTE_WIDTH 4
#define LWDO_REGS_ADCT_PULS1_PSC_DIV_BYTE_SIZE 4
#define LWDO_REGS_ADCT_PULS1_PSC_DIV_BYTE_OFFSET 0x46
#define LWDO_REGS_ADCT_PULS2_PSC_DIV_VAL_BIT_WIDTH 23
#define LWDO_REGS_ADCT_PULS2_PSC_DIV_VAL_BIT_MASK 0x7fffff
#define LWDO_REGS_ADCT_PULS2_PSC_DIV_VAL_BIT_OFFSET 0
#define LWDO_REGS_ADCT_PULS2_PSC_DIV_BYTE_WIDTH 4
#define LWDO_REGS_ADCT_PULS2_PSC_DIV_BYTE_SIZE 4
#define LWDO_REGS_ADCT_PULS2_PSC_DIV_BYTE_OFFSET 0x4a
#define LWDO_REGS_ADCT_PULS1_DLY_VAL_BIT_WIDTH 9
#define LWDO_REGS_ADCT_PULS1_DLY_VAL_BIT_MASK 0x1ff
#define LWDO_REGS_ADCT_PULS1_DLY_VAL_BIT_OFFSET 0
#define LWDO_REGS_ADCT_PULS1_DLY_BYTE_WIDTH 2
#define LWDO_REGS_ADCT_PULS1_DLY_BYTE_SIZE 2
#define LWDO_REGS_ADCT_PULS1_DLY_BYTE_OFFSET 0x4e
#define LWDO_REGS_ADCT_PULS2_DLY_VAL_BIT_WIDTH 9
#define LWDO_REGS_ADCT_PULS2_DLY_VAL_BIT_MASK 0x1ff
#define LWDO_REGS_ADCT_PULS2_DLY_VAL_BIT_OFFSET 0
#define LWDO_REGS_ADCT_PULS2_DLY_BYTE_WIDTH 2
#define LWDO_REGS_ADCT_PULS2_DLY_BYTE_SIZE 2
#define LWDO_REGS_ADCT_PULS2_DLY_BYTE_OFFSET 0x50
#define LWDO_REGS_ADCT_PULS1_PWIDTH_VAL_BIT_WIDTH 16
#define LWDO_REGS_ADCT_PULS1_PWIDTH_VAL_BIT_MASK 0xffff
#define LWDO_REGS_ADCT_PULS1_PWIDTH_VAL_BIT_OFFSET 0
#define LWDO_REGS_ADCT_PULS1_PWIDTH_BYTE_WIDTH 2
#define LWDO_REGS_ADCT_PULS1_PWIDTH_BYTE_SIZE 2
#define LWDO_REGS_ADCT_PULS1_PWIDTH_BYTE_OFFSET 0x52
#define LWDO_REGS_ADCT_PULS2_PWIDTH_VAL_BIT_WIDTH 16
#define LWDO_REGS_ADCT_PULS2_PWIDTH_VAL_BIT_MASK 0xffff
#define LWDO_REGS_ADCT_PULS2_PWIDTH_VAL_BIT_OFFSET 0
#define LWDO_REGS_ADCT_PULS2_PWIDTH_BYTE_WIDTH 2
#define LWDO_REGS_ADCT_PULS2_PWIDTH_BYTE_SIZE 2
#define LWDO_REGS_ADCT_PULS2_PWIDTH_BYTE_OFFSET 0x54
#define LWDO_REGS_ADC_CON_ADC1_EN_BIT_WIDTH 1
#define LWDO_REGS_ADC_CON_ADC1_EN_BIT_MASK 0x1
#define LWDO_REGS_ADC_CON_ADC1_EN_BIT_OFFSET 0
#define LWDO_REGS_ADC_CON_ADC2_EN_BIT_WIDTH 1
#define LWDO_REGS_ADC_CON_ADC2_EN_BIT_MASK 0x1
#define LWDO_REGS_ADC_CON_ADC2_EN_BIT_OFFSET 1
#define LWDO_REGS_ADC_CON_BYTE_WIDTH 2
#define LWDO_REGS_ADC_CON_BYTE_SIZE 2
#define LWDO_REGS_ADC_CON_BYTE_OFFSET 0x80
#define LWDO_REGS_ADC_FIFO1_STS_EMPTY_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO1_STS_EMPTY_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO1_STS_EMPTY_BIT_OFFSET 0
#define LWDO_REGS_ADC_FIFO1_STS_FULL_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO1_STS_FULL_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO1_STS_FULL_BIT_OFFSET 1
#define LWDO_REGS_ADC_FIFO1_STS_HFULL_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO1_STS_HFULL_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO1_STS_HFULL_BIT_OFFSET 2
#define LWDO_REGS_ADC_FIFO1_STS_OVFL_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO1_STS_OVFL_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO1_STS_OVFL_BIT_OFFSET 3
#define LWDO_REGS_ADC_FIFO1_STS_UDFL_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO1_STS_UDFL_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO1_STS_UDFL_BIT_OFFSET 4
#define LWDO_REGS_ADC_FIFO1_STS_BYTE_WIDTH 2
#define LWDO_REGS_ADC_FIFO1_STS_BYTE_SIZE 2
#define LWDO_REGS_ADC_FIFO1_STS_BYTE_OFFSET 0x82
#define LWDO_REGS_ADC_FIFO2_STS_EMPTY_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO2_STS_EMPTY_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO2_STS_EMPTY_BIT_OFFSET 0
#define LWDO_REGS_ADC_FIFO2_STS_FULL_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO2_STS_FULL_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO2_STS_FULL_BIT_OFFSET 1
#define LWDO_REGS_ADC_FIFO2_STS_HFULL_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO2_STS_HFULL_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO2_STS_HFULL_BIT_OFFSET 2
#define LWDO_REGS_ADC_FIFO2_STS_OVFL_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO2_STS_OVFL_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO2_STS_OVFL_BIT_OFFSET 3
#define LWDO_REGS_ADC_FIFO2_STS_UDFL_BIT_WIDTH 1
#define LWDO_REGS_ADC_FIFO2_STS_UDFL_BIT_MASK 0x1
#define LWDO_REGS_ADC_FIFO2_STS_UDFL_BIT_OFFSET 4
#define LWDO_REGS_ADC_FIFO2_STS_BYTE_WIDTH 2
#define LWDO_REGS_ADC_FIFO2_STS_BYTE_SIZE 2
#define LWDO_REGS_ADC_FIFO2_STS_BYTE_OFFSET 0x84
#define LWDO_REGS_FTUN_VTUNE_SET_VAL_BIT_WIDTH 16
#define LWDO_REGS_FTUN_VTUNE_SET_VAL_BIT_MASK 0xffff
#define LWDO_REGS_FTUN_VTUNE_SET_VAL_BIT_OFFSET 0
#define LWDO_REGS_FTUN_VTUNE_SET_BYTE_WIDTH 2
#define LWDO_REGS_FTUN_VTUNE_SET_BYTE_SIZE 2
#define LWDO_REGS_FTUN_VTUNE_SET_BYTE_OFFSET 0xa0
#define LWDO_REGS_TEST_RW1_VAL_BIT_WIDTH 16
#define LWDO_REGS_TEST_RW1_VAL_BIT_MASK 0xffff
#define LWDO_REGS_TEST_RW1_VAL_BIT_OFFSET 0
#define LWDO_REGS_TEST_RW1_BYTE_WIDTH 2
#define LWDO_REGS_TEST_RW1_BYTE_SIZE 2
#define LWDO_REGS_TEST_RW1_BYTE_OFFSET 0x1f0
#define LWDO_REGS_TEST_RO1_VAL_BIT_WIDTH 16
#define LWDO_REGS_TEST_RO1_VAL_BIT_MASK 0xffff
#define LWDO_REGS_TEST_RO1_VAL_BIT_OFFSET 0
#define LWDO_REGS_TEST_RO1_BYTE_WIDTH 2
#define LWDO_REGS_TEST_RO1_BYTE_SIZE 2
#define LWDO_REGS_TEST_RO1_BYTE_OFFSET 0x1f2
#define LWDO_REGS_TEST_RO2_VAL_BIT_WIDTH 16
#define LWDO_REGS_TEST_RO2_VAL_BIT_MASK 0xffff
#define LWDO_REGS_TEST_RO2_VAL_BIT_OFFSET 0
#define LWDO_REGS_TEST_RO2_BYTE_WIDTH 2
#define LWDO_REGS_TEST_RO2_BYTE_SIZE 2
#define LWDO_REGS_TEST_RO2_BYTE_OFFSET 0x1f4
#define LWDO_REGS_TEST_RO3_VAL_BIT_WIDTH 32
#define LWDO_REGS_TEST_RO3_VAL_BIT_MASK 0xffffffff
#define LWDO_REGS_TEST_RO3_VAL_BIT_OFFSET 0
#define LWDO_REGS_TEST_RO3_BYTE_WIDTH 4
#define LWDO_REGS_TEST_RO3_BYTE_SIZE 4
#define LWDO_REGS_TEST_RO3_BYTE_OFFSET 0x1f6
#define LWDO_REGS_TEST_RO4_VAL_BIT_WIDTH 32
#define LWDO_REGS_TEST_RO4_VAL_BIT_MASK 0xffffffff
#define LWDO_REGS_TEST_RO4_VAL_BIT_OFFSET 0
#define LWDO_REGS_TEST_RO4_BYTE_WIDTH 4
#define LWDO_REGS_TEST_RO4_BYTE_SIZE 4
#define LWDO_REGS_TEST_RO4_BYTE_OFFSET 0x1fa
typedef struct {
  uint32_t magic;
  uint32_t version;
  uint16_t con;
  uint16_t pll;
} lwdo_regs_sys_t;
typedef struct {
  uint16_t con;
  uint32_t n1;
  uint32_t n2;
} lwdo_regs_pdet_t;
typedef struct {
  uint16_t con;
  uint16_t srate1_psc_div;
  uint16_t srate2_psc_div;
  uint32_t puls1_psc_div;
  uint32_t puls2_psc_div;
  uint16_t puls1_dly;
  uint16_t puls2_dly;
  uint16_t puls1_pwidth;
  uint16_t puls2_pwidth;
} lwdo_regs_adct_t;
typedef struct {
  uint16_t con;
  uint16_t fifo1_sts;
  uint16_t fifo2_sts;
} lwdo_regs_adc_t;
typedef struct {
  uint16_t vtune_set;
} lwdo_regs_ftun_t;
typedef struct {
  uint16_t rw1;
  uint16_t ro1;
  uint16_t ro2;
  uint32_t ro3;
  uint32_t ro4;
} lwdo_regs_test_t;
typedef struct {
  lwdo_regs_sys_t sys;
  uint16_t __reserved_0x00c;
  uint16_t __reserved_0x00e;
  uint16_t __reserved_0x010;
  uint16_t __reserved_0x012;
  uint16_t __reserved_0x014;
  uint16_t __reserved_0x016;
  uint16_t __reserved_0x018;
  uint16_t __reserved_0x01a;
  uint16_t __reserved_0x01c;
  uint16_t __reserved_0x01e;
  lwdo_regs_pdet_t pdet;
  uint16_t __reserved_0x02a;
  uint16_t __reserved_0x02c;
  uint16_t __reserved_0x02e;
  uint16_t __reserved_0x030;
  uint16_t __reserved_0x032;
  uint16_t __reserved_0x034;
  uint16_t __reserved_0x036;
  uint16_t __reserved_0x038;
  uint16_t __reserved_0x03a;
  uint16_t __reserved_0x03c;
  uint16_t __reserved_0x03e;
  lwdo_regs_adct_t adct;
  uint16_t __reserved_0x056;
  uint16_t __reserved_0x058;
  uint16_t __reserved_0x05a;
  uint16_t __reserved_0x05c;
  uint16_t __reserved_0x05e;
  uint16_t __reserved_0x060;
  uint16_t __reserved_0x062;
  uint16_t __reserved_0x064;
  uint16_t __reserved_0x066;
  uint16_t __reserved_0x068;
  uint16_t __reserved_0x06a;
  uint16_t __reserved_0x06c;
  uint16_t __reserved_0x06e;
  uint16_t __reserved_0x070;
  uint16_t __reserved_0x072;
  uint16_t __reserved_0x074;
  uint16_t __reserved_0x076;
  uint16_t __reserved_0x078;
  uint16_t __reserved_0x07a;
  uint16_t __reserved_0x07c;
  uint16_t __reserved_0x07e;
  lwdo_regs_adc_t adc;
  uint16_t __reserved_0x086;
  uint16_t __reserved_0x088;
  uint16_t __reserved_0x08a;
  uint16_t __reserved_0x08c;
  uint16_t __reserved_0x08e;
  uint16_t __reserved_0x090;
  uint16_t __reserved_0x092;
  uint16_t __reserved_0x094;
  uint16_t __reserved_0x096;
  uint16_t __reserved_0x098;
  uint16_t __reserved_0x09a;
  uint16_t __reserved_0x09c;
  uint16_t __reserved_0x09e;
  lwdo_regs_ftun_t ftun;
  uint16_t __reserved_0x0a2;
  uint16_t __reserved_0x0a4;
  uint16_t __reserved_0x0a6;
  uint16_t __reserved_0x0a8;
  uint16_t __reserved_0x0aa;
  uint16_t __reserved_0x0ac;
  uint16_t __reserved_0x0ae;
  uint16_t __reserved_0x0b0;
  uint16_t __reserved_0x0b2;
  uint16_t __reserved_0x0b4;
  uint16_t __reserved_0x0b6;
  uint16_t __reserved_0x0b8;
  uint16_t __reserved_0x0ba;
  uint16_t __reserved_0x0bc;
  uint16_t __reserved_0x0be;
  uint16_t __reserved_0x0c0;
  uint16_t __reserved_0x0c2;
  uint16_t __reserved_0x0c4;
  uint16_t __reserved_0x0c6;
  uint16_t __reserved_0x0c8;
  uint16_t __reserved_0x0ca;
  uint16_t __reserved_0x0cc;
  uint16_t __reserved_0x0ce;
  uint16_t __reserved_0x0d0;
  uint16_t __reserved_0x0d2;
  uint16_t __reserved_0x0d4;
  uint16_t __reserved_0x0d6;
  uint16_t __reserved_0x0d8;
  uint16_t __reserved_0x0da;
  uint16_t __reserved_0x0dc;
  uint16_t __reserved_0x0de;
  uint16_t __reserved_0x0e0;
  uint16_t __reserved_0x0e2;
  uint16_t __reserved_0x0e4;
  uint16_t __reserved_0x0e6;
  uint16_t __reserved_0x0e8;
  uint16_t __reserved_0x0ea;
  uint16_t __reserved_0x0ec;
  uint16_t __reserved_0x0ee;
  uint16_t __reserved_0x0f0;
  uint16_t __reserved_0x0f2;
  uint16_t __reserved_0x0f4;
  uint16_t __reserved_0x0f6;
  uint16_t __reserved_0x0f8;
  uint16_t __reserved_0x0fa;
  uint16_t __reserved_0x0fc;
  uint16_t __reserved_0x0fe;
  uint16_t __reserved_0x100;
  uint16_t __reserved_0x102;
  uint16_t __reserved_0x104;
  uint16_t __reserved_0x106;
  uint16_t __reserved_0x108;
  uint16_t __reserved_0x10a;
  uint16_t __reserved_0x10c;
  uint16_t __reserved_0x10e;
  uint16_t __reserved_0x110;
  uint16_t __reserved_0x112;
  uint16_t __reserved_0x114;
  uint16_t __reserved_0x116;
  uint16_t __reserved_0x118;
  uint16_t __reserved_0x11a;
  uint16_t __reserved_0x11c;
  uint16_t __reserved_0x11e;
  uint16_t __reserved_0x120;
  uint16_t __reserved_0x122;
  uint16_t __reserved_0x124;
  uint16_t __reserved_0x126;
  uint16_t __reserved_0x128;
  uint16_t __reserved_0x12a;
  uint16_t __reserved_0x12c;
  uint16_t __reserved_0x12e;
  uint16_t __reserved_0x130;
  uint16_t __reserved_0x132;
  uint16_t __reserved_0x134;
  uint16_t __reserved_0x136;
  uint16_t __reserved_0x138;
  uint16_t __reserved_0x13a;
  uint16_t __reserved_0x13c;
  uint16_t __reserved_0x13e;
  uint16_t __reserved_0x140;
  uint16_t __reserved_0x142;
  uint16_t __reserved_0x144;
  uint16_t __reserved_0x146;
  uint16_t __reserved_0x148;
  uint16_t __reserved_0x14a;
  uint16_t __reserved_0x14c;
  uint16_t __reserved_0x14e;
  uint16_t __reserved_0x150;
  uint16_t __reserved_0x152;
  uint16_t __reserved_0x154;
  uint16_t __reserved_0x156;
  uint16_t __reserved_0x158;
  uint16_t __reserved_0x15a;
  uint16_t __reserved_0x15c;
  uint16_t __reserved_0x15e;
  uint16_t __reserved_0x160;
  uint16_t __reserved_0x162;
  uint16_t __reserved_0x164;
  uint16_t __reserved_0x166;
  uint16_t __reserved_0x168;
  uint16_t __reserved_0x16a;
  uint16_t __reserved_0x16c;
  uint16_t __reserved_0x16e;
  uint16_t __reserved_0x170;
  uint16_t __reserved_0x172;
  uint16_t __reserved_0x174;
  uint16_t __reserved_0x176;
  uint16_t __reserved_0x178;
  uint16_t __reserved_0x17a;
  uint16_t __reserved_0x17c;
  uint16_t __reserved_0x17e;
  uint16_t __reserved_0x180;
  uint16_t __reserved_0x182;
  uint16_t __reserved_0x184;
  uint16_t __reserved_0x186;
  uint16_t __reserved_0x188;
  uint16_t __reserved_0x18a;
  uint16_t __reserved_0x18c;
  uint16_t __reserved_0x18e;
  uint16_t __reserved_0x190;
  uint16_t __reserved_0x192;
  uint16_t __reserved_0x194;
  uint16_t __reserved_0x196;
  uint16_t __reserved_0x198;
  uint16_t __reserved_0x19a;
  uint16_t __reserved_0x19c;
  uint16_t __reserved_0x19e;
  uint16_t __reserved_0x1a0;
  uint16_t __reserved_0x1a2;
  uint16_t __reserved_0x1a4;
  uint16_t __reserved_0x1a6;
  uint16_t __reserved_0x1a8;
  uint16_t __reserved_0x1aa;
  uint16_t __reserved_0x1ac;
  uint16_t __reserved_0x1ae;
  uint16_t __reserved_0x1b0;
  uint16_t __reserved_0x1b2;
  uint16_t __reserved_0x1b4;
  uint16_t __reserved_0x1b6;
  uint16_t __reserved_0x1b8;
  uint16_t __reserved_0x1ba;
  uint16_t __reserved_0x1bc;
  uint16_t __reserved_0x1be;
  uint16_t __reserved_0x1c0;
  uint16_t __reserved_0x1c2;
  uint16_t __reserved_0x1c4;
  uint16_t __reserved_0x1c6;
  uint16_t __reserved_0x1c8;
  uint16_t __reserved_0x1ca;
  uint16_t __reserved_0x1cc;
  uint16_t __reserved_0x1ce;
  uint16_t __reserved_0x1d0;
  uint16_t __reserved_0x1d2;
  uint16_t __reserved_0x1d4;
  uint16_t __reserved_0x1d6;
  uint16_t __reserved_0x1d8;
  uint16_t __reserved_0x1da;
  uint16_t __reserved_0x1dc;
  uint16_t __reserved_0x1de;
  uint16_t __reserved_0x1e0;
  uint16_t __reserved_0x1e2;
  uint16_t __reserved_0x1e4;
  uint16_t __reserved_0x1e6;
  uint16_t __reserved_0x1e8;
  uint16_t __reserved_0x1ea;
  uint16_t __reserved_0x1ec;
  uint16_t __reserved_0x1ee;
  lwdo_regs_test_t test;
  uint16_t __reserved_0x1fe;
} lwdo_regs_t;
#endif
