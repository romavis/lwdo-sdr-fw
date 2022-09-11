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
        // Command 1 - WR_AINCR
        test_vector[i++] = 8'hA3;   // CMD
        test_vector[i++] = 8'd03;   // CNT0
        test_vector[i++] = 8'd00;   // ADDR0
        test_vector[i++] = 8'hA0;   // DATA
        test_vector[i++] = 8'hA1;   // DATA
        test_vector[i++] = 8'hA2;   // DATA
        test_vector[i++] = 8'hA3;   // DATA
        test_vector[i++] = 8'hA4;   // DATA
        test_vector[i++] = 8'hA5;   // DATA
        test_vector[i++] = 8'hA6;   // DATA
        test_vector[i++] = 8'hA7;   // DATA
        test_vector[i++] = 8'hA8;   // DATA
        test_vector[i++] = 8'hA9;   // DATA
        test_vector[i++] = 8'hAA;   // DATA
        test_vector[i++] = 8'hAB;   // DATA
        test_vector[i++] = 8'hAC;   // DATA
        test_vector[i++] = 8'hAD;   // DATA
        test_vector[i++] = 8'hAE;   // DATA
        test_vector[i++] = 8'hAF;   // DATA
        // Command 2 - WR_AINCR
        test_vector[i++] = 8'hA3;   // CMD
        test_vector[i++] = 8'd00;   // CNT0
        test_vector[i++] = 8'd00;   // ADDR0
        test_vector[i++] = 8'hB0;   // DATA
        test_vector[i++] = 8'hB1;   // DATA
        test_vector[i++] = 8'hB2;   // DATA
        test_vector[i++] = 8'hB3;   // DATA
        // Command 3 - WR_FIXED
        test_vector[i++] = 8'hA1;   // CMD
        test_vector[i++] = 8'd02;   // CNT0
        test_vector[i++] = 8'd01;   // ADDR0
        test_vector[i++] = 8'hB0;   // DATA
        test_vector[i++] = 8'hB1;   // DATA
        test_vector[i++] = 8'hB2;   // DATA
        test_vector[i++] = 8'hB3;   // DATA
        test_vector[i++] = 8'hB4;   // DATA
        test_vector[i++] = 8'hB5;   // DATA
        test_vector[i++] = 8'hB6;   // DATA
        test_vector[i++] = 8'hB7;   // DATA
        test_vector[i++] = 8'hB8;   // DATA
        test_vector[i++] = 8'hB9;   // DATA
        test_vector[i++] = 8'hBA;   // DATA
        test_vector[i++] = 8'hBB;   // DATA
        // Command 4 - RD_FIXED
        test_vector[i++] = 8'hA2;   // CMD
        test_vector[i++] = 8'd01;   // CNT0
        test_vector[i++] = 8'd01;   // ADDR0
        // Command 5 - WR_AINCR
        test_vector[i++] = 8'hA3;   // CMD
        test_vector[i++] = 8'd01;   // CNT0
        test_vector[i++] = 8'd05;   // ADDR0
        test_vector[i++] = 8'hC0;   // DATA
        test_vector[i++] = 8'hC1;   // DATA
        test_vector[i++] = 8'hC2;   // DATA
        test_vector[i++] = 8'hC3;   // DATA
        test_vector[i++] = 8'hC4;   // DATA
        test_vector[i++] = 8'hC5;   // DATA
        test_vector[i++] = 8'hC6;   // DATA
        test_vector[i++] = 8'hC7;   // DATA
        // Command 6 - RD_AINCR
        test_vector[i++] = 8'hA4;   // CMD
        test_vector[i++] = 8'd07;   // CNT0
        test_vector[i++] = 8'd00;   // ADDR0
        // Garbage
        test_vector[i++] = 8'h23;
        test_vector[i++] = 8'hE0;
        test_vector[i++] = 8'h01;
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

module test_wbcon;

    localparam WB_ADDR_WIDTH = 8;
    localparam COUNT_WIDTH = 8;

    wb_mem_dly #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .STALL_WS(0),
        .ACK_WS(0)
    ) mem (
        .i_clk(clk),
        .i_rst(rst),
        // wb
        .i_wb_cyc(wb_cyc),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wb_stall),
        .o_wb_ack(wb_ack),
        .i_wb_we(wb_we),
        .i_wb_addr(wb_addr),
        .i_wb_data(wb_data_w),
        .i_wb_sel(wb_sel),
        .o_wb_data(wb_data_r)
    );

    stream_gen rx_stream (
        .i_clk(clk),
        .i_enable(rx_en),
        .i_ready(rx_ready),
        .o_data(rx_data),
        .o_valid(rx_valid)
    );

    wbcon #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH)
    ) dut (
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
        .o_rx_ready(rx_ready),
        .i_rx_data(rx_data),
        .i_rx_valid(rx_valid),
        // tx
        .i_tx_ready(tx_ready),
        .o_tx_data(tx_data),
        .o_tx_valid(tx_valid)
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
    wire [31:0] wb_data_w;
    wire [3:0] wb_sel;
    wire [31:0] wb_data_r;
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
            $display("WB: req addr=0x%0x sel=%4b we=%b wdata=0x%08x",
                wb_addr,
                wb_sel,
                wb_we,
                wb_data_w
            );
        end
        if (wb_cyc && wb_ack) begin
            $display("WB: ack rdata=0x%08x", wb_data_r);
        end
    end

    initial begin
        $dumpfile("test_wbcon.vcd");
        $dumpvars(0);

        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (5) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);

        tx_ready <= 1;
        repeat (10) @(posedge clk);
        rx_en <= 0;
        repeat (10) @(posedge clk);
        tx_ready <= 0;
        repeat (10) @(posedge clk);
        rx_en <= 1;
        repeat (50) @(posedge clk);
        tx_ready <= 1;
        repeat (150) @(posedge clk);

        $finish;
    end

endmodule
