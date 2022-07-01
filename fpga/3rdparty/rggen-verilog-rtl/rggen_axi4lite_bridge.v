module rggen_axi4lite_bridge #(
  parameter ID_WIDTH        = 0,
  parameter ADDRESS_WIDTH   = 8,
  parameter BUS_WIDTH       = 32,
  parameter ACTUAL_ID_WIDTH = (ID_WIDTH > 0) ? ID_WIDTH : 1
)(
  input                         i_clk,
  input                         i_rst_n,
  input                         i_bus_valid,
  input   [1:0]                 i_bus_access,
  input   [ADDRESS_WIDTH-1:0]   i_bus_address,
  input   [BUS_WIDTH-1:0]       i_bus_write_data,
  input   [BUS_WIDTH/8-1:0]     i_bus_strobe,
  output                        o_bus_ready,
  output  [1:0]                 o_bus_status,
  output  [BUS_WIDTH-1:0]       o_bus_read_data,
  output                        o_awvalid,
  input                         i_awready,
  output  [ACTUAL_ID_WIDTH-1:0] o_awid,
  output  [ADDRESS_WIDTH-1:0]   o_awaddr,
  output  [2:0]                 o_awprot,
  output                        o_wvalid,
  input                         i_wready,
  output  [BUS_WIDTH-1:0]       o_wdata,
  output  [BUS_WIDTH/8-1:0]     o_wstrb,
  input                         i_bvalid,
  output                        o_bready,
  input   [ACTUAL_ID_WIDTH-1:0] i_bid,
  input   [1:0]                 i_bresp,
  output                        o_arvalid,
  input                         i_arready,
  output  [ACTUAL_ID_WIDTH-1:0] o_arid,
  output  [ADDRESS_WIDTH-1:0]   o_araddr,
  output  [2:0]                 o_arprot,
  input                         i_rvalid,
  output                        o_rready,
  input   [ACTUAL_ID_WIDTH-1:0] i_rid,
  input   [1:0]                 i_rresp,
  input   [BUS_WIDTH-1:0]       i_rdata
);
  localparam  [1:0] RGGEN_READ  = 2'b10;

  wire  [2:0] w_request_valid;
  reg   [2:0] r_request_done;
  wire        w_bus_ready;
  wire  [1:0] w_bus_status;

  //  Request
  assign  o_awvalid       = w_request_valid[0];
  assign  o_awid          = {ACTUAL_ID_WIDTH{1'b0}};
  assign  o_awaddr        = i_bus_address;
  assign  o_awprot        = 3'b000;
  assign  o_wvalid        = w_request_valid[1];
  assign  o_wdata         = i_bus_write_data;
  assign  o_wstrb         = i_bus_strobe;
  assign  o_arvalid       = w_request_valid[2];
  assign  o_arid          = {ACTUAL_ID_WIDTH{1'b0}};
  assign  o_araddr        = i_bus_address;
  assign  o_arprot        = 3'b000;

  assign  w_request_valid[0]  = i_bus_valid && (!r_request_done[0]) && (i_bus_access != RGGEN_READ);
  assign  w_request_valid[1]  = i_bus_valid && (!r_request_done[1]) && (i_bus_access != RGGEN_READ);
  assign  w_request_valid[2]  = i_bus_valid && (!r_request_done[2]) && (i_bus_access == RGGEN_READ);

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_request_done  <= 3'b000;
    end
    else if (w_bus_ready) begin
      r_request_done  <= 3'b000;
    end
    else begin
      if (w_request_valid[0] && i_awready) begin
        r_request_done[0] <= 1'b1;
      end
      if (w_request_valid[1] && i_wready) begin
        r_request_done[1] <= 1'b1;
      end
      if (w_request_valid[2] && i_arready) begin
        r_request_done[2] <= 1'b1;
      end
    end
  end

  //  Response

  assign  o_bready  = r_request_done[0] && r_request_done[1];
  assign  o_rready  = r_request_done[2];

  assign  o_bus_ready     = w_bus_ready;
  assign  o_bus_status    = w_bus_status;
  assign  o_bus_read_data = i_rdata;

  assign  w_bus_ready =
    (i_bvalid && r_request_done[0] && r_request_done[1]) ||
    (i_rvalid && r_request_done[2]);
  assign  w_bus_status
      = (r_request_done[0] && r_request_done[1]) ? i_bresp
      : (r_request_done[2]                     ) ? i_rresp : 2'b00;
endmodule
