module PMU_padrao (

input  clk, rst,
input  signed [31:0] in ,
output signed [31:0] out,
output [1:0] req_in,
output [3:0] out_en,
output cheguei);

/* verilator tracing_off */

wire itr = 1'b0;
wire proc_req_in, proc_out_en;
wire [0:0] addr_in;
wire [1:0] addr_out;

`ifdef __ICARUS__
 `ifndef YANC_SIM_VIS
  `define YANC_SIM_VIS
 `endif
`endif
`ifdef YANC_TRACE
 `ifndef YANC_SIM_VIS
  `define YANC_SIM_VIS
 `endif
`endif

`ifdef YANC_SIM_VIS
wire mem_wr;
wire [9:0] mem_addr_wr;
wire [8:0] pc_sim_val;
`endif

processor#(.NUBITS(32),
.NBMANT(23),
.NBEXPO(8),
.NBOPER(10),
.NUGAIN(128),
.MDATAS(639),
.MINSTS(348),
.SDEPTH(32),
.DDEPTH(64),
.NBIOIN(1),
.NBIOOU(2),
.FFTSIZ(8),
.TOAQUIADDR(272),
.LOD(1),
.SET(1),
.LES(1),
.JIZ(1),
.P_LOD(1),
.F_NEG(1),
.F_ADD(1),
.CAL(1),
.STI(1),
.ADD(1),
.EQU(1),
.F_SU1(1),
.F_MLT(1),
.F_SU2(1),
.SF_DIV(1),
.LDI(1),
.F_DIV(1),
.SET_P(1),
.INN(1),
.F_INN(1),
.AND(1),
.SF_MLT(1),
.NEG_M(1),
.GRE(1),
.PF_NEG_M(1),
.SF_SU2(1),
.SF_ADD(1),
.F_LES(1),
.F2I(1),
.OUT(1),
.F_ABS_M(1),
.F_SGN(1),
.I2F(1),
.DFILE("C:/Users/LCOM/Documents/Github/proj_PMU_padrao/PMU_padrao/Hardware/PMU_padrao_data.mif"),
.IFILE("C:/Users/LCOM/Documents/Github/proj_PMU_padrao/PMU_padrao/Hardware/PMU_padrao_inst.mif"))

`ifdef YANC_SIM_VIS
p_PMU_padrao (clk, rst, in, out, addr_in, addr_out, proc_req_in, proc_out_en, itr, cheguei, mem_wr, mem_addr_wr,pc_sim_val);
`else
p_PMU_padrao (clk, rst, in, out, addr_in, addr_out, proc_req_in, proc_out_en, itr, cheguei);
`endif

addr_dec #(2) dec_in (proc_req_in, addr_in , req_in);
addr_dec #(4) dec_out(proc_out_en, addr_out, out_en);

/* verilator tracing_on */

// ----------------------------------------------------------------------------
// Simulation -----------------------------------------------------------------
// ----------------------------------------------------------------------------

`ifdef YANC_SIM_VIS

// I/O ------------------------------------------------------------------------

reg signed [31:0] in_sim_0 = 0;
reg req_in_sim_0 = 0;
reg signed [31:0] in_sim_1 = 0;
reg req_in_sim_1 = 0;

reg signed [31:0] out_sig_0 = 0;
reg out_en_sim_0 = 0;
reg signed [31:0] out_sig_1 = 0;
reg out_en_sim_1 = 0;
reg signed [31:0] out_sig_2 = 0;
reg out_en_sim_2 = 0;
reg signed [31:0] out_sig_3 = 0;
reg out_en_sim_3 = 0;

always @ (posedge clk) begin
   if (req_in == 1) in_sim_0 <= in;
   if (req_in == 2) in_sim_1 <= in;
end
always @ (*) begin
   req_in_sim_0 = req_in == 1;
   req_in_sim_1 = req_in == 2;
end

always @ (posedge clk) begin
   if (out_en == 1) out_sig_0 <= out;
   if (out_en == 2) out_sig_1 <= out;
   if (out_en == 4) out_sig_2 <= out;
   if (out_en == 8) out_sig_3 <= out;
end
always @ (*) begin
   out_en_sim_0 = out_en == 1;
   out_en_sim_1 = out_en == 2;
   out_en_sim_2 = out_en == 4;
   out_en_sim_3 = out_en == 8;
end

// variables ------------------------------------------------------------------

/* verilator tracing_off */  // float decode helpers (not traced)
reg signed [23:0] sm_me2; always @ (*) sm_me2 = (out[31]) ? -$signed({1'b0, out[22:0]}) : $signed({1'b0, out[22:0]});
reg signed [7:0] e_me2; always @ (*)  e_me2 = $signed(out[30:23]);
/* verilator tracing_on */

