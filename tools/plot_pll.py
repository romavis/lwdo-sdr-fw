#!/usr/bin/env python3

import sys
import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as sig


data = np.genfromtxt(sys.argv[1], delimiter=',')

TDC_GATE_FREQ = 100

data_t = data[:, 0]
data_valid = data[:, 1]
data_err_cyc = data[:, 2]
data_err_rel = data[:, 3]
data_pid_p = data[:, 4]
data_pid_i = data[:, 5]
data_tune = data[:, 6]
data_tune_int = data[:, 7]

fig, ax = plt.subplots(3, 1, sharex=True)
ax[0].plot(data_t, data_err_cyc)
ax[0].set_title('error_cyc')
ax[0].grid()
ax[1].plot(data_t, (data_err_rel * 1 / TDC_GATE_FREQ) * 1e9)
ax[1].set_title('error_ns')
ax[1].grid()
ax[2].plot(data_t, data_tune_int)
ax[2].set_title('dac_control')
ax[2].grid()
fig.tight_layout()
plt.show()
