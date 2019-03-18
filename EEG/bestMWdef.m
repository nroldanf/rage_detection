function xcorr_chan = bestMWdef(m_sig,s_winsize,s_winoverlap)
% Calcula para cada subabnda la correlación cruzada

s_chan = size(m_sig,1);
s_length = size(m_sig,2);

s_step = s_winsize - s_winoverlap; %step length
s_nwins = floor((s_length-s_winoverlap)/s_step); % number of windows



fam_names = {'db','sym','coif','morl' , 'meyr' , 'mexh'};
MW_names = {};

xcorr_chan = {{},{},{},{},{},{}};

% SURE THRESHOLD
thr = [963.6,2211.642,0.013,0.006,0.008];


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
        
        % Decomposition
        [c0,l0] = wavedec(m_sig,5,MW_names{MW});
        D = zeros(6,s_length);
        % Reconstruction and plotting (time and frequency)
        for i = 1:5
            if i == 5
                D(i,:) = wrcoef('d',c0,l0,MW_names{MW},i);
                D(i,:) = wthresh(D(i,:),'s',thr(i));
                D(i+1,:) = wrcoef('a',c0,l0,MW_names{MW},i);
            else
                D(i,:) = wrcoef('d',c0,l0,MW_names{MW},i);
                D(i,:) = wthresh(D(i,:),'s',thr(i));
            end
        end


        corr = zeros();% Matriz con la correlación de cada MW
        % ***Ventaneo***
        while(s_wincount <= s_nwins)
            % Extraiga una ventana para cada canal
            m_win = m_sig(1,s_index:s_index+s_winsize-1);
            % Para cada D y A
            for i = 1:6
                m_win2 = D(i,s_index:s_index+s_winsize-1);
                % Realice la correlación cruzada
                R = corrcoef(m_win,m_win2);c = R(2,1);
                % Concatene
                corr(i,s_wincount) = c;
            end
            s_wincount = s_wincount+1;
            s_index = s_index + s_step;
        end
        xcorr_chan{fam}{MW} = corr;
    end

end




end

