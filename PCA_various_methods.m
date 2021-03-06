load("chb01_01_edfm.mat");
m_eeg = val';
%% PCA mediante la matriz de covarianza
% Direcciones que maximizan la varianza 
% Todos los eigenvectores son unitarios

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
%     c{i} = strcat('PCA ',num2str(len));
%     len = len-1;
end
% c = categorical(c);
cum=cumsum(var_exp);

figure;
bar(var_exp);
title("Explained variance by different principal components");
ylabel("Explained variance in percent");
grid on;
hold;
plot(cum,'-o');
plot(ones(size(var_exp))*95,'--')

% Obtención de la matriz de proyección (concatenación de los primeros eigenv)
% criterio del 95% de la varianza
criteria = 95;
var = 0;cont=1;
mask = zeros();
while(var<=criteria)
    var = var+var_exp(cont);
    mask(cont) = cont;
    cont=cont+1;
end

new_feat = eig_vect(:,mask);
% Proyección en el nuevo espacio
Y = m_eeg*new_feat;
Sy =cov(Y);
% La matriz con vectores fila de cada canal relevante se ingresa en jadeR
B= jadeR(Y',length(mask));
Yind=B*Y';

figure;
plot(m_eeg(:,1))
figure;
plot(Yind(1,:));

%%
