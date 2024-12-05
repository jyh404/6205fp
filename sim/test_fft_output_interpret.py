with open("simulation_output.txt","r") as z:
    data = z.read().split("\n")

magnitudes = []

for i in range(512):
    data_re = data[i][1:33]
    data_im = data[i][35:67]
    #print(data_im)
    if (i<10):
        print(data_re,data_im)
    data_re = (int(data_re,2)^(1<<31))-(1<<31)
    data_im = (int(data_im,2)^(1<<31))-(1<<31)
    #print(data_im)
    data_mag = int((data_re**2+data_im**2)**0.5)
    if (i<10):
        print(data_re,data_im,data_mag)
    magnitudes += [data_mag]

with open("simulation_processed.txt","w") as z:
    for i in range(512):
        z.write(str(magnitudes[i])+"\n")
