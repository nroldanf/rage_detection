function  timePlot(der,sig,fs,tMin,tMax,scale,name)
%Function to plot a time series signal on a given interval in seconds
% Inputs
%     sig: Temporal sequence of samples
%     fs: Sampling Frequency
%     tMin: Inferior limit (float)
%     tMax: Superior limit (float)
%     scale: Magnitude order of the signal (string)
%     name: Name of the signal (string)

seg = sig(der,(tMin*fs)+1:(tMax*fs)+1);
t = (0:length(seg)-1)/fs;

figure();plot(t,seg);
xlabel('Tiempo (segundos)');ylabel(strcat( 'Magnitud ','(',scale,')' ));
title(name);

end

