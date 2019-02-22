function filtered = combFilter(fc,sig)
%frecuencia fundamental
wc = zeros();
for k=1:2:5
    wc(k) = k*(fc/fs1)*2*pi;
    wc(k+1) = -k*(fc/fs1)*2*pi;
end
z = exp(1i*wc);
c = poly(z);

filtered = filter(c,1,sig);

end