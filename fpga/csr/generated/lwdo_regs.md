## lwdo_regs

* byte_size
    * 1024

|name|offset_address|
|:--|:--|
|[sys.magic](#lwdo_regs-sys-magic)|0x000|
|[sys.version](#lwdo_regs-sys-version)|0x004|
|[sys.con](#lwdo_regs-sys-con)|0x008|
|[sys.pll](#lwdo_regs-sys-pll)|0x00c|
|[hwtime.cnt](#lwdo_regs-hwtime-cnt)|0x020|
|[tdc.con](#lwdo_regs-tdc-con)|0x040|
|[tdc.pll](#lwdo_regs-tdc-pll)|0x044|
|[tdc.div_gate](#lwdo_regs-tdc-div_gate)|0x048|
|[tdc.div_meas](#lwdo_regs-tdc-div_meas)|0x04c|
|[adc.con](#lwdo_regs-adc-con)|0x060|
|[adc.sample_rate_div](#lwdo_regs-adc-sample_rate_div)|0x064|
|[adc.ts_rate_div](#lwdo_regs-adc-ts_rate_div)|0x068|
|[ftun.vtune_set](#lwdo_regs-ftun-vtune_set)|0x080|
|[pps.con](#lwdo_regs-pps-con)|0x0a0|
|[pps.rate_div](#lwdo_regs-pps-rate_div)|0x0a4|
|[pps.pulse_width](#lwdo_regs-pps-pulse_width)|0x0a8|
|[test.rw](#lwdo_regs-test-rw)|0x3e0|

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
    * 0x00c
* type
    * default
* comment
    * Read-only PLL configuration bits (for host to compute sys_clk)

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|divr|[3:0]|rof|default: 0x0||||
|divf|[10:4]|rof|default: 0x00||||
|divq|[13:11]|rof|default: 0x0||||

### <div id="lwdo_regs-hwtime-cnt"></div>hwtime.cnt

* offset_address
    * 0x020
* type
    * default
* comment
    * HWTIME counter value

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|cnt|[31:0]|ro|||||

### <div id="lwdo_regs-tdc-con"></div>tdc.con

* offset_address
    * 0x040
* type
    * default
* comment
    * TDC control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|en|[0]|rw|0x0|||Enable TDC|
|meas_div_en|[1]|rw|0x0|||If 1, divide clk_meas; if 0 then use undivided clk_meas. Set this when clk_meas is fast (more than ~1 kHz)|
|gate_fdec|[2]|rw|0x0|||Set this to decrease the frequency of divided clk_gate (increases clk_gate divider)|
|gate_finc|[3]|rw|0x0|||Set this to increase the frequency of divided clk_gate (decreases clk_gate divider)|

### <div id="lwdo_regs-tdc-pll"></div>tdc.pll

* offset_address
    * 0x044
* type
    * default
* comment
    * Read-only PLL configuration bits (for host to compute tdc_clk)

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|divr|[3:0]|rof|default: 0x0||||
|divf|[10:4]|rof|default: 0x00||||
|divq|[13:11]|rof|default: 0x0||||
|ss_divfspan|[20:14]|rof|default: 0x00||||

### <div id="lwdo_regs-tdc-div_gate"></div>tdc.div_gate

* offset_address
    * 0x048
* type
    * default
* comment
    * Divider for clk_gate

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|div_gate|[31:0]|rof|default: 0x00000000||||

### <div id="lwdo_regs-tdc-div_meas"></div>tdc.div_meas

* offset_address
    * 0x04c
* type
    * default
* comment
    * Divider for clk_meas

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|div_meas|[31:0]|rof|default: 0x00000000||||

### <div id="lwdo_regs-adc-con"></div>adc.con

* offset_address
    * 0x060
* type
    * default
* comment
    * ADC control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|adc_en|[3:0]|rw|0x0|||Enable ADC channels 1-4|

### <div id="lwdo_regs-adc-sample_rate_div"></div>adc.sample_rate_div

* offset_address
    * 0x064
* type
    * default
* comment
    * ADC sample rate divider

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|sample_rate_div|[23:0]|rw|0xffffff||||

### <div id="lwdo_regs-adc-ts_rate_div"></div>adc.ts_rate_div

* offset_address
    * 0x068
* type
    * default
* comment
    * Timestamping rate divider

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|ts_rate_div|[7:0]|rw|0xff||||

### <div id="lwdo_regs-ftun-vtune_set"></div>ftun.vtune_set

* offset_address
    * 0x080
* type
    * default
* comment
    * VCTCXO DAC control (linear scale, higher value -> higher frequency)

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|dac_low|[7:0]|rw|0x00|||VCTCXO DAC setting (low bits)|
|dac_high|[23:8]|rwtrg|0x8000|||VCTCXO DAC setting (high bits)|

### <div id="lwdo_regs-pps-con"></div>pps.con

* offset_address
    * 0x0a0
* type
    * default
* comment
    * PPS control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|en|[0]|rw|0x0|||Enable PPS generator|

### <div id="lwdo_regs-pps-rate_div"></div>pps.rate_div

* offset_address
    * 0x0a4
* type
    * default
* comment
    * PPS rate divider

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|rate_div|[27:0]|rw|0xfffffff||||

### <div id="lwdo_regs-pps-pulse_width"></div>pps.pulse_width

* offset_address
    * 0x0a8
* type
    * default
* comment
    * PPS pulse width control

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|pulse_width|[27:0]|rw|0x0010000||||

### <div id="lwdo_regs-test-rw"></div>test.rw

* offset_address
    * 0x3e0
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[31:0]|rw|0xaaa5555b||||
