# Apache NuttX RTOS on PinePhone

[Apache NuttX RTOS](https://nuttx.apache.org/docs/latest/) now runs on Arm Cortex-A53 with Multi-Core SMP...

-   [nuttx/boards/arm64/qemu/qemu-a53](https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53)

PinePhone is based on Allwinner A64 SoC with 4 Cores of Arm Cortex-A53...

-   [PinePhone Wiki](https://wiki.pine64.org/index.php/PinePhone)

Will NuttX run on PinePhone? Let's find out!

_Why NuttX?_

NuttX is tiny and might be a fun way to teach more people about the internals of Phone Operating Systems. (Without digging deep into the entire Linux Stack)

Someday we might have a cheap, fast, responsive and tweakable phone running on NuttX!

Many thanks to [qinwei2004](https://github.com/qinwei2004) and the NuttX Team for implementing [Cortex-A53 support](https://github.com/apache/incubator-nuttx/pull/6478)!

# Download NuttX

Download the Source Code for NuttX Mainline, which supports Arm Cortex-A53...

```bash
## Create NuttX Directory
mkdir nuttx
cd nuttx

## Download NuttX OS
git clone \
    --recursive \
    --branch arm64 \
    https://github.com/lupyuen/incubator-nuttx \
    nuttx

## Download NuttX Apps
git clone \
    --recursive \
    --branch arm64 \
    https://github.com/lupyuen/incubator-nuttx-apps \
    apps

## We'll build NuttX inside nuttx/nuttx
cd nuttx
```

Install the Build Prerequisites, skip the RISC-V Toolchain...

-   ["Install Prerequisites"](https://lupyuen.github.io/articles/nuttx#install-prerequisites)

# Download Toolchain

Download the Arm Toolchain for AArch64 ELF Bare-Metal Target (`aarch64-none-elf`)...

-   [Arm GNU Toolchain Downloads](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)

For macOS: [arm-gnu-toolchain-11.3.rel1-darwin-x86_64-aarch64-none-elf.pkg](https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-darwin-x86_64-aarch64-none-elf.pkg)

For Linux x64 and WSL: [gcc-arm-11.2-2022.02-x86_64-aarch64-none-elf.tar.xz](https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-aarch64-none-elf.tar.xz)

(I don't recommend building NuttX on Plain Old Windows CMD, please use WSL instead)

Add it to the `PATH`...

```bash
## For Linux:
export PATH="$PATH:$HOME/gcc-arm-11.2-2022.02-x86_64-aarch64-none-elf/bin"

## For macOS:
export PATH="$PATH:/Applications/ArmGNUToolchain/11.3.rel1/aarch64-none-elf/bin"
```

Check the toolchain...

```bash
aarch64-none-elf-gcc -v
```

[(Based on the instructions here)](https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53)

# Download QEMU

Download and install QEMU...

-   [Download QEMU](https://www.qemu.org/download/)

For macOS we may use `brew`...

```bash
brew install qemu
```

# Build NuttX: Single Core

TODO

Configure NuttX and compile...

```bash
## Configure NuttX for Single Core
./tools/configure.sh -l qemu-a53:nsh

## Build NuttX
make

## Dump the disassembly to nuttx.S
aarch64-none-elf-objdump \
  -t -S --demangle --line-numbers --wide \
  nuttx \
  >nuttx.S \
  2>&1
```

Test with qemu...

```bash
## Start QEMU (Single Core) with NuttX
qemu-system-aarch64 \
    -cpu cortex-a53 \
    -nographic \
    -machine virt,virtualization=on,gic-version=3 \
    -net none \
    -chardev stdio,id=con,mux=on \
    -serial chardev:con \
    -mon chardev=con,mode=readline \
    -kernel ./nuttx
```

# Build NuttX: Multi Core

TODO

Configure NuttX and compile...

```bash
## Configure NuttX for 4 Cores
./tools/configure.sh -l qemu-a53:nsh_smp

## Build NuttX
make

## Dump the disassembly to nuttx.S
aarch64-none-elf-objdump \
  -t -S --demangle --line-numbers --wide \
  nuttx \
  >nuttx.S \
  2>&1
```

Test with qemu...

```bash
## Start QEMU (4 Cores) with NuttX
qemu-system-aarch64 \
    -smp 4 \
    -cpu cortex-a53 \
    -nographic \
    -machine virt,virtualization=on,gic-version=3 \
    -net none \
    -chardev stdio,id=con,mux=on \
    -serial chardev:con \
    -mon chardev=con,mode=readline \
    -kernel ./nuttx
```

# Inside NuttX for Cortex-A53

TODO

https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53

https://github.com/apache/incubator-nuttx/tree/master/arch/arm64/src/qemu

https://github.com/apache/incubator-nuttx/tree/master/arch/arm64/src/common

# NuttX Image

TODO: Analyse NuttX Image with Ghidra and NuttX Disassembly

Top Part of NuttX Image Header...

![Top Part of NuttX Image Header](https://lupyuen.github.io/images/Screenshot%202022-08-22%20at%204.09.55%20PM.png)

Bottom Part of NuttX Image Header...

![Bottom Part of NuttX Image Header](https://lupyuen.github.io/images/Screenshot%202022-08-22%20at%204.10.04%20PM.png)

When we refer to the NuttX Disassembly `nuttx.S`, we see this...

https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L79-L117

```text
    /* Kernel startup entry point.
     * ---------------------------
     *
     * The requirements are:
     *   MMU = off, D-cache = off, I-cache = on or off,
     *   x0 = physical address to the FDT blob.
     *       it will be used when NuttX support device tree in the future
     *
     * This must be the very first address in the loaded image.
     * It should be loaded at any 4K-aligned address.
     */
    .globl __start;
__start:

    /* DO NOT MODIFY. Image header expected by Linux boot-loaders.
     *
     * This add instruction has no meaningful effect except that
     * its opcode forms the magic "MZ" signature of a PE/COFF file
     * that is required for UEFI applications.
     *
     * Some bootloader (such imx8 uboot) checking the magic "MZ" to see
     * if the image is a valid Linux image. but modifying the bootLoader is
     * unnecessary unless we need to do a customize secure boot.
     * so just put the ''MZ" in the header to make bootloader happiness
     */

    add     x13, x18, #0x16      /* the magic "MZ" signature */
    b       real_start           /* branch to kernel start */
    .quad   0x480000              /* Image load offset from start of RAM */
    .quad   _e_initstack - __start         /* Effective size of kernel image, little-endian */
    .quad   __HEAD_FLAGS         /* Informative flags, little-endian */
    .quad   0                    /* reserved */
    .quad   0                    /* reserved */
    .quad   0                    /* reserved */
    .ascii  "ARM\x64"            /* Magic number, "ARM\x64" */
    .long   0                    /* reserved */

real_start:
    /* Disable all exceptions and interrupts */
```

NuttX Image actually follows the Linux Kernel Image Format, as defined here...

-   ["Booting AArch64 Linux"](https://www.kernel.org/doc/html/latest/arm64/booting.html)

Linux Kernel Image contains a 64-byte header as follows:

```text
u32 code0;                    /* Executable code */
u32 code1;                    /* Executable code */
u64 text_offset;              /* Image load offset, little endian */
u64 image_size;               /* Effective Image size, little endian */
u64 flags;                    /* kernel flags, little endian */
u64 res2      = 0;            /* reserved */
u64 res3      = 0;            /* reserved */
u64 res4      = 0;            /* reserved */
u32 magic     = 0x644d5241;   /* Magic number, little endian, "ARM\x64" */
u32 res5;                     /* reserved (used for PE COFF offset) */
```

# PinePhone Image

TODO: Disassemble a PinePhone Image with Ghidra to look at the Linux Kernel Header and Startup Code

https://github.com/dreemurrs-embedded/Jumpdrive

Download https://github.com/dreemurrs-embedded/Jumpdrive/releases/download/0.8/pine64-pinephone.img.xz

Expand `pine64-pinephone.img.xz`

Expand the files inside...

```bash
gunzip Image.gz
gunzip initramfs.gz
tar xvf initramfs
```

Import `Image` as AARCH64:LE:v8A:default...
-   Processor: AARCH64 
-   Variant: v8A 
-   Size: 64 
-   Endian: little 
-   Compiler: default

`Image` seems to start at 0x40000000, as suggested by this Memory Map...

https://linux-sunxi.org/A64/Memory_map

-   Click Window > Memory Map

-   Click "ram"

-   Click the 4-Arrows icon (Move a block to another address)

-   Change Start Address to 40000000

According to this doc...

-   ["Booting AArch64 Linux"](https://www.kernel.org/doc/html/latest/arm64/booting.html)

Linux Kernel Magic Number `ARM\x64` is at offset 0x38

# TODO

TODO: Verify that NuttX uses similar Startup Code

TODO: Build UART Driver in NuttX for Allwinner A64 SoC

UART0 Memory Map: https://linux-sunxi.org/A64/Memory_map

More about A64 UART: https://linux-sunxi.org/UART

Serial Debug Cable: https://wiki.pine64.org/index.php/PinePhone#Serial_console

TODO: Configure NuttX Memory Regions for Allwinner A64 SoC

TODO: Copy NuttX to microSD Card

A64 Boot ROM: https://linux-sunxi.org/BROM#A64

A64 U-Boot: https://linux-sunxi.org/U-Boot

A64 U-Boot SPL: https://linux-sunxi.org/BROM#U-Boot_SPL_limitations

SD Card Layout: https://linux-sunxi.org/Bootable_SD_card#SD_Card_Layout

TODO: Boot NuttX on PinePhone and test NuttX Shell

TODO: Build NuttX Drivers for PinePhone's LCD Display, Touch Panel, LTE Modem, WiFi, BLE, Power Mgmt, ...

TODO: From [Alan Carvalho de Assis](https://www.linkedin.com/in/acassis/)

-   I ran NuttX on PCDuino (ARM Cortex-A9 I think)

-   also NuttX on iMX6 and BeagleBoneBlack

-   nice to try evolve NuttX on Desktop direction

-   Tom Window Manager that Greg ported to NuttX

-   TODO: port NanoX (nxlib/microwindows) it could open doors to port X11 graphic applications from Linux

TODO: Boot Files for Manjaro Phosh on PinePhone:

```text
[manjaro@manjaro-arm ~]$ ls -l /boot
total 38568
-rw-r--r-- 1 root root     1476 Jun 22 08:36 boot.scr
-rw-r--r-- 1 root root     1404 Apr  6 11:51 boot.txt
drwxr-xr-x 3 root root     4096 Oct 16  2021 dtbs
-rw-r--r-- 1 root root 20160520 Jul  3 14:56 Image
-rw-r--r-- 1 root root  8359044 Jul  3 14:56 Image.gz
-rw-r--r-- 1 root root  7327835 Jul 24 14:33 initramfs-linux.img
-rw-r--r-- 1 root root   722223 Apr  6 11:51 u-boot-sunxi-with-spl-pinephone-492.bin
-rw-r--r-- 1 root root   722223 Apr  6 11:51 u-boot-sunxi-with-spl-pinephone-528.bin
-rw-r--r-- 1 root root   722223 Apr  6 11:51 u-boot-sunxi-with-spl-pinephone-552.bin
-rw-r--r-- 1 root root   722223 Apr  6 11:51 u-boot-sunxi-with-spl-pinephone-592.bin
-rw-r--r-- 1 root root   722223 Apr  6 11:51 u-boot-sunxi-with-spl-pinephone-624.bin

[manjaro@manjaro-arm ~]$ ls -l /boot/dtbs
total 8
drwxr-xr-x 2 root root 8192 Jul 24 14:30 allwinner

[manjaro@manjaro-arm ~]$ ls -l /boot/dtbs/allwinner
total 1504
-rw-r--r-- 1 root root 13440 Jul  3 14:56 sun50i-a100-allwinner-perf1.dtb
-rw-r--r-- 1 root root 41295 Jul  3 14:56 sun50i-a64-amarula-relic.dtb
-rw-r--r-- 1 root root 41648 Jul  3 14:56 sun50i-a64-bananapi-m64.dtb
-rw-r--r-- 1 root root 40512 Jul  3 14:56 sun50i-a64-nanopi-a64.dtb
-rw-r--r-- 1 root root 39951 Jul  3 14:56 sun50i-a64-oceanic-5205-5inmfd.dtb
-rw-r--r-- 1 root root 41268 Jul  3 14:56 sun50i-a64-olinuxino.dtb
-rw-r--r-- 1 root root 41397 Jul  3 14:56 sun50i-a64-olinuxino-emmc.dtb
-rw-r--r-- 1 root root 42295 Jul  3 14:56 sun50i-a64-orangepi-win.dtb
-rw-r--r-- 1 root root 40316 Jul  3 14:56 sun50i-a64-pine64.dtb
-rw-r--r-- 1 root root 40948 Jul  3 14:56 sun50i-a64-pine64-lts.dtb
-rw-r--r-- 1 root root 40438 Jul  3 14:56 sun50i-a64-pine64-plus.dtb
-rw-r--r-- 1 root root 42979 Jul  3 14:56 sun50i-a64-pinebook.dtb
-rw-r--r-- 1 root root 53726 Jul  3 14:56 sun50i-a64-pinephone-1.0.dtb
-rw-r--r-- 1 root root 53753 Jul  3 14:56 sun50i-a64-pinephone-1.1.dtb
-rw-r--r-- 1 root root 53718 Jul  3 14:56 sun50i-a64-pinephone-1.2.dtb
-rw-r--r-- 1 root root 44110 Jul  3 14:56 sun50i-a64-pinetab.dtb
-rw-r--r-- 1 root root 44150 Jul  3 14:56 sun50i-a64-pinetab-early-adopter.dtb
-rw-r--r-- 1 root root 40816 Jul  3 14:56 sun50i-a64-sopine-baseboard.dtb
-rw-r--r-- 1 root root 42234 Jul  3 14:56 sun50i-a64-teres-i.dtb
-rw-r--r-- 1 root root 31407 Jul  3 14:56 sun50i-h5-bananapi-m2-plus.dtb
-rw-r--r-- 1 root root 32846 Jul  3 14:56 sun50i-h5-bananapi-m2-plus-v1.2.dtb
-rw-r--r-- 1 root root 31056 Jul  3 14:56 sun50i-h5-emlid-neutis-n5-devboard.dtb
-rw-r--r-- 1 root root 31277 Jul  3 14:56 sun50i-h5-libretech-all-h3-cc.dtb
-rw-r--r-- 1 root root 29939 Jul  3 14:56 sun50i-h5-libretech-all-h3-it.dtb
-rw-r--r-- 1 root root 31872 Jul  3 14:56 sun50i-h5-libretech-all-h5-cc.dtb
-rw-r--r-- 1 root root 29013 Jul  3 14:56 sun50i-h5-nanopi-neo2.dtb
-rw-r--r-- 1 root root 29704 Jul  3 14:56 sun50i-h5-nanopi-neo-plus2.dtb
-rw-r--r-- 1 root root 31401 Jul  3 14:56 sun50i-h5-nanopi-r1s-h5.dtb
-rw-r--r-- 1 root root 31082 Jul  3 14:56 sun50i-h5-orangepi-pc2.dtb
-rw-r--r-- 1 root root 29806 Jul  3 14:56 sun50i-h5-orangepi-prime.dtb
-rw-r--r-- 1 root root 29044 Jul  3 14:56 sun50i-h5-orangepi-zero-plus2.dtb
-rw-r--r-- 1 root root 29131 Jul  3 14:56 sun50i-h5-orangepi-zero-plus.dtb
-rw-r--r-- 1 root root 31911 Jul  3 14:56 sun50i-h6-beelink-gs1.dtb
-rw-r--r-- 1 root root 33042 Jul  3 14:56 sun50i-h6-orangepi-3.dtb
-rw-r--r-- 1 root root 30504 Jul  3 14:56 sun50i-h6-orangepi-lite2.dtb
-rw-r--r-- 1 root root 30287 Jul  3 14:56 sun50i-h6-orangepi-one-plus.dtb
-rw-r--r-- 1 root root 32368 Jul  3 14:56 sun50i-h6-pine-h64.dtb
-rw-r--r-- 1 root root 32882 Jul  3 14:56 sun50i-h6-pine-h64-model-b.dtb
-rw-r--r-- 1 root root 29544 Jul  3 14:56 sun50i-h6-tanix-tx6.dtb
-rw-r--r-- 1 root root 29305 Jul  3 14:56 sun50i-h6-tanix-tx6-mini.dtb

[manjaro@manjaro-arm ~]$ cat /boot/boot.txt
#
# /boot/boot.txt
# After modifying, run "pp-uboot-mkscr" to re-generate the U-Boot boot script.
#

#
# This is the description of the GPIO lines used in this boot script:
#
# GPIO #98 is PD2, or A64 ball W19, which controls the vibrator motor
# GPIO #114 is PD18, or A64 ball AB13, which controls the red part of the multicolor LED
# GPIO #115 is PD19, or A64 ball AB12, which controls the green part of the multicolor LED
# GPIO #116 is PD20, or A64 ball AB11, which controls the blue part of the multicolor LED
#

gpio set 98
gpio set 114

# Set root partition to the second partition of boot device
part uuid ${devtype} ${devnum}:1 uuid_boot
part uuid ${devtype} ${devnum}:2 uuid_root

setenv bootargs loglevel=4 console=tty0 console=${console} earlycon=uart,mmio32,0x01c28000 consoleblank=0 boot=PARTUUID=${uuid_boot} root=PARTUUID=${uuid_root} rw rootwait quiet audit=0 bootsplash.bootfile=bootsplash-themes/manjaro/bootsplash

if load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /Image; then
  gpio clear 98
  if load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /dtbs/${fdtfile}; then
    if load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /initramfs-linux.img; then
      gpio set 115
      booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r};
    else
      gpio set 116
      booti ${kernel_addr_r} - ${fdt_addr_r};
    fi;
  fi;
fi

# EOF
```
