`include  "rggen_rtl_macros.vh"
module rggen_skid_buffer #(
  parameter ID_WIDTH        = 0,
  parameter ADDRESS_WIDTH   = 8,
  parameter BUS_WIDTH       = 32,
  parameter ACTUAL_ID_WIDTH = `rggen_clip_width(ID_WIDTH)
)(
  input                         i_clk,
  input                         i_rst_n,
  input                         i_awvalid,
  output                        o_awready,
  input   [ACTUAL_ID_WIDTH-1:0] i_awid,
  input   [ADDRESS_WIDTH-1:0]   i_awaddr,
  input   [2:0]                 i_awprot,
  input                         i_wvalid,
  output                        o_wready,
  input   [BUS_WIDTH-1:0]       i_wdata,
  input   [BUS_WIDTH/8-1:0]     i_wstrb,
  output                        o_bvalid,
  input                         i_bready,
  output  [ACTUAL_ID_WIDTH-1:0] o_bid,
  output  [1:0]                 o_bresp,
  input                         i_arvalid,
  output                        o_arready,
  input   [ACTUAL_ID_WIDTH-1:0] i_arid,
  input   [ADDRESS_WIDTH-1:0]   i_araddr,
  input   [2:0]                 i_arprot,
  output                        o_rvalid,
  input                         i_rready,
  output  [ACTUAL_ID_WIDTH-1:0] o_rid,
  output  [1:0]                 o_rresp,
  output  [BUS_WIDTH-1:0]       o_rdata,
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
  wire                        w_awvalid;
  wire                        w_awready;
  reg                         r_awvalid;
  reg   [ACTUAL_ID_WIDTH-1:0] r_awid;
  reg   [ADDRESS_WIDTH-1:0]   r_awaddr;
  reg   [2:0]                 r_awprot;
  wire                        w_wvalid;
  wire                        w_wready;
  reg                         r_wvalid;
  reg   [BUS_WIDTH-1:0]       r_wdata;
  reg   [BUS_WIDTH/8-1:0]     r_wstrb;
  wire                        w_arvalid;
  wire                        w_arready;
  reg                         r_arvalid;
  reg   [ACTUAL_ID_WIDTH-1:0] r_arid;
  reg   [ADDRESS_WIDTH-1:0]   r_araddr;
  reg   [2:0]                 r_arprot;

  //  Write address channel
  assign  o_awready = w_awready;
  assign  o_awvalid = w_awvalid;
  assign  o_awid    = (r_awvalid) ? r_awid   : i_awid;
  assign  o_awaddr  = (r_awvalid) ? r_awaddr : i_awaddr;
  assign  o_awprot  = (r_awvalid) ? r_arprot : i_awprot;

  assign  w_awvalid = i_awvalid || r_awvalid;
  assign  w_awready = !r_awvalid;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_awvalid <= 1'b0;
    end
    else if (w_awvalid && i_awready) begin
      r_awvalid <= 1'b0;
    end
    else if (i_awvalid && w_awready) begin
      r_awvalid <= 1'b1;
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_awid    <= {ACTUAL_ID_WIDTH{1'b0}};
      r_awaddr  <= {ADDRESS_WIDTH{1'b0}};
      r_awprot  <= 3'b000;
    end
    else if (i_awvalid && w_awready) begin
      r_awid    <= i_awid;
      r_awaddr  <= i_awaddr;
      r_awprot  <= i_awprot;
    end
  end

  //  Write data channel
  assign  o_wready  = w_wready;
  assign  o_wvalid  = w_wvalid;
  assign  o_wdata   = (r_wvalid) ? r_wdata : i_wdata;
  assign  o_wstrb   = (r_wvalid) ? r_wstrb : i_wstrb;

  assign  w_wvalid  = i_wvalid || r_wvalid;
  assign  w_wready  = !r_wvalid;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_wvalid  <= 1'b0;
    end
    else if (w_wvalid && i_wready) begin
      r_wvalid  <= 1'b0;
    end
    else if (i_wvalid && w_wready) begin
      r_wvalid  <= 1'b1;
    end
  end

  always @(posedge i_clk) begin
    if (i_wvalid && w_wready) begin
      r_wdata <= i_wdata;
      r_wstrb <= i_wstrb;
    end
  end

  //  Write response channel
  assign  o_bready  = i_bready;
  assign  o_bvalid  = i_bvalid;
  assign  o_bid     = i_bid;
  assign  o_bresp   = i_bresp;

  //  Read address channel
  assign  o_arready = w_arready;
  assign  o_arvalid = w_arvalid;
  assign  o_arid    = (r_arvalid) ? r_arid   : i_arid;
  assign  o_araddr  = (r_arvalid) ? r_araddr : i_araddr;
  assign  o_arprot  = (r_arvalid) ? r_arprot : i_arprot;

  assign  w_arvalid = i_arvalid || r_arvalid;
  assign  w_arready = !r_arvalid;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_arvalid <= 1'b0;
    end
    else if (w_arvalid && i_arready) begin
      r_arvalid <= 1'b0;
    end
    else if (i_arvalid && w_arready) begin
      r_arvalid <= 1'b1;
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_arid    <= {ACTUAL_ID_WIDTH{1'b0}};
      r_araddr  <= {ADDRESS_WIDTH{1'b0}};
      r_arprot  <= 3'b000;
    end
    else if (i_arvalid && w_arready) begin
      r_arid    <= i_arid;
      r_araddr  <= i_araddr;
      r_arprot  <= i_arprot;
    end
  end

  //  Read response channel
  assign  o_rready  = i_rready;
  assign  o_rvalid  = i_rvalid;
  assign  o_rid     = i_rid;
  assign  o_rresp   = i_rresp;
  assign  o_rdata   = i_rdata;
endmodule
