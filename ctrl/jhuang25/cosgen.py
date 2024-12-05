from math import cos, pi

I = 160

for i in range(2*I):
    val = cos(i * pi / I) / I
    hex = f"{(int(val*(1<<31))):08x}"
    # print(hex)
    # because things are so small they never come close to using
    # the first digit, so we are ok to check first digit for sign
    if hex[0] == '-':
        hex = '0' + hex[1:]
    elif hex[0] == '0' and i != 80 and i != 240: # should not be 0
        hex = '8' + hex[1:]
    print(f"assign lookup[{i}] = 32'h{hex}; // {i} {val}")