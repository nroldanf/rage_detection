% Mejor wavelet madre para el EEG
addpath("Signals"); 
close all;clc;
eeg = load('chb01_01_edfm.mat');eeg = eeg.val;
fs = 256;
%% Daubechies family
daub = {};
cont = 1;
figure();
for i = 2:10
    daub{cont}= strcat('db',num2str(i));
    cont=cont+1;
    
    [PHI,PSI,XVAL] = wavefun(daub{i-1},10);% wavelet without scaling function
    
    disp(length(PSI))
    
    subplot(5,2,i-1);
    plot(XVAL,PSI);
    title(daub{i-1})
end
%% morlet
clc;
[PSI,XVAL] = wavefun("morl",10);% wavelet without scaling function
figure();plot(XVAL,PSI)
%% Ventaneo sin sobrelapado
clc;close all;

m_corr = {};
for wave = 1:length(daub)
    [PHI,PSI,XVAL] = wavefun(daub{wave},10);% wavelet mother
    % inicializar
    win = length(PSI)/fs;%ventana en segundos
    inf = 0; sup = 200; sig = eeg(1, (inf*fs)+1 : (sup*fs) );%segmento de la señal
    nWin = length(sig)/(win*fs);
    n = 3;cont = 1;corr = zeros();
    %avanzará en pasos del step del for por la longitud de la ventana (0.5*win)
    for ind = 1:1/2^n:nWin
        seg = sig( (ind-1)*win*fs +1 : (ind)*win*fs );
        % correlacion con la ventana
        R = corrcoef(seg,PSI);
        corr(cont) = R(2,1);
        %gráfica correspondiente al tiempo del segmento
    %     figure();plot( (ind-1)*win : 1/fs : ind*win- 1/fs , seg);% tiempo inicial de la ventana a tiempo final en pasos de 1/fs
        cont = cont+1;
    end
    
    disp(strcat('Daubechies','_', daub{wave} ));
    disp( strcat('El máximo es: ',num2str( max(corr) ) ) );
    disp( strcat('Media : ',num2str( mean(corr) ), '±' ,num2str( std(corr) ) ) );
    
    figure();plot(corr);title( strcat('Correlación ',daub{wave} ) );
    
    
end
    
%% Morlet, Meyer, Mexican hat

waves = {'morl' , 'meyr' , 'mexh'};

for i = 1:length(waves)
    [PSI,XVAL] = wavefun(waves{i},10);% wavelet mother
    % inicializar
    win = length(PSI)/fs;%ventana en segundos
    inf = 0; sup = 200; sig = eeg(1, (inf*fs)+1 : (sup*fs) );%segmento de la señal
    nWin = length(sig)/(win*fs);
    n = 3;cont = 1;corr = zeros();
    %avanzará en pasos del step del for por la longitud de la ventana (0.5*win)
    for ind = 1:1/2^n:nWin
        seg = sig( (ind-1)*win*fs +1 : (ind)*win*fs );
        % correlacion con la ventana
        R = corrcoef(seg,PSI);
        corr(cont) = R(2,1);
        %gráfica correspondiente al tiempo del segmento
    %     figure();plot( (ind-1)*win : 1/fs : ind*win- 1/fs , seg);% tiempo inicial de la ventana a tiempo final en pasos de 1/fs
        cont = cont+1;
    end

    disp( strcat('El máximo es: ',num2str( max(corr) ) ) );
    disp( strcat('Media : ',num2str( mean(corr) ), '±' ,num2str( std(corr) ) ) );

    figure();plot(corr);title(strcat('Correlación ', waves{i} ));
end
    
%% Symlets 