`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps


module stream_gen (
    input i_clk,
    input i_enable,

    input i_ready,
    output [31:0] o_data,
    output o_valid
);

    reg [31:0] d;

    assign o_valid = i_enable;
    assign o_data = d;

    initial begin
        d <= 32'd0;
    end

    always @(posedge i_clk) begin
        if (o_valid && i_ready) begin
            // Transaction happens, increment data
            d <= d + 32'd1;
        end
    end

endmodule

module test_wb_rxfifo;

    localparam FIFO_ADDR_WIDTH = 3;

    wb_rxfifo #(
        .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        // wb
        .i_wb_cyc(wb_cyc),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wb_stall),
        .o_wb_ack(wb_ack),
        .i_wb_we(wb_we),
        .o_wb_data(wb_data_r),
        // rx stream
        .i_rx_valid(rx_valid),
        .o_rx_ready(rx_ready),
        .i_rx_data(rx_data),
        // fifo status
        .o_fifo_count(fifo_count),
        .o_fifo_empty(fifo_empty),
        .o_fifo_full(fifo_full),
        .o_fifo_half_full(fifo_half_full),
        .o_fifo_overflow(fifo_overflow),
        .o_fifo_underflow(fifo_underflow)
    );

    stream_gen sgen (
        .i_clk(clk),
        .i_enable(rx_enable),
        .i_ready(rx_ready),
        .o_valid(rx_valid),
        .o_data(rx_data)
    );

    reg clk = 0;
    reg rst = 0;
    //
    reg wb_cyc = 0;
    reg wb_stb = 0;
    wire wb_stall;
    wire wb_ack;
    reg wb_we = 0;
    wire [31:0] wb_data_r;
    //
    reg rx_enable = 1;
    wire rx_ready;
    wire rx_valid;
    wire [7:0] rx_data;
    //
    wire [FIFO_ADDR_WIDTH-1:0] fifo_count;
    wire fifo_empty, fifo_full, fifo_half_full, fifo_overflow, fifo_underflow;
    //


    wire wb_req_ack;
    wire wb_resp_ack;
    assign wb_req_ack = wb_cyc && wb_stb && !wb_stall;
    assign wb_resp_ack = wb_cyc && wb_ack;

    always @(posedge clk) begin
        if (rst) begin
            $display("RESET");
        end else begin
            $display("       FIFO count: %d", fifo_count);
            if (fifo_overflow) begin
                $display("FIFO: OVERFLOW");
            end
            if (fifo_underflow) begin
                $display("FIFO: UNDERFLOW");
            end
            if (rx_valid && rx_ready) begin
                $display("Rx: 0x%02x", rx_data);
            end
            if (wb_req_ack) begin
                $display("WB: req we=%b", wb_we);
            end
            if (wb_resp_ack) begin
                $display("WB: ack rdata=0x%08x", wb_data_r);
            end
        end
    end

    always @(posedge fifo_empty) begin
        $display("FIFO becomes empty");
    end
    always @(posedge fifo_full) begin
        $display("FIFO becomes full");
    end
    always @(posedge fifo_half_full) begin
        $display("FIFO becomes half-full");
    end


    always #5 clk = ~clk;

    task wb_single_transaction();
        begin
            wb_stb <= 1;
            @(posedge clk) while(!wb_req_ack) @(posedge clk);
            wb_stb <= 0;
            @(posedge clk) while(!wb_resp_ack) @(posedge clk);
        end
    endtask

    integer i;
    initial begin
        $dumpfile("test_wb_rxfifo.vcd");
        $dumpvars;

        
        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (5) @(posedge clk);
        rst <= 0;
        // Raise cyc
        wb_cyc <= 1;
        repeat (5) @(posedge clk);
        // Write something
        wb_we <= 1;
        wb_stb <= 1;

        wb_single_transaction();

        // Remove stb
        wb_stb <= 0;
        repeat (5) @(posedge clk);
        // Read
        wb_stb <= 1;
        wb_we <= 0;
        
        for(i = 0; i < 10; i = i+1) begin
            wb_single_transaction();
        end

        // Terminate cycle
        wb_cyc <= 0;
        repeat (10) @(posedge clk);

        $finish;
    end

endmodule