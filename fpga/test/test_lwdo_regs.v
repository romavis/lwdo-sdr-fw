`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module stream_gen (
    input i_clk,
    input i_enable,

    input i_ready,
    output [7:0] o_data,
    output o_valid
);

    reg [9:0] test_vector_idx = 0;
    reg [7:0] test_vector [0:1023];

    integer i;
    initial begin
        i = 0;
        // Zero bytes
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        // Garbage
        test_vector[i++] = 8'h23;
        test_vector[i++] = 8'hE0;
        test_vector[i++] = 8'h01;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'hFA;
        test_vector[i++] = 8'h77;
        // Command 1 - READ MAGIC
        test_vector[i++] = 8'hA2;   // CMD
        test_vector[i++] = 8'd00;   // CNT0
        test_vector[i++] = 8'd00;   // ADDR0
        // Command 2 - READ EVERYTHING
        test_vector[i++] = 8'hA4;   // CMD
        test_vector[i++] = 8'hFF;   // CNT
        test_vector[i++] = 8'h00;   // ADDR
        //
        for (i = i; i < 1024; i = i + 1) begin
            test_vector[i] = 8'b0;
        end
    end

    assign o_valid = i_enable;
    assign o_data = test_vector[test_vector_idx];

    always @(posedge i_clk) begin
        if (o_valid && i_ready) begin
            // Transaction happens, increment idx
            test_vector_idx <= test_vector_idx + 10'd1;
        end
    end

endmodule

module test_lwdo_regs;

    localparam WB_ADDR_WIDTH = 8;
    localparam WB_DATA_WIDTH = 16;
    localparam WB_SEL_WIDTH = 2;
    localparam COUNT_WIDTH = 8;

    localparam WORD_SIZE = (WB_DATA_WIDTH + 7) / 8;
    localparam BYTE_ADDR_BITS = $clog2(WORD_SIZE);

    lwdo_regs #(
        .ADDRESS_WIDTH(WB_ADDR_WIDTH + BYTE_ADDR_BITS),
        .DEFAULT_READ_DATA(32'hDEAD)
    ) dut (
        .i_clk(clk),
        .i_rst_n(~rst),
        // wb
        .i_wb_cyc(wb_cyc),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wb_stall),
        .o_wb_ack(wb_ack),
        .i_wb_we(wb_we),
        .i_wb_adr({wb_addr, {BYTE_ADDR_BITS{1'b0}}}),
        .i_wb_dat(wb_data_w),
        .i_wb_sel(wb_sel),
        .o_wb_dat(wb_data_r)
        //
        // .i_adcstr1_rx_data(adcstr1_data),
        // .i_adcstr2_rx_data(adcstr2_data),
        // .o_adcstr1_rx_data_read_trigger(adcstr1_rd),
        // .o_adcstr2_rx_data_read_trigger(adcstr2_rd)
    );

    stream_gen rx_stream (
        .i_clk(clk),
        .i_enable(rx_en),
        .i_ready(rx_ready),
        .o_data(rx_data),
        .o_valid(rx_valid)
    );

    // Wishbone port Rx (incoming data)
    wire [7:0] cpstr_rx_wb_data;
    wire cpstr_rx_wb_valid;
    wire cpstr_rx_wb_ready;
    // Wishbone port Tx (outgoing data)
    wire [7:0] cpstr_tx_wb_data;
    wire cpstr_tx_wb_valid;
    wire cpstr_tx_wb_ready;
    // Dummy data generator for testing (Tx)
    wire [7:0] cpstr_tx_dummy1_data = 8'hAA;
    wire cpstr_tx_dummy1_valid = 1'b0;
    wire cpstr_tx_dummy1_ready;
    wire [7:0] cpstr_tx_dummy2_data = 8'hBB;
    wire cpstr_tx_dummy2_valid = 1'b0;
    wire cpstr_tx_dummy2_ready;

    // ----------------------------------
    // Control port stream management
    // ----------------------------------

    wire cpstr_send_stridx;

    cpstr_mgr_rx cpstr_mgr_rx (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_data(rx_data),
        .i_valid(rx_valid),
        .o_ready(rx_ready),
        //
        .o_data(cpstr_rx_wb_data),
        .o_valid(cpstr_rx_wb_valid),
        .i_ready(cpstr_rx_wb_ready),
        //
        .o_send_stridx(cpstr_send_stridx)
    );

    cpstr_mgr_tx #(
        .NUM_STREAMS(3),
        .MAX_BURST(32)
    ) cpstr_mgr_tx (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_data(tx_data),
        .o_valid(tx_valid),
        .i_ready(tx_ready),
        // (order: MSB->LSB!)
        .i_data({cpstr_tx_dummy2_data, cpstr_tx_dummy1_data, cpstr_tx_wb_data}),
        .i_valid({cpstr_tx_dummy2_valid, cpstr_tx_dummy1_valid, cpstr_tx_wb_valid}),
        .o_ready({cpstr_tx_dummy2_ready, cpstr_tx_dummy1_ready, cpstr_tx_wb_ready}),
        //
        .i_send_stridx(cpstr_send_stridx)
    );

    wbcon #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .WB_DATA_WIDTH(WB_DATA_WIDTH),
        .WB_SEL_WIDTH(WB_SEL_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH)
    ) wbcon (
        .i_clk(clk),
        .i_rst(rst),
        // wb
        .o_wb_cyc(wb_cyc),
        .o_wb_stb(wb_stb),
        .i_wb_stall(wb_stall),
        .i_wb_ack(wb_ack),
        .o_wb_we(wb_we),
        .o_wb_addr(wb_addr),
        .o_wb_data(wb_data_w),
        .o_wb_sel(wb_sel),
        .i_wb_data(wb_data_r),
        // rx
        .i_rx_data(cpstr_rx_wb_data),
        .i_rx_valid(cpstr_rx_wb_valid),
        .o_rx_ready(cpstr_rx_wb_ready),
        // tx
        .o_tx_data(cpstr_tx_wb_data),
        .o_tx_valid(cpstr_tx_wb_valid),
        .i_tx_ready(cpstr_tx_wb_ready)
    );

    reg clk = 0;
    reg rst = 0;
    reg rx_en = 1;
    // wb
    wire wb_cyc;
    wire wb_stb;
    wire wb_stall;
    wire wb_ack;
    wire wb_we;
    wire [WB_ADDR_WIDTH-1:0] wb_addr;
    wire [WB_DATA_WIDTH-1:0] wb_data_w;
    wire [WB_SEL_WIDTH-1:0] wb_sel;
    wire [WB_DATA_WIDTH-1:0] wb_data_r;
    // rx stream
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_ready;
    // tx stream
    wire [7:0] tx_data;
    wire tx_valid;
    reg tx_ready = 0;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rx_valid && rx_ready) begin
            $display("Rx: 0x%02x", rx_data);
        end
        if (tx_valid && tx_ready) begin
            $display("Tx:     0x%02x", tx_data);
        end
        if (wb_cyc && wb_stb && !wb_stall) begin
            $display("WB: req addr=0x%0x sel=%4b we=%b wdata=0x%04x",
                wb_addr,
                wb_sel,
                wb_we,
                wb_data_w
            );
        end
        if (wb_cyc && wb_ack) begin
            $display("WB: ack rdata=0x%04x", wb_data_r);
        end
    end

    initial begin
        $dumpfile("test_lwdo_regs.vcd");
        $dumpvars(0);

        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (5) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);

        tx_ready <= 1;
        repeat (1600) @(posedge clk);

        $finish;
    end

endmodule
