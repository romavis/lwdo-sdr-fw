
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module stream_gen (
    input i_clk,
    input i_enable,

    input i_ready,
    output [7:0] o_data,
    output o_valid
);

    reg [7:0] d;

    assign o_valid = i_enable;
    assign o_data = d;

    initial begin
        d <= 8'd0;
    end

    always @(posedge i_clk) begin
        if (o_valid && i_ready) begin
            // Transaction happens, increment data
            d <= d + 8'd1;
        end
    end

endmodule

module test_stream_buf;
    reg clk = 0;
    reg rst = 0;
    reg en = 0;
  
    wire [7:0] data_in;
    wire [7:0] data_out;
    wire valid_in;
    wire valid_out;
    reg ready_in = 0;
    wire ready_out;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (ready_in && valid_out) begin
            $display("slave received %d", data_out);
        end
        if (valid_in && ready_out) begin
            $display("master sent %d", data_in);
        end
    end

    initial begin
        $dumpfile("test_stream_buf.vcd");
        $dumpvars(0);

        $monitor(,$time,"  en=%b,valid_in=%b,ready_out=%b,valid_out=%b,ready_in=%b",en,valid_in,ready_out,valid_out,ready_in);

        repeat (5) @(posedge clk);
        #3
        rst <= 1;
        repeat (1) @(posedge clk);
        #3
        rst <= 0;
        repeat (5) @(posedge clk);
        #3
        en <= 1;
        repeat (5) @(posedge clk);
        #3
        ready_in <= 1;
        repeat (5) @(posedge clk);
        #3
        ready_in <= 0;
        repeat (5) @(posedge clk);
        #3
        ready_in <= 1;
        repeat (5) @(posedge clk);
        #3
        ready_in <= 0;
        repeat (5) @(posedge clk);
        #3
        ready_in <= 1;
        repeat (5) @(posedge clk);
        #3
        en <= 0;
        repeat (5) @(posedge clk);
        #3
        ready_in <= 0;
        repeat (5) @(posedge clk);
        #3
        en <= 1;
        repeat (5) @(posedge clk);
        #3
        ready_in <= 1;
        repeat (5) @(posedge clk);
        #3
        ready_in <= 0;
        repeat (5) @(posedge clk);
        #3
        en <= 0;
        ready_in <= 1;
        repeat (5) @(posedge clk);
        $finish;
    end
  
    stream_gen gen (
        .i_clk(clk),
        .i_enable(en),
        .i_ready(ready_out),
        .o_data(data_in),
        .o_valid(valid_in)
    );

    wire [7:0] t12_data;
    wire t12_valid;
    wire t12_ready;

    stream_buf dut1 (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_data(data_in),
        .i_valid(valid_in),
        .o_ready(ready_out),
        //
        .o_data(t12_data),
        .o_valid(t12_valid),
        .i_ready(t12_ready)
    );

    stream_buf dut2 (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_data(t12_data),
        .i_valid(t12_valid),
        .o_ready(t12_ready),
        //
        .o_data(data_out),
        .o_valid(valid_out),
        .i_ready(ready_in)
    );

endmodule
