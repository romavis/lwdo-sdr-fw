`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps


module test_wb_mem;

    localparam WB_ADDR_WIDTH = 6;

    wb_mem #(
        .WB_ADDR_WIDTH(WB_ADDR_WIDTH),
        .STALL_WS(0),
        .ACK_WS(0),
    ) dut (
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
        .o_wb_data(wb_data_r),
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

    initial begin
        $dumpfile("test_wb_mem.vcd");
        $dumpvars(0);

        
        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (5) @(posedge clk);
        rst <= 0;
        // Raise cyc
        wb_cyc <= 1;
        repeat (5) @(posedge clk);
        // Write something
        wb_addr <= WB_ADDR_WIDTH'd15;
        wb_we <= 1;
        wb_data_w <= 32'hAABBCCDD;
        wb_sel <= 4'b0001;
        wb_stb <= 1;

        @(posedge clk); wait(wb_req_ack) @(posedge clk);
        @(posedge clk); wait(wb_resp_ack) @(posedge clk);

        // Write something again 
        wb_data_w <= 32'h11223344;
        wb_sel <= 4'b0011;
        
        @(posedge clk); wait(wb_req_ack) @(posedge clk);
        @(posedge clk); wait(wb_resp_ack) @(posedge clk);

        // Remove stb
        wb_stb <= 0;
        repeat (5) @(posedge clk);
        // Write something again
        wb_stb <= 1;
        wb_addr <= WB_ADDR_WIDTH'd16;
        wb_data_w <= 32'h87654321;
        wb_sel <= 4'b1111;
        
        @(posedge clk); wait(wb_req_ack) @(posedge clk);
        @(posedge clk); wait(wb_resp_ack) @(posedge clk);

        // Read
        wb_we <= 0;
        wb_addr <= WB_ADDR_WIDTH'd15;
        
        @(posedge clk); wait(wb_req_ack) @(posedge clk);
        @(posedge clk); wait(wb_resp_ack) @(posedge clk);

        // Read
        wb_addr <= WB_ADDR_WIDTH'd16;
        
        @(posedge clk); wait(wb_req_ack) @(posedge clk);
        @(posedge clk); wait(wb_resp_ack) @(posedge clk);

        // Terminate cycle
        wb_cyc <= 0;
        repeat (10) @(posedge clk);

        $finish;
    end

endmodule