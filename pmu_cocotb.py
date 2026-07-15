# aurora-toplevel: PMU_padrao
# =============================================================================
#  pmu_cocotb.py - cocotb testbench for the SAPHO "PMU_padrao" processor
#
#  Replicates Matlab/main.m (Signal Frequency test, IEC/IEEE 60255-118):
#      A = 1, f1 = 62 Hz, N = 1600 samples, f0 = 60 Hz, Fs = 1920 Hz, Fr = 60
#
#  The Python side (this file):
#    1. generates the test signal x[n] and its analytic reference phasor X[n]
#       (port of Matlab/signal_frequency.m, with a FIXED phase for
#       reproducibility - MATLAB uses a random one);
#    2. runs a double-precision reference model of the PMU (streaming port of
#       Matlab/PMU_padrao.m, identical to the C+- program's algorithm);
#    3. drives the SAPHO processor in the EVENT-DRIVEN (#PRACA) model: it pulses
#       the hardware itr pin once per ADC sample (emulating the FPGA ADC strobe),
#       serves that sample on fin(0), and collects the four Q20 integer outputs
#       (Re{Xe}, Im{Xe}, fe, ROCOF) * 2^20;
#    4. writes everything to TXT files in PMU_padrao/Simulation/ and checks
#       TVE / FE / ROCOF limits.
#
#  No waveform is needed: run with Aurora's "Fast Sim" button.
# =============================================================================

import math
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import (Event, FallingEdge, First, NextTimeStep,
                             ReadOnly, Timer, ValueChange)

try:                                    # cocotb >= 2.0
    from cocotb.simtime import get_sim_time
except ImportError:                     # older cocotb
    from cocotb.utils import get_sim_time

# ----------------------------------------------------------------------------
# Test parameters (mirror Matlab/main.m)
# ----------------------------------------------------------------------------
A        = 1.0                    # signal amplitude
F1       = 62.0                   # signal frequency [Hz]  (60 + 2)
F0       = 60.0                   # nominal frequency [Hz]
FS       = 1920.0                 # sampling frequency [Hz]
FREP     = 60.0                   # reporting frequency [Hz]
NSAMP    = int(os.environ.get("PMU_NSAMPLES", "1600"))   # 16*100 in main.m
PHI      = math.pi / 4            # fixed initial phase (MATLAB: random)

NFILT    = 164                    # class-M FIR length  (Fn=60, Fr=60)
FREP_FLT = 8.19                   # class-M design parameter (filtro_classM.m)
GDELAY   = NFILT // 2             # FIR group delay = 82 samples

SCALE    = 1 << 20                # Q20 port scaling (must match the .cmm)
MASK32   = 0xFFFFFFFF

# ADC-strobe emulation (EVENT-DRIVEN / #PRACA model): every PMU_STROBE_CLKS
# clock cycles a new sample is latched onto input port 0 and the itr pin is
# pulsed, exactly like the FPGA ADC front-end will do.  The itr pulse makes the
# processor jump to #PRACA and process that one sample.  STROBE_CLKS must exceed
# the per-sample processing time (~4.6k cycles) so the processor is back at idle
# before the next strobe; 6000 leaves ~25% headroom.  The real 100 MHz/1920 Hz
# ratio would be 52083 (set the env var to try it - results are identical, the
# sim just takes ~9x longer).
STROBE_CLKS = int(os.environ.get("PMU_STROBE_CLKS", "6000"))
CLK_NS      = 10                  # testbench clock period

# One-time startup hold-off: main() builds the demod LUTs and the 164-tap FIR
# ONCE before it can accept samples.  itr must stay LOW during that build (an
# early pulse would abort it mid-way), so the first strobe waits this many
# clocks after reset - the FPGA wrapper does the same with a power-on counter.
# Tune against the first sim: the build is ~15-25k cycles; 40000 is safe slack.
STARTUP_CLKS = int(os.environ.get("PMU_STARTUP_CLKS", "40000"))

# itr pulse width.  While itr is high the PC is held at the #PRACA entry; the
# per-sample code runs once itr drops.  A short pulse (a couple of clocks) is
# enough to latch the jump.
ITR_PULSE_CLKS = int(os.environ.get("PMU_ITR_PULSE_CLKS", "2"))

