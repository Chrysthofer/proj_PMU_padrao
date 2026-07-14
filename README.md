# PMU classe M em processador SAPHO, validada com cocotb

Implementação de uma PMU (Phasor Measurement Unit) classe M no soft-processor
[SAPHO](https://github.com/nipscernlab/yanc), com verificação totalmente
automatizada em Python/cocotb contra a implementação MATLAB de referência.

O estimador segue a norma IEC/IEEE 60255-118-1: demodulação em quadratura na
frequência nominal, filtro classe M de 164 taps, fasor, frequência e ROCOF.
A referência (source of truth) é o código MATLAB em `Matilab/`.

## Resultado da validação

Teste Signal Frequency (A = 1, f1 = 62 Hz, f0 = 60 Hz, Fs = 1920 Hz, 1600
amostras), janela de regime [400, 1600):

| Métrica | Valor | Critério |
|---|---|---|
| TVE máximo | 0,9802 % | < 1,2 % (o próprio algoritmo MATLAB dá 0,9799 %) |
| Viés de frequência | +0,7 mHz | < 10 mHz |
| Fasor, hardware × modelo double | 5,2e-6 | < 1e-4 |
| Frequência, hardware × modelo double | 6,9e-4 Hz | < 1e-2 Hz |
| Overruns de amostra | 0 em 1600 | = 0 |

O processador replica o algoritmo MATLAB até o limite da precisão do seu
float de 24 bits. Verificação cruzada adicional: um testbench Verilog puro
(`PMU_padrao/Simulation/xcheck_tb.v`), sem Python no caminho dos dados,
produz saídas bit a bit idênticas às capturadas pelo cocotb.

## Pipeline de simulação (um clique na AURORA)

O botão Fast Sim da IDE [AURORA](https://github.com/nipscernlab/aurora)
executa a cadeia completa, sem waveform:

1. recompila `PMU_padrao/Software/PMU_padrao.cmm` (C±) para Verilog;
2. roda o cocotb (Icarus): `pmu_cocotb.py` gera o sinal de teste, emula o
   front-end do ADC (strobe periódico + flag de amostra nova), alimenta o
   processador e captura as 4 saídas;
3. o mesmo teste roda o modelo de referência em double, calcula TVE/FE/ROCOF,
   grava os TXT e o relatório, e gera os gráficos (`pmu_plots.png`).

Saídas em `PMU_padrao/Simulation/`: `input_0.txt` e `output_0..3.txt`
(inteiros Q20 crus das portas), `pmu_results.txt` (tabela por amostra),
`pmu_report.txt` (resumo com PASS/FAIL) e `pmu_plots.png`.

Detalhes de uso, escala Q20 das portas e handshake de amostra nova:
[README_SIMULACAO.md](README_SIMULACAO.md). Explicação didática do ciclo do
processador e do gatilho: [docs/diagrama_ciclo_processador.html](docs/diagrama_ciclo_processador.html).

## Requisitos

- AURORA com a toolchain yanc embarcada (compiladores C±/ASM, Icarus Verilog,
  Python 3.12 com cocotb 2.0.1). Abra `proj_PMU_padrao.spf` e use Fast Sim.
- Para os gráficos: um Python do sistema com `matplotlib` e `numpy`
  (detectado automaticamente; configurável via variável `PMU_PLOT_PYTHON`).
- Alternativa sem AURORA: compile com os binários do yanc e rode o runner
  cocotb manualmente, ou use o `xcheck_tb.v` com iverilog/vvp puro.

## Variáveis de ambiente do teste

| Variável | Default | Efeito |
|---|---|---|
| `PMU_NSAMPLES` | 1600 | número de amostras simuladas |
| `PMU_STROBE_CLKS` | 6000 | período do strobe do ADC em clocks (caso real 100 MHz/1920 Hz: 52083) |
| `PMU_MAKE_PLOTS` | 1 | 0 desliga a geração de gráficos |
| `PMU_PLOT_PYTHON` | auto | caminho do Python usado para os gráficos |

## Estrutura

```
Matilab/                  referência MATLAB (source of truth)
PMU_padrao/Software/      PMU_padrao.cmm (C±) e .asm gerado
PMU_padrao/Hardware/      Verilog e imagens de memória gerados pelo yanc
PMU_padrao/Simulation/    resultados TXT, gráficos, xcheck_tb.v, baseline
pmu_cocotb.py             testbench cocotb (estímulo, ADC emulado, análise)
plot_results.py           gráficos matplotlib a partir de pmu_results.txt
docs/                     diagrama didático do ciclo do processador
proj_PMU_padrao.spf       projeto AURORA
```
