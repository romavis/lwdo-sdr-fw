module dac8551 #(
    parameter CLK_DIV = 10  // SPI clock is: f(spi) = f(i_clk)/(2*CLK_DIV)
) (
    // SysCon
    input i_clk,
    input i_rst,
    // Data bus: data to be written and WR strobe
    input i_wr,
    input [23:0] i_wr_data,
    // DAC pins
    output o_dac_sclk,
    output o_dac_mosi,
    output o_dac_sync_n,
    // Status
    output o_busy
);

    localparam CLK_DIV_BITS = $clog2(CLK_DIV);

    // CLK & RST
    wire clk, rst;
    assign clk = i_clk;
    assign rst = i_rst;

    // Data latch
    reg latch_valid;
    reg [23:0] latch_data;

    always @(posedge clk) begin
        if (rst) begin
            latch_valid <= 1'b0;
            latch_data <= 24'b0;
        end else begin
            if (i_wr) begin
                latch_valid <= 1'b1;
                latch_data <= i_wr_data;
            end
        end
    end

    reg [23:0] dac_reg;
    reg [4:0] dac_cycle;
    reg [CLK_DIV_BITS-1:0] dac_div;
    reg dac_spi_clk;
    reg dac_spi_sync_n;

    always @(posedge clk) begin
        if (rst) begin
            dac_reg <= 24'b0;
            dac_cycle <= 5'd0;
            dac_div <= {CLK_DIV_BITS{1'b0}};
            dac_spi_clk <= 1'b0;
            dac_spi_sync_n <= 1'b1;
        end else begin
            if (dac_div) begin
                dac_div <= dac_div - {{CLK_DIV_BITS-1{1'b0}}, 1'b1};
            end else begin
                dac_div <= CLK_DIV - 1;
                dac_spi_clk <= ~dac_spi_clk;
                // clock dac state machine on the positive SPI CLK edge
                if (!dac_spi_clk) begin
                    if (dac_cycle == 5'd0) begin
                        if (latch_valid) begin
                            // Load word to shift, assert nSYNC
                            dac_reg <= latch_data;
                            dac_spi_sync_n <= 1'b0;
                            dac_cycle <= 5'd1;
                            // Reset latch
                            if (!i_wr) begin
                                latch_valid <= 1'b0;
                            end
                        end
                    end else if(dac_cycle < 5'd24) begin
                        // shift
                        dac_reg[23:0] <= {dac_reg[22:0], 1'b0};
                        dac_cycle <= dac_cycle + 5'd1;
                    end else if(dac_cycle < 5'd26) begin 
                        // Deassert nSYNC and reset MOSI
                        dac_spi_sync_n <= 1'b1;
                        dac_reg <= 24'b0;
                        dac_cycle <= dac_cycle + 5'd1;
                    end else begin
                        // Reset dac_cycle
                        dac_cycle <= 5'd0;
                    end
                end 
            end
        end
    end

    assign o_dac_mosi = dac_reg[23];
    assign o_dac_sync_n = dac_spi_sync_n;
    assign o_dac_sclk = dac_spi_clk | dac_spi_sync_n; // gated clock output
    assign o_busy = latch_valid || (dac_cycle != 5'd0);

endmodule