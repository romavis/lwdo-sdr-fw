/*****************************************************************************

                            ---- fastcounter ----

Fast synchronous up-/down- counter. Fast - because it uses registered carry
signals within internal stages, which allows it to obtain higher fMAX.

Direction is selected by i_dir:
    0 - downcounter (decrements value, overflows to all-ones)
    1 - upcounter (increments value, overflows to all-zeros)

Synchronous load can be triggered by i_load, which is always effective, except
for when counter is kept in reset via i_rst.

Modes:
    0 - AUTORELOAD
        if carry==0 (counter is not overflowing):
            counter counts when i_en==1
        if carry==1 (counter is going to overflow):
            counter is loaded (o_q<=i_load_q) when i_en==1
    1 - ONESHOT
        if carry==0 (counter is not overflowing):
            counter counts when i_en==1
        if carry==1 (counter is going to overflow):
            i_en is disabled
            counter may still be reloaded by i_load
    2 - OVERFLOW
        if carry==0 (counter is not overflowing):
            counter counts when i_en==1
        if carry==1 (counter is going to overflow):
            counter overflows when i_en==1
        counter may be reloaded by i_load at any point

Status outputs:
    o_end
        is 1 when o_q is at last pre-overflow value
        (0 for i_dir=0, all-ones for i_dir=1), 0 otherwise
    o_nend
        inverse of o_end
    o_carry
        carry flag
        is 1 when:
            o_q is zero (i_dir=0) or all-ones (i_dir=1),
            and i_en=1
            and counter is not in oneshot mode
    o_carry_dly
        o_carry delayed by 1 i_clk cycle (use to improve timings)
    o_epulse
        1 clk wide pulse generated when o_end goes high
        except when counter is reset via i_rst

Applications:
    In all modes, i_en can be used to "gate" count.
    When i_en=0, the counter holds its value unless i_rst or i_load
    are used. o_carry is also held at 0 when i_en=0.
    This can be convenient when counter is driven from another prescaler.
    In this case, i_en should be fed with positive 1x i_clk wide pulses
    coming at desired count rate.

    Clock prescaler:
        Divides input clock (or frequency of clk gating pulses generated
        by another prescaler) by DIV_RATIO, and generates clk gating
        pulses with resulting frequency.

        i_rst
            Connect to global asynchronous reset network
        i_mode
            set to 0 (AUTORELOAD)
        i_dir
            set to 0
        i_en
            Divide i_clk: set to 1
            Divide output of another prescaler: connect to o_carry(_dly)
            of another prescaler
        i_load
            set to 0
        i_load_q
            set to DIV_RATIO-1, where DIV_RATIO is the desired frequency
            division ratio
        o_carry, o_carry_dly
            output of prescaler:
                when DIV_RATIO>1:
                    1x i_clk wide pulses, one pulse per
                    DIV_RATIO*(i_clk or i_en) cycles
                when DIV_RATIO=1:
                    o_carry is a copy of i_en
        o_end, o_nend, o_epulse
            not used

    One-shot:
        When triggered, counter is reloaded with VAL value and then
        decrements by 1 on each i_clk cycle when i_en==1. When counter
        reaches zero, it stops decrementing till external trigger is
        applied again.

        This allows to generate pulses of specified width, and to generate
        1x i_clk wide pulses with controlled delay w.r.t trigger.

        Counter is triggered by positive-edge transition on i_load.

        i_rst
            Connect to global asynchronous reset network
        i_mode
            set to 1 (ONESHOT)
        i_dir
            set to 0
        i_en
            Count with i_clk rate: set to 1
            Count with prescaled rate: connect to output of prescaler
        i_load
            Connect to trigger signal
        i_load_q
            set to NCOUNT
        o_nend
            Produces positive pulse that starts on the next i_clk cycle
            after i_load==1 and has width of NCOUNT*(i_clk or i_en) cycles
        o_end
            Produces inverted pulse, otherwise same as o_nend
        o_epulse
            Produces pulse that is delayed w.r.t. cycle of i_load==1 by
            NCOUNT+1 count clocks
        o_carry, o_carry_dly
            not used

*****************************************************************************/

