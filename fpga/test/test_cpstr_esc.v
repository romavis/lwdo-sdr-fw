
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

    reg [7:0] emit_data = 0;
    reg emit_valid = 0;
    wire emit_ready;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (src_valid && src_ready) begin
            $display("SRC: 0x%02x", src_data);
        end
        if (dst_valid && dst_ready) begin
            $display("DST:     0x%02x", dst_data);
        end
        if (emit_valid && emit_ready) begin
            $display("EMIT:        0x%02x", dst_data);
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
        // Emit
        emit_data <= 8'hBE;
        emit_valid <= 1;
        @(posedge clk); wait(emit_ready) @(posedge clk);
        emit_valid <= 0;
        repeat (3) @(posedge clk);
        // Emit with stall
        repeat (2) @(posedge clk);
        emit_valid <= 1;
        repeat (1) @(posedge clk);
        dst_ready <= 0;
        repeat (2) @(posedge clk);
        dst_ready <= 1;
        @(posedge clk); wait(emit_ready) @(posedge clk);
        emit_valid <= 0;
        dst_ready <= 0;
        repeat (2) @(posedge clk);
        dst_ready <= 1;
        repeat (5) @(posedge clk);
        // End
        dst_ready <= 0;
        repeat (5) @(posedge clk);
        $finish;
    end

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
        .i_emit_valid(emit_valid),
        .i_emit_data(emit_data),
        .o_emit_ready(emit_ready)
    );

endmodule
