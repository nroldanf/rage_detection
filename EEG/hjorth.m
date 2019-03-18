function [act,mob,com] = hjorth(sig)
%Esta función calcula los parámetros de Hjorth de un señal sig:
%act (actividad), mob (mobilidad) y com (complejidad).
%% Definición de factores de primer y segundo orden
dv_sig = diff(sig);%primera diferencia
dv_sig2 = diff(dv_sig);%segunda diferencia
so = mean(sig.^2);%media de la señal al cuadrado
s1 = mean(dv_sig.^2);%media de la primera derivada al cuadrado
s2 = mean(dv_sig2.^2);%media de la segunda diferencia al cuadrado
%% Cálculo de los parametros de Hjorth
% dxV = diff([0;xV]);
% ddxV = diff([0;dxV]);
act = so;
mob = s1/so;
com = sqrt((s2/s1) - (s1/so));
end

