function xcorr_chan = bestMW2(m_sig,s_winsize,s_winoverlap)
% Función que realiza la correlación cruzada para determinar la wavelet
% madre (MW) más apta para el análisis multiresolución de determinadas
% señales m_sig.
% Entradas:
% m_sig: Señal cuyos canales están en filas y muestras en columnas
% win_size depende del tamaño de PSI


% Cosas que debe realizar la función:
%{
- Hacerlo para todos los canales.
- Hacerlo para cada canal, con todas las MW de cada una de las familias.
***Por cada canal -> cada familia -> cada MW***
-
- Familias: dB, sym, coiflet

%}

s_chan = size(m_sig,1);
s_length = size(m_sig,2);

s_step = s_winsize - s_winoverlap; %step length
s_nwins = floor((s_length-s_winoverlap)/s_step); % number of windows



fam_names = {'db','sym','coif','morl' , 'meyr' , 'mexh'};
MW_names = {};

xcorr_chan = {{},{},{},{},{},{}};


% Para cada familia de MW
for fam = 1:6
    % Determinar todos los nombres de la familia 
    switch fam_names{fam}
        case {'db','sym'}
            for i = 1:20 
                MW_names{i} = strcat(fam_names{fam},num2str(i));
                fam_len=20;
            end
        case 'coif'
            for i = 1:5 
                MW_names{i} = strcat(fam_names{fam},num2str(i));
                fam_len=5;
            end
        case{'morl','meyr','mexh'}
            MW_names{i} = strcat(fam_names{fam});
            fam_len=1;
    end
    
    
    % Para cada MW dentro de la familia
    for MW = 1:fam_len
        s_wincount = 1;
        s_index = 1;
        
        [sigDEN,wDEC] = func_denoise_sw1d(m_sig,MW_names{MW});
        corr = zeros();% Matriz con la correlación de cada MW
        % ***Ventaneo***
        while(s_wincount <= s_nwins)
            % Extraiga una ventana para cada canal
            m_win = m_sig(1,s_index:s_index+s_winsize-1);
            m_win2 = sigDEN(1,s_index:s_index+s_winsize-1);
    
            % Realice la correlación cruzada
            R = corrcoef(m_win,m_win2);c = R(2,1);
            % Concatene
            corr(s_wincount) = c;
            
            s_wincount = s_wincount+1;
            s_index = s_index + s_step;
        end
        xcorr_chan{fam}{MW} = corr;
    end

end




end

