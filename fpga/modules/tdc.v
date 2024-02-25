/****************************************************************************

                                ---- tdc ----

TDC - Time to Digital Converter. This can be used as a phase detector.

****************************************************************************/

module tdc #(
    parameter COUNTER_WIDTH = 32,
    parameter DATA_WIDTH = 3 * COUNTER_WIDTH
) (
    input i_clk,
    input i_rst,
    // Time signals:
    //  s0 - gate pulse
    //  s1 - measured pulse
    // Both should be synchronized to @(posedge i_clk) domain
    input i_s0,
    input i_s1,
    // Output readings
    output [DATA_WIDTH-1:0] o_m_axis_tdata,
    output o_m_axis_tvalid,
    input i_m_axis_tready
);

    // Counter
    reg [COUNTER_WIDTH-1:0] cnt_reg;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cnt_reg <= 1'd0;
        end else begin
            if (i_s0) begin
                cnt_reg <= 1'd0;
            end else begin
                cnt_reg <= cnt_reg + 1'd1;
            end
        end
    end


    // T1, T2 recording
    reg [COUNTER_WIDTH-1:0] t1_reg;
    reg [COUNTER_WIDTH-1:0] t2_reg;
    reg t12_valid_reg;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            t1_reg <= 1'b0;
            t2_reg <= 1'b0;
            t12_valid_reg <= 1'b0;
        end else begin
            if (i_s0) begin
                // reset
                t1_reg <= 1'b0;
                t2_reg <= 1'b0;
                t12_valid_reg <= 1'b0;
            end else if (i_s1) begin
                // record t2 and optionally t1
                if (!t12_valid_reg) begin
                    t1_reg <= cnt_reg;
                end
                t2_reg <= cnt_reg;
                t12_valid_reg <= 1'b1;
            end
        end
    end

    // Data holding registers
    reg [COUNTER_WIDTH-1:0] data_t0_reg;
    reg [COUNTER_WIDTH-1:0] data_t1_reg;
    reg [COUNTER_WIDTH-1:0] data_t2_reg;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            data_t0_reg <= 1'd0;
            data_t1_reg <= 1'd0;
            data_t2_reg <= 1'd0;
        end else begin
            if (i_s0) begin
                data_t0_reg <= cnt_reg;
                if (!i_s1) begin
                    // Copy recorded values
                    if (t12_valid_reg) begin
                        data_t1_reg <= t1_reg;
                        data_t2_reg <= t2_reg;
                    end else begin
                        // If T1-2 invalid, fill them with 1's
                        data_t1_reg <= {COUNTER_WIDTH{1'b1}};
                        data_t2_reg <= {COUNTER_WIDTH{1'b1}};
                    end
                end else begin
                    // It's too late to copy from T1-2,
                    // make values on the spot
                    if (t12_valid_reg) begin
                        data_t1_reg <= t1_reg;
                    end else begin
                        data_t1_reg <= cnt_reg;
                    end
                    data_t2_reg <= cnt_reg;
                end
            end
        end
    end

    // AXI-S handshake
    reg axis_tvalid_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            axis_tvalid_reg <= 1'b0;
        end else begin
            if (i_s0) begin
                axis_tvalid_reg <= 1'b1;
            end else if (i_m_axis_tready) begin
                axis_tvalid_reg <= 1'b0;
            end
        end
    end

    assign o_m_axis_tvalid = axis_tvalid_reg;
    assign o_m_axis_tdata =
        {data_t2_reg, data_t1_reg, data_t0_reg};

endmodule