STEADY0  = 400                    # first sample of the steady-state window

# pass/fail limits over the steady-state window.
# TVE is judged against the analytic truth (the MATLAB algorithm itself sits
# at ~0.98% for f1=62 due to negative-image leakage, so 1.2% flags real
# regressions without failing the reference behaviour).  fe/ROCOF carry an
# intrinsic per-sample ripple in the MATLAB algorithm (phase derivative with
# no post-smoothing), so the hardware is judged on how well it REPLICATES the
# double-precision model, not on absolute frequency error.
TVE_MAX_PCT   = 1.2               # vs analytic truth
DPHASOR_MAX   = 1e-4              # |Re/Im hw - model| max
DFE_MAX_HZ    = 0.01              # |fe hw - model| max
DROCOF_MAX    = 0.01              # |ROCOF hw - model| max
FE_MEAN_MAX   = 0.01              # |mean(fe - f1)| (bias) max, Hz

OUTDIR = Path(__file__).resolve().parent / "PMU_padrao" / "Simulation"


# ----------------------------------------------------------------------------
# Reference generation (ports of the MATLAB sources - the source of truth)
# ----------------------------------------------------------------------------
def signal_frequency(a, f1, n, f0, fs, phi):
    """Port of Matlab/signal_frequency.m (fixed phase instead of random)."""
    x = [a * math.cos(2.0 * math.pi * f1 * k / fs + phi) for k in range(n)]
    ref = [(a / math.sqrt(2.0)) *
           complex(math.cos(2.0 * math.pi * (f1 - f0) * k / fs + phi),
                   math.sin(2.0 * math.pi * (f1 - f0) * k / fs + phi))
           for k in range(n)]
    return x, ref


def filtro_class_m(fs=FS, frep=FREP_FLT, n=NFILT):
    """Port of Matlab/filtro_classM.m for Fn=60, Fr=60 (frep=8.19, N=164)."""
    w = [0.0] * n
    for k in range(n):
        a = 2.0 * math.pi * (2.0 * frep / fs) * (k - n / 2.0)
        h = 0.54 - 0.46 * math.cos(2.0 * math.pi * k / (n - 1))
        w[k] = 1.0 if k == n // 2 else (math.sin(a) / a) * h
    s = math.sqrt(2.0) / sum(w)
    return [c * s for c in w]


def pmu_reference_model(x):
    """Streaming double-precision port of Matlab/PMU_padrao.m.

    Same algorithm the C+- program implements: quadrature demod at Fn,
    class-M FIR, frequency from the consecutive-phasor angle difference,
    ROCOF from the frequency difference.  Returns per-sample lists aligned
    with the processor outputs (index n = n-th input sample).
    """
    w0 = filtro_class_m()
    bufr = [0.0] * NFILT
    bufi = [0.0] * NFILT
    wr = 0
    yprev = complex(0.0, 0.0)
    feprev = F0
    ys, fes, rocofs = [], [], []
    for n, xn in enumerate(x):
        ang = 2.0 * math.pi * (n % 32) / 32.0        # Fn/Fs = 1/32 exactly
        bufr[wr] = xn * math.cos(ang)
        bufi[wr] = xn * math.sin(ang)
        accr = acci = 0.0
        idx = wr
        for k in range(NFILT):
            accr += w0[k] * bufr[idx]
            acci += w0[k] * bufi[idx]
            idx = NFILT - 1 if idx == 0 else idx - 1
        wr = 0 if wr == NFILT - 1 else wr + 1
        y = complex(accr, -acci)
        if n == 0:
            dphi = 0.0
        else:
            rot = y * yprev.conjugate()
            dphi = math.atan2(rot.imag, rot.real)
        fe = FS / (2.0 * math.pi) * dphi + F0
        rocof = fe - feprev
        ys.append(y)
        fes.append(fe)
        rocofs.append(rocof)
        yprev = y
        feprev = fe
    return ys, fes, rocofs


def tve_pct(est, ref):
    """Port of Matlab/TVE.m for a single pair of phasors."""
    d = est - ref
    return 100.0 * math.sqrt((d.real ** 2 + d.imag ** 2) /
                             (ref.real ** 2 + ref.imag ** 2))


