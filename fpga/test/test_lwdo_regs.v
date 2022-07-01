`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps


module test_lwdo_regs;

    localparam WB_ADDR_WIDTH = 8;

    lwdo_regs #(
        .ADDRESS_WIDTH(WB_ADDR_WIDTH + 2),
        .DEFAULT_READ_DATA(32'hDEADBEEF)
    ) dut (
        .i_clk(clk),
        .i_rst_n(~rst),
        // wb
        .i_wb_cyc(wb_cyc),
        .i_wb_stb(wb_stb),
        .o_wb_stall(wb_stall),
        .o_wb_ack(wb_ack),
        .i_wb_we(wb_we),
        .i_wb_adr({wb_addr, 2'b0}),
        .i_wb_dat(wb_data_w),
        .i_wb_sel(wb_sel),
        .o_wb_dat(wb_data_r),
        //
        .i_adcstr1_rx_data(adcstr1_data),
        .i_adcstr2_rx_data(adcstr2_data),
        .o_adcstr1_rx_data_read_trigger(adcstr1_rd),
        .o_adcstr2_rx_data_read_trigger(adcstr2_rd)
    );

    reg clk = 0;
    reg rst = 0;
    reg wb_cyc = 0;
    reg wb_stb = 0;
    wire wb_stall;
    wire wb_ack;
    reg wb_we = 0;
    reg [WB_ADDR_WIDTH-1:0] wb_addr = 30'd0;
    reg [31:0] wb_data_w = 32'd0;
    reg [3:0] wb_sel = 4'd0;
    wire [31:0] wb_data_r;

    always #5 clk = ~clk;

    wire wb_req_ack;
    wire wb_resp_ack;
    assign wb_req_ack = wb_cyc && wb_stb && !wb_stall;
    assign wb_resp_ack = wb_cyc && wb_ack;


    task wb_single_transaction;
        begin
            wb_stb <= 1;
            @(posedge clk) while(!wb_req_ack) @(posedge clk);
            wb_stb <= 0;
            @(posedge clk) while(!wb_resp_ack) @(posedge clk);
        end
    endtask

    // Simulate ADC FIFOs
    wire adcstr1_rd, adcstr2_rd;
    reg [31:0] adcstr1_data, adcstr2_data;

    always @(posedge clk) begin
        if (rst) begin
            adcstr1_data <= 32'hABCD0000;
            adcstr2_data <= 32'hEFFA0000;
        end else begin
            if (adcstr1_rd)
                adcstr1_data <= adcstr1_data + 32'd1;
            if (adcstr2_rd)
                adcstr2_data <= adcstr2_data + 32'd1;
        end
    end

    initial begin
        $dumpfile("test_wb_regs.vcd");
        $dumpvars(0);


        @(posedge clk);
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        // Raise cyc
        wb_cyc <= 1;
        repeat (5) @(posedge clk);

        // Read magic
        wb_addr <= 'h00;
        wb_we <= 0;
        wb_single_transaction();

        // Write magic
        wb_addr <= 'h00;
        wb_sel <= 4'b1111;
        wb_data_w <= 32'h00000000;
        wb_we <= 1;
        wb_single_transaction();
        wb_we <= 0;

        // Read reset
        wb_addr <= 'h01;
        wb_single_transaction();

        // Write reset
        wb_addr <= 'h01;
        wb_sel <= 4'b1111;
        wb_data_w <= 32'h00000001;
        wb_we <= 1;
        wb_single_transaction();
        wb_we <= 0;

        // Read reset
        wb_addr <= 'h01;
        wb_single_transaction();

        // Read adcstr1
        repeat (5) begin
            wb_addr <= 'h02;
            wb_single_transaction();
        end

        // Read adcstr2
        repeat (5) begin
            wb_addr <= 'h03;
            wb_single_transaction();
        end

        // Read unmapped
        wb_addr <= 'hFE;
        wb_single_transaction();

        // Reset
        rst <= 1;
        @(posedge clk);
        rst <= 0;

        // Terminate cycle
        wb_cyc <= 0;
        repeat (10) @(posedge clk);

        $finish;
    end

endmodule
