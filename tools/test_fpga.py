#!/usr/bin/env python3

import argparse, logging, sys, time
from typing import Iterable
from pyftdi.ftdi import Ftdi

logger = logging.getLogger(__name__)

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
    ftdi = Ftdi()
    print(f"Opening {url!r} and switching to SyncFIFO")
    ftdi.open_from_url(url)
    ftdi.reset()
    ftdi.set_bitmode(0, Ftdi.BitMode.RESET)
    ftdi.set_bitmode(0, Ftdi.BitMode.SYNCFF)
    ftdi.set_latency_timer(50)
    ftdi.purge_buffers()

    def recv_and_log(nbytes: int = 4096) -> bytes:
        d = ftdi.read_data(nbytes)
        s = ' '.join(f'{x:02x}' for x in d)
        logger.info(f'Received {len(d)} bytes: [{s}]')
        return d

    def log_and_send(data: Iterable[int]):
        data = bytes(data)
        s = ' '.join(f'{x:02x}' for x in data)
        logger.info(f'Sending {len(data)} bytes: [{s}]')
        ftdi.write_data(data)

    # Now let's talk..
    recv_and_log()
    log_and_send([])
    recv_and_log()
    log_and_send([0xc0, 0xc0])
    recv_and_log()
    # log_and_send([0x21, 0x00, 0x00, 0xc0])
    # recv_and_log()
    # log_and_send([0x23, 0xc0])
    # recv_and_log()
    # log_and_send([0x23, 0xc0])
    # recv_and_log()
    # log_and_send([0x21, 0x02, 0x00, 0xc0])
    # recv_and_log()
    # log_and_send([0x23, 0xc0])
    # recv_and_log()
    # log_and_send([0x21, 0x00, 0x01, 0xc0])
    # recv_and_log()
    # log_and_send([0x23, 0xc0])
    recv_and_log()
    recv_and_log()

    print("Done.")


if __name__ == "__main__":
    main()
