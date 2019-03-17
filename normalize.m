function m_sig = normalize(m_sig,op)
% m_sig: variables en columnas e instancias en filas
% Normalizan cada canal.
s_chann = size(m_sig,2);

for chan = 1:s_chann
    seg = m_sig(:,chan);
    switch op
        case 'normalize'
            m_sig(:,chan) = (seg - min(seg)) / (max(seg) - min(seg));
        case 'standarize'
            m_sig(:,chan) = ( seg - mean(seg) ) / ( std(seg) );
    end
end

end

