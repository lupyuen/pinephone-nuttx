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

./test >test.log
diff \
    --ignore-all-space \
    expected.log test.log \
    | grep ">" \
    | grep -v "up_mdelay" \
    | grep -v "TODO" \
    | grep -v "txlen" \
    | grep -v "*0x1ca0200" \
    | grep -v "*0x1ca0048" \
    | grep -v "ret=" \
    | grep -v "pktlen=" \
    | grep -v "hello" \
