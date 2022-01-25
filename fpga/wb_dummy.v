module wb_dummy (
    // Clock (posedge) and sync reset
    input i_clk,
    // Wishbone bus slave
    input i_wb_cyc,
    input i_wb_stb,
    output o_wb_stall,
    output o_wb_ack,
    output [31:0] o_wb_data
);

    reg r_ack;

    assign o_wb_data = 32'hDEADBEEF;
    assign o_wb_stall = 1'b0;
    assign o_wb_ack = r_ack;

    always @(posedge i_clk) begin
        r_ack <= 1'b0;
        if (i_wb_cyc) begin
            if (i_wb_stb) begin
                r_ack <= 1'b1;
            end
        end
    end

endmodule