def generate_plots(log):
    """Render pmu_plots.html by running plot_results.py in an external Python.

    Aurora's bundled MSYS interpreter has no plotly, so the plots are
    delegated to a system Python that does.  Search order: PMU_PLOT_PYTHON
    env var, common Windows install paths, the 'py' launcher.  Skipping is
    non-fatal: the TXT outputs are already written.
    """
    import shutil
    import subprocess

    if os.environ.get("PMU_MAKE_PLOTS", "1") != "1":
        return
    script = Path(__file__).resolve().parent / "plot_results.py"
    if not script.exists():
        log.warning("PMU: plot_results.py not found, skipping plots")
        return

    local = os.environ.get("LOCALAPPDATA", "")
    candidates = [os.environ.get("PMU_PLOT_PYTHON", "")]
    candidates += [str(Path(local) / "Programs" / "Python" / d / "python.exe")
                   for d in ("Python314", "Python313", "Python312",
                             "Python311", "Python310")]
    py = shutil.which("py")
    launchers = [[c] for c in candidates if c and Path(c).exists()]
    if py:
        launchers.append([py, "-3"])

    # The simulator runs an EMBEDDED (MSYS) Python that exports PYTHONHOME/
    # PYTHONPATH pointing at its own stdlib+site-packages; a child that
    # inherits them imports from the MSYS tree (no plotly), so the probe
    # would fail even for a valid system Python.  Strip every PYTHON* var
    # that redirects module resolution before spawning the interpreter.
    child_env = {k: v for k, v in os.environ.items()
                 if k.upper() not in ("PYTHONHOME", "PYTHONPATH",
                                      "PYTHONSTARTUP", "PYTHONEXECUTABLE",
                                      "PYTHONNOUSERSITE")}

    for cmd in launchers:
        try:
            probe = subprocess.run(cmd + ["-c", "import plotly, numpy"],
                                   capture_output=True, timeout=60, env=child_env)
            if probe.returncode != 0:
                continue
            run = subprocess.run(cmd + [str(script)], capture_output=True,
                                 text=True, timeout=300, env=child_env,
                                 cwd=str(script.parent))
            if run.returncode == 0:
                log.info("PMU: plots -> %s" % run.stdout.strip()
                         .splitlines()[-1] if run.stdout.strip() else "ok")
            else:
                log.warning("PMU: plot_results.py failed:\n%s" % run.stderr)
            return
        except (OSError, subprocess.TimeoutExpired):
            continue
    log.warning("PMU: no Python with plotly found, skipping plots "
                "(set PMU_PLOT_PYTHON or run plot_results.py manually)")


# ----------------------------------------------------------------------------
# DUT drivers - emulate the FPGA ADC front-end wrapper
# ----------------------------------------------------------------------------
async def adc_strobe(dut, samples_int, adc, period_clks):
    """Latch one sample + pulse the itr pin every period_clks cycles.

    Mirrors the FPGA ADC front-end: at each strobe the sample register is
    updated and the itr pin is pulsed, which makes the processor jump to
    #PRACA and process exactly that one sample.  Strobing starts only after
    STARTUP_CLKS (the one-time LUT/FIR build must finish with itr low first).
    If the previous sample has not been fully processed when the next strobe
    fires (fewer outputs than strobes), it is flagged as an overrun.
    """
    # hold itr low through reset + the one-time startup build
    for _ in range(STARTUP_CLKS):
        await FallingEdge(dut.clk)

    for i, s in enumerate(samples_int):
        # present the new sample, then pulse itr -> jump to #PRACA
        adc["sample"] = s
        dut.itr.value = 1
        for _ in range(ITR_PULSE_CLKS):
            await FallingEdge(dut.clk)
        dut.itr.value = 0
        adc["strobed"] = i + 1
        # overrun check: the processor should have emitted all 4 outputs of the
        # previous sample (== i completed samples) before this strobe landed
        if adc["produced"] < i:
            adc["overruns"] += 1
        # wait out the rest of the sample period before the next strobe
        for _ in range(max(1, period_clks - ITR_PULSE_CLKS)):
            await FallingEdge(dut.clk)


