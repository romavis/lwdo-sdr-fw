module rggen_indirect_register #(
  parameter                             READABLE              = 1'b1,
  parameter                             WRITABLE              = 1'b1,
  parameter                             ADDRESS_WIDTH         = 8,
  parameter [ADDRESS_WIDTH-1:0]         OFFSET_ADDRESS        = {ADDRESS_WIDTH{1'b0}},
  parameter                             BUS_WIDTH             = 32,
  parameter                             DATA_WIDTH            = BUS_WIDTH,
  parameter                             INDIRECT_INDEX_WIDTH  = 1,
  parameter [INDIRECT_INDEX_WIDTH-1:0]  INDIRECT_INDEX_VALUE  = {INDIRECT_INDEX_WIDTH{1'b0}}
)(
  input                               i_clk,
  input                               i_rst_n,
  input                               i_register_valid,
  input   [1:0]                       i_register_access,
  input   [ADDRESS_WIDTH-1:0]         i_register_address,
  input   [BUS_WIDTH-1:0]             i_register_write_data,
  input   [BUS_WIDTH/8-1:0]           i_register_strobe,
  output                              o_register_active,
  output                              o_register_ready,
  output  [1:0]                       o_register_status,
  output  [BUS_WIDTH-1:0]             o_register_read_data,
  output  [DATA_WIDTH-1:0]            o_register_value,
  input   [INDIRECT_INDEX_WIDTH-1:0]  i_indirect_index,
  output                              o_bit_field_valid,
  output  [DATA_WIDTH-1:0]            o_bit_field_read_mask,
  output  [DATA_WIDTH-1:0]            o_bit_field_write_mask,
  output  [DATA_WIDTH-1:0]            o_bit_field_write_data,
  input   [DATA_WIDTH-1:0]            i_bit_field_read_data,
  input   [DATA_WIDTH-1:0]            i_bit_field_value
);
  wire  w_index_match;

  assign  w_index_match = i_indirect_index == INDIRECT_INDEX_VALUE;
  rggen_register_common #(
    .READABLE       (READABLE       ),
    .WRITABLE       (WRITABLE       ),
    .ADDRESS_WIDTH  (ADDRESS_WIDTH  ),
    .OFFSET_ADDRESS (OFFSET_ADDRESS ),
    .BUS_WIDTH      (BUS_WIDTH      ),
    .DATA_WIDTH     (DATA_WIDTH     ),
    .REGISTER_INDEX (0              )
  ) u_register_common (
    .i_clk                  (i_clk                  ),
    .i_rst_n                (i_rst_n                ),
    .i_register_valid       (i_register_valid       ),
    .i_register_access      (i_register_access      ),
    .i_register_address     (i_register_address     ),
    .i_register_write_data  (i_register_write_data  ),
    .i_register_strobe      (i_register_strobe      ),
    .o_register_active      (o_register_active      ),
    .o_register_ready       (o_register_ready       ),
    .o_register_status      (o_register_status      ),
    .o_register_read_data   (o_register_read_data   ),
    .o_register_value       (o_register_value       ),
    .i_additional_match     (w_index_match          ),
    .o_bit_field_valid      (o_bit_field_valid      ),
    .o_bit_field_read_mask  (o_bit_field_read_mask  ),
    .o_bit_field_write_mask (o_bit_field_write_mask ),
    .o_bit_field_write_data (o_bit_field_write_data ),
    .i_bit_field_read_data  (i_bit_field_read_data  ),
    .i_bit_field_value      (i_bit_field_value      )
  );
endmodule
