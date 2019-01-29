# -*- coding: utf-8 -*-
"""
Created on Fri Aug  3 19:32:25 2018

@author: Nicolás

"""
import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as sig
# In[] Plotting signal and DFT Magnitude
raw =  np.genfromtxt('ECG_2.csv', delimiter=',')
ecg_sig = raw[2:,1]
#ecg_sig = ecg_sig - np.mean(ecg_sig)# Removing DC level

fs = 500# Sampling frequency
t = np.arange(0.0,len(ecg_sig)/fs,(1/fs))
fou = np.abs( np.fft.fft(ecg_sig) )
# Due to symmetry of the Magnitude of Fourier Transform
fou = fou[0:int(len(fou)/2)]
f = np.linspace(0,fs/2,len(fou))# Frequency vector

#Plotting both
plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(t,ecg_sig)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax1 = plt.subplot(2,1,2)
plt.plot(f,fou)
plt.title('Magnitud de la transformada de Fourier'),plt.xlabel('Frecuencia (Hz)'),plt.ylabel('Amplitud')
plt.grid()
plt.show()
# In[]   Notch Filter

fc = 50
wc_b = (fc/fs)*(2*np.pi)
wc = np.array([wc_b,-wc_b])
z = np.exp(1j*wc)#Polynomial roots
c = np.poly(z)# Get polynomial with that roots
# Filter and remove dc level
ecg_filt = sig.lfilter(c,1,ecg_sig)

fou2 = np.abs( np.fft.fft(ecg_filt) )
# Due to symmetry of the Magnitude of Fourier Transform
fou2 = fou2[0:int(len(fou)/2)]
f2 = np.linspace(0,fs/2,len(fou2))# Frequency vector
# Frequency response of the filter
w, h = sig.freqz(c)
# Conversion from rad/sample to Hz
w_hz = (w*fs)/(2*np.pi)

#Plotting the filtered signal and the frequency response
plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(t,ecg_filt)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax2 = plt.subplot(2,1,2)
plt.plot(f2,fou2)
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [Hz]')

# In[] baseline filter
b, a = sig.butter(10, 100/(0.5*fs), btype='low')
b2, a2 = sig.butter(5, 0.5/(0.5*fs), btype='high')
# Frequency response of the filter
w, h = sig.freqz(b,a)
# Conversion from rad/sample to Hz
w_hz = (w*fs)/(2*np.pi)
# Frequency response of the filter
w2, h2 = sig.freqz(b2,a2)
# Conversion from rad/sample to Hz
w_hz2 = (w2*fs)/(2*np.pi)

plt.figure()
plt.plot(w_hz, 20 * np.log10(abs(h)), 'b')
plt.title('Pasabajas')
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [rad/sample]')
plt.show()

plt.figure()
plt.plot(w_hz2, 20 * np.log10(abs(h2)), 'b')
plt.title('Pasaaltas')
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [rad/sample]')
plt.show()


# Applying filter
ecg_filt = sig.lfilter(b,a,ecg_sig)
ecg_filt = sig.lfilter(b2,a2,ecg_filt)
#
fou2 = np.abs( np.fft.fft(ecg_filt) )
# Due to symmetry of the Magnitude of Fourier Transform
fou2 = fou2[0:int(len(fou)/2)]
f2 = np.linspace(0,fs/2,len(fou2))# Frequency vector

#Plotting the filtered signal and the frequency response
plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(t,ecg_filt)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax2 = plt.subplot(2,1,2)
plt.plot(f2,fou2)
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [Hz]')



#function [sig_o] = baseline_filter(sig,fs)
#close all;
#%%
#%Realiza el filtro de baseline wandering para n canales de ECG.
#%Generalizado para n canales
#%NOTA: Funciona para frecuencias de muestreo menores a 1000 (TESTED xD)
#
#[cha,m] = size(sig);
#fnyq = fs/2;    %Frecuencia de Nyquist
#Wp = [1 100]/fnyq;   %Banda pasante normalizada (IZQ y DER)
#Ws = [0.5 120]/fnyq;    %Banda rechazada normalizada
#Rp = 10;        %Rizado de Passband
#Rs = 30;        %Rizado de Stopband
#%%
#%Filtro Chevyshev tipo II
#[n,Ws] = cheb2ord(Wp,Ws,Rp,Rs);
#[b,a] = cheby2(n,Rs,Ws);
#freqz(b,a,1024,fs)
#%%
#temp = [];
#sig_o = [];
#for i=1:cha
#    temp = filtfilt(b,a,sig(i,:));
#    sig_o = [sig_o;temp];
#end
#end
# In[]
fnyq = fs/2
Wp = np.array([1,100])/fnyq
Ws = np.array([0.5,120])/fnyq
Rp = 10
Rs = 30
n,Ws = sig.cheb2ord(Wp,Ws,Rp,Rs)
b,a = sig.cheby2(n,Rs,Ws,btype='bandpass')
# Frequency response of the filter
w, h = sig.freqz(b,a)
# Conversion from rad/sample to Hz
w_hz = (w*fs)/(2*np.pi)
plt.figure()
plt.plot(w_hz, 20 * np.log10(abs(h)), 'b')
plt.title('Pasabajas')
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [rad/sample]')
plt.show()


ecg_filt = sig.lfilter(b,a,ecg_sig)
# Due to symmetry of the Magnitude of Fourier Transform
fou2 = fou2[0:int(len(fou)/2)]
f2 = np.linspace(0,fs/2,len(fou2))# Frequency vector

#Plotting the filtered signal and the frequency response
plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(t,ecg_sig)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax2 = plt.subplot(2,1,2)
plt.plot(t,ecg_filt)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()


plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(f,fou)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax2 = plt.subplot(2,1,2)
plt.plot(f2,fou2)
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [Hz]')

