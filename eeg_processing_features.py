# -*- coding: utf-8 -*-
"""
Created on Mon Jan 28 23:04:50 2019

@author: Nicolas
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import scipy.signal as sig
# In[] 
raw =  np.genfromtxt('eeg.csv', delimiter=',')
eeg = raw[2:,1:]
# Carga de la señal
#data = pd.read_csv('eeg.csv',header = 0)
#eeg = data.iloc[1:,1:].as_matrix()
fs = 500
t = np.arange(0,len(eeg)/fs,(1/fs))
# In[] 
plt.close('all')



eeg1 = np.array(eeg[0:,0])/626.970913945
seg = eeg1[0:20*fs]

fwelch, pxx = sig.welch(seg, fs=fs, window='blackman', nperseg=256, noverlap=None, nfft=None, 
      detrend='constant', return_onesided=True, scaling='density', axis=-1)

fou = np.abs(np.fft.fft(seg))
fou = fou[0:int(len(fou)/2)]
f = np.linspace(0,fs/2,len(fou))# Frequency vector

plt.figure()
plt.plot(t[0:20*fs],seg)
plt.show()

plt.figure()
plt.grid('on')
plt.semilogy(fwelch, pxx)
plt.xlabel('frequency [Hz]')
plt.ylabel('PSD [V**2/Hz]')
plt.show()

plt.figure()
plt.plot(f,fou)
plt.show()

# In[]
#Parámetros de Hjorth
def hjorth(sig):
    dv_sig = np.diff(sig)
    dv_sig2 = np.diff(dv_sig)
    s0 = np.mean(np.square(sig))
    s1 = np.mean(np.square(dv_sig^2))
    s2 = np.mean(np.square(dv_sig2^2))
    # Cálculo
    act = s0
    mob = s1/s0
    com = np.sqrt((s2/s1)-(s1/s0))
    return act,mob,com
    