async def bus_server(dut, adc):
    """Answer the processor's input reads (req_in one-hot: 1 == port 0).

    In the #PRACA model there is a single input port: reading port 0 (fin(0))
    delivers the latched ADC sample.  The value is placed on the bus at the
    time step after req_in rises, i.e. before the closing posedge at which the
    processor latches it.
    """
    sig_in = getattr(dut, "in")         # 'in' is a Python keyword
    while True:
        await ValueChange(dut.req_in)
        await ReadOnly()
        try:
            req = int(dut.req_in.value)
        except ValueError:              # X/Z during reset
            continue
        if req == 0:
            continue
        await NextTimeStep()
        if req == 1:                    # port 0: serve the sample
            sig_in.value = adc["sample"] & MASK32
            adc["consumed"] += 1


async def collect_outputs(dut, outs, adc, done_evt, nsamp):
    """Record the output port (signed) whenever out_en is one-hot (0..3).

    Port 3 (ROCOF) is the last fout() of each sample, so its running count is
    the number of fully-produced samples - published in adc["produced"] for the
    strobe's overrun check.
    """
    sig_out = getattr(dut, "out")
    port_of = {1: 0, 2: 1, 4: 2, 8: 3}
    while True:
        await ValueChange(dut.out_en)
        await ReadOnly()
        try:
            en = int(dut.out_en.value)
        except ValueError:          # X/Z during reset
            continue
        port = port_of.get(en)
        if port is None:
            continue
        try:
            raw = sig_out.value.to_signed()
        except ValueError:
            raw = 0
        outs[port].append(raw)
        if port == 3:
            adc["produced"] = len(outs[3])
            if len(outs[3]) % 160 == 0:
                dut._log.info("PMU: %d/%d samples processed (sim time %.3f ms)"
                              % (len(outs[3]), nsamp, get_sim_time("ns") / 1e6))
        if len(outs[3]) >= nsamp:
            done_evt.set()
            return


