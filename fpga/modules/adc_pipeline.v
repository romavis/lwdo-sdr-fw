/****************************************************************************

                        ---- adc_pipeline ----

Implements data pipeline for AD7357.

****************************************************************************/


module adc_pipeline #(
    // Number of ADC channels
    parameter ADC_NUM_CHANNELS = 4,
    // Hardware ADC resolution (bits)
    parameter ADC_CHN_WIDTH = 14,
    // Number of bytes output per channel
    parameter ADC_CHN_BYTES = (ADC_CHN_WIDTH + 7) / 8,
    // Timestamp counter width
    parameter TIMESTAMP_WIDTH = 32,
    // Number of bytes transmitted for timestamp counter
    parameter TIMESTAMP_BYTES = (TIMESTAMP_WIDTH + 7) / 8,
    // ADC/TS FIFO depth
    parameter FIFO_DEPTH = 512
) (
    input i_clk,
    input i_rst,
    // ADC pins
    // DDR output:
    //  _h - latch on ddr_clk L->H, output if ddr_clk=H
    //  _l - latch on ddr_clk H->L, output if ddr_clk=L
    // DDR input:
    //  _h - latched when ddr_clk H->L
    //  _l - latched when ddr_clk L->H
    output o_adc_ddr_clk,
    output o_adc_sclk_ddr_h,
    output o_adc_sclk_ddr_l,
    output o_adc_cs_n,
    input [ADC_NUM_CHANNELS-1:0] i_adc_sdata_ddr_h,
    input [ADC_NUM_CHANNELS-1:0] i_adc_sdata_ddr_l,
    // Timestamp counter
    input [TIMESTAMP_WIDTH-1:0] i_timestamp,
    // Channel enable bits
    input [ADC_NUM_CHANNELS-1:0] i_chn_en,
    // Control signals:
    //  sync_acq - 1 clk wide pulse, triggers conversion
    //  sync_ts - 1 clk wide pulse, triggers timestamping of next conversion
    input i_sync_acq,
    input i_sync_ts,
    // 8-bit packeted AXI-S output for ADC data
    output [7:0] o_m_axis_adc_tdata,
    output o_m_axis_adc_tkeep,
    output o_m_axis_adc_tvalid,
    input i_m_axis_adc_tready,
    output o_m_axis_adc_tlast,
    // 8-bit packeted AXI-S output for timestamps
    output [7:0] o_m_axis_ts_tdata,
    output o_m_axis_ts_tkeep,
    output o_m_axis_ts_tvalid,
    input i_m_axis_ts_tready,
    output o_m_axis_ts_tlast   //
);

    localparam TS_WIDTH = TIMESTAMP_WIDTH;

    // Width of flattened ADC bus
    localparam ADC_FLTN_WIDTH = ADC_CHN_WIDTH * ADC_NUM_CHANNELS;
    // Width of muxed ADC/TS AXI-S bus
    localparam ADC_TS_MUX_WIDTH =
        ADC_FLTN_WIDTH > TS_WIDTH ? ADC_FLTN_WIDTH : TS_WIDTH;

    // Width of padded / converted / corrected ADC stream
    localparam ADC_CORR_CHN_WIDTH = ADC_CHN_BYTES * 8;
    localparam ADC_CORR_FLTN_WIDTH = ADC_CORR_CHN_WIDTH * ADC_NUM_CHANNELS;
    localparam ADC_CORR_FLTN_BYTES = ADC_CHN_BYTES * ADC_NUM_CHANNELS;

    localparam ADC_CORR_PAD =
        ADC_CORR_CHN_WIDTH > ADC_CHN_WIDTH ? (ADC_CORR_CHN_WIDTH - ADC_CHN_WIDTH) : 0;

    integer i;

    // ====================================================================
    //                      Wires and registers
    // ====================================================================

    // ADC driver<->clk_gen
    wire adc_ctl_cken;
    // ADC acquisition sync pulse
    wire adc_sample;
    // Raw ADC AXI-S data stream
    wire [ADC_FLTN_WIDTH-1:0] adc_tdata;
    wire adc_tvalid;
    wire adc_tready;
    // Timestamping mechanism
    reg ts_armed;
    reg [TS_WIDTH-1:0] ts_tdata;
    reg ts_tvalid;
    wire ts_tready;
    // Multiplexed ADC / TS stream
    wire adc_ts_tvalid;
    wire adc_ts_tready;
    wire [ADC_TS_MUX_WIDTH-1:0] adc_ts_tdata;
    wire adc_ts_tid;
    // ADC / TS stream after FIFO
    wire fifo_adc_ts_tvalid;
    wire fifo_adc_ts_tready;
    wire [ADC_TS_MUX_WIDTH-1:0] fifo_adc_ts_tdata;
    wire fifo_adc_ts_tid;
    wire fifo_adc_ts_tlast;
    // ADC stream after FIFO (demuxed)
    wire dem_adc_tvalid;
    wire dem_adc_tready;
    wire [ADC_TS_MUX_WIDTH-1:0] dem_adc_tdata_wide;
    wire [ADC_FLTN_WIDTH-1:0] dem_adc_tdata;
    wire dem_adc_tlast;
    // TS stream after FIFO (demuxed)
    wire dem_ts_tvalid;
    wire dem_ts_tready;
    wire [ADC_TS_MUX_WIDTH-1:0] dem_ts_tdata_wide;
    wire [TS_WIDTH-1:0] dem_ts_tdata;
    wire dem_ts_tlast;
    // ADC stream after FIFO and correction
    reg corr_adc_tvalid;
    wire corr_adc_tready;
    reg [ADC_CORR_FLTN_WIDTH-1:0] corr_adc_tdata;
    reg corr_adc_tlast;
    reg [ADC_CORR_FLTN_BYTES-1:0] corr_adc_tkeep;

    // ====================================================================
    //                          Implementation
    // ====================================================================

    ad7357_clk_gen u_adc_clk_gen (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_ctl_cken(adc_ctl_cken),
        .o_adc_ddr_clk(o_adc_ddr_clk),
        .o_adc_sclk_ddr_h(o_adc_sclk_ddr_h),
        .o_adc_sclk_ddr_l(o_adc_sclk_ddr_l)
    );

    // Synchronized acquisition on all channels:
    // all ADCs controlled by a single driver
    ad7357_driver #(
        .DATA_WIDTH(ADC_CHN_WIDTH),
        .NUM_CHANNELS(ADC_NUM_CHANNELS)
    ) u_adc_driver (
        .i_clk(i_clk),
        .i_rst(i_rst),
        // .o_ready(),
        .i_start(i_sync_acq),
        .o_sample(adc_sample),
        .o_m_axis_tdata(adc_tdata),
        .o_m_axis_tvalid(adc_tvalid),
        .i_m_axis_tready(adc_tready),
        .o_adc_cs_n(o_adc_cs_n),
        .i_adc_sdata_ddr_h(i_adc_sdata_ddr_h),
        .i_adc_sdata_ddr_l(i_adc_sdata_ddr_l),
        .o_ctl_cken(adc_ctl_cken)
    );

    // Timestamping mechanism
    // Arms on i_sync_ts, fires on adc_sample, outputs TS AXI-S stream
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            ts_armed <= 1'b0;
            ts_tdata <= 1'b0;
            ts_tvalid <= 1'b0;
        end else begin
            if (i_sync_ts) begin
                ts_armed <= 1'b1;
            end
            if (ts_armed && adc_sample) begin
                ts_armed <= 1'b0;
                if (!ts_tvalid || ts_tready) begin
                    ts_tdata <= i_timestamp;
                    ts_tvalid <= 1'b1;
                end
            end else if (ts_tvalid && ts_tready) begin
                ts_tvalid <= 1'b0;
            end
        end
    end

    // Multiplex ADC and TS streams into a single ADC / TS stream
    // slave 0 - timestamps
    // slave 1 - ADC
    // TID matches slave index
    axis_arb_mux #(
        .S_COUNT(2),
        .DATA_WIDTH(ADC_TS_MUX_WIDTH),
        .KEEP_ENABLE(0),
        .ID_ENABLE(1),
        .S_ID_WIDTH(1),
        .M_ID_WIDTH(1),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .LAST_ENABLE(0),
        .UPDATE_TID(0),
        .ARB_TYPE_ROUND_ROBIN(0),
        .ARB_LSB_HIGH_PRIORITY(1)
    ) u_adc_ts_mux (
        .clk(i_clk),
        .rst(i_rst),
        //
        .s_axis_tdata({
            {{(ADC_TS_MUX_WIDTH-ADC_FLTN_WIDTH){1'b0}}, adc_tdata},
            {{(ADC_TS_MUX_WIDTH-TS_WIDTH){1'b0}}, ts_tdata}}),
        .s_axis_tvalid({adc_tvalid, ts_tvalid}),
        .s_axis_tready({adc_tready, ts_tready}),
        .s_axis_tid({1'b1, 1'b0}),
        //
        .m_axis_tdata(adc_ts_tdata),
        .m_axis_tvalid(adc_ts_tvalid),
        .m_axis_tready(adc_ts_tready),
        .m_axis_tid(adc_ts_tid)
    );

    // Buffer multiplexed ADC / TS stream in the FIFO
    axis_fifo #(
        .DEPTH(FIFO_DEPTH),
        .DATA_WIDTH(ADC_TS_MUX_WIDTH),
        .KEEP_ENABLE(0),
        .LAST_ENABLE(0),
        .ID_ENABLE(1),
        .ID_WIDTH(1),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .RAM_PIPELINE(1),
        .OUTPUT_FIFO_ENABLE(0),
        .FRAME_FIFO(0)
    ) u_adc_ts_fifo (
        .clk(i_clk),
        .rst(i_rst),
        //
        .s_axis_tdata(adc_ts_tdata),
        .s_axis_tvalid(adc_ts_tvalid),
        .s_axis_tready(adc_ts_tready),
        .s_axis_tid(adc_ts_tid),
        .s_axis_tlast(1'b0),
        //
        .m_axis_tdata(fifo_adc_ts_tdata),
        .m_axis_tvalid(fifo_adc_ts_tvalid),
        .m_axis_tready(fifo_adc_ts_tready),
        .m_axis_tid(fifo_adc_ts_tid)
    );

    // ADC/TS stream TLAST generator (packing logic)
    assign fifo_adc_ts_tlast = 1'b1;    // TODO!!

    // Demultiplex ADC / TS stream after FIFO
    // TID is used as TDEST
    axis_demux #(
        .M_COUNT(2),
        .DATA_WIDTH(ADC_TS_MUX_WIDTH),
        .KEEP_ENABLE(0),
        .ID_ENABLE(0),
        .DEST_ENABLE(1),
        .S_DEST_WIDTH(1),
        .USER_ENABLE(0),
        .TDEST_ROUTE(1)
    ) u_adc_ts_demux (
        .clk(i_clk),
        .rst(i_rst),
        //
        .s_axis_tdata(fifo_adc_ts_tdata),
        .s_axis_tvalid(fifo_adc_ts_tvalid),
        .s_axis_tready(fifo_adc_ts_tready),
        .s_axis_tlast(fifo_adc_ts_tlast),
        .s_axis_tdest(fifo_adc_ts_tid),
        //
        .m_axis_tdata({dem_adc_tdata_wide, dem_ts_tdata_wide}),
        .m_axis_tvalid({dem_adc_tvalid, dem_ts_tvalid}),
        .m_axis_tready({dem_adc_tready, dem_ts_tready}),
        .m_axis_tlast({dem_adc_tlast, dem_ts_tlast}),
        //
        .enable(1'b1)
    );

    assign dem_adc_tdata = dem_adc_tdata_wide[ADC_FLTN_WIDTH-1:0];
    assign dem_ts_tdata = dem_ts_tdata_wide[TS_WIDTH-1:0];

    // Correct and repack ADC data
    assign dem_adc_tready = corr_adc_tready;
    always @* begin
        corr_adc_tvalid = dem_adc_tvalid;
        corr_adc_tlast = dem_adc_tlast;
        for (i = 0; i < ADC_NUM_CHANNELS; i = i + 1) begin
            // TKEEP - propagate channel enable to all bytes of a channel
            corr_adc_tkeep[(i+1)*ADC_CHN_BYTES-1:i*ADC_CHN_BYTES] =
                {ADC_CHN_BYTES{i_chn_en[i]}};
            // TDATA - pad LSBs
            // TODO: more corrections (2's complement)
            corr_adc_tdata[(i+1)*ADC_CORR_CHN_WIDTH-1:i*ADC_CORR_CHN_WIDTH] =
                {
                    dem_adc_tdata[(i+1)*ADC_CHN_WIDTH-1:i*ADC_CHN_WIDTH],
                    {ADC_CORR_PAD{1'b0}}
                };
        end
    end

    // Serialize corrected ADC stream
    axis_adapter #(
        .S_DATA_WIDTH(ADC_CORR_FLTN_WIDTH),
        .S_KEEP_ENABLE(1),
        .S_KEEP_WIDTH(ADC_CORR_FLTN_BYTES),
        .M_DATA_WIDTH(8),
        .M_KEEP_ENABLE(1),
        .M_KEEP_WIDTH(1),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0)
    ) u_adc_serializer (
        .clk(i_clk),
        .rst(i_rst),
        //
        .s_axis_tdata(corr_adc_tdata),
        .s_axis_tkeep(corr_adc_tkeep),
        .s_axis_tvalid(corr_adc_tvalid),
        .s_axis_tready(corr_adc_tready),
        .s_axis_tlast(corr_adc_tlast),
        //
        .m_axis_tdata(o_m_axis_adc_tdata),
        .m_axis_tkeep(o_m_axis_adc_tkeep),
        .m_axis_tvalid(o_m_axis_adc_tvalid),
        .m_axis_tready(i_m_axis_adc_tready),
        .m_axis_tlast(o_m_axis_adc_tlast)
    );

    // Serialize timestamp stream
    axis_adapter #(
        .S_DATA_WIDTH(TS_WIDTH),
        .S_KEEP_ENABLE(1),
        .S_KEEP_WIDTH(TIMESTAMP_BYTES),
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
        .s_axis_tdata(dem_ts_tdata),
        .s_axis_tkeep({TIMESTAMP_BYTES{1'b1}}),
        .s_axis_tvalid(dem_ts_tvalid),
        .s_axis_tready(dem_ts_tready),
        .s_axis_tlast(dem_ts_tlast),
        //
        .m_axis_tdata(o_m_axis_ts_tdata),
        .m_axis_tkeep(o_m_axis_ts_tkeep),
        .m_axis_tvalid(o_m_axis_ts_tvalid),
        .m_axis_tready(i_m_axis_ts_tready),
        .m_axis_tlast(o_m_axis_ts_tlast)
    );

endmodule
