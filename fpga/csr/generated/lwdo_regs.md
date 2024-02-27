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
|[tdc.div_gate](#lwdo_regs-tdc-div_gate)|0x044|
|[tdc.div_meas_fast](#lwdo_regs-tdc-div_meas_fast)|0x048|
|[adc.con](#lwdo_regs-adc-con)|0x060|
|[ftun.vtune_set](#lwdo_regs-ftun-vtune_set)|0x080|
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

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|cnt|[31:0]|ro||||HWTIME counter value|

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
|clk_meas_fast|[1]|rw|0x0|||Set this when clk_meas is fast (more than ~1 kHz)|
|gate_fdec|[2]|rw|0x0|||Set this to decrease the frequency of divided clk_gate (increases clk_gate divider)|
|gate_finc|[3]|rw|0x0|||Set this to increase the frequency of divided clk_gate (decreases clk_gate divider)|

### <div id="lwdo_regs-tdc-div_gate"></div>tdc.div_gate

* offset_address
    * 0x044
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[31:0]|rof|default: 0x00000000|||Divider for clk_gate|

### <div id="lwdo_regs-tdc-div_meas_fast"></div>tdc.div_meas_fast

* offset_address
    * 0x048
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[31:0]|rof|default: 0x00000000|||Fast clk_meas divider (applied only when clk_meas_fast is set)|

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

### <div id="lwdo_regs-test-rw"></div>test.rw

* offset_address
    * 0x3e0
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|val|[31:0]|rw|0xaaa5555b||||
