module wb_mem #(
    parameter WB_ADDR_WIDTH = 6
)
(
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Wishbone bus slave
    input i_wb_cyc,
    input i_wb_stb,
    output o_wb_stall,
    output o_wb_ack,
    input i_wb_we,
    input [WB_ADDR_WIDTH-1:0] i_wb_addr,
    input [31:0] i_wb_data,
    input [3:0] i_wb_sel,
    output [31:0] o_wb_data
);

    localparam MEM_NWORDS = 1 << WB_ADDR_WIDTH;

    // Memory
    reg [31:0] mem [0:MEM_NWORDS-1];

    integer i;
    initial begin
        for (i = 0; i < MEM_NWORDS; i = i + 1) begin
            mem[i] <= 32'd0;
        end
    end

    reg r_ack;
    reg [31:0] r_data_rd;
    always @(posedge i_clk) begin
        r_ack <= 1'b0;
        if (i_wb_cyc && i_wb_stb) begin
            r_ack <= 1'b1;
            if (i_wb_we) begin
                // Handle WB write request
                if (i_wb_sel[0]) mem[i_wb_addr][7:0] <= i_wb_data [7:0];
                if (i_wb_sel[1]) mem[i_wb_addr][15:8] <= i_wb_data [15:8];
                if (i_wb_sel[2]) mem[i_wb_addr][23:16] <= i_wb_data [23:16];
                if (i_wb_sel[3]) mem[i_wb_addr][31:24] <= i_wb_data [31:24];
            end else begin
                // Handle WB read request
                r_data_rd <= mem[i_wb_addr];
            end
        end
    end

    //
    // Outputs
    //
    assign o_wb_stall = 1'b0;
    assign o_wb_ack = r_ack;
    assign o_wb_data = r_data_rd;

endmodule