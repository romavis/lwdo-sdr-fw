# Makefile template borrowed from https://gist.github.com/DurandA/15c83f37ee64b185801f88fbe0a0f25c

OUT_DIR = ./out
OUT_TEST_DIR = $(OUT_DIR)/test
SRC_DIR = .
TEST_DIR = $(SRC_DIR)/test

PNRGUI ?= 0
PROJ = top
PIN_DEF = $(SRC_DIR)/top.pcf
DEVICE = hx4k
PACKAGE = tq144

NEXTPNR_EXTRA =
ifeq ($(PNRGUI), 1)
	NEXTPNR_EXTRA += --gui
endif

all: $(OUT_DIR)/$(PROJ).bin

.SECONDARY:

V_MODULES := \
	$(SRC_DIR)/top.v \
	$(SRC_DIR)/ad7357if.v \
	$(SRC_DIR)/dac8551.v \
	$(SRC_DIR)/ft245sync.v \
	$(SRC_DIR)/stream_buf.v \
	$(SRC_DIR)/syncfifo.v \
	$(SRC_DIR)/crc8.v \
	$(SRC_DIR)/fastcounter.v \
	$(SRC_DIR)/cmd_rx.v \
	$(SRC_DIR)/cmd_tx.v \
	$(SRC_DIR)/cmd_wb.v \
	$(SRC_DIR)/mreq_seq2.v \
	$(SRC_DIR)/mreq_arbiter.v \
	$(SRC_DIR)/wb_ctrl_port.v \
	$(SRC_DIR)/wb_mem.v \
	$(SRC_DIR)/wb_mem_dly.v \
	$(SRC_DIR)/wb_rxfifo.v \
	$(SRC_DIR)/wb_dummy.v \
	$(SRC_DIR)/wb_mux.v


V_INCLUDE_PATHS := \
	$(SRC_DIR)

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

# 3rdparty verilog modules: verilog-wishbone
V_MODULES += \
	$(SRC_DIR)/3rdparty/verilog-wishbone/rtl/arbiter.v \
	$(SRC_DIR)/3rdparty/verilog-wishbone/rtl/priority_encoder.v \
	$(SRC_DIR)/3rdparty/verilog-wishbone/rtl/wb_reg.v

V_INCLUDE_PATHS += \
	$(SRC_DIR)/3rdparty/verilog-wishbone/rtl

# Tests
TESTS := \
	test_syncfifo \
	test_cmd_wb \
	test_cmd_tx \
	test_cmd_rx \
	test_wb_ctrl_port \
	test_wb_rxfifo \
	test_dac8551 \
	test_fastcounter

# Directories
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(OUT_TEST_DIR):
	mkdir -p $(OUT_TEST_DIR)

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

# Bitstream
$(OUT_DIR)/top.json: $(V_MODULES)
	yosys -p 'synth_ice40 -top $(PROJ) -json $@' $^

$(OUT_DIR)/%.asc: $(OUT_DIR)/%.json $(PIN_DEF)
	nextpnr-ice40 --randomize-seed --$(DEVICE) --package $(PACKAGE) --json $< --pcf $(PIN_DEF) --asc $@ $(NEXTPNR_EXTRA)

$(OUT_DIR)/%.bin: $(OUT_DIR)/%.asc
	icepack -v $< $@

$(OUT_DIR)/%.rpt: $(OUT_DIR)/%.asc
	icetime -d $(DEVICE) -mtr $@ $<

$(OUT_DIR)/%_tb: $(OUT_DIR)/%_tb.v $(SRC_DIR)/%.v
	iverilog -o $@ $^

$(OUT_DIR)/%_tb.vcd: $(OUT_DIR)/%_tb
	vvp -N $< +vcd=$@

$(OUT_DIR)/%_syn.v: $(OUT_DIR)/%.blif
	yosys -p 'read_blif -wideports $^; write_verilog $@'

$(OUT_DIR)/%_syntb: $(OUT_DIR)/%_tb.v $(OUT_DIR)/%_syn.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

$(OUT_DIR)/%_syntb.vcd: $(OUT_DIR)/%_syntb
	vvp -N $< +vcd=$@

clean:
	rm -f $(foreach test,$(TESTS),$(OUT_TEST_DIR)/$(test).vcd)
	rm -f $(foreach test,$(TESTS),$(OUT_TEST_DIR)/$(test))
	rm -f $(OUT_DIR)/$(PROJ).blif $(OUT_DIR)/$(PROJ).asc $(OUT_DIR)/$(PROJ).rpt $(OUT_DIR)/$(PROJ).bin $(OUT_DIR)/$(PROJ).json
