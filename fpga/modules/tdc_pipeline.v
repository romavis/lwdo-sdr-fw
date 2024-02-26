/****************************************************************************

                            ---- tdc_pipeline ----

Logic that performs phase difference measurement using TDC.

****************************************************************************/

module tdc_pipeline #(
    parameter COUNTER_WIDTH = 32,
    parameter COUNTER_BYTES = 4,
    parameter DIV_GATE = 2000000,
    parameter DIV_MEAS_FAST = 100000,
    parameter FF_SYNC_DEPTH = 2
) (
    // Main clock domain
    input i_clk,
    input i_rst,
    // TDC clock domain
    input i_clk_tdc,
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

    localparam TDC_TOT_WIDTH = COUNTER_WIDTH * 3;
    localparam TDC_PAD_WIDTH = COUNTER_BYTES * 8;
    localparam TDC_PAD_TOT_BYTES = COUNTER_BYTES * 3;
    localparam TDC_PAD_TOT_WIDTH = TDC_PAD_TOT_BYTES * 8;

    // ====================================================================
    //                      Wires and registers
    // ====================================================================

    // Resets for i_clk_tdc / i_clk_gate / i_clk_meas domains
    wire rst_tdc;
    wire rst_gate;
    wire rst_meas;
    // Divided clk_gate
    wire clk_gate_div;
    // Divided clk_meas
    wire clk_meas_div_fast;
    // Signals resynchronized into i_clk_tdc domain
    wire tdc_clk_gate_div;
    wire tdc_clk_meas;
    wire tdc_clk_meas_div_fast;
    wire tdc_meas_fast;
    // S0 and S1 TDC signals
    wire [1:0] tdc_s;
    // Edge detected S0 and S1
    reg [1:0] tdc_s_q;
    wire [1:0] tdc_s_pulse;
    // Wide TDC AXI-S bus (i_clk_tdc domain)
    wire [TDC_TOT_WIDTH-1:0] tdc_tdata;
    wire tdc_tvalid;
    wire tdc_tready;
    // Wide TDC AXI-S bus (i_clk comain)
    wire [TDC_TOT_WIDTH-1:0] sync_tdata;
    wire sync_tvalid;
    wire sync_tready;
    // Padded TDC AXI-S bus
    reg [TDC_PAD_TOT_WIDTH-1:0] pad_tdata;
    reg pad_tvalid;
    wire pad_tready;

    // ====================================================================
    //                          Implementation
    // ====================================================================

    rst_bridge u_rst_bridge_tdc (
        .clk(i_clk_tdc),
        .rst(i_rst),
        .out(rst_tdc)
    );

    rst_bridge u_rst_bridge_gate (
        .clk(i_clk_gate),
        .rst(i_rst),
        .out(rst_gate)
    );

    rst_bridge u_rst_bridge_meas (
        .clk(i_clk_meas),
        .rst(i_rst),
        .out(rst_meas)
    );

    // clk_gate divider
    wire [DIV_GATE_BITS-1:0] _div_gate_n = DIV_GATE - 1;
    fastcounter #(
        .NBITS(DIV_GATE_BITS)
    ) u_div_gate (
        .i_clk(i_clk_gate),
        .i_rst(rst_gate),
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
        .i_rst(rst_meas),
        //
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(1'b1),
        .i_load(1'b0),
        .i_load_q(_div_meas_fast_n),
        .o_carry_dly(clk_meas_div_fast)
    );

    // clock domain crossing into i_clk_tdc domain
    ff_sync #(
        .DEPTH(FF_SYNC_DEPTH)
    ) u_sync_clk_gate (
        .i_clk(i_clk_tdc),
        .i_rst(rst_tdc),
        .i_d(clk_gate_div),
        .o_q(tdc_clk_gate_div)
    );

    ff_sync #(
        .DEPTH(FF_SYNC_DEPTH)
    ) u_sync_clk_meas (
        .i_clk(i_clk_tdc),
        .i_rst(rst_tdc),
        .i_d(i_clk_meas),
        .o_q(tdc_clk_meas)
    );

    ff_sync #(
        .DEPTH(FF_SYNC_DEPTH)
    ) u_sync_clk_meas_div_fast (
        .i_clk(i_clk_tdc),
        .i_rst(rst_tdc),
        .i_d(clk_meas_div_fast),
        .o_q(tdc_clk_meas_div_fast)
    );

    ff_sync #(
        .DEPTH(FF_SYNC_DEPTH)
    ) u_sync_meas_fast (
        .i_clk(i_clk_tdc),
        .i_rst(rst_tdc),
        .i_d(i_meas_fast),
        .o_q(tdc_meas_fast)
    );

    // TDC S0, S1 signals
    assign tdc_s[0] = tdc_clk_gate_div;
    assign tdc_s[1] = tdc_meas_fast ? tdc_clk_meas_div_fast : tdc_clk_meas;

    // Positive edge detector
    always @(posedge i_clk_tdc or posedge rst_tdc) begin
        if (rst_tdc) begin
            tdc_s_q <= 1'b0;
        end else begin
            tdc_s_q <= tdc_s;
        end
    end

    assign tdc_s_pulse = tdc_s & ~tdc_s_q;

    // TDC
    tdc #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .DATA_WIDTH(TDC_TOT_WIDTH)
    ) u_tdc (
        .i_clk(i_clk_tdc),
        .i_rst(rst_tdc),
        .i_s0(tdc_s_pulse[0]),
        .i_s1(tdc_s_pulse[1]),
        .o_m_axis_tdata(tdc_tdata),
        .o_m_axis_tvalid(tdc_tvalid),
        .i_m_axis_tready(tdc_tready)
    );

    // AsyncFIFO clock domain crossing using
    axis_async_fifo #(
        .DEPTH(32),
        .DATA_WIDTH(TDC_TOT_WIDTH),
        .KEEP_ENABLE(0),
        .LAST_ENABLE(0),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .RAM_PIPELINE(1),
        .OUTPUT_FIFO_ENABLE(0),
        .FRAME_FIFO(0),
        .PAUSE_ENABLE(0)
    ) u_async_fifo (
        .s_clk(i_clk_tdc),
        .s_rst(rst_tdc),
        .s_axis_tdata(tdc_tdata),
        .s_axis_tvalid(tdc_tvalid),
        .s_axis_tready(tdc_tready),
        //
        .m_clk(i_clk),
        .m_rst(i_rst),
        .m_axis_tdata(sync_tdata),
        .m_axis_tvalid(sync_tvalid),
        .m_axis_tready(sync_tready),
    );

    // Repack TDC AXI-S to align with bytes
    assign sync_tready = pad_tready;
    integer ii;
    always @* begin
        pad_tvalid = sync_tvalid;
        for (ii = 0; ii < 3; ii = ii + 1) begin
            pad_tdata[(ii+1)*TDC_PAD_WIDTH-1:ii*TDC_PAD_WIDTH] =
                sync_tdata[(ii+1)*COUNTER_WIDTH-1:ii*COUNTER_WIDTH];
        end
    end

    // AXI-S serializer
    axis_adapter #(
        .S_DATA_WIDTH(TDC_PAD_TOT_WIDTH),
        .S_KEEP_ENABLE(1),
        .S_KEEP_WIDTH(TDC_PAD_TOT_BYTES),
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
        .s_axis_tdata(pad_tdata),
        .s_axis_tkeep({TDC_PAD_TOT_BYTES{1'b1}}),
        .s_axis_tvalid(pad_tvalid),
        .s_axis_tready(pad_tready),
        .s_axis_tlast(1'b1),
        //
        .m_axis_tdata(o_m_axis_tdata),
        .m_axis_tkeep(o_m_axis_tkeep),
        .m_axis_tvalid(o_m_axis_tvalid),
        .m_axis_tready(i_m_axis_tready),
        .m_axis_tlast(o_m_axis_tlast)
    );

endmodule
