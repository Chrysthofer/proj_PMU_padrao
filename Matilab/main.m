clear all
close all
clc


% Assuming signal_frequency, EstimadorPhasor, and TVE functions are defined elsewhere
A = 1;
f1 = 60 + (2);
N = 16*100;
f0 = 60;
Fs = 960;
Fs = 1920;
Frep = 60;
Fn =60
Fr = Frep
w0 = filtro_classM(Fs, Fn, Fr);
w1 = [22, -67, -58, 0, 58, 67, -22] * 1/252; % filtro SAVITZKY GOLAY
AA =2
CLOCK2 = 1/(1920*AA);


[x, X, f, ROCOF] = signal_frequency(A, f1, N, f0, Fs, Frep); 
[Xe, fe, ROCOFe] = PMU_padrao(Fs, f0, Frep, x);
TVEe = TVE(Xe, X);

% Create figure with subplots
figure;
set(gcf, 'Position', [100, 100, 900, 1200]);

% Subplot 1: Generated signal
subplot(6,1,1);
plot(x, 'b', 'LineWidth', 1);
title('Sinal gerado / Estimado');
ylabel('Wave');
xlim([200 800]);
grid on;

% Subplot 2: Amplitude X
subplot(6,1,2);
plot(abs(X), 'r--', 'LineWidth', 1);
hold on;
plot(abs(Xe), 'b', 'LineWidth', 1);
title('Amplitude X');
legend('Real', 'Estimado', 'Location', 'best');
grid on;

% Subplot 3: Phase X
subplot(6,1,3);
plot(angle(Xe)*180/pi, 'b', 'LineWidth', 1);
hold on;
plot(angle(X)*180/pi, 'r--', 'LineWidth', 1);
title('Fase X');
legend('Estimado', 'Real', 'Location', 'best');
grid on;

% Subplot 4: Frequency
subplot(6,1,4);
plot(f, 'r', 'LineWidth', 1);
hold on;
plot(fe, 'b--', 'LineWidth', 1);
title('Frequência');
legend('Real', 'Estimado', 'Location', 'best');
grid on;

% Subplot 5: ROCOF
subplot(6,1,5);
plot(ROCOF, 'r--', 'LineWidth', 1);
hold on;
plot(ROCOFe, 'b', 'LineWidth', 1);
title('ROCOF');
legend('Real', 'Estimado', 'Location', 'best');
grid on;

% Subplot 6: TVE %
subplot(6,1,6);
plot(ones(size(X)), 'r--', 'LineWidth', 1);
hold on;
plot(TVEe, 'b', 'LineWidth', 1);
title('TVE %');
xlabel('Amostra (n)');
ylabel('TVE %');
ylim([0 5]);
legend('Referência', 'TVE', 'Location', 'best');
grid on;

% Main title
sgtitle('Análise de Sinal e Estimativas');




