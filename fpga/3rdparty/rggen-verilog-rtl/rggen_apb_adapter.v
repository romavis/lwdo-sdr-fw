module rggen_apb_adapter #(
  parameter                     ADDRESS_WIDTH       = 8,
  parameter                     LOCAL_ADDRESS_WIDTH = 8,
  parameter                     BUS_WIDTH           = 32,
  parameter                     REGISTERS           = 1,
  parameter                     PRE_DECODE          = 0,
  parameter [ADDRESS_WIDTH-1:0] BASE_ADDRESS        = {ADDRESS_WIDTH{1'b0}},
  parameter                     BYTE_SIZE           = 256,
  parameter                     ERROR_STATUS        = 0,
  parameter [BUS_WIDTH-1:0]     DEFAULT_READ_DATA   = {BUS_WIDTH{1'b0}}
)(
  input                             i_clk,
  input                             i_rst_n,
  input                             i_psel,
  input                             i_penable,
  input   [ADDRESS_WIDTH-1:0]       i_paddr,
  input   [2:0]                     i_pprot,
  input                             i_pwrite,
  input   [BUS_WIDTH/8-1:0]         i_pstrb,
  input   [BUS_WIDTH-1:0]           i_pwdata,
  output                            o_pready,
  output  [BUS_WIDTH-1:0]           o_prdata,
  output                            o_pslverr,
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
  reg                       r_pready;
  reg   [BUS_WIDTH-1:0]     r_prdata;
  reg                       r_pslverr;

  assign  w_bus_valid       = i_psel && (!r_pready);
  assign  w_bus_access      = {1'b1, i_pwrite};
  assign  w_bus_address     = i_paddr;
  assign  w_bus_write_data  = i_pwdata;
  assign  w_bus_strobe      = i_pstrb;

  assign  o_pready  = r_pready;
  assign  o_prdata  = r_prdata;
  assign  o_pslverr = r_pslverr;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_pready  <= 1'b0;
    end
    else begin
      r_pready  <= w_bus_valid && w_bus_ready;
    end
  end

  always @(posedge i_clk) begin
    if (w_bus_valid && w_bus_ready) begin
      r_prdata  <= w_bus_read_data;
      r_pslverr <= w_bus_status[1];
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