# ----------------------------------------------------------------------------
# The test
# ----------------------------------------------------------------------------
@cocotb.test()
async def pmu_signal_frequency(dut):
    # ---------------- stimulus and reference (pure Python) ------------------
    x, xref = signal_frequency(A, F1, NSAMP, F0, FS, PHI)
    x_int = [int(round(v * SCALE)) for v in x]
    ymod, femod, rocofmod = pmu_reference_model(x)

    # ---------------- clock / reset ----------------------------------------
    getattr(dut, "in").value = 0
    dut.itr.value = 0                 # itr must stay low through the startup build
    dut.rst.value = 1
    Clock(dut.clk, 10, "ns").start()
    for _ in range(4):
        await FallingEdge(dut.clk)
    dut.rst.value = 0

    # ---------------- run --------------------------------------------------
    outs = [[], [], [], []]
    done = Event()
    adc = {"sample": 0, "consumed": 0, "strobed": 0, "produced": 0,
           "overruns": 0}
    cocotb.start_soon(adc_strobe(dut, x_int, adc, STROBE_CLKS))
    cocotb.start_soon(bus_server(dut, adc))
    cocotb.start_soon(collect_outputs(dut, outs, adc, done, NSAMP))

    # sim-time watchdog: one-time startup hold-off + one strobe period per
    # sample + generous slack
    timeout_ns = int((STARTUP_CLKS + NSAMP * (STROBE_CLKS + 5000)) * CLK_NS
                     + 50e6 * 10)
    await First(done.wait(), Timer(timeout_ns, "ns"))
    assert done.is_set(), (
        "PMU timeout: %d strobed / %d consumed / %d produced of %d "
        "(port counts: %s)"
        % (adc["strobed"], adc["consumed"], len(outs[3]), NSAMP,
           [len(o) for o in outs]))
    assert adc["overruns"] == 0, (
        "%d overruns: itr strobed before the previous sample finished "
        "(STROBE_CLKS=%d too short?)" % (adc["overruns"], STROBE_CLKS))
    dut._log.info("PMU: %d itr strobes, %d samples read, 0 overruns "
                  "(period %d clks, startup hold-off %d clks)"
                  % (adc["strobed"], adc["consumed"], STROBE_CLKS,
                     STARTUP_CLKS))

    ncap = len(outs[3])
    re_hw    = [v / SCALE for v in outs[0][:ncap]]
    im_hw    = [v / SCALE for v in outs[1][:ncap]]
    fe_hw    = [v / SCALE for v in outs[2][:ncap]]
    rocof_hw = [v / SCALE for v in outs[3][:ncap]]
    y_hw = [complex(r, i) for r, i in zip(re_hw, im_hw)]

    # ---------------- analysis ---------------------------------------------
    # y_hw[n] estimates the phasor at sample n - GDELAY (FIR group delay),
    # exactly like Matlab/PMU_padrao.m which drops floor(N/2) samples.
    steady0 = STEADY0 if ncap > STEADY0 + 50 else max(GDELAY + 1, ncap // 2)
    win = [n for n in range(steady0, ncap)]
    tve_hw  = {n: tve_pct(y_hw[n], xref[n - GDELAY]) for n in win}
    tve_mod = {n: tve_pct(ymod[n], xref[n - GDELAY]) for n in win}
    fe_err  = {n: fe_hw[n] - F1 for n in win}
    roc_err = {n: rocof_hw[n] - 0.0 for n in win}

    # hardware float (24-bit mantissa) vs double-precision model
    dre  = max(abs(y_hw[n].real - ymod[n].real) for n in win)
    dim  = max(abs(y_hw[n].imag - ymod[n].imag) for n in win)
    dfe  = max(abs(fe_hw[n] - femod[n]) for n in win)
    droc = max(abs(rocof_hw[n] - rocofmod[n]) for n in win)

    stats = {
        "tve_max": max(tve_hw.values()),
        "tve_mean": sum(tve_hw.values()) / len(win),
        "tve_mod_max": max(tve_mod.values()),
        "fe_max": max(abs(v) for v in fe_err.values()),
        "fe_mean": sum(fe_err.values()) / len(win),
        "rocof_max": max(abs(v) for v in roc_err.values()),
    }

    # ---------------- TXT outputs ------------------------------------------
    OUTDIR.mkdir(parents=True, exist_ok=True)

    with open(OUTDIR / "input_0.txt", "w") as f:
        f.write("\n".join(str(v) for v in x_int) + "\n")
    for p in range(4):
        with open(OUTDIR / ("output_%d.txt" % p), "w") as f:
            f.write("\n".join(str(v) for v in outs[p]) + "\n")

    with open(OUTDIR / "pmu_results.txt", "w") as f:
        f.write("# PMU_padrao on SAPHO - cocotb fast sim results\n")
        f.write("# A=%g f1=%g Hz f0=%g Hz Fs=%g Hz Fr=%g Hz phi=%.10f rad "
                "N=%d Q20\n" % (A, F1, F0, FS, FREP, PHI, ncap))
        f.write("# TVE compares y_hw[n] against X[n-%d] (FIR group delay); "
                "'-' while n < %d\n" % (GDELAY, GDELAY))
        f.write("#%7s %12s %12s %12s %12s %12s %12s %12s %10s\n"
                % ("n", "x[n]", "Re_hw", "Im_hw", "abs_hw", "fase_deg",
                   "fe_hw", "ROCOF_hw", "TVE_pct"))
        for n in range(ncap):
            mag = abs(y_hw[n])
            ph = math.degrees(math.atan2(y_hw[n].imag, y_hw[n].real))
            tve_s = ("%10.5f" % tve_pct(y_hw[n], xref[n - GDELAY])
                     ) if n >= GDELAY else "%10s" % "-"
            f.write("%8d %12.7f %12.7f %12.7f %12.7f %12.6f %12.7f %12.7f %s\n"
                    % (n, x[n], re_hw[n], im_hw[n], mag, ph,
                       fe_hw[n], rocof_hw[n], tve_s))

    ok_tve   = stats["tve_max"] < TVE_MAX_PCT
    ok_febia = abs(stats["fe_mean"]) < FE_MEAN_MAX
    ok_dphas = dre < DPHASOR_MAX and dim < DPHASOR_MAX
    ok_dfe   = dfe < DFE_MAX_HZ
    ok_droc  = droc < DROCOF_MAX

    with open(OUTDIR / "pmu_report.txt", "w") as f:
        f.write("PMU_padrao (SAPHO) x MATLAB reference - summary report\n")
        f.write("=" * 62 + "\n")
        f.write("Test          : Signal Frequency (IEC/IEEE 60255-118)\n")
        f.write("Parameters    : A=%g  f1=%g Hz  f0=%g Hz  Fs=%g Hz  Fr=%g\n"
                % (A, F1, F0, FS, FREP))
        f.write("Fixed phase   : %.10f rad (MATLAB main.m uses random)\n" % PHI)
        f.write("Samples       : %d fed / %d captured, steady window [%d,%d)\n"
                % (NSAMP, ncap, steady0, ncap))
        f.write("Port scaling  : Q20 (2^20 = %d)\n" % SCALE)
        f.write("ADC handshake : itr strobe every %d clks (#PRACA per-sample "
                "restart), %d overruns\n\n" % (STROBE_CLKS, adc["overruns"]))
        f.write("Steady-state metrics (hardware vs analytic truth X):\n")
        f.write("  TVE   max   : %.6f %%   (limit %.2f %%)  -> %s\n"
                % (stats["tve_max"], TVE_MAX_PCT,
                   "PASS" if ok_tve else "FAIL"))
        f.write("  TVE   mean  : %.6f %%   (model max: %.6f %%)\n"
                % (stats["tve_mean"], stats["tve_mod_max"]))
        f.write("  FE    mean  : %+.6f Hz  (bias limit %.3f) -> %s\n"
                % (stats["fe_mean"], FE_MEAN_MAX,
                   "PASS" if ok_febia else "FAIL"))
        f.write("  |FE|  max   : %.6f Hz   (info: intrinsic per-sample ripple\n"
                "                of the MATLAB algorithm, present in the\n"
                "                double model as well - not a hardware error)\n"
                % stats["fe_max"])
        f.write("  |ROCOF| max : %.6f Hz/sample (info)\n\n" % stats["rocof_max"])
        f.write("Replication of the MATLAB algorithm (hardware float vs the\n")
        f.write("same algorithm in double precision), max |diff| in window:\n")
        f.write("  Re    : %.3e  (limit %.0e) -> %s\n"
                % (dre, DPHASOR_MAX, "PASS" if dre < DPHASOR_MAX else "FAIL"))
        f.write("  Im    : %.3e  (limit %.0e) -> %s\n"
                % (dim, DPHASOR_MAX, "PASS" if dim < DPHASOR_MAX else "FAIL"))
        f.write("  fe    : %.3e Hz (limit %.0e) -> %s\n"
                % (dfe, DFE_MAX_HZ, "PASS" if ok_dfe else "FAIL"))
        f.write("  ROCOF : %.3e  (limit %.0e) -> %s\n"
                % (droc, DROCOF_MAX, "PASS" if ok_droc else "FAIL"))
        f.write("\nFiles: input_0.txt, output_0..3.txt (raw Q20 integers),\n")
        f.write("       pmu_results.txt (per-sample table, real units)\n")

    dut._log.info("PMU report: TVE max %.4f%% | FE max %.5f Hz | "
                  "ROCOF max %.5f | hw-vs-model dRe %.2e dfe %.2e"
                  % (stats["tve_max"], stats["fe_max"],
                     stats["rocof_max"], dre, dfe))
    dut._log.info("PMU: TXT written to %s" % OUTDIR)

    # plots come before the asserts so they exist even when a check fails
    generate_plots(dut._log)

    assert ncap == NSAMP and all(len(o) == NSAMP for o in outs), \
        "output count mismatch: %s" % [len(o) for o in outs]
    assert ok_tve, "TVE max %.4f%% exceeds %.2f%%" % (stats["tve_max"],
                                                      TVE_MAX_PCT)
    assert ok_febia, "FE bias %.5f Hz exceeds %.3f Hz" % (stats["fe_mean"],
                                                          FE_MEAN_MAX)
    assert ok_dphas, "phasor deviates from double model: dRe=%.2e dIm=%.2e" \
        % (dre, dim)
    assert ok_dfe, "fe deviates from double model: %.2e Hz" % dfe
    assert ok_droc, "ROCOF deviates from double model: %.2e" % droc
