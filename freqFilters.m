%% Filtros frecuenciales básicos
%% Notch con FIR
clc;
fs = 256;fnyq = fs/2;
order = 80;
window = hanning(order+1);% Hanning el mejor entre blackman, hanning , hamming, hann
c = fir1(order,[55 65]/fnyq,'stop',window);
figure();freqz(c,1,1024,fs);
%% Variación de la línea de base con IIR (2 etapas) - Pasabandas
n = 16;
%% Butterworth
Wp = 30/fnyq ;Ws = 2;Rp = 2;Rs=3;
[n,Wn] = buttord(Wp,Ws,Rp,Rs);
[b1,a1] = butter(n,Wn,ftype);
%% Chebyshev Tipo I y Tipo II
[n,Wp] = cheb1ord(Wp,Ws,Rp,Rs); 
[b2,a2] = cheby1(n,Rp,Wp,ftype);
%%
[n,Wp] = cheb2ord(Wp,Ws,Rp,Rs);
[b3,a3] = cheby2(n,Rp,Wp,ftype);

%% Eliptico
[n,Wp] = ellipord(Wp,Ws,Rp,Rs);