# In[] Filtro de peine
# 60,120,240 (3 y 5 armonico)
# angulos (6 angulos)
fc = 50
wc_b = (fc/fs)*2*np.pi
wc = []
z = []
for k in range(1,5,2):
    wc.append(k*(fc/fs)*2*np.pi)
    wc.append(-k*(fc/fs)*2*np.pi)
    print(k)

z = np.exp(1j*np.array(wc))
c = np.poly(z);

w, h = sig.freqz(c,1)
# Conversion from rad/sample to Hz
w_hz = (w*fs)/(2*np.pi)
plt.figure()
ax1 = plt.suplot(2,1,1)
plt.plot(w_hz, 20 * np.log10(abs(h)), 'b')
plt.title('Pasabajas')
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [rad/sample]')
ax1 = plt.suplot(2,1,2)
plt.plot(w_hz, 20 * np.log10(abs(h)), 'b')

plt.show()


ecg_filt2 = sig.lfilter(c,1,ecg_filt)
# Due to symmetry of the Magnitude of Fourier Transform
fou3 = np.abs( np.fft.fft(ecg_filt2) )
fou3 = fou3[0:int(len(fou3)/2)]
f3 = np.linspace(0,fs/2,len(fou3))# Frequency vector

#Plotting the filtered signal and the frequency response
plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(t,ecg_sig)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax2 = plt.subplot(2,1,2)
plt.plot(t,ecg_filt2)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()


plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(f,fou)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax2 = plt.subplot(2,1,2)
plt.plot(f3,fou3)
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [Hz]')

# In[]
fs = 500
t = np.arange(0.0,len(ecg_filt)/fs,(1/fs))

b = np.array([1,-1])
a = np.array([1,-0.995])
w, h = sig.freqz(b,a)
# Conversion from rad/sample to Hz
w_hz = (w*fs)/(2*np.pi)
plt.figure()
plt.plot(w_hz, 20 * np.log10(abs(h)), 'b')
plt.title('Pasabajas')
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [rad/sample]')
plt.show()


ecg_filt = sig.filtfilt(b,a,ecg_sig)

#Plotting the filtered signal and the frequency response
plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(t,ecg_filt)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax2 = plt.subplot(2,1,2)
plt.plot(t,ecg_filt2)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()


plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(f,fou)
plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
plt.grid()
ax2 = plt.subplot(2,1,2)
plt.plot(f3,fou3)
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [Hz]')

# In[] Pan Tompkins
# Band-pass filter: Muscle noise, baseline wander, T-wave interference. 5-15 Hz.
# Low-pass filter
blp = np.zeros(13)
blp[0] = 1;blp[6] = -2;blp[12] = 1;
alp = [1,-2,1]
wlp,hlp = sig.freqz(blp,alp)
# High-pass filter
bhp = np.zeros(33);
bhp[0] = -1;bhp[16] = 32; bhp[32] = 1;
ahp = [1,1];
whp,hhp = sig.freqz(bhp,ahp)

# Derivative filter
bder = (1/8)*fs*np.array([1,2,0,-2,-1])
wder,hder = sig.freqz(bder,1,1024,fs);

# Integration

sig_filt = sig.lfilter(blp,alp,ecg_sig)
sig_filt2 = sig.lfilter(bhp,ahp,sig_filt)
sig_filt3 = sig.lfilter(bder,1,sig_filt2)

plt.figure
ax1 = plt.subplot(3,1,1)
plt.plot(t,sig_filt)
plt.title('Filtro pasa-bajas')

ax1 = plt.subplot(3,1,2)
plt.plot(t,sig_filt2)
plt.title('Filtro pasa-bandas')

ax1 = plt.subplot(3,1,3)
plt.plot(t,sig_filt3)
plt.title('Filtro derivativo')
plt.show()


sig_filt4 = np.square(sig_filt3)

plt.figure()
ax1 = plt.subplot(2,1,1)
plt.plot(t,sig_filt4);
plt.title('Elevada al cuadrado');


N=30
Y_VenMovil = sig_filt4
Y_Int = []
for i in range(0,len(Y_VenMovil)):
    suma = 0
    for n in range(0,N):
            if i > (N-n):
                suma += Y_VenMovil[i -(N-n)]
    Y_Int.append(suma)
Y_Int = np.array(Y_Int)*(1/N)


ax1 = plt.subplot(2,1,2)
plt.plot(t,Y_Int);
plt.title('Integrada');
plt.show()



#Nder = 3;
#bder1 = zeros(1,7);
#bder1(1) = 1;bder(7) = -1;
#bder1 = bder1*(1/(2*Nder));
#
#ader1 = zeros(1,7);
#ader1(Nder+1) = 1;
#
#Yfin = filter(bder1,1,Y_Int);
#figure;
#plot(t(1:5*fs),Yfin);
#
#
#
#Yfin = filter(bder1,1,Y_Int);
#figure;
#plot(t(1:5*fs),Yfin);




# In[] Funciones

def plotting(sig,fs,t):
    # Due to symmetry of the Magnitude of Fourier Transform
    fou = np.abs( np.fft.fft(sig) )
    fou = fou[0:int(len(fou)/2)]
    f = np.linspace(0,fs/2,len(fou))# Frequency vector
    
        #Plotting both
    plt.figure()
    ax1 = plt.subplot(2,1,1)
    plt.plot(t,sig)
    plt.title('ECG'),plt.xlabel('Tiempo (s)'),plt.ylabel('Amplitud')
    plt.grid()
    ax1 = plt.subplot(2,1,2)
    plt.plot(f,fou)
    plt.title('Magnitud de la transformada de Fourier'),plt.xlabel('Frecuencia (Hz)'),plt.ylabel('Amplitud')
    plt.grid()
