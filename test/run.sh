#!/usr/bin/env bash
## Test Locally

set -e  #  Exit when any command fails
set -x  #  Echo commands

clear

## Compile test code
gcc \
    -o test \
    -I . \
    -I ../../nuttx/arch/arm64/src/a64 \
    test.c \
    ../../nuttx/arch/arm64/src/a64/a64_de.c \
    ../../nuttx/arch/arm64/src/a64/a64_mipi_dphy.c \
    ../../nuttx/arch/arm64/src/a64/a64_mipi_dsi.c \
    ../../nuttx/arch/arm64/src/a64/a64_rsb.c \
    ../../nuttx/arch/arm64/src/a64/a64_tcon0.c \
    ../../nuttx/arch/arm64/src/a64/mipi_dsi.c

## Run the test
./test

## Diff the actual and expected test logs
./test >test.log
set +e  #  Ignore errors
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
    | grep -v "fb0=" \
    | grep -v "*0x1100004 = 0x0" \
    | grep -v "*0x1100008 = 0x0" \
    | grep -v "*0x1105ff8 = 0x0" \
    | grep -v "*0x1105ffc = 0x0" \
    | grep -v "*0x1103010 = 0x12345678" \
    | grep -v "*0x1104010 = 0x23456789" \
    | grep -v "*0x1105010 = 0x34567890" \
    | grep -v "*0x1f0341c = 0x8" \
    | grep -v "*0x1f0341c = 0x10" \
    | grep -v "rt_addr=0x2d, reg_addr=0x15, value=0x1a" \
    | grep -v "rt_addr=0x2d, reg_addr=0x12, value=0x8" \
    | grep -v "rt_addr=0x2d, reg_addr=0x91, value=0x1a" \
    | grep -v "rt_addr=0x2d, reg_addr=0x90, value=0x3" \
    | grep -v "rt_addr=0x2d, reg_addr=0x16, value=0xb" \
    | grep -v "rt_addr=0x2d, reg_addr=0x12, value=0x10" \
    | grep -v "rt_addr=0x2d, reg_addr=0x12" \

set -e  #  Exit when any command fails
