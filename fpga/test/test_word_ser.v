
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module stream_gen #(
    parameter WORD_BITS = 32,
    parameter [WORD_BITS-1:0] INIT_VAL = 0
) (
    input i_clk,
    input i_enable,

    output [WORD_BITS-1:0] o_data,
    output o_valid,
    input i_ready
);

    reg [WORD_BITS-1:0] d = INIT_VAL;

    assign o_valid = i_enable;
    assign o_data = d;

    always @(posedge i_clk) begin
        if (o_valid && i_ready) begin
            d <= {d[WORD_BITS-2:0], d[WORD_BITS-1]} + 1'd1;
        end
    end

endmodule

module test_word_ser;
    localparam WORD_BITS = 32;
    localparam INIT_VAL = 32'hAABBCCDD;

    reg clk = 0;
    reg rst = 0;
    reg en = 0;

    wire [WORD_BITS-1:0] data_in;
    wire [7:0] data_out;
    wire valid_in;
    wire valid_out;
    reg ready_in = 0;
    wire ready_out;

    stream_gen #(
        .WORD_BITS(WORD_BITS),
        .INIT_VAL(INIT_VAL)
    ) stream_gen (
        .i_clk(clk),
        .i_enable(en),
        .i_ready(ready_out),
        .o_data(data_in),
        .o_valid(valid_in)
    );

    word_ser word_ser (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_data(data_in),
        .i_valid(valid_in),
        .o_ready(ready_out),
        //
        .o_data(data_out),
        .o_valid(valid_out),
        .i_ready(ready_in)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (ready_in && valid_out) begin
            $display("slave received %0x", data_out);
        end
        if (valid_in && ready_out) begin
            $display("master sent %0x", data_in);
        end
    end

    initial begin
        $dumpfile("test_word_ser.vcd");
        $dumpvars(0);

        repeat (1) @(posedge clk);
        rst <= 1;
        repeat (1) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);
        en <= 1;
        repeat (10) @(posedge clk);
        ready_in <= 1;
        repeat (33) @(posedge clk);
        ready_in <= 0;
        repeat (10) @(posedge clk);
        ready_in <= 1;
        repeat (2) @(posedge clk);
        ready_in <= 0;
        repeat (10) @(posedge clk);
        ready_in <= 1;
        repeat (20) @(posedge clk);
        en <= 0;
        repeat (10) @(posedge clk);
        ready_in <= 0;
        repeat (5) @(posedge clk);
        en <= 1;
        repeat (5) @(posedge clk);
        ready_in <= 1;
        repeat (20) @(posedge clk);
        ready_in <= 0;
        repeat (5) @(posedge clk);
        en <= 0;
        ready_in <= 1;
        repeat (5) @(posedge clk);
        $finish;
    end

endmodule
