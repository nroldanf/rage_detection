function [m_signals] = gUSBplotting(gds_interface,t_adqui,fs,scans,num_chan,ancho_win,hax1,hax2)

% ======filtro==========
% order = 7;
% c = fir1(order,[0.5 30]./(fs/2));
% pack = length(c);
% times = 3*ceil(pack/scans);
% % lim1_scans = 1;lim2_scans = scans;
% scans_cum = times*scans;
% sig_temp = zeros(scans_cum,length(num_chan));
%=======================
% =============CONTROL KEYBOARD===============
global KEY_IS_PRESSED
KEY_IS_PRESSED = 0;
gcf
set(gcf, 'KeyPressFcn', @myfun)
%============================================
t = (0:fs*ancho_win-1)/fs;
signal = zeros(ancho_win*fs,length(num_chan));% vector para graficar
chan = length(num_chan);

plot_names = {'ECG','Fp1','Fp2','T1','T2'};

% Inicialización
samples_acquired = 0;
lim1_plot = 1;lim2_plot = scans;
% ======== si hay filtro ======== 
% lim1_plot = 1;lim2_plot = times*scans;
%================================
lim1 = 1;lim2 = scans;
% ======== si hay filtro ========
% lim1 = 1;lim2 = times*scans;
%================================
% total_samples = t_adqui*fs;
% m_signals = zeros(total_samples,length(num_chan));
%============= TIEMPO DETERMINADO POR BOTÓN=====
m_signals = [];
%============================================
gds_interface.StartDataAcquisition();
%================= MENSAJE ======================
disp('Adquiriendo...');
while ~KEY_IS_PRESSED%(samples_acquired < total_samples)
    [scans_received, signal(lim1_plot:lim2_plot,:)] = gds_interface.GetData(scans);

    %========== si hay filtrado==================
%     for i = 1:times
%         [scans_received, data] = gds_interface.GetData(scans);
%         sig_temp((i-1)*scans+1:i*scans,:) = data;% sin contadores
%     end
%     sig_temp = filtfilt(c,1,sig_temp);
%     
%     signal(lim1_plot:lim2_plot,:)=sig_temp;
%     %========== subplot =================
%     for j = 1:chan
%        subplot(2,1,j);plot(t,signal(:,j));
%        grid on;
%     end

%     m_signals(lim1:lim2,:) = sig_temp;

    %====================================   
%     plot(t(1,lim1_plot:lim2_plot),sig_temp(1,:));
    
%     lim1 = lim1+scans_cum;
%     lim2 = lim2+scans_cum;
%     
%     lim1_plot = lim1_plot+scans_cum;
%     lim2_plot = lim2_plot+scans_cum;
%     xlim([lim1_plot lim2_plot]);
%     
%     if lim2_plot >= ancho_win*fs
%         lim1_plot = 1;lim2_plot=times*scans;
%     end
%     samples_acquired = samples_acquired + times*scans;
    %====================================
%     m_signals(lim1:lim2,:) = signal(lim1_plot:lim2_plot,:);% Matriz de señales
    m_signals = vertcat(m_signals,signal(lim1_plot:lim2_plot,:));
    %========== subplot =================
    for chan = 1:chan
        if chan == 1
            plot(hax1,t,signal(:,chan));
            %title(hax1,plot_names{chan});
%             grid(hax1,'on');
        else
            plot(hax2(chan-1),t,signal(:,chan));
%             title(hax2(chan-1),plot_names{chan});
%             grid(hax2(chan-1),'on');
        end

    end
    %====================================    
    samples_acquired = samples_acquired + scans_received;
%     desplace los indices de la matriz de señales
    lim1 = lim1+scans_received;
    lim2 = lim2+scans_received;
%     desplace el vector de señal que se está graficando
    lim1_plot = lim1_plot+scans_received;
    lim2_plot = lim2_plot+scans_received;
%     Reinicie los vectores de tiempo y señal
    if lim2_plot >= ancho_win*fs
        lim1_plot = 1;lim2_plot = scans;
    end
end
disp('Parando adquisición...');
gds_interface.StopDataAcquisition();
disp('Adquisición finalizada.');
end

