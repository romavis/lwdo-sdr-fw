#!/usr/bin/env python3

import argparse, logging, sys, time, abc
from typing import Iterable, Optional
from pyftdi.ftdi import Ftdi
import threading
import math


logger = logging.getLogger("lwdo")


class TDCMeasurement:
    """
    Represents a single measurement of a TDC - a Time-to-Digital Converter
    """

    def __init__(self, t0: int, t1: int, t2: int, t12_valid: bool) -> None:
        assert t0 >= 0
        self.t0 = t0
        self.t1 = t1
        self.t2 = t2
        self.t12_valid = t12_valid
        if t12_valid:
            assert 0 <= t1 <= t0
            assert 0 <= t2 <= t0

    def __str__(self) -> str:
        if self.t12_valid:
            return f"(t0={self.t0:08x}, t1={self.t1:08x}, t2={self.t2:08x})"
        else:
            return f"(t0={self.t0:08x})"


class TDCPhaseDetector:
    """
    Converts TDC measurements into phase difference readings
    """

    def __init__(self):
        self._first = True
        self._prev_t12_avail = False
        self._prev_ct0 = 1
        self._prev_ct2 = 0
        self._prev_mp = 0

    def process_meas(self, meas: TDCMeasurement) -> Optional[int]:
        # Two pulse signals: S0 and S1
        #   Sc - high-frequency counting clock
        #   S0 - gate signal (sequence of pulses)
        #   S1 - reference signal (sequence of pulses)
        #   S0, S1 pulses are each 1x Sc pulse wide.
        # The counter CX counts +1 in each Sc cycle, except in a cycle when
        # S0 is 1 – in that cycle counter is reset to 0. The counter reset marks
        # the end of a previous counting interval and the beginning of a new
        # counting interval. Specifically, the first cycle of the interval is
        # the one in which S0==1, and the last cycle is the one immediately
        # preceding the one in which S0==1. These two cycles can be the same
        # cycle if S0 period is equal to 1 (S0 is constantly set to 1).
        # The logic circuitry around the counter records following counter values:
        #   T0 - value of CX in the last cycle of the interval.
        #   T1 - value of CX in the cycle that S1==1 for the first time within the
        #       interval.
        #   T2 - value of CX in the cycle that S1==1 for the last time within the
        #       interval.
        # Notes:
        #   T0-T2 recordings are taken during each counting interval, and are
        #       transmitted on the first cycle of the next counting interval.
        #   T0 is always recorded and available.
        #   T1-T2 may not be available (e.g. if S1==1 was never observed during
        #       the counting interval). Each T0-T2 recording contains extra data
        #       that allows to detect if this is the case.
        ct0 = meas.t0 + 1
        ct2 = ct0 - meas.t2
        mp = ct0 // 2  # midpoint

        # Left-hand (negative) candidate – comes from T2 point of the previous
        # interval.
        cn = self._prev_ct2
        cn_valid = self._prev_t12_avail and cn <= self._prev_mp
        # Right-hand (non-negative) candidate – comes from T1 point of the
        # current interval.
        cp = meas.t1
        cp_valid = meas.t12_valid and cp < mp

        # Decide which to use
        px = 0
        px_valid = False
        if cp_valid and cn_valid:
            cp_valid = cp <= cn
        if cp_valid:
            px = cp
            px_valid = True
        elif cn_valid:
            px = -cn
            px_valid = True

        self._prev_t12_avail = meas.t12_valid
        self._prev_ct0 = ct0
        self._prev_ct2 = ct2
        self._prev_mp = mp

        # Skip first measurement
        px_valid = px_valid and not self._first
        self._first = False
        # Return error in clock cycles
        if px_valid:
            return px
        return None


