clc;clear;close all;
%% HRV Principal
%{
- Filtros adecuados para ECG
- Algoritmo de detección de picos R
- Interpolación de la señal a una frecuencia determinada (e.g. 1Hz)
- Extracción de caracteristicas espectrales: Energía del espectro de potencia en VLF(0.01-0.05 Hz), LF(0.05-0.2
Hz), HF(0.2-0.4 Hz), LF/HF, Entropía del espectro, Detrented Fluctuation,
Lyapunov mean and max exponents
%}
clc;
load('100m.mat');
fs = 360;
[qrs_amp_raw,qrs_i_raw,delay]=pan_tompkin(val,fs,0);
% Obtención de la serie de intervalos RR consecutivos
hrv = diff(qrs_i_raw/fs);
% Preprocesamiento:Criterio para eliminar intervalos RR anormales 
%{
Si se desvia más del 20% con respecto a la media de los intervalos RR
anteriores, remuevalo.
Esto puede eliminar latidos ectopicos que se presenten.

%}
hrv_new = hrv;
i = 1;% contador indice
cont = 0;% contador de rr eliminados
while i < length(hrv)-cont
    if i > 1
        mu = mean(hrv_new(1:i-1));% calcule la media de los precedentes
        disp(i)
        if hrv_new(i) > 1.2*mu
            hrv_new(i) = [];% remueva el elemento
            cont = cont+1;
        else
            i = i+1;% incremente si no lo elimino
        end
    else
        i = i+1;
    end
end
% Medidas temporales
%{
SDNN
RMSSD: se han propuesto periodos ultra cortos de 10, 30, 60 s

%}
% SDNN (puede hacerse en periodos cortos de 60 a 240 s)
sdnn= 0;rmssd = 0;pNN50 = 0;
for rr = 1:length(hrv_new)
    sdnn = sdnn + ( (hrv_new(rr) - mean(hrv_new)) )^2;
    if rr < length(hrv_new)-1
        rmssd = rmssd + (hrv_new(rr+1) - hrv_new(rr) )^2 ;
        %pNN50: aquellos intervalos que difieran de más de 50ms (se puede hacer en segmentos de 2 min minimo)
        % se han propuesto intevalos de 60 s.
        diff = hrv_new(rr+1) - hrv_new(rr);
        if diff > 0.05
            pNN50 = pNN50 + 1;
        end
    end    
end
sdnn = sqrt( sdnn/(length(hrv_new)-1) );
rmssd = sqrt( rmssd/(length(hrv_new)-1) );
pNN50 = pNN50/length(hrv_new)*100;
% SDANN (cada 5 minutos)


% geometricas
% indice triangular: integral de la función de densidad de probabilidad dividida por el
% máximo de la distribución. total de NN/numero de intervalos NN en el bin
% modal, siendo independiente de la longitud del bin
% TINN: 

% RMSSD

% histograma: 



% figure;plot(hrv);
% figure;plot(hrv_new);
%% PSD de la HRV
clc;clear;close all;

load('100m.mat');
fs = 360;
win_types = {'Hanning','Hamming','Hann','Blackmann-Harris','Barlett','Kaiser'};

n_val = [512,1024,2048];
n_over = [0.25,0.5,0.75];

for i = 1:length(n_val)
%     n = n_val(i);
    n = 4096;
    figure('Name',['Ventana de ' num2str(n_over(i)) ],'NumberTitle','off')
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

        psd_over = length(psd_win)*n_over(i);
        p = nextpow2(length(val));nfft = 2^p;

        [m_Pxx, v_w] = pwelch(val(1,1:100*fs), psd_win,psd_over,nfft,fs);
        
        subplot(3,2,win);
        plot(v_w,10*log(m_Pxx+1));
        title(['Ventanta tipo ' win_types{win}]);
        xlabel('Frecuencia (Hz)');ylabel('Potencia (dB/Hz)');
        grid on;
    end
end
%% Potencias relativas mediante areas con trapz
win_size = 10*fs;
win_over = win_size*0.75;
% Frecuenciales
n_val = 1024;n_over = 0.75;
psd_win = hanning(n_val);
psd_over = length(psd_win)*n_over;
p = nextpow2(length(val));nfft = 2^p;% número de puntos sobre el que calcula la fft
freqLim = [0,1];% rango de frecuencias

[m_totalpower, m_powHF, m_powLF, m_powVLF, m_powULF]...
    = ...
    f_HRV_FreqFeats(ecg',win_size, win_over,...
                                    psd_win, psd_over,nfft, fs,freqLim);
%% Interpolation for evenly samples
fs_hrv = 10;
t = (0:length(qrs_i_raw)-1)/fs_hrv;
t2 = (0:length(ecg)-1)/fs;
y=interp1(t,hrv_new,t2,'spline')'; %cubic spline interpolation

figure;plot(y)

%% 
% [pxx,f] = pburg(___,fs)
pburg(y,32,512*2,10);
%% Lomb-Scargle Method -> No requiere resampling
maxF = 0.5;nfft = 512;
%Calculate PSD
deltaF=maxF/nfft;
F = linspace(0.0,maxF-deltaF,nfft);
figure;plomb(hrv_new,t,0.5); %calc lomb psd


