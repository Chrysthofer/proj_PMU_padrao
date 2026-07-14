`timescale 1ns/1ps

module PMU_padrao_tb();

// clock and reset generation -------------------------------------------------

reg clk, rst;

initial begin
    clk = 0;
    rst = 1;
    #10.000000;
    rst = 0;
end

always #5.000000 clk = ~clk;

// processor instance ---------------------------------------------------------

/* verilator tracing_off */

reg  signed [31:0] proc_io_in = 0;
wire signed [31:0] proc_io_out;
wire [1:0] proc_req_in;
wire [3:0] proc_out_en;

wire proc_cheguei;

/* verilator tracing_on */
PMU_padrao proc(clk,rst,proc_io_in,proc_io_out,proc_req_in,proc_out_en,proc_cheguei);

/* verilator tracing_off */

// input ports ----------------------------------------------------------------

// port 0 variables
integer data_in_0;
reg signed [31:0] in_0 = 0;
reg req_in_0 = 0;

// port 1 variables
integer data_in_1;
reg signed [31:0] in_1 = 0;
reg req_in_1 = 0;

// open a file for reading on each port
initial begin
    data_in_0 = $fopen("C:/Users/LCOM/Documents/Github/proj_PMU_padrao/PMU_padrao/Simulation/input_0.txt", "r"); // place your input data in this file
    data_in_1 = $fopen("C:/Users/LCOM/Documents/Github/proj_PMU_padrao/PMU_padrao/Simulation/input_1.txt", "r"); // place your input data in this file
end

// decode input ports
always @ (*) begin
    proc_io_in = 0;
    // port 0 decoding
    if (proc_req_in == 1) proc_io_in = in_0;
    req_in_0 = proc_req_in == 1;
    // port 1 decoding
    if (proc_req_in == 2) proc_io_in = in_1;
    req_in_1 = proc_req_in == 2;
end

// implement reading of the input data
integer scan_result;
always @ (negedge clk) begin  
    // reading port 0
    if (data_in_0 != 0 && proc_req_in == 1) scan_result = $fscanf(data_in_0, "%d", in_0);
    // reading port 1
    if (data_in_1 != 0 && proc_req_in == 2) scan_result = $fscanf(data_in_1, "%d", in_1);
end

// output ports ---------------------------------------------------------------

// port 0 variables
integer data_out_0;
reg signed [31:0] out_sig_0 = 0;
reg out_en_0 = 0;

// port 1 variables
integer data_out_1;
reg signed [31:0] out_sig_1 = 0;
reg out_en_1 = 0;

// port 2 variables
integer data_out_2;
reg signed [31:0] out_sig_2 = 0;
reg out_en_2 = 0;

// port 3 variables
integer data_out_3;
reg signed [31:0] out_sig_3 = 0;
reg out_en_3 = 0;

// open a file for writing on each port
initial begin
    data_out_0 = $fopen("C:/Users/LCOM/Documents/Github/proj_PMU_padrao/PMU_padrao/Simulation/output_0.txt", "w"); // check the output data in this file
    data_out_1 = $fopen("C:/Users/LCOM/Documents/Github/proj_PMU_padrao/PMU_padrao/Simulation/output_1.txt", "w"); // check the output data in this file
    data_out_2 = $fopen("C:/Users/LCOM/Documents/Github/proj_PMU_padrao/PMU_padrao/Simulation/output_2.txt", "w"); // check the output data in this file
    data_out_3 = $fopen("C:/Users/LCOM/Documents/Github/proj_PMU_padrao/PMU_padrao/Simulation/output_3.txt", "w"); // check the output data in this file
end

// decode output ports
always @ (*) begin
    // port 0 decoding
    out_sig_0 = proc_io_out;
    out_en_0  = proc_out_en == 1;
    // port 1 decoding
    out_sig_1 = proc_io_out;
    out_en_1  = proc_out_en == 2;
    // port 2 decoding
    out_sig_2 = proc_io_out;
    out_en_2  = proc_out_en == 4;
    // port 3 decoding
    out_sig_3 = proc_io_out;
    out_en_3  = proc_out_en == 8;
end

// implement writing to the file
always @ (posedge clk) begin
    // write to port 0
    if (out_en_0 == 1'b1) begin $fdisplay(data_out_0, "%0d", out_sig_0); $fflush(data_out_0); end
    // write to port 1
    if (out_en_1 == 1'b1) begin $fdisplay(data_out_1, "%0d", out_sig_1); $fflush(data_out_1); end
    // write to port 2
    if (out_en_2 == 1'b1) begin $fdisplay(data_out_2, "%0d", out_sig_2); $fflush(data_out_2); end
    // write to port 3
    if (out_en_3 == 1'b1) begin $fdisplay(data_out_3, "%0d", out_sig_3); $fflush(data_out_3); end
end

// signal registration, progress bar and finish ------------------------------

integer chrys;

always @ (posedge clk) if (proc.valr10 == 282) begin
    $display("Info: end of program!");
    $finish;
end

initial begin

    $dumpfile("PMU_padrao_tb.vcd");

    $dumpvars(0,PMU_padrao_tb.clk);
    $dumpvars(0,PMU_padrao_tb.rst);
    $dumpvars(0,PMU_padrao_tb.proc.req_in_sim_0);
    $dumpvars(0,PMU_padrao_tb.proc.in_sim_0);
    $dumpvars(0,PMU_padrao_tb.proc.req_in_sim_1);
    $dumpvars(0,PMU_padrao_tb.proc.in_sim_1);
    $dumpvars(0,PMU_padrao_tb.proc.out_en_sim_0);
    $dumpvars(0,PMU_padrao_tb.proc.out_sig_0);
    $dumpvars(0,PMU_padrao_tb.proc.out_en_sim_1);
    $dumpvars(0,PMU_padrao_tb.proc.out_sig_1);
    $dumpvars(0,PMU_padrao_tb.proc.out_en_sim_2);
    $dumpvars(0,PMU_padrao_tb.proc.out_sig_2);
    $dumpvars(0,PMU_padrao_tb.proc.out_en_sim_3);
    $dumpvars(0,PMU_padrao_tb.proc.out_sig_3);
    $dumpvars(0,PMU_padrao_tb.proc.valr2);
    $dumpvars(0,PMU_padrao_tb.proc.linetabs);
    $dumpvars(0,PMU_padrao_tb.proc.me1_f_main_v_ii_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_ang_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_sumw_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_fk_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_a_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_h_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_sc_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me1_f_global_v_wr_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me1_f_global_v_nsmp_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_global_v_feprev_e_);
    $dumpvars(0,PMU_padrao_tb.proc.comp_me3_f_global_v_yprev_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me1_f_main_v_flagv_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_x_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me1_f_main_v_ph_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_yr_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_yi_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_accr_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_acci_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me1_f_main_v_idx_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me1_f_main_v_k_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_yi_out_e_);
    $dumpvars(0,PMU_padrao_tb.proc.comp_me3_f_main_v_y_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_dphi_e_);
    $dumpvars(0,PMU_padrao_tb.proc.comp_me3_f_main_v_rot_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_fe_e_);
    $dumpvars(0,PMU_padrao_tb.proc.me2_f_main_v_rocof_e_);
    $dumpvars(0,PMU_padrao_tb.proc.p_PMU_padrao.core.instr_fetch.isp_blk.isp.pointeri);
    $dumpvars(0,PMU_padrao_tb.proc.p_PMU_padrao.core.instr_fetch.isp_blk.isp.fl_max);
    $dumpvars(0,PMU_padrao_tb.proc.p_PMU_padrao.core.instr_fetch.isp_blk.isp.fl_full);
    $dumpvars(0,PMU_padrao_tb.proc.p_PMU_padrao.core.sp.pointeri);
    $dumpvars(0,PMU_padrao_tb.proc.p_PMU_padrao.core.sp.fl_max);
    $dumpvars(0,PMU_padrao_tb.proc.p_PMU_padrao.core.sp.fl_full);
    $dumpvars(0,PMU_padrao_tb.proc.p_PMU_padrao.core.ula.delta_float);
    $dumpvars(0,PMU_padrao_tb.proc.p_PMU_padrao.core.ula.delta_int);

    if ($test$plusargs("HEADER_ONLY")) begin #1; $dumpflush; $finish; end

    for (chrys = 10; chrys <= 100; chrys = chrys + 10) begin
        #2000.000000;  // wall-clock slice of the total sim time
        $display("Progress: %0d%% complete", chrys);
        $fflush;
    end

    $display("Simulation Complete!");
    $finish;

end

endmodule
