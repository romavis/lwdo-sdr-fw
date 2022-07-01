module rggen_adapter_common #(
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
  input                             i_bus_valid,
  input   [1:0]                     i_bus_access,
  input   [ADDRESS_WIDTH-1:0]       i_bus_address,
  input   [BUS_WIDTH-1:0]           i_bus_write_data,
  input   [BUS_WIDTH/8-1:0]         i_bus_strobe,
  output                            o_bus_ready,
  output  [1:0]                     o_bus_status,
  output  [BUS_WIDTH-1:0]           o_bus_read_data,
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
  localparam  [1:0] DEFAULT_STATUS  = (ERROR_STATUS != 0) ? 2'b10 : 2'b00;

  genvar                i;
  reg                   r_busy;
  wire                  w_inside_range;
  wire                  w_register_ready;
  wire                  w_register_inactive;
  wire  [1:0]           w_register_status;
  wire  [BUS_WIDTH-1:0] w_register_read_data;
  wire                  w_bus_ready;

  //  State
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_busy  <= 1'b0;
    end
    else if (w_bus_ready) begin
      r_busy  <= 1'b0;
    end
    else if (i_bus_valid) begin
      r_busy  <= 1'b1;
    end
  end

  //  Pre decode
  assign  w_inside_range  = (PRE_DECODE != 0) ? pre_decode(i_bus_address) : 1'b1;

  function automatic pre_decode;
    input [ADDRESS_WIDTH-1:0] address;

    reg [ADDRESS_WIDTH-1:0] begin_address;
    reg [ADDRESS_WIDTH-1:0] end_address;
  begin
    begin_address = BASE_ADDRESS;
    end_address   = BASE_ADDRESS + BYTE_SIZE - 1;
    pre_decode    = (address >= begin_address) && (address <= end_address);
  end
  endfunction

  //  Request
  assign  o_register_valid      = i_bus_valid && w_inside_range && (!r_busy);
  assign  o_register_access     = i_bus_access;
  assign  o_register_address    = i_bus_address[LOCAL_ADDRESS_WIDTH-1:0];
  assign  o_register_write_data = i_bus_write_data;
  assign  o_register_strobe     = i_bus_strobe;

  //  Response
  assign  o_bus_ready     = w_bus_ready;
  assign  o_bus_status    = (w_register_inactive) ? DEFAULT_STATUS    : w_register_status;
  assign  o_bus_read_data = (w_register_inactive) ? DEFAULT_READ_DATA : w_register_read_data;

  assign  w_register_inactive = (i_register_active == {REGISTERS{1'b0}}) || (!w_inside_range);
  assign  w_register_ready    = (i_register_ready  != {REGISTERS{1'b0}});
  assign  w_bus_ready         = w_register_ready || w_register_inactive;

  rggen_mux #(
    .WIDTH    (2          ),
    .ENTRIES  (REGISTERS  )
  ) u_status_mux (
    .i_select (i_register_active  ),
    .i_data   (i_register_status  ),
    .o_data   (w_register_status  )
  );

  rggen_mux #(
    .WIDTH    (BUS_WIDTH  ),
    .ENTRIES  (REGISTERS  )
  ) u_read_data_mux (
    .i_select (i_register_active    ),
    .i_data   (i_register_read_data ),
    .o_data   (w_register_read_data )
  );
endmodule
