/*****************************************************************************

                            ---- phase_det ----

Digital phase detector. Used to measure phase offset between two clocks
asynchronous to each other, using FPGA system clock as a timing reference.

Input clocks:
- eclk1
    first measured clock (high frequency)
- eclk2
    second measured clock, typically slower than clk1
- clk
    FPGA system clock used to synchronize data exchange and clock TIC
    (time interval counter)


****************************** ECLK1 path ************************************

           +-----------+     +-----------------+     +-------------+
 eclk1 --> | DIV BY N1 | --> | FF SYNCHRONISER | --> | EDGE DETECT | --> stop
           +-----------+     +-----------------+     +-------------+
                 ^                    ^
               eclk1                 clk


****************************** ECLK2 path ************************************

            +-----------+     +-----------------+
 eclk2 -+-> | DIV BY N2 | --> | FF SYNCHRONISER | --> sync_eclk2h --> ...
        |   +-----------+     +-----------------+
        |         ^                    ^
        |       eclk2                 clk
        |
        |   +-----------------+
        +-> | FF SYNCHRONISER | --> sync_eclk2l --> ...
            +-----------------+
                    ^
                   clk

                 +--------+
 sync_eclk2h --> |        |     +-------------+
                 |  MUX   | --> | EDGE DETECT | --> start
 sync_eclk2l --> |        |     +-------------+
                 +--------+
                     ^
                 eclk2_slow


****************************** TIC path ************************************

           +-----+
 start --> |     | ==> [TIC_BITS-1:0] count
           | TIC | --> valid
  stop --> |     | <-- ready
           +-----+
              ^
             clk

******************************** NOTES *************************************

TIC measures time between `start` & `stop` pulses by counting `clk` cycles.
Whenever measurement is completed, it is made available via `count` port,
and `rdy` bit is pulsed high for one sys clock. `count` should be read only
when `rdy` is high.

1. Count starts on a `start` pulse and completes on a following
   (or coinceding) `stop` pulse.

2. If `start` pulse is followed by another `start` pulse, count is restarted
   like there was no previous `start` pulse.

3. If `stop` pulse is followed by another `stop` pulse, the second pulse is
   ignored.

4. If counter overflows, measurement is aborted, counter behaves like there
   was no `start` pulse that triggered the count.

Normally, when ECLK1 and ECLK2 are periodic, measurement result is made
available periodically every Tmeas seconds:

    Tmeas = 1 / MIN(F(start), F(stop))
    where `F(x)` is frequency of `x` in Hz

Measured time interval Tx ranges from 0 to Tmax seconds:

    0 <= Tx < Tmax
    Tmax = 1 / MAX(F(start), F(stop))

Measurement result is Tx expressed `i_clk` cycles:

    Count = Tx * F(i_clk)


** Recommendations for use:

1. Although F(start) and F(stop) may be different, to achieve phase lock they
   must be harmonically related. That is, following must hold:
        F(start)/F(stop) = M or 1/M
        where M is an integer

2. The most efficient use of phase detector is achieved when frequencies are
   close:
        F(start) ~= F(stop)

3. Therefore it is essential to select N1 and N2 divisors properly for
   target usecase.

4. eclk2_slow allows forwarding raw eclk2 to TIC. This is needed when eclk2
   is a 1Hz PPS signal - there's no point in dividing it.

5. Module was designed primarily for slow narrow-bandwidth digital VCXO PLLs,
   where F(start), F(stop) are 1~500 Hz, while F(i_clk) is >50 MHz.

****************************************************************************/