class PID:
    """
    PID controller
    """

    def __init__(
        self, p_gain: float, i_gain: float, d_gain: float, limit: float = 1e-1
    ):
        assert p_gain >= 0
        assert i_gain >= 0
        assert d_gain >= 0
        self._limit = abs(limit)
        self._kp = p_gain
        self._ki = i_gain
        self._kd = d_gain
        self._zs_yint = 0.0
        self._zs_x = 0.0
        self._p = 0.
        self._i = 0.
        self._d = 0.

    def reset(self):
        self._zs_yint = 0.0
        self._zs_x = 0.0
        self._p = 0.
        self._i = 0.
        self._d = 0.

    def force(self, pos: bool = True):
        """
        Override PID state to force the output to either
        +LIM (pos=True) or -LIM (pos=False).
        """
        self._p = 0
        self._d = 0
        self._i = self._limit if pos else -self._limit

    def update(self, dt: float, err: float):
        """
        See:
         https://e2e.ti.com/cfs-file/__key/communityserver-discussions-components-files/171/Discrete-PID-controller.pdf

        dt - in seconds
        """
        assert dt > 0

        z_kp = self._kp
        z_ki = dt * self._ki
        z_kd = self._kd / dt

        # proportional
        self._p = err * z_kp
        # integral
        dy = 0.5 * (err + self._zs_x) * z_ki
        dy = min(max(dy, -self._limit), self._limit)
        i = self._zs_yint + dy
        i = min(max(i, -self._limit), self._limit)
        self._i = i
        # differential
        d = (err - self._zs_x) * z_kd
        d = min(max(d, -self._limit), self._limit)
        self._d = d
        # States update
        self._zs_yint = i
        self._zs_x = err

    @property
    def output(self) -> float:
        return self._p + self._i + self._d

    @property
    def p(self) -> float:
        return self._p

    @property
    def i(self) -> float:
        return self._i

    @property
    def d(self) -> float:
        return self._d


class LwdoReadHandler:
    @abc.abstractmethod
    def handle_rx(self, stream: int, data: bytes): ...


class LwdoInterface:
    SLIP_END = bytes((0xC0,))
    SLIP_ESC = bytes((0xDB,))
    SLIP_ESC_END = bytes((0xDC,))
    SLIP_ESC_ESC = bytes((0xDD,))

    def __init__(self, ftdi_url: str, read_handler: Optional[LwdoReadHandler] = None):
        # init FTDI
        self.ftdi = Ftdi()
        self.ftdi.open_from_url(ftdi_url)
        self.ftdi.reset()
        self.ftdi.set_bitmode(0, Ftdi.BitMode.RESET)
        self.ftdi.set_bitmode(0, Ftdi.BitMode.SYNCFF)
        self.ftdi.set_latency_timer(2)
        # Read thread
        self.rdt_stop = threading.Event()
        self.rdt = threading.Thread(target=self.read_thread)
        self.rdt.start()
        # SLIP decoder state
        self.slip_tmp = bytearray()
        # Read handler
        self.read_handler = read_handler

    def stop(self):
        self.rdt_stop.set()
        self.rdt.join()

    def read_thread(self):
        logger.debug(f"Reader thread {id(self)} starting")
        while True:
            try:
                data = self.ftdi.read_data(self.ftdi.read_data_get_chunksize())
                pkts = (self.slip_tmp + data).split(self.SLIP_END)
                assert len(pkts) >= 1
                for pkt in pkts[:-1]:
                    pkt = pkt.replace(self.SLIP_ESC + self.SLIP_ESC_END, self.SLIP_END)
                    pkt = pkt.replace(self.SLIP_ESC + self.SLIP_ESC_ESC, self.SLIP_ESC)
                    if not pkt:
                        logger.debug("Rx: empty packet received")
                    else:
                        if self.read_handler is not None:
                            self.read_handler.handle_rx(pkt[0], pkt[1:])
                self.slip_tmp = pkts[-1]
            except Exception as e:
                logger.exception("FTDI read thread caught exception")
                raise SystemExit from e
            if self.rdt_stop.is_set():
                break

    def write(self, data: bytes):
        logger.debug(f'Tx: [{data.hex(" ")}]')
        # SLIP
        data = data.replace(self.SLIP_ESC, self.SLIP_ESC + self.SLIP_ESC_ESC)
        data = data.replace(self.SLIP_END, self.SLIP_ESC + self.SLIP_ESC_END)
        data = data + self.SLIP_END
        # Send
        self.ftdi.write_data(data)


