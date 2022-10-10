module ad7357if (
  // Main clock input
  // Because AD7357's clock is quite fast for iCE40 (60~80MHz on the pin), DDR output should be used to generate it.
  // Even then, to avoid setup time violation most likely you'll need to re-buffer this clock on the pin (use inout pin)
  // Then you feed that rebuffered clock to `i_if_sclk`. This clock then drives entire AD7357 clocking domain.
  // --
  // Because AD7357 is clocked on the falling edge, the entire clocking domain uses `@negedge i_if_sclk`.
  input i_if_sclk,
  // Reset
  input   i_rst,
  // Conversion is triggered when i_sync is 1
  input   i_sync,
  // Sampled data
  output  o_ready,
  output  [13:0]  o_sample_a,
  output  [13:0]  o_sample_b,
  // External interface pins connected to AD7357
  output  o_if_cs_n,
  input   i_if_sdata_a,
  input   i_if_sdata_b
);

  reg   [13:0]  r_data_a;
  reg   [13:0]  r_data_b;
  reg   [1:0]   r_overhead;
  reg   r_out_ready;
  reg   r_if_cs_n;
  reg   r_running;
  
  assign o_sample_a = r_data_a;
  assign o_sample_b = r_data_b;
  assign o_ready = r_out_ready;
  assign o_if_cs_n = r_if_cs_n;

  always @(negedge i_if_sclk) begin
    if (i_rst) begin
      r_data_a <= 14'b0;
      r_data_b <= 14'b0;
      r_overhead <= 2'b0;
      r_out_ready <= 1'b0;
      r_if_cs_n <= 1'b1;
      r_running <= 1'b0;
    end else begin
      if (!r_running) begin
        r_out_ready <= 1'b0;
        if (i_sync) begin
          // kick off ADC conversion and acquisition
          r_running <= 1'b1;
          r_if_cs_n <= 1'b0;
          // data: LSB is 1, rest is 0
          r_data_a <= 14'b1;
          r_data_b <= 14'b1;
          r_overhead <= 2'b0;
        end
      end else begin
        // read data (AD7357 data goes MSB-first)
        r_overhead[1:0] <= {r_overhead[0], r_data_a[13]};
        r_data_a[13:0] <= {r_data_a[12:0], i_if_sdata_a};
        r_data_b[13:0] <= {r_data_b[12:0], i_if_sdata_b};
        // detect end of conversion - that happens when r_data_a[15] is 1'b1
        if (r_overhead[1]) begin 
          r_running <= 1'b0;
          r_out_ready <= 1'b1;
          r_if_cs_n <= 1'b1;
        end
      end
    end
  end

endmodule
