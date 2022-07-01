module rggen_address_decoder #(
  parameter             READABLE      = 1'b1,
  parameter             WRITABLE      = 1'b1,
  parameter             WIDTH         = 8,
  parameter             BUS_WIDTH     = 32,
  parameter [WIDTH-1:0] START_ADDRESS = {WIDTH{1'b0}},
  parameter [WIDTH-1:0] END_ADDRESS   = {WIDTH{1'b0}}
)(
  input   [WIDTH-1:0] i_address,
  input   [1:0]       i_access,
  input               i_additional_match,
  output              o_match
);
  localparam  LSB         = clog2(BUS_WIDTH) - 3;
  localparam  ACCESS_BIT  = 0;

  wire  w_address_match;
  wire  w_access_match;

  assign  w_address_match = match_address(i_address);
  assign  w_access_match  = match_access(i_access);
  assign  o_match         = w_address_match && w_access_match && i_additional_match;

  function automatic integer clog2;
    input integer n;

    integer result;
    integer value;
  begin
    value   = n - 1;
    result  = 0;
    while (value > 0) begin
      result  = result + 1;
      value   = value >> 1;
    end
    clog2 = result;
  end
  endfunction

  function automatic match_address;
    input [WIDTH-1:0] address;
  begin
    if (START_ADDRESS[WIDTH-1:LSB] == END_ADDRESS[WIDTH-1:LSB]) begin
      match_address = (address[WIDTH-1:LSB] == START_ADDRESS[WIDTH-1:LSB]);
    end
    else begin
      match_address =
        (address[WIDTH-1:LSB] >= START_ADDRESS[WIDTH-1:LSB]) &&
        (address[WIDTH-1:LSB] <= END_ADDRESS[WIDTH-1:LSB]  );
    end
  end
  endfunction

  function automatic match_access;
    input [1:0] access;
  begin
    if (READABLE && WRITABLE) begin
      match_access  = 1'b1;
    end
    else if (READABLE) begin
      match_access  = !access[ACCESS_BIT];
    end
    else begin
      match_access  = access[ACCESS_BIT];
    end
  end
  endfunction
endmodule
