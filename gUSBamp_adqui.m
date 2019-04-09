clc;clear;close all;

num_chan = [1 5 6 7 8];
fs = 256;scans = 8;
ancho_win = 5;
% ===== TIEMPO DE ADQUICISIÓN E ID DE LA PERSONA
t_adqui = 10;
ID = 1;
% ================= CONFIGURACIÓN g.USBamp ==============================
gds_interface = gtecDeviceInterface;
% Configuración del cliente-servidor
gds_interface.IPAddressHost = '127.0.1.1';
gds_interface.IPAddressLocal = '127.0.0.1';
gds_interface.HostPort = 50223;
gds_interface.LocalPort = 50224;
% Dispositivos conectados
connected_devices = gds_interface.GetConnectedDevices();
% Obtener canales disponibles (arreglo lógico)
gusbamp_config = gUSBampDeviceConfiguration();
gusbamp_config.Name = connected_devices(1,1).Name;
gds_interface.DeviceConfigurations = gusbamp_config;
available_channels = gds_interface.GetAvailableChannels();
% Configuración de la fs 
gusbamp_config.SamplingRate = fs;
gusbamp_config.NumberOfScans = scans;
gusbamp_config.CounterEnabled = true;% contador 

channels_selected = zeros(1,length(available_channels));
for i=num_chan
    if (available_channels(1,i))
        gusbamp_config.Channels(1,i).Available = true;
        gusbamp_config.Channels(1,i).Acquire = true;
        bp = gUSBfilters(gds_interface,256,0.5,100);
        gusbamp_config.Channels(1,i).BandpassFilterIndex = bp;
        gusbamp_config.Channels(1,i).NotchFilterIndex = -1; % do not use a bipolar channel 
        gusbamp_config.Channels(1,i).BipolarChannel = 0;
        channels_selected(i) = 1;
        disp(['Canal ' num2str(i) ' configurado.']);
    end
end
% Asigne la configuración al objeto
gds_interface.DeviceConfigurations = gusbamp_config;
gds_interface.SetConfiguration();
%%
% Figuras
x_off = 300;y_off = 250;
% ECG
figure('Name','ECG','NumberTitle','off');
movegui([x_off y_off]);
hax1 = axes;
% EEG
figure('Name','EEG','NumberTitle','off');
movegui([-x_off y_off]);
hax2_1 = subplot(4,1,1);
hax2_2 = subplot(4,1,2);
hax2_3 = subplot(4,1,3);
hax2_4 = subplot(4,1,4);
hax2 = [hax2_1,hax2_2,hax2_3,hax2_4];
%%

m_signals = gUSBplotting(gds_interface,t_adqui,fs,scans,num_chan,ancho_win,hax1,hax2);
save(['P2C_session1_0' num2str(ID)],'m_signals');
disp('Segunda etapa.Presione un botón...');
pause;
% m_signals2 = gUSBplotting(gds_interface,t_adqui,fs,scans,num_chan,ancho_win,hax1,hax2);
% save(['P2C_session2_0' num2str(ID)],'m_signals2');

%% =============== INICIAR EL JUEGO ============
% Ejecutable de UNREAL
command = 'C:\Users\juan.lopezl\Documents\PD_2019_1_NicolasRoldan\CARLA_0.9.4\CarlaUE4.exe';
[status,cmdout] = system(command);
% Script de Python 
command2 = 'cd C:\Users\juan.lopezl\Documents\PD_2019_1_NicolasRoldan\CARLA_0.9.4\';
[status,cmdout] = system(command2);
command3 = 'python C:\Users\juan.lopezl\Documents\PD_2019_1_NicolasRoldan\CARLA_0.9.4\manual_control.py -n 10';
[status,cmdout] = system(command3);

%%
% delete(gds_interface);
% clear gds_interface;