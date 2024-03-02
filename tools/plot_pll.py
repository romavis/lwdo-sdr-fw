#!/usr/bin/env python3

import sys
import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as sig


data = np.genfromtxt(sys.argv[1], delimiter=',')

data_t = data[:, 0]
data_valid = data[:, 1]
data_err_cyc = data[:, 2]
data_err_rel = data[:, 3]
data_pid_p = data[:, 4]
data_pid_i = data[:, 5]
data_tune = data[:, 6]
data_tune_int = data[:, 7]

# np.median
mf = sig.medfilt(data_err_cyc, 9)

fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True)
ax1.plot(data_t, data_err_cyc)
ax1.plot(data_t, mf)
ax1.set_title('error_cyc')
ax1.grid()
ax2.plot(data_t, data_tune_int)
ax2.set_title('dac_control')
ax2.grid()
fig.tight_layout()
plt.show()
