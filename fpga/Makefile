# Makefile template borrowed from https://gist.github.com/DurandA/15c83f37ee64b185801f88fbe0a0f25c

# ----------------------------------------------------------------------------
# Tools
# ----------------------------------------------------------------------------

# TBD Windows?
PYTHON ?= python
RGGEN ?= rggen

# ----------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------

OUT_DIR = ./out
OUT_TEST_DIR = $(OUT_DIR)/test
SRC_DIR = .
TEST_DIR = $(SRC_DIR)/test

RGGEN_SRC = $(SRC_DIR)/rggen
RGGEN_OUT = $(OUT_DIR)/rggen

PNRGUI ?= 0
PROJ = top
PIN_DEF = $(SRC_DIR)/top.pcf
DEVICE = hx4k
PACKAGE = tq144

NEXTPNR_FLAGS = \
		--randomize-seed

ifeq ($(PNRGUI), 1)
	NEXTPNR_FLAGS += --gui
endif

all: \
	$(OUT_DIR)/$(PROJ).bin \
	$(OUT_DIR)/$(PROJ).icetime.txt \
	$(RGGEN_OUT)/lwdo_regs.hpp

.SECONDARY:

# Top level
V_MODULES := \
	$(SRC_DIR)/top.v \

V_INCLUDE_PATHS := \
	$(SRC_DIR)


# Other custom modules
# (keep in alphabet order)
V_MODULES += \
	$(SRC_DIR)/modules/ad7357if.v \
	$(SRC_DIR)/modules/cpstr_desc.v \
	$(SRC_DIR)/modules/cpstr_esc.v \
	$(SRC_DIR)/modules/cpstr_mgr_rx.v \
	$(SRC_DIR)/modules/cpstr_mgr_tx.v \
	$(SRC_DIR)/modules/dac8551.v \
	$(SRC_DIR)/modules/fastcounter.v \
	$(SRC_DIR)/modules/ft245sync.v \
	$(SRC_DIR)/modules/phase_det.v \
	$(SRC_DIR)/modules/rr_arbiter.v \
	$(SRC_DIR)/modules/rst_bridge.v \
	$(SRC_DIR)/modules/stream_buf.v \
	$(SRC_DIR)/modules/syncfifo.v \
	$(SRC_DIR)/modules/wb_mem_dly.v \
	$(SRC_DIR)/modules/wbcon_exec.v \
	$(SRC_DIR)/modules/wbcon_rx.v \
	$(SRC_DIR)/modules/wbcon_tx.v \
	$(SRC_DIR)/modules/wbcon.v \
	$(SRC_DIR)/modules/word_ser.v

V_INCLUDE_PATHS += \
	$(SRC_DIR)/modules


# 3rdparty verilog modules: async_fifo
V_MODULES += \
	$(SRC_DIR)/3rdparty/async_fifo/src/vlog/async_fifo.v \
	$(SRC_DIR)/3rdparty/async_fifo/src/vlog/fifo_2mem.v \
	$(SRC_DIR)/3rdparty/async_fifo/src/vlog/rptr_empty.v \
	$(SRC_DIR)/3rdparty/async_fifo/src/vlog/sync_r2w.v \
	$(SRC_DIR)/3rdparty/async_fifo/src/vlog/sync_w2r.v \
	$(SRC_DIR)/3rdparty/async_fifo/src/vlog/wptr_full.v

V_INCLUDE_PATHS += \
	$(SRC_DIR)/3rdparty/async_fifo/src/vlog

# 3rdparty verilog modules: rggen-verilog-rtl
RGGEN_VERILOG_RTL_ROOT = $(SRC_DIR)/3rdparty/rggen-verilog-rtl

V_INCLUDE_PATHS += \
	$(RGGEN_VERILOG_RTL_ROOT)

V_MODULES += \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_mux.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_bit_field.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_bit_field_w01trg.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_address_decoder.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_register_common.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_default_register.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_external_register.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_indirect_register.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_adapter_common.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_apb_adapter.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_apb_bridge.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_axi4lite_skid_buffer.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_axi4lite_adapter.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_axi4lite_bridge.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_wishbone_adapter.v \
	$(RGGEN_VERILOG_RTL_ROOT)/rggen_wishbone_bridge.v

# rggen-generated verilog modules
RGGEN_INPUTS = \
	$(RGGEN_SRC)/lwdo_regs.yml

V_MODULES += \
	$(RGGEN_OUT)/lwdo_regs.v

