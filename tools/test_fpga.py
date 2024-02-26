#!/usr/bin/env python3

import argparse, logging, sys, time
from typing import Iterable
from pyftdi.ftdi import Ftdi
import threading


logger = logging.getLogger('lwdo')


class LwdoInterface:
    SLIP_END = bytes((0xC0,))
    SLIP_ESC = bytes((0xDB,))
    SLIP_ESC_END = bytes((0xDC,))
    SLIP_ESC_ESC = bytes((0xDD,))

    def __init__(self, ftdi_url: str) -> None:
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

    def stop(self):
        self.rdt_stop.set()
        self.rdt.join()

    def read_handle_packet(self, pkt: bytes):
        if pkt:
            stream = pkt[0]
            data = pkt[1:]
            if stream in (4,):
                logger.info(f'Rx {stream:02x} [{data.hex(" ")}]')
        else:
            logger.info(f'Rx empty packet')

    def read_thread(self):
        logger.debug(f'Reader thread {id(self)} starting')
        while True:
            try:
                data = self.ftdi.read_data(self.ftdi.read_data_get_chunksize())
                pkts = (self.slip_tmp + data).split(self.SLIP_END)
                assert len(pkts) >= 1
                for pkt in pkts[:-1]:
                    pkt = pkt.replace(self.SLIP_ESC + self.SLIP_ESC_END, self.SLIP_END)
                    pkt = pkt.replace(self.SLIP_ESC + self.SLIP_ESC_ESC, self.SLIP_ESC)
                    self.read_handle_packet(pkt)
                self.slip_tmp = pkts[-1]
            except Exception as e:
                logger.exception('FTDI read thread caught exception')
                raise SystemExit from e
            if self.rdt_stop.is_set():
                break

    def write(self, data: bytes):
        logger.info(f'Tx: [{data.hex(" ")}]')
        # SLIP
        data = data.replace(self.SLIP_ESC, self.SLIP_ESC + self.SLIP_ESC_ESC)
        data = data.replace(self.SLIP_END, self.SLIP_ESC + self.SLIP_ESC_END)
        data = data + self.SLIP_END
        # Send
        self.ftdi.write_data(data)


def main():
    logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)
    logging.getLogger().setLevel(logging.DEBUG)

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
    logger.info(f'Using FTDI URL=\'{url}\'')
    lwdo = LwdoInterface(url)
    lwdo.write(b'')
    # VTUNE SET
    lwdo.write(bytes((0x21, 0xa0, 0x00,)))
    lwdo.write(bytes((0x23,)))
    lwdo.write(bytes((0x22, 0x90, 0x82)))
    lwdo.write(bytes((0x23,)))
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass
    lwdo.stop()


if __name__ == "__main__":
    main()
