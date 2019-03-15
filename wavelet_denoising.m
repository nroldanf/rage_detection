% Wavelet Denoising practice
%% Wavelet Families
waveletfamilies('f');% Familias wavelet disponibles
waveletfamilies('a');% Todas las wavelet madre por cada familia
waveinfo('db');% Mother wavelet info
% Start the toolbox window to analyze mother wavelets (decomposition and
% reconstruction)
% waveletAnalyzer

%% Wavelet filters
seg = val(1,(256*0)+1:(256*120));
cw1 = cwt(seg,1:2048,'db2','plot');
title('Continuous Transform, absolute coefficients.') 
ylabel('Scale')
[cw1,sc] = cwt(seg,1:2048,'db2','scal');
title('Scalogram') 
ylabel('Scale')
colormap jet;
%% 
close all;
clc;
[XD,CXD,LXD] = wden(seg,'rigrsure','h','one',3,'db2');

plotting(1,fs,0,100,0,50,seg,'ruido')
plotting(1,fs,0,100,0,50,XD,'sin ruido')
%% EEG decomposition into bands (Wavelet)
%{
    Delta (0.5-4 Hz) 
    Theta (4-8 Hz)
    Alpha (8-14 Hz)
    Beta (14-35 Hz)
    Gamma (25-100 Hz)
    Noise ()
    
    Tasks:
    - Determine the ideal wavelet mother for EEG (Cross-corelation with
    the mother wavelet and decomposition and reconstruction with the
    smallest error
    - 

%}
close all;
sig = load('chb01_01_edfm.mat');sig = sig.val;
fs = 256;
wave = 'db4';
bands = {'Noise','Gamma','Beta','Alpha','Thetha','Delta'};
thr = [963.6,2211.642,0.013,0.006,0.008];

% Decomposition
[c0,l0] = wavedec(sig,5,wave);
D = zeros(6,length(sig));
A = [];
% Reconstruction and plotting (time and frequency)
for i = 1:5
    if i == 5
        D(i,:) = wrcoef('d',c0,l0,wave,i);
        D(i,:) = wthresh(D(i,:),'s',thr(i));
        D(i+1,:) = wrcoef('a',c0,l0,wave,i);
    else
        D(i,:) = wrcoef('d',c0,l0,wave,i);
        D(i,:) = wthresh(D(i,:),'s',thr(i));
    end
end


for i = 1:6
    plotting(i,fs,0,100,0,fs/2,D,bands{i})
end

% D(1,:) = zeros();
sig_fin = zeros();
for i = 1:6
    sig_fin = sig_fin+D(i,:);
end

% Check for perfect reconstruction. 
err = sig_fin-sig;

plotting(1,fs,0,100,0,fs/2,sig,'Con ruido');
plotting(1,fs,0,100,0,fs/2,sig_fin,'Sin ruido');


% plotting(1,fs,0,100,0,fs/2,A,'apro')

%% HRV filtering


%% GSR filtering
% Wavelet
close all;
sig = load('drive01_handGSR.mat');
fs = 41;
[XD,CXD,LXD] = wden(sig.val,'rigrsure','h','one',3,'db4');

plotting(1,fs,0,(length(sig.val)-1)/fs,0,fs/2,sig.val,'GSR sin filtrar');
plotting(1,fs,0,(length(sig.val)-1)/fs,0,fs/2,XD,'GSR filtrada');
plotting(1,fs,0,(length(sig.val)-1)/fs,0,fs/2,sig.val-XD,'Residuos');

[sig_o] = baseline_filter(sig.val,fs);

plotting(1,fs,0,(length(sig_o)-1)/fs,0,fs/2,sig_o,'Sin linea de base');
sig.val = sig.val/mean(sig.val);
plotting(1,fs,0,(length(sig.val)-1)/fs,0,fs/2,sig.val,'GSR sin filtrar');
%% Ventaneo con sobrelapado
len = length(D);
win = fs*1;
act = zeros();mob = zeros();com = zeros();
%para un solo canal (len/win ventanas)
ind = 1;
for k = 1:win/2:(len - (win/2+1))
    [act(ind),mob(ind),com(ind)] = hjorth(D(1,k:k+win/2+1));
%     FD(ind) = hfd(eeg_sig(1,k:k+win/2+1));
    ind = ind+1;
end
%% PSD por método de Welch
%{
Ventanas acorde a la señal a analizar:
    - Anchura Main lobes y side lobes de respuesta en frecuencia
    - Sobrelapado
    - Número de puntos sobre el que se realiza la fft
    - 
%}
fs = 41;
w = blackman(fs*4);
p = nextpow2(length(sig(1,10*fs:100*fs)));n = 2^p;
pxx = pwelch(sig(1,10*fs:100*fs),w,length(w)/2,n);
f = linspace(0,fs/2,length(pxx));

figure();
plot(f,10*log(pxx+1));
grid on;
%% Potencia relativa por banda