class LwdoDriver(LwdoReadHandler):
    TDC_GATE_FREQ = 100  # TDC reports at 10 Hz
    TDC_COUNT_FREQ = 80e6   # average
    VCXO_RANGE = 2.5e-6  # VCTXO tuning range is f0-RANGE..f0+RANGE
    VCXO_DPLL_TAU = 10
    VCXO_DPLL_QFACTOR = 0.707
    VCXO_DPLL_HF_ERROR_GAIN = 1 # don't change this, PID KD must be 0 otherwise output is too noisy
    VCXO_DPLL_FAST_TUNE_ABOVE = 5000e-6

    REG_SYS_CON = 0x08
    REG_TDC_CON = 0x40
    REG_FTUN_VTUNE_SET = 0x80
    REG_PPS_CON = 0x0a0
    REG_PPS_RATE = 0x0a4
    REG_PPS_PWIDTH = 0x0a8
    REG_IO_CLKOUT = 0x0c0

    def __init__(self, ftdi_url: str, pll_trace_file: Optional[str] = None, pll_step_test: bool = False):
        self.iface = LwdoInterface(ftdi_url, self)
        # TDC
        self.tdc_time = 0
        self.tdc_pd = TDCPhaseDetector()
        self.tdc_tprev = 0
        # VCTCXO PLL
        # Calculate PID coefs from time constant TAU and quality factor QFACTOR
        assert self.VCXO_DPLL_TAU > 0
        assert self.TDC_GATE_FREQ > 0
        assert 0 < self.VCXO_DPLL_HF_ERROR_GAIN <= 1
        pid_wn = 1 / self.VCXO_DPLL_TAU
        pid_w0 = 2 * math.pi * self.TDC_GATE_FREQ
        pid_d = (1 / self.VCXO_DPLL_HF_ERROR_GAIN - 1) / pid_w0
        pid_i = (pid_wn ** 2 / pid_w0) * (1 + pid_w0 * pid_d)
        pid_p = (pid_wn / (pid_w0 * self.VCXO_DPLL_QFACTOR)) * (1 + pid_w0 * pid_d)
        pid_lim = self.VCXO_RANGE
        logger.info(f'Using PID params: KP={pid_p:e}, KI={pid_i:e}, KD={pid_d:e}, limit={pid_lim:e}')
        self.vcxo_pid1 = PID(
            pid_p,
            pid_i,
            pid_d,
            pid_lim,
        )
        # Trace file
        self.pll_trace_file = None
        if pll_trace_file:
            self.pll_trace_file = open(pll_trace_file, 'w')
        # PLL step response test
        self.pll_step_test = pll_step_test
        self.pll_step_test_rem = 3 * self.TDC_GATE_FREQ if pll_step_test else 0
        # Init comms - send empty packet (so called wbcon null operation)
        self.iface.write(b"")
        # Reset
        self.iface.write(bytes([0x21, self.REG_SYS_CON]))
        self.iface.write(bytes([0x22, 0x01]))  # RST
        # Enable TDC
        self.iface.write(bytes([0x21, self.REG_TDC_CON]))
        self.iface.write(bytes([0x22, 0b11]))  # MEAS_FAST, EN
        # Enable PPS
        self.iface.write(bytes([0x21, self.REG_PPS_RATE]))
        self.iface.write(bytes([0x22, 0x00, 0xB4, 0xC4, 0x04]))
        self.iface.write(bytes([0x21, self.REG_PPS_PWIDTH]))
        self.iface.write(bytes([0x22, 0x7F, 0x38, 0x01, 0x00]))
        self.iface.write(bytes([0x21, self.REG_PPS_CON]))
        self.iface.write(bytes([0x22, 0x01, 0x00, 0x00, 0x00]))
        # Configure CLK_OUT
        self.iface.write(bytes([0x21, self.REG_IO_CLKOUT]))
        self.iface.write(bytes([0x22, 2, 0, 0, 0x00]))


    def stop(self):
        self.iface.stop()

    def update_vcxo_pll(self, tdc: TDCMeasurement):
        self.tdc_time += 1.0 / self.TDC_GATE_FREQ
        meas_err_cyc = self.tdc_pd.process_meas(tdc)

        valid = False
        meas_err_rel = math.nan
        dt = 0
        if meas_err_cyc is not None:
            valid = True
            dt = self.tdc_time - self.tdc_tprev
            self.tdc_tprev = self.tdc_time
            meas_err_rel = meas_err_cyc / (dt * self.TDC_COUNT_FREQ) #/ tdc.t0
            self.vcxo_pid1.update(dt, -meas_err_rel)
        # Fast retuning - decision
        fast = 0
        if self.pll_step_test:
            # When step test is enabled, do fast tuning only during the "step" phase,
            # then disable
            if self.pll_step_test_rem:
                fast = -1
                # Force PID to +MAX
                self.vcxo_pid1.force()
        else:
            if valid and meas_err_rel > self.VCXO_DPLL_FAST_TUNE_ABOVE:
                fast = -1
            elif valid and meas_err_rel < -self.VCXO_DPLL_FAST_TUNE_ABOVE:
                fast = 1
        # Fast retuning - apply
        if fast < 0:
            # Decrease gate frequency by fiddling with the TDC divider
            self.iface.write(bytes([0x21, self.REG_TDC_CON]))
            self.iface.write(bytes([0x22, 0b0111]))
            # Reset PID when fast-tuning
            #self.vcxo_pid1.reset()
        elif fast > 0:
            # Increase gate frequency by fiddling with the TDC divider
            self.iface.write(bytes([0x21, self.REG_TDC_CON]))
            self.iface.write(bytes([0x22, 0b1011]))
            # Reset PID when fast-tuning
            #self.vcxo_pid1.reset()
        else:
            # Stop fast tuning
            self.iface.write(bytes([0x21, self.REG_TDC_CON]))
            self.iface.write(bytes([0x22, 0b0011]))
        tune_ppm = self.vcxo_pid1.output
        # convert tuning to register scale
        tune_int = int((tune_ppm / (2 * self.VCXO_RANGE) + 0.5) * 0x10000)
        tune_int = min(max(tune_int, 0), 0xFFFF)
        # Update VCXO tuning reg
        tune_bytes = tune_int.to_bytes(2, 'little', signed=False)
        self.iface.write(bytes([0x21, self.REG_FTUN_VTUNE_SET]))
        self.iface.write(bytes([0x22, 0x00]) + tune_bytes)
        # elaborate logs
        logger.info(
            "[VCXO PLL] T={:9.3f}: meas_err_cyc={:<+15.0f}{:s}  meas_err_ppm={:<14.5f} pid_p={:<14.5f} pid_i={:<14.5f} tune_ppm={:<14.5f} tune_int={:04x} {:s}".format(
                self.tdc_time,
                meas_err_cyc if valid else math.nan,
                " " if not valid else "#" if meas_err_cyc != 0 else ".",
                (meas_err_rel * 1e6) if valid else math.nan,
                self.vcxo_pid1.p * 1e6,
                self.vcxo_pid1.i * 1e6,
                tune_ppm * 1e6,
                tune_int,
                'FAST++' if fast > 0 else 'FAST--' if fast < 0 else ''
            )
        )
        if self.pll_trace_file:
            flog = f'{self.tdc_time:f},{1 if valid else 0},' \
                f'{meas_err_cyc if valid else 0:d},' \
                f'{meas_err_rel if valid else 0:e},' \
                f'{self.vcxo_pid1.p:e},{self.vcxo_pid1.i:e},' \
                f'{tune_ppm:e},{tune_int>>8:d}\n'
            self.pll_trace_file.write(flog)
        # PLL step test counter
        if self.pll_step_test_rem:
            self.pll_step_test_rem -= 1

    def handle_rx(self, stream: int, data: bytes):
        logger.debug(f'Rx {stream:02x} [{data.hex(" ")}]')
        if stream == 4:
            tdc_t0 = int.from_bytes(data[0:4], "little")
            tdc_t1 = int.from_bytes(data[4:8], "little")
            tdc_t2 = int.from_bytes(data[8:12], "little")
            tdc_t12_valid = tdc_t1 != 0xFFFFFFFF or tdc_t2 != 0xFFFFFFFF
            meas = TDCMeasurement(tdc_t0, tdc_t1, tdc_t2, tdc_t12_valid)
            logger.debug(f"TDC measurement: {meas}")
            self.update_vcxo_pll(meas)


def main():
    logging.basicConfig(
        stream=sys.stderr,
        level=logging.INFO,
        format='%(asctime)s.%(msecs)03d %(levelname)s %(module)s: %(message)s',
        datefmt='%H:%M:%S'
    )

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--device",
        type=str,
        help="Pyftdi USB device URL",
        default="ftdi://0x0403:0x6010/1",
    )
    parser.add_argument(
        "--pll_trace",
        type=str,
        help="Path at which we should store CSV PLL trace file",
    )
    parser.add_argument(
        "--pll_step_test",
        action='store_true',
        help="Enable PLL step response test",
    )
    args = parser.parse_args()

    # Open FTDI and set it to SyncFIFO mode
    url = args.device
    logger.info(f"Using FTDI URL='{url}'")
    lwdo = LwdoDriver(url, pll_trace_file=args.pll_trace, pll_step_test=args.pll_step_test)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass
    lwdo.stop()


if __name__ == "__main__":
    main()
