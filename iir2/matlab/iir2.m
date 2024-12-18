
format long;
fc = 1/4;    % cutoff at 1/4 Nyquist frequency

% Butterworth 2nd-order IIR low-pass filter
[b, a] = butter(2, fc);
disp('Numerator coefficients (b):');
disp(b);
disp('Denominator coefficients (a):');
disp(a);

% Impulse response
h = impz(b, a, 16);
disp('Impulse response:');
disp(h);
