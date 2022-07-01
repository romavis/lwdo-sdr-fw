`ifndef RGGEN_RTL_MACRO_VH
`define RGGEN_RTL_MACRO_VH

`define RGGEN_READ          2'b10
`define RGGEN_POSTED_WRITE  2'b01
`define RGGEN_WRITE         2'b11

`define RGGEN_OKAY          2'b00
`define RGGEN_EXOKAY        2'b01
`define RGGEN_SLAVE_ERROR   2'b10
`define RGGEN_DECODE_ERROR  2'b11

`define RGGEN_SW_ACCESS 0
`define RGGEN_HW_ACCESS 1

`define RGGEN_ACTIVE_LOW  1'b0
`define RGGEN_ACTIVE_HIGH 1'b1

`define RGGEN_READ_NONE     0
`define RGGEN_READ_DEFAULT  1
`define RGGEN_READ_CLEAR    2
`define RGGEN_READ_SET      3

`define RGGEN_WRITE_NONE      0
`define RGGEN_WRITE_DEFAULT   1
`define RGGEN_WRITE_0_CLEAR   2
`define RGGEN_WRITE_1_CLEAR   3
`define RGGEN_WRITE_CLEAR     4
`define RGGEN_WRITE_0_SET     5
`define RGGEN_WRITE_1_SET     6
`define RGGEN_WRITE_SET       7
`define RGGEN_WRITE_0_TOGGLE  8
`define RGGEN_WRITE_1_TOGGLE  9

`define rggen_slice(EXPRESSION, WIDTH, INDEX) \
(((EXPRESSION) >> ((WIDTH) * (INDEX))) & {(WIDTH){1'b1}})

`define rggen_clip_width(WIDTH) \
(((WIDTH) > 0) ? (WIDTH) : 1)

`define rggen_tie_off_unused_signals(WIDTH, VALID_BITS, READ_DATA, VALUE) \
if (1) begin : __g_tie_off \
  genvar  __i; \
  for (__i = 0;__i < WIDTH;__i = __i + 1) begin : g \
    if (!((VALID_BITS >> __i) & 1'b1)) begin : g \
      assign  READ_DATA[__i]  = 1'b0; \
      assign  VALUE[__i]      = 1'b0; \
    end \
  end \
end

`endif
