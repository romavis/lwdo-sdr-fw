/****************************************************************************

                        ---- async_fifo_bram ----

Wrapped variant of async_fifo that properly handles the issue of the
first word fall-through for technologies that require adding a buffer at
DP-RAM read port (like ICE40).

****************************************************************************/


module async_fifo_bram #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
) (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [DSIZE-1:0] wdata,
    output wire             wfull,
    output wire             awfull,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire             rinc,
    output wire [DSIZE-1:0] rdata,
    output wire             rempty,
    output wire             arempty
);

    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH("TRUE")
    ) u_async_fifo (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wfull(wfull),
        .awfull(awfull),
        //
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc && !rempty),
        .rdata(raw_rdata),
        .rempty(raw_rempty),
        .arempty(raw_arempty)
    );

    wire [DSIZE-1:0] raw_rdata;
    wire raw_rempty;
    wire raw_arempty;

    // buffer rdata and empty signals
    reg [DSIZE-1:0] rdata_q;
    reg rempty_q;
    reg arempty_q;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= {DSIZE{1'b0}};
            rempty_q <= 1'b1;
            arempty_q <= 1'b0;
        end else begin
            rdata_q <= raw_rdata;
            rempty_q <= raw_rempty;
            arempty_q <= raw_arempty;
        end
    end

    reg [DSIZE-1:0] rdata_reg;
    reg rempty_reg;
    reg arempty_reg;

    always @* begin
        // Delay clearing of rempty
        rempty_reg = raw_rempty ? 1'b1 : rempty_q;
        arempty_reg = rempty_reg ? 1'b0 : raw_arempty;
        rdata_reg = rdata_q;
    end

    wire [ASIZE-1:0] waddr, raddr;
    wire [  ASIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;
    
    // The module synchronizing the read point
    // from read to write domain
    sync_r2w
    #(ASIZE)
    sync_r2w (
    .wq2_rptr (wq2_rptr),
    .rptr     (rptr),
    .wclk     (wclk),
    .wrst_n   (wrst_n)
    );

    // The module synchronizing the write point
    // from write to read domain
    sync_w2r
    #(ASIZE)
    sync_w2r (
    .rq2_wptr (rq2_wptr),
    .wptr     (wptr),
    .rclk     (rclk),
    .rrst_n   (rrst_n)
    );
    
    // The module handling the write requests
    wptr_full
    #(ASIZE)
    wptr_full (
    .awfull   (awfull),
    .wfull    (wfull),
    .waddr    (waddr),
    .wptr     (wptr),
    .wq2_rptr (wq2_rptr),
    .winc     (winc),
    .wclk     (wclk),
    .wrst_n   (wrst_n)
    );

    // The DC-RAM 
    fifomem
    #(DSIZE, ASIZE, FALLTHROUGH)
    fifomem (
    .rclken (rinc),
    .rclk   (rclk),
    .rdata  (rdata),
    .wdata  (wdata),
    .waddr  (waddr),
    .raddr  (raddr),
    .wclken (winc),
    .wfull  (wfull),
    .wclk   (wclk)
    );

    // The module handling read requests
    rptr_empty
    #(ASIZE)
    rptr_empty (
    .arempty  (arempty),
    .rempty   (rempty),
    .raddr    (raddr),
    .rptr     (rptr),
    .rq2_wptr (rq2_wptr),
    .rinc     (rinc),
    .rclk     (rclk),
    .rrst_n   (rrst_n)
    );

endmodule
