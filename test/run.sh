#!/usr/bin/env bash
## Test Locally

set -e  #  Exit when any command fails
set -x  #  Echo commands

clear

## Compile test code
gcc \
    -o test \
    -I ../../nuttx/arch/arm64/src/a64 \
    test.c \
    ../../nuttx/arch/arm64/src/a64/a64_mipi_dphy.c \
    ../../nuttx/arch/arm64/src/a64/a64_mipi_dsi.c \
    ../../nuttx/arch/arm64/src/a64/mipi_dsi.c

## Run the test
./test
