function plotting(derv,s_fs,t_inf,t_sup,f_inf,f_sup,sig,name)
time = t_inf : 1/s_fs : t_sup; %En pasos del periodo de muestreo
sig_segment = sig(derv,(t_inf*s_fs)+1 : (t_sup*s_fs)+1);%De la muestra en el tiempo t_inf hasta la muestra de t_sup
% figure;
% plot(time,sig_segment);title(name);xlabel('Tiempo (s)');ylabel('Amplitud (mV)');grid on;
%
p = nextpow2(length(sig_segment));
n = 2^p;
sig_freq = fft(sig_segment,n);
sig_freq (end/2:end) = [];
sig_freq = abs(sig_freq);
%freq = linspace(0,s_fs/2,length(sig_segment));
freq = 0:(s_fs/2)/((( t_sup - t_inf )* (s_fs/2))-1):(s_fs/2)/((( t_sup - t_inf )* (s_fs/2))-1)*(length(sig_freq)-1);
% figure;
% plot(freq,sig_freq);title('FFT');xlabel('Frecuencia (Hz)');ylabel('Amplitud');grid on;xlim([f_inf,f_sup]);

figure;
subplot(2,1,1);
plot(time,sig_segment);title(name);xlabel('Tiempo (s)');ylabel('Amplitud (mV)');grid on;
subplot(2,1,2)
plot(freq,sig_freq);title('FFT');xlabel('Frecuencia (Hz)');ylabel('Amplitud');grid on;xlim([f_inf,f_sup]);

end
