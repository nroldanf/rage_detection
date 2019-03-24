function m_PCA = eegPCA(m_eeg,op,criteria)
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

% PCA mediante la matriz de covarianza
%{
1. Hallar matriz de covarianza
2. Determinar eigenvectores y eigenvalores.
3. Hallar la varianza que aporta cada variable
4. Seg�n criteria, obtener los componentes principales m�s significativos.
%}

switch op
    case "covariance"
        S =  cov(m_eeg);% covarianza entre variables
        % Obtener eigenvectores y eigenvalores de la matriz de covarianza
        [eig_vect,eig_val] = eig(S);
        % Ordenar en orden descendente los eigenvalores y eigenvectores
        eig_val = sort(diag(eig_val),'descend');
        eig_vect = fliplr(eig_vect);
        % Explained variance to choose the most significant components
        tot = sum(eig_val);

        var_exp = [];
        c = {};
        len = length(eig_val);
        for i = 1:length(eig_val)
            var_exp(i) = (eig_val(i)/tot)*100; 
        end
        cum=cumsum(var_exp);

        figure;
        bar(var_exp);
        title("Explained variance by different principal components");
        ylabel("Explained variance in percent");
        grid on;
        hold;
        plot(cum,'-o');
        plot(ones(size(var_exp))*criteria,'--')

        % Obtenci�n de la matriz de proyecci�n (concatenaci�n de los primeros eigenv)
        var = 0;cont=1;
        mask = zeros();
        while(var<=criteria)
            var = var+var_exp(cont);
            mask(cont) = cont;
            cont=cont+1;
        end
        new_feat = eig_vect(:,mask);
        % Proyecci�n en el nuevo espacio
        m_PCA = m_eeg*new_feat;
       
end



end

