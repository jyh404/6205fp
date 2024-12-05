# plan:
# 1) force people to state "vowel of interest" at start, need to extract out formants, reference "wanna"
# 2) compute intensity, need to make some cutoff value (relative to 'n' in wanna)
# -- see https://diu.edu/wp-content/uploads/steve_parker/Parker-dissertation.pdf
# 3) if intensity > cutoff, then just frame shift fourier transform to peak at right places (based on formants in 1)
# -- ifft into sequence, write to .wav
# 4) otherwise, save to wav
# things to read: 
# -- what is mfcc: https://www.youtube.com/watch?v=4_SH2nfbQZ8
# -- source-filter: https://courses.grainger.illinois.edu/ece417/fa2018/ece417fa2018lecture11.pdf
# -- darla transcription: http://darla.dartmouth.edu/
# -- vowel qualities from mfccs: https://www.aisv.it/StudiAISV/2018/vol_4/001_Iskarous.pdf

from scipy.io import wavfile
from scipy.fft import fft, fftfreq, ifft
import numpy as np
import matplotlib.pyplot as plt

## editing
def editing():
    rate, data = wavfile.read("output.wav")
    wavfile.write("vowel.wav", rate, data[int(rate*4.5):rate*6])
    wavfile.write("ref_wanna.wav", rate, data[int(rate*1.5):int(rate*2.25)])
    wavfile.write("sample.wav", rate, data[int(rate*6.5):])

## find vowel fft

def vowel_window():
    rate, data = wavfile.read("vowel.wav")
    ## make assumption: just try to fft every window of 25 ms, eventually some window will have nice formants since we are a vowel sound
    window_time = 0.025 # in s
    window_len = int(rate * window_time) # in samples
    avg = np.mean(data)
    # data = data - avg
    # print(window_len)
    for i in range(len(data)//window_len - 1):
        data_fft = fft(data[i*window_len : (i+1)*window_len] - avg) ## trim dc offset, noisy signal
        freq_fft = fftfreq(window_len, 1/rate)[:window_len//2]
        plt.plot(freq_fft, np.log(abs(data_fft[:window_len//2])))
        plt.savefig(f"img/vowel/group_{i}.png")
        plt.close()
    ## based on looking at the graphs of the fft, a reasonable thing to do is "if the maximum abs of a coefficient in the 2000-4000Hz A_range is 
    ## a magnitude of e greater than the maximum abs of a coefficient in the 5000-8000Hz B_range, then this is a good snapshot"

    def freq_to_index(freq):
        ## recall our window len is the number of indices in the fft
        ## these correspond to frequencies 0 to rate/2 at least for the first half
        return int((freq/(rate/2)) * window_len/2)

    for i in range(len(data)//window_len - 1):
        data_fft = fft(data[i*window_len : (i+1)*window_len] - avg)
        A_range_max = np.max(data_fft[freq_to_index(2000):freq_to_index(4000)])
        B_range_max = np.max(data_fft[freq_to_index(5000):freq_to_index(8000)])
        if np.log(A_range_max) >= B_range_max + 1.5:
            # good window
            print(f"vowel sample taken from window {i}, which is time {i*window_time} to {(i+1)*window_time} in seconds")
            wavfile.write("vowel_window.wav", rate, data[i*window_len:(i+1)*window_len])
            break

# vowel_window()

## find formants: ignore for now

## replace all vowels, using same trick as before

rate, data = wavfile.read("sample.wav")
vowel_rate, vowel_data = wavfile.read("vowel_window.wav")

assert vowel_rate == rate

# print(type(data), data.dtype)

# # trim dc offset
# avg = np.mean(data)
# data = data - avg

# start writing in terms of windows
window_time = 0.025 # in s
window_len = int(rate * window_time) # in samples
new_data = []

# look at what the ffts look like this time with consonants
# for i in range(len(data)//window_len - 1):
#     data_fft = fft(data[i*window_len : (i+1)*window_len]) ## trim dc offset, noisy signal
#     freq_fft = fftfreq(window_len, 1/rate)[:window_len//2]
#     plt.plot(freq_fft, np.log(abs(data_fft[:window_len//2])))
#     plt.savefig(f"img/sample/group_{i}.png")
#     plt.close()

def freq_to_index(freq):
    ## recall our window len is the number of indices in the fft
    ## these correspond to frequencies 0 to rate/2 at least for the first half
    return int((freq/(rate/2)) * window_len/2)

for i in range(len(data)//window_len - 1):
    data_fft = fft(data[i*window_len : (i+1)*window_len])
    A_range_max = np.max(data_fft[freq_to_index(2000):freq_to_index(4000)])
    B_range_avg = np.mean(data_fft[freq_to_index(5000):freq_to_index(8000)])
    if np.log(A_range_max) >= B_range_avg + 1:
        # good window, interpret this as a vowel
        print(f"window {i} is a vowel, which is time {i*window_time} to {(i+1)*window_time} in seconds")
        new_data.extend(vowel_data)
    else:
        new_data.extend(data[i*window_len : (i+1)*window_len])

new_data = np.array(new_data, dtype="uint8")

wavfile.write("sample_with_vowel.wav", rate, new_data)