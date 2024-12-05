import serial
import wave


# opens serial port, waits for 6 seconds of 8kHz audio data, writes it to output.wav

# set to proper serial port name and WAV!
# find the port name using test_ports.py
# CHANGE ME
SERIAL_PORT_NAME = "/dev/ttyUSB1"
BAUD_RATE = 230400
TIME_SECONDS = 6

ser = serial.Serial("/dev/ttyUSB1",230400)
print("Serial port initialized")

print("Recording ",TIME_SECONDS," seconds of audio:")
ypoints = []
for i in range(16000*TIME_SECONDS):
    val = int.from_bytes(ser.read(),'little')
    if ((i+1)%16000==0):
        print(f"{(i+1)/16000} seconds complete")
    ypoints.append(val)

with open("output.txt","w") as z:
    for point in ypoints:
        z.write(str(point)+"\n")

with wave.open('output.wav','wb') as wf:
    wf.setframerate(16000)
    wf.setnchannels(1)
    wf.setsampwidth(1)
    samples = bytearray(ypoints)
    wf.writeframes(samples)
    print("Recording saved to output.wav")

