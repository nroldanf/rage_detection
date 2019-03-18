function eegPCA(m_EEG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function f_EEG_TempFeats
% Inputs: 
%       m_EEG: Matrix with columns as Channels and rows as samples

% Outputs:
%       m_PCA: Matrix with the most relevant channels.
%
% Author: Nicolás Roldán Fajardo
% Date: 2019/03
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s_chan = size(m_EEG,2);% Número de canales/variables
s_len = size(m_EEG,1);% Número de muestras/observaciones
% Centrar variables restando la media 
for chan = 1:s_chan
   m_EEG(:,chan) = m_EEG(:,chan) - mean(m_EEG(:,chan)); 
end
% Compoenentes principales
[U,S,pc] = svd(m_EEG,'econ');
eigen = diag(S).^2;
for i = 1:s_chan
   pc(:,i) = pc(:,i)*sqrt(eigen(i)); 
end
figure;plot(eigen);
title('Scree plot');xlabel('N');ylabel('Valores propios');grid 'on';

total_eigen = sum(eigen);
pct = zeros();
for i = 1:s_chan
    pct(i) = sum(eigen(i:s_chan))/total_eigen;
end
disp(pct*100);
% Tome los k canales más significativos




end

