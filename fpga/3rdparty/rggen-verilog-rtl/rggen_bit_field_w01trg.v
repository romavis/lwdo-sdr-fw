module rggen_bit_field_w01trg #(
  parameter TRIGGER_VALUE = 1'b0,
  parameter WIDTH         = 8
)(
  input               i_clk,
  input               i_rst_n,
  input               i_bit_field_valid,
  input   [WIDTH-1:0] i_bit_field_read_mask,
  input   [WIDTH-1:0] i_bit_field_write_mask,
  input   [WIDTH-1:0] i_bit_field_write_data,
  output  [WIDTH-1:0] o_bit_field_read_data,
  output  [WIDTH-1:0] o_bit_field_value,
  output  [WIDTH-1:0] o_trigger
);
  reg [WIDTH-1:0] r_trigger;

  assign  o_bit_field_read_data = {WIDTH{1'b0}};
  assign  o_bit_field_value     = r_trigger;
  assign  o_trigger             = r_trigger;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_trigger <= {WIDTH{1'b0}};
    end
    else if (i_bit_field_valid) begin
      r_trigger <=
        (TRIGGER_VALUE != 0)
          ? i_bit_field_write_mask & ( i_bit_field_write_data)
          : i_bit_field_write_mask & (~i_bit_field_write_data);
    end
    else if (r_trigger != {WIDTH{1'b0}}) begin
      r_trigger <= {WIDTH{1'b0}};
    end
  end
endmodule
