
`timescale 1 ns/100 ps

module stream_gen (
    input i_clk,
    input i_enable,

    input i_ready,
    output [7:0] o_data,
    output o_valid
);

    reg [7:0] d;

    assign o_valid = i_enable;
    assign o_data =
        (d[2:0] < 5) ? (d + 1) : 8'd27;
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

module test_cpstr_esc;
    reg clk = 0;
    reg rst = 0;
    reg en = 0;

    wire [7:0] src_data;
    wire src_valid;
    wire src_ready;

    wire [7:0] dst_data;
    wire dst_valid;
    reg dst_ready = 0;

    reg [7:0] esc_data = 0;
    reg esc_valid = 0;
    wire esc_ready;

    stream_gen gen (
        .i_clk(clk),
        .i_enable(en),
        .i_ready(src_ready),
        .o_data(src_data),
        .o_valid(src_valid)
    );

    cpstr_esc dut (
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
        .i_esc_valid(esc_valid),
        .i_esc_data(esc_data),
        .o_esc_ready(esc_ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (src_valid && src_ready) begin
            $display("SRC: 0x%02x", src_data);
        end
        if (esc_valid && esc_ready) begin
            $display("ESC:       0x%02x", esc_data);
        end
        if (dst_valid && dst_ready) begin
            $display("DST:    0x%02x", dst_data);
        end
    end

    initial begin
        $dumpfile("test_cpstr_esc.vcd");
        $dumpvars;

        repeat (5) @(posedge clk);
        rst <= 1;
        repeat (1) @(posedge clk);
        rst <= 0;
        // Pass
        repeat (2) @(posedge clk);
        en <= 1;
        repeat (2) @(posedge clk);
        dst_ready <= 1;
        repeat (5) @(posedge clk);
        // Stall
        dst_ready <= 0;
        repeat (2) @(posedge clk);
        // Unstall
        dst_ready <= 1;
        repeat (4) @(posedge clk);
        // Esc
        esc_data <= 8'hBE;
        esc_valid <= 1;
        @(posedge clk); while(!esc_ready) @(posedge clk);
        esc_valid <= 0;
        repeat (3) @(posedge clk);
        // Esc with stall
        repeat (2) @(posedge clk);
        esc_valid <= 1;
        repeat (1) @(posedge clk);
        dst_ready <= 0;
        repeat (2) @(posedge clk);
        dst_ready <= 1;
        @(posedge clk); while(!esc_ready) @(posedge clk);
        esc_valid <= 0;
        dst_ready <= 0;
        repeat (2) @(posedge clk);
        dst_ready <= 1;
        repeat (5) @(posedge clk);
        // Stall
        dst_ready <= 0;
        repeat (5) @(posedge clk);
        dst_ready <= 1;
        repeat (5) @(posedge clk);
        en <= 0;
        // End
        repeat (5) @(posedge clk);
        $finish;
    end

endmodule
