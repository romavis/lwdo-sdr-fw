module rggen_external_register #(
  parameter ADDRESS_WIDTH = 8,
  parameter BUS_WIDTH     = 32,
  parameter [ADDRESS_WIDTH-1:0] START_ADDRESS = {ADDRESS_WIDTH{1'b0}},
  parameter [ADDRESS_WIDTH-1:0] END_ADDRESS   = {ADDRESS_WIDTH{1'b0}}
)(
  input                       i_clk,
  input                       i_rst_n,
  input                       i_register_valid,
  input   [1:0]               i_register_access,
  input   [ADDRESS_WIDTH-1:0] i_register_address,
  input   [BUS_WIDTH-1:0]     i_register_write_data,
  input   [BUS_WIDTH/8-1:0]   i_register_strobe,
  output                      o_register_active,
  output                      o_register_ready,
  output  [1:0]               o_register_status,
  output  [BUS_WIDTH-1:0]     o_register_read_data,
  output  [BUS_WIDTH-1:0]     o_register_value,
  output                      o_external_valid,
  output  [1:0]               o_external_access,
  output  [ADDRESS_WIDTH-1:0] o_external_address,
  output  [BUS_WIDTH-1:0]     o_external_data,
  output  [BUS_WIDTH/8-1:0]   o_external_strobe,
  input                       i_external_ready,
  input   [1:0]               i_external_status,
  input   [BUS_WIDTH-1:0]     i_external_data
);
  //  Decode address
  wire  w_match;

  rggen_address_decoder #(
    .READABLE       (1'b1           ),
    .WRITABLE       (1'b1           ),
    .WIDTH          (ADDRESS_WIDTH  ),
    .BUS_WIDTH      (BUS_WIDTH      ),
    .START_ADDRESS  (START_ADDRESS  ),
    .END_ADDRESS    (END_ADDRESS    )
  ) u_decoder (
    .i_address          (i_register_address ),
    .i_access           (i_register_access  ),
    .i_additional_match (1'b1               ),
    .o_match            (w_match            )
  );

  //  Request
  reg                     r_valid;
  reg [1:0]               r_access;
  reg [ADDRESS_WIDTH-1:0] r_address;
  reg [BUS_WIDTH-1:0]     r_write_data;
  reg [BUS_WIDTH/8-1:0]   r_strobe;

  assign  o_external_valid    = r_valid;
  assign  o_external_access   = r_access;
  assign  o_external_address  = r_address;
  assign  o_external_data     = r_write_data;
  assign  o_external_strobe   = r_strobe;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_valid <= 1'b0;
    end
    else if (r_valid && i_external_ready) begin
      r_valid <= 1'b0;
    end
    else if (i_register_valid && w_match) begin
      r_valid <= 1'b1;
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_access  <= 2'b00;
      r_address <= {ADDRESS_WIDTH{1'b0}};
    end
    else if (i_register_valid && w_match) begin
      r_access  <= i_register_access;
      r_address <= i_register_address - START_ADDRESS;
    end
  end

  always @(posedge i_clk) begin
    if (i_register_valid && w_match) begin
      r_write_data  <= i_register_write_data;
      r_strobe      <= i_register_strobe;
    end
  end

  //  Response
  assign  o_register_active     = w_match;
  assign  o_register_ready      = r_valid && i_external_ready;
  assign  o_register_status     = i_external_status;
  assign  o_register_read_data  = i_external_data;
  assign  o_register_value      = i_external_data;
endmodule
