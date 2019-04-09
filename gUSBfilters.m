function varargout = gUSBfilters(gds_interface,fs,varargin)

% bpLowFreq,bpHighFreq,nLowFreq,nHighFreq)
% Filtros disponibles
% Posibles valores:
%{
fhigh: 0,15,30,60,100,200,250,500,1000,2000,4000
flow: 0.01, 0.1, 0.5 ,1 , 2 , 5
%}

fields = {'FilterIndex','LowerCutoffFrequency','UpperCutoffFrequency'};
filters = gds_interface.GetAvailableFilters(fs);

if nargin == 4
    sup = length(filters.BandpassFilters);
    for i = 1:sup
        low = filters.BandpassFilters(i).(fields{2});% lower
        high = filters.BandpassFilters(i).(fields{3});% upper
        if low == varargin{1} && high == varargin{2}
            varargout{1} = filters.BandpassFilters(i).(fields{1});
        end
    end
    
elseif nargin > 4
    sup = length(filters.BandpassFilters);
    for i = 1:sup
        low = filters.BandpassFilters(i).(fields{2});% lower
        high = filters.BandpassFilters(i).(fields{3});% upper
        if low == varargin{1} && high == varargin{2}
            varargout{1} = filters.BandpassFilters(i).(fields{1});
        end
    end
    
    sup = length(filters.NotchFilters);
    % Notch
    for i = 1:sup
        low = filters.NotchFilters(i).(fields{2});% lower
        high = filters.NotchFilters(i).(fields{3});% upper
        if low == varargin{3} && high == varargin{4}
            varargout{2} = filters.NotchFilters(i).(fields{1});
        end
    end
    
else
    disp('Faltan argumentos de entrada.')
end