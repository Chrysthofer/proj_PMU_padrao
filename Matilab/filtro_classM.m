function w = filtro_classM(Fs, Fn, Fr)
    % Fs    - Frequencia de amostragem [float]
    % Fn    - Frequencia nominal [float]
    % Fr    - Frequencia de reporte [float]

    % w     - Coeficiente filtro Classe M

    if (Fn == 50)
        if (Fr == 100)
            frep = 14.1;
            N = 66;
        elseif (Fr == 50)
            frep = 7.75;
            N = 142;
        elseif (Fr == 25)
            frep = 4.355;
            N = 338;
        elseif (Fr == 10)
            frep = 1.779;
            N = 806;
        end
    elseif (Fn == 60)
        if (Fr == 120)
            frep = 16.25;
            N = 70;
        elseif (Fr == 60)
            frep = 8.19;
            N = 164;
        elseif (Fr == 30)
            frep = 5.02;
            N = 306;
        elseif (Fr == 20)
            frep = 3.50;
            N = 502;
        elseif (Fr == 15)
            frep = 2.64;
            N = 662;
        elseif (Fr == 12)
            frep = 2.125;
            N = 816;
        elseif (Fr == 10)
            frep = 1.78;
            N = 968;
        end
    end

    w = zeros(1, N);
    for k = 0:N-1
        a = 2*pi*(2*frep/Fs)*(k-N/2);
        h = 0.54 - 0.46*cos(2*pi*(k)/(N-1));
        if (k == N/2)
            w(floor(N/2)+1) = 1;  % MATLAB uses 1-based indexing
        else
            w(k+1) = (sin(a)/a) * h;
        end
    end

    w = w * (sqrt(2)/sum(w));  % Normalização
end