#!/bin/bash

set -e

# Docker hub rggen image, including the tag
RGGEN_IMAGE="rggendev/rggen-docker:0.33-0.11-0.9"

# Tools
DOCKER="${DOCKER:=sudo docker}"
APPTAINER="${APPTAINER:=apptainer}"

# Paths
CSR_DIR=$(cd "$(dirname "$0")"; pwd)
GEN_DIR=generated
RGGEN_CONFIG=map/config.yml
RGGEN_MAPS=(
    map/lwdo_regs.yml
)


# Determine container engine to use
if [ -z "$CONTAINER" ]; then
    if v=$(apptainer version 2>&1); then
        CONTAINER=apptainer
    elif v=$(docker -v 2>&1); then
        CONTAINER=docker
    else
        echo "Unable to determine your container engine."
        exit 1
    fi
fi

echo "Running using $CONTAINER..."

case "$CONTAINER" in
    apptainer)
        RGGEN="$APPTAINER run --containall --bind $CSR_DIR:/work docker://$RGGEN_IMAGE"
        PREFIX=/work
        ;;
    docker)
        RGGEN="$DOCKER run -v $CSR_DIR:/work --user $(id -u):$(id -g) $RGGEN_IMAGE"
        PREFIX=/work
        echo "Note: docker executed via sudo may ask for authentication."
        ;;
    *)
        echo "Unsupported CONTAINER engine specified: '$CONTAINER'"
        exit 1
        ;;
esac

set -x
# Generate Verilog and C headers
$RGGEN -c $PREFIX/$RGGEN_CONFIG -o $PREFIX/$GEN_DIR --enable verilog_rtl --enable c_header  ${RGGEN_MAPS[@]/#/$PREFIX/}
set +x

echo "Done."
