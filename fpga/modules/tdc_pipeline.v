/****************************************************************************

                            ---- tdc_pipeline ----

Logic that performs phase difference measurement using TDC.

****************************************************************************/

module tdc_pipeline #(
    parameter COUNTER_WIDTH = 32,
    parameter DIV_GATE = 2000000,
    parameter DIV_MEAS_FAST = 100000,
    parameter FF_SYNC_DEPTH = 2
) (
    input i_clk,
    input i_rst,
    // 8-bit AXI-S output
    output [7:0] o_m_axis_tdata,
    output o_m_axis_tkeep,
    output o_m_axis_tvalid,
    input i_m_axis_tready,
    output o_m_axis_tlast,
    // Asynchronous input signals
    input i_clk_gate,
    input i_clk_meas,
    // Control
    input i_meas_fast   // if 1, DIV_MEAS_FAST is used; if 0, no division
);

    localparam DIV_GATE_BITS = $clog2(DIV_GATE);
    localparam DIV_MEAS_FAST_BITS = $clog2(DIV_MEAS_FAST);

    localparam TDC_DATA_WIDTH = COUNTER_WIDTH * 3;
    localparam TDC_DATA_BYTES = (TDC_DATA_WIDTH + 7) / 8;

    // ====================================================================
    //                      Wires and registers
    // ====================================================================

    // Resets for i_clk_gate / i_clk_meas domains
    wire clk_gate_rst;
    wire clk_meas_rst;
    // Divided clk_gate
    wire clk_gate_div;
    // Divided clk_meas
    wire clk_meas_div_fast;
    // Clocks resynchronized into i_clk domain
    wire sync_clk_gate_div;
    wire sync_clk_meas;
    wire sync_clk_meas_div_fast;
    // S0 and S1 TDC signals
    wire [1:0] tdc_s;
    // Edge detected S0 and S1
    reg [1:0] tdc_s_q;
    wire [1:0] tdc_s_pulse;
    // Wide TDC AXI-S bus
    wire [TDC_DATA_WIDTH-1:0] tdc_tdata;
    wire tdc_tvalid;
    wire tdc_tready;

    // ====================================================================
    //                          Implementation
    // ====================================================================

    rst_bridge u_rst_bridge_gate (
        .clk(i_clk_gate),
        .rst(i_rst),
        .out(clk_gate_rst)
    );

    rst_bridge u_rst_bridge_meas (
        .clk(i_clk_meas),
        .rst(i_rst),
        .out(clk_meas_rst)
    );

    // clk_gate divider
    wire [DIV_GATE_BITS-1:0] _div_gate_n = DIV_GATE - 1;
    fastcounter #(
        .NBITS(DIV_GATE_BITS)
    ) u_div_gate (
        .i_clk(i_clk_gate),
        .i_rst(clk_gate_rst),
        //
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(1'b1),
        .i_load(1'b0),
        .i_load_q(_div_gate_n),
        .o_carry_dly(clk_gate_div)
    );

    // clk_meas divider
    wire [DIV_MEAS_FAST_BITS-1:0] _div_meas_fast_n = DIV_MEAS_FAST - 1;
    fastcounter #(
        .NBITS(DIV_MEAS_FAST_BITS)
    ) u_div_meas_fast (
        .i_clk(i_clk_meas),
        .i_rst(clk_meas_rst),
        //
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(1'b1),
        .i_load(1'b0),
        .i_load_q(_div_meas_fast_n),
        .o_carry_dly(clk_meas_div_fast)
    );

    // clock domain crossing
    ff_sync #(
        .DEPTH(FF_SYNC_DEPTH)
    ) u_sync_gate (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_d(clk_gate_div),
        .o_q(sync_clk_gate_div)
    );

    ff_sync #(
        .DEPTH(FF_SYNC_DEPTH)
    ) u_sync_meas (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_d(i_clk_meas),
        .o_q(sync_clk_meas)
    );

    ff_sync #(
        .DEPTH(FF_SYNC_DEPTH)
    ) u_sync_meas_fast (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_d(clk_meas_div_fast),
        .o_q(sync_clk_meas_div_fast)
    );

    // TDC S0, S1 signals
    assign tdc_s[0] = clk_gate_div;
    assign tdc_s[1] = i_meas_fast ? sync_clk_meas_div_fast : sync_clk_meas;

    // Positive edge detector
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            tdc_s_q <= 1'b0;
        end else begin
            tdc_s_q <= tdc_s;
        end
    end

    assign tdc_s_pulse = tdc_s & ~tdc_s_q;

    // TDC
    tdc #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .DATA_WIDTH(TDC_DATA_WIDTH)
    ) u_tdc (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_s0(tdc_s_pulse[0]),
        .i_s1(tdc_s_pulse[1]),
        .o_m_axis_tdata(tdc_tdata),
        .o_m_axis_tvalid(tdc_tvalid),
        .i_m_axis_tready(tdc_tready)
    );

    // AXI-S serializer
    axis_adapter #(
        .S_DATA_WIDTH(TDC_DATA_WIDTH),
        .S_KEEP_ENABLE(1),
        .S_KEEP_WIDTH(TDC_DATA_BYTES),
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
        .s_axis_tdata(tdc_tdata),
        .s_axis_tkeep({TDC_DATA_BYTES{1'b1}}),
        .s_axis_tvalid(tdc_tvalid),
        .s_axis_tready(tdc_tready),
        .s_axis_tlast(1'b1),
        //
        .m_axis_tdata(o_m_axis_tdata),
        .m_axis_tkeep(o_m_axis_tkeep),
        .m_axis_tvalid(o_m_axis_tvalid),
        .m_axis_tready(i_m_axis_tready),
        .m_axis_tlast(o_m_axis_tlast)
    );

endmodule