# Tests
# (keep in alphabet order)
TESTS := \
	test_cpstr_desc \
	test_cpstr_esc \
	test_cpstr_mgr_tx \
	test_dac8551 \
	test_fastcounter \
	test_lwdo_regs \
	test_phase_det \
	test_stream_buf \
	test_syncfifo \
	test_wbcon_exec \
	test_wbcon_rx \
	test_wbcon_tx \
	test_wbcon \
	test_word_ser

# ----------------------------------------------------------------------------
# Rules
# ----------------------------------------------------------------------------

# Directories
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(OUT_TEST_DIR):
	mkdir -p $(OUT_TEST_DIR)

# RGGEN register generator
# This requires you to:
#	1. Install rggen with all its dependencies (https://github.com/rggen/rggen)
#	2. Install rggen-verilog plugin (https://github.com/rggen/rggen-verilog)
#	3. Install rggen-c-header plugin (https://github.com/rggen/rggen-c-header)
#	4. Make sure that rggen is on your PATH (e.g. `export PATH=$PATH:$HOME/.gem/ruby/<version>/bin`)
$(RGGEN_OUT)/%.v: $(RGGEN_INPUTS) $(RGGEN_SRC)/config.yml
	$(RGGEN) --plugin rggen-verilog -c $(RGGEN_SRC)/config.yml --enable verilog -o $(RGGEN_OUT) $(RGGEN_INPUTS)

$(RGGEN_OUT)/%.h: $(RGGEN_INPUTS) $(RGGEN_SRC)/config.yml
	$(RGGEN) --plugin rggen-c-header -c $(RGGEN_SRC)/config.yml --enable c_header -o $(RGGEN_OUT) $(RGGEN_INPUTS)

$(RGGEN_OUT)/%.hpp: $(RGGEN_OUT)/%.h $(RGGEN_SRC)/gen_cpp_regs.py
	$(PYTHON) $(RGGEN_SRC)/gen_cpp_regs.py $* $< > $@

# Tests
.PHONY: test
test: $(TESTS)

.PHONY: $(TESTS)
$(TESTS): test_%: $(OUT_TEST_DIR)/test_% $(OUT_TEST_DIR)/test_%.vcd

$(OUT_TEST_DIR)/test_%: $(TEST_DIR)/test_%.v $(OUT_TEST_DIR) $(V_MODULES)
	iverilog -g2005-sv -o $@ $< $(foreach mod,$(V_MODULES), -l $(mod)) $(foreach path,$(V_INCLUDE_PATHS),-I $(path))

$(OUT_TEST_DIR)/test_%.vcd: $(OUT_TEST_DIR)/test_%
	@echo "Running test: $<"
	cd $(OUT_TEST_DIR); $(abspath $<)

# Synthesis
$(OUT_DIR)/%.json: $(V_MODULES)
	yosys \
		-f "verilog $(foreach path,$(V_INCLUDE_PATHS),-I $(path))" \
		-p "\
			read_verilog -D ICE40_HX -lib -specify +/ice40/cells_sim.v;\
			hierarchy -check -top $*;\
			flatten;\
			proc;\
			opt -full;\
			opt_clean -purge;\
			synth_ice40 -run coarse: -json $@;\
			"\
		$^

# Place-and-route
$(OUT_DIR)/%.asc: $(OUT_DIR)/%.json $(PIN_DEF)
	nextpnr-ice40 \
		--$(DEVICE) \
		--package $(PACKAGE) \
		--json $< \
		--pcf $(PIN_DEF) \
		--log $(OUT_DIR)/$*.pnr.txt \
		--asc $(OUT_DIR)/$*.asc \
		$(NEXTPNR_FLAGS)

# Bitstream generation
$(OUT_DIR)/%.bin: $(OUT_DIR)/%.asc
	icepack -v $< $@

# Timing report (can differ from nextpnr!)
$(OUT_DIR)/%.icetime.txt: $(OUT_DIR)/%.asc
	icetime -d $(DEVICE) -mtr $@ $<

clean:
	rm -f $(foreach test,$(TESTS),$(OUT_TEST_DIR)/$(test).vcd)
	rm -f $(foreach test,$(TESTS),$(OUT_TEST_DIR)/$(test))
	rm -f $(OUT_DIR)/$(PROJ).blif $(OUT_DIR)/$(PROJ).asc $(OUT_DIR)/$(PROJ).rpt $(OUT_DIR)/$(PROJ).bin $(OUT_DIR)/$(PROJ).json
