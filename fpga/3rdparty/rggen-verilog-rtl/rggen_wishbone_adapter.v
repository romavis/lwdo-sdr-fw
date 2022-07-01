module rggen_wishbone_adapter #(
  parameter                     ADDRESS_WIDTH       = 8,
  parameter                     LOCAL_ADDRESS_WIDTH = 8,
  parameter                     BUS_WIDTH           = 32,
  parameter                     REGISTERS           = 1,
  parameter                     PRE_DECODE          = 0,
  parameter [ADDRESS_WIDTH-1:0] BASE_ADDRESS        = {ADDRESS_WIDTH{1'b0}},
  parameter                     BYTE_SIZE           = 256,
  parameter                     ERROR_STATUS        = 0,
  parameter [BUS_WIDTH-1:0]     DEFAULT_READ_DATA   = {BUS_WIDTH{1'b0}},
  parameter                     USE_STALL           = 1
)(
  input                             i_clk,
  input                             i_rst_n,
  input                             i_wb_cyc,
  input                             i_wb_stb,
  output                            o_wb_stall,
  input   [ADDRESS_WIDTH-1:0]       i_wb_adr,
  input                             i_wb_we,
  input   [BUS_WIDTH-1:0]           i_wb_dat,
  input   [BUS_WIDTH/8-1:0]         i_wb_sel,
  output                            o_wb_ack,
  output                            o_wb_err,
  output                            o_wb_rty,
  output  [BUS_WIDTH-1:0]           o_wb_dat,
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
  wire                      w_bus_valid;
  wire  [1:0]               w_bus_access;
  wire  [ADDRESS_WIDTH-1:0] w_bus_address;
  wire  [BUS_WIDTH-1:0]     w_bus_write_data;
  wire  [BUS_WIDTH/8-1:0]   w_bus_strobe;
  wire                      w_bus_ready;
  wire  [1:0]               w_bus_status;
  wire  [BUS_WIDTH-1:0]     w_bus_read_data;
  wire  [1:0]               w_request_valid;
  wire  [ADDRESS_WIDTH-1:0] w_wb_adr;
  wire                      w_wb_we;
  wire  [BUS_WIDTH-1:0]     w_wb_dat;
  wire  [BUS_WIDTH/8-1:0]   w_wb_sel;
  reg   [1:0]               r_response_valid;
  reg   [BUS_WIDTH-1:0]     r_response_data;

  assign  o_wb_stall  = w_request_valid[1];
  assign  o_wb_ack    = r_response_valid[0];
  assign  o_wb_err    = r_response_valid[1];
  assign  o_wb_rty    = 1'b0;
  assign  o_wb_dat    = r_response_data;

  assign  w_bus_valid       = (w_request_valid != 2'b00) && (r_response_valid == 2'b00);
  assign  w_bus_access      = (w_request_valid[1]) ? {1'b1, w_wb_we} : {1'b1, i_wb_we};
  assign  w_bus_address     = (w_request_valid[1]) ? w_wb_adr        : i_wb_adr;
  assign  w_bus_write_data  = (w_request_valid[1]) ? w_wb_dat        : i_wb_dat;
  assign  w_bus_strobe      = (w_request_valid[1]) ? w_wb_sel        : i_wb_sel;

  assign  w_request_valid[0]  = i_wb_cyc && i_wb_stb;
  generate
    if (USE_STALL) begin : g_stall
      reg                     r_request_valid;
      reg [ADDRESS_WIDTH-1:0] r_wb_adr;
      reg                     r_wb_we;
      reg [BUS_WIDTH-1:0]     r_wb_dat;
      reg [BUS_WIDTH/8-1:0]   r_wb_sel;

      assign  w_request_valid[1]  = r_request_valid;
      assign  w_wb_adr            = r_wb_adr;
      assign  w_wb_we             = r_wb_we;
      assign  w_wb_dat            = r_wb_dat;
      assign  w_wb_sel            = r_wb_sel;

      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_request_valid <= 1'b0;
        end
        else if (r_response_valid != 2'b00) begin
          r_request_valid <= 1'b0;
        end
        else if (w_request_valid == 2'b01) begin
          r_request_valid <= 1'b1;
        end
      end

      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_wb_adr  <= {ADDRESS_WIDTH{1'b0}};
          r_wb_we   <= 1'b0;
          r_wb_dat  <= {BUS_WIDTH{1'b0}};
          r_wb_sel  <= {(BUS_WIDTH/8){1'b0}};
        end
        else if (w_request_valid == 2'b01) begin
          r_wb_adr  <= i_wb_adr;
          r_wb_we   <= i_wb_we;
          r_wb_dat  <= i_wb_dat;
          r_wb_sel  <= i_wb_sel;
        end
      end
    end
    else begin : g_no_stall
      assign  w_request_valid[1]  = 1'b0;
      assign  w_wb_adr            = {ADDRESS_WIDTH{1'b0}};
      assign  w_wb_we             = 1'b0;
      assign  w_wb_dat            = {BUS_WIDTH{1'b0}};
      assign  w_wb_sel            = {(BUS_WIDTH/8){1'b0}};
    end
  endgenerate

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_response_valid  <= 2'b00;
    end
    else if (r_response_valid != 2'b00) begin
      r_response_valid  <= 2'b00;
    end
    else if (w_bus_valid && w_bus_ready) begin
      if (w_bus_status[1]) begin
        r_response_valid  <= 2'b10;
      end
      else begin
        r_response_valid  <= 2'b01;
      end
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_response_data <= {BUS_WIDTH{1'b0}};
    end
    else if (w_bus_valid && w_bus_ready) begin
      r_response_data <= w_bus_read_data;
    end
  end

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
