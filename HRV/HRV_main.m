clc;clear;close all;
%% HRV Principal
%{
- Filtros adecuados para ECG
- Algoritmo de detecciÃ³n de picos R
- InterpolaciÃ³n de la seÃ±al a una frecuencia determinada (e.g. 1Hz)
- ExtracciÃ³n de caracteristicas espectrales: EnergÃ­a del espectro de potencia en VLF(0.01-0.05 Hz), LF(0.05-0.2
Hz), HF(0.2-0.4 Hz), LF/HF, EntropÃ­a del espectro, Detrented Fluctuation,
Lyapunov mean and max exponents
%}
clc;
load('100m.mat');
% *** Caracteristicas de la se�al ***
fs = 360;
fs_hrv = 1;
t = (0:length(val)-1)/fs;
[qrs_amp_raw,qrs_i_raw,delay]=pan_tompkin(val,fs,0);
v_t = qrs_i_raw/fs;v_test = v_t;
v_t = v_t(1:end-1);% vector de tiempo de la señal de RR
% desplazo el vector de tiempo la mitad de la duración del intervalo
% es decir, cada muestra está ubicada a la mitad del intervalo
v_thalf = diff(v_test);v_thalf = v_thalf/2;
v_tshift = v_t+v_thalf;
% NOTA:
%{
Cada instante donde sucede el RR se toma como el tiempo donde está el
primer pico RR del intervalo respectivo.
%}
%% **** Extracción de la señal de HRV a partir de la señal de ECG *****

hrv = diff(qrs_i_raw/fs);% Obtencion de la serie de intervalos RR consecutivos ( en segundos)
% 1. Preprocesamiento:Criterio para eliminar intervalos RR anormales 
%{
Si se desvia mÃ¡s del 20% con respecto a la media de los intervalos RR
anteriores, remuevalo.
Esto puede eliminar latidos ectopicos que se presenten.
-Remover la media
%}
[hrv_no_ect,v_tfin] = removeEctBeats(hrv,v_tshift);
hrv_clean = hrv_no_ect-mean(hrv_no_ect);
%***grafica***
figure;
subplot(3,1,1);plot(hrv);title('Señal de RR cruda');
subplot(3,1,2);plot(hrv_no_ect);title('Señal RR sin látidos ectopicos');
subplot(3,1,3);plot(hrv_clean);title('Señal RR sin la media');
%% 2. Interpolation for unevenly samples
clc;close all;
interp = {'pchip','makima'};
for i = 1:length(interp)
    t_int = 0:1/fs:(length(val)-1)/fs;% vector de tiempo query 
    hrv_int = interp1(v_tfin,hrv_no_ect,t_int,interp{i});% señal interpolada
    %grafica
    figure;
    subplot(2,1,1);plot(v_tfin,hrv_no_ect,'o',t_int,hrv_int,'.');grid on;
    title(interp{i});
    subplot(2,1,2);plot(t,val);grid on;
end
% makima es el que mejor se comporta con cubic
%%
clc;
n_over = 0;
nx = length(hrv_int);na = 16;
psd_win = hanning(floor(nx/na));
psd_over = round(length(psd_win)*n_over);
p = nextpow2(length(hrv_int));nfft = 2^p;% nÃºmero de puntos sobre el que calcula la fft
[m_Pxx, v_w] = pwelch(hrv_int,psd_win,psd_over,nfft,fs_hrv);
figure;
plot(v_w,10*log(m_Pxx+1));
title('Ventanta tipo hanning');
xlabel('Frecuencia (Hz)');ylabel('Potencia (dB/Hz)');
xlim([0 0.1]);
grid on;
%% PSD de la HRV
% clc;clear;
close all;

win_types = {'Hanning','Hamming','Hann','Blackmann-Harris','Barlett','Kaiser'};
nx = length(hrv_int);
na = 2.^(0:5);% numero de veces que se promedia el espectro
n_val = floor(nx./na);
n_over = [0.25,0.5,0.75];

