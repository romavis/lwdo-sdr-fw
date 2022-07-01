module rggen_apb_bridge #(
  parameter ADDRESS_WIDTH = 8,
  parameter BUS_WIDTH     = 32
)(
  input                             i_clk,
  input                             i_rst_n,
  input                             i_bus_valid,
  input   [1:0]                     i_bus_access,
  input   [ADDRESS_WIDTH-1:0]       i_bus_address,
  input   [BUS_WIDTH-1:0]           i_bus_write_data,
  input   [BUS_WIDTH/8-1:0]         i_bus_strobe,
  output                            o_bus_ready,
  output  [1:0]                     o_bus_status,
  output  [BUS_WIDTH-1:0]           o_bus_read_data,
  output                            o_psel,
  output                            o_penable,
  output  [ADDRESS_WIDTH-1:0]       o_paddr,
  output  [2:0]                     o_pprot,
  output                            o_pwrite,
  output  [BUS_WIDTH/8-1:0]         o_pstrb,
  output  [BUS_WIDTH-1:0]           o_pwdata,
  input                             i_pready,
  input   [BUS_WIDTH-1:0]           i_prdata,
  input                             i_pslverr
);
  reg   r_busy;
  wire  w_psel;
  wire  w_penble;

  //  Request
  assign  w_psel    = i_bus_valid;
  assign  w_penble  = i_bus_valid && r_busy;
  assign  o_psel    = w_psel;
  assign  o_penable = w_penble;
  assign  o_paddr   = i_bus_address;
  assign  o_pprot   = 3'b000;
  assign  o_pwrite  = i_bus_access[0];
  assign  o_pstrb   = i_bus_strobe;
  assign  o_pwdata  = i_bus_write_data;

  //  Response
  assign  o_bus_ready     = i_pready && r_busy;
  assign  o_bus_status    = {i_pslverr, 1'b0};
  assign  o_bus_read_data = i_prdata;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_busy  <= 1'b0;
    end
    else if (w_penble && i_pready) begin
      r_busy  <= 1'b0;
    end
    else if (w_psel) begin
      r_busy  <= 1'b1;
    end
  end
endmodule
