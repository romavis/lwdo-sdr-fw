module mreq_seq2 (
    input i_clk,
    input i_rst,
    // Master MREQ
    input i_valid,
    output o_ready,
    // Slave 1 MREQ
    output o_valid1,
    input i_ready1,
    // Slave 2 MREQ
    output o_valid2,
    input i_ready2
);

    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    reg [1:0] state;
    reg [1:0] state_next;

    localparam ST_IDLE = 2'd0;
    localparam ST_SERVE1 = 2'd1;
    localparam ST_SERVE2 = 2'd2;

    always @(posedge clk) begin
        if (rst)
            state <= ST_IDLE;
        else 
            state <= state_next;
    end

    always @(*) begin
        state_next = state;
        case (state)
        ST_IDLE:
            state_next = i_valid ? ST_SERVE1 : state;
        ST_SERVE1:
            state_next = (o_valid1 && i_ready1) ? ST_SERVE2 : state;
        ST_SERVE2:
            state_next = (o_valid2 && i_ready2) ? ST_IDLE : state;
        endcase
    end

    assign o_valid1 = (state == ST_SERVE1) ? 1'b1 : 1'b0;
    assign o_valid2 = (state == ST_SERVE2) ? 1'b1 : 1'b0;
    assign o_ready = (state == ST_SERVE2 && state_next == ST_IDLE) ? 1'b1 : 1'b0;

endmodule