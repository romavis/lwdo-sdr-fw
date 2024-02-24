#!/bin/bash

OP=$1
EEPROMCONF=${EEPROMCONF:=ftdi_eeprom.ini}
DEVICE=${DEVICE:=ftdi://ftdi:2232/1}

case $OP in
    "read")
        ftconf.py -vd -x $DEVICE
        ;;
    "write")
        ftconf.py -vd -i $EEPROMCONF -x -u $DEVICE
        ;;
    "erase")
        ftconf.py -vd -E -u $DEVICE
        ;;
    *)
        echo "Usage: script.sh OP"
        echo " where OP is one of: read, write, erase"
        exit 1
        ;;
esac 