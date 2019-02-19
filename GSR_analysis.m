% GSR Analysis
% Time Variables
%{ 
    - Descriptive statistics: Mean, STD
    - 
%}
% Functions to make:
%{
    - Plot in time in given interval (n channels)
    - 
%}

load('drive01_handGSR.mat');
fs = 41;
t = (0:length(val)-1)/fs;
tMin = 0;tMax = 400;
plotting(1,fs,tMin,tMax,1,10,val);
seg = val(1,(tMin*fs)+1:(tMax*fs));

win = hamming(100);
p = nextpow2(length(seg));
n = 2^p;
[m_Pxx, v_w] = pwelch(seg,win,length(win)/2,n,fs);
