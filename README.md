# What

This repository hosts firmware for [LWDO-SDR project](https://github.com/RomaVis/lwdo-sdr-hw).

There are two pieces of firmware needed by LWDO-SDR device:
- Bitstream for *ICE40HX4K-TQ144* FPGA (stored in *W25Q16* SPI flash)
- Configuration blob for *FT2232H* USB bridge (stored in *93C56* EEPROM)

# How to - FPGA

There is a makefile which handles HDL-related tasks. You'll need GNU Make to use it.

## Creating bitstream

You'll need following tools to generate FPGA bitstream:
1. [Yosys](https://github.com/YosysHQ/yosys)
2. [nextpnr-ice40](https://github.com/YosysHQ/nextpnr)
3. [icestorm](https://github.com/YosysHQ/icestorm)
4. Python 3.6 or above (for C++ register map generation)

Run following commands to get it:
```
$ cd fpga/
$ make

# Bitstream binary will be created at ./fpga/out/top.bin
```

## Flashing bitstream

Currently, a modified version of [iceprog](https://github.com/YosysHQ/icestorm/tree/master/iceprog) is used for USB programming of SPI flash memory. Modification is necessary because LWDO-SDR connects *CS*, *CRESET* and *CDONE* to different FTDI pins than is usually assumed with ICE40 evaluation boards (*oops, happens* 🤷).

At the moment of writing, the modified version has not been published anywhere yet. If someone ever decides to build this device (*sic!*), please contact me privately or open a GitHub issue and I will help with getting iceprog working.

## Running testbenches

There are a few non-asserting testbenches that I wrote while developing HDL modules. They are also run via makefile. To run all of them:
```
$ cd fpga/
$ make test
```

To run some of them follow the pattern (all testbenches located under *./fpga/test* should be runnable this way):
```
$ cd fpga/
$ make test_fastcounter
```

Each testbench typically produces VCD waveform dump. You'll need GtkWave to view it:
```
$ cd fpga/
$ gtkwave out/test/test_fastcounter.vcd&
```

# How to - FTDI

TBD

# Design documentation

TBD

# License

All project files, except if listed below, are released under MIT license (`SPDX-License-Identifier: MIT`), full license text is available in [LICENSE.txt](LICENSE.txt) file.

Third-party HDL modules (located in *./fpga/3rdparty/*) are used in accordance with their own licenses. Although my intention was to include only modules under permissive licenses, keep in mind that you still have to comply with their individual licenses when reusing this work.

FTDI tools build on top of **libftdi** and **libusb** libraries, which are currently distributed under some flavor of LGPL. Therefore, special considerations apply if you want to redistribute them partially or as a whole.