module fastcounter_stage_ #(
    parameter NBITS = 3
) (
    input i_clk,
    input i_rst,
    input i_dir,    // 1 for increment, 0 for decrement
    input i_en,
    input i_load,
    input [NBITS-1:0] i_load_q,
    output [NBITS-1:0] o_q,
    output o_zero,  // 1 when counter is 0 (registered)
    output o_ones   // 1 when counter is all-ones (registered)
);

    reg [NBITS-1:0] count;
    reg zero;   // registered carry signal for downcounter
    reg ones;   // registered carry signal for upcounter

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            count <= {NBITS{1'b0}};
            zero <= 1'b1;
            ones <= 1'b0;
        end else if (i_load) begin
            count <= i_load_q;
            zero <= (i_load_q == {NBITS{1'b0}});
            ones <= (i_load_q == {NBITS{1'b1}});
        end else begin
            if (i_en) begin
                count <= i_dir ? (count + 1'b1) : (count - 1'b1);
                zero <= (count == {{NBITS-1{1'b0}}, 1'b1});
                ones <= (count == {{NBITS-1{1'b1}}, 1'b0});
            end
        end
    end

    assign o_q = count;
    assign o_zero = zero;
    assign o_ones = ones;

endmodule


module fastcounter #(
    parameter NBITS = 10,
    parameter NBITS_STAGE = 9   // default value good for iCE40
) (
    input i_clk,
    input i_rst,
    //
    input [1:0] i_mode,
    input i_dir,
    input i_en,
    input [NBITS-1:0] i_load_q,
    input i_load,
    //
    output o_end,
    output o_nend,
    output o_carry,
    output o_carry_dly,
    output o_epulse,
    //
    output [NBITS-1:0] o_q
);

    localparam MODE_AUTORELOAD = 2'd0;
    localparam MODE_ONESHOT = 2'd1;
    localparam MODE_OVERFLOW = 2'd2;

    localparam NSTAGES = ((NBITS + NBITS_STAGE - 1) / NBITS_STAGE); // ceil
    localparam NLBITS = NBITS - (NSTAGES-1) * NBITS_STAGE;

    genvar ii;

    wire clk = i_clk;
    wire rst = i_rst;

    // ZERO outputs of all stages
    wire [NSTAGES-1:0] st_zero;
    // ONES outputs of all stages
    wire [NSTAGES-1:0] st_ones;
    // EN inputs of all stages
    wire [NSTAGES-1:0] st_en;

    // Carry chain logic
    assign st_en[0] = en;
    generate
        for (ii = 1; ii < NSTAGES; ii=ii+1) begin
            assign st_en[ii] =
                st_en[ii-1] && (i_dir ? st_ones[ii-1] : st_zero[ii-1]);
        end
    endgenerate

    // Carry output logic
    assign o_carry =
        st_en[NSTAGES-1] && (i_dir ? st_ones[NSTAGES-1] : st_zero[NSTAGES-1]);

    // Delayed carry generator
    reg carry_dly;
    always @(posedge clk or posedge rst)
        if (rst)
            carry_dly <= 1'b0;
        else
            carry_dly <= o_carry;

    assign o_carry_dly = carry_dly;

    // End logic
    assign o_end = i_dir ? (&st_ones) : (&st_zero);
    assign o_nend = ~o_end;

    // End pulse generator
    reg end_dly;
    always @(posedge clk or posedge rst)
        if (rst) begin
            // to avoid pusle on reset
            end_dly <= 1'b1;
        end else if (load) begin
            // to generate new pulse each time counter
            // is loaded with end value
            end_dly <= 1'b0;
        end else begin
            end_dly <= o_end;
        end

    assign o_epulse = o_end & ~end_dly;

    // i_load edge detector for one-shot mode
    reg load_dly;
    always @(posedge clk or posedge rst)
        if (rst)
            load_dly <= 1'b0;
        else
            load_dly <= i_load;

    wire load_edge = i_load & ~load_dly;

    // Mode-dependent enable and load logic
    reg en, load;
    always @(*) begin
        // Normal (overflow) mode
        en = i_en;
        load = i_load;
        // Special modes
        case(i_mode)
        MODE_AUTORELOAD: begin
            en = i_en;
            load = i_load || o_carry;
        end
        MODE_ONESHOT: begin
            en = i_en && !o_end;
            load = load_edge;
        end
        endcase
    end

    // Counter stages
    generate
        for (ii = 0; ii < NSTAGES; ii = ii + 1) begin
            if (ii < NSTAGES-1) begin
                fastcounter_stage_ #(
                    .NBITS(NBITS_STAGE)
                ) ctr (
                    .i_clk(clk),
                    .i_rst(rst),
                    .i_dir(i_dir),
                    .i_en(st_en[ii]),
                    .i_load(load),
                    .i_load_q(i_load_q[(ii+1)*NBITS_STAGE-1:ii*NBITS_STAGE]),
                    .o_q(o_q[(ii+1)*NBITS_STAGE-1:ii*NBITS_STAGE]),
                    .o_zero(st_zero[ii]),
                    .o_ones(st_ones[ii])
                );
            end else begin
                fastcounter_stage_ #(
                    .NBITS(NLBITS)
                ) ctr (
                    .i_clk(clk),
                    .i_rst(rst),
                    .i_dir(i_dir),
                    .i_en(st_en[ii]),
                    .i_load(load),
                    .i_load_q(i_load_q[NBITS-1:ii*NBITS_STAGE]),
                    .o_q(o_q[NBITS-1:ii*NBITS_STAGE]),
                    .o_zero(st_zero[ii]),
                    .o_ones(st_ones[ii])
                );
            end
        end
    endgenerate

endmodule
