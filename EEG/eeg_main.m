clc;clear;close all;
%% EEG principal
% En este script se busca realizar todo el preprocesamiento (filtrado), extracciÃ³n de caracteristicas y validaciÃ³n de un
% modelo de Machine learning determinado.
% TambiÃ©n se busca la mejor ventana, nÃºmero de puntos, sobrelape, para realizar la PSD de manera adecuada.

%{
Preprocesamiento: Filtrado con WT y elecciÃ³n de la mejor WT.
ReducciÃ³n de la dimensionalidad: PCA e ICA para escoger los canales.
ExtracciÃ³n de caracteristicas: Temporales y frecuenciales
OrganizaciÃ³n de la tabla de entrenamiento
Entrenamiento del modelo

%}
clc;
names = {'03_edfm.mat','04_edfm.mat','15_edfm.mat','16_edfm.mat'};
annot = {[766976,777216],[375552,382464],[443392, 453632],[259840,272896]};
for name = 4:4
    load(['chb01_' names{name}]);
    [chan,len] = size(val);
    % Genere la seÃ±al de etiqueta
    dummy = zeros(len,1);
    dummy(annot{name}(1):annot{name}(2)-1,1) = 1;
    %ParÃ¡metros de la seÃ±al 
    fs = 256;
    % ParÃ¡metros del filtrado wavelet
    wave = 'dmey';% MW
    thr = [963.6,2211.642,0.013,0.006,0.008];% Umbrales determinados con la toolbox
    level = 5;% niveles de descomposiciÃ³n
    % ParÃ¡metros de la extracciÃ³n de caracterÃ­sticas
    win_size = 10*fs;
    win_over = win_size*0.75;
    % Frecuenciales
    n_val = 1024;n_over = 0.75;
    psd_win = hanning(n_val);
    psd_over = length(psd_win)*n_over;
    p = nextpow2(length(val));nfft = 2^p;% nÃºmero de puntos sobre el que calcula la fft
    freqLim = [0,100];% rango de frecuencias
    % *** Filtrado wavelet***
    m_eeg = WaveletDenoising(val',wave,thr,level,fs,0);
    disp('Acabe de filtrar')
    seg_eeg = m_eeg(annot{name}(1) - 60*fs:annot{name}(2) + 60*fs,:);
    seg_dummy = dummy(annot{name}(1) - 60*fs:annot{name}(2) + 60*fs,:);
    % *** ExtracciÃ³n de caracteristicas ***
    bands = {'Ruido','\gamma (25-100 Hz)','\beta (14-35 Hz)','\alpha (8-14 Hz)','\theta (4-8 Hz)','\delta (0.5-4 Hz)'};%Para cada canal
    feats = {'Pot_total', 'delta', 'theta', 'alpha', 'beta', ' low_gamma','Freq_media','Media','STD','Skew','Kurt','Act','Mob','Compl','FD','Class'};

    % Frecuenciales
    [m_totalpower, m_powdelta, m_powtheta, m_powalpha, m_powbeta,...
        m_powlowgamma, m_freqhalfpower] = ...
        f_EEG_FreqFeats(seg_eeg,win_size, win_over,...
                                        psd_win, psd_over,nfft, fs,freqLim);

    % Temporales
    [m_mu, m_sigma, m_sk, m_kurt, m_act, m_mob, m_comp, m_FD,v_label] = ...
        f_EEG_TempFeats(seg_eeg, win_size, win_over,seg_dummy);
    % repita la etiqueta
    v_labelFin = [];
    for i =1:chan
        v_labelFin = [v_labelFin; v_label];
    end

    % ColocaciÃ³n en una tabla
    % Matriz de caracteristicas
    m_Feats = zeros(size(m_mu,1) * size(m_mu,2) , length(feats) );
    
    m_Feats(:,1) = m_totalpower(:);
    m_Feats(:,2) = m_powdelta(:);
    m_Feats(:,3) = m_powtheta(:);
    m_Feats(:,4) = m_powalpha(:);
    m_Feats(:,5) = m_powbeta(:);
    m_Feats(:,6) = m_powlowgamma(:);
    m_Feats(:,7) = m_freqhalfpower(:);
    m_Feats(:,8) = m_mu(:);
    m_Feats(:,9) = m_sigma(:);
    m_Feats(:,10) = m_sk(:);
    m_Feats(:,11) = m_kurt(:);
    m_Feats(:,12) = m_act(:);
    m_Feats(:,13) = m_mob(:);
    m_Feats(:,14) = m_comp(:);
    m_Feats(:,15) = m_FD(:);
    m_Feats(:,16) = v_labelFin;
    % Preprocesamiento (imputaciÃ³n, outliers, normalizaciÃ³n/estandarizaciÃ³n)
    outliers = isoutlier(m_Feats,'median'); % detecta los outliers
    m_FeatsNoOut = filloutliers(m_Feats, 'clip','mean');% reemplaza los outliers (Clamp method)
    m_FeatsNorm = m_FeatsNoOut;
    m_FeatsNorm(:,1:end-1) = normalize(m_FeatsNoOut(:,1:end-1),'standarize');% normaliza las variables numÃ©ricas
    if name == 1
        Tfin = m_FeatsNorm;
    else
        Tfin = vertcat(Tfin,m_FeatsNorm);
    end
    
    
end
% Convierta en una tabla (entrada la modelo de entrenamiento
T = table;
for i = 1:length(feats)
    temp = table(Tfin(:,i));temp.Properties.VariableNames = {feats{i}};
    T = [T temp];
end
%% Prediga sobre otros datos
yfit = trainedModel2.predictFcn(T(4072:end,1:end-1));% Ingrese las variables requeridas
% Verifique la precisiÃ³n
cont = 0;
for i = 1:length(yfit)
    if v_labelFin(i,1) == yfit(i,1)
        cont = cont+1;
    end
end

%% Prueba PSD para EEG (escogencia de la mejor ventana, sobrelape y nÃºmero de puntos)
%{
Tipo de ventana
- Mainlobe width: ResoluciÃ³n
- Sidelobe heigth: Rango dinÃ¡mico
Longitud de la ventana
- 
Sobrelape
- 
NÃºmero de puntos para la fft
- 

%}

clc;clear;close all;
load('chb01_03_edfm.mat');
val = val(1,:);
fs = 256;
win_types = {'Hanning','Hamming','Hann','Blackmann-Harris','Barlett','Kaiser'};
nx = length(val);
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
        p = nextpow2(length(val));nfft = 2^p;

        [m_Pxx, v_w] = pwelch(val, psd_win,psd_over,nfft,fs);
        
        subplot(3,2,win);
        plot(v_w,10*log(m_Pxx+1));
        title(['Ventanta tipo ' win_types{win}]);
        xlabel('Frecuencia (Hz)');ylabel('Potencia (dB/Hz)');
        grid on;
    end
end
%% PCA
%{
- Calcular la media de cada variable. Centrar los datos con respecto a dicha media.
- Calcular la regresiÃ³n lineal para el conjunto de datos. Se encuentra la
linea que minimiza la distancia hasta los puntos o maximizar la distancia
de las proyecciones de los puntos en la linea hasta el origen.
- 

%}

                                
                                
