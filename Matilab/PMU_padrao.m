function [Xe, fe, ROCOF] = PMU_padrao(Fs, Fn, Fr, x)
    % Fs    - Frequencia de amostragem [float]
    % Fn    - Frequencia nominal [float]
    % Fr    - Frequencia de reporte [float]
    % x     - Sinal [array]

    % y     - Fasor estimado sem correção
    % yfase - Estimação de frequencia (devio de frequencia)
    % Pha   - Fasor estimado Corrigido

    % Demodulação ------------------------------------
    yr = zeros(size(x));
    yi = zeros(size(x));
    for i = 1:length(x)
        yr(i) = x(i) * cos(2*pi*(i-1)*1/Fs*Fn);
        yi(i) = x(i) * sin(2*pi*(i-1)*1/Fs*Fn);
    end

    % Filtro Classe M ---------------------------------
    w0 = filtro_classM(Fs, Fn, Fr);  % Calcula o filtro

    y_r = filter(w0, 1.0, yr);
    y_i = filter(w0, 1.0, yi);

    y = y_r - 1j * y_i;

    % FREQUENCIA -------------------------------------
    yf = unwrap(angle(y));
    % Por Derivada
    if true
        fe = diff(Fs/(2*pi)*yf) + Fn;
    end
    % Por Filtro SAVITZKY GOLAY
    if false
        w1 = [22, -67, -58, 0, 58, 67, -22] * 1/252; % filtro SAVITZKY GOLAY
        fe = filter(w1, 1.0, Fs/(2*pi)*yf) + Fn;
    end

    % ROCOF ------------------------------------------
    ROCOF = diff(fe);

    % Correção do fasor
    start_idx = floor(length(w0)/2);
    Xe = y(start_idx:end);
    fe = fe(start_idx:end);
    ROCOF = ROCOF(start_idx:end);
end