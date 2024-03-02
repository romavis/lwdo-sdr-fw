/****************************************************************************

                            ---- cdc_pulsed ----

Clock domain crossing contraption for pulsed signals.
Receives rare 1 clock-wide pulses from one clock domain, and emits
1 clock-wide pulses in another domain.

****************************************************************************/

module cdc_pulsed #(
    parameter DEPTH_FWD=3,
    parameter DEPTH_REV=DEPTH_FWD,

) (
    // Side A - pulse input
    input i_a_clk,
    input i_a_rst,
    input i_a_pulse,
    output o_a_busy,
    // Side B - pulse output
    input i_b_clk,
    input i_b_rst,
    output o_b_pulse    //
);

    // Input latch
    reg a_data;
    reg a_busy;
    always @(posedge i_a_clk or posedge i_a_rst) begin
        if (i_a_rst) begin
            a_data <= 1'b0;
            a_busy <= 1'b0;
        end else begin
            if (!a_busy) begin
                // BUSY=0
                if (i_a_pulse) begin
                    a_data <= 1'b1;
                    a_busy <= 1'b1;
                end
            end else begin
                // BUSY=1
                if (a_data) begin
                    // Wait for ACK=1 and clear DATA
                    if (a_ack) begin
                        a_data <= 1'b0;
                    end
                end else begin
                    // Wait for ACK=0 and clear BUSY
                    if (!a_ack) begin
                        a_busy <= 1'b0;
                    end
                end
            end
        end
    end

    // CDC for data line
    wire b_data;
    cdc_ffsync #(
        .DEPTH(DEPTH_FWD)
    ) u_cdc_ffsync_a_b (
        .i_clk(i_b_clk),
        .i_rst(i_b_rst),
        .i_d(a_data),
        .o_q(b_data)
    );

    // CDC for ack line - feeds back data line from B to A
    wire a_ack;
    cdc_ffsync #(
        .DEPTH(DEPTH_REV)
    ) u_cdc_ffsync_b_a (
        .i_clk(i_a_clk),
        .i_rst(i_a_rst),
        .i_d(b_data),
        .o_q(a_ack)
    );

    // Output pulse former
    reg b_data_q;
    always @(posedge i_b_clk or posedge i_b_rst) begin
        if (i_b_rst) begin
            b_data_q <= 1'b0;
        end else begin
            b_data_q <= b_data;
        end
    end

    assign o_a_busy = a_busy;
    assign o_b_pulse = b_data & ~b_data_q;

endmodule
