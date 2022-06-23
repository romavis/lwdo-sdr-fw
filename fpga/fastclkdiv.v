module fastclkdiv_ctr_ #(
    parameter NBITS = 3
) (
    input i_clk,
    input i_en,
    input i_load,
    input [NBITS-1:0] i_load_q,
    output [NBITS-1:0] o_q,
    output o_zero
);

    reg [NBITS-1:0] count;
    reg zero;

    wire aend;
    assign aend = (count == {{NBITS-1{1'b0}}, 1'b1});

    always @(posedge i_clk) begin
        if (i_load) begin
            count <= i_load_q;
            zero <= (i_load_q == {NBITS{1'b0}});
        end else begin
            if (i_en) begin
                count <= count - {{NBITS-1{1'b0}}, 1'b1};
                zero <= aend;
            end
        end
    end

    assign o_q = count;
    assign o_zero = zero & i_en;

endmodule


module fastclkdiv #(
    parameter NBITS = 10,
    parameter NBITS_STAGE = 9   // default value good for iCE40
) (
    input i_clk,
    input i_en,
    input i_load,
    input i_autoreload_en,
    input [NBITS-1:0] i_load_q,
    output [NBITS-1:0] o_q,
    output o_zero
);

    localparam NSTAGES = ((NBITS + NBITS_STAGE - 1) / NBITS_STAGE); // ceil
    localparam NLBITS = NBITS - (NSTAGES-1) * NBITS_STAGE;
 
    // END (ZERO) outputs of all stages
    wire [NSTAGES-1:0] st_end;
    // EN inputs of all stages
    wire [NSTAGES-1:0] st_en;

    // Load logic
    wire load;
    assign load = i_load || (i_autoreload_en && o_zero);

    // Carry logic
    assign st_en[0] = i_en;
    generate
        if(NSTAGES > 1)
            assign st_en[NSTAGES-1:1] = st_end[NSTAGES-2:0];
    endgenerate

    // Counter modules
    genvar ii;
    generate
        for (ii = 0; ii < NSTAGES; ii = ii + 1) begin
            if (ii < NSTAGES-1) begin
                fastclkdiv_ctr_ #(
                    .NBITS(NBITS_STAGE)
                ) ctr (
                    .i_clk(i_clk),
                    .i_en(st_en[ii]),
                    .i_load(load),
                    .i_load_q(i_load_q[(ii+1)*NBITS_STAGE-1:ii*NBITS_STAGE]),
                    .o_q(o_q[(ii+1)*NBITS_STAGE-1:ii*NBITS_STAGE]),
                    .o_zero(st_end[ii])
                );
            end else begin
                fastclkdiv_ctr_ #(
                    .NBITS(NLBITS)
                ) ctr (
                    .i_clk(i_clk),
                    .i_en(st_en[ii]),
                    .i_load(load),
                    .i_load_q(i_load_q[NBITS-1:ii*NBITS_STAGE]),
                    .o_q(o_q[NBITS-1:ii*NBITS_STAGE]),
                    .o_zero(st_end[ii])
                );
            end
        end
    endgenerate

    assign o_zero = st_end[NSTAGES-1];

endmodule