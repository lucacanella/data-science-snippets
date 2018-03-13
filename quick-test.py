import matplotlib.pyplot as plt
import scipy.fftpack as fft
import numpy as np
import math
import cmath

filter_threshold = 2.0
range_span = 2 * math.pi
g_range = np.arange(.0, range_span, .1)
# x = np.array([-1.0, .0, 1.0, -.8, -.1, .9, .0])
x = [1 + math.cos(_x) for _x in g_range]
y = fft.fft(x)
r = [f for f in y if ( abs(f) > filter_threshold )]

print('r', r)
print('r0', r[0])

#inverse fft
#invfft = fft.ifft(r)
#invfft

f1 = cmath.polar(r[0]) # [r, phi]
print('f1: ', f1)
g = [math.sin( f1[1] + i * f1[0] ) for i in g_range]
plt.plot(x, '-', g, '-')