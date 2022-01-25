module wb_mem #(
    parameter WB_ADDR_WIDTH = 6,
    parameter STALL_WS=2,
    parameter ACK_WS=2
)
(
    // Clock (posedge) and sync reset
    input i_clk,
    input i_rst,
    // Wishbone bus slave
    input i_wb_cyc,
    input i_wb_stb,
    output o_wb_stall,
    output o_wb_ack,
    input i_wb_we,
    input [WB_ADDR_WIDTH-1:0] i_wb_addr,
    input [31:0] i_wb_data,
    input [3:0] i_wb_sel,
    output [31:0] o_wb_data
);

    localparam MEM_NWORDS = 1 << WB_ADDR_WIDTH;

    //
    // State machine
    //
    reg [1:0] state;
    reg [1:0] state_next;
    wire state_change;
    assign state_change = (state != state_next) ? 1'b1 : 1'b0;

    wire [1:0] state_resp_ack;
    assign state_resp_ack = ACK_WS ? ST_ACK_WAIT : ST_ACK; 
    wire [1:0] state_req_ack;
    assign state_req_ack = STALL_WS ? ST_STALL_WAIT : state_resp_ack;

    localparam ST_IDLE = 2'd0;
    localparam ST_STALL_WAIT = 2'd1;
    localparam ST_ACK_WAIT = 2'd2;
    localparam ST_ACK = 2'd3;

    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= ST_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;

        case (state)
        ST_IDLE: begin
            if (i_wb_cyc && i_wb_stb) begin
                state_next = state_req_ack;
            end
        end

        ST_STALL_WAIT: begin
            if (!stall_ws_ctr) begin
                state_next = state_resp_ack;
            end
        end

        ST_ACK_WAIT: begin
            if (!ack_ws_ctr) begin
                state_next = ST_ACK;
            end
        end

        ST_ACK: begin
            state_next = i_wb_stb ? state_req_ack : ST_IDLE;
        end

        endcase

        // Global override: if CYC is de-asserted, go back to IDLE
        if (!i_wb_cyc) begin
            state_next = ST_IDLE;
        end
    end

    //
    // Stall waitstate counter
    //
    reg [7:0] stall_ws_ctr;

    always @(posedge i_clk) begin
        if (i_rst) begin
            stall_ws_ctr <= 8'd0;
        end else begin
            if (state_change && state_next == ST_STALL_WAIT) begin
                stall_ws_ctr <= STALL_WS - 8'd1;
            end else begin
                if (stall_ws_ctr) begin
                    stall_ws_ctr <= stall_ws_ctr - 8'd1;
                end
            end
        end
    end

    //
    // ACK waitstate counter
    //
    reg [7:0] ack_ws_ctr;

    always @(posedge i_clk) begin
        if (i_rst) begin
            ack_ws_ctr <= 8'd0;
        end else begin
            if (state_change && state_next == ST_ACK_WAIT) begin
                ack_ws_ctr <= ACK_WS - 8'd1;
            end else begin
                if (ack_ws_ctr) begin
                    ack_ws_ctr <= ack_ws_ctr - 8'd1;
                end
            end
        end
    end

    //
    // WB request buffer
    //
    reg [29:0] r_addr;
    reg r_we;
    reg [31:0] r_wdata;
    reg [3:0] r_wsel;

    always @(posedge i_clk) begin
        if (i_rst) begin
            r_addr <= 30'd0;
            r_we <= 1'd0;
            r_wdata <= 32'd0;
            r_wsel <= 4'b0;
        end else begin
            // Cache WB request whenever it is accepted
            if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
                r_addr <= i_wb_addr;
                r_we <= i_wb_we;
                r_wdata <= i_wb_data;
                r_wsel <= i_wb_sel;
            end
        end
    end

    //
    // Small memory
    //
    reg [31:0] mem [0:MEM_NWORDS-1];

    integer i;
    initial begin
        for (i = 0; i < MEM_NWORDS; i = i + 1) begin
            mem[i] <= 32'd0;
        end
    end

    always @(posedge i_clk) begin
        if (i_wb_cyc && o_wb_ack && r_we) begin
            // Handle WB write request
            if(r_addr < MEM_NWORDS) begin
                if (r_wsel[0]) mem[r_addr][7:0] <= r_wdata [7:0];
                if (r_wsel[1]) mem[r_addr][15:8] <= r_wdata [15:8];
                if (r_wsel[2]) mem[r_addr][23:16] <= r_wdata [23:16];
                if (r_wsel[3]) mem[r_addr][31:24] <= r_wdata [31:24];
            end
        end
    end

    //
    // Outputs
    //
    reg wb_stall;
    reg wb_ack;
    reg [31:0] wb_data;
    assign o_wb_stall = wb_stall;
    assign o_wb_ack = wb_ack;
    assign o_wb_data = wb_data;

    always @(*) begin
        wb_stall = 1'bx;
        wb_ack = 1'bx;
        wb_data = 32'bx;
        if (i_wb_cyc) begin
            // stall
            wb_stall = 1'b1;
            if (state_next != ST_STALL_WAIT) begin
                wb_stall = 1'b0;
            end
            // ack
            wb_ack = (state == ST_ACK) ? 1'b1 : 1'b0;
            // data
            if (!r_we && (state == ST_ACK)) begin
                wb_data = mem[r_addr];
            end
        end
    end

endmodule