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
        test_vector[i++] = 8'hFE;
        test_vector[i++] = 8'h01;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'hFA;
        test_vector[i++] = 8'h77;
        // CRC error
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        // Write: addr=0x12345678, asize=1byte, incr=1, bytes=5
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'b001001;
        test_vector[i++] = 8'h05;
        test_vector[i++] = 8'h78;
        test_vector[i++] = 8'h56;
        test_vector[i++] = 8'h34;
        test_vector[i++] = 8'h12;
        test_vector[i++] = 8'hCE; //crc
        // 5 bytes
        test_vector[i++] = 8'h11;
        test_vector[i++] = 8'h22;
        test_vector[i++] = 8'h33;
        test_vector[i++] = 8'h44;
        test_vector[i++] = 8'h55;
        // Read: addr=0x87654321, asize=2byte, incr=1, bytes=5
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'b101000;
        test_vector[i++] = 8'h05;
        test_vector[i++] = 8'h78;
        test_vector[i++] = 8'h56;
        test_vector[i++] = 8'h34;
        test_vector[i++] = 8'h12;
        test_vector[i++] = 8'hDC; //crc
        // some nullekes
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        // stall it
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'b000010;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h1F; //crc
        // Read: addr=0x87654321, asize=2byte, incr=1, bytes=5
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'b011000;
        test_vector[i++] = 8'h05;
        test_vector[i++] = 8'h21;
        test_vector[i++] = 8'h43;
        test_vector[i++] = 8'h65;
        test_vector[i++] = 8'h87;
        test_vector[i++] = 8'hBA; //crc
        // stall it
        test_vector[i++] = 8'hA3;
        test_vector[i++] = 8'b000010;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h00;
        test_vector[i++] = 8'h1F; //crc

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

module test_cmd_wb;
    
    localparam WB_ADDR_WIDTH = 6;
    localparam EMREQ_NUM = 2;

    `include "cmd_defines.vh"
    `include "mreq_defines.vh"

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
        .i_enable(1'b1),
        .i_ready(rx_ready),
        .o_data(rx_data),
        .o_valid(rx_valid)
    );

    wb_ctrl_port #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .NUM_EMREQS(EMREQ_NUM)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .o_err_crc(err_crc),
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
        .o_tx_valid(tx_valid),
        // EMREQs
        .i_emreqs_valid({EMREQ_NUM{1'b1}}),
        .i_emreqs({
            pack_mreq(1'b0, 1'b0, MREQ_WSIZE_VAL_4BYTE, 2, 32'hFEEDCEEF),
            pack_mreq(1'b0, 1'b0, MREQ_WSIZE_VAL_2BYTE, 3, 32'hDEADBEEF)
            })
    );

    // localparam NREQS = 3;
    // localparam IREQ_BITS = 2;

    // mreq_arbiter #(
    //     .NREQS(NREQS),
    //     .IREQ_BITS(IREQ_BITS)
    // ) arb (
    //     .i_clk(clk),
    //     .i_rst(rst),
    //     .i_mreqs_valid({1'b1, 1'b1, })
    // );

    reg clk = 0;
    reg rst = 0;
    wire err_crc;
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
        if (err_crc) begin
            $display("Rx: WB_CTRL_PORT reports CRC error");
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
        $dumpfile("test_wb_ctrl_port.vcd");
        $dumpvars(0);

        
        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (5) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);

        tx_ready <= 1;
        repeat (20) @(posedge clk);
        tx_ready <= 0;
        repeat (50) @(posedge clk);
        tx_ready <= 1;
        repeat (150) @(posedge clk);

        // It should be stalled here. Reset
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        // Continue processing
        repeat (150) @(posedge clk);


        $finish;
    end

endmodule