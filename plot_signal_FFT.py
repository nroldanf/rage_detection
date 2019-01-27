# -*- coding: utf-8 -*-
"""
Created on Fri Aug  3 19:32:25 2018

@author: Nicolás

"""
import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as sig
# In[] Plotting signal and DFT Magnitude
raw =  np.genfromtxt('samples.csv', delimiter=',')
ecg_sig = raw[2:,1]
#ecg_sig = ecg_sig - np.mean(ecg_sig)# Removing DC level

fs = 360# Sampling frequency
t = np.arange(0.0,10.0,(1/fs))
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

fc = 60
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
fc = 60
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
plt.plot(w_hz, 20 * np.log10(abs(h)), 'b')
plt.title('Pasabajas')
plt.ylabel('Amplitude [dB]', color='b')
plt.xlabel('Frequency [rad/sample]')
plt.show()


ecg_filt2 = sig.lfilter(c,1,ecg_filt)
# Due to symmetry of the Magnitude of Fourier Transform
fou3 = np.abs( np.fft.fft(ecg_filt) )
fou3 = fou2[0:int(len(fou3)/2)]
f3 = np.linspace(0,fs/2,len(fou3))# Frequency vector

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