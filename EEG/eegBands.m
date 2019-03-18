function [m_delta,m_theta,m_alpha,m_beta,m_gamma,m_noise] = eegBands(m_EEG,wave,fs)
% EEG decomposition into bands (Wavelet)
% Function that plots each subband (in time and frequency) given a mother wavelet for 5 levels of decomposition (5 detailed coefficients
% and 1 aproximation coefficient.)
%{
    Delta (0-4 Hz) - D1
    Theta (4-8 Hz) - D2
    Alpha (8-16 Hz) - D3
    Beta (16-32 Hz) - D4
    Gamma (32-64 Hz) - D5
    High Gamma and noise (64-128 Hz) - A5
%}
% Dimensions
s_chan = size(m_EEG,2);% número de canales
s_len = size(m_EEG,1);% número de muestras
% Iniacialización de las matrices
m_delta = zeros(s_len,s_chan);
m_theta = zeros(s_len,s_chan);
m_alpha = zeros(s_len,s_chan);
m_beta = zeros(s_len,s_chan);
m_gamma = zeros(s_len,s_chan);
m_noise = zeros(s_len,s_chan);
% Time and frequency vectors
t = (0:s_len-1)/fs;
f = linspace(0,fs/2,length(fftMag(m_EEG(:,1))));
% Variables de la wavelet
%wave = 'dmey';% Wavelet madre
% bands = {'Noise','Gamma','Beta','Alpha','Thetha','Delta'};% bandas
bands = {'Ruido','\gamma (25-100 Hz)','\beta (14-35 Hz)','\alpha (8-14 Hz)','\theta (4-8 Hz)','\delta (0.5-4 Hz)'};
% Decomposition for each channel
for chan = 1:s_chan
    [c0,l0] = wavedec(m_EEG(:,chan),6,wave);
    % Reconstruction and plotting (time and frequency)
    figure;
    for i = 1:6
        switch i
            case 1
                m_noise(:,chan) = wrcoef('d',c0,l0,wave,i);
                %tiempo
                subplot(6,2,i);
                plot(t,m_noise(:,chan));grid on;
                xlabel('Tiempo');ylabel('\mu V');
                %frecuencia
                subplot(6,2,i+1);
                plot(f,fftMag(m_noise(:,chan)));grid on;
                title(bands{i});
            case 2
                m_gamma(:,chan) = wrcoef('d',c0,l0,wave,i);
                %tiempo
                subplot(6,2,i+1);
                plot(t,m_gamma(:,chan));grid on;
                xlabel('Tiempo');ylabel('\mu V');
                %frecuencia
                subplot(6,2,i+2);
                plot(f,fftMag(m_gamma(:,chan)));grid on;
                title(bands{i})
            case 3
                m_beta(:,chan) = wrcoef('d',c0,l0,wave,i);
                %tiempo
                subplot(6,2,i+2);
                plot(t,m_beta(:,chan));grid on;
                xlabel('Tiempo');ylabel('\mu V');
                %frecuencia
                subplot(6,2,i+3);
                plot(f,fftMag(m_beta(:,chan)));grid on;
                title(bands{i})
            case 4
                m_alpha(:,chan) = wrcoef('d',c0,l0,wave,i);
                %tiempo
                subplot(6,2,i+3);
                plot(t,m_alpha(:,chan));grid on;
                xlabel('Tiempo');ylabel('\mu V');
                %frecuencia
                subplot(6,2,i+4);
                plot(f,fftMag(m_alpha(:,chan)));grid on;
                title(bands{i})
            case 5
                m_theta(:,chan) = wrcoef('d',c0,l0,wave,i);
                %tiempo
                subplot(6,2,i+4);
                plot(t,m_theta(:,chan));grid on;
                xlabel('Tiempo');ylabel('\mu V');
                %frecuencia
                subplot(6,2,i+5);
                plot(f,fftMag(m_theta(:,chan)));grid on;
                title(bands{i})
            case 6
                m_delta(:,chan) = wrcoef('a',c0,l0,wave,i);
                %tiempo
                subplot(6,2,i+5);
                plot(t,m_delta(:,chan));grid on;
                xlabel('Tiempo');ylabel('\mu V');
                %frecuencia
                subplot(6,2,i+6);
                plot(f,fftMag(m_delta(:,chan)));grid on;
                title(bands{i})
        end
    end
end
end


