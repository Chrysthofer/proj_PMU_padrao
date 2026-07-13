# =============================================================================
#  plot_results.py - graficos dos resultados da PMU SAPHO (fast sim cocotb)
#
#  Le PMU_padrao/Simulation/pmu_results.txt (gerado pelo pmu_cocotb.py) e
#  reproduz os 6 paineis do Matilab/main.m: sinal de entrada, amplitude,
#  fase, frequencia, ROCOF e TVE - referencia analitica vs estimado no
#  processador.
#
#  Uso:  python plot_results.py [caminho\pmu_results.txt] [--show]
#        (sem argumentos usa PMU_padrao/Simulation/pmu_results.txt)
#  Saida: pmu_plots.png ao lado do arquivo de entrada.
# =============================================================================

import math
import re
import sys
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# paleta validada (dataviz): estimado = azul, referencia = vermelho tracejado
C_EST   = "#2a78d6"
C_REF   = "#e34948"
C_TEXT  = "#0b0b0b"
C_MUTED = "#52514e"
C_GRID  = "#d9d8d4"

GDELAY = 82            # atraso de grupo do FIR (164/2), como no PMU_padrao.m
STEADY0 = 400          # inicio da janela de regime usada no relatorio


def parse_results(path):
    """Le o cabecalho (parametros) e a tabela do pmu_results.txt."""
    params = {}
    rows = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith("#"):
                for key, val in re.findall(r"(\w+)=([-\d.]+)", line):
                    params.setdefault(key, float(val))
                continue
            parts = line.split()
            if len(parts) != 9:
                continue
            rows.append([float("nan") if p == "-" else float(p) for p in parts])
    if not rows:
        raise SystemExit(f"nenhuma linha de dados em {path} - rode a fast sim antes")
    return params, np.array(rows)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    show = "--show" in sys.argv
    path = Path(args[0]) if args else (
        Path(__file__).resolve().parent / "PMU_padrao" / "Simulation" / "pmu_results.txt")

    params, tab = parse_results(path)
    n        = tab[:, 0]
    x        = tab[:, 1]
    mag_hw   = tab[:, 4]
    fase_hw  = tab[:, 5]
    fe_hw    = tab[:, 6]
    rocof_hw = tab[:, 7]
    tve      = tab[:, 8]

    A   = params.get("A", 1.0)
    f1  = params.get("f1", 62.0)
    f0  = params.get("f0", 60.0)
    fs  = params.get("Fs", 1920.0)
    phi = params.get("phi", math.pi / 4)

    # referencia analitica alinhada ao atraso de grupo: X[n-82]
    mag_ref  = np.full_like(n, A / math.sqrt(2.0))
    fase_ref = np.degrees(np.angle(np.exp(
        1j * (2 * math.pi * (f1 - f0) * (n - GDELAY) / fs + phi))))

    steady = n >= STEADY0
    tve_st = tve[steady & ~np.isnan(tve)]
    fe_st  = fe_hw[steady]
    stats = (f"regime (n>={STEADY0}): TVE max {np.max(tve_st):.4f}% / "
             f"medio {np.mean(tve_st):.4f}%  |  "
             f"|FE| max {np.max(np.abs(fe_st - f1)) * 1e3:.2f} mHz")
    print(stats)

    fig, axs = plt.subplots(6, 1, figsize=(10, 14), sharex=True)
    fig.patch.set_facecolor("#fcfcfb")

    def style(ax):
        ax.set_facecolor("#fcfcfb")
        ax.grid(True, color=C_GRID, linewidth=0.6, alpha=0.6)
        for side in ("top", "right"):
            ax.spines[side].set_visible(False)
        for side in ("left", "bottom"):
            ax.spines[side].set_color(C_MUTED)
        ax.tick_params(colors=C_MUTED, labelsize=9)
        ax.axvspan(STEADY0, n[-1], color="#000000", alpha=0.04, zorder=0)

    # 1 - sinal de entrada
    ax = axs[0]
    ax.plot(n, x, color=C_EST, linewidth=0.9)
    ax.set_title("Sinal de entrada x[n]  (A=%g, f1=%g Hz, Fs=%g Hz)"
                 % (A, f1, fs), color=C_TEXT, fontsize=11, loc="left")
    ax.set_ylabel("x[n]", color=C_MUTED)

    # 2 - amplitude do fasor
    ax = axs[1]
    ax.plot(n, mag_ref, color=C_REF, linewidth=1.6, linestyle="--",
            label="Real (A/√2)")
    ax.plot(n, mag_hw, color=C_EST, linewidth=1.6, label="Estimado (SAPHO)")
    ax.set_title("Amplitude |X|", color=C_TEXT, fontsize=11, loc="left")
    ax.set_ylabel("|X|", color=C_MUTED)
    ax.set_ylim(0, 1.1 * A / math.sqrt(2) + 0.1)
    ax.legend(loc="lower right", fontsize=9, frameon=False)

    # 3 - fase do fasor
    ax = axs[2]
    ax.plot(n, fase_ref, color=C_REF, linewidth=1.6, linestyle="--",
            label="Real")
    ax.plot(n, fase_hw, color=C_EST, linewidth=1.2, label="Estimado (SAPHO)")
    ax.set_title("Fase de X (alinhada ao atraso de grupo, X[n-%d])" % GDELAY,
                 color=C_TEXT, fontsize=11, loc="left")
    ax.set_ylabel("graus", color=C_MUTED)
    ax.legend(loc="lower right", fontsize=9, frameon=False)

    # 4 - frequencia
    ax = axs[3]
    ax.plot(n, np.full_like(n, f1), color=C_REF, linewidth=1.6,
            linestyle="--", label="Real (%g Hz)" % f1)
    ax.plot(n, fe_hw, color=C_EST, linewidth=1.6, label="Estimado (SAPHO)")
    ax.set_title("Frequência estimada", color=C_TEXT, fontsize=11,
                 loc="left")
    ax.set_ylabel("Hz", color=C_MUTED)
    ax.set_ylim(f1 - 3, f1 + 3)   # o transitorio inicial sai da escala
    ax.legend(loc="lower right", fontsize=9, frameon=False)

    # 5 - ROCOF
    ax = axs[4]
    ax.plot(n, np.zeros_like(n), color=C_REF, linewidth=1.6, linestyle="--",
            label="Real (0)")
    ax.plot(n, rocof_hw, color=C_EST, linewidth=1.2, label="Estimado (SAPHO)")
    ax.set_title("ROCOF", color=C_TEXT, fontsize=11, loc="left")
    ax.set_ylabel("Hz/amostra", color=C_MUTED)
    ax.set_ylim(-0.5, 0.5)
    ax.legend(loc="lower right", fontsize=9, frameon=False)

    # 6 - TVE
    ax = axs[5]
    ax.plot(n, np.ones_like(n), color=C_REF, linewidth=1.6, linestyle="--",
            label="Limite 1 %")
    ax.plot(n, tve, color=C_EST, linewidth=1.6, label="TVE (SAPHO)")
    ax.set_title("TVE", color=C_TEXT, fontsize=11, loc="left")
    ax.set_ylabel("%", color=C_MUTED)
    ax.set_xlabel("amostra n", color=C_MUTED)
    ax.set_ylim(0, 5)
    ax.legend(loc="upper right", fontsize=9, frameon=False)
    ax.annotate(stats, xy=(0.01, 0.86), xycoords="axes fraction",
                fontsize=8.5, color=C_MUTED)

    for ax in axs:
        style(ax)

    fig.suptitle("PMU padrão em SAPHO × referência analítica "
                 "— teste Signal Frequency (faixa cinza = janela de regime)",
                 color=C_TEXT, fontsize=12, x=0.5, y=0.995)
    fig.tight_layout(rect=(0, 0, 1, 0.985))

    out = path.parent / "pmu_plots.png"
    fig.savefig(out, dpi=150, facecolor=fig.get_facecolor())
    print(f"grafico salvo em {out}")
    if show:
        plt.show()


if __name__ == "__main__":
    main()
