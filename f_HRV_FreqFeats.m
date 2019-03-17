%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function f_EEG_FreqFeats
% Inputs: 
%       m_EEG: Matrix with columns as Channels and rows as samples
%       s_winsize: window size in samples
%       s_winoverlap: window overlap in samples
%       s_psdwinsize: window size for psd
%       s_psdwinover: window overlap for psd
%       s_nfft: size of fft
%       s_fs: sampling frequency
%       v_freqlims: lower and upper limits in frequency
% Outputs:
%       m_totalpower: power from PSD (Welch method)
%       organized by rows for each window, and columns for each channel
%       m_powdelta: relative power delta 0.5 - 4.0 Hz from PSD
%       m_powtheta: relative power theta 4.0 - 8.0 Hz from PSD
%       m_powalpha: relative power alpha 8.0 - 12.0 Hz from PSD
%       m_powbeta: relative power beta 12.0 - 30.0 Hz from PSD
%       m_powlowgamma: relative power low gamma 30.0 - 50 Hz from PSD
%       m_freqhalfpower: frequency of half power
% Author: Juan Manuel López / Date: 2018/07
% Modified: Nicolás Roldán Fajardo / Date: 2019/03
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [m_totalpower, m_powHF, m_powLF, m_powVLF, m_powULF]...
    = ...
    f_HRV_FreqFeats(m_HRV, s_winsize, s_winoverlap,...
                                    s_psdwinsize, s_psdwinover,s_nfft, s_fs,v_freqlims)

s_length = size(m_HRV,1); % data length
s_chann = size(m_HRV,2); % number of channels

s_step = s_winsize - s_winoverlap; %step length
s_nwins = floor((s_length-s_winoverlap)/s_step); % number of windows

% variables init
m_totalpower = zeros(s_nwins, s_chann);
m_powHF = zeros(s_nwins, s_chann);
m_powLF = zeros(s_nwins, s_chann);
m_powVLF = zeros(s_nwins, s_chann);
m_powULF = zeros(s_nwins, s_chann);
m_LFHFratio = zeros(s_nwins, s_chann);
% m_powlowgamma = zeros(s_nwins, s_chann);
% m_freqhalfpower = zeros(s_nwins, s_chann);

% counters init
s_wincount = 1;
s_index = 1;


while(s_wincount <= s_nwins)
    
    % Window movement and extraction
    m_win = m_HRV(s_index:s_index+s_winsize-1,:);
    
    [m_Pxx, v_w] = pwelch(m_win, s_psdwinsize,s_psdwinover,s_nfft,s_fs);

    % total power 
    s_ind = (v_w>=v_freqlims(1)) & (v_w<=v_freqlims(2));
    v_totalpower = trapz(v_w(s_ind,:), m_Pxx(s_ind,:));
    m_totalpower(s_wincount,:) = v_totalpower;
    
    % relative power
    % HF 0.15-0.4 Hz
    s_ind = (v_w>=0.15) & (v_w<=0.4);
    v_powHF = trapz(v_w(s_ind,:), m_Pxx(s_ind,:));
    v_powHF = (v_powHF./v_totalpower)*100;
    m_powHF(s_wincount,:)=v_powHF;
    
    % relative power
    % LF 0.04-0.15 Hz
    s_ind = (v_w>=0.04) & (v_w<=0.15);
    v_powLF = trapz(v_w(s_ind,:), m_Pxx(s_ind,:));
    v_powLF = (v_powLF./v_totalpower)*100;
    m_powLF(s_wincount,:)=v_powLF;
    
    % relative power
    % VLF 0-0.04 Hz
    s_ind = (v_w>=0) & (v_w<=0.04);
    v_powVLF = trapz(v_w(s_ind,:), m_Pxx(s_ind,:));
    v_powVLF = (v_powVLF./v_totalpower)*100;
    m_powVLF(s_wincount,:)=v_powVLF;
    
    % relative power
    % ULF 0-0.003 Hz
    s_ind = (v_w>=0) & (v_w<=0.003);
    v_powULF = trapz(v_w(s_ind,:), m_Pxx(s_ind,:));
    v_powULF = (v_powULF./v_totalpower)*100;
    m_powULF(s_wincount,:)=v_powULF;
    
    % LF/HF ratio
    v_LFHFratio = v_powLF./v_powHF;
    m_LFHFratio(s_wincount,:) = v_LFHFratio;

    s_wincount = s_wincount+1;
    s_index = s_index + s_step;
end 
                                
                                

