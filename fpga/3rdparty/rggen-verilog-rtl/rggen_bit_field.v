`include  "rggen_rtl_macros.vh"
module rggen_bit_field #(
  parameter             WIDTH                     = 8,
  parameter [WIDTH-1:0] INITIAL_VALUE             = {WIDTH{1'b0}},
  parameter             PRECEDENCE_ACCESS         = `RGGEN_HW_ACCESS,
  parameter             SW_READ_ACTION            = `RGGEN_READ_DEFAULT,
  parameter             SW_WRITE_ACTION           = `RGGEN_WRITE_DEFAULT,
  parameter             SW_WRITE_ONCE             = 0,
  parameter             SW_WRITE_ENABLE_POLARITY  = `RGGEN_ACTIVE_HIGH,
  parameter             HW_WRITE_ENABLE_POLARITY  = `RGGEN_ACTIVE_HIGH,
  parameter             HW_SET_WIDTH              = WIDTH,
  parameter             HW_CLEAR_WIDTH            = WIDTH,
  parameter             STORAGE                   = 1,
  parameter             EXTERNAL_READ_DATA        = 0,
  parameter             TRIGGER                   = 0
)(
  input                         i_clk,
  input                         i_rst_n,
  input                         i_sw_valid,
  input   [WIDTH-1:0]           i_sw_read_mask,
  input                         i_sw_write_enable,
  input   [WIDTH-1:0]           i_sw_write_mask,
  input   [WIDTH-1:0]           i_sw_write_data,
  output  [WIDTH-1:0]           o_sw_read_data,
  output  [WIDTH-1:0]           o_sw_value,
  output                        o_write_trigger,
  output                        o_read_trigger,
  input                         i_hw_write_enable,
  input   [WIDTH-1:0]           i_hw_write_data,
  input   [HW_SET_WIDTH-1:0]    i_hw_set,
  input   [HW_CLEAR_WIDTH-1:0]  i_hw_clear,
  input   [WIDTH-1:0]           i_value,
  input   [WIDTH-1:0]           i_mask,
  output  [WIDTH-1:0]           o_value,
  output  [WIDTH-1:0]           o_value_unmasked
);
//--------------------------------------------------------------
//  Utility functions
//--------------------------------------------------------------
  function automatic [1:0] get_sw_update;
    input             valid;
    input [WIDTH-1:0] read_mask;
    input             write_enable;
    input [WIDTH-1:0] write_mask;
    input             write_done;

    reg [1:0] action;
    reg [1:0] access;
  begin
    action[0] = (SW_READ_ACTION  == `RGGEN_READ_CLEAR) ||
                (SW_READ_ACTION  == `RGGEN_READ_SET  );
    action[1] = (SW_WRITE_ACTION != `RGGEN_WRITE_NONE);

    access[0] = (read_mask  != {WIDTH{1'b0}});
    access[1] = (write_mask != {WIDTH{1'b0}}) && (write_enable == SW_WRITE_ENABLE_POLARITY) && (!write_done);

    get_sw_update[0]  = valid && action[0] && access[0];
    get_sw_update[1]  = valid && action[1] && access[1];
  end
  endfunction

  function automatic get_hw_update;
    input                       write_enable;
    input [HW_SET_WIDTH-1:0]    set;
    input [HW_CLEAR_WIDTH-1:0]  clear;

    reg [2:0] update;
  begin
    update[0]     = write_enable == HW_WRITE_ENABLE_POLARITY;
    update[1]     = set   != {HW_SET_WIDTH{1'b0}};
    update[2]     = clear != {HW_CLEAR_WIDTH{1'b0}};
    get_hw_update = update[0] || update[1] || update[2];
  end
  endfunction

  function automatic [WIDTH-1:0] get_next_value;
    input [WIDTH-1:0]           current_value;
    input [1:0]                 sw_update;
    input [WIDTH-1:0]           sw_write_mask;
    input [WIDTH-1:0]           sw_write_data;
    input                       hw_write_enable;
    input [WIDTH-1:0]           hw_write_data;
    input [HW_SET_WIDTH-1:0]    hw_set;
    input [HW_CLEAR_WIDTH-1:0]  hw_clear;

    reg [WIDTH-1:0] value;
  begin
    if (PRECEDENCE_ACCESS == `RGGEN_SW_ACCESS) begin
      value =
        get_hw_next_value(
          current_value, hw_write_enable, hw_write_data,
          hw_set, hw_clear
        );
      value =
        get_sw_next_value(
          value, sw_update, sw_write_mask, sw_write_data
        );
    end
    else begin
      value =
        get_sw_next_value(
          current_value, sw_update, sw_write_mask, sw_write_data
        );
      value =
        get_hw_next_value(
          value, hw_write_enable, hw_write_data,
          hw_set, hw_clear
        );
    end

    get_next_value  = value;
  end
  endfunction

  function automatic [WIDTH-1:0] get_sw_next_value;
    input [WIDTH-1:0] current_value;
    input [1:0]       update;
    input [WIDTH-1:0] write_mask;
    input [WIDTH-1:0] write_data;

    reg [WIDTH-1:0] value[0:1];
    reg [WIDTH-1:0] masked_data[0:1];
  begin
    case (SW_READ_ACTION)
      `RGGEN_READ_CLEAR:  value[0]  = {WIDTH{1'b0}};
      `RGGEN_READ_SET:    value[0]  = {WIDTH{1'b1}};
      default:            value[0]  = current_value;
    endcase

    masked_data[0]  = write_mask & (~write_data);
    masked_data[1]  = write_mask & ( write_data);
    case (SW_WRITE_ACTION)
      `RGGEN_WRITE_DEFAULT:   value[1]  = (current_value & (~write_mask)) | masked_data[1];
      `RGGEN_WRITE_0_CLEAR:   value[1]  = current_value & (~masked_data[0]);
      `RGGEN_WRITE_1_CLEAR:   value[1]  = current_value & (~masked_data[1]);
      `RGGEN_WRITE_CLEAR:     value[1]  = {WIDTH{1'b0}};
      `RGGEN_WRITE_0_SET:     value[1]  = current_value | masked_data[0];
      `RGGEN_WRITE_1_SET:     value[1]  = current_value | masked_data[1];
      `RGGEN_WRITE_SET:       value[1]  = {WIDTH{1'b1}};
      `RGGEN_WRITE_0_TOGGLE:  value[1]  = current_value ^ masked_data[0];
      `RGGEN_WRITE_1_TOGGLE:  value[1]  = current_value ^ masked_data[1];
      default:                value[1]  = current_value;
    endcase

    case (update)
      2'b01:    get_sw_next_value = value[0];
      2'b10:    get_sw_next_value = value[1];
      default:  get_sw_next_value = current_value;
    endcase
  end
  endfunction

  function automatic [WIDTH-1:0] get_hw_next_value;
    input [WIDTH-1:0]           current_value;
    input                       write_enable;
    input [WIDTH-1:0]           write_data;
    input [HW_SET_WIDTH-1:0]    set;
    input [HW_CLEAR_WIDTH-1:0]  clear;

    reg [WIDTH-1:0] set_clear[0:1];
    reg [WIDTH-1:0] value;
  begin
    if (HW_SET_WIDTH == WIDTH) begin
      set_clear[0][HW_SET_WIDTH-1:0]  = set;
    end
    else begin
      set_clear[0]  = {WIDTH{set[0]}};
    end

    if (HW_CLEAR_WIDTH == WIDTH) begin
      set_clear[1][HW_CLEAR_WIDTH-1:0]  = clear;
    end
    else begin
      set_clear[1]  = {WIDTH{clear[0]}};
    end

    if (write_enable == HW_WRITE_ENABLE_POLARITY) begin
      value = write_data;
    end
    else begin
      value = current_value;
    end

    get_hw_next_value = (value & (~set_clear[1])) | set_clear[0];
  end
  endfunction

//--------------------------------------------------------------
//  Body
//--------------------------------------------------------------
  localparam  SW_READABLE = SW_READ_ACTION != `RGGEN_READ_NONE;

  wire  [1:0]       w_sw_update;
  wire              w_sw_write_done;
  wire              w_hw_update;
  wire  [1:0]       w_trigger;
  wire  [WIDTH-1:0] w_read_data;
  wire  [WIDTH-1:0] w_value;

  assign  o_sw_read_data    = w_read_data & i_mask;
  assign  o_sw_value        = w_value;
  assign  o_write_trigger   = w_trigger[0];
  assign  o_read_trigger    = w_trigger[1];
  assign  o_value           = w_value & i_mask;
  assign  o_value_unmasked  = w_value;

  assign  w_sw_update =
    get_sw_update(
      i_sw_valid, i_sw_read_mask, i_sw_write_enable,
      i_sw_write_mask, w_sw_write_done
    );
  assign  w_hw_update =
    get_hw_update(
      i_hw_write_enable, i_hw_set, i_hw_clear
    );

  generate
    if (STORAGE && SW_WRITE_ONCE) begin : g_sw_write_done
      reg r_sw_write_done;

      assign  w_sw_write_done = r_sw_write_done;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_sw_write_done <= 1'b0;
        end
        else if (w_sw_update[1]) begin
          r_sw_write_done <= 1'b1;
        end
      end
    end
    else begin : g_sw_write_done
      assign  w_sw_write_done = 1'b0;
    end
  endgenerate

  generate
    if (TRIGGER && (SW_WRITE_ACTION != `RGGEN_WRITE_NONE)) begin : g_write_trigger
      reg r_trigger;

      assign  w_trigger[0]  = r_trigger;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_trigger <= 1'b0;
        end
        else begin
          r_trigger <= w_sw_update[1];
        end
      end
    end
    else begin : g_write_trigger
      assign  w_trigger[0]  = 1'b0;
    end

    if (TRIGGER && (SW_WRITE_ACTION != `RGGEN_READ_NONE)) begin : g_read_trigger
      reg r_trigger;

      assign  w_trigger[1]  = r_trigger;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_trigger <= 1'b0;
        end
        else begin
          r_trigger <= i_sw_valid && (i_sw_read_mask != {WIDTH{1'b0}});
        end
      end
    end
    else begin : g_read_trigger
      assign  w_trigger[1]  = 1'b0;
    end
  endgenerate

  generate
    if (STORAGE) begin : g_value
      wire  [WIDTH-1:0] w_value_next;
      reg   [WIDTH-1:0] r_value;

      assign  w_value_next  =
        get_next_value(
          w_value, w_sw_update, i_sw_write_mask, i_sw_write_data,
          i_hw_write_enable, i_hw_write_data, i_hw_set, i_hw_clear
        );
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_value <= INITIAL_VALUE;
        end
        else if (w_sw_update[0] || w_sw_update[1] || w_hw_update) begin
          r_value <= w_value_next;
        end
      end

      assign  w_value = r_value;
    end
    else begin : g_value
      assign  w_value = i_value;
    end
  endgenerate

  generate
    if (!SW_READABLE) begin : g_read_data
      assign  w_read_data = {WIDTH{1'b0}};
    end
    else if (EXTERNAL_READ_DATA) begin : g_read_data
      assign  w_read_data = i_value;
    end
    else begin : g_read_data
      assign  w_read_data = w_value;
    end
  endgenerate
endmodule
