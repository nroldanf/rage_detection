function sig_freq = fftMag(sig)
p = nextpow2(length(sig));n = 2^p;
sig_freq = fft(sig,n);
sig_freq (end/2:end) = [];
sig_freq = abs(sig_freq);

end

