`include  "rggen_rtl_macros.vh"
module rggen_axi4lite_adapter #(
  parameter                     ID_WIDTH            = 0,
  parameter                     ADDRESS_WIDTH       = 8,
  parameter                     LOCAL_ADDRESS_WIDTH = 8,
  parameter                     BUS_WIDTH           = 32,
  parameter                     REGISTERS           = 1,
  parameter                     PRE_DECODE          = 0,
  parameter [ADDRESS_WIDTH-1:0] BASE_ADDRESS        = {ADDRESS_WIDTH{1'b0}},
  parameter                     BYTE_SIZE           = 256,
  parameter                     ERROR_STATUS        = 0,
  parameter [BUS_WIDTH-1:0]     DEFAULT_READ_DATA   = {BUS_WIDTH{1'b0}},
  parameter                     WRITE_FIRST         = 1,
  parameter                     ACTUAL_ID_WIDTH     = `rggen_clip_width(ID_WIDTH)
)(
  input                             i_clk,
  input                             i_rst_n,
  input                             i_awvalid,
  output                            o_awready,
  input   [ACTUAL_ID_WIDTH-1:0]     i_awid,
  input   [ADDRESS_WIDTH-1:0]       i_awaddr,
  input   [2:0]                     i_awprot,
  input                             i_wvalid,
  output                            o_wready,
  input   [BUS_WIDTH-1:0]           i_wdata,
  input   [BUS_WIDTH/8-1:0]         i_wstrb,
  output                            o_bvalid,
  input                             i_bready,
  output  [ACTUAL_ID_WIDTH-1:0]     o_bid,
  output  [1:0]                     o_bresp,
  input                             i_arvalid,
  output                            o_arready,
  input   [ACTUAL_ID_WIDTH-1:0]     i_arid,
  input   [ADDRESS_WIDTH-1:0]       i_araddr,
  input   [2:0]                     i_arprot,
  output                            o_rvalid,
  input                             i_rready,
  output  [ACTUAL_ID_WIDTH-1:0]     o_rid,
  output  [1:0]                     o_rresp,
  output  [BUS_WIDTH-1:0]           o_rdata,
  output                            o_register_valid,
  output  [1:0]                     o_register_access,
  output  [LOCAL_ADDRESS_WIDTH-1:0] o_register_address,
  output  [BUS_WIDTH-1:0]           o_register_write_data,
  output  [BUS_WIDTH/8-1:0]         o_register_strobe,
  input   [REGISTERS-1:0]           i_register_active,
  input   [REGISTERS-1:0]           i_register_ready,
  input   [2*REGISTERS-1:0]         i_register_status,
  input   [BUS_WIDTH*REGISTERS-1:0] i_register_read_data
);
  localparam  [1:0] RGGEN_WRITE = 2'b11;
  localparam  [1:0] RGGEN_READ  = 2'b10;

  wire                        w_awvalid;
  wire                        w_awready;
  wire  [ACTUAL_ID_WIDTH-1:0] w_awid;
  wire  [ADDRESS_WIDTH-1:0]   w_awaddr;
  wire  [2:0]                 w_awprot;
  wire                        w_wvalid;
  wire                        w_wready;
  wire  [BUS_WIDTH-1:0]       w_wdata;
  wire  [BUS_WIDTH/8-1:0]     w_wstrb;
  wire                        w_bvalid;
  wire                        w_bready;
  wire  [ACTUAL_ID_WIDTH-1:0] w_bid;
  wire  [1:0]                 w_bresp;
  wire                        w_arvalid;
  wire                        w_arready;
  wire  [ACTUAL_ID_WIDTH-1:0] w_arid;
  wire  [ADDRESS_WIDTH-1:0]   w_araddr;
  wire  [2:0]                 w_arprot;
  wire                        w_rvalid;
  wire                        w_rready;
  wire  [ACTUAL_ID_WIDTH-1:0] w_rid;
  wire  [1:0]                 w_rresp;
  wire  [BUS_WIDTH-1:0]       w_rdata;
  wire                        w_bus_valid;
  wire  [1:0]                 w_bus_access;
  wire  [ADDRESS_WIDTH-1:0]   w_bus_address;
  wire  [BUS_WIDTH-1:0]       w_bus_write_data;
  wire  [BUS_WIDTH/8-1:0]     w_bus_strobe;
  wire                        w_bus_ready;
  wire  [1:0]                 w_bus_status;
  wire  [BUS_WIDTH-1:0]       w_bus_read_data;

  //  Buffer
  rggen_skid_buffer #(
    .ID_WIDTH       (ID_WIDTH       ),
    .ADDRESS_WIDTH  (ADDRESS_WIDTH  ),
    .BUS_WIDTH      (BUS_WIDTH      )
  ) u_buffer (
    .i_clk      (i_clk      ),
    .i_rst_n    (i_rst_n    ),
    .i_awvalid  (i_awvalid  ),
    .o_awready  (o_awready  ),
    .i_awid     (i_awid     ),
    .i_awaddr   (i_awaddr   ),
    .i_awprot   (i_awprot   ),
    .i_wvalid   (i_wvalid   ),
    .o_wready   (o_wready   ),
    .i_wdata    (i_wdata    ),
    .i_wstrb    (i_wstrb    ),
    .o_bvalid   (o_bvalid   ),
    .i_bready   (i_bready   ),
    .o_bid      (o_bid      ),
    .o_bresp    (o_bresp    ),
    .i_arvalid  (i_arvalid  ),
    .o_arready  (o_arready  ),
    .i_arid     (i_arid     ),
    .i_araddr   (i_araddr   ),
    .i_arprot   (i_arprot   ),
    .o_rvalid   (o_rvalid   ),
    .i_rready   (i_rready   ),
    .o_rid      (o_rid      ),
    .o_rresp    (o_rresp    ),
    .o_rdata    (o_rdata    ),
    .o_awvalid  (w_awvalid  ),
    .i_awready  (w_awready  ),
    .o_awid     (w_awid     ),
    .o_awaddr   (w_awaddr   ),
    .o_awprot   (w_awprot   ),
    .o_wvalid   (w_wvalid   ),
    .i_wready   (w_wready   ),
    .o_wdata    (w_wdata    ),
    .o_wstrb    (w_wstrb    ),
    .i_bvalid   (w_bvalid   ),
    .o_bready   (w_bready   ),
    .i_bid      (w_bid      ),
    .i_bresp    (w_bresp    ),
    .o_arvalid  (w_arvalid  ),
    .i_arready  (w_arready  ),
    .o_arid     (w_arid     ),
    .o_araddr   (w_araddr   ),
    .o_arprot   (w_arprot   ),
    .i_rvalid   (w_rvalid   ),
    .o_rready   (w_rready   ),
    .i_rid      (w_rid      ),
    .i_rresp    (w_rresp    ),
    .i_rdata    (w_rdata    )
  );

  wire  [1:0]                 w_request_valid;
  wire  [2:0]                 w_request_ready;
  reg   [1:0]                 r_response_valid;
  wire                        w_response_ack;
  wire  [ACTUAL_ID_WIDTH-1:0] w_id;
  reg   [BUS_WIDTH-1:0]       r_read_data;
  reg   [1:0]                 r_status;

  //  Request
  assign  w_awready = w_bus_ready && w_request_ready[0] && (r_response_valid == 2'b00);
  assign  w_wready  = w_bus_ready && w_request_ready[1] && (r_response_valid == 2'b00);
  assign  w_arready = w_bus_ready && w_request_ready[2] && (r_response_valid == 2'b00);

  assign  w_bus_valid       = (w_request_valid != 2'b00) && (r_response_valid == 2'b00);
  assign  w_bus_access      = (w_request_valid[0]) ? RGGEN_WRITE : RGGEN_READ;
  assign  w_bus_address     = (w_request_valid[0]) ? w_awaddr    : w_araddr;
  assign  w_bus_write_data  = w_wdata;
  assign  w_bus_strobe      = w_wstrb;

  assign  w_request_valid = get_request_valid(w_awvalid, w_wvalid, w_arvalid);
  assign  w_request_ready = get_request_ready(w_awvalid, w_wvalid, w_arvalid);

  function automatic [1:0] get_request_valid;
    input awvalid;
    input wvalid;
    input arvalid;

    reg [1:0] valid;
  begin
    if (WRITE_FIRST) begin
      valid[0]  = awvalid && wvalid;
      valid[1]  = arvalid && (!valid[0]);
    end
    else begin
      valid[0]  = awvalid && wvalid && (!arvalid);
      valid[1]  = arvalid;
    end

    get_request_valid = valid;
  end
  endfunction

  function automatic [2:0] get_request_ready;
    input       awvalid;
    input       wvalid;
    input       arvalid;

    reg [2:0] ready;
  begin
    if (WRITE_FIRST) begin
      ready[0]  = wvalid;
      ready[1]  = awvalid;
      ready[2]  = !(awvalid && wvalid);
    end
    else begin
      ready[0]  = (!arvalid) && wvalid;
      ready[1]  = (!arvalid) && awvalid;
      ready[2]  = 1'b1;
    end

    get_request_ready = ready;
  end
  endfunction

  //  Response
  assign  w_bvalid  = r_response_valid[0];
  assign  w_bid     = w_id;
  assign  w_bresp   = r_status;
  assign  w_rvalid  = r_response_valid[1];
  assign  w_rid     = w_id;
  assign  w_rdata   = r_read_data;
  assign  w_rresp   = r_status;

  assign  w_response_ack  =
    (r_response_valid[0] && w_bready) ||
    (r_response_valid[1] && w_rready);
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_response_valid  <= 2'b00;
    end
    else if (w_response_ack) begin
      r_response_valid  <= 2'b00;
    end
    else if (w_bus_valid && w_bus_ready) begin
      if (w_bus_access == RGGEN_WRITE) begin
        r_response_valid  <= 2'b01;
      end
      else begin
        r_response_valid  <= 2'b10;
      end
    end
  end

  generate if (ID_WIDTH >= 1) begin : g_id
    reg [ID_WIDTH-1:0]  r_id;

    assign  w_id  = r_id;
    always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
        r_id  <= {ID_WIDTH{1'b0}};
      end
      else if (w_awvalid && w_awready) begin
        r_id  <= w_awid;
      end
      else if (w_arvalid && w_arready) begin
        r_id  <= w_arid;
      end
    end
  end
  else begin : g_id
    assign  w_id  = 1'b0;
  end endgenerate

  always @(posedge i_clk) begin
    if (w_bus_valid && w_bus_ready) begin
      r_read_data <= w_bus_read_data;
      r_status    <= w_bus_status;
    end
  end

  //  Adapter common
  rggen_adapter_common #(
    .ADDRESS_WIDTH        (ADDRESS_WIDTH        ),
    .LOCAL_ADDRESS_WIDTH  (LOCAL_ADDRESS_WIDTH  ),
    .BUS_WIDTH            (BUS_WIDTH            ),
    .REGISTERS            (REGISTERS            ),
    .PRE_DECODE           (PRE_DECODE           ),
    .BASE_ADDRESS         (BASE_ADDRESS         ),
    .BYTE_SIZE            (BYTE_SIZE            ),
    .ERROR_STATUS         (ERROR_STATUS         ),
    .DEFAULT_READ_DATA    (DEFAULT_READ_DATA    )
  ) u_adapter_common (
    .i_clk                  (i_clk                  ),
    .i_rst_n                (i_rst_n                ),
    .i_bus_valid            (w_bus_valid            ),
    .i_bus_access           (w_bus_access           ),
    .i_bus_address          (w_bus_address          ),
    .i_bus_write_data       (w_bus_write_data       ),
    .i_bus_strobe           (w_bus_strobe           ),
    .o_bus_ready            (w_bus_ready            ),
    .o_bus_status           (w_bus_status           ),
    .o_bus_read_data        (w_bus_read_data        ),
    .o_register_valid       (o_register_valid       ),
    .o_register_access      (o_register_access      ),
    .o_register_address     (o_register_address     ),
    .o_register_write_data  (o_register_write_data  ),
    .o_register_strobe      (o_register_strobe      ),
    .i_register_active      (i_register_active      ),
    .i_register_ready       (i_register_ready       ),
    .i_register_status      (i_register_status      ),
    .i_register_read_data   (i_register_read_data   )
  );
endmodule
