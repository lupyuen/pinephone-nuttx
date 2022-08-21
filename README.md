# Apache NuttX RTOS on PinePhone

Apache NuttX RTOS runs on Cortex-A53 with Multi-Core SMP...

https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53

Will NuttX run on PinePhone? PinePhone is based on Allwinner A64 SoC with 4 Cores of Arm Cortex-A53...

https://wiki.pine64.org/index.php/PinePhone

NuttX might be a fun way to teach more people about Phone Operating Systems. And someday we might have a cheap, fast and responsive phone running on NuttX!

Many thanks to [qinwei2004](https://github.com/qinwei2004) and the NuttX Team for implementing [Cortex-A53 support](https://github.com/apache/incubator-nuttx/pull/6478)!

# Download NuttX

TODO

```bash
mkdir nuttx
cd nuttx
git clone --recursive --branch arm64 \
    https://github.com/lupyuen/incubator-nuttx \
    nuttx
git clone --recursive --branch arm64 \
    https://github.com/lupyuen/incubator-nuttx-apps \
    apps
cd nuttx
```

Install prerequisites, skip the RISC-V Toolchain...

https://lupyuen.github.io/articles/nuttx#install-prerequisites

# Download Toolchain

TODO

Instructions:

https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53

Download toolchain for AArch64 ELF bare-metal target (aarch64-none-elf)

https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads

For macOS:

https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-darwin-x86_64-aarch64-none-elf.pkg

For x64 Linux:

https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-aarch64-none-elf.tar.xz

Add to PATH: /Applications/ArmGNUToolchain/11.3.rel1/aarch64-none-elf/bin

```bash
export PATH="$PATH:/Applications/ArmGNUToolchain/11.3.rel1/aarch64-none-elf/bin"
```

# Download QEMU

TODO

Download QEMU: https://www.qemu.org/download/

```bash
brew install qemu
```

# Build NuttX: Single Core

TODO

Configure NuttX and compile...

```bash
./tools/configure.sh -l qemu-a53:nsh
make
```

Test with qemu...

```bash
qemu-system-aarch64 -cpu cortex-a53 -nographic \
    -machine virt,virtualization=on,gic-version=3 \
    -net none -chardev stdio,id=con,mux=on -serial chardev:con \
    -mon chardev=con,mode=readline -kernel ./nuttx
```

# Build NuttX: Multi Core

TODO

Configure NuttX and compile...

```bash
./tools/configure.sh -l qemu-a53:nsh_smp
make
```

Test with qemu...

```bash
qemu-system-aarch64 -cpu cortex-a53 -smp 4 -nographic \
    -machine virt,virtualization=on,gic-version=3 \
    -net none -chardev stdio,id=con,mux=on -serial chardev:con \
    -mon chardev=con,mode=readline -kernel ./nuttx
```

# TODO

TODO: Disassemble a PinePhone Image with Ghidra to look at the Startup Code

TODO: Verify that NuttX uses similar Startup Code

TODO: Build UART Driver in NuttX for Allwinner A64 SoC

TODO: Configure NuttX Memory Regions for Allwinner A64 SoC

TODO: Copy NuttX to microSD Card

TODO: Boot NuttX on PinePhone and test NuttX Shell
