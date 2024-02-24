#!/usr/bin/env python3

import argparse, logging, sys

from spiflash.serialflash import W25xFlashDevice
from pyftdi.spi import SpiController
from pyftdi.ftdi import Ftdi


class Pins:
    """FT2232H BDBUS pin map in LWDO-SDR"""

    SCK = 0x01
    DO = 0x02
    DI = 0x04
    CS = 0x08
    CNRESET = 0x10
    CDONE = 0x20
    CIO1 = 0x40
    CIO2 = 0x80


def main():
    logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)
    logging.getLogger().setLevel(logging.DEBUG)
    parser = argparse.ArgumentParser(
        description="Program LWDO-SDR FPGA bitstream into SPI flash chip"
        " over USB interface",
    )
    parser.add_argument(
        "bitstream",
        metavar="BITSTREAM.BIN",
        type=str,
        help="Path to a bitstream binary file",
    )
    parser.add_argument(
        "--device", "-d",
        type=str,
        help="Pyftdi USB device URL",
        default="ftdi://0x0403:0x6010/2",
    )
    parser.add_argument(
        "--freq", "-f",
        type=int,
        help="SPI frequency in Hz",
        default=1000000,
    )
    args = parser.parse_args()

    bsfile = args.bitstream
    url = args.device
    freq = args.freq

    # Read bitstream
    print(f"Reading bitstream from {bsfile!r}")
    with open(bsfile, "rb") as f:
        bitstream = f.read()

    # Open and perform full FTDI reset. This is needed to reset both A
    # and B interfaces, as if A is in SyncFIFO we can't really control B.
    ftdi = Ftdi()
    print(f"Opening {url!r}, resetting and closing it")
    ftdi.open_from_url(url)
    ftdi.reset(usb_reset=True)
    ftdi.close()
    # Open FTDI device in MPSSE mode, pull CNRESET low
    spi = SpiController()
    print(f"Opening {url!r} in MPSSE/SPI mode")
    spi.configure(
        url,
        cs_count=1,
        direction=(Pins.CNRESET),
        initial=0x0,
        frequency=freq,
    )
    gpio = spi.get_gpio()
    gpio.set_direction(Pins.CNRESET | Pins.CDONE | Pins.CIO1 | Pins.CIO2, Pins.CNRESET)
    gpio.write(0)
    print(f"Reset & wake up SPI flash chip..")
    port = spi.get_port(0)
    port.exchange([0x66])  # Enable Reset
    port.exchange([0x99])  # Reset
    # Read JEDEC ID
    jid = bytearray(port.exchange([0x9F], readlen=3))
    jid_str = " ".join(f"0x{b:02X}" for b in jid)
    print(f"Read flash JEDEC ID: {jid_str}")
    if jid[0] != 0xEF:
        raise RuntimeError(f"Seems we have a bad / non-responding flash chip")
    # Hotfix for spiflash which expects 0x40 not 0x70
    jid[1] = 0x40
    flash = W25xFlashDevice(spi.get_port(0), jid)
    print(f"Treating flash chip as: '{flash}'")
    # Erase full chip
    print(f"Erasing the chip... (this can take a while)")
    flash.erase(0, -1)
    # Program
    print(f"Programming {len(bitstream)} bytes...")
    flash.write(0, bitstream)
    # Verify
    print(f"Verifying {len(bitstream)} bytes...")
    bitstream_chip = flash.read(0, len(bitstream))
    for off in range(len(bitstream)):
        b_exp = bitstream[off]
        b_act = bitstream_chip[off]
        if b_act != b_exp:
            raise RuntimeError(
                f"Verification error: mismatch @ 0x{off:x}: expected 0x{b_exp:02x}, have 0x{b_act:02x}"
            )
    # Disconnect MPSSE and reset FTDI, this should deassert FPGA reset and start it
    spi.close()
    print(f"Opening {url!r}, resetting and closing it")
    ftdi.open_from_url(url)
    ftdi.reset(usb_reset=True)
    ftdi.close()
    print("Done.")


if __name__ == "__main__":
    main()
