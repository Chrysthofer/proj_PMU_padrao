// Cross-check testbench: pure Verilog, ZERO Python in the data path.
// Implements the same ADC front-end wrapper the FPGA will have:
//   - every STROBE_CLKS cycles: latch next sample from input_0.txt and set
//     the new-sample flag (input port 1);
//   - the processor busy-waits on port 1, then reads port 0, which clears
//     the flag.
// Dumps the raw output integers; must match cocotb's output_*.txt exactly.
`timescale 1ns/1ps

module xcheck_tb();

parameter NSAMP_X     = 40;      // samples to cross-check
parameter STROBE_CLKS = 6000;    // ADC strobe period (clock cycles)

reg clk = 0, rst = 1;
initial #10 rst = 0;
always #5 clk = ~clk;

reg  signed [31:0] in_bus = 0;
wire signed [31:0] io_out;
wire [1:0] req_in;               // one-hot: 1 = port 0 (sample), 2 = port 1 (flag)
wire [3:0] out_en;
wire cheguei;

PMU_padrao proc(clk, rst, in_bus, io_out, req_in, out_en, cheguei);

// ---------------- ADC front-end wrapper (what the FPGA will contain) --------
integer fi, sr;
reg  signed [31:0] sample_reg = 0;
reg  flag = 0;
reg  seen_poll = 0;              // strobing starts after the first flag poll
integer strobe_cnt = 0;
integer nstrobed = 0;

initial begin
    fi = $fopen("input_0.txt", "r");
    if (fi == 0) begin $display("FATAL: input_0.txt not found"); $finish; end
end

always @ (posedge clk) begin
    if (req_in == 2'd2) seen_poll <= 1;              // processor is polling
    if (seen_poll && nstrobed < NSAMP_X) begin
        strobe_cnt <= strobe_cnt + 1;
        if (strobe_cnt == STROBE_CLKS - 1) begin     // ADC strobe
            strobe_cnt <= 0;
            sr = $fscanf(fi, "%d", sample_reg);
            flag <= 1;
            nstrobed <= nstrobed + 1;
        end
    end
    if (req_in == 2'd1) flag <= 0;                   // port-0 read clears it
end

// bus decode: like the yanc tb, the value is presented while req_in is high
always @ (*) begin
    in_bus = 0;
    if (req_in == 2'd1) in_bus = sample_reg;
    if (req_in == 2'd2) in_bus = {31'b0, flag};
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
