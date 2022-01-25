module clkdiv #(parameter
  RATIO = 1
)(
  input i_clk,
  input i_en,
  output o_clk,
  output o_cycle
);

generate
  if (RATIO == 1) begin
    
    reg r_gate;
    
    always @(posedge i_clk) begin
      r_gate <= i_en;
    end
    
    assign o_clk = i_clk & r_gate;
    assign o_cycle = r_gate;
  
  end else begin
    
    localparam CWIDTH = $clog2(RATIO);
    
    reg [CWIDTH-1:0] r_counter;
    reg r_out;
    reg r_cycle;
  
    always @(posedge i_clk) begin
      if (!i_en) begin
        r_counter <= 'd0;
        r_out <= 0;
        r_cycle <= 0;
      end else begin
        if (r_counter == 'd0) begin
          r_counter <= RATIO - 1;
          r_out <= 1;
        end else begin
          r_counter <= r_counter - 1;
          r_out <= (r_counter > RATIO / 2) ? 1 : 0; 
        end
        r_cycle <= (r_counter == 'd1) ? 1 : 0;
      end
    end
  
    assign o_clk = r_out;
    assign o_cycle = r_cycle;
    
  end
endgenerate
  
endmodule
