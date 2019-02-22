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
% Author: Juan Manuel López
% Date: 2018/07
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [m_totalpower, m_powdelta, m_powtheta, m_powalpha, m_powbeta,...
    m_powlowgamma, m_freqhalfpower] = ...
    f_EEG_FreqFeats(m_EEG, s_winsize, s_winoverlap,...
                                    s_psdwinsize, s_psdwinover,s_nfft, s_fs,v_freqlims)

s_length = size(m_EEG,1); % data length
s_chann = size(m_EEG,2); % number of channels

s_step = s_winsize - s_winoverlap; %step length
s_nwins = floor((s_length-s_winoverlap)/s_step); % number of windows

% variables init
m_totalpower = zeros(s_nwins, s_chann);
m_powdelta = zeros(s_nwins, s_chann);
m_powtheta = zeros(s_nwins, s_chann);
m_powalpha = zeros(s_nwins, s_chann);
m_powbeta = zeros(s_nwins, s_chann);
m_powlowgamma = zeros(s_nwins, s_chann);
m_freqhalfpower = zeros(s_nwins, s_chann);

% counters init
s_wincount = 1;
s_index = 1;


while(s_wincount <= s_nwins)
    
    % Window movement and extraction
    m_win = m_EEG(s_index:s_index+s_winsize-1,:);
    
    [m_Pxx, v_w] = pwelch(m_win, s_psdwinsize,s_psdwinover,s_nfft,s_fs);

    % total power
    s_indmin = find(v_w>=v_freqlims(1),1);
    s_indmax = find(v_w>=v_freqlims(2),1);
    v_totalpower = sum(m_Pxx(s_indmin:s_indmax,:));
     
    m_totalpower(s_wincount,:) = v_totalpower;
    
        
    % relative power
    % delta 0.5-4.0 Hz
    s_ind1 = find(v_w>=0.5,1);
    s_ind2 = find(v_w>=4,1);
    v_powdelta = sum(m_Pxx(s_ind1:s_ind2,:));
    v_powdelta = v_powdelta./v_totalpower;
    m_powdelta(s_wincount,:)=v_powdelta;
    
    % relative power
    % theta 4.0-8.0 Hz
    s_ind1 = find(v_w>=4,1);
    s_ind2 = find(v_w>=8,1);
    v_powtheta= sum(m_Pxx(s_ind1:s_ind2,:));
    v_powtheta= v_powtheta./v_totalpower;
    m_powtheta(s_wincount,:)=v_powtheta;
    
    % relative power
    % alpha 8.0-12 Hz
    s_ind1 = find(v_w>=8,1);
    s_ind2 = find(v_w>=12,1);
    v_powalpha= sum(m_Pxx(s_ind1:s_ind2,:));
    v_powalpha= v_powalpha./v_totalpower;
    m_powalpha(s_wincount,:)=v_powalpha;
    
    % relative power
    % beta 12-30 Hz
    s_ind1 = find(v_w>=12,1);
    s_ind2 = find(v_w>=30,1);
    v_powbeta= sum(m_Pxx(s_ind1:s_ind2,:));
    v_powbeta= v_powbeta./v_totalpower;
    m_powbeta(s_wincount,:)=v_powbeta;
    
    % relative power
    % low gamma 30.0-50.0 Hz
    s_ind1 = find(v_w>=30,1);
    s_ind2 = find(v_w>=50,1);
    v_powlowgamma= sum(m_Pxx(s_ind1:s_ind2,:));
    v_powlowgamma= v_powlowgamma./v_totalpower;
    m_powlowgamma(s_wincount,:)=v_powlowgamma;
    
    % Frequency of half power
    % m_freqhalfpower: frequency of half power
    m_cummpower = zeros(size(m_Pxx));
    m_cummpower(1,:) = m_Pxx(s_indmin,:);
    
    s_cont = 2;
    for i =s_indmin:s_indmax
        m_cummpower(s_cont,:) = m_cummpower(s_cont-1,:)+m_Pxx(i,:);
        s_cont = s_cont+1;
    end

    for j = 1:size(m_Pxx,2)
        s_halfpowerj = v_totalpower(j)/2;
        s_freqind = find(m_cummpower(:,j) >=s_halfpowerj,1);
        s_freqhalf = v_w(s_freqind+s_indmin);
        m_freqhalfpower (s_wincount,j)=s_freqhalf;
    end

    s_wincount = s_wincount+1;
    s_index = s_index + s_step;
end 
                                
                                

