import math
import functools

TAG = "log_scaled"

with open(TAG+"_f.txt", "r") as z:
    spec_data = z.read().split("\n")

I = 160
NUMBER_SEGMENTS = 5
eps = 0.01

#We attempt compression by finding the boundary
#using a slightly modified F and B
COMP = 1

#order is in natural order
spec_data = [pow(2,int(coef)/8) for coef in spec_data]
#spec_data = [int(coef) for coef in spec_data]

#take the first packet for now
NUMBER_FRAMES = len(spec_data)//256

all_formants = []

for index in range(NUMBER_FRAMES):
    print("PACKET", str(index))
    freq_packet = spec_data[:256]
    freq_packet = freq_packet[::-1]
    spec_data = spec_data[256:]
    freq_packet = freq_packet[:I]

    #freq_packet_comp = [sum(freq_packet[i:i+COMP]) for i in range(0,256,COMP)]


    #now we use the DP algorithm proposed by Lutz and Hermann
    #in Formant Estimation for Speech Recognition
    #particularly because root finding and matrix manipulation is kinda bad

    #initialisation

    #calculate Ti
    @functools.cache
    def T(nu,i):
        total = 0
        for j in range(0,i+1):
            total += freq_packet[j]*math.cos(2*math.pi*nu*j/2/I)
        return total/(I+1) #because power of 2. also scaling doesnt change.

    #actually r in the document
    @functools.cache
    def tau(nu,j,i):
        assert i>=j
        return T(nu,i)-T(nu,j)    

    #compute Emin[j,i] for 0<=j<=i<=I, I=255
    @functools.cache
    def Em(j,i):
        a = tau(0,j,i)
        b = tau(1,j,i)
        c = tau(2,j,i)
        try:
            #print((a*(a*a-b*b)-b*(a*b-b*c)-c*(a*c-b*b))/(a*a-b*b+eps))
            return (a*(a*a-b*b)-b*(a*b-b*c)-c*(a*c-b*b))/(a*a-b*b+eps)
        except ZeroDivisionError:
            return 0
        #+0.01 is my brain dead way of avoiding/0 issues



    F = [[10**9 for _ in range((I+1)//COMP)] for _ in range(NUMBER_SEGMENTS)]
    B = [[-1 for _ in range((I+1)//COMP)] for _ in range(NUMBER_SEGMENTS)]
    F[0][0] = 0

    #for freq in range(0,I//COMP):
    for freq in range (50): #for debug
        #easier comparison
        seg = 1
        F[seg-1][freq] = Em(0,freq*COMP)
        B[seg-1][freq] = 0 #the location of the previous segment break
        
        for seg in range(2,NUMBER_SEGMENTS+1):
            #finding the value for F each time.
            for check_freq in range(seg-1,freq):
                if F[seg-2][check_freq+1]+Em((check_freq+1)*COMP,freq*COMP)<F[seg-1][freq]:
                    F[seg-1][freq] = F[seg-2][check_freq+1]+Em((check_freq+1)*COMP,freq*COMP)
                    B[seg-1][freq] = check_freq
            pass

    traceback = [0 for _ in range(NUMBER_SEGMENTS+1)]
    traceback[-1] = I//COMP-1 #the maximum

    for step in range(NUMBER_SEGMENTS):
        traceback[-step-2] = B[-step-1][traceback[-step-1]]


    print(traceback)
    def phi(j,i):
        a = tau(0,j*COMP,i*COMP)
        b = tau(1,j*COMP,i*COMP)
        c = tau(2,j*COMP,i*COMP)
        ak = (a*b-b*c)/(a*a-b*b+eps)
        bk = (a*c-b*b)/(a*a-b*b+eps)
        print((a*(a*a-b*b)-b*(a*b-b*c)-c*(a*c-b*b))/(a*a-b*b+eps))
        #print(a,b,c,ak,bk)
        #print(ak,bk,(-ak*(1-bk)+eps)/4/(bk+eps))
        try:
            return math.acos((-ak*(1-bk)+eps)/4/(bk+eps))/math.pi*5000+31.25 
        except ValueError:
            print("F in ValueError")
            return math.acos(0)
        #take phase angle and scale by maximum frequency (8000)
        #we may be off by abit but w/e for now, ok shifting
        #yeah the extra sample really gives a 31.25 shift LOL

    formants_found = tuple(int(phi(traceback[step],traceback[step+1])) for step in range(NUMBER_SEGMENTS))
    all_formants += [formants_found]
    #for step in range(NUMBER_SEGMENTS):
        #formants_found += [()]
        #print("Formant",str(step+1),str(phi(traceback[step],traceback[step+1])),"Hz")
    #print(str(phi(traceback[0],traceback[1])),"Hz")

with open(TAG+"_p.txt","w") as z:
    for i in all_formants[:-1]:
        z.write(str(i)+"\n")
    z.write(str(all_formants[-1]))
