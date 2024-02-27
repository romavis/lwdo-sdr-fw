/****************************************************************************

                        ---- ad7357_driver ----

Driver for AD7357 ADC.
To be used with ad7357_clk_gen (several drivers can share one clk_gen).

One driver produces one CSn signal and can read several SDATA channels.

****************************************************************************/


module ad7357_driver #(
    parameter DATA_WIDTH = 14,
    parameter NUM_CHANNELS = 2,
) (
    input i_clk,
    input i_rst,
    // Conversion control
    output o_ready,     // If 0, 'start' will be ignored
    input i_start,      // Pulse to 1 to start conversion
    output o_sample,    // Set to 1 in the cycle in which CSn goes H->L
    // Output data, with AXI-S handshake
    output [DATA_WIDTH*NUM_CHANNELS-1:0] o_m_axis_tdata,
    output o_m_axis_tvalid,
    input i_m_axis_tready,
    // CSn pin driver (no DDR here)
    output o_adc_cs_n,
    // SDATA pins acquired using DDR input buffers
    // NOTE: SDATA DDR input cell should be clocked by i_clk.
    // You can also delay SDATA cell clock by a few ns to
    // compensate for AD7357 long SDATA output delay + FPGA i/o delays.
    input [NUM_CHANNELS-1:0] i_adc_sdata_ddr_h, // Input latched when i_clk: H->L
    input [NUM_CHANNELS-1:0] i_adc_sdata_ddr_l, // Input latched when i_clk: L->H
    // Signaling to the clk_gen module
    output o_ctl_cken   //
);
    // Duration of STATE_CONV in cycles
    // also duration of CSn low phase
    localparam NUM_CONV_CYCLES = DATA_WIDTH + 2;
    // Delay introduced by DDR sampling of SDATA + writing it to shift register
    localparam DATA_DELAY_CYCLES = 2;
    // Number of bits in sync shift register
    localparam SYNC_STAGES = NUM_CONV_CYCLES + DATA_DELAY_CYCLES;

    // FSM
    localparam STATE_IDLE = 2'd0;   // ckreq=0, CSn=1, sync_in=0
    localparam STATE_PREP = 2'd1;   // ckreq=1, CSn=1, sync_in=1
    localparam STATE_CONV = 2'd2;   // ckreq=1, CSn=0, sync_in=0

    reg [1:0] state;
    reg [1:0] state_next;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= STATE_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @* begin
        state_next = state;
        case (state)
            STATE_IDLE: begin
                if (i_start) begin
                    state_next = STATE_PREP;
                end
            end
            STATE_PREP: begin
                state_next = STATE_CONV;
            end
            STATE_CONV: begin
                if (sync_conv_last) begin
                    state_next = STATE_IDLE;
                end
            end
        endcase
    end

    // Pipeline synchronization shift register
    reg [SYNC_STAGES-1:0] sync_reg;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            sync_reg <= 1'b0;
        end else begin
            // sync_reg[0] is 1 in the first cycle of STATE_CONV
            // CS goes low in the same cycle
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], sync_prep};
        end
    end

    // Sync signals
    reg sync_idle;          // active in IDLE state
    reg sync_prep;          // active in PREP state
    reg sync_conv_first;    // first cycle of CONV state
    reg sync_conv_lastm1;   // cycle before the last cycle of CONV state
    reg sync_conv_last;     // last cycle of CONV state
    reg sync_data_valid;    // data_reg contains valid DATA_WIDTH bits
    always @* begin
        sync_idle = (state == STATE_IDLE);
        sync_prep = (state == STATE_PREP);
        sync_conv_first = sync_reg[0];
        sync_conv_lastm1 = sync_reg[NUM_CONV_CYCLES-2];
        sync_conv_last = sync_reg[NUM_CONV_CYCLES-1];
        sync_data_valid = sync_reg[NUM_CONV_CYCLES-1+DATA_DELAY_CYCLES];
    end

    // CKEN generator
    reg cken_reg;
    always @* begin
        cken_reg = 1'b0;
        // CKEN active in PREP and all cycles of CONV except for two last
        // clk_gen has 2 cycles delay between CKEN and SCLK output on/off
        if (state == STATE_PREP) begin
            cken_reg = 1'b1;
        end else if (state == STATE_CONV) begin
            cken_reg = !(sync_conv_last || sync_conv_lastm1);
        end
    end

    // CS generator
    reg cs_n_reg;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cs_n_reg <= 1'b1;
        end else begin
            if (sync_prep) begin
                cs_n_reg <= 1'b0;
            end else if (sync_conv_last) begin
                cs_n_reg <= 1'b1;
            end
        end
    end

    // Shift in sampled & latched SDATA
    reg [DATA_WIDTH*NUM_CHANNELS-1:0] data_reg;
    integer i1;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            data_reg <= 1'd0;
        end else begin
            // Note: i_adc_sdata_ddr_l/h are already registered by o_adc_sdata_ddr_clk
            for (i1 = 0; i1 < NUM_CHANNELS; i1 = i1 + 1) begin
                data_reg[DATA_WIDTH*i1+DATA_WIDTH-1:DATA_WIDTH*i1] <= 
                    {data_reg[DATA_WIDTH*i1+DATA_WIDTH-2:DATA_WIDTH*i1], i_adc_sdata_ddr_l[i1]};
            end
        end
    end

    // Data holding register
    reg [DATA_WIDTH*NUM_CHANNELS-1:0] axis_tdata_reg;
    reg axis_tvalid_reg;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            axis_tdata_reg <= 1'b0;
            axis_tvalid_reg <= 1'b0;
        end else begin
            // Transfer from shift reg into TDATA but only if it's not holding
            // any data, or that data is read out in the current cycle.
            if (sync_data_valid && (!axis_tvalid_reg || i_m_axis_tready)) begin
                axis_tdata_reg <= data_reg;
                axis_tvalid_reg <= 1'b1;
            end else if (axis_tvalid_reg && i_m_axis_tready) begin
                axis_tvalid_reg <= 1'b0;
            end
        end
    end

    assign o_ready = sync_idle;
    assign o_sample = sync_conv_first;
    assign o_m_axis_tdata = axis_tdata_reg;
    assign o_m_axis_tvalid = axis_tvalid_reg;
    assign o_adc_cs_n = cs_n_reg;
    assign o_ctl_cken = cken_reg;

endmodule
