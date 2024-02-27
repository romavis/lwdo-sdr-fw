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
        self, p_gain: float, i_gain: float, d_gain: float, integrator_clip: float = 1e-1
    ):
        assert p_gain >= 0
        assert i_gain >= 0
        assert d_gain >= 0
        self._integrator_clip = abs(integrator_clip)
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
        dy = min(max(dy, -self._integrator_clip), self._integrator_clip)
        i = self._zs_yint + dy
        self._i = min(max(i, -self._integrator_clip), self._integrator_clip)
        # differential
        self._d = (err - self._zs_x) * z_kd
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
        self.ftdi.set_latency_timer(10)
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
    TDC_GATE_FREQ = 10  # TDC reports at 10 Hz
    VCXO_RANGE = 10e-6  # +-10ppm
    VCXO_PID1_PGAIN = 0.0050
    VCXO_PID1_IGAIN = 0.0001
    VCXO_PID1_DGAIN = 0
    VCXO_FAST_TUNE_ABOVE = 1000e-6

    REG_SYS_CON = 0x08
    REG_TDC_CON = 0x40
    REG_FTUN_VTUNE_SET = 0x80

    def __init__(self, ftdi_url: str):
        self.iface = LwdoInterface(ftdi_url, self)
        # TDC
        self.tdc_time = 0
        self.tdc_pd = TDCPhaseDetector()
        self.tdc_tprev = 0
        # VCTCXO PLL
        self.vcxo_pid1 = PID(
            self.VCXO_PID1_PGAIN,
            self.VCXO_PID1_IGAIN,
            self.VCXO_PID1_DGAIN,
            100e-6,
        )
        # Init comms - send empty packet (so called wbcon null operation)
        self.iface.write(b"")
        # Reset
        self.iface.write(bytes([0x21, self.REG_SYS_CON]))
        self.iface.write(bytes([0x22, 0x01]))  # RST
        # Enable TDC
        self.iface.write(bytes([0x21, self.REG_TDC_CON]))
        self.iface.write(bytes([0x22, 0b11]))  # MEAS_FAST, EN

    def stop(self):
        self.iface.stop()

    def update_vcxo_pll(self, tdc: TDCMeasurement):
        self.tdc_time += 1.0 / self.TDC_GATE_FREQ
        meas_err_cyc = self.tdc_pd.process_meas(tdc)

        valid = False
        meas_err_rel = math.nan
        pid1 = math.nan
        pid2 = math.nan
        dt = 0
        if meas_err_cyc is not None:
            valid = True
            dt = self.tdc_time - self.tdc_tprev
            self.tdc_tprev = self.tdc_time
            meas_err_rel = meas_err_cyc / tdc.t0
            self.vcxo_pid1.update(dt, meas_err_rel)
        # Fast retuning
        fast = 0
        if valid and meas_err_rel > self.VCXO_FAST_TUNE_ABOVE:
            # Decrease gate frequency by fiddling with the TDC divider
            fast = -1
            self.vcxo_pid1.reset()
            self.iface.write(bytes([0x21, self.REG_TDC_CON]))
            self.iface.write(bytes([0x22, 0b0111]))
        elif valid and meas_err_rel < -self.VCXO_FAST_TUNE_ABOVE:
            # Increase gate frequency by fiddling with the TDC divider
            fast = 1
            self.vcxo_pid1.reset()
            self.iface.write(bytes([0x21, self.REG_TDC_CON]))
            self.iface.write(bytes([0x22, 0b1011]))
        else:
            # Stop fast tuning
            self.iface.write(bytes([0x21, self.REG_TDC_CON]))
            self.iface.write(bytes([0x22, 0b0011]))
        tune_ppm = -self.vcxo_pid1.output
        # convert tuning to register scale
        tune_int = int((tune_ppm / (2 * self.VCXO_RANGE) + 0.5) * 0x1000000)
        tune_int = min(max(tune_int, 0), 0xFFFFFF)
        # Update VCXO tuning reg
        tune_bytes = tune_int.to_bytes(3, 'little', signed=False)
        self.iface.write(bytes([0x21, self.REG_FTUN_VTUNE_SET]))
        self.iface.write(bytes([0x22]) + tune_bytes)
        # elaborate logs
        logger.info(
            "[VCXO PLL] T={:9.3f}: meas_err_cyc={:<15.0f}{:s}  meas_err_ppm={:<14.5f} pid_p={:<14.5f} pid_i={:<14.5f} tune_ppm={:<14.5f} tune_int={:06x} {:s}".format(
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
    args = parser.parse_args()

    # Open FTDI and set it to SyncFIFO mode
    url = args.device
    logger.info(f"Using FTDI URL='{url}'")
    lwdo = LwdoDriver(url)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass
    lwdo.stop()


if __name__ == "__main__":
    main()
