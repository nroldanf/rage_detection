%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function f_GSR_TempFeats
% Inputs: 
%       m_EEG: Matrix with columns as Channels and rows as samples
%       s_winsize: window size in samples
%       s_winoverlap: window overlap in samples
%       dummy: vector with the labels
% Outputs:
%       m_mu: mean of samples organized by rows for each window, and columns
%       for each channel
%       m_sigma: variance of samples
%       m_sk: skewness of samples
%       m_kurt: kurtosis
%       m_act: Hjörth activity
%       m_mob: Hjörth movility
%       m_comp: Hjörth complexity
%       m_FD: fractal dimension
%
% Author: Juan Manuel López/ Date: 2018/07
% Modified: Nicolás Roldán / Date: 2019/03
% 0.0125 Hz de paso
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [m_mu,m_sigma,m_sk,m_kurt,m_median] = f_GSR_FreqFeats(m_gsr,...
                                    s_winsize, s_winoverlap)
                                
s_length = size(m_gsr,1); % data length
s_chann = size(m_gsr,2); % number of channels

s_step = s_winsize - s_winoverlap; %step length
s_nwins = floor((s_length-s_winoverlap)/s_step); % number of windows

% variables init
m_mu = zeros(s_nwins, s_chann);
m_sigma = zeros(s_nwins, s_chann);
m_sk = zeros(s_nwins, s_chann);
m_kurt = zeros(s_nwins, s_chann);
m_median = zeros(s_nwins, s_chann);

% counters init
s_wincount = 1;
s_index = 1;


while(s_wincount <= s_nwins)
    
    % Window movement and extraction
    m_win = m_gsr(s_index:s_index+s_winsize-1,:);
    % Determine PSD
    [m_Pxx, v_w] = pwelch(m_win, s_psdwinsize,s_psdwinover,s_nfft,s_fs);

    
    %mean, variance, skewness and kurtosis
    m_mu(s_wincount,:) = mean(m_Pxx);
    m_sigma(s_wincount,:) = var(m_Pxx);
    m_sk(s_wincount,:)=skewness(m_Pxx);
    m_kurt(s_wincount,:)=kurtosis(m_Pxx);
    m_median(s_wincount,:)=median(m_Pxx);
    
    s_wincount = s_wincount+1;
    s_index = s_index + s_step;
end



end

