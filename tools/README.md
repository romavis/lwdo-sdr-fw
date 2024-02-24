# FTDI tools for LWDO-SDR

LWDO-SDR uses FT2232H chip to access FPGA via USB High-Speed. We mostly use
SyncFIFO mode of FTDI for high-speed data transfers. However, before SyncFIFO
can be used two things must happen:
1. A small 93c56 EEPROM that stores configuration of FTDI chip has to be
flashed.
2. The FPGA bitstream has to be loaded to the QSPI flash from which the FPGA
boots.

Both these tasks require interacting with the FTDI chip in a special way that
differs from how it is used during the normal device operation. We rely on
a wonderful [pyftdi](https://github.com/eblot/pyftdi/) library for this task,
and this directory contains tools which are needed to accomplish that.

This directory
contains tools that are needed to accomplish that. For 

## Environment preparation

Create a Python virtual environment as usually, and install the dependencies
specified in *requirements.txt*. Something along these lines:

```bash
% python -m virtualenv venv
% source venv/bin/activate
(venv) % pip install -r requirements.txt
```

The above installs **pyftdi**. Note that a pretty recent version must be used
for EEPROM manipulation, so it is not recommended going lower than the version
specified in the *requirements.txt*.

## udev rules

One can use this rule on Linux, assuming that their user had been added to the
**plugdev** group:

```bash
% cat /etc/udev/rules.d/72-ftdi.rules
# FTDI
SUBSYSTEMS=="usb",ACTION=="add",ATTRS{idVendor}=="0403",ATTRS{idProduct}=="6010",MODE="0660",GROUP="plugdev",SYMLINK+="ftdi-%n"
```

## Find FTDI URL

Connect LWDO-SDR and discover the FTDI devices in your system. If the
EEPROM is empty, the device will use default FTDI configuration:

```bash
% source venv/bin/activate
(venv) % ftdi_urls.py
Available interfaces:
  ftdi://ftdi:2232:1:2d/1   (Dual RS232-HS)
  ftdi://ftdi:2232:1:2d/2   (Dual RS232-HS)
```

If the EEPROM has been flashed it may look a little different:
```bash

```

##
To update the EEPROM one can use *ftconf.py* tool that comes together with
**pyftdi**. The initial configuration is specified in *eeprom.ini* and can be
modified either in the file, or via command-line options.
