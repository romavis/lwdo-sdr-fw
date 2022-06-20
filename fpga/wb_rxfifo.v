// Bridge that reads data from a data/valid/ready stream into FIFO
// and provides read-only access to that FIFO over wishbone

module wb_rxfifo #(
    parameter FIFO_ADDR_WIDTH = 5
) (
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Wishbone bus slave
    input i_wb_cyc,
    input i_wb_stb,
    input i_wb_we,
    output o_wb_stall,
    output o_wb_ack,
    output [31:0] o_wb_data,
    // Input data stream sink
    input i_rx_valid,
    output o_rx_ready,
    input [31:0] i_rx_data,
    // Status
    output [FIFO_ADDR_WIDTH-1:0] o_fifo_count,
    output o_fifo_empty,
    output o_fifo_full,
    output o_fifo_half_full,
    output o_fifo_overflow,
    output o_fifo_underflow
);

    //
    // SysCon
    //
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    //
    // FIFO
    //

    wire [31:0] fifo_wr_data;
    wire [31:0] fifo_rd_data;
    wire fifo_wr, fifo_rd;

    syncfifo #(
        .ADDR_WIDTH(FIFO_ADDR_WIDTH),
        .DATA_WIDTH(32)
    ) fifo (
        .i_clk(clk),
        .i_rst(rst),
        .i_data(fifo_wr_data),
        .o_data(fifo_rd_data),
        .i_wr(fifo_wr),
        .i_rd(fifo_rd),
        // status bits
        .o_count(o_fifo_count),
        .o_empty(o_fifo_empty),
        .o_full(o_fifo_full),
        .o_half_full(o_fifo_half_full),
        .o_overflow(o_fifo_overflow),
        .o_underflow(o_fifo_underflow)
    );

    //
    // Input stream -> FIFO
    //
    assign fifo_wr_data = i_rx_data;
    assign o_rx_ready = !o_fifo_full;
    assign fifo_wr = i_rx_valid && o_rx_ready;

    //
    // FIFO -> wishbone
    //

    reg wb_ack;
    reg wb_we;
    always @(posedge clk) begin
        if (rst) begin
            wb_ack <= 1'b0;
            wb_we <= 1'b0;
        end else begin
            wb_ack <= 1'b0;
            wb_we <= 1'b0;
            if (i_wb_cyc && i_wb_stb) begin
                // acknowledge transfer on the next cycle
                wb_ack <= 1'b1;
                wb_we <= i_wb_we;
            end
        end
    end
    
    // Read from FIFO during ACK phase of a read WB transfer
    assign fifo_rd = wb_ack && !wb_we;
    // WB read bus & status
    assign o_wb_data = fifo_rd_data;
    assign o_wb_ack = wb_ack;
    assign o_wb_stall = 1'b0;   // never stall

endmodule