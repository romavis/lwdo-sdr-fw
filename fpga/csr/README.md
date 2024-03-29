# CSR (control and status registers)

Verilog CSR definitions are generated by [rggen](https://github.com/rggen/rggen).
To make things simpler, it's recommended to run **rggen** via
[rggen-docker](https://github.com/rggen/rggen-docker) container.

*make_csr.sh* Bash script is provided to automate running rggen. It supports
following container engines:
- Apptainer (recommended)
- Docker

The engine can be selected using a `CONTAINER` environment variable. If that
variable is not specified, the script attempts to auto-detect the engine.

**NOTE:** it's a Bash script, Windows systems were not considered when writing
it. However, the script is so simple that implementing a suitable batch or
PowerShell replacement won't take much effort.

To update CSR files after modifying the register map in *map* directory,
run:
```bash
% ./make_csr.sh

Running using apptainer...
+ apptainer run --containall --bind csr:/work docker://rggendev/rggen-docker:0.33-0.11-0.9 -c /work/map/config.yml -o /work/generated --plugin rggen-verilog /work/map/lwdo_regs.yml
INFO:    Using cached SIF image
INFO:    gocryptfs not found, will not be able to use gocryptfs
+ apptainer run --containall --bind csr:/work docker://rggendev/rggen-docker:0.33-0.11-0.9 -c /work/map/config.yml -o /work/generated --plugin rggen-c-header /work/map/lwdo_regs.yml
INFO:    Using cached SIF image
INFO:    gocryptfs not found, will not be able to use gocryptfs
+ set +x
Done.
```