module phase_det #(
    parameter TIC_BITS = 20,
    parameter DIV_N1 = 999, // div by 1000 (default)
    parameter DIV_N2 = 999  // div by 1000 (default)
) (
    // system clock domain
    input i_clk,
    input i_rst,
    // control bits
    input i_en,
    input i_eclk2_slow,
    // measurement result
    output [TIC_BITS-1:0] o_count,
    output o_count_rdy,
    // clocks to measure
    input i_eclk1,
    input i_eclk2
);

    localparam BITS_N1 = (DIV_N1 >= 1) ? $clog2(DIV_N1 + 1) : 1;
    localparam BITS_N2 = (DIV_N2 >= 1) ? $clog2(DIV_N2 + 1) : 1;

    wire clk = i_clk;
    wire rst = i_rst;
    wire eclk1 = i_eclk1;
    wire eclk2 = i_eclk2;

    // --------------------------------------------------------------------
    // ECLK1 pipeline
    // --------------------------------------------------------------------

    wire eclk1_rst;

    // Reset bridge
    rst_bridge rst_bridge_eclk1 (
        .clk(eclk1),
        .rst(rst),
        .out(eclk1_rst)
    );

    // N1 divider
    wire eclk1_div1;
    fastcounter #(
        .NBITS(BITS_N1)
    ) ctr_n1 (
        .i_clk(eclk1),
        .i_rst(eclk1_rst),
        //
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(1'b1),
        .i_load(1'b0),
        .i_load_q(DIV_N1[BITS_N1-1:0]),
        .o_carry_dly(eclk1_div1)
    );

    // Div-by-2
    reg eclk1_div2;
    always @(posedge eclk1 or posedge eclk1_rst)
        if (eclk1_rst)
            eclk1_div2 <= 1'b0;
        else if (eclk1_div1)
            eclk1_div2 <= ~eclk1_div2;

    // Synchronizer
    reg [1:0] eclk1_ffsync;
    always @(posedge clk or posedge rst)
        if (rst)
            eclk1_ffsync <= 0;
        else
            eclk1_ffsync <= {eclk1_div2, eclk1_ffsync[1]};

    wire eclk1_sync = eclk1_ffsync[0];

    // --------------------------------------------------------------------
    // ECLK2 pipeline
    // --------------------------------------------------------------------

    wire eclk2_rst;

    // Reset bridge
    rst_bridge rst_bridge_eclk2 (
        .clk(i_eclk2),
        .rst(rst),
        .out(eclk2_rst)
    );

    // N1 divider
    wire eclk2_div1;

    fastcounter #(
        .NBITS(BITS_N2)
    ) ctr_n2 (
        .i_clk(i_eclk2),
        .i_rst(eclk2_rst),
        //
        .i_mode(2'd0),      // AUTORELOAD
        .i_dir(1'b0),       // DOWN
        .i_en(1'b1),
        .i_load(1'b0),
        .i_load_q(DIV_N2[BITS_N2-1:0]),
        .o_carry_dly(eclk2_div1)
    );

    // Div-by-2
    reg eclk2_div2;
    always @(posedge eclk2 or posedge eclk2_rst)
        if (eclk2_rst)
            eclk2_div2 <= 1'b0;
        else if (eclk2_div1)
            eclk2_div2 <= ~eclk2_div2;

    // Synchronizer
    reg [1:0] eclk2_ffsync;
    always @(posedge clk or posedge rst)
        if (rst)
            eclk2_ffsync <= 0;
        else
            eclk2_ffsync <= {eclk2_div2, eclk2_ffsync[1]};

    wire eclk2_sync_fast = eclk2_ffsync[0];

    // Slow clock synchronizer
    reg [1:0] eclk2_slow_ffsync;
    always @(posedge clk or posedge rst)
        if (rst)
            eclk2_slow_ffsync <= 0;
        else
            eclk2_slow_ffsync <= {i_eclk2, eclk2_slow_ffsync[1]};

    wire eclk2_sync_slow = eclk2_slow_ffsync[0];

    // Mux
    reg eclk2_slow_sel;
    always @(posedge clk or posedge rst)
        if (rst)
            eclk2_slow_sel <= 1'b0;
        else
            eclk2_slow_sel <= i_eclk2_slow;

    wire eclk2_sync = eclk2_slow_sel ? eclk2_sync_slow : eclk2_sync_fast;

    // --------------------------------------------------------------------
    // Edge detection
    // --------------------------------------------------------------------

    reg eclk1_prev, eclk2_prev;

    always @(posedge clk or posedge rst)
        if (rst) begin
            eclk1_prev <= 1'b0;
            eclk2_prev <= 1'b0;
        end else begin
            eclk1_prev <= eclk1_sync;
            eclk2_prev <= eclk2_sync;
        end

    wire tic_start = eclk2_sync && !eclk2_prev;
    wire tic_stop = eclk1_sync && !eclk1_prev;

    // --------------------------------------------------------------------
    // TIC
    // --------------------------------------------------------------------

    wire [TIC_BITS-1:0] tic_q;
    wire tic_end;

    fastcounter #(
        .NBITS(TIC_BITS)
    ) ctr_tic (
        .i_clk(clk),
        .i_rst(rst),
        //
        .i_mode(2'd2),      // OVERFLOW
        .i_dir(1'b1),       // UP
        .i_en(tic_gate),
        .i_load(tic_load),
        .i_load_q({{TIC_BITS-1{1'b0}}, 1'b1}),  // load 'd1
        //
        .o_q(tic_q),
        .o_end(tic_end)
    );

    // Gate & Load control
    wire tic_load = tic_start;
    reg tic_gate;

    // Result readout
    reg [TIC_BITS-1:0] meas;
    reg meas_rdy;

    always @(posedge clk or posedge rst)
        if (rst) begin
            tic_gate <= 1'b0;
            meas <= 0;
            meas_rdy <= 1'b0;
        end else begin
            // Gate opens on start and closes on stop
            if (tic_start)
                tic_gate <= 1'b1;
            if (tic_stop)
                tic_gate <= 1'b0;
            // Result readout
            meas_rdy <= 1'b0;
            if (tic_stop) begin
                if (tic_gate) begin
                    meas_rdy <= 1'b1;
                    meas <= tic_q;
                end
                if (tic_start) begin
                    // special case (start == stop == 1)
                    meas_rdy <= 1'b1;
                    meas <= 0;
                end
            end
            // Overflow handling
            if (tic_end && !tic_load)
                tic_gate <= 1'b0;
            // Disabled means disabled
            if (!i_en)
                tic_gate <= 1'b0;
        end

    assign o_count_rdy = meas_rdy;
    assign o_count = meas;

endmodule
