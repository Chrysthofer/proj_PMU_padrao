// Cross-check testbench: pure Verilog, ZERO Python in the data path.
// Implements the same ADC front-end wrapper the FPGA will have, in the
// EVENT-DRIVEN (#PRACA) model:
//   - after a one-time startup hold-off (the LUT/FIR build must finish with
//     itr low), every STROBE_CLKS cycles: latch the next sample from
//     input_0.txt onto port 0 and PULSE the itr pin, which makes the
//     processor jump to #PRACA and process exactly that one sample.
// Dumps the raw output integers; must match cocotb's output_*.txt exactly.
//
// NOTE: the PMU_padrao instance below now carries the itr input (generated
// because the .cmm has a #PRACA marker). Regenerate the hardware in Aurora
// before simulating; the port order is (clk, rst, in, out, req_in, out_en,
// itr, cheguei).
`timescale 1ns/1ps

module xcheck_tb();

parameter NSAMP_X       = 40;      // samples to cross-check
parameter STROBE_CLKS   = 6000;    // ADC strobe period (clock cycles)
parameter STARTUP_CLKS  = 40000;   // one-time LUT/FIR build hold-off (itr low)
parameter ITR_PULSE_CLKS = 2;      // itr pulse width (clocks)

reg clk = 0, rst = 1;
initial #10 rst = 0;
always #5 clk = ~clk;

reg  signed [31:0] in_bus = 0;
wire signed [31:0] io_out;
wire req_in;                     // NUIOIN=1: single input port (port 0 = sample)
wire [3:0] out_en;
reg  itr = 0;                    // hardware new-sample strobe -> jump to #PRACA
wire cheguei;

PMU_padrao proc(clk, rst, in_bus, io_out, req_in, out_en, itr, cheguei);

// ---------------- ADC front-end wrapper (what the FPGA will contain) --------
integer fi, sr;
reg  signed [31:0] sample_reg = 0;
reg  started = 0;                // set once the startup hold-off elapses
integer warmup_cnt = 0;
integer strobe_cnt = 0;
integer itr_cnt    = 0;
integer nstrobed   = 0;

initial begin
    fi = $fopen("input_0.txt", "r");
    if (fi == 0) begin $display("FATAL: input_0.txt not found"); $finish; end
end

always @ (posedge clk) begin
    if (rst) begin
        itr <= 0; started <= 0; warmup_cnt <= 0; strobe_cnt <= 0;
        itr_cnt <= 0; nstrobed <= 0;
    end
    else if (!started) begin
        // hold itr low while the one-time LUT/FIR build runs
        warmup_cnt <= warmup_cnt + 1;
        if (warmup_cnt >= STARTUP_CLKS - 1) started <= 1;
    end
    else if (nstrobed < NSAMP_X) begin
        // start of a strobe period: latch next sample and raise itr
        if (strobe_cnt == 0) begin
            sr = $fscanf(fi, "%d", sample_reg);
            itr      <= 1;
            itr_cnt  <= 0;
            nstrobed <= nstrobed + 1;
        end
        // drop itr after ITR_PULSE_CLKS so the per-sample code can run
        if (itr) begin
            itr_cnt <= itr_cnt + 1;
            if (itr_cnt >= ITR_PULSE_CLKS - 1) itr <= 0;
        end
        // advance / wrap the period counter
        if (strobe_cnt == STROBE_CLKS - 1) strobe_cnt <= 0;
        else                               strobe_cnt <= strobe_cnt + 1;
    end
end

// bus decode: present the latched sample while the processor reads port 0
always @ (*) begin
    in_bus = 0;
    if (req_in == 1'b1) in_bus = sample_reg;   // port 0 (fin(0))
end

// ---------------- output capture --------------------------------------------
integer f0, f1, f2, f3;
integer n3 = 0;

initial begin
    f0 = $fopen("xout_0.txt", "w");
    f1 = $fopen("xout_1.txt", "w");
    f2 = $fopen("xout_2.txt", "w");
    f3 = $fopen("xout_3.txt", "w");
end

always @ (posedge clk) begin
    if (out_en == 4'd1) $fdisplay(f0, "%0d", io_out);
    if (out_en == 4'd2) $fdisplay(f1, "%0d", io_out);
    if (out_en == 4'd4) $fdisplay(f2, "%0d", io_out);
    if (out_en == 4'd8) begin
        $fdisplay(f3, "%0d", io_out);
        n3 = n3 + 1;
        if (n3 >= NSAMP_X) begin
            $display("XCHECK: %0d samples done", n3);
            $fflush(f0); $fflush(f1); $fflush(f2); $fflush(f3);
            $finish;
        end
    end
end

endmodule
