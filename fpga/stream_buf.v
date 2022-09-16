// Single clock cycle buffer for the standard data+valid+ready stream protocol.
// The main goal of this block is to buffer 'ready' and 'valid' signals, so that
// if they're coming from or going to slow logic, we get a bit wider timing margins.
module stream_buf (
    input i_clk,
    input i_rst,
    // Upstream
    input [7:0] i_data,
    input i_valid,
    output o_ready,
    // Downstream
    output [7:0] o_data,
    output o_valid,
    input i_ready
);

    reg [7:0] buf_data;
    reg [7:0] buf_data_ovfl;
    reg buf_valid;
    reg buf_ready;
    reg buf_overflown;

    wire up_transfer_ok;
    wire down_transfer_ok;

    assign up_transfer_ok = i_valid && o_ready;
    assign down_transfer_ok = o_valid && i_ready;

    // Output pins
    assign o_data = buf_overflown ? buf_data_ovfl : buf_data;
    assign o_valid = buf_valid;
    assign o_ready = buf_ready && (!buf_overflown);

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin

            buf_data <= 8'b0;
            buf_data_ovfl <= 8'b0;
            buf_valid <= 1'b0;
            buf_ready <= 1'b0;
            buf_overflown <= 1'b0;

        end else begin
            // Buffer ready signal
            buf_ready <= i_ready | (~buf_valid);

            if (up_transfer_ok) begin
                // Buffer data, set valid and overflow flags
                buf_data_ovfl <= buf_data;
                buf_data <= i_data;
                buf_valid <= 1'b1;
                // Overflow
                if (!down_transfer_ok && buf_valid) begin
                    buf_overflown <= 1'b1;
                end
            end else begin
                // Clear overflow and valid flags
                if (down_transfer_ok) begin
                    if (buf_overflown ) begin
                        buf_overflown <= 1'b0;
                    end else begin
                        buf_valid <= 1'b0;
                    end
                end
            end
        end
    end

endmodule
