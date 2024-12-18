import matplotlib.pyplot as plt
import numpy as np
import wave
import math

TAG = "postfinal6"
LOG_NEEDED = False

spec_data = []
with open(TAG+"_f.txt","r") as z:
    spec_data = z.read().split("\n")

SECONDS = (len(spec_data)//256)//100

audio_data = []
with wave.open(TAG+"_output.wav","rb") as z:
    audio_data = z.readframes(16000*SECONDS)

audio_data = [int(x) for x in audio_data]

formant_data = []
with open(TAG+"_formants.txt","r") as z:
    formant_data = z.read().split("\n")
formant_data = [int(i) for i in formant_data]

#for board formants
formants = [formant_data[5*i:5*i+5] for i in range (100*SECONDS)]

#formants = []
#with open(TAG+"_p.txt","r") as z:
#    formants = z.read().split("\n")
#formants = [[int(val) for val in formant[1:-1].split(", ")] for formant in formants]
#print(formants[0])

#scaled to log for plotting
#spec_data = [math.log(int(i)+1) for i in spec_data]

spec_data = [int(i) for i in spec_data]
print(len(spec_data))
FRAMES = len(spec_data)//256

spec_processed = np. array(spec_data).reshape(FRAMES,-1)
spec_processed = np.swapaxes(spec_processed,0,1)

#NFFT = 256  # the length of the windowing segments
#Fs = 16000  # the sampling frequency

#fig, (ax1,ax2,ax3) = plt.subplots(3)
fig, (ax1,ax3) = plt.subplots(2) #drop the specgram plot...

#Pxx, freqs, bins, im = ax2.specgram(audio_data, NFFT=NFFT, Fs=Fs)

ax1.set_xlabel('Time (8000/s)')
ax1.set_ylabel('Frequency (Hz)')


ax1.imshow(spec_processed, extent = [0,SECONDS*8000,0,8000])
#ax1.set(xticks=np.linspace(0, SECONDS*8000, SECONDS+1),
#       xticklabels=np.arange(0, SECONDS+1, 1),
#       yticks=np.linspace(0, 8000, 9),
#       yticklabels=np.arange(0, 8001, 1000))

#magnitude used here
#ax2.specgram(audio_data, mode="magnitude")

#plotting the F1 over time
ax3.plot(np.arange(0, SECONDS*100,1), formants)
plt.show()
