## lwdo_regs

* byte_size
    * 512

|name|offset_address|
|:--|:--|
|[sys.magic](#lwdo_regs-sys-magic)|0x000|
|[sys.version](#lwdo_regs-sys-version)|0x004|
|[sys.con](#lwdo_regs-sys-con)|0x008|
|[sys.pll](#lwdo_regs-sys-pll)|0x00a|
|[pdet.con](#lwdo_regs-pdet-con)|0x020|
|[pdet.n1](#lwdo_regs-pdet-n1)|0x022|
|[pdet.n2](#lwdo_regs-pdet-n2)|0x026|
|[adct.con](#lwdo_regs-adct-con)|0x040|
|[adct.srate1_psc_div](#lwdo_regs-adct-srate1_psc_div)|0x042|
|[adct.srate2_psc_div](#lwdo_regs-adct-srate2_psc_div)|0x044|
|[adct.puls1_psc_div](#lwdo_regs-adct-puls1_psc_div)|0x046|
|[adct.puls2_psc_div](#lwdo_regs-adct-puls2_psc_div)|0x04a|
|[adct.puls1_dly](#lwdo_regs-adct-puls1_dly)|0x04e|
|[adct.puls2_dly](#lwdo_regs-adct-puls2_dly)|0x050|
|[adct.puls1_pwidth](#lwdo_regs-adct-puls1_pwidth)|0x052|
|[adct.puls2_pwidth](#lwdo_regs-adct-puls2_pwidth)|0x054|
|[adc.con](#lwdo_regs-adc-con)|0x080|
|[adc.fifo1_sts](#lwdo_regs-adc-fifo1_sts)|0x082|
|[adc.fifo2_sts](#lwdo_regs-adc-fifo2_sts)|0x084|
|[ftun.vtune_set](#lwdo_regs-ftun-vtune_set)|0x0a0|
|[test.rw1](#lwdo_regs-test-rw1)|0x1f0|
|[test.ro1](#lwdo_regs-test-ro1)|0x1f2|
|[test.ro2](#lwdo_regs-test-ro2)|0x1f4|
|[test.ro3](#lwdo_regs-test-ro3)|0x1f6|
|[test.ro4](#lwdo_regs-test-ro4)|0x1fa|

### <div id="lwdo_regs-sys-magic"></div>sys.magic

* offset_address
    * 0x000
* type
    * default
* comment
    * Read-only magic value

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|magic|[31:0]|rof|0x4544574c||||

### <div id="lwdo_regs-sys-version"></div>sys.version

* offset_address
    * 0x004
* type
    * default
* comment
    * Register file version

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|major|[15:0]|rof|0x0001||||
|minor|[31:16]|rof|0x0001||||

### <div id="lwdo_regs-sys-con"></div>sys.con

* offset_address
    * 0x008
* type
    * default
* comment
    * System-level control bits

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|sys_rst|[0]|w1|0x0|||write 1 to perform complete system reset|

### <div id="lwdo_regs-sys-pll"></div>sys.pll

* offset_address
    * 0x00a
* type
    * default
* comment
    * Read-only PLL configuration bits (for host to compute sys_clk)

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|divr|[3:0]|rof|default: 0x0||||
|divf|[10:4]|rof|default: 0x00||||
|divq|[13:11]|rof|default: 0x0||||

### <div id="lwdo_regs-pdet-con"></div>pdet.con

* offset_address
    * 0x020
* type
    * default
* comment
    * Phase detector control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|en|[0]|rw|0x0|||Enable phase detector|
|eclk2_slow|[1]|rw|0x0|||ECLK2 is slow (1Hz ~ 10Hz). If set, N2 divider is bypassed and fTIC2=fECLK2|

### <div id="lwdo_regs-pdet-n1"></div>pdet.n1

* offset_address
    * 0x022
* type
    * default
* comment
    * N1 divider

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[31:0]|rof|default: 0x00000000|||Clock frequency division factor for N1 divider. fTIC1=fECLK1/(2*(val+1))|

### <div id="lwdo_regs-pdet-n2"></div>pdet.n2

* offset_address
    * 0x026
* type
    * default
* comment
    * N2 divider

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[31:0]|rof|default: 0x00000000|||Clock frequency division factor for N2 divider. fTIC2=fECLK2/(2*(val+1))|

### <div id="lwdo_regs-adct-con"></div>adct.con

* offset_address
    * 0x040
* type
    * default
* comment
    * Common enable/disable bits

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|srate1_en|[0]|rw|0x0|||Enable sample rate generator 1|
|srate2_en|[1]|rw|0x0|||Enable sample rate generator 2|
|puls1_en|[2]|rw|0x0|||Enable pulse generator 1|
|puls2_en|[3]|rw|0x0|||Enable pulse generator 2|

### <div id="lwdo_regs-adct-srate1_psc_div"></div>adct.srate1_psc_div

* offset_address
    * 0x042
* type
    * default
* comment
    * Sample rate generator 1 prescaler division factor

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[7:0]|rw|0xc7|||Clock frequency division factor for sample rate generator 1. fSRATE1=fSYSCLK/(val+1)|

### <div id="lwdo_regs-adct-srate2_psc_div"></div>adct.srate2_psc_div

* offset_address
    * 0x044
* type
    * default
* comment
    * Sample rate generator 2 prescaler division factor

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[7:0]|rw|0xc7|||Clock frequency division factor for sample rate generator 2. fSRATE2=fSYSCLK/(val+1)|

### <div id="lwdo_regs-adct-puls1_psc_div"></div>adct.puls1_psc_div

* offset_address
    * 0x046
* type
    * default
* comment
    * Pulse generator 1 prescaler division factor

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[22:0]|rw|0x000000|||Clock frequency division factor for pulse generator 1. fPULS1=fSRATE1/(val+1)|

### <div id="lwdo_regs-adct-puls2_psc_div"></div>adct.puls2_psc_div

* offset_address
    * 0x04a
* type
    * default
* comment
    * Pulse generator 2 prescaler division factor

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[22:0]|rw|0x000000|||Clock frequency division factor for pulse generator 2. fPULS2=fSRATE2/(val+1)|

### <div id="lwdo_regs-adct-puls1_dly"></div>adct.puls1_dly

* offset_address
    * 0x04e
* type
    * default
* comment
    * Pulse generator 1 micro-delay control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[8:0]|rw|0x000|||Delay for pulse generator 1 output, number of SYSCLK cycles. Tdelay=(val+1)/fSYSCLK|

### <div id="lwdo_regs-adct-puls2_dly"></div>adct.puls2_dly

* offset_address
    * 0x050
* type
    * default
* comment
    * Pulse generator 2 micro-delay control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[8:0]|rw|0x000|||Delay for pulse generator 2 output, number of SYSCLK cycles. Tdelay=(val+1)/fSYSCLK|

### <div id="lwdo_regs-adct-puls1_pwidth"></div>adct.puls1_pwidth

* offset_address
    * 0x052
* type
    * default
* comment
    * Pulse generator 1 pulse width control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[15:0]|rw|0x0001|||Pulse width for pulse generator 1 output, number of SRATE1 cycles. Tpulse=val/fSRATE1|

### <div id="lwdo_regs-adct-puls2_pwidth"></div>adct.puls2_pwidth

* offset_address
    * 0x054
* type
    * default
* comment
    * Pulse generator 2 pulse width control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[15:0]|rw|0x0001|||Pulse width for pulse generator 2 output, number of SRATE2 cycles. Tpulse=val/fSRATE2|

### <div id="lwdo_regs-adc-con"></div>adc.con

* offset_address
    * 0x080
* type
    * default
* comment
    * ADC control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|adc1_en|[0]|rw|0x0|||Enable ADC1|
|adc2_en|[1]|rw|0x0|||Enable ADC2|

### <div id="lwdo_regs-adc-fifo1_sts"></div>adc.fifo1_sts

* offset_address
    * 0x082
* type
    * default
* comment
    * ADC1 FIFO status

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|empty|[0]|ro||||FIFO is empty|
|full|[1]|ro||||FIFO is full|
|hfull|[2]|ro||||FIFO is half-full|
|ovfl|[3]|rotrg||||FIFO has overflown (sticky bit, read to clear)|
|udfl|[4]|rotrg||||FIFO has underflown (sticky bit, read to clear)|

### <div id="lwdo_regs-adc-fifo2_sts"></div>adc.fifo2_sts

* offset_address
    * 0x084
* type
    * default
* comment
    * ADC2 FIFO status

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|empty|[0]|ro||||FIFO is empty|
|full|[1]|ro||||FIFO is full|
|hfull|[2]|ro||||FIFO is half-full|
|ovfl|[3]|rotrg||||FIFO has overflown (sticky bit, read to clear)|
|udfl|[4]|rotrg||||FIFO has underflown (sticky bit, read to clear)|

### <div id="lwdo_regs-ftun-vtune_set"></div>ftun.vtune_set

* offset_address
    * 0x0a0
* type
    * default
* comment
    * VCTCXO DAC control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[15:0]|rwtrg|0x8000|||VCTCXO DAC setting (linear scale, higher value -> higher frequency)|

### <div id="lwdo_regs-test-rw1"></div>test.rw1

* offset_address
    * 0x1f0
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[15:0]|rw|0x0000||||

### <div id="lwdo_regs-test-ro1"></div>test.ro1

* offset_address
    * 0x1f2
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[15:0]|rof|0xffff||||

### <div id="lwdo_regs-test-ro2"></div>test.ro2

* offset_address
    * 0x1f4
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[15:0]|rof|0x0000||||

### <div id="lwdo_regs-test-ro3"></div>test.ro3

* offset_address
    * 0x1f6
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[31:0]|rof|0xaaaaaa55||||

### <div id="lwdo_regs-test-ro4"></div>test.ro4

* offset_address
    * 0x1fa
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[31:0]|rof|0x55aa5555||||
