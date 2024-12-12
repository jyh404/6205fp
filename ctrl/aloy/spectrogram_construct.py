import wave

full_data = []
#manipulation has been done to start with 255,255,255,255

TAG = "postfinal6"
with open(TAG+".txt", "r") as z:
    full_data = z.read().split("\n")
print(len(full_data), len(full_data)//42000, "seconds")

NUMBER_PACKETS = len(full_data)//420 #take 100*number of seconds of recording


formantpoints = []
apoints = []
fpoints = []
for _ in range(NUMBER_PACKETS):
    packet = full_data[:420]
    packet = [int(ltr) for ltr in packet]
    full_data = full_data[420:]
    assert packet[0]==255
    assert packet[1]==255
    assert packet[2]==255
    assert packet[3]==255
    fpoints.extend(packet[4:260])
    formantpoints.extend([packet[2*i+5]*256+packet[2*i+4] for i in range (5)])
    """
    fpoints_pre = packet[4:260]
    for i in range(256):
        j = format(i,"08b")
        j = j[::-1]
        j = int(j,2)
        fpoints += [fpoints_pre[j]] #take multiples of 31.25 from 1.
    """
     
    """
    #extract fourier coeff from UART'd output
    with open("fourier.txt","w") as z:
        for point in fpoints:
            z.write(str(point)+"\n")
    """

    #extract audio from UART'ed output
    apoints.extend(packet[260:420])

with open(TAG+'_formants.txt','w') as z:
    for i in (formantpoints[:-1]):
        z.write(str(i)+"\n")
    z.write(str(formantpoints[-1]))

with open(TAG+'_f.txt','w') as z:
    for i in (fpoints[:-1]):
        z.write(str(i)+"\n")
    z.write(str(fpoints[-1]))

with wave.open(TAG+'_output.wav','wb') as wf:
    wf.setframerate(16000)
    wf.setnchannels(1)
    wf.setsampwidth(1)
    samples = bytearray(apoints)
    wf.writeframes(samples)
    print("Recording saved to output.wav")
