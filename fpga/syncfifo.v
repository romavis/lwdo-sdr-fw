module syncfifo #(
    parameter ADDR_WIDTH = 5,   // Max elements that FIFO can store: (2**ADDR_WIDTH)-1
    parameter DATA_WIDTH = 8
) (
    // SysCon
    input i_clk,
    input i_rst,
    // I/O data
    input [DATA_WIDTH-1:0] i_data,
    output [DATA_WIDTH-1:0] o_data,
    // Control signals
    input i_wr,
    input i_rd,
    // Status
    output [ADDR_WIDTH-1:0] o_count,
    output o_empty,
    output o_full,
    output o_half_full,
    // Error signals
    output o_overflow,
    output o_underflow
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    //
    // Syscon
    //
    wire clk;
    wire rst;
    assign clk = i_clk;
    assign rst = i_rst;

    //
    // Memory
    //
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    //
    // Pointers
    //
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH-1:0] wr_ptr_next;
    reg [ADDR_WIDTH-1:0] rd_ptr_next;

    //
    // Clocked read/write logic
    //
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (do_write) begin
                mem[wr_ptr] <= i_data;
                wr_ptr <= wr_ptr_next;
            end
            if (do_read) begin
                rd_ptr <= rd_ptr_next;
            end
        end
    end

    //
    // Read logic
    //
    reg [DATA_WIDTH-1:0] read_data;
    always @(*) begin
        read_data = mem[rd_ptr];
    end

    //
    // Counter increment
    //
    always @(*) begin
        wr_ptr_next = wr_ptr + {{ADDR_WIDTH-1{1'b0}}, 1'b1};
        rd_ptr_next = rd_ptr + {{ADDR_WIDTH-1{1'b0}}, 1'b1};
    end

    //
    // Number of elements currently in fifo
    // 
    reg [ADDR_WIDTH-1:0] count;
    always @(*) begin
        count = wr_ptr - rd_ptr;
    end

    //
    // Status bit generation
    //
    reg do_write;
    reg do_read;
    reg empty;
    reg full;
    reg hfull;
    reg ovfl;
    reg udfl;
    always @(*) begin
        // FIFO is empty when rd_ptr==wr_ptr
        empty = (rd_ptr == wr_ptr);
        // FIFO is full when wr_ptr+1==rd_ptr
        full = (rd_ptr == wr_ptr_next);
        // FIFO is half-full when the MSB of (wr_ptr-rd_ptr) is set
        hfull = count[ADDR_WIDTH-1];

        // Write if i_wr=1, and either o_full=0 or i_rd=1 (so when full=wr=rd=1, FIFO performs read&write and does not overflow)
        do_write = i_wr && (!full || i_rd);
        // Read if i_rd=1 and o_empty=0 (so empty=wr=rd=1 is _not_ OK and generates underflow)
        do_read = i_rd && !empty;
        // Overflow happens when i_wr=1 but do_write=0
        ovfl = i_wr && !do_write;
        // Underflow happens when i_rd=1 but do_read=0
        udfl = i_rd && !do_read;
    end

    // Connect outputs
    assign o_data = read_data;
    assign o_count = count;
    assign o_empty = empty;
    assign o_full = full;
    assign o_half_full = hfull;
    assign o_overflow = ovfl;
    assign o_underflow = udfl;

endmodule