#include <libftdi1/ftdi.h>
#include <stdio.h>
#include <stdlib.h>

char* mfr = "RomaVis";
char* product = "LWDO-SDR";
char* serial = "00000001";

int main(int argc, const char** argv) {
  int ret;
  struct ftdi_context* ftdi;

  // Check args
  if(argc != 2) {
    fprintf(stderr, "Usage: prepare_eeprom DEVICE\n");
    fprintf(stderr, " DEVICE is in usual libftdi format, e.g.:   i:0x0403:0x6010\n");
    return EXIT_FAILURE;
  }
  const char* device = argv[1];

  // Init context
  ftdi = ftdi_new();
  if(ftdi == NULL) {
    fprintf(stderr, "Unable to init FTDI\n");
    return EXIT_FAILURE;
  }

  // Open device
  ret = ftdi_usb_open_string(ftdi, device);
  if(ret) {
    fprintf(stderr, "Unable to open USB device: %s\n", ftdi_get_error_string(ftdi));
    return EXIT_FAILURE;
  }

  // Init EEPROM
  ret = ftdi_eeprom_initdefaults(ftdi, mfr, product, serial);
  if(ret) {
    fprintf(stderr, "Unable to default-init EEPROM: %s\n", ftdi_get_error_string(ftdi));
    return EXIT_FAILURE;
  }

  // Customize
  struct {
    enum ftdi_eeprom_value what;
    int value;
  } values[] = {
    {VENDOR_ID, 0x0403},
    {PRODUCT_ID, 0x6010},
    {SELF_POWERED, 0},
    {REMOTE_WAKEUP, 0},
    {SUSPEND_DBUS7, 1},
    {SUSPEND_PULL_DOWNS, 1},
    {USE_SERIAL, 1},
    {MAX_POWER, 500},
    {CHANNEL_A_TYPE, CHANNEL_IS_FIFO},
    {CHANNEL_B_TYPE, CHANNEL_IS_FIFO},
    {CHANNEL_A_DRIVER, 0},
    {CHANNEL_B_DRIVER, 0},
    {GROUP0_DRIVE, DRIVE_8MA},
    {GROUP1_DRIVE, DRIVE_8MA},
    {GROUP2_DRIVE, DRIVE_8MA},
    {GROUP3_DRIVE, DRIVE_8MA},
    // no schmitt
    {GROUP0_SCHMITT, 0},
    {GROUP1_SCHMITT, 0},
    {GROUP2_SCHMITT, 0},
    {GROUP3_SCHMITT, 0},
    // no slow slew rate
    {GROUP0_SLEW, 0},
    {GROUP1_SLEW, 0},
    {GROUP2_SLEW, 0},
    {GROUP3_SLEW, 0},
    // eeprom is 93c56
    {CHIP_TYPE, 0x56},
  };

  for(unsigned i = 0; i < sizeof(values) / sizeof(values[0]); i++) {
    ret = ftdi_set_eeprom_value(ftdi, values[i].what, values[i].value);
    if(ret) {
      fprintf(stderr, "Unable to set EEPROM value %d to 0x%02x: %s\n",
              values[i].what, values[i].value, ftdi_get_error_string(ftdi));
      return EXIT_FAILURE;
    }
  }
  // Build EEPROM binary from cached param values
  int sz = ftdi_eeprom_build(ftdi);
  if(sz < 1) {
    fprintf(stderr, "Unable to build EEPROM: %s\n", ftdi_get_error_string(ftdi));
    return EXIT_FAILURE;
  }

  // Decode eeprom for humans
  printf("Decoding generated eeprom..\n");
  ret = ftdi_eeprom_decode(ftdi, 1);
  if(ret) {
    fprintf(stderr, "Unable to decode EEPROM: %s\n", ftdi_get_error_string(ftdi));
    return EXIT_FAILURE;
  }

  // Program eeprom
  printf("Programming EEPROM...\n");
  ret = ftdi_write_eeprom(ftdi);
  if(ret) {
    fprintf(stderr, "Unable to write EEPROM: %s\n", ftdi_get_error_string(ftdi));
    return EXIT_FAILURE;
  }

  printf("Done. EEPROM programmed. Reset FTDI chip to apply changes.\n");

  // Free context
  ftdi_free(ftdi);

  return EXIT_SUCCESS;
}