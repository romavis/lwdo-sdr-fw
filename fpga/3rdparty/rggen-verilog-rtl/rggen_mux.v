module rggen_mux #(
  parameter WIDTH   = 1,
  parameter ENTRIES = 2
)(
  input   [ENTRIES-1:0]       i_select,
  input   [WIDTH*ENTRIES-1:0] i_data,
  output  [WIDTH-1:0]         o_data
);

  wire [ENTRIES*WIDTH-1:0] masked_data;
  wire [ENTRIES*WIDTH-1:0] orred_data;

  genvar i;
  generate
    for (i = 0; i < ENTRIES; i = i + 1) begin
        assign masked_data[i*WIDTH+:WIDTH] = {WIDTH{i_select[i]}} & i_data[i*WIDTH+:WIDTH];
        if ( i == 0 ) begin
          assign orred_data[i*WIDTH+:WIDTH] = masked_data[i*WIDTH+:WIDTH];
        end else begin
          assign orred_data[i*WIDTH+:WIDTH] = orred_data[(i-1)*WIDTH+:WIDTH] | masked_data[i*WIDTH+:WIDTH];
        end
    end
  endgenerate

  assign  o_data  = orred_data[(ENTRIES-1)*WIDTH+:WIDTH];
endmodule
