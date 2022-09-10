
`timescale 1 ns/100 ps

module stream_gen (
    input i_clk,
    input i_enable,
    input i_send_esc,

    input i_ready,
    output [7:0] o_data,
    output o_valid
);

    reg [7:0] d;

    assign o_valid = i_enable;
    assign o_data = i_send_esc ? 8'd27 : d;

    initial begin
        d <= 8'd0;
    end

    always @(posedge i_clk) begin
        if (o_valid && i_ready) begin
            // Transaction happens, increment
            d <= d + 8'd1;
        end
    end

endmodule

module test_cpstr_mgr_tx;
    stream_gen gen1 (
        .i_clk(clk),
        .i_enable(en[0]),
        .i_send_esc(send_esc),
        .i_ready(src_ready[0]),
        .o_data(src_data[0 +: 8]),
        .o_valid(src_valid[0])
    );

    stream_gen gen2 (
        .i_clk(clk),
        .i_enable(en[1]),
        .i_send_esc(send_esc),
        .i_ready(src_ready[1]),
        .o_data(src_data[8 +: 8]),
        .o_valid(src_valid[1])
    );

    stream_gen gen3 (
        .i_clk(clk),
        .i_enable(en[2]),
        .i_send_esc(send_esc),
        .i_ready(src_ready[2]),
        .o_data(src_data[16 +: 8]),
        .o_valid(src_valid[2])
    );

    cpstr_mgr_tx #(
        .NUM_STREAMS(3),
        .MAX_BURST(4)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_data(src_data),
        .i_valid(src_valid),
        .o_ready(src_ready),
        //
        .o_data(dst_data),
        .o_valid(dst_valid),
        .i_ready(dst_ready),
        //
        .i_send_stridx(send_stridx)
    );

    reg clk = 0;
    reg rst = 0;
    reg send_esc = 0;
    reg [2:0] en = 0;

    wire [23:0] src_data;
    wire [2:0] src_valid;
    wire [2:0] src_ready;

    wire [7:0] dst_data;
    wire dst_valid;
    reg dst_ready = 0;

    reg send_stridx = 0;

    always #5 clk = ~clk;

    integer i;
    genvar jj;
    generate
        for (jj = 0; jj < 3; jj = jj + 1) begin
            always @(posedge en[jj])
                $display("ENABLE %1d", jj);
            always @(negedge en[jj])
                $display("DISABLE %1d", jj);
        end
    endgenerate

    always @(posedge clk) begin
        for (i = 0; i < 3; i=i+1) begin
            if (src_valid[i] && src_ready[i]) begin
                $display("SRC %1d: 0x%02x", i, src_data[8*i +: 8]);
            end
        end
        if (dst_valid && dst_ready) begin
            $display("DST:       0x%02x", dst_data);
        end
    end

    initial begin
        $dumpfile("test_cpstr_mgr_tx.vcd");
        $dumpvars;

        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (1) @(posedge clk);
        rst <= 0;
        // activate str 0
        en[0] <= 1;
        repeat (4) @(posedge clk);
        dst_ready <= 1;
        repeat (10) @(posedge clk);
        // activate str 1, check arbitrage
        en[1] <= 1;
        repeat (40) @(posedge clk);
        // activate str 2, check arbitrage
        en[2] <= 1;
        repeat (44) @(posedge clk);
        dst_ready <= 0;
        repeat (10) @(posedge clk);
        dst_ready <= 1;
        repeat (6) @(posedge clk);
        // deactivate all, activate 1
        en <= 0;
        en[1] <= 1;
        repeat (10) @(posedge clk);
        // deactivate all, activate 1 with delay
        en <= 0;
        repeat (5) @(posedge clk);
        en[1] <= 1;
        // wait for ESC_CHAR and then disable stream
        @(posedge clk);
        while(!(src_valid[1] && src_ready[1] && src_data[8+:8] == 8'd27))
            @(posedge clk);
        // deactivate 1, enable 2
        en <= 0;
        en[2] <= 1;
        repeat (20) @(posedge clk);
        // deactivate 2, enable 1
        en <= 0;
        en[1] <= 1;
        repeat (10) @(posedge clk);
        // send strind in the middle of the stream
        send_stridx <= 1'b1;
        @(posedge clk);
        send_stridx <= 1'b0;
        repeat (10) @(posedge clk);
        // activate 2 for one byte
        en[2] <= 1;
        @(posedge clk); while(!(src_valid[2] & src_ready[2])) @(posedge clk);
        // activate 0 for one byte
        en <= 0;
        en[0] <= 1;
        @(posedge clk); while(!(src_valid[0] & src_ready[0])) @(posedge clk);
        // deactivate
        en <= 0;
        repeat (10) @(posedge clk);

        $finish;
    end

endmodule
