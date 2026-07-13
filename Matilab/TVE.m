function TVE = TVE(x1, x2)
    % TVE - Calculates the Total Vector Error between two complex signals
    % Inputs:
    %   x1 - First complex signal (estimated)
    %   x2 - Second complex signal (reference)
    % Output:
    %   TVE - Total Vector Error (%)
    
    % Make sure both vectors have the same length
    if length(x1) > length(x2)
        x1 = x1(1:length(x2));
    else
        x2 = x2(1:length(x1));
    end
    
    % Calculate TVE
    real_diff = real(x1) - real(x2);
    imag_diff = imag(x1) - imag(x2);
    denominator = real(x2).^2 + imag(x2).^2;
    
    TVE = 100 * sqrt( (real_diff.^2 + imag_diff.^2) ./ denominator );
end