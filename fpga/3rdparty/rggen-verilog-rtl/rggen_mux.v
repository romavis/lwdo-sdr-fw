module rggen_mux #(
  parameter WIDTH   = 1,
  parameter ENTRIES = 2
)(
  input   [ENTRIES-1:0]       i_select,
  input   [WIDTH*ENTRIES-1:0] i_data,
  output  [WIDTH-1:0]         o_data
);
  function automatic [WIDTH-1:0] __reduce_or;
    input integer             n;
    input integer             offset;
    input [ENTRIES*WIDTH-1:0] data;

    integer           next_n;
    integer           next_offset;
    reg [WIDTH-1:0]   result[0:1];
  begin
    if (n > 4) begin
      next_n      = n / 2;
      next_offset = offset;
      result[0]   = __reduce_or(next_n, next_offset, data);

      next_n      = (n / 2) + (n % 2);
      next_offset = (n / 2) + offset;
      result[1]   = __reduce_or(next_n, next_offset, data);

      __reduce_or = result[0] | result[1];
    end
    else if (n == 4) begin
      __reduce_or = data[(0+offset)*WIDTH+:WIDTH] | data[(1+offset)*WIDTH+:WIDTH]
                  | data[(2+offset)*WIDTH+:WIDTH] | data[(3+offset)*WIDTH+:WIDTH];
    end
    else if (n == 3) begin
      __reduce_or = data[(0+offset)*WIDTH+:WIDTH] | data[(1+offset)*WIDTH+:WIDTH]
                  | data[(2+offset)*WIDTH+:WIDTH];
    end
    else if (n == 2) begin
      __reduce_or = data[(0+offset)*WIDTH+:WIDTH] | data[(1+offset)*WIDTH+:WIDTH];
    end
    else begin
      __reduce_or = data[(0+offset)*WIDTH+:WIDTH];
    end
  end
  endfunction

  function automatic [WIDTH-1:0] mux;
    input [ENTRIES-1:0]       select;
    input [WIDTH*ENTRIES-1:0] data;

    integer                 i;
    reg [ENTRIES*WIDTH-1:0] masked_data;
  begin
    if (ENTRIES > 1) begin
      for (i = 0;i < ENTRIES;i = i + 1) begin
        masked_data[i*WIDTH+:WIDTH] = {WIDTH{select[i]}} & data[i*WIDTH+:WIDTH];
      end

      mux = __reduce_or(ENTRIES, 0, masked_data);
    end
    else begin
      mux = data[0+:WIDTH];
    end
  end
  endfunction

  assign  o_data  = mux(i_select, i_data);
endmodule
