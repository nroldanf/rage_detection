clc;clear;close all;
% ************ Tablas **************
% Lectura de archivos de UCI
data = readtable('flower_data.csv');
% Cambiar las propiedades de la tabla
data.Properties.VariableNames = {'Sepal_len' 'Sepal_width' 'Petal_len' 'Petal_width' 'Class'};
% Mirar estadisticas descripticas de la tabla 
summary(data);
% Cambiar el orden de las columnas
data(:,[5 1 2 3 4]);
% Ordenar por filas basado en una variable en particular
sortrows(data,'Sepal_width','Descend');
sortrows(data,{'Class','Sepal_len'},{'Descend', 'Ascend' })
%% Preprocesmaiento
% Manejo de valores faltantes (Imputation)
% 1. Borrar filas o columnas
data_pre = rmissing(data);
% Eliminar aquellas instancias en las cuales falten por lo menos n valores
n = 2;data_pre = rmissing(data, 'MinNumMissing',n);
% 2. Reemplazarlos por la media
M_sepal = mean(data.Sepal_len, 'omitnan' );% omita los NaN
data_sepal = fillmissing(data.Sepal_len, 'constant', M_sepal);
data.Sepal_len = data_sepal;
% 3. Trabajar con valores no num�ricos
data.Class = categorical(data.Class);
freq = mode(data.Class);
% llene con el valor de la moda
class = fillmissing(data.Class, 'constant', cellstr(freq));
%% Escalamiento de caracteristicas (Estandarizaci�n y normalizaci�n)
%{
Importante en el momento de distancias donde se requiere que las variables
tenga la misma atribuci�n

�Cuando utiulizar cadauno?
Normalizaci�n no es recomendada cuando el data tiene outlayers, puede que
contraiga mucho el rango de valores que puede tomar la variable

%}
% Para aquellas variables que posean escalas diferentes
% Estandarizaci�n
%****x_new = ( x-mean(x) ) / ( std(x) );****
% Normalizaci�n (sobre el rango)
%*** x_new = (x-min(x)) / (max(x) - min(x));***

sepal_est = (data.Sepal_len - mean(data.Sepal_len)) / std(data.Sepal_len);
sepal_nor = ( data.Sepal_len - min(data.Sepal_len) ) / (max(data.Sepal_len) - min(data.Sepal_len) )

%% Manejo de outliers
%{
Valores que est�n muy alejados de la media.
Puede que haya outliers no validos, ya sea por el registro de los datos, en
ese caso deben ser removidos. 

C�mo identificar si est�n presentes?
- Revisar la distribuci�n. Si la asimetr�a es muy marcada es probable que
haya outliers.


Como manejarlos?
Forma 1 (puede repetirse el proceso para mejorar el modelo)
- Entrenar el modelo (e.g regresi�n)
- Remover aquellos que est�n muy alejados
- Entrenar de nuevo.

Clamp Transformation 
- Para aquellos valores que est�n m�s all� de 2 STD de la media (5% de los datos), haga que
dichos valores tomen el valor de 2*STD.

C�mo lo detecta MATLAB (isoutlier):
- Usa la mediana, la media (clamp) y otros m�todos.
C�mo los reemplaza MATLAB (filloutliers)
- Se especifica el m�todo para llenar (fillmethod) y el m�todo para
detectarlos (findmethod)

%}
clc;
% ************M�todo 1: Borrar valores************
% outliers = isoutlier(data.Sepal_width) % retorna un arreglo binario
outliers = isoutlier(data.Sepal_width,'median') % retorna un arreglo binario
% Remoci�n de los outliers (remueve las filas donde sea 0)
data = data(~outliers,:);
% REPETIR PARA CADA VARIABLE
% ************M�todo 2: Reeplazar por otro valor ************
% Por el valor central (mediana o media) (CLAMP METHOD)
sepal_len = filloutliers(data.Sepal_len, 'clip','mean')
% Por el valor previo que no es outlier
sepal_len = filloutliers(data.Sepal_len, 'previous');
%% C�dificar las variables categoricas
%{
No basta con asignar valores, dado que el modelo entender� que un valor es
mayor o menor que el otro.

M�todo para variables sin orden:
- Introducir variables dummy (1 por categoria), donde se le asigna un 1

M�todo para variables con orden
- Asignar n�meros a cada valor de la variable acorde a la escala

%}

