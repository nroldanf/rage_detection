function m_sigNew = WaveletDenoising(m_sig,wave,thr,levels,fs,plotFlag)
% Realiza un filtro wavelet con una wavelet madre wave y niveles de umbral
% thr para cada banda en orden: Dlevels hasta la aproximación Alevels



% Parámetros importantes
s_length = size(m_sig,1);% en filas
s_chann = size(m_sig,2);% en columnas
m_sigNew = m_sig;% matriz de la nueva señal
t = (0:s_length-1)/fs;% vector de tiempo
f = linspace(0,fs/2,length(fftMag(m_sig(:,1))));

bands = {'Ruido','\gamma (25-100 Hz)','\beta (14-35 Hz)','\alpha (8-14 Hz)','\theta (4-8 Hz)','\delta (0.5-4 Hz)'};%Para cada canal
for i = 1:s_chann
% Decomposition
    [c0,l0] = wavedec(m_sig(:,i),levels,wave);
    D = zeros(6,s_length);
    % Umbralización (filtrado)
    for j = 1:levels
        % Para el nivel de coeficientes de aproximación alevels
        if j == levels
            D(j,:) = wrcoef('d',c0,l0,wave,j);
            D(j,:) = wthresh(D(j,:),'s',thr(j));
            D(j+1,:) = wrcoef('a',c0,l0,wave,j);
        else
            D(j,:) = wrcoef('d',c0,l0,wave,j);
            D(j,:) = wthresh(D(j,:),'s',thr(j));
        end
    end

    D = D';% transpuesta
    if plotFlag == 1 
    % Plotee cada subbanda
        figure('Name',['Canal ' num2str(i)],'NumberTitle','off')
        for k = 1:6
            %tiempo
            subplot(6,2,k*2-1);
            plot(t,D(:,k));grid on;
            xlabel('Tiempo');ylabel('\mu V');
            %frecuencia
            subplot(6,2,k*2);
            plot(f,fftMag(D(:,k)));grid on;
            xlabel('Frecuencia')
            title(bands{k})
        end
    end
% Sume los componentes
    for k = 1:6
        m_sigNew(:,i) = m_sigNew(:,i)+D(:,k);
    end
end

end

