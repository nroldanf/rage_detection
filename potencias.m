clc;clear;
load('chb01_02_edfm.mat');
%%
fs = 256;
[m_delta,m_theta,m_alpha,m_beta,m_gamma,m_noise] = eegBands(val(1,:)',fs);
%% por banda


%%
% PSD
fs = 256;
pow = nextpow2(size(val,2));nfft = 2^p;% número de puntos de la fft
win = hanning(fs*50);% ventana
[m_Pxx, v_w] = pwelch(val(1,:), win,length(win)*0.75,nfft,fs);% pwelch method
figure;
plot(v_w,10*log(m_Pxx+1));
title('PSD de EDA');xlabel('Frecuencia (Hz)');
grid on;

theta = sum(m_Pxx);
total = sum(m_Pxx);
theta_p =  theta/total;
%% Potencias relativas por canal
%{
    Delta (0.5-4 Hz) 
    Theta (4-8 Hz)
    Alpha (8-14 Hz)
    Beta (14-35 Hz)
    Gamma (25-100 Hz)
%}
fs = 256;
pow = nextpow2(size(val,2));nfft = 2^p;% número de puntos de la fft
win = hanning(fs*50);% ventana

bandas = [m_delta,m_theta,m_alpha,m_beta,m_gamma];
% Inicializar matrices

% m_powdelta = zeros();
% m_powtheta = zeros();
% m_powalpha = zeros();
% m_powbeta = zeros();
% m_powgamma = zeros();

%potencia total
[m_Pxx, v_w] = pwelch(val(1,:), win,length(win)*0.75,nfft,fs);% pwelch method
s_1 = find(v_w==0.5,1);
s_2 = find(v_w==100,1);

m_powtotal = sum(m_Pxx(s_1:s_2,1));

% potencia relativa delta
[m_Pxx, v_w] = pwelch(m_delta', win,length(win)*0.75,nfft,fs);% pwelch method
m_powdelta = sum(m_Pxx);
m_powdelta = m_powdelta./m_powtotal;%para todos los canales

[m_Pxx, v_w] = pwelch(m_theta', win,length(win)*0.75,nfft,fs);% pwelch method
m_powtheta = sum(m_Pxx);
m_powtheta = m_powtheta./m_powtotal;

[m_Pxx, v_w] = pwelch(m_alpha', win,length(win)*0.75,nfft,fs);% pwelch method
m_powalpha = sum(m_Pxx);
m_powalpha = m_powalpha./m_powtotal;

[m_Pxx, v_w] = pwelch(m_beta', win,length(win)*0.75,nfft,fs);% pwelch method
m_powbeta = sum(m_Pxx);
m_powbeta = m_powbeta./m_powtotal;

[m_Pxx, v_w] = pwelch(m_gamma', win,length(win)*0.75,nfft,fs);% pwelch method
m_powgamma = sum(m_Pxx);
m_powgamma = m_powgamma./m_powtotal;
