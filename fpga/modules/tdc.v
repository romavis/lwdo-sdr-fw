/****************************************************************************

                                ---- tdc ----

TDC - Time to Digital Converter. This can be used as a phase detector.

****************************************************************************/

module tdc #(
    parameter COUNTER_WIDTH = 32,
    // TDATA is:
    // {t12_valid[0], t2[CW-1:0], t1[CW-1:0], t0[CW-1:0]}
    parameter DATA_WIDTH = 1 + COUNTER_WIDTH * 3
) (
    input i_clk,
    input i_rst,
    // Enable signal
    input i_en,
    // Time signals:
    //  s0 - gate pulse
    //  s1 - measured pulse
    // Both should be synchronized to @(posedge i_clk) domain
    input [1:0] i_s,
    // Output readings
    output [DATA_WIDTH-1:0] o_m_axis_tdata,
    output o_m_axis_tvalid,
    input i_m_axis_tready
);

    // Gated & registered s0 and s1
    reg [1:0] sg;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            sg <= 1'b0;
        end else begin
            sg <= i_s & {2{i_en}};
        end
    end

    // Counter
    reg [COUNTER_WIDTH-1:0] cnt_q0;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cnt_q0 <= 1'd0;
        end else begin
            if (sg[0] || !i_en) begin
                cnt_q0 <= 1'd0;
            end else begin
                cnt_q0 <= cnt_q0 + 1'd1;
            end
        end
    end

    // Register counter, s0 and s1
    reg [COUNTER_WIDTH-1:0] cnt_q1;
    reg [1:0] s_q1;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cnt_q1 <= 1'd0;
            s_q1 <= 1'd0;
        end else begin
            cnt_q1 <= cnt_q0;
            s_q1 <= sg;
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
            if (s_q1[0]) begin
                // reset
                t1_reg <= 1'b0;
                t2_reg <= 1'b0;
                t12_valid_reg <= 1'b0;
            end else if (s_q1[1]) begin
                // record t2 and optionally t1
                if (!t12_valid_reg) begin
                    t1_reg <= cnt_q1;
                end
                t2_reg <= cnt_q1;
                t12_valid_reg <= 1'b1;
            end
        end
    end

    // Data holding registers
    reg [COUNTER_WIDTH-1:0] data_t0_reg;
    reg [COUNTER_WIDTH-1:0] data_t1_reg;
    reg [COUNTER_WIDTH-1:0] data_t2_reg;
    reg data_t12_valid_reg;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            data_t0_reg <= 1'd0;
            data_t1_reg <= 1'd0;
            data_t2_reg <= 1'd0;
        end else begin
            if (s_q1[0]) begin
                data_t0_reg <= cnt_q1;
                if (!s_q1[1]) begin
                    // Copy recorded values
                    data_t12_valid_reg <= t12_valid_reg;
                    data_t1_reg <= t1_reg;
                    data_t2_reg <= t2_reg;
                end else begin
                    // It's too late to copy from T1-2,
                    // make values on the spot
                    data_t12_valid_reg <= 1'b1;
                    if (t12_valid_reg) begin
                        data_t1_reg <= t1_reg;
                    end else begin
                        data_t1_reg <= cnt_q1;
                    end
                    data_t2_reg <= cnt_q1;
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
            if (s_q1[0]) begin
                axis_tvalid_reg <= 1'b1;
            end else if (i_m_axis_tready) begin
                axis_tvalid_reg <= 1'b0;
            end
        end
    end

    assign o_m_axis_tvalid = axis_tvalid_reg;
    assign o_m_axis_tdata =
        {data_t12_valid_reg, data_t2_reg, data_t1_reg, data_t0_reg};

endmodule
