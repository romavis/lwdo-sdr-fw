// `ifndef CMD_DEFINES_VH_
// `define CMD_DEFINES_VH_

// Start byte
localparam CMD_RX_START = 8'hA3;
localparam CMD_TX_START = 8'hA5;

// Access sizes
localparam CMD_WSIZE_1BYTE = 2'b00;
localparam CMD_WSIZE_2BYTE = 2'b01;
localparam CMD_WSIZE_4BYTE = 2'b10;

// Indices of request header bytes
localparam CMD_RX_BIDX_OP = 3'd0;
localparam CMD_RX_BIDX_SZ = 3'd1;
localparam CMD_RX_BIDX_A0 = 3'd2;
localparam CMD_RX_BIDX_A1 = 3'd3;
localparam CMD_RX_BIDX_A2 = 3'd4;
localparam CMD_RX_BIDX_A3 = 3'd5;
localparam CMD_RX_BIDX_CRC = 3'd6;

// Indices of response header bytes
localparam CMD_TX_BIDX_OP = 3'd0;
localparam CMD_TX_BIDX_SZ = 3'd1;
localparam CMD_TX_BIDX_A0 = 3'd2;
localparam CMD_TX_BIDX_A1 = 3'd3;
localparam CMD_TX_BIDX_A2 = 3'd4;
localparam CMD_TX_BIDX_A3 = 3'd5;
localparam CMD_TX_BIDX_CRC = 3'd6;
localparam CMD_TX_BIDX_LAST = 3'd7;


// `endif
