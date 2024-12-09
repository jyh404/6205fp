from math import cos, pi

I = 160

for i in range(2*I):
    val = cos(i * pi / I) / I
    hex = format(int(val * (1<<31) + (1<<31)), '032b')
    chars = [hex[j] for j in range(32)]
    chars[0] = '1' if chars[0] == '0' else '0' # flip
    res = ""
    for j in range(32):
        res += chars[j]
    print(f"assign lookup[{i}] = 32'h{int(res,2):08x}; // {i} {val}")