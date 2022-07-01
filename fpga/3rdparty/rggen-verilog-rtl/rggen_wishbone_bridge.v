module rggen_wishbone_bridge #(
  parameter ADDRESS_WIDTH = 8,
  parameter BUS_WIDTH     = 32,
  parameter USE_STALL     = 1
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
  output                            o_wb_cyc,
  output                            o_wb_stb,
  input                             i_wb_stall,
  output  [ADDRESS_WIDTH-1:0]       o_wb_adr,
  output                            o_wb_we,
  output  [BUS_WIDTH-1:0]           o_wb_dat,
  output  [BUS_WIDTH/8-1:0]         o_wb_sel,
  input                             i_wb_ack,
  input                             i_wb_err,
  input                             i_wb_rty,
  input   [BUS_WIDTH-1:0]           i_wb_dat
);
  wire  w_request_done;

  assign  o_wb_cyc  = i_bus_valid;
  assign  o_wb_stb  = i_bus_valid && (!w_request_done);
  assign  o_wb_adr  = i_bus_address;
  assign  o_wb_we   = i_bus_access != `RGGEN_READ;
  assign  o_wb_dat  = i_bus_write_data;
  assign  o_wb_sel  = i_bus_strobe;

  assign  o_bus_ready     = i_wb_ack || i_wb_err || i_wb_rty;
  assign  o_bus_status    = (i_wb_ack) ? `RGGEN_OKAY : `RGGEN_SLAVE_ERROR;
  assign  o_bus_read_data = i_wb_dat;

  generate
    if (USE_STALL) begin : g_stall
      reg r_request_done;

      assign  w_request_done  = r_request_done;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_request_done  <= 1'b0;
        end
        else if (i_bus_valid && (i_wb_ack || i_wb_err || i_wb_rty)) begin
          r_request_done  <= 1'b0;
        end
        else if (i_bus_valid && (!i_wb_stall)) begin
          r_request_done  <= 1'b1;
        end
      end
    end
    else begin : g_no_stall
      assign  w_request_done  = 1'b0;
    end
  endgenerate
endmodule
