# =============================================================================
#  plot_results.py - graficos INTERATIVOS dos resultados da PMU SAPHO (Plotly)
#
#  Le PMU_padrao/Simulation/pmu_results.txt (gerado pelo pmu_cocotb.py) e
#  reproduz os 6 paineis do Matlab/main.m: sinal de entrada, amplitude,
#  fase, frequencia, ROCOF e TVE - referencia analitica vs estimado no
#  processador.
#
#  Uso:  python plot_results.py [caminho\pmu_results.txt] [--no-show]
#        (sem argumentos usa PMU_padrao/Simulation/pmu_results.txt)
#  Saida: pmu_plots.html (interativo) ao lado do arquivo de entrada; abre no
#         navegador automaticamente (use --no-show para so gerar o arquivo).
# =============================================================================

import math
import re
import sys
from pathlib import Path

import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# paleta validada (dataviz): estimado = azul, referencia = vermelho tracejado
C_EST   = "#2a78d6"
C_REF   = "#e34948"
C_TEXT  = "#0b0b0b"
C_MUTED = "#52514e"
C_GRID  = "#d9d8d4"
C_BG    = "#fcfcfb"

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
    show = "--no-show" not in sys.argv
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

    titles = (
        "Sinal de entrada x[n]  (A=%g, f1=%g Hz, Fs=%g Hz)" % (A, f1, fs),
        "Amplitude |X|",
        "Fase de X (alinhada ao atraso de grupo, X[n-%d])" % GDELAY,
        "Frequência estimada",
        "ROCOF",
        "TVE",
    )
    fig = make_subplots(rows=6, cols=1, shared_xaxes=True,
                        vertical_spacing=0.035, subplot_titles=titles)

    ref_kw = dict(mode="lines", line=dict(color=C_REF, width=2, dash="dash"))
    est_kw = dict(mode="lines", line=dict(color=C_EST, width=2))

    def add(row, y, name, **kw):
        fig.add_trace(go.Scatter(x=n, y=y, name=name, legendgroup=name,
                                 showlegend=(row == 2), **kw), row=row, col=1)

    # 1 - sinal de entrada
    fig.add_trace(go.Scatter(x=n, y=x, name="x[n]", showlegend=False,
                             mode="lines", line=dict(color=C_EST, width=1)),
                  row=1, col=1)

    # 2 - amplitude do fasor
    add(2, mag_ref, "Real (referência)", **ref_kw)
    add(2, mag_hw,  "Estimado (SAPHO)",  **est_kw)

    # 3 - fase do fasor
    add(3, fase_ref, "Real (referência)", **ref_kw)
    add(3, fase_hw,  "Estimado (SAPHO)",  **est_kw)

    # 4 - frequencia
    add(4, np.full_like(n, f1), "Real (referência)", **ref_kw)
    add(4, fe_hw,               "Estimado (SAPHO)",  **est_kw)

    # 5 - ROCOF
    add(5, np.zeros_like(n), "Real (referência)", **ref_kw)
    add(5, rocof_hw,         "Estimado (SAPHO)",  **est_kw)

    # 6 - TVE (referencia = limite de 1 %)
    add(6, np.ones_like(n), "Real (referência)", **ref_kw)
    add(6, tve,             "Estimado (SAPHO)",  **est_kw)

    # eixos y: rotulos e limites equivalentes ao matplotlib
    fig.update_yaxes(title_text="x[n]", row=1, col=1)
    fig.update_yaxes(title_text="|X|", range=[0, 1.1 * A / math.sqrt(2) + 0.1],
                     row=2, col=1)
    fig.update_yaxes(title_text="graus", row=3, col=1)
    fig.update_yaxes(title_text="Hz", range=[f1 - 3, f1 + 3], row=4, col=1)
    fig.update_yaxes(title_text="Hz/amostra", range=[-0.5, 0.5], row=5, col=1)
    fig.update_yaxes(title_text="%", range=[0, 5], row=6, col=1)
    fig.update_xaxes(title_text="amostra n", row=6, col=1)

    # faixa cinza = janela de regime (n >= STEADY0), em todos os paineis
    for r in range(1, 7):
        fig.add_vrect(x0=STEADY0, x1=float(n[-1]), fillcolor="#000000",
                      opacity=0.04, line_width=0, layer="below", row=r, col=1)

    # nota de estatisticas no painel do TVE
    fig.add_annotation(text=stats, xref="x domain", yref="y domain",
                       x=0.01, y=0.94, showarrow=False, align="left",
                       font=dict(size=11, color=C_MUTED), row=6, col=1)

    fig.update_layout(
        title=dict(text="PMU padrão em SAPHO × referência analítica "
                        "— teste Signal Frequency (faixa cinza = janela de regime)",
                   x=0.5, font=dict(size=15, color=C_TEXT)),
        height=1400, width=1000,
        paper_bgcolor=C_BG, plot_bgcolor=C_BG,
        font=dict(color=C_MUTED),
        legend=dict(orientation="h", yanchor="bottom", y=1.02,
                    xanchor="right", x=1),
        hovermode="x unified",
        margin=dict(t=90, r=40, l=70, b=50),
    )
    fig.update_xaxes(showgrid=True, gridcolor=C_GRID, zeroline=False)
    fig.update_yaxes(showgrid=True, gridcolor=C_GRID, zeroline=False)

    out = path.parent / "pmu_plots.html"
    fig.write_html(out, include_plotlyjs="cdn")
    print(f"grafico interativo salvo em {out}")
    if show:
        fig.show()


if __name__ == "__main__":
    main()