reg [31:0] me1_f_main_v_ii_e_ = 0;
real me2_f_main_v_ang_e_ = 0.0;
real me2_f_main_v_sumw_e_ = 0.0;
real me2_f_main_v_fk_e_ = 0.0;
real me2_f_main_v_a_e_ = 0.0;
real me2_f_main_v_h_e_ = 0.0;
real me2_f_main_v_sc_e_ = 0.0;
reg [31:0] me1_f_global_v_wr_e_ = 0;
reg [31:0] me1_f_global_v_nsmp_e_ = 0;
real me2_f_global_v_feprev_e_ = 0.0;
reg [31:0] me1_f_main_v_flagv_e_ = 0;
real me2_f_main_v_x_e_ = 0.0;
reg [31:0] me1_f_main_v_ph_e_ = 0;
real me2_f_main_v_yr_e_ = 0.0;
real me2_f_main_v_yi_e_ = 0.0;
real me2_f_main_v_accr_e_ = 0.0;
real me2_f_main_v_acci_e_ = 0.0;
reg [31:0] me1_f_main_v_idx_e_ = 0;
reg [31:0] me1_f_main_v_k_e_ = 0;
real me2_f_main_v_yi_out_e_ = 0.0;
real me2_f_main_v_dphi_e_ = 0.0;
real me2_f_main_v_fe_e_ = 0.0;
real me2_f_main_v_rocof_e_ = 0.0;
/* verilator tracing_off */  // comp raw halves (joined below, not traced)
reg [31:0] me3_f_global_v_yprev_i_e_ /* verilator public_flat */ = 32'dx;
reg [31:0] me3_f_global_v_yprev_e_ /* verilator public_flat */ = 32'dx;
reg [31:0] me3_f_main_v_y_i_e_ /* verilator public_flat */ = 32'dx;
reg [31:0] me3_f_main_v_y_e_ /* verilator public_flat */ = 32'dx;
reg [31:0] me3_f_main_v_rot_i_e_ /* verilator public_flat */ = 32'dx;
reg [31:0] me3_f_main_v_rot_e_ /* verilator public_flat */ = 32'dx;
/* verilator tracing_on */

always @ (posedge clk) begin
   if (mem_addr_wr == 557 && mem_wr) me1_f_main_v_ii_e_ <= out;
   if (mem_addr_wr == 559 && mem_wr) me2_f_main_v_ang_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 564 && mem_wr) me2_f_main_v_sumw_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 565 && mem_wr) me2_f_main_v_fk_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 571 && mem_wr) me2_f_main_v_a_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 575 && mem_wr) me2_f_main_v_h_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 577 && mem_wr) me2_f_main_v_sc_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 578 && mem_wr) me1_f_global_v_wr_e_ <= out;
   if (mem_addr_wr == 579 && mem_wr) me1_f_global_v_nsmp_e_ <= out;
   if (mem_addr_wr == 581 && mem_wr) me2_f_global_v_feprev_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 582 && mem_wr) me3_f_global_v_yprev_i_e_ <= out;
   if (mem_addr_wr == 583 && mem_wr) me3_f_global_v_yprev_e_ <= out;
   if (mem_addr_wr == 584 && mem_wr) me1_f_main_v_flagv_e_ <= out;
   if (mem_addr_wr == 586 && mem_wr) me2_f_main_v_x_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 588 && mem_wr) me1_f_main_v_ph_e_ <= out;
   if (mem_addr_wr == 589 && mem_wr) me2_f_main_v_yr_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 590 && mem_wr) me2_f_main_v_yi_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 591 && mem_wr) me2_f_main_v_accr_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 592 && mem_wr) me2_f_main_v_acci_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 593 && mem_wr) me1_f_main_v_idx_e_ <= out;
   if (mem_addr_wr == 594 && mem_wr) me1_f_main_v_k_e_ <= out;
   if (mem_addr_wr == 596 && mem_wr) me2_f_main_v_yi_out_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 597 && mem_wr) me3_f_main_v_y_i_e_ <= out;
   if (mem_addr_wr == 598 && mem_wr) me3_f_main_v_y_e_ <= out;
   if (mem_addr_wr == 599 && mem_wr) me2_f_main_v_dphi_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 602 && mem_wr) me3_f_main_v_rot_i_e_ <= out;
   if (mem_addr_wr == 603 && mem_wr) me3_f_main_v_rot_e_ <= out;
   if (mem_addr_wr == 610 && mem_wr) me2_f_main_v_fe_e_ <= sm_me2*$pow(2.0,e_me2);
   if (mem_addr_wr == 611 && mem_wr) me2_f_main_v_rocof_e_ <= sm_me2*$pow(2.0,e_me2);
end

wire [16+32*2-1:0] comp_me3_f_global_v_yprev_e_ = {8'd23, 8'd8, me3_f_global_v_yprev_e_, me3_f_global_v_yprev_i_e_};
wire [16+32*2-1:0] comp_me3_f_main_v_y_e_ = {8'd23, 8'd8, me3_f_main_v_y_e_, me3_f_main_v_y_i_e_};
wire [16+32*2-1:0] comp_me3_f_main_v_rot_e_ = {8'd23, 8'd8, me3_f_main_v_rot_e_, me3_f_main_v_rot_i_e_};

// instructions ---------------------------------------------------------------

reg [31:0] valr2=0;
/* verilator tracing_off */
reg [31:0] valr1 /* verilator public_flat */=0;
reg [31:0] valr3 /* verilator public_flat */=0;
reg [31:0] valr4 /* verilator public_flat */=0;
reg [31:0] valr5 /* verilator public_flat */=0;
reg [31:0] valr6 /* verilator public_flat */=0;
reg [31:0] valr7 /* verilator public_flat */=0;
reg [31:0] valr8 /* verilator public_flat */=0;
reg [31:0] valr9 /* verilator public_flat */=0;
reg [31:0] valr10 /* verilator public_flat */=0;
/* verilator tracing_on */

reg [19:0] min [0:283-1];

/* verilator tracing_off */ reg signed [19:0] linetab /* verilator public_flat */ =-1; /* verilator tracing_on */
reg signed [19:0] linetabs=-1;

initial	$readmemb("pc_PMU_padrao_mem.txt",min);

always @ (posedge clk) begin
if (pc_sim_val < 283) linetab <= min[pc_sim_val];
linetabs <= linetab;   
valr1    <= {{(23){1'b0}}, pc_sim_val};
valr2    <= valr1;
valr3    <= valr2;
valr4    <= valr3;
valr5    <= valr4;
valr6    <= valr5;
valr7    <= valr6;
valr8    <= valr7;
valr9    <= valr8;
valr10   <= valr9;
end

`endif

endmodule