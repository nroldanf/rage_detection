function [v_SDNN,v_RMSSD,v_pNN50] = f_HRV_TempFeats(m_HRV,s_winsize, s_winoverlap)
%{
SDNN (puede hacerse en periodos cortos de 60 a 240 s)
RMSSD: se han propuesto periodos ultra cortos de 10, 30, 60 s

%}
s_length = size(m_HRV,2); % data length
s_chann = size(m_HRV,1); % number of channels

s_step = s_winsize - s_winoverlap; %step length
s_nwins = floor((s_length-s_winoverlap)/s_step); % number of windows


v_SDNN = zeros(s_nwins, s_chann);
v_RMSSD = zeros(s_nwins, s_chann);
v_pNN50 = zeros(s_nwins, s_chann);

% counters init
s_wincount = 1;
s_index = 1;

while(s_wincount <= s_nwins)
    hrv = m_HRV(1,s_index:s_index+s_winsize-1);
    
    sdnn= 0;rmssd = 0;pNN50 = 0;
    for rr = 1:length(hrv)
        sdnn = sdnn + ( (hrv(rr) - mean(hrv)) )^2;
        if rr < length(hrv)-1
            rmssd = rmssd + (hrv(rr+1) - hrv(rr) )^2 ;
            %pNN50: aquellos intervalos que difieran de más de 50ms (se puede hacer en segmentos de 2 min minimo)
            % se han propuesto intevalos de 60 s.
            diff = hrv(rr+1) - hrv(rr);
            if diff > 0.05
                pNN50 = pNN50 + 1;
            end
        end    
    end
    v_SDNN(s_wincount,1) = sqrt( sdnn/(length(hrv)-1) );
    v_RMSSD(s_wincount,1) = sqrt( rmssd/(length(hrv)-1) );
    v_pNN50(s_wincount,1) = pNN50/length(hrv)*100;

    s_wincount = s_wincount+1;
    s_index = s_index + s_step;
    
end


end

