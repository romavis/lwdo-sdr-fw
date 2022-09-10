
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

module test_cpstr_desc;
    reg clk = 0;
    reg rst = 0;
    reg en = 0;

    wire [7:0] src_data;
    wire src_valid;
    wire src_ready;

    wire [7:0] dst_data;
    wire dst_valid;
    reg dst_ready = 0;

    wire [7:0] esc_data;
    wire esc_valid;
    reg esc_ready = 0;

    reg send_esc = 0;

    stream_gen gen (
        .i_clk(clk),
        .i_enable(en),
        .i_ready(src_ready),
        .i_send_esc(send_esc),
        .o_data(src_data),
        .o_valid(src_valid)
    );

    cpstr_desc dut (
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
        .o_esc_valid(esc_valid),
        .o_esc_data(esc_data),
        .i_esc_ready(esc_ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (src_valid && src_ready) begin
            $display("SRC: 0x%02x", src_data);
        end
        if (dst_valid && dst_ready) begin
            $display("DST:    0x%02x", dst_data);
        end
        if (esc_valid && esc_ready) begin
            $display("ESC:       0x%02x", dst_data);
        end
    end

    initial begin
        $dumpfile("test_cpstr_desc.vcd");
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
        esc_ready <= 1;
        repeat (5) @(posedge clk);
        // Stall
        dst_ready <= 0;
        repeat (2) @(posedge clk);
        // Unstall
        dst_ready <= 1;
        repeat (4) @(posedge clk);
        // generate 4 esc chars
        send_esc <= 1;
        @(posedge clk); while(!(src_ready && src_valid)) @(posedge clk);
        @(posedge clk); while(!(src_ready && src_valid)) @(posedge clk);
        @(posedge clk); while(!(src_ready && src_valid)) @(posedge clk);
        @(posedge clk); while(!(src_ready && src_valid)) @(posedge clk);
        // some normal bytes
        send_esc <= 0;
        repeat (4) @(posedge clk);
        // generate one esc char + normal byte
        send_esc <= 1;
        @(posedge clk); while(!(src_ready && src_valid)) @(posedge clk);
        send_esc <= 0;
        @(posedge clk);
        send_esc <= 1;
        @(posedge clk); while(!(src_ready && src_valid)) @(posedge clk);
        send_esc <= 0;
        esc_ready <= 0;
        repeat (5) @(posedge clk);
        esc_ready <= 1;
        repeat (5) @(posedge clk);

        $finish;
    end

endmodule
