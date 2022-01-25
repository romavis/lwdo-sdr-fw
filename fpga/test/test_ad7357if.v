
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module ad7357if_mock (
  input sclk,
  input cs_n,
  input [13:0] data_a,
  input [13:0] data_b,
  output sdata_a,
  output sdata_b
);
  reg in_conversion = 0;
  reg [4:0] clock_idx = 'd0;
  wire second_data = ~clock_idx[4];
  wire [3:0] bit_idx = clock_idx[3:0];
  
  always @(cs_n) begin
    if(!cs_n) begin
      in_conversion <= 1;
      clock_idx <= 'd31;
    end else begin
      in_conversion <= 0;
    end
  end
  
  always @(negedge sclk) begin
    if (in_conversion) begin
      clock_idx <= clock_idx - 1;
      if (clock_idx == 'd0) begin
        in_conversion <= 0;
      end
    end
  end
  
  assign sdata_a = in_conversion ? (bit_idx > 'd13 ? 'b0 : (second_data ? data_b[bit_idx] : data_a[bit_idx])) : 'bx;
  assign sdata_b = in_conversion ? (bit_idx > 'd13 ? 'b0 : (second_data ? data_a[bit_idx] : data_b[bit_idx])) : 'bx;
endmodule

module test_ad7357if;
  reg clk = 0;
  reg rst = 0;
  reg acq = 0;
  wire ready;
  wire [13:0] sample_a;
  wire [13:0] sample_b;
  wire if_sclk;
  wire if_cs_n;
  wire if_sdata_a;
  wire if_sdata_b;
  
  reg [13:0] test_data_a = 'h2345;
  reg [13:0] test_data_b = 'h1234;
  localparam period = 20;  
  
  always #5 clk = ~clk;
  
  initial begin
    $dumpfile("test_ad7357if.vcd");
    $dumpvars(0);

    repeat (5) @(posedge clk);
    #3
    rst <= 1;
    repeat (1) @(posedge clk);
    #3
    rst <= 0;
    repeat (5) @(posedge clk);
    #3
    acq <= 1;
    repeat (2) @(posedge clk);
    #3
    acq <= 0;
    repeat (40) @(posedge clk);
    $finish;
  end
  
  ad7357if adc_if (
    .i_clk(clk),
    .i_rst(rst),
    .i_acquire(acq),
    .o_ready(ready),
    .o_sample_a(sample_a),
    .o_sample_b(sample_b),
    .o_if_sclk(if_sclk),
    .o_if_cs_n(if_cs_n),
    .i_if_sdata_a(if_sdata_a),
    .i_if_sdata_b(if_sdata_b)
  );
  
  ad7357if_mock adc_mock (
    .sclk(if_sclk),
    .cs_n(if_cs_n),
    .sdata_a(if_sdata_a),
    .sdata_b(if_sdata_b),
    .data_a(test_data_a),
    .data_b(test_data_b)
  );

endmodule
