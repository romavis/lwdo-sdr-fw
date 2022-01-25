# Makefile template borrowed from https://gist.github.com/DurandA/15c83f37ee64b185801f88fbe0a0f25c

OUT_DIR = out
SRC_DIR = .

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
	$(SRC_DIR)/ft245sync.v \
	$(SRC_DIR)/stream_buf.v \
	$(SRC_DIR)/crc8.v \
	$(SRC_DIR)/cmd_rx.v \
	$(SRC_DIR)/cmd_tx.v \
	$(SRC_DIR)/cmd_wb.v \
	$(SRC_DIR)/wb_ft245sync.v \
	$(SRC_DIR)/wb_mem.v \
	$(SRC_DIR)/wb_dummy.v


$(OUT_DIR)/top.json: $(V_MODULES)
	yosys -p 'synth_ice40 -top $(PROJ) -json $@' $^

$(OUT_DIR)/%.asc: $(OUT_DIR)/%.json $(PIN_DEF)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --json $< --pcf $(PIN_DEF) --asc $@ $(NEXTPNR_EXTRA)

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
	rm -f $(OUT_DIR)/$(PROJ).blif $(OUT_DIR)/$(PROJ).asc $(OUT_DIR)/$(PROJ).rpt $(OUT_DIR)/$(PROJ).bin
