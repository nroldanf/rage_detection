function [v_SDNN,v_RMSSD,v_pNN50] = f_HRV_TempFeats(hrv)
%{
SDNN (puede hacerse en periodos cortos de 60 a 240 s)
RMSSD: se han propuesto periodos ultra cortos de 10, 30, 60 s

%}
v_SDNN = zeros();
v_RMSSD = zeros();
v_pNN50 = zeros();

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
sdnn = sqrt( sdnn/(length(hrv)-1) );
rmssd = sqrt( rmssd/(length(hrv)-1) );
pNN50 = pNN50/length(hrv)*100;




end

