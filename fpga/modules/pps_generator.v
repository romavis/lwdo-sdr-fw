/****************************************************************************

                        ---- pps_generator ----

PPS (pulse per second) generator with variable pulse width and timestamping.

****************************************************************************/


module pps_generator #(
    // PPS divider counter width
    parameter RATE_DIV_WIDTH = 28,
    // Width of PPS pulse width generator counter
    parameter PULSE_WIDTH_WIDTH = RATE_DIV_WIDTH,
    // Timestamp counter width
    parameter TS_WIDTH = 32,
    // Number of bytes transmitted for timestamp counter
    parameter TS_BYTES = (TS_WIDTH + 7) / 8,
) (
    input i_clk,
    input i_rst,
    // Gate
    input i_en,
    // Divider settings
    input [RATE_DIV_WIDTH-1:0] i_rate_div,
    input [PULSE_WIDTH_WIDTH-1:0] i_pulse_width,
    // Timestamp counter
    input [TS_WIDTH-1:0] i_ts,
    // 8-bit packeted AXI-S output for timestamps
    output [7:0] o_m_axis_ts_tdata,
    output o_m_axis_ts_tkeep,
    output o_m_axis_ts_tvalid,
    input i_m_axis_ts_tready,
    output o_m_axis_ts_tlast,
    // PPS 1-clock-wide pulse (for timing)
    output o_pps_sample,
    // PPS width-formed pulse (for output to outside)
    output o_pps_formed //
);

    // ====================================================================
    //                      Wires and registers
    // ====================================================================

    // PPS divider
    reg [RATE_DIV_WIDTH-1:0] pps_rate_ctr;
    reg pps_sample;
    // PPS width generator
    reg [PULSE_WIDTH_WIDTH-1:0] pps_pwidth_ctr;
    reg pps_formed;
    // Timestamping mechanism
    reg [TS_WIDTH-1:0] ts_tdata;
    reg ts_tvalid;
    wire ts_tready;

    // ====================================================================
    //                          Implementation
    // ====================================================================

    // PPS rate generator
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pps_rate_ctr <= 1'd0;
            pps_sample <= 1'b0;
        end else begin
            if (i_en) begin
                if (pps_rate_ctr) begin
                    pps_rate_ctr <= pps_rate_ctr - 1'd1;
                    pps_sample <= 1'b0;
                end else begin
                    pps_rate_ctr <= i_rate_div;
                    pps_sample <= 1'b1;
                end
            end else begin
                pps_sample <= 1'b0;
            end
        end
    end

    // PPS pulse width former
    // Width = (i_pps_pwidth + 1) i_clk cycles
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pps_pwidth_ctr <= 1'd0;
            pps_formed <= 1'b0;
        end else begin
            if (pps_sample) begin
                pps_pwidth_ctr <= i_pulse_width;
                pps_formed <= 1'b1;
            end else begin
                if (pps_pwidth_ctr) begin
                    pps_pwidth_ctr <= pps_pwidth_ctr - 1'd1;
                end else begin
                    pps_formed <= 1'b0;
                end
            end
        end
    end

    // Timestamping mechanism
    // Fires on each PPS sample, puts data into the TS AXI-S stream.
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            ts_tdata <= 1'b0;
            ts_tvalid <= 1'b0;
        end else begin
            if (pps_sample) begin
                if (!ts_tvalid || ts_tready) begin
                    ts_tdata <= i_ts;
                    ts_tvalid <= 1'b1;
                end
            end else if (ts_tvalid && ts_tready) begin
                ts_tvalid <= 1'b0;
            end
        end
    end

    // Serialize timestamp stream
    axis_adapter #(
        .S_DATA_WIDTH(TS_WIDTH),
        .S_KEEP_ENABLE(1),
        .S_KEEP_WIDTH(TS_BYTES),
        .M_DATA_WIDTH(8),
        .M_KEEP_ENABLE(1),
        .M_KEEP_WIDTH(1),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0)
    ) u_ts_serializer (
        .clk(i_clk),
        .rst(i_rst),
        //
        .s_axis_tdata(ts_tdata),
        .s_axis_tkeep({TS_BYTES{1'b1}}),
        .s_axis_tvalid(ts_tvalid),
        .s_axis_tready(ts_tready),
        .s_axis_tlast(1'b1),
        //
        .m_axis_tdata(o_m_axis_ts_tdata),
        .m_axis_tkeep(o_m_axis_ts_tkeep),
        .m_axis_tvalid(o_m_axis_ts_tvalid),
        .m_axis_tready(i_m_axis_ts_tready),
        .m_axis_tlast(o_m_axis_ts_tlast)
    );

    assign o_pps_sample = pps_sample;
    assign o_pps_formed = pps_formed;

endmodule
