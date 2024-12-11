#This is code used to interpret the spectrogram packet
#Run spectrogram_construct and plotting after to see the graphs
#They are very cool.
#Making it appear live is a future goal, but I assume will not be hard.

import serial
import wave


# opens serial port, waits for 6 seconds of 8kHz audio data, writes it to output.wav

# set to proper serial port name and WAV!
# find the port name using test_ports.py
# CHANGE ME
SERIAL_PORT_NAME = "/dev/ttyUSB1"
BAUD_RATE = 460800
TIME_SECONDS = 3
OUT_PER_SECOND = 43000 #+10 for formants
# this needs to take all fourier and audio
# 160 audio and 256 fourier every 10 ms with some exception probably.
# easiest to use 1/2 often.
# send it up to process for now.

ser = serial.Serial("/dev/ttyUSB1",460800)
print("Serial port initialized")

print("Recording ",TIME_SECONDS," seconds of audio:")
ypoints = [255,255,255,255]

#conspire to only start recording when 255,255,255,255 received

start_valid = 0
while True:
    val = int.from_bytes(ser.read(),'little')
    if (val==255):
        start_valid += 1
    else:
        start_valid = 0
    if start_valid == 4:
        break
    
for i in range(OUT_PER_SECOND*TIME_SECONDS-4):
    val = int.from_bytes(ser.read(),'little')
    if ((i+1)%OUT_PER_SECOND==0):
        print(f"{(i+1)/OUT_PER_SECOND} seconds complete")
    ypoints.append(val)

fpoints = ypoints
#extract fourier coeff from UART'd output
with open("output.txt","w") as z:
    for point in fpoints[:-1]:
        z.write(str(point)+"\n")
    z.write(str(fpoints[-1]))


"""
#extract audio from UART'ed output
apoints = ypoints

with wave.open('output.wav','wb') as wf:
    wf.setframerate(16000)
    wf.setnchannels(1)
    wf.setsampwidth(1)
    samples = bytearray(apoints)
    wf.writeframes(samples)
    print("Recording saved to output.wav")
"""
