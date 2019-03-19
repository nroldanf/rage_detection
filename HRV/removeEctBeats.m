function [hrv_new,v_t] = removeEctBeats(hrv,v_t)
hrv_new = hrv;
i = 1;% contador indice
cont = 0;% contador de rr eliminados
while i < length(hrv)-cont
    if i > 1
        mu = mean(hrv_new(1:i-1));% calcule la media de los precedentes
        disp(i)
        if hrv_new(i) > 1.2*mu% 
            hrv_new(i) = [];% remueva el element
            v_t(i) = [];
            cont = cont+1;
        else
            i = i+1;% incremente si no lo elimino
        end
    else
        i = i+1;
    end
end
end

