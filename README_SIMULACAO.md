# PMU padrão em SAPHO — simulação cocotb (fast sim)

Processador SAPHO que replica a PMU classe M do MATLAB (`Matlab/PMU_padrao.m`),
validado por um testbench cocotb que gera o estímulo e analisa as saídas em TXT.

## Como simular

Na AURORA, com este projeto aberto, use o botão **Fast Sim** (simulação headless,
sem waveform/GTKWave/Surfer — a mais rápida). A AURORA:

1. recompila `PMU_padrao/Software/PMU_padrao.cmm` → `.asm` → `Hardware/PMU_padrao.v`;
2. roda o cocotb (Icarus por padrão) com `pmu_cocotb.py` dirigindo o processador puro
   (`# aurora-toplevel: PMU_padrao`);
3. o teste escreve os resultados em `PMU_padrao/Simulation/` (caminhos absolutos,
   independentes do cwd da simulação).

Duração de referência: ~10 min para 1600 amostras no Icarus. Para uma rodada
rápida, defina a variável de ambiente `PMU_NSAMPLES` (ex.: 250) antes de abrir a
AURORA — com poucas amostras o TVE inclui o transitório do filtro e pode "falhar".

## Teste implementado

*Signal Frequency* (IEC/IEEE 60255-118), espelhando `Matlab/main.m`:
`A=1, f1=62 Hz, f0=60 Hz, Fs=1920 Hz, Fr=60, N=1600`. A fase inicial é fixa
(π/4) para reprodutibilidade — o MATLAB usa fase aleatória.

O `pmu_cocotb.py` também roda o mesmo algoritmo em `double` (porta fiel do
`PMU_padrao.m`) e reporta a diferença hardware × modelo, isolando o efeito do
float de 24 bits do SAPHO do comportamento do algoritmo.

## Escala das portas (Q20)

O `fin()` do SAPHO converte o **inteiro** de `io_in` para float (23 bits com
sinal) e o `fout()` trunca o float de volta para **inteiro** em `io_out`.
Por isso todos os valores nas portas usam ponto fixo Q20 (×2²⁰ = 1048576):

| Porta | Conteúdo | Escala |
|-------|----------|--------|
| in 0  | amostra x[n] | `round(x·2²⁰)` |
| out 0 | Re{Xe}       | `Re·2²⁰` |
| out 1 | Im{Xe}       | `Im·2²⁰` |
| out 2 | fe (Hz)      | `fe·2²⁰` |
| out 3 | ROCOF (Hz/amostra) | `ROCOF·2²⁰` |

O `.cmm` desfaz a escala na entrada (`x = fin(0) * 2^-20`) e aplica na saída.
O `#TOAQUI` pulsa o pino `cheguei` uma vez por amostra processada.

## Reset por amostra (pino `itr` + marcador `#PRACA`)

O `in()`/`fin()` do SAPHO **não espera** — lê o que estiver no barramento no
ciclo da instrução. A sincronização com o ADC é feita por um **reset quente por
amostra**, disparado por hardware:

- **`.cmm` (modelo orientado a evento)**: o `main()` constrói as LUTs/FIR **uma
  vez**, executa `return` e fica idle. O marcador `#PRACA` marca o ponto de
  reentrada por amostra. Cada pulso do pino `itr` faz o PC saltar para o
  `#PRACA`, ler **uma** amostra em `fin(0)`, emitir os 4 resultados e voltar ao
  idle. Como `#PRACA` é um restart *quente* (não zera a memória de dados nem
  reexecuta o startup), a linha de atraso do FIR de 164 taps e o estado (`wr`,
  `nsmp`, `yprev`, `feprev`) **sobrevivem** entre amostras — o que um `rst`
  global destruiria. O `#TOAQUI` continua pulsando o pino `cheguei` ("result
  ready") uma vez por amostra.
- **Wrapper (FPGA / testbench)**: a cada strobe do ADC, registra a amostra
  (ligada à porta 0) e **pulsa o `itr`**. Na FPGA o `itr` é um pino de hardware
  real, dirigido pelo front-end do ADC — por isso é, de fato, um reset de
  hardware disparado externamente, só que do tipo que preserva o estado.

No cocotb o strobe é emulado com período `PMU_STROBE_CLKS` (default 6000 clocks;
o caso real 100 MHz / 1920 Hz seria 52083 — resultados idênticos, simulação ~9×
mais lenta). O `itr` fica baixo durante um **hold-off de startup**
(`PMU_STARTUP_CLKS`, default 40000) para não abortar o build único das LUTs/FIR.
O testbench conta **overruns** (novo strobe antes de a amostra anterior
terminar) e falha se houver algum. O cross-check em Verilog puro
(`PMU_padrao/Simulation/xcheck_tb.v`) faz o mesmo, dirigindo `itr` diretamente.

Custo de processamento medido: ~4,6 mil ciclos por amostra → clock mínimo para
tempo real a 1920 Hz ≈ **8,8 MHz**. A 100 MHz o processador fica ~91 % do
período em idle aguardando o próximo `itr`.

## Arquivos de saída (`PMU_padrao/Simulation/`)

- `input_0.txt` — amostras Q20 enviadas (mesmo formato do fluxo Verilog-tb da AURORA);
- `output_0.txt` … `output_3.txt` — inteiros Q20 crus emitidos pelo processador;
- `pmu_results.txt` — tabela por amostra em unidades reais: `n, x, Re, Im, |Xe|,
  fase(°), fe, ROCOF, TVE%` (TVE contra `X[n-82]`, compensando o atraso de grupo
  do FIR de 164 taps);
- `pmu_report.txt` — resumo: TVE/FE/ROCOF máx/médio em regime (janela [400,1600)),
  PASS/FAIL e a comparação hardware × modelo double.

## Critérios de aprovação (janela de regime [400, 1600))

O objetivo é **replicar o algoritmo MATLAB**, então os critérios principais
comparam o hardware com o mesmo algoritmo em double:

- TVE máx < 1,2 % contra a verdade analítica (o próprio algoritmo MATLAB fica
  em ~0,98 % com f1 = 62 Hz, por vazamento da imagem em −122 Hz);
- viés de frequência |média(fe − f1)| < 0,01 Hz;
- fidelidade ao modelo double: |ΔRe|, |ΔIm| < 1e-4; |Δfe| < 0,01 Hz;
  |ΔROCOF| < 0,01.

O |FE| máximo instantâneo (~0,18 Hz) é ripple intrínseco do algoritmo de
referência (derivada da fase amostra a amostra, sem suavização) — aparece
idêntico no modelo double e **não** é erro do processador.

Resultado da validação (1600 amostras, Icarus): TVE máx 0,9802 % (modelo:
0,9799 %), viés de FE +0,0007 Hz, hardware × double: ΔRe 5,2e-6, Δfe 6,9e-4 Hz
— todos os critérios PASS.

## Gráficos

`python plot_results.py` (Python do sistema, precisa de plotly/numpy) lê o
`pmu_results.txt` e gera `PMU_padrao/Simulation/pmu_plots.html` — gráfico
**interativo** com os 6 painéis do `main.m` (sinal de entrada, |X|, fase,
frequência, ROCOF e TVE), abrindo no navegador. Use `--no-show` para só gerar o
arquivo.
