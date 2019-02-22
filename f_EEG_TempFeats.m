%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function f_EEG_TempFeats
% Inputs: 
%       m_EEG: Matrix with columns as Channels and rows as samples
%       s_winsize: window size in samples
%       s_winoverlap: window overlap in samples
% Outputs:
%       m_mu: mean of samples organized by rows for each window, and columns
%       for each channel
%       m_sigma: variance of samples
%       m_sk: skewness of samples
%       m_kurt: kurtosis
%       m_act: Hj�rth activity
%       m_mob: Hj�rth movility
%       m_comp: Hj�rth complexity
%       m_FD: fractal dimension
%
% Author: Juan Manuel L�pez
% Date: 2018/07
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [m_mu, m_sigma, m_sk, m_kurt, m_act, m_mob, m_comp, m_FD] = ...
    f_EEG_TempFeats(m_EEG, s_winsize, s_winoverlap)

s_length = size(m_EEG,1); % data length
s_chann = size(m_EEG,2); % number of channels

s_step = s_winsize - s_winoverlap; %step length
s_nwins = floor((s_length-s_winoverlap)/s_step); % number of windows

% variables init
m_mu = zeros(s_nwins, s_chann);
m_sigma = zeros(s_nwins, s_chann);
m_sk = zeros(s_nwins, s_chann);
m_kurt = zeros(s_nwins, s_chann);

m_act = zeros(s_nwins, s_chann);
m_mob = zeros(s_nwins, s_chann);
m_comp = zeros(s_nwins, s_chann);

m_FD = zeros(s_nwins, s_chann);

% counters init
s_wincount = 1;
s_index = 1;


while(s_wincount <= s_nwins)
    
    % Window movement and extraction
    m_win = m_EEG(s_index:s_index+s_winsize-1,:);
    
    %mean, variance, skewness and kurtosis
    m_mu(s_wincount,:) = mean(m_win);
    m_sigma(s_wincount,:) = var(m_win);
    m_sk(s_wincount,:)=skewness(m_win);
    m_kurt(s_wincount,:)=kurtosis(m_win);
   
    %Hj�rth Parameters
    [v_act, v_mob, v_comp] = f_HjorthFeats(m_win);
    m_act(s_wincount,:) = v_act;
    m_mob(s_wincount,:) = v_mob;
    m_comp(s_wincount,:)=v_comp;
    
    %Fractal Dimension
    for i = 1:size(m_win,2)
        s_FD = Higuchi_FD(m_win(:,i)',10);
        m_FD(s_wincount,i) = s_FD;
    end
    
    s_wincount = s_wincount+1;
    s_index = s_index + s_step;
end