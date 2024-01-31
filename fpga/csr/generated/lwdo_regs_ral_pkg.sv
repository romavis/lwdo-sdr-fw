package lwdo_regs_ral_pkg;
  import uvm_pkg::*;
  import rggen_ral_pkg::*;
  `include "uvm_macros.svh"
  `include "rggen_ral_macros.svh"
  class sys_magic_reg_model extends rggen_ral_reg;
    rand rggen_ral_field magic;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(magic, 0, 32, "RO", 0, 32'h4544574c, 1, -1, "")
    endfunction
  endclass
  class sys_version_reg_model extends rggen_ral_reg;
    rand rggen_ral_field major;
    rand rggen_ral_field minor;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(major, 0, 16, "RO", 0, 16'h0001, 1, -1, "")
      `rggen_ral_create_field(minor, 16, 16, "RO", 0, 16'h0001, 1, -1, "")
    endfunction
  endclass
  class sys_con_reg_model extends rggen_ral_reg;
    rand rggen_ral_field sys_rst;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(sys_rst, 0, 1, "W1", 0, 1'h0, 1, -1, "")
    endfunction
  endclass
  class sys_pll_reg_model extends rggen_ral_reg;
    rand rggen_ral_field divr;
    rand rggen_ral_field divf;
    rand rggen_ral_field divq;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(divr, 0, 4, "RO", 0, 4'h0, 1, -1, "")
      `rggen_ral_create_field(divf, 4, 7, "RO", 0, 7'h00, 1, -1, "")
      `rggen_ral_create_field(divq, 11, 3, "RO", 0, 3'h0, 1, -1, "")
    endfunction
  endclass
  class sys_reg_file_model extends rggen_ral_reg_file;
    rand sys_magic_reg_model magic;
    rand sys_version_reg_model version;
    rand sys_con_reg_model con;
    rand sys_pll_reg_model pll;
    function new(string name);
      super.new(name, 2, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(magic, '{}, 9'h000, "RO", "g_magic.u_register")
      `rggen_ral_create_reg(version, '{}, 9'h004, "RO", "g_version.u_register")
      `rggen_ral_create_reg(con, '{}, 9'h008, "RW", "g_con.u_register")
      `rggen_ral_create_reg(pll, '{}, 9'h00a, "RO", "g_pll.u_register")
    endfunction
  endclass
  class pdet_con_reg_model extends rggen_ral_reg;
    rand rggen_ral_field en;
    rand rggen_ral_field eclk2_slow;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(en, 0, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(eclk2_slow, 1, 1, "RW", 0, 1'h0, 1, -1, "")
    endfunction
  endclass
  class pdet_n1_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 32, "RO", 0, 32'h00000000, 1, -1, "")
    endfunction
  endclass
  class pdet_n2_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 32, "RO", 0, 32'h00000000, 1, -1, "")
    endfunction
  endclass
  class pdet_reg_file_model extends rggen_ral_reg_file;
    rand pdet_con_reg_model con;
    rand pdet_n1_reg_model n1;
    rand pdet_n2_reg_model n2;
    function new(string name);
      super.new(name, 2, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(con, '{}, 9'h000, "RW", "g_con.u_register")
      `rggen_ral_create_reg(n1, '{}, 9'h002, "RO", "g_n1.u_register")
      `rggen_ral_create_reg(n2, '{}, 9'h006, "RO", "g_n2.u_register")
    endfunction
  endclass
  class adct_con_reg_model extends rggen_ral_reg;
    rand rggen_ral_field srate1_en;
    rand rggen_ral_field srate2_en;
    rand rggen_ral_field puls1_en;
    rand rggen_ral_field puls2_en;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(srate1_en, 0, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(srate2_en, 1, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(puls1_en, 2, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(puls2_en, 3, 1, "RW", 0, 1'h0, 1, -1, "")
    endfunction
  endclass
  class adct_srate1_psc_div_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 8, "RW", 0, 8'hc7, 1, -1, "")
    endfunction
  endclass
  class adct_srate2_psc_div_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 8, "RW", 0, 8'hc7, 1, -1, "")
    endfunction
  endclass
  class adct_puls1_psc_div_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 23, "RW", 0, 23'h000000, 1, -1, "")
    endfunction
  endclass
  class adct_puls2_psc_div_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 23, "RW", 0, 23'h000000, 1, -1, "")
    endfunction
  endclass
  class adct_puls1_dly_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 9, "RW", 0, 9'h000, 1, -1, "")
    endfunction
  endclass
  class adct_puls2_dly_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 9, "RW", 0, 9'h000, 1, -1, "")
    endfunction
  endclass
  class adct_puls1_pwidth_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 16, "RW", 0, 16'h0001, 1, -1, "")
    endfunction
  endclass
  class adct_puls2_pwidth_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 16, "RW", 0, 16'h0001, 1, -1, "")
    endfunction
  endclass
  class adct_reg_file_model extends rggen_ral_reg_file;
    rand adct_con_reg_model con;
    rand adct_srate1_psc_div_reg_model srate1_psc_div;
    rand adct_srate2_psc_div_reg_model srate2_psc_div;
    rand adct_puls1_psc_div_reg_model puls1_psc_div;
    rand adct_puls2_psc_div_reg_model puls2_psc_div;
    rand adct_puls1_dly_reg_model puls1_dly;
    rand adct_puls2_dly_reg_model puls2_dly;
    rand adct_puls1_pwidth_reg_model puls1_pwidth;
    rand adct_puls2_pwidth_reg_model puls2_pwidth;
    function new(string name);
      super.new(name, 2, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(con, '{}, 9'h000, "RW", "g_con.u_register")
      `rggen_ral_create_reg(srate1_psc_div, '{}, 9'h002, "RW", "g_srate1_psc_div.u_register")
      `rggen_ral_create_reg(srate2_psc_div, '{}, 9'h004, "RW", "g_srate2_psc_div.u_register")
      `rggen_ral_create_reg(puls1_psc_div, '{}, 9'h006, "RW", "g_puls1_psc_div.u_register")
      `rggen_ral_create_reg(puls2_psc_div, '{}, 9'h00a, "RW", "g_puls2_psc_div.u_register")
      `rggen_ral_create_reg(puls1_dly, '{}, 9'h00e, "RW", "g_puls1_dly.u_register")
      `rggen_ral_create_reg(puls2_dly, '{}, 9'h010, "RW", "g_puls2_dly.u_register")
      `rggen_ral_create_reg(puls1_pwidth, '{}, 9'h012, "RW", "g_puls1_pwidth.u_register")
      `rggen_ral_create_reg(puls2_pwidth, '{}, 9'h014, "RW", "g_puls2_pwidth.u_register")
    endfunction
  endclass
  class adc_con_reg_model extends rggen_ral_reg;
    rand rggen_ral_field adc1_en;
    rand rggen_ral_field adc2_en;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(adc1_en, 0, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(adc2_en, 1, 1, "RW", 0, 1'h0, 1, -1, "")
    endfunction
  endclass
  class adc_fifo1_sts_reg_model extends rggen_ral_reg;
    rand rggen_ral_field empty;
    rand rggen_ral_field full;
    rand rggen_ral_field hfull;
    rand rggen_ral_field ovfl;
    rand rggen_ral_field udfl;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(empty, 0, 1, "RO", 1, 1'h0, 0, -1, "")
      `rggen_ral_create_field(full, 1, 1, "RO", 1, 1'h0, 0, -1, "")
      `rggen_ral_create_field(hfull, 2, 1, "RO", 1, 1'h0, 0, -1, "")
      `rggen_ral_create_field(ovfl, 3, 1, "RO", 1, 1'h0, 0, -1, "")
      `rggen_ral_create_field(udfl, 4, 1, "RO", 1, 1'h0, 0, -1, "")
    endfunction
  endclass
  class adc_fifo2_sts_reg_model extends rggen_ral_reg;
    rand rggen_ral_field empty;
    rand rggen_ral_field full;
    rand rggen_ral_field hfull;
    rand rggen_ral_field ovfl;
    rand rggen_ral_field udfl;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(empty, 0, 1, "RO", 1, 1'h0, 0, -1, "")
      `rggen_ral_create_field(full, 1, 1, "RO", 1, 1'h0, 0, -1, "")
      `rggen_ral_create_field(hfull, 2, 1, "RO", 1, 1'h0, 0, -1, "")
      `rggen_ral_create_field(ovfl, 3, 1, "RO", 1, 1'h0, 0, -1, "")
      `rggen_ral_create_field(udfl, 4, 1, "RO", 1, 1'h0, 0, -1, "")
    endfunction
  endclass
  class adc_reg_file_model extends rggen_ral_reg_file;
    rand adc_con_reg_model con;
    rand adc_fifo1_sts_reg_model fifo1_sts;
    rand adc_fifo2_sts_reg_model fifo2_sts;
    function new(string name);
      super.new(name, 2, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(con, '{}, 9'h000, "RW", "g_con.u_register")
      `rggen_ral_create_reg(fifo1_sts, '{}, 9'h002, "RO", "g_fifo1_sts.u_register")
      `rggen_ral_create_reg(fifo2_sts, '{}, 9'h004, "RO", "g_fifo2_sts.u_register")
    endfunction
  endclass
  class ftun_vtune_set_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 16, "RW", 0, 16'h8000, 1, -1, "")
    endfunction
  endclass
  class ftun_reg_file_model extends rggen_ral_reg_file;
    rand ftun_vtune_set_reg_model vtune_set;
    function new(string name);
      super.new(name, 2, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(vtune_set, '{}, 9'h000, "RW", "g_vtune_set.u_register")
    endfunction
  endclass
  class test_rw1_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 16, "RW", 0, 16'h0000, 1, -1, "")
    endfunction
  endclass
  class test_ro1_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 16, "RO", 0, 16'hffff, 1, -1, "")
    endfunction
  endclass
  class test_ro2_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 16, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 16, "RO", 0, 16'h0000, 1, -1, "")
    endfunction
  endclass
  class test_ro3_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 32, "RO", 0, 32'haaaaaa55, 1, -1, "")
    endfunction
  endclass
  class test_ro4_reg_model extends rggen_ral_reg;
    rand rggen_ral_field val;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(val, 0, 32, "RO", 0, 32'h55aa5555, 1, -1, "")
    endfunction
  endclass
  class test_reg_file_model extends rggen_ral_reg_file;
    rand test_rw1_reg_model rw1;
    rand test_ro1_reg_model ro1;
    rand test_ro2_reg_model ro2;
    rand test_ro3_reg_model ro3;
    rand test_ro4_reg_model ro4;
    function new(string name);
      super.new(name, 2, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(rw1, '{}, 9'h000, "RW", "g_rw1.u_register")
      `rggen_ral_create_reg(ro1, '{}, 9'h002, "RO", "g_ro1.u_register")
      `rggen_ral_create_reg(ro2, '{}, 9'h004, "RO", "g_ro2.u_register")
      `rggen_ral_create_reg(ro3, '{}, 9'h006, "RO", "g_ro3.u_register")
      `rggen_ral_create_reg(ro4, '{}, 9'h00a, "RO", "g_ro4.u_register")
    endfunction
  endclass
  class lwdo_regs_block_model extends rggen_ral_block;
    rand sys_reg_file_model sys;
    rand pdet_reg_file_model pdet;
    rand adct_reg_file_model adct;
    rand adc_reg_file_model adc;
    rand ftun_reg_file_model ftun;
    rand test_reg_file_model test;
    function new(string name);
      super.new(name, 2, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg_file(sys, '{}, 9'h000, "g_sys")
      `rggen_ral_create_reg_file(pdet, '{}, 9'h020, "g_pdet")
      `rggen_ral_create_reg_file(adct, '{}, 9'h040, "g_adct")
      `rggen_ral_create_reg_file(adc, '{}, 9'h080, "g_adc")
      `rggen_ral_create_reg_file(ftun, '{}, 9'h0a0, "g_ftun")
      `rggen_ral_create_reg_file(test, '{}, 9'h1f0, "g_test")
    endfunction
  endclass
endpackage