for i = 1:length(n_val)
    n = n_val(i);
%     figure('Name',['Ventana de ' num2str(n_over(i)) ],'NumberTitle','off')
    figure('Name',['Promedio de ' num2str(na(i)) ],'NumberTitle','off')
    for win = 1:length(win_types)
        switch win
            case 1
                psd_win = hanning(n);
            case 2
                psd_win = hamming(n);
            case 3
                psd_win = blackman(n);
            case 4
                psd_win = bartlett(n);
            case 5
                psd_win = kaiser(n);
        end

        psd_over = length(psd_win)*n_over(1);
        p = nextpow2(length(hrv_int));nfft = 2^p;

        [m_Pxx, v_w] = pwelch(hrv_int, psd_win,psd_over,nfft,fs_hrv);
        
        subplot(3,2,win);
        plot(v_w,10*log(m_Pxx+1));
        title(['Ventanta tipo ' win_types{win}]);
        xlabel('Frecuencia (Hz)');ylabel('Potencia (dB/Hz)');
        xlim([0 0.5]);
        ylim([0 10]);
        grid on;
    end
end
%% Medidas temporales

% SDANN (cada 5 minutos)
% SDNN (puede hacerse en periodos cortos de 60 a 240 s)
% rmssd: 10, 30, 60 s
sdnn= 0;rmssd = 0;pNN50 = 0;
for rr = 1:length(hrv_clean)
    sdnn = sdnn + ( (hrv_clean(rr) - mean(hrv_clean)) )^2;
    if rr < length(hrv_clean)-1
        rmssd = rmssd + (hrv_clean(rr+1) - hrv_clean(rr) )^2 ;
        %pNN50: aquellos intervalos que difieran de más de 50ms (se puede hacer en segmentos de 2 min minimo)
        % se han propuesto intevalos de 60 s.
        diff = hrv_clean(rr+1) - hrv_clean(rr);
        if diff > 0.05
            pNN50 = pNN50 + 1;
        end
    end    
end
sdnn = sqrt( sdnn/(length(hrv_clean)-1) );
rmssd = sqrt( rmssd/(length(hrv_clean)-1) );
pNN50 = pNN50/length(hrv_clean)*100;

% geometricas
% indice triangular: integral de la funciÃ³n de densidad de probabilidad dividida por el
% mÃ¡ximo de la distribuciÃ³n. total de NN/numero de intervalos NN en el bin
% modal, siendo independiente de la longitud del bin
% TINN: 

% RMSSD

% histograma: 

% figure;plot(hrv);
% figure;plot(hrv_new);
%%
% Temporales
m_HRV = hrv_int;s_winsize = fs*30;s_winoverlap = 0;
 [v_SDNN,v_RMSSD,v_pNN50] = f_HRV_TempFeats(m_HRV,s_winsize, s_winoverlap);
 % Frecuenciales
 

%% Medidas frecuenciales
clc;
win_size = 30*fs;
win_over = 0;
% Frecuenciales
n_over = 0;
nx = length(hrv_int);na = 16;
psd_win = hanning(floor(nx/na));
psd_over = round(length(psd_win)*n_over);
p = nextpow2(length(hrv_int));nfft = 2^p;% nÃºmero de puntos sobre el que calcula la fft
freqLim = [0,0.5];

[m_totalpower, m_powHF, m_powLF, m_powVLF, m_powULF]...
    = ...
    f_HRV_FreqFeats(hrv_int',win_size, win_over,...
                                    psd_win, psd_over,nfft, fs,freqLim);
                                
[m_Pxx, v_w] = pwelch(hrv_int',psd_win,psd_over,nfft,fs_hrv);
figure;
plot(v_w,10*log(m_Pxx+1));
title('Ventanta tipo hanning');
xlabel('Frecuencia (Hz)');ylabel('Potencia (dB/Hz)');
xlim([0 0.1]);
grid on;

%%