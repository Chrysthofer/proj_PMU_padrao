function [x, X, f, ROCOF] = signal_frequency(A, f1, N, f0, Fs, Frep)
% Gera sinais para o teste Signal Frequency segundo a norma IEC/IEEE 60255-118
% Parameters:
% -----------
%     A (float): Amplitude do sinal
%     f1 (float): Frequência do sinal
%     N (integer): Número de pontos do sinal gerado
%     f0 (float): Frequência nominal
%     Fs (float): Frequência de Amostragem
%     Frep (float): Frequência de Reporte
%
% Returns:
% --------
%     x (array): Amplitude do sinal
%     X (complex array): Frequência do sinal
%     f (array): Número de pontos do sinal gerado
%     ROCOF (array): Frequência nominal

    status = true;
    if Frep < 10
        if abs(f1-f0) > 2
            error('Frequencia do sinal fora do intervalo estipulado pela norma');
        end
    elseif Frep < 25
        if abs(f1-f0) > Frep/5
            error('Frequencia do sinal fora do intervalo estipulado pela norma');
        end
    else
        if Frep >= 25
            if abs(f1-f0) > 5
                error('Frequencia do sinal fora do intervalo estipulado pela norma');
            end
        end
    end

    if ~status
        x = 0;
        X = 0;
        f = 0;
        ROCOF = 0;
        return;
    else
        t = (0:N-1)/Fs;
        phi = -pi + 2*pi*rand();  % Random number between -pi and pi
        
        x = A*cos(2*pi*f1*t + phi);
        
        X = (A/sqrt(2))*exp(1j*(2*pi*(f1-f0)*t + phi));
        
        f = f1*ones(size(x));
        ROCOF = zeros(size(x));
    end
end