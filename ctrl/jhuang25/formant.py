## https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=650308

from scipy.io import wavfile
from scipy.fft import fft, fftfreq, ifft
import numpy as np
import matplotlib.pyplot as plt

rate, data = wavfile.read("audio/vowel.wav")

## find windows of size 25 ms every 10 ms
window_len = 0.025 # s
window_interval = 0.010 # s
N = len(data)
windows = []
for i in range(0, N, window_interval * rate):
    if i + window_len * rate < N: # the window starting at sample i fits
        windows.append(np.array(data[i:i+window_len*rate]))

## compute first order differences
window_diffs = []
for i in range(len(windows) - 1):
    window_diffs.append(windows[i+1]-windows[i])

## focus on 0th window_diffs

data = np.concatenate((data, np.zeros(FFT_SIZE - len(data))))
data *= np.hamming(FFT_SIZE)

s = fft(data)

freq_fft = fftfreq(FFT_SIZE, 1/rate)[:FFT_SIZE//2]
plt.plot(freq_fft, np.log(abs(s[:FFT_SIZE//2])))
plt.savefig(f"formant/vowel_fft_hamming.png")
plt.close()