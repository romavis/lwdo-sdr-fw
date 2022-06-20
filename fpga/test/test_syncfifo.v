`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps


module test_syncfifo;

    localparam ADDR_WIDTH = 3;
    localparam DATA_WIDTH = 8;

    syncfifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_data(wr_data),
        .o_data(rd_data),
        .i_wr(wr),
        .i_rd(rd),
        .o_count(count),
        .o_empty(empty),
        .o_full(full),
        .o_half_full(half_full),
        .o_overflow(overflow),
        .o_underflow(underflow)
    );

    reg clk = 0;
    reg rst = 0;
    reg [DATA_WIDTH-1:0] wr_data = {DATA_WIDTH-1{1'b0}};
    wire [DATA_WIDTH-1:0] rd_data;
    reg rd = 0;
    reg wr = 0;
    wire [ADDR_WIDTH-1:0] count;
    wire empty, full, half_full, overflow, underflow;

    always @(posedge clk) begin
        if (rst) begin
            $display("RESET");
        end else begin
            $display("       count: %d", count);
            if (wr) begin
                if (!overflow) begin
                    $display("WR: data 0x%x", wr_data);
                end else begin
                    $display("WR: overflow (lost 0x%x)", wr_data);
                end
            end
            if (rd) begin
                if (!underflow) begin
                    $display("RD: data 0x%x", rd_data);
                end else begin
                    $display("RD: underflow (read garbage)");
                end
            end
        end
    end

    always @(posedge empty) begin
        $display("FIFO becomes empty");
    end
    always @(posedge full) begin
        $display("FIFO becomes full");
    end
    always @(posedge half_full) begin
        $display("FIFO becomes half-full");
    end

    always #5 clk = ~clk;

    // Data generator
    always @(posedge clk) begin
        wr_data <= wr_data + {{DATA_WIDTH-1{1'b0}}, 1'b1};
    end

    initial begin
        $dumpfile("test_syncfifo.vcd");
        $dumpvars;

        
        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (5) @(posedge clk);
        rst <= 0;
        // Write some data
        wr <= 1;
        repeat (5) @(posedge clk);
        wr <= 0;
        // Read data
        rd <= 1;
        repeat (5) @(posedge clk);
        rd <= 0;
        // Make fifo full and overflow
        wr <= 1;
        repeat (10) @(posedge clk);
        wr <= 0;
        // Read all the elements and underflow
        rd <= 1;
        repeat (10) @(posedge clk);
        wr <= 0;
        // Read and write simultaneously
        wr <= 1;
        rd <= 1;
        repeat (10) @(posedge clk);
        // Make it full
        rd <= 0;
        repeat (6) @(posedge clk);
        // Read & write simultaneously
        rd <= 1;
        repeat (10) @(posedge clk);
        // Drain
        wr <= 0;
        repeat (7) @(posedge clk);
        rd <= 0;

        repeat (20) @(posedge clk);

        $finish;
    end

endmodule