![Apache NuttX RTOS on PinePhone](https://lupyuen.github.io/images/de-title.jpg)

[__Watch the Demo on YouTube__](https://youtube.com/shorts/WmRzfCiWV6o?feature=share)

[__Another Demo Video__](https://youtu.be/MJDxCcKAv0g)

# Apache NuttX RTOS on PinePhone

Read the articles...

-   ["Apache NuttX RTOS on Arm Cortex-A53: How it might run on PinePhone"](https://lupyuen.github.io/articles/arm)

-   ["PinePhone boots Apache NuttX RTOS"](https://lupyuen.github.io/articles/uboot)

-   ["NuttX RTOS for PinePhone: Fixing the Interrupts"](https://lupyuen.github.io/articles/interrupt)

-   ["NuttX RTOS for PinePhone: UART Driver"](https://lupyuen.github.io/articles/serial)

-   ["NuttX RTOS for PinePhone: Blinking the LEDs"](https://lupyuen.github.io/articles/pio)

-   ["Understanding PinePhone's Display (MIPI DSI)"](https://lupyuen.github.io/articles/dsi)

-   ["NuttX RTOS for PinePhone: Display Driver in Zig"](https://lupyuen.github.io/articles/dsi2)

[Apache NuttX RTOS](https://nuttx.apache.org/docs/latest/) now runs on Arm Cortex-A53 with Multi-Core SMP...

-   [nuttx/boards/arm64/qemu/qemu-a53](https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53)

PinePhone is based on [Allwinner A64 SoC](https://linux-sunxi.org/A64) with 4 Cores of Arm Cortex-A53...

-   [PinePhone Wiki](https://wiki.pine64.org/index.php/PinePhone)

_Will NuttX run on PinePhone?_

Yep it does! PinePhone (with a Serial Debug Cable) boots to the NuttX Shell...

-   [Watch the Demo on YouTube](https://youtube.com/shorts/WmRzfCiWV6o?feature=share)

Here's the NuttX Source Code for PinePhone...

-   NuttX OS: [lupyuen/incubator-nuttx/tree/pinephone](https://github.com/lupyuen/incubator-nuttx/tree/pinephone)

-   NuttX Apps: [lupyuen/incubator-nuttx-apps/tree/pinephone](https://github.com/lupyuen/incubator-nuttx-apps/tree/pinephone)

_Why NuttX?_

NuttX is tiny and might be a fun way to teach more people about the internals of Phone Operating Systems. (Without digging deep into the entire Linux Stack)

Someday we might have a cheap, fast, responsive and tweakable phone running on NuttX!

Many thanks to [qinwei2004](https://github.com/qinwei2004) and the NuttX Team for implementing [Cortex-A53 support](https://github.com/apache/incubator-nuttx/pull/6478)!

The following is a journal that documents the porting of NuttX to PinePhone. It looks super messy and unstructured, please read the articles (at the top of this page) instead.

# Download NuttX

We start with NuttX Mainline, run it on QEMU, then mod it for PinePhone.

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

For Linux x64 and WSL:

-   [gcc-arm-11.2-2022.02-x86_64-aarch64-none-elf.tar.xz](https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-aarch64-none-elf.tar.xz)

For macOS:

-   [arm-gnu-toolchain-11.3.rel1-darwin-x86_64-aarch64-none-elf.pkg](https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-darwin-x86_64-aarch64-none-elf.pkg)

(I don't recommend building NuttX on Plain Old Windows CMD, please use WSL instead)

Add it to the `PATH`...

```bash
## For Linux x64 and WSL:
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

First we build NuttX for a Single Core of Arm Cortex-A53...

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

The NuttX Output Files may be found here...

-   [NuttX for Arm Cortex-A53 Single Core](https://github.com/lupyuen/pinephone-nuttx/releases/tag/v1.0.1)

# Test NuttX with QEMU: Single Core

This is how we test NuttX on QEMU with a Single Core of Arm Cortex-A53...

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

Here's NuttX with a Single Core running on QEMU...

```text
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize

nx_start: Entry
up_allocate_heap: heap_start=0x0x402c4000, heap_size=0x7d3c000
gic_validate_dist_version: GICv3 version detect
gic_validate_dist_version: GICD_TYPER = 0x37a0007
gic_validate_dist_version: 224 SPIs implemented
gic_validate_dist_version: 0 Extended SPIs implemented
gic_validate_dist_version: Distributor has no Range Selector support
gic_validate_redist_version: GICD_TYPER = 0x1000011
gic_validate_redist_version: 16 PPIs implemented
gic_validate_redist_version: no VLPI support, no direct LPI support
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 62.50MHz, cycle 62500
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x402a7000 _einit: 0x402a7000 _stext: 0x40280000 _etext: 0x402a8000
nsh: sysinit: fopen failed: 2
nsh: mkfatfs: command not found

NuttShell (NSH) NuttX-10.3.0-RC2
nsh> nx_start: CPU0: Beginning Idle Loop

nsh> help
help usage:  help [-v] [<cmd>]

  .         cd        dmesg     help      mount     rmdir     true      xd        
  [         cp        echo      hexdump   mv        set       truncate  
  ?         cmp       exec      kill      printf    sleep     uname     
  basename  dirname   exit      ls        ps        source    umount    
  break     dd        false     mkdir     pwd       test      unset     
  cat       df        free      mkrd      rm        time      usleep    

Builtin Apps:
  getprime  hello     nsh       ostest    sh        

nsh> uname -a
NuttX 10.3.0-RC2 1e8f2a8 Aug 23 2022 07:04:54 arm64 qemu-a53

nsh> hello
task_spawn: name=hello entry=0x4029b594 file_actions=0x402c9580 attr=0x402c9588 argv=0x402c96d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
Hello, World!!

nsh> ls /
/:
 dev/
 etc/
 proc/

nsh> ls /dev
/dev:
 console
 null
 ram0
 ram2
 ttyS0
 zero

nsh> ls /proc
/proc:
 0/
 1/
 2/
 meminfo
 memdump
 fs/
 self/
 uptime
 version

nsh> ls /etc
/etc:
 init.d/

nsh> ls /etc/init.d
/etc/init.d:
 rcS

nsh> cat /etc/init.d/rcS
# Create a RAMDISK and mount it at /tmp

mkrd -m 2 -s 512 1024
mkfatfs /dev/ram2
mount -t vfat /dev/ram2 /tmp
```

NuttX is [POSIX Compliant](https://nuttx.apache.org/docs/latest/introduction/inviolables.html), so the developer experience feels very much like Linux. (But much smaller)

And NuttX runs everything in RAM, no File System needed. (For now)

# Build NuttX: Multi Core

From Single Core to Multi Core! Now we build NuttX for 4 Cores of Arm Cortex-A53...

```bash
## Erase the NuttX Configuration
make distclean

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

The NuttX Output Files may be found here...

-   [NuttX for Arm Cortex-A53 Multi-Core](https://github.com/lupyuen/pinephone-nuttx/releases/tag/v1.0.0)

# Test NuttX with QEMU: Multi Core

And this is how we test NuttX on QEMU with 4 Cores of Arm Cortex-A53...

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

Note that `smp` is set to 4. [(Symmetric Multi-Processing)](https://developer.arm.com/documentation/den0024/a/Multi-core-processors/Multi-processing-systems/Symmetric-multi-processing?lang=en)

Here's NuttX with 4 Cores running on QEMU...

```text
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize

[CPU0] psci_detect: Detected PSCI v1.1
[CPU0] nx_start: Entry
[CPU0] up_allocate_heap: heap_start=0x0x402db000, heap_size=0x7d25000
[CPU0] gic_validate_dist_version: GICv3 version detect
[CPU0] gic_validate_dist_version: GICD_TYPER = 0x37a0007
[CPU0] gic_validate_dist_version: 224 SPIs implemented
[CPU0] gic_validate_dist_version: 0 Extended SPIs implemented
[CPU0] gic_validate_dist_version: Distributor has no Range Selector support
[CPU0] gic_validate_redist_version: GICD_TYPER = 0x1000001
[CPU0] gic_validate_redist_version: 16 PPIs implemented
[CPU0] gic_validate_redist_version: no VLPI support, no direct LPI support
[CPU0] up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 62.50MHz, cycle 62500
[CPU0] uart_register: Registering /dev/console
[CPU0] uart_register: Registering /dev/ttyS0

- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize

[CPU1] gic_validate_redist_version: GICD_TYPER = 0x101000101
[CPU1] gic_validate_redist_version: 16 PPIs implemented
[CPU1] gic_validate_redist_version: no VLPI support, no direct LPI support
[CPU1] nx_idle_trampoline: CPU1: Beginning Idle Loop
[CPU0] arm64_start_cpu: Secondary CPU core 1 (MPID:0x1) is up

- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize

[CPU2] gic_validate_redist_version: GICD_TYPER = 0x201000201
[CPU2] gic_validate_redist_version: 16 PPIs implemented
[CPU2] gic_validate_redist_version: no VLPI support, no direct LPI support
[CPU2] nx_idle_trampoline: CPU2: Beginning Idle Loop
[CPU0] arm64_start_cpu: Secondary CPU core 2 (MPID:0x2) is up

- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize

[CPU3] gic_validate_redist_version: GICD_TYPER = 0x301000311
[CPU3] gic_validate_redist_version: 16 PPIs implemented
[CPU3] gic_validate_redist_version: no VLPI support, no direct LPI support
[CPU0] arm64_start_cpu: Secondary CPU core 3 (MPID:0x3) is up
[CPU0] work_start_highpri: Starting high-priority kernel worker thread(s)
[CPU0] nx_start_application: Starting init thread
[CPU3] nx_idle_trampoline: CPU3: Beginning Idle Loop
[CPU0] nx_start: CPU0: Beginning Idle Loop

nsh: sysinit: fopen failed: 2
nsh: mkfatfs: command not found

NuttShell (NSH) NuttX-10.3.0-RC2
nsh> help
help usage:  help [-v] [<cmd>]

  .         cd        dmesg     help      mount     rmdir     true      xd        
  [         cp        echo      hexdump   mv        set       truncate  
  ?         cmp       exec      kill      printf    sleep     uname     
  basename  dirname   exit      ls        ps        source    umount    
  break     dd        false     mkdir     pwd       test      unset     
  cat       df        free      mkrd      rm        time      usleep    

Builtin Apps:
  getprime  hello     nsh       ostest    sh        smp       taskset   

nsh> uname -a
NuttX 10.3.0-RC2 1e8f2a8 Aug 21 2022 15:57:35 arm64 qemu-a53

nsh> hello
[CPU0] task_spawn: name=hello entry=0x4029cee4 file_actions=0x402e52b0 attr=0x402e52b8 argv=0x402e5400
[CPU0] spawn_execattrs: Setting policy=2 priority=100 for pid=6
Hello, World!
```

We see each of the 4 Cores starting NuttX (CPU0 to CPU3). That's so cool!

(Can we use QEMU to partially emulate PinePhone? That would be extremely helpful!)

# Inside NuttX for Cortex-A53

Now we browse the Source Files for the implementation of Cortex-A53 on NuttX.

NuttX treats QEMU as a Target Board (as though it was a dev board). Here are the Source Files and Build Configuration for the QEMU Board...

-   [nuttx/boards/arm64/qemu/qemu-a53](https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53)

(We'll clone this to create a Target Board for PinePhone)

The Board-Specific Drivers for QEMU are started in [qemu-a53/src/qemu_bringup.c](https://github.com/apache/incubator-nuttx/blob/master/boards/arm64/qemu/qemu-a53/src/qemu_bringup.c)

(We'll start the PinePhone Drivers here)

The QEMU Board calls the QEMU Architecture-Specific Drivers at...

-   [nuttx/arch/arm64/src/qemu](https://github.com/apache/incubator-nuttx/tree/master/arch/arm64/src/qemu)

The UART Driver is located at [qemu/qemu_serial.c](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/qemu/qemu_serial.c) and [qemu/qemu_lowputc.S](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/qemu/qemu_lowputc.S)

(For PinePhone we'll create a UART Driver for Allwinner A64 SoC. I2C, SPI and other Low-Level A64 Drivers will be located here too)

The QEMU Functions (Board and Architecture) call the Arm64 Architecture Functions at...

-   [nuttx/arch/arm64/src/common](https://github.com/apache/incubator-nuttx/tree/master/arch/arm64/src/common)

Which implements all kinds of Arm64 Features: [FPU](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/common/arm64_fpu.c), [Interrupts](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/common/arm64_gicv3.c), [MMU](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/common/arm64_mmu.c), [Tasks](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/common/arm64_task_sched.c), [Timers](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/common/arm64_arch_timer.c)...

(We'll reuse them for PinePhone)

# NuttX Image

Next we analyse the NuttX Image with [Ghidra](https://ghidra-sre.org/), to understand the NuttX Image Header and Startup Code.

Here's the [NuttX ELF Image `nuttx`](https://github.com/lupyuen/pinephone-nuttx/releases/download/v1.0.0/nuttx) analysed by Ghidra...

![Ghidra with Apache NuttX RTOS for Arm Cortex-A53](https://lupyuen.github.io/images/arm-ghidra1.png)

Note that the NuttX Image jumps to `real_start` (to skip the Image Header)...

```text
40280000 4d 5a 00 91     add        x13,x18,#0x16
40280004 0f 00 00 14     b          real_start
```

`real_start` is defined at 0x4028 0040 with the Startup Code...

![Bottom Part of NuttX Image Header](https://lupyuen.github.io/images/arm-title.png)

We see something interesting: The Magic Number `ARM\x64` appears at address 0x4028 0038.

Searching the net for this Magic Number reveals that it's actually an Arm64 Linux Kernel Header!

When we refer to the [NuttX Arm64 Disassembly `nuttx.S`](https://github.com/lupyuen/pinephone-nuttx/releases/download/v1.0.0/nuttx.S), we find happiness: [arch/arm64/src/common/arm64_head.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L79-L117)

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

NuttX Image actually follows the Arm64 Linux Kernel Image Format! As defined here...

-   ["Booting AArch64 Linux"](https://www.kernel.org/doc/html/latest/arm64/booting.html)

Arm64 Linux Kernel Image contains a 64-byte header...

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

Start of RAM is 0x4000 0000. The Image Load Offset in our NuttX Image Header is 0x48 0000 according to [arch/arm64/src/common/arm64_head.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L107)

```text
    .quad   0x480000              /* Image load offset from start of RAM */
```

This means that our NuttX Image will be loaded at 0x4048 0000.

I wonder if this Image Load Offset should have been 0x28 0000? (Instead of 0x48 0000)

Remember that Ghidra (and the Arm Disassembly) says that our NuttX Image is actually loaded at 0x4028 0000. (Instead of 0x4048 0000)

RAM Size and RAM Start are defined in the NuttX Configuration: [boards/arm64/qemu/qemu-a53/configs/nsh_smp/defconfig](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/boards/arm64/qemu/qemu-a53/configs/nsh_smp/defconfig#L47-L48)

```text
CONFIG_RAM_SIZE=134217728
CONFIG_RAM_START=0x40000000
```

That's 128 MB RAM. Which should fit inside PinePhone's 2 GB RAM.

The NuttX Image was built with this Linker Command, based on `make --trace`...

```bash
aarch64-none-elf-ld \
  --entry=__start \
  -nostdlib \
  --cref \
  -Map=nuttx/nuttx/nuttx.map \
  -Tnuttx/nuttx/boards/arm64/qemu/qemu-a53/scripts/dramboot.ld  \
  -L nuttx/nuttx/staging \
  -L nuttx/nuttx/arch/arm64/src/board  \
  -o nuttx/nuttx/nuttx arm64_head.o  \
  --start-group \
  -lsched \
  -ldrivers \
  -lboards \
  -lc \
  -lmm \
  -larch \
  -lapps \
  -lfs \
  -lbinfmt \
  -lboard /Applications/ArmGNUToolchain/11.3.rel1/aarch64-none-elf/bin/../lib/gcc/aarch64-none-elf/11.3.1/libgcc.a /Applications/ArmGNUToolchain/11.3.rel1/aarch64-none-elf/bin/../lib/gcc/aarch64-none-elf/11.3.1/../../../../aarch64-none-elf/lib/libm.a \
  --end-group
```

NuttX Image begins at `__start`, which is defined as 0x4028 0000 in the NuttX Linker Script: [boards/arm64/qemu/qemu-a53/scripts/dramboot.ld](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/boards/arm64/qemu/qemu-a53/scripts/dramboot.ld#L30-L33)

```text
SECTIONS
{
  . = 0x40280000;  /* uboot load address */
  _start = .;
```

We'll change this to 0x4008 0000 for PinePhone, since Kernel Start Address is 0x4008 0000 and Image Load Offset is 0. (See below)

We've seen the NuttX Image (which looks like a Linux Kernel Image), let's compare with a PinePhone Linux Kernel Image and see how NuttX needs to be tweaked...

# PinePhone Image

Will NuttX run on PinePhone? Let's analyse a PinePhone Linux Kernel Image with Ghidra, to look at the Linux Kernel Header and Startup Code.

We'll use the PinePhone Jumpdrive Image, since it's small...

https://github.com/dreemurrs-embedded/Jumpdrive

Download https://github.com/dreemurrs-embedded/Jumpdrive/releases/download/0.8/pine64-pinephone.img.xz

Expand `pine64-pinephone.img.xz`

Expand the files inside...

```bash
gunzip Image.gz
gunzip initramfs.gz
tar xvf initramfs
```

Import the uncompressed `Image` (Linux Kernel) into Ghidra.

For "Language" select AARCH64:LE:v8A:default...
-   Processor: AARCH64 
-   Variant: v8A 
-   Size: 64 
-   Endian: little 
-   Compiler: default

![For "Language" select AARCH64:LE:v8A:default](https://lupyuen.github.io/images/arm-ghidra7.png)

Here's the Jumpdrive `Image` (Linux Kernel) in Ghidra...

![Ghidra with PinePhone Linux Image](https://lupyuen.github.io/images/arm-ghidra2.png)

According to the Linux Kernel Header...

-   ["Booting AArch64 Linux"](https://www.kernel.org/doc/html/latest/arm64/booting.html)

We see Linux Kernel Magic Number `ARM\x64` at offset 0x38.

Image Load Offset is 0, according to the header.

Kernel Start Address on PinePhone is 0x4008 0000.

So we shift `Image` in Ghidra to start at 0x4008 0000...

-   Click Window > Memory Map

-   Click "ram"

-   Click the 4-Arrows icon ("Move a block to another address")

-   Change "New Start Address" to 40080000

![Ghidra with PinePhone Linux Image](https://lupyuen.github.io/images/arm-ghidra3.png)

# Will NuttX Boot On PinePhone?

_So will NuttX boot on PinePhone?_

It's highly plausible! We discovered (with happiness) that NuttX already generates an Arm64 Linux Kernel Header.

So NuttX could be a drop-in replacement for the PinePhone Linux Kernel! We just need to...

-   Write PinePhone Jumpdrive to a microSD Card (with Etcher, in FAT format)

-   Overwrite `Image.gz` by the (gzipped) NuttX Binary Image `nuttx.bin.gz`

-   Insert the microSD Card into PinePhone

-   Power on PinePhone

And NuttX should (theoretically) boot on PinePhone!

As mentioned earlier, we should rebuild NuttX so that `__start` is changed to 0x4008 0000 (from 0x4028 0000), as defined in the NuttX Linker Script: [boards/arm64/qemu/qemu-a53/scripts/dramboot.ld](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/boards/arm64/qemu/qemu-a53/scripts/dramboot.ld#L30-L33)

```text
SECTIONS
{
SECTIONS
{
  . = 0x40080000;  /* PinePhone uboot load address (kernel_addr_r) */
  /* Previously: . = 0x40280000; */  /* uboot load address */
  _start = .;
```

Also the Image Load Offset in our NuttX Image Header should be changed to 0x0 (from 0x48 0000): [arch/arm64/src/common/arm64_head.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L107)

```text
    .quad   0x0000               /* PinePhone Image load offset from start of RAM */
    # Previously: .quad   0x480000              /* Image load offset from start of RAM */
```

Later we'll increase the RAM Size to 2 GB (from 128 MB): [boards/arm64/qemu/qemu-a53/configs/nsh_smp/defconfig](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/boards/arm64/qemu/qemu-a53/configs/nsh_smp/defconfig#L47-L48)

```text
/* TODO: Increase to 2 GB for PinePhone */
CONFIG_RAM_SIZE=134217728
CONFIG_RAM_START=0x40000000
```

But not right now, because it might clash with the Device Tree and RAM File System.

_But will we see anything when NuttX boots on PinePhone?_

Not yet. We'll need to implement the UART Driver for NuttX...

# UART Driver for NuttX

We won't see any output from NuttX until we implement the UART Driver for NuttX.

These are the Source Files for the QEMU UART Driver (PL011)...

-   [arch/arm64/src/qemu/qemu_serial.c](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/qemu/qemu_serial.c)

-   [arch/arm64/src/qemu/qemu_lowputc.S](https://github.com/apache/incubator-nuttx/blob/master/arch/arm64/src/qemu/qemu_lowputc.S)

    [(More about PL011 UART)](https://krinkinmu.github.io/2020/11/29/PL011.html)

We'll replace the code above with the UART Driver for Allwinner A64 SoC...

-   [UART0 Memory Map](https://linux-sunxi.org/A64/Memory_map)

-   [Allwinner A64 UART](https://linux-sunxi.org/UART)

-   [Allwinner A64 User Manual](https://linux-sunxi.org/File:Allwinner_A64_User_Manual_V1.1.pdf)

-   [Allwinner A64 Info](https://linux-sunxi.org/A64)

To access the UART Port on PinePhone, we'll use this USB Serial Debug Cable...

-   [PinePhone Serial Debug Cable](https://wiki.pine64.org/index.php/PinePhone#Serial_console)

Which connects to the Headphone Port. Genius!

[(Remember to flip the Headphone Switch to OFF)](https://wiki.pine64.org/index.php/PinePhone#Privacy_switch_configuration)

![PinePhone UART Port in disguise](https://lupyuen.github.io/images/arm-uart.jpg)

[_PinePhone UART Port in disguise_](https://wiki.pine64.org/index.php/PinePhone#Serial_console)

# PinePhone U-Boot Log

Before starting the Linux Kernel, PinePhone boots by running the U-Boot Bootloader...

-   [A64 Boot ROM](https://linux-sunxi.org/BROM#A64)

-   [A64 U-Boot](https://linux-sunxi.org/U-Boot)

-   [A64 U-Boot SPL](https://linux-sunxi.org/BROM#U-Boot_SPL_limitations)

-   [SD Card Layout](https://linux-sunxi.org/Bootable_SD_card#SD_Card_Layout)

Here's the PinePhone U-Boot Log captured with the USB Serial Debug Cable...

(Press Enter repeatedly when PinePhone powers on to enter the U-Boot Prompt)

```text
$ screen /dev/ttyUSB0 115200

DRAM: 2048 MiB
Trying to boot from MMC1
NOTICE:  BL31: v2.2(release):v2.2-904-gf9ea3a629
NOTICE:  BL31: Built : 15:32:12, Apr  9 2020
NOTICE:  BL31: Detected Allwinner A64/H64/R18 SoC (1689)
NOTICE:  BL31: Found U-Boot DTB at 0x4064410, model: PinePhone
NOTICE:  PSCI: System suspend is unavailable

U-Boot 2020.07 (Nov 08 2020 - 00:15:12 +0100)

DRAM:  2 GiB
MMC:   Device 'mmc@1c11000': seq 1 is in use by 'mmc@1c10000'
mmc@1c0f000: 0, mmc@1c10000: 2, mmc@1c11000: 1
Loading Environment from FAT... *** Warning - bad CRC, using default environment

starting USB...
No working controllers found
Hit any key to stop autoboot:

=> help
?         - alias for 'help'
base      - print or set address offset
bdinfo    - print Board Info structure
blkcache  - block cache diagnostics and control
boot      - boot default, i.e., run 'bootcmd'
bootd     - boot default, i.e., run 'bootcmd'
bootelf   - Boot from an ELF image in memory
booti     - boot Linux kernel 'Image' format from memory
bootm     - boot application image from memory
bootvx    - Boot vxWorks from an ELF image
cmp       - memory compare
coninfo   - print console devices and information
cp        - memory copy
crc32     - checksum calculation
dm        - Driver model low level access
echo      - echo args to console
editenv   - edit environment variable
env       - environment handling commands
exit      - exit script
ext2load  - load binary file from a Ext2 filesystem
ext2ls    - list files in a directory (default /)
ext4load  - load binary file from a Ext4 filesystem
ext4ls    - list files in a directory (default /)
ext4size  - determine a file's size
false     - do nothing, unsuccessfully
fatinfo   - print information about filesystem
fatload   - load binary file from a dos filesystem
fatls     - list files in a directory (default /)
fatmkdir  - create a directory
fatrm     - delete a file
fatsize   - determine a file's size
fatwrite  - write file into a dos filesystem
fdt       - flattened device tree utility commands
fstype    - Look up a filesystem type
go        - start application at address 'addr'
gpio      - query and control gpio pins
gpt       - GUID Partition Table
gzwrite   - unzip and write memory to block device
help      - print command description/usage
iminfo    - print header information for application image
imxtract  - extract a part of a multi-image
itest     - return true/false on integer compare
ln        - Create a symbolic link
load      - load binary file from a filesystem
loadb     - load binary file over serial line (kermit mode)
loads     - load S-Record file over serial line
loadx     - load binary file over serial line (xmodem mode)
loady     - load binary file over serial line (ymodem mode)
loop      - infinite loop on address range
ls        - list files in a directory (default /)
lzmadec   - lzma uncompress a memory region
md        - memory display
mm        - memory modify (auto-incrementing address)
mmc       - MMC sub system
mmcinfo   - display MMC info
mw        - memory write (fill)
nm        - memory modify (constant address)
part      - disk partition related commands
poweroff  - Perform POWEROFF of the device
printenv  - print environment variables
random    - fill memory with random pattern
reset     - Perform RESET of the CPU
run       - run commands in an environment variable
save      - save file to a filesystem
saveenv   - save environment variables to persistent storage
setenv    - set environment variables
setexpr   - set environment variable as the result of eval expression
sf        - SPI flash sub-system
showvar   - print local hushshell variables
size      - determine a file's size
sleep     - delay execution for some time
source    - run script from memory
sysboot   - command to get and boot from syslinux files
test      - minimal test like /bin/sh
true      - do nothing, successfully
unlz4     - lz4 uncompress a memory region
unzip     - unzip a memory region
usb       - USB sub-system
usbboot   - boot from USB device
version   - print monitor, compiler and linker version

=> printenv
arch=arm
baudrate=115200
board=sunxi
board_name=sunxi
boot_a_script=load ${devtype} ${devnum}:${distro_bootpart} ${scriptaddr} ${prefix}${script}; source ${scriptaddr}
boot_extlinux=sysboot ${devtype} ${devnum}:${distro_bootpart} any ${scriptaddr} ${prefix}${boot_syslinux_conf}
boot_net_usb_start=usb start
boot_prefixes=/ /boot/
boot_script_dhcp=boot.scr.uimg
boot_scripts=boot.scr.uimg boot.scr
boot_syslinux_conf=extlinux/extlinux.conf
boot_targets=fel mmc_auto usb0 
bootcmd=run distro_bootcmd
bootcmd_fel=if test -n ${fel_booted} && test -n ${fel_scriptaddr}; then echo '(FEL boot)'; source ${fel_scriptaddr}; fi
bootcmd_mmc0=devnum=0; run mmc_boot
bootcmd_mmc1=devnum=1; run mmc_boot
bootcmd_mmc_auto=if test ${mmc_bootdev} -eq 1; then run bootcmd_mmc1; run bootcmd_mmc0; elif test ${mmc_bootdev} -eq 0; then run bootcmd_mmc0; run bootcmd_mmc1; fi
bootcmd_usb0=devnum=0; run usb_boot
bootdelay=0
bootm_size=0xa000000
console=ttyS0,115200
cpu=armv8
dfu_alt_info_ram=kernel ram 0x40080000 0x1000000;fdt ram 0x4FA00000 0x100000;ramdisk ram 0x4FE00000 0x4000000
distro_bootcmd=for target in ${boot_targets}; do run bootcmd_${target}; done
ethaddr=02:ba:8c:73:bf:ca
fdt_addr_r=0x4FA00000
fdtcontroladdr=bbf4dd40
fdtfile=allwinner/sun50i-a64-pinephone.dtb
kernel_addr_r=0x40080000
mmc_boot=if mmc dev ${devnum}; then devtype=mmc; run scan_dev_for_boot_part; fi
mmc_bootdev=0
partitions=name=loader1,start=8k,size=32k,uuid=${uuid_gpt_loader1};name=loader2,size=984k,uuid=${uuid_gpt_loader2};name=esp,size=128M,bootable,uuid=${uuid_gpt_esp};name=system,size=-,uuid=${uuid_gpt_system};
preboot=usb start
pxefile_addr_r=0x4FD00000
ramdisk_addr_r=0x4FE00000
scan_dev_for_boot=echo Scanning ${devtype} ${devnum}:${distro_bootpart}...; for prefix in ${boot_prefixes}; do run scan_dev_for_extlinux; run scan_dev_for_scripts; done;
scan_dev_for_boot_part=part list ${devtype} ${devnum} -bootable devplist; env exists devplist || setenv devplist 1; for distro_bootpart in ${devplist}; do if fstype ${devtype} ${devnum}:${distro_bootpart} bootfstype; then run scan_dev_for_boot; fi; done; setenv devplist
scan_dev_for_extlinux=if test -e ${devtype} ${devnum}:${distro_bootpart} ${prefix}${boot_syslinux_conf}; then echo Found ${prefix}${boot_syslinux_conf}; run boot_extlinux; echo SCRIPT FAILED: continuing...; fi
scan_dev_for_scripts=for script in ${boot_scripts}; do if test -e ${devtype} ${devnum}:${distro_bootpart} ${prefix}${script}; then echo Found U-Boot script ${prefix}${script}; run boot_a_script; echo SCRIPT FAILED: continuing...; fi; done
scriptaddr=0x4FC00000
serial#=92c07dba8c73bfca
soc=sunxi
stderr=serial@1c28000
stdin=serial@1c28000
stdout=serial@1c28000
usb_boot=usb start; if usb dev ${devnum}; then devtype=usb; run scan_dev_for_boot_part; fi
uuid_gpt_esp=c12a7328-f81f-11d2-ba4b-00a0c93ec93b
uuid_gpt_system=b921b045-1df0-41c3-af44-4c6f280d3fae

Environment size: 2861/131068 bytes

=> boot
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
653 bytes read in 3 ms (211.9 KiB/s)
## Executing script at 4fc00000
gpio: pin 114 (gpio 114) value is 1
4275261 bytes read in 192 ms (21.2 MiB/s)
Uncompressed size: 10170376 = 0x9B3008
36162 bytes read in 4 ms (8.6 MiB/s)
1078500 bytes read in 51 ms (20.2 MiB/s)
## Flattened Device Tree blob at 4fa00000
   Booting using the fdt blob at 0x4fa00000
   Loading Ramdisk to 49ef8000, end 49fff4e4 ... OK
   Loading Device Tree to 0000000049eec000, end 0000000049ef7d41 ... OK

Starting kernel ...

/ # 
```

According to the U-Boot Log, the Start of RAM `kernel_addr_r` is 0x4008 0000.

We need to set this in the NuttX Linker Script and the NuttX Header...

# NuttX Boots On PinePhone

In the previous section, U-Boot says that the Start of RAM `kernel_addr_r` is 0x4008 0000.

Let's set this in the NuttX Linker Script and the NuttX Header...

-   Change Image Load Offset in NuttX Header to 0x0 (from 0x48000)

    [(See the changes)](https://github.com/lupyuen/incubator-nuttx/commit/9916b52f9dba17944a35aafd4c21fb9eabb17c0e#diff-a830678a9f1b0773c404196c86ad45d1ef7d7e51a52b935cd08df35f5949aaf8)

-   Change NuttX Linker Script to set the Start Address `_start` to 0x4008 0000 (from 0x4028 0000)

    [(See the changes)](https://github.com/lupyuen/incubator-nuttx/commit/9916b52f9dba17944a35aafd4c21fb9eabb17c0e#diff-d8d987cb5ba644b5f79987e42663217799e03e384552b2e8dbb041f145fa8ad1)

For PinePhone Allwinner A64 UART: We reused the previous code for transmitting output to UART...

```text
/* PL011 UART transmit character
 * xb: register which contains the UART base address
 * wt: register which contains the character to transmit
 */

.macro early_uart_transmit xb, wt
    strb  \wt, [\xb]             /* -> UARTDR (Data Register) */
.endm
```

[(Source)](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/qemu/qemu_lowputc.S#L87-L94)

But we updated the UART Register Address for Allwinner A64 UART...

```text
 /* 32-bit register definition for qemu pl011 uart */

 /* PinePhone Allwinner A64 UART0 Base Address: */
 #define UART1_BASE_ADDRESS 0x01C28000
 /* Previously: #define UART1_BASE_ADDRESS 0x9000000 */
 #define EARLY_UART_PL011_BAUD_RATE  115200
```

[(Source)](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/qemu/qemu_lowputc.S#L40-L45)

Right now we don't check if UART is ready to transmit, so our UART output will have missing characters. This needs to be fixed...

```text
/* PL011 UART wait UART to be ready to transmit
 * xb: register which contains the UART base address
 * c: scratch register number
 */

.macro early_uart_ready xb, wt
1:
    # TODO: Wait for PinePhone Allwinner A64 UART
    # ldrh  \wt, [\xb, #0x18]      /* <- UARTFR (Flag register) */
    # tst   \wt, #0x8              /* Check BUSY bit */
    # b.ne  1b                     /* Wait for the UART to be ready */
.endm
```

[(Source)](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/qemu/qemu_lowputc.S#L74-L85)

We don't init the UART Port because U-Boot has kindly done it for us. This needs to be fixed...

```text
/* PL011 UART initialization
 * xb: register which contains the UART base address
 * c: scratch register number
 */

GTEXT(up_earlyserialinit)
SECTION_FUNC(text, up_earlyserialinit)
    # TODO: Set PinePhone Allwinner A64 Baud Rate Divisor: UART_LCR (DLAB), UART_DLL, UART_DLH
    # ldr   x15, =UART1_BASE_ADDRESS
    # mov   x0, #(7372800 / EARLY_UART_PL011_BAUD_RATE % 16)
    # strh  w0, [x15, #0x28]      /* -> UARTFBRD (Baud divisor fraction) */
    # mov   x0, #(7372800 / EARLY_UART_PL011_BAUD_RATE / 16)
    # strh  w0, [x15, #0x24]      /* -> UARTIBRD (Baud divisor integer) */
    # mov   x0, #0x60             /* 8n1 */
    # str   w0, [x15, #0x2C]      /* -> UARTLCR_H (Line control) */
    # ldr   x0, =0x00000301       /* RXE | TXE | UARTEN */
    # str   w0, [x15, #0x30]      /* -> UARTCR (Control Register) */
    ret
```

[(Source)](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/qemu/qemu_lowputc.S#L55-L72)

With the above changes, NuttX boots on PinePhone yay!

![NuttX Boots On PinePhone](https://lupyuen.github.io/images/Screenshot_2022-08-26_08-04-34_080626.png)

[__Watch the Demo on YouTube__](https://youtube.com/shorts/WmRzfCiWV6o?feature=share)

# NuttX Boot Log

This is how we build NuttX for PinePhone...

```bash
## TODO: Install Build Prerequisites
## https://lupyuen.github.io/articles/uboot#install-prerequisites

## Create NuttX Directory
mkdir nuttx
cd nuttx

## Download NuttX OS for PinePhone
git clone \
    --recursive \
    --branch pinephone \
    https://github.com/lupyuen/incubator-nuttx \
    nuttx

## Download NuttX Apps for PinePhone
git clone \
    --recursive \
    --branch pinephone \
    https://github.com/lupyuen/incubator-nuttx-apps \
    apps

## We'll build NuttX inside nuttx/nuttx
cd nuttx

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

## Compress the NuttX Binary Image
cp nuttx.bin Image
rm -f Image.gz
gzip Image

## Copy compressed NuttX Binary Image to Jumpdrive microSD.
## How to create Jumpdrive microSD: https://lupyuen.github.io/articles/uboot#pinephone-jumpdrive
## TODO: Change the microSD Path
cp Image.gz "/Volumes/NO NAME"
```

Insert the Jumpdrive microSD into PinePhone and power up.

Here's the UART Log of NuttX booting on PinePhone...

```text
DRAM: 2048 MiB
Trying to boot from MMC1
NOTICE:  BL31: v2.2(release):v2.2-904-gf9ea3a629
NOTICE:  BL31: Built : 15:32:12, Apr  9 2020
NOTICE:  BL31: Detected Allwinner A64/H64/R18 SoC (1689)
NOTICE:  BL31: Found U-Boot DTB at 0x4064410, model: PinePhone
NOTICE:  PSCI: System suspend is unavailable

U-Boot 2020.07 (Nov 08 2020 - 00:15:12 +0100)

DRAM:  2 GiB
MMC:   Device 'mmc@1c11000': seq 1 is in use by 'mmc@1c10000'
mmc@1c0f000: 0, mmc@1c10000: 2, mmc@1c11000: 1
Loading Environment from FAT... *** Warning - bad CRC, using default environment

starting USB...
No working controllers found
Hit any key to stop autoboot:  0 
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
653 bytes read in 3 ms (211.9 KiB/s)
## Executing script at 4fc00000
gpio: pin 114 (gpio 114) value is 1
99784 bytes read in 8 ms (11.9 MiB/s)
Uncompressed size: 278528 = 0x44000
36162 bytes read in 4 ms (8.6 MiB/s)
1078500 bytes read in 51 ms (20.2 MiB/s)
## Flattened Device Tree blob at 4fa00000
   Booting using the fdt blob at 0x4fa00000
   Loading Ramdisk to 49ef8000, end 49fff4e4 ... OK
   Loading Device Tree to 0000000049eec000, end 0000000049ef7d41 ... OK

Starting kernel ...

HELLO NUTTX ON PINEPHONE!
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x400c4000, heap_size=0x7f3c000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
arm64_gic_initialize: GIC Version is 2
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
up_timer_initialize: _vector_table=0x400a7000
up_timer_initialize: Before writing: vbar_el1=0x40227000
up_timer_initialize: After writing: vbar_el1=0x400a7000
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x400a7000 _einit: 0x400a7000 _stext: 0x40080000 _etext: 0x400a8000
nsh: sysinit: fopen failed: 2
nshn:x _msktfaarttf:s :C PcUo0m:m aBnedg innonti nfgo uInddle  L oNouptt
 Shell (NSH) NuttX-10.3.0-RC2

nsh> uname -a
NuttX 10.3.0-RC2 fc909c6-dirty Sep  1 2022 17:05:44 arm64 qemu-a53

nsh> help
help usage:  help [-v] [<cmd>]

  .         cd        dmesg     help      mount     rmdir     true      xd        
  [         cp        echo      hexdump   mv        set       truncate  
  ?         cmp       exec      kill      printf    sleep     uname     
  basename  dirname   exit      ls        ps        source    umount    
  break     dd        false     mkdir     pwd       test      unset     
  cat       df        free      mkrd      rm        time      usleep    

Builtin Apps:
  getprime  hello     nsh       ostest    sh        

nsh> hello
task_spawn: name=hello entry=0x4009b1a0 file_actions=0x400c9580 attr=0x400c9588 argv=0x400c96d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
Hello, World!!

nsh> ls /dev
/dev:
 console
 null
 ram0
 ram2
 ttyS0
 zero
```

[__Watch the Demo on YouTube__](https://youtube.com/shorts/WmRzfCiWV6o?feature=share)

The output is slightly garbled, the UART Driver needs fixing.

# Interrupt Controller

Let's talk about the __Arm Generic Interrupt Controller (GIC)__ for PinePhone...

```text
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
arm64_gic_initialize: GIC Version is 2
```

This is the current implementation of [Arm GIC Version 3](https://developer.arm.com/documentation/ihi0069/latest) in NuttX Arm64...

-   [arch/arm64/src/common/arm64_gicv3.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gicv3.c)

-   [arch/arm64/src/common/arm64_gic.h](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gic.h)

This implementation won't work on PinePhone, so we have commented out the existing code and inserted our own implementation.

_Why won't Arm GIC Version 3 work on PinePhone?_

According to the Allwinner A64 SoC User Manual (page 210, "GIC"), PinePhone's Interrupt Controller runs on...

-   [Arm GIC PL400](https://developer.arm.com/documentation/ddi0471/b/introduction/about-the-gic-400), which is based on...

-   [Arm GIC Version 2](https://developer.arm.com/documentation/ihi0048/latest/)

We'll have to downgrade [arm64_gicv3.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gicv3.c) to support Arm GIC Version 2 for PinePhone.

_Does NuttX implement Arm GIC Version 2?_

NuttX has an implementation of Arm GIC Version 2, but it's based on Arm32. We'll port it from Arm32 to Arm64...

-   [arch/arm/src/armv7-a/arm_gicv2.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm/src/armv7-a/arm_gicv2.c)

-   [arch/arm/src/armv7-a/arm_gicv2_dump.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm/src/armv7-a/arm_gicv2_dump.c)

-   [arch/arm/src/armv7-a/gic.h](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm/src/armv7-a/gic.h)

-   [arch/arm/src/armv7-a/mpcore.h](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm/src/armv7-a/mpcore.h)

-   [arch/arm/src/imx6/chip.h](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm/src/imx6/chip.h)

-   [arch/arm/src/imx6/hardware/imx_memorymap.h](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm/src/imx6/hardware/imx_memorymap.h)

By reusing the code above, we have implemented Arm GIC Version 2 for PinePhone...

-   [arch/arm64/src/common/arm64_gicv3.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gicv3.c#L765-L823)

We made minor tweaks to NuttX's implementation of GIC Version 2...

-   [Changes for arch/arm/src/armv7-a/arm_gicv2.c](https://github.com/lupyuen/incubator-nuttx/commit/6fa0e7e5d2beddad07890c83d2ee428a3f2b8a62#diff-6e1132aef124dabaf94c200ab06d65c7bc2b9967bf76a46aba71a7f43b5fb219)

-   [Changes for arch/arm/src/armv7-a/arm_gicv2_dump.c](https://github.com/lupyuen/incubator-nuttx/commit/4fc2669fef62d12ba1dd428f2daf03d3bc362501#diff-eb05c977988d59202a9472f6fa7f9dc290724662ad6d15a4ba99b8f1fc1dc8f8)

-   [Changes for arch/arm/src/armv7-a/gic.h](https://github.com/lupyuen/incubator-nuttx/commit/6fa0e7e5d2beddad07890c83d2ee428a3f2b8a62#diff-b4fcb67b71de954c942ead9bb0868e720a5802c90743f0a1883f84b7565e1a0f)

_Where in memory is the GIC located?_

According to the Allwinner A64 SoC User Manual (page 74, "Memory Mapping"), the GIC is located at this address...

| Module | Address (It is for Cluster CPU) | Remarks
| :----- | :------ | :------
|SCU space | 0x01C80000| (What's this?)
| | GIC_DIST: 0x01C80000 + 0x1000| GIC Distributor (GICD)
|CPUS can’t access | GIC_CPUIF:0x01C80000 + 0x2000| GIC CPU Interface (GICC)

(Why "CPUS can’t access"?)

The __Interrupt Sources__ are defined in the Allwinner A64 SoC User Manual (page 210, "GIC")...

-   16 x Software-Generated Interrupts (SGI)

    "This is an interrupt generated by software writing to a GICD_SGIR register in the GIC. The system uses SGIs for interprocessor communication."

-   16 x Private Peripheral Interrupts (PPI)

    "This is a peripheral interrupt that is specific to a single processor"

-   125 x Shared Peripheral Interrupts (SPI)

    "This is a peripheral interrupt that the Distributor can route to any of a specified combination of processors"

To verify the GIC Version, read the __Peripheral ID2 Register (ICPIDR2)__ at Offset 0xFE8 of GIC Distributor.

Bits 4 to 7 of ICPIDR2 are...

-   0x1 for GIC Version 1
-   0x2 for GIC Version 2

This is how we implement the GIC Version verification: [arch/arm64/src/common/arm64_gicv3.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gicv3.c#L710-L734)

```c
// Init GIC v2 for PinePhone. See https://github.com/lupyuen/pinephone-nuttx#interrupt-controller
int arm64_gic_initialize(void)
{
  sinfo("TODO: Init GIC for PinePhone\n");

  // To verify the GIC Version, read the Peripheral ID2 Register (ICPIDR2) at Offset 0xFE8 of GIC Distributor.
  // Bits 4 to 7 of ICPIDR2 are...
  // - 0x1 for GIC Version 1
  // - 0x2 for GIC Version 2
  // GIC Distributor is at 0x01C80000 + 0x1000.
  // See https://github.com/lupyuen/pinephone-nuttx#interrupt-controller
  const uint8_t *ICPIDR2 = (const uint8_t *) (CONFIG_GICD_BASE + 0xFE8);
  uint8_t version = (*ICPIDR2 >> 4) & 0b1111;
  sinfo("GIC Version is %d\n", version);
  DEBUGASSERT(version == 2);

  // arm_gic0_initialize must be called on CPU0
  arm_gic0_initialize();

  // arm_gic_initialize must be called for all CPUs
  // TODO: Move to arm64_gic_secondary_init
  arm_gic_initialize();

  return 0;
}
```

See below for the [GIC Register Dump](https://github.com/lupyuen/pinephone-nuttx#gic-register-dump).

# Multi Core SMP

Right now NuttX is configured to run on a Single Core for PinePhone.

To support all 4 Cores on PinePhone with SMP (Symmetric Multi-Processing), we need to fix these in the Generic Interrupt Controller Version 2...

https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gicv3.c#L717-L743

```c
// Init GIC v2 for PinePhone. See https://github.com/lupyuen/pinephone-nuttx#interrupt-controller
int arm64_gic_initialize(void)
{
  ...
  // arm_gic0_initialize must be called on CPU0
  arm_gic0_initialize();

  // arm_gic_initialize must be called for all CPUs
  // TODO: Move to arm64_gic_secondary_init
  arm_gic_initialize();
```

https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gicv3.c#L746-L761

```c
#ifdef CONFIG_SMP
...
// TODO: Init GIC for PinePhone
void arm64_gic_secondary_init(void)
{
  sinfo("TODO: Init GIC Secondary for PinePhone\n");

  //  TODO: arm_gic_initialize must be called for all CPUs.
  arm_gic_initialize();
}
#endif  //  NOTUSED
```

And we rebuild NuttX for Multi Core...

```bash
## Erase the NuttX Configuration
make distclean

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

# System Timer 

NuttX starts the System Timer when it boots. Here's how the System Timer is started: [arch/arm64/src/common/arm64_arch_timer.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.c#L212-L233)

```c
void up_timer_initialize(void)
{
  uint64_t curr_cycle;

  arch_timer_rate   = arm64_arch_timer_get_cntfrq();
  cycle_per_tick    = ((uint64_t)arch_timer_rate / (uint64_t)TICK_PER_SEC);

  sinfo("%s: cp15 timer(s) running at %lu.%02luMHz, cycle %ld\n", __func__,
        (unsigned long)arch_timer_rate / 1000000,
        (unsigned long)(arch_timer_rate / 10000) % 100, cycle_per_tick);

  irq_attach(ARM_ARCH_TIMER_IRQ, arm64_arch_timer_compare_isr, 0);
  arm64_gic_irq_set_priority(ARM_ARCH_TIMER_IRQ, ARM_ARCH_TIMER_PRIO,
                             ARM_ARCH_TIMER_FLAGS);

  curr_cycle = arm64_arch_timer_count();
  arm64_arch_timer_set_compare(curr_cycle + cycle_per_tick);
  arm64_arch_timer_enable(true);

  up_enable_irq(ARM_ARCH_TIMER_IRQ);
  arm64_arch_timer_set_irq_mask(false);
}
```

At every tick, the System Timer triggers an interrupt that calls [`arm64_arch_timer_compare_isr`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.c#L109-L169)

(`CONFIG_SCHED_TICKLESS` is undefined)

__Timer IRQ `ARM_ARCH_TIMER_IRQ`__ is defined in [arch/arm64/src/common/arm64_arch_timer.h](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.h#L38-L45)

```c
#define CONFIG_ARM_TIMER_SECURE_IRQ         (GIC_PPI_INT_BASE + 13)
#define CONFIG_ARM_TIMER_NON_SECURE_IRQ     (GIC_PPI_INT_BASE + 14)
#define CONFIG_ARM_TIMER_VIRTUAL_IRQ        (GIC_PPI_INT_BASE + 11)
#define CONFIG_ARM_TIMER_HYP_IRQ            (GIC_PPI_INT_BASE + 10)

#define ARM_ARCH_TIMER_IRQ	CONFIG_ARM_TIMER_VIRTUAL_IRQ
#define ARM_ARCH_TIMER_PRIO	IRQ_DEFAULT_PRIORITY
#define ARM_ARCH_TIMER_FLAGS	IRQ_TYPE_LEVEL
```

`GIC_PPI_INT_BASE` is defined in [arch/arm64/src/common/arm64_gic.h](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gic.h#L120-L128)

```c
#define GIC_SGI_INT_BASE            0
#define GIC_PPI_INT_BASE            16
#define GIC_IS_SGI(intid)           (((intid) >= GIC_SGI_INT_BASE) && \
                                     ((intid) < GIC_PPI_INT_BASE))

#define GIC_SPI_INT_BASE            32
#define GIC_NUM_INTR_PER_REG        32
#define GIC_NUM_CFG_PER_REG         16
#define GIC_NUM_PRI_PER_REG         4
```

# Timer Interrupt Isn't Handled

Previously NuttX hangs midsentence while booting on PinePhone, let's find out how we fixed it...

```text
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
arm64_gic_initialize: GIC Version is 2
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
uart_regi
```

Based on our experiments, it seems the [System Timer](https://github.com/lupyuen/pinephone-nuttx#system-timer) triggered a Timer Interrupt, and NuttX hangs while attempting to handle the Timer Interrupt.

The Timer Interrupt Handler [`arm64_arch_timer_compare_isr`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.c#L109-L169) is never called. (We checked using [`up_putc`](https://github.com/lupyuen/pinephone-nuttx#boot-debugging))

_Is it caused by PinePhone's GIC?_

This problem doesn't seem to be caused by [PinePhone's Generic Interrupt Controller (GIC)](https://github.com/lupyuen/pinephone-nuttx#interrupt-controller) that we have implemented. We [successfully tested PinePhone's GIC](https://github.com/lupyuen/pinephone-nuttx#test-pinephone-gic-with-qemu) with QEMU.

Let's troubleshoot the Timer Interrupt...

-   We called [`up_putc`](https://github.com/lupyuen/pinephone-nuttx#boot-debugging) to understand [how Interrupts are handled on NuttX](https://github.com/lupyuen/pinephone-nuttx#handling-interrupts).

    We also added Debug Code to the [Arm64 Interrupt Handler](https://github.com/lupyuen/pinephone-nuttx#interrupt-debugging).

    [(Maybe we should have used GDB with QEMU)](https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53) 

-   We [dumped the Interrupt Vector Table](https://github.com/lupyuen/pinephone-nuttx#dump-interrupt-vector-table).

    We verified that the Timer Interrupt Handler Address in the table is correct.

-   We confirmed that [Interrupt Dispatcher `irq_dispatch`](https://github.com/lupyuen/pinephone-nuttx#handling-interrupts) isn't called.

    And [Unexpected Interrupt Handler `irq_unexpected_isr`](https://github.com/lupyuen/pinephone-nuttx#handling-interrupts) isn't called either.

-   Let's backtrack, maybe there's a problem in the Arm64 Interrupt Handler?

    But [`arm64_enter_exception`](https://github.com/lupyuen/pinephone-nuttx#handling-interrupts) and [`arm64_irq_handler`](https://github.com/lupyuen/pinephone-nuttx#handling-interrupts) aren't called either.

-   Maybe the __Arm64 Vector Table `_vector_table`__ isn't correctly configured?

    [arch/arm64/src/common/arm64_vector_table.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vector_table.S#L93-L232)

And we're right! The Arm64 Vector Table is indeed incorrectly configured! Here why...

# Arm64 Vector Table Is Wrong

Earlier we saw that the Interrupt Handler wasn't called for System Timer Interrupt. And it might be due to problems in the __Arm64 Vector Table `_vector_table`__: [arch/arm64/src/common/arm64_vector_table.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vector_table.S#L93-L232)

Let's check whether the Arm64 Vector Table `_vector_table` is correctly configured in the Arm CPU: [arch/arm64/src/common/arm64_arch_timer.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.c#L212-L235)

```c
void up_timer_initialize(void)
{
  ...
  // Attach System Timer Interrupt Handler
  irq_attach(ARM_ARCH_TIMER_IRQ, arm64_arch_timer_compare_isr, 0);

  // For PinePhone: Read Vector Base Address Register EL1
  extern void *_vector_table[];
  sinfo("_vector_table=%p\n", _vector_table);
  sinfo("Before writing: vbar_el1=%p\n", read_sysreg(vbar_el1));
```

After attaching the Interrupt Handler for System Timer, we read the Arm64 [Vector Base Address Register EL1](https://github.com/lupyuen/pinephone-nuttx#handling-interrupts). Here's the output...

```text
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
up_timer_initialize: _vector_table=0x400a7000
up_timer_initialize: Before writing: vbar_el1=0x40227000
```

Aha! `_vector_table` is at 0x400a7000... But Vector Base Address Register EL1 says 0x40227000!

Our Arm64 CPU is pointing to the wrong Arm64 Vector Table... Hence our Interrupt Handler is never called!

Let's fix the Vector Base Address Register EL1: [arch/arm64/src/common/arm64_arch_timer.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.c#L212-L235)

```c
  // For PinePhone: Write Vector Base Address Register EL1
  write_sysreg((uint64_t)_vector_table, vbar_el1);
  ARM64_ISB();

  // For PinePhone: Read Vector Base Address Register EL1
  sinfo("After writing: vbar_el1=%p\n", read_sysreg(vbar_el1));
```

This writes the correct value of `_vector_table` back into Vector Base Address Register EL1. Here's the output...

```text
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
up_timer_initialize: _vector_table=0x400a7000
up_timer_initialize: Before writing: vbar_el1=0x40227000
up_timer_initialize: After writing: vbar_el1=0x400a7000
```

Yep Vector Base Address Register EL1 is now correct.

And our Interrupt Handlers are now working fine yay!

# Test PinePhone GIC with QEMU

This is how we build NuttX for QEMU with [Generic Interrupt Controller (GIC) Version 2](https://github.com/lupyuen/pinephone-nuttx#interrupt-controller)...

```bash
## TODO: Install Build Prerequisites
## https://lupyuen.github.io/articles/uboot#install-prerequisites

## Create NuttX Directory
mkdir nuttx
cd nuttx

## Download NuttX OS for QEMU with GIC Version 2
git clone \
    --recursive \
    --branch gicv2 \
    https://github.com/lupyuen/incubator-nuttx \
    nuttx

## Download NuttX Apps for QEMU
git clone \
    --recursive \
    --branch arm64 \
    https://github.com/lupyuen/incubator-nuttx-apps \
    apps

## We'll build NuttX inside nuttx/nuttx
cd nuttx

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

And this is how we tested PinePhone's GIC Version 2 with QEMU...

```bash
## Run GIC v2 with QEMU
qemu-system-aarch64 \
  -smp 4 \
  -cpu cortex-a53 \
  -nographic \
  -machine virt,virtualization=on,gic-version=2 \
  -net none \
  -chardev stdio,id=con,mux=on \
  -serial chardev:con \
  -mon chardev=con,mode=readline \
  -kernel ./nuttx
```

Note that `gic-version=2`, instead of the usual GIC Version 3 for NuttX Arm64.

Also we simulated 4 Cores of Arm Cortex-A53 (similar to PinePhone): `-smp 4`

QEMU boots OK with PinePhone's GIC Version 2...

```text
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x402c4000, heap_size=0x7d3c000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x8000000
arm64_gic_initialize: CONFIG_GICR_BASE=0x8010000
arm64_gic_initialize: GIC Version is 2
EFGHup_timer_initialize: up_timer_initialize: cp15 timer(s) running at 62.50MHz, cycle 62500
AKLMNOPBIJuart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
AKLMNOPBIJwork_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x402a7000 _einit: 0x402a7000 _stext: 0x40280000 _etext: 0x402a8000
nsh: sysinit: fopen failed: 2
nsh: mkfatfs: command not found

NuttShell (NSH) NuttX-10.3.0-RC2
nsh> nx_start: CPU0: Beginning Idle Loop
```

So our implementation of GIC Version 2 for PinePhone is probably OK.

_Is the Timer Interrupt triggered correctly with PinePhone GIC?_

Yes, we verified that the Timer Interrupt Handler [`arm64_arch_timer_compare_isr`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.c#L109-L169) is  called periodically. (We checked using [`up_putc`](https://github.com/lupyuen/pinephone-nuttx#boot-debugging))

_How did we get the GIC Base Addresses?_

```text
arm64_gic_initialize: CONFIG_GICD_BASE=0x8000000
arm64_gic_initialize: CONFIG_GICR_BASE=0x8010000
```

We got the GIC v2 Base Addresses for GIC Distributor (`CONFIG_GICD_BASE`) and GIC CPU Interface (`CONFIG_GICR_BASE`) by dumping the Device Tree from QEMU...

```bash
## GIC v2 Dump Device Tree
qemu-system-aarch64 \
  -smp 4 \
  -cpu cortex-a53 \
  -nographic \
  -machine virt,virtualization=on,gic-version=2,dumpdtb=gicv2.dtb \
  -net none \
  -chardev stdio,id=con,mux=on \
  -serial chardev:con \
  -mon chardev=con,mode=readline \
  -kernel ./nuttx

## Convert Device Tree to text format
dtc -o gicv2.dts -O dts -I dtb gicv2.dtb
```

The Base Addresses are revealed in the GIC v2 Device Tree: [gicv2.dts](https://github.com/lupyuen/incubator-nuttx/blob/gicv2/gicv2.dts#L324)...

```text
intc@8000000 {
reg = <
    0x00 0x8000000 0x00 0x10000  //  GIC Distributor:   0x8000000
    0x00 0x8010000 0x00 0x10000  //  GIC CPU Interface: 0x8010000
    0x00 0x8030000 0x00 0x10000  //  VGIC Virtual Interface Control: 0x8030000
    0x00 0x8040000 0x00 0x10000  //  VGIC Virtual CPU Interface:     0x8040000
>;
compatible = "arm,cortex-a15-gic";
```

[(More about this)](https://www.kernel.org/doc/Documentation/devicetree/bindings/interrupt-controller/arm%2Cgic.txt)

We defined the Base Addresses in [arch/arm64/include/qemu/chip.h](https://github.com/lupyuen/incubator-nuttx/blob/gicv2/arch/arm64/include/qemu/chip.h#L38-L40)

Compare the above Base Addresses with the GIC v3 Device Tree: [gicv3.dts](https://github.com/lupyuen/incubator-nuttx/blob/gicv2/gicv3.dts#L324)

```text
intc@8000000 {
reg = <
    0x00 0x8000000 0x00 0x10000   //  GIC Distributor:   0x8000000
    0x00 0x80a0000 0x00 0xf60000  //  GIC CPU Interface: 0x80a0000
>;
#redistributor-regions = <0x01>;
compatible = "arm,gic-v3";
```

This is how we copied the PinePhone GIC v2 Source Files into NuttX QEMU Arm64 for testing...

```bash
cp ~/PinePhone/nuttx/nuttx/arch/arm64/src/common/arm64_gicv3.c      ~/gicv2/nuttx/nuttx/arch/arm64/src/common/arm64_gicv3.c
cp ~/PinePhone/nuttx/nuttx/arch/arm/src/armv7-a/arm_gicv2.c         ~/gicv2/nuttx/nuttx/arch/arm/src/armv7-a/arm_gicv2.c
cp ~/PinePhone/nuttx/nuttx/arch/arm/src/armv7-a/gic.h               ~/gicv2/nuttx/nuttx/arch/arm/src/armv7-a/gic.h
cp ~/PinePhone/nuttx/nuttx/arch/arm/src/armv7-a/arm_gicv2_dump.c    ~/gicv2/nuttx/nuttx/arch/arm/src/armv7-a/arm_gicv2_dump.c
cp ~/PinePhone/nuttx/nuttx/arch/arm64/src/common/arm64_arch_timer.c ~/gicv2/nuttx/nuttx/arch/arm64/src/common/arm64_arch_timer.c
```

# Handling Interrupts

Let's talk about NuttX and how it handles interrupts.

The __Interrupt Vector Table__ is defined in [sched/irq/irq_initialize.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/sched/irq/irq_initialize.c#L47-L53)

```c
/* This is the interrupt vector table */
struct irq_info_s g_irqvector[NR_IRQS];
```

(Next section talks about dumping the Interrupt Vector Table)

At startup, the Interrupt Vector Table is initialised to the __Unexpected Interrupt Handler `irq_unexpected_isr`__: [sched/irq/irq_initialize.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/sched/irq/irq_initialize.c#L59-L85)

```c
/****************************************************************************
 * Name: irq_initialize
 * Description:
 *   Configure the IRQ subsystem
 ****************************************************************************/
void irq_initialize(void)
{
  /* Point all interrupt vectors to the unexpected interrupt */
  for (i = 0; i < NR_IRQS; i++)
    {
      g_irqvector[i].handler = irq_unexpected_isr;
    }
  up_irqinitialize();
}
```

__Unexpected Interrupt Handler `irq_unexpected_isr`__ is called when an Interrupt is triggered and there's no Interrupt Handler attached to the Interrupt: [sched/irq/irq_unexpectedisr.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/sched/irq/irq_unexpectedisr.c#L38-L59)

```c
/****************************************************************************
 * Name: irq_unexpected_isr
 * Description:
 *   An interrupt has been received for an IRQ that was never registered
 *   with the system.
 ****************************************************************************/
int irq_unexpected_isr(int irq, FAR void *context, FAR void *arg)
{
  up_irq_save();
  _err("ERROR irq: %d\n", irq);
  PANIC();
```

To __attach an Interrupt Handler__, we set the Handler and the Argument in the Interrupt Vector Table: [sched/irq/irq_attach.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/sched/irq/irq_attach.c#L37-L136)

```c
/****************************************************************************
 * Name: irq_attach
 * Description:
 *   Configure the IRQ subsystem so that IRQ number 'irq' is dispatched to
 *   'isr'
 ****************************************************************************/
int irq_attach(int irq, xcpt_t isr, FAR void *arg)
{
  ...
  /* Save the new ISR and its argument in the table. */
  g_irqvector[irq].handler = isr;
  g_irqvector[irq].arg     = arg;
```

When an __Interrupt is triggered__...

1.  Arm CPU looks up the __Arm64 Vector Table `_vector_table`__: [arch/arm64/src/common/arm64_vector_table.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vector_table.S#L93-L232)

    ```text
    /* Four types of exceptions:
    * - synchronous: aborts from MMU, SP/CP alignment checking, unallocated
    *   instructions, SVCs/SMCs/HVCs, ...)
    * - IRQ: group 1 (normal) interrupts
    * - FIQ: group 0 or secure interrupts
    * - SError: fatal system errors
    *
    * Four different contexts:
    * - from same exception level, when using the SP_EL0 stack pointer
    * - from same exception level, when using the SP_ELx stack pointer
    * - from lower exception level, when this is AArch64
    * - from lower exception level, when this is AArch32
    *
    * +------------------+------------------+-------------------------+
    * |     Address      |  Exception type  |       Description       |
    * +------------------+------------------+-------------------------+
    * | VBAR_ELn + 0x000 | Synchronous      | Current EL with SP0     |
    * |          + 0x080 | IRQ / vIRQ       |                         |
    * |          + 0x100 | FIQ / vFIQ       |                         |
    * |          + 0x180 | SError / vSError |                         |
    * +------------------+------------------+-------------------------+
    * |          + 0x200 | Synchronous      | Current EL with SPx     |
    * |          + 0x280 | IRQ / vIRQ       |                         |
    * |          + 0x300 | FIQ / vFIQ       |                         |
    * |          + 0x380 | SError / vSError |                         |
    * +------------------+------------------+-------------------------+
    * |          + 0x400 | Synchronous      | Lower EL using  AArch64 |
    * |          + 0x480 | IRQ / vIRQ       |                         |
    * |          + 0x500 | FIQ / vFIQ       |                         |
    * |          + 0x580 | SError / vSError |                         |
    * +------------------+------------------+-------------------------+
    * |          + 0x600 | Synchronous      | Lower EL using AArch64  |
    * |          + 0x680 | IRQ / vIRQ       |                         |
    * |          + 0x700 | FIQ / vFIQ       |                         |
    * |          + 0x780 | SError / vSError |                         |
    * +------------------+------------------+-------------------------+
    */
    GTEXT(_vector_table)
    SECTION_SUBSEC_FUNC(exc_vector_table,_vector_table_section,_vector_table)
        ...
        /* Current EL with SP0 / IRQ */
        .align 7
        arm64_enter_exception x0, x1
        b    arm64_irq_handler
        ...
        /* Current EL with SPx / IRQ */
        .align 7
        arm64_enter_exception x0, x1
        b    arm64_irq_handler
    ```

    [(`arm64_enter_exception` is defined here)](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vector_table.S#L41-L87)

1.  Based on the Arm64 Vector Table `_vector_table`, Arm CPU jumps to `arm64_irq_handler`: [arch/arm64/src/common/arm64_vectors.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S#L326-L413)

    ```text
    /****************************************************************************
    * Name: arm64_irq_handler
    * Description:
    *   Interrupt exception handler
    ****************************************************************************/
    GTEXT(arm64_irq_handler)
    SECTION_FUNC(text, arm64_irq_handler)
        ...
        /* Call arm64_decodeirq() on the interrupt stack
        * with interrupts disabled
        */
        bl     arm64_decodeirq
    ```

1.  `arm64_irq_handler` calls `arm64_decodeirq` to decode the Interrupt: [arch/arm64/src/common/arm64_gicv3.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gicv3.c#L800-L829)

    ```c
    /***************************************************************************
    * Name: arm64_decodeirq
    * Description:
    *   This function is called from the IRQ vector handler in arm64_vectors.S.
    *   At this point, the interrupt has been taken and the registers have
    *   been saved on the stack.  This function simply needs to determine the
    *   the irq number of the interrupt and then to call arm_doirq to dispatch
    *   the interrupt.
    *  Input Parameters:
    *   regs - A pointer to the register save area on the stack.
    ***************************************************************************/
    // Decode IRQ for PinePhone, based on arm_decodeirq in arm_gicv2.c
    uint64_t * arm64_decodeirq(uint64_t * regs)
    {
      ...
      if (irq < NR_IRQS)
        {
          /* Dispatch the interrupt */

          regs = arm64_doirq(irq, regs);
    ```

1.  `arm64_decodeirq` calls `arm64_doirq` to dispatch the Interrupt: [arch/arm64/src/common/arm64_doirq.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_doirq.c#L64-L119)

    ```c
    /****************************************************************************
     * Name: arm64_doirq
    * Description:
    *   Receives the decoded GIC interrupt information and dispatches control
    *   to the attached interrupt handler.
    *
    ****************************************************************************/
    uint64_t *arm64_doirq(int irq, uint64_t * regs)
    {
      ...
      /* Deliver the IRQ */
      irq_dispatch(irq, regs);
    ```

1.  `irq_dispatch` calls the Interrupt Handler fetched from the Interrupt Vector Table: [sched/irq/irq_dispatch.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/sched/irq/irq_dispatch.c#L115-L173)

    ```c
    /****************************************************************************
     * Name: irq_dispatch
    * Description:
    *   This function must be called from the architecture-specific logic in
    *   order to dispatch an interrupt to the appropriate, registered handling
    *   logic.
    ****************************************************************************/
    void irq_dispatch(int irq, FAR void *context)
    {
      if ((unsigned)irq < NR_IRQS)
        {
          if (g_irqvector[ndx].handler)
            {
              vector = g_irqvector[ndx].handler;
              arg    = g_irqvector[ndx].arg;
            }
        }
      /* Then dispatch to the interrupt handler */
      CALL_VECTOR(ndx, vector, irq, context, arg);
    ```

_How is the [Arm64 Vector Table `_vector_table`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vector_table.S#L93-L232) configured in the Arm CPU?_

The [Arm64 Vector Table `_vector_table`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vector_table.S#L93-L232) is configured in the Arm CPU during EL1 Init by `arm64_boot_el1_init`: [arch/arm64/src/common/arm64_boot.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_boot.c#L132-L162)

```c
void arm64_boot_el1_init(void)
{
  /* Setup vector table */
  write_sysreg((uint64_t)_vector_table, vbar_el1);
  ARM64_ISB();
```

`vbar_el1` refers to __Vector Base Address Register EL1__.

[(See Arm Cortex-A53 Technical Reference Manual, page 4-121, "Vector Base Address Register, EL1")](https://documentation-service.arm.com/static/5e9075f9c8052b1608761519?token=)

[(Arm64 Vector Table is also configured during EL3 Init by `arm64_boot_el3_init`)](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_boot.c#L39-L75)

EL1 Init `arm64_boot_el1_init` is called by our Startup Code: [arch/arm64/src/common/arm64_head.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L216-L230)

```text
    PRINT(switch_el1, "- Boot from EL1\r\n")

    /* EL1 init */
    bl    arm64_boot_el1_init

    /* set SP_ELx and Enable SError interrupts */
    msr   SPSel, #1
    msr   DAIFClr, #(DAIFCLR_ABT_BIT)
    isb

jump_to_c_entry:
    PRINT(jump_to_c_entry, "- Boot to C runtime for OS Initialize\r\n")
    ret x25
```

_What are EL1 and EL3?_

According to [Arm Cortex-A53 Technical Reference Manual](https://documentation-service.arm.com/static/5e9075f9c8052b1608761519?token=) page 3-5 ("Exception Level")...

> The ARMv8 exception model defines exception levels EL0-EL3, where:

> - EL0 has the lowest software execution privilege, and execution at EL0 is called unprivileged execution.

> - Increased exception levels, from 1 to 3, indicate increased software execution privilege.

> - EL2 provides support for processor virtualization.

> - EL3 provides support for a secure state, see Security state on page 3-6.

PinePhone only uses EL1 and EL2 (but not EL3)...

```text
HELLO NUTTX ON PINEPHONE!
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
```

From this we see that NuttX runs mostly in EL1.

(EL1 is less privileged than EL2, which supports Processor Virtualization)

# Dump Interrupt Vector Table

This is how we dump the Interrupt Vector Table to troubleshoot Interrupts...

Based on [arch/arm64/src/common/arm64_arch_timer.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.c#L210-L240)

```c
#include "irq/irq.h" // For dumping Interrupt Vector Table

void up_timer_initialize(void)
{
  ...
  // Attach System Timer Interrupt Handler
  irq_attach(ARM_ARCH_TIMER_IRQ, arm64_arch_timer_compare_isr, 0);

  // Begin dumping Interrupt Vector Table
  sinfo("ARM_ARCH_TIMER_IRQ=%d\n", ARM_ARCH_TIMER_IRQ);
  sinfo("arm64_arch_timer_compare_isr=%p\n", arm64_arch_timer_compare_isr);
  sinfo("irq_unexpected_isr=%p\n", irq_unexpected_isr);
  for (int i = 0; i < NR_IRQS; i++)
    {
      sinfo("g_irqvector[%d].handler=%p\n", i, g_irqvector[i].handler);
    }
  // End dumping Interrupt Vector Table
```

This code runs at startup to attach the very first Interrupt Handler, for the [System Timer Interrupt](https://github.com/lupyuen/pinephone-nuttx#system-timer).

We see that the System Timer Interrupt Number (IRQ) is 27...

```text
up_timer_initialize: ARM_ARCH_TIMER_IRQ=27
up_timer_initialize: arm64_arch_timer_compare_isr=0x4009ae18
up_timer_initialize: irq_unexpected_isr=0x400820e0

up_timer_initialize: g_irqvector[0].handler=0x400820e0
...
up_timer_initialize: g_irqvector[26].handler=0x400820e0
up_timer_initialize: g_irqvector[27].handler=0x4009ae18
up_timer_initialize: g_irqvector[28].handler=0x400820e0
...
up_timer_initialize: g_irqvector[219].handler=0x400820e0
```

All entries in the Interrupt Vector Table point to the [Unexpected Interrupt Handler `irq_unexpected_isr`](https://github.com/lupyuen/pinephone-nuttx#handling-interrupts), except for `g_irqvector[27]` which points to the [System Timer Interrupt Handler `arm64_arch_timer_compare_isr`](https://github.com/lupyuen/pinephone-nuttx#system-timer).

# Interrupt Debugging

_Can we debug the Arm64 Interrupt Handler?_

Yep we can write to the UART Port like this...

Based on [arch/arm64/src/common/arm64_vectors.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S#L326-L413)

```text
# PinePhone Allwinner A64 UART0 Base Address
#define UART1_BASE_ADDRESS 0x01C28000

# QEMU UART Base Address
# Previously: #define UART1_BASE_ADDRESS 0x9000000

/****************************************************************************
 * Name: arm64_irq_handler
 * Description:
 *   Interrupt exception handler
 ****************************************************************************/
GTEXT(arm64_irq_handler)
SECTION_FUNC(text, arm64_irq_handler)

    mov   x0, #84                 /* For Debug: 'T' */
    ldr   x1, =UART1_BASE_ADDRESS /* For Debug */
    strb  w0, [x1]                /* For Debug */

    /* switch to IRQ stack and save current sp on it. */
    ...
```

This will print "T" on the console whenever the Arm64 CPU triggers an Interrupt. (Assuming that the UART Buffer hasn't overflowed)

We can insert this debug code for every handler in [arch/arm64/src/common/arm64_vectors.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S)...

-   [`arm64_sync_exc`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S#L172-L324): Handle synchronous exception

-   [`arm64_irq_handler`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S#L326-L413): Interrupt exception handler

-   [`arm64_serror_handler`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S#L401-L413): SError handler (Fatal System Errors)

-   [`arm64_mode32_error`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S#L415-L425): Mode32 Error

-   [`arm64_irq_spurious`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S#L427-L438): Spurious Interrupt

This is how we insert the debug code for every handler in [arm64_vectors.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vectors.S): https://gist.github.com/lupyuen/4bea83c61704080f1af18abfda63c77e

We can do the same for the __Arm64 Vector Table__: [arch/arm64/src/common/arm64_vector_table.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_vector_table.S#L47-L75)

```text
# PinePhone Allwinner A64 UART0 Base Address
#define UART1_BASE_ADDRESS 0x01C28000

# QEMU UART Base Address
# Previously: #define UART1_BASE_ADDRESS 0x9000000

/* Save Corruptible Registers and exception context
 * on the task stack
 * note: allocate stackframe with XCPTCONTEXT_GP_REGS
 *     which is ARM64_ESF_REGS + ARM64_CS_REGS
 *     but only save ARM64_ESF_REGS
 */
.macro arm64_enter_exception xreg0, xreg1
    sub    sp, sp, #8 * XCPTCONTEXT_GP_REGS

    stp    x0,  x1,  [sp, #8 * REG_X0]
    stp    x2,  x3,  [sp, #8 * REG_X2]
    ...
    stp    x28, x29, [sp, #8 * REG_X28]

    mov   x0, #88                 /* For Debug: 'X' */
    ldr   x1, =UART1_BASE_ADDRESS /* For Debug */
    strb  w0, [x1]                /* For Debug */
```

# Memory Map

PinePhone depends on Arm's Memory Management Unit (MMU). We defined two MMU Memory Regions for PinePhone: RAM and Device I/O: [arch/arm64/include/qemu/chip.h](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/include/qemu/chip.h#L38-L62)

```c
// PinePhone Generic Interrupt Controller
// GIC_DIST:  0x01C80000 + 0x1000
// GIC_CPUIF: 0x01C80000 + 0x2000
#define CONFIG_GICD_BASE          0x01C81000  
#define CONFIG_GICR_BASE          0x01C82000  

// Previously:
// #define CONFIG_GICD_BASE          0x8000000
// #define CONFIG_GICR_BASE          0x80a0000

// PinePhone RAM: 0x4000 0000 to 0x4800 0000
#define CONFIG_RAMBANK1_ADDR      0x40000000
#define CONFIG_RAMBANK1_SIZE      MB(128)

// PinePhone Device I/O: 0x0 to 0x2000 0000
#define CONFIG_DEVICEIO_BASEADDR  0x00000000
#define CONFIG_DEVICEIO_SIZE      MB(512)

// Previously:
// #define CONFIG_DEVICEIO_BASEADDR  0x7000000
// #define CONFIG_DEVICEIO_SIZE      MB(512)

// PinePhone uboot load address (kernel_addr_r)
#define CONFIG_LOAD_BASE          0x40080000
// Previously: #define CONFIG_LOAD_BASE          0x40280000
```

We also changed CONFIG_LOAD_BASE for PinePhone's Kernel Start Address (kernel_addr_r).

_How are the MMU Memory Regions used?_

NuttX initialises the Arm MMU with the MMU Memory Regions at startup: [arch/arm64/src/qemu/qemu_boot.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/qemu/qemu_boot.c#L52-L67)

```c
static const struct arm_mmu_region mmu_regions[] =
{
  MMU_REGION_FLAT_ENTRY("DEVICE_REGION",
                        CONFIG_DEVICEIO_BASEADDR, MB(512),
                        MT_DEVICE_NGNRNE | MT_RW | MT_SECURE),

  MMU_REGION_FLAT_ENTRY("DRAM0_S0",
                        CONFIG_RAMBANK1_ADDR, MB(512),
                        MT_NORMAL | MT_RW | MT_SECURE),
};

const struct arm_mmu_config mmu_config =
{
  .num_regions = ARRAY_SIZE(mmu_regions),
  .mmu_regions = mmu_regions,
};
```

The Arm MMU Initialisation is done by `arm64_mmu_init`, defined in [arch/arm64/src/common/arm64_mmu.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_mmu.c#L571-L622)

We'll talk more about the Arm MMU in the next section...

# Boot Sequence

This section describes the Boot Sequence for NuttX on PinePhone...

1.  [Startup Code](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L117-L176) (in Arm64 Assembly) inits the Arm64 System Registers and UART Port.

1.  [Startup Code](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L178-L182) prints the Hello Message...

    ```text
    HELLO NUTTX ON PINEPHONE!
    Ready to Boot CPU
    ```

1.  [Startup Code](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L199-L213) calls [`arm64_boot_el2_init`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_boot.c#L91-L130) to Init EL2

    ```text
    Boot from EL2
    ```

1.  [Startup Code](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L215-L226) calls [`arm64_boot_el1_init`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_boot.c#L132-L162) to Init EL1 and load the [Vector Base Address Register EL1](https://github.com/lupyuen/pinephone-nuttx#handling-interrupts)

    ```text
    Boot from EL1
    ```

1.  [Startup Code](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L228-L230) jumps to `arm64_boot_secondary_c_routine`: [arch/arm64/src/common/arm64_head.S](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_head.S#L228-L230)

    ```text
        ldr    x25, =arm64_boot_secondary_c_routine
        ...
    jump_to_c_entry:
        PRINT(jump_to_c_entry, "- Boot to C runtime for OS Initialize\r\n")
        ret x25
    ```

    Which appears as...

    ```text
    Boot to C runtime for OS Initialize
    ```

1.  TODO: Who calls `qemu_pl011_setup` to init the UART Port?

1.  `arm64_boot_primary_c_routine` inits the BSS, calls `arm64_chip_boot` to init the Arm64 CPU, and `nx_start` to start the NuttX processes: [arch/arm64/src/common/arm64_boot.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_boot.c#L179-L189)

    ```c
    void arm64_boot_primary_c_routine(void)
    {
      boot_early_memset(_START_BSS, 0, _END_BSS - _START_BSS);
      arm64_chip_boot();
      nx_start();
    }
    ```

    Which appears as...

    ```text
    nx_start: Entry
    ```

1.  `arm64_chip_boot` calls `arm64_mmu_init` to enable the Arm Memory Management Unit, and `qemu_board_initialize` to init the Board Drivers: [arch/arm64/src/qemu/qemu_boot.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/qemu/qemu_boot.c#L81-L105)

    ```c
    void arm64_chip_boot(void)
    {
      /* MAP IO and DRAM, enable MMU. */

      arm64_mmu_init(true);

    #ifdef CONFIG_SMP
      arm64_psci_init("smc");

    #endif

      /* Perform board-specific device initialization. This would include
      * configuration of board specific resources such as GPIOs, LEDs, etc.
      */

      qemu_board_initialize();

    #ifdef USE_EARLYSERIALINIT
      /* Perform early serial initialization if we are going to use the serial
      * driver.
      */

      qemu_earlyserialinit();
    #endif
    }
    ```

    `arm64_mmu_init` is defined in [arch/arm64/src/common/arm64_mmu.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_mmu.c#L571-L622)

1.  TODO: Who calls `up_allocate_heap` to allocate the heap?

    ```text
    up_allocate_heap: heap_start=0x0x400c4000, heap_size=0x7f3c000
    ```

1.  TODO: Who calls [`arm64_gic_initialize`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_gicv3.c#L710-L734) to init the GIC?

    ```text
    arm64_gic_initialize: TODO: Init GIC for PinePhone
    arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
    arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
    arm64_gic_initialize: GIC Version is 2
    ```

1.  TODO: Who calls [`up_timer_initialize`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_arch_timer.c#L212-L235) to start the System Timer?

1.  TODO: Who calls `uart_register` to register `/dev/console` and `/dev/ttyS0`?

1.  TODO: Who calls `qemu_pl011_attach` to Attach UART Interrupt and `qemu_pl011_rxint` to Enable UART Receive Interrupt?

1.  TODO: Who calls `work_start_highpri` to start high-priority kernel worker thread(s)?

1.  TODO: Who calls `nx_start_application` to starting init thread?

1.  TODO: Who calls `nxtask_start` to start the NuttX Shell?

1.  [`nxtask_start`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/sched/task/task_start.c#L60-L145) calls [`nxtask_startup`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/libs/libc/sched/task_startup.c#L40-L71) to start the NuttX Shell

1.  [`nxtask_startup`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/libs/libc/sched/task_startup.c#L40-L71) calls [`lib_cxx_initialize`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/libs/libc/misc/lib_cxx_initialize.c#L68-L123) to init the C++ Constructors.

    ```text
    lib_cxx_initialize: _sinit: 0x400a7000 _einit: 0x400a7000 _stext: 0x40080000 _etext: 0x400a8000
    ```

    Then [`nxtask_startup`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/libs/libc/sched/task_startup.c#L40-L71) calls the Main Entry Point for the NuttX Shell, [`entrypt`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/libs/libc/sched/task_startup.c#L66-L70)

1.  [`entrypt`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/libs/libc/sched/task_startup.c#L66-L70) points to [`nsh_main`](https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/system/nsh/nsh_main.c#L87-L165), the Main Function for the NuttX Shell

1.  [`nsh_main`](https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/system/nsh/nsh_main.c#L87-L165), starts the NuttX Shell.

    UART Transmit and Receive Interrupts must work, otherwise nothing appears in NuttX Shell.

    (Because NuttX Shell calls Stream I/O with the Serial Driver)

1.  TODO: Who calls `qemu_pl011_txint` to Enable UART Transmit Interrupt?

    ```text
    HHHHHHHHHHHH: qemu_pl011_txint
    ```

1.  TODO: Who calls `qemu_pl011_rxint` to Enable UART Receive Interrupt?

    ```text
    GG: qemu_pl011_rxint
    ```

1.  `nx_start` starts the Idle Loop

    ```text
    nx_start: CPU0: Beginning Idle Loop
    ```

The next section talks about debugging the Boot Sequence...

# Boot Debugging

_How can we debug NuttX while it boots?_

We may call `up_putc` to print characters to the Serial Console and troubleshoot the Boot Sequence: [arch/arm64/src/common/arm64_boot.c](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/common/arm64_boot.c#L179-L189)

```c
void arm64_boot_primary_c_routine(void)
{
  int up_putc(int ch);  // For debugging
  up_putc('0');  // For debugging
  boot_early_memset(_START_BSS, 0, _END_BSS - _START_BSS);
  up_putc('1');  // For debugging
  arm64_chip_boot();
  up_putc('2');  // For debugging
  nx_start();
}
```

This prints "012" to the Serial Console as NuttX boots.

[`up_putc`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/qemu/qemu_serial.c#L924-L946) calls [`up_lowputc`](https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm64/src/qemu/qemu_lowputc.S#L100-L109) to print directly to the UART Port by writing to the UART Register. So it's safe to be called as NuttX boots.

# UART Interrupts

Previously we noticed that NuttX Shell wasn't generating output on the Serial Console.

We discovered that `sinfo` (`syslog`) works, but `printf` (`puts`) doesn't! 

Here's what we tested with NuttX Shell: [system/nsh/nsh_main.c](https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/system/nsh/nsh_main.c#L88-L102)

```c
/****************************************************************************
 * Name: nsh_main
 *
 * Description:
 *   This is the main logic for the case of the NSH task.  It will perform
 *   one-time NSH initialization and start an interactive session on the
 *   current console device.
 *
 ****************************************************************************/

int main(int argc, FAR char *argv[])
{
  sinfo("****main\n");////
  printf("****main2\n");////
  sinfo("****main3\n");////
```

`main2` never appears in the output because UART Transmit Interrupts (`qemu_pl011_txint`) haven't been implemented...

```text
nsh_main: ****main
HH: qemu_pl011_txint
nsh_main: ****main3
```

This is the sequence of calls to `qemu_pl011_attach`, `qemu_pl011_rxint` and `qemu_pl011_txint` for UART Transmit and Receive Interrupts...

```text
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
K: qemu_pl011_attach
G: qemu_pl011_rxint
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x400a7000 _einit: 0x400a7000 _stext: 0x40080000 _etext: 0x400a8000
nsh_main: ****main
puts: A
HH: qemu_pl011_txint
puts: B
nsh_main: ****main3
HHHHHHHHHHHH: qemu_pl011_txint
GG: qemu_pl011_rxint
nx_start: CPU0: Beginning Idle Loop
```

We need to implement UART Transmit and Receive Interrupts to support NuttX Shell.

Here's our implementation...

-   ["NuttX RTOS on PinePhone: UART Driver"](https://lupyuen.github.io/articles/serial)

# Backlight and LEDs

Let's light up the PinePhone Backlight and the Red / Green / Blue LEDs.

Based on the [PinePhone Schematic](https://files.pine64.org/doc/PinePhone/PinePhone%20v1.2b%20Released%20Schematic.pdf)...

-   Backlight Enable is connected to GPIO PH10

    (PH10-LCD-BL-EN)

-   Backlight PWM is connected to PWM PL10 

    (PL10-LCD-PWM)

This is how we turn on GPIO PH10 in Allwinner A64 Port Controller (PIO): [examples/hello/hello_main.c](https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/examples/hello/hello_main.c#L83-L122)

```c
// PIO Base Address for PinePhone Allwinner A64 Port Controller (GPIO)
#define PIO_BASE_ADDRESS 0x01C20800

// Turn on the PinePhone Backlight
static void test_backlight(void)
{
  // From PinePhone Schematic: https://files.pine64.org/doc/PinePhone/PinePhone%20v1.2b%20Released%20Schematic.pdf
  // - Backlight Enable: GPIO PH10 (PH10-LCD-BL-EN)
  // - Backlight PWM:    PWM  PL10 (PL10-LCD-PWM)
  // We won't handle the PWM yet

  // Write to PH Configure Register 1 (PH_CFG1_REG)
  // Offset: 0x100
  uint32_t *ph_cfg1_reg = (uint32_t *)
    (PIO_BASE_ADDRESS + 0x100);

  // Bits 10 to 8: PH10_SELECT (Default 0x7)
  // 000: Input     001: Output
  // 010: MIC_CLK   011: Reserved
  // 100: Reserved  101: Reserved
  // 110: PH_EINT10 111: IO Disable
  *ph_cfg1_reg = 
    (*ph_cfg1_reg & ~(0b111 << 8))  // Clear the bits
    | (0b001 << 8);                 // Set the bits for Output
  printf("ph_cfg1_reg=0x%x\n", *ph_cfg1_reg);

  // Write to PH Data Register (PH_DATA_REG)
  // Offset: 0x10C
  uint32_t *ph_data_reg = (uint32_t *)
    (PIO_BASE_ADDRESS + 0x10C);

  // Bits 11 to 0: PH_DAT (Default 0)
  // If the port is configured as input, the corresponding bit is the pin state. If
  // the port is configured as output, the pin state is the same as the
  // corresponding bit. The read bit value is the value setup by software.
  // If the port is configured as functional pin, the undefined value will
  // be read.
  *ph_data_reg |= (1 << 10);  // Set Bit 10 for PH10
  printf("ph_data_reg=0x%x\n", *ph_data_reg);
}
```

The Backlight lights up and the output shows...

```text
ph_cfg1_reg=0x7177
ph_data_reg=0x400
```

Now for the LEDs. Based on the [PinePhone Schematic](https://files.pine64.org/doc/PinePhone/PinePhone%20v1.2b%20Released%20Schematic.pdf)...

-   Red LED is connected to GPIO PD18

    (PD18-LED-R)

-   Green LED is connected to GPIO PD19

    (PD19-LED-G)

-   Blue LED is connected to GPIO PD20 

    (PD20-LED-B)

This is how we turn on GPIOs PD18, PD19, PD20 in Allwinner A64 Port Controller (PIO): [examples/hello/hello_main.c](https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/examples/hello/hello_main.c#L124-L179)

```c
// PIO Base Address for PinePhone Allwinner A64 Port Controller (GPIO)
#define PIO_BASE_ADDRESS 0x01C20800

// Turn on the PinePhone Red, Green and Blue LEDs
static void test_led(void)
{
  // From PinePhone Schematic: https://files.pine64.org/doc/PinePhone/PinePhone%20v1.2b%20Released%20Schematic.pdf
  // - Red LED:   GPIO PD18 (PD18-LED-R)
  // - Green LED: GPIO PD19 (PD19-LED-G)
  // - Blue LED:  GPIO PD20 (PD20-LED-B)

  // Write to PD Configure Register 2 (PD_CFG2_REG)
  // Offset: 0x74
  uint32_t *pd_cfg2_reg = (uint32_t *)
    (PIO_BASE_ADDRESS + 0x74);

  // Bits 10 to 8: PD18_SELECT (Default 0x7)
  // 000: Input    001: Output
  // 010: LCD_CLK  011: LVDS_VPC
  // 100: RGMII_TXD0/MII_TXD0/RMII_TXD0 101: Reserved
  // 110: Reserved 111: IO Disable
  *pd_cfg2_reg = 
    (*pd_cfg2_reg & ~(0b111 << 8))  // Clear the bits
    | (0b001 << 8);                 // Set the bits for Output

  // Bits 14 to 12: PD19_SELECT (Default 0x7)
  // 000: Input    001: Output
  // 010: LCD_DE   011: LVDS_VNC
  // 100: RGMII_TXCK/MII_TXCK/RMII_TXCK 101: Reserved
  // 110: Reserved 111: IO Disable
  *pd_cfg2_reg = 
    (*pd_cfg2_reg & ~(0b111 << 12))  // Clear the bits
    | (0b001 << 12);                 // Set the bits for Output

  // Bits 18 to 16: PD20_SELECT (Default 0x7)
  // 000: Input     001: Output
  // 010: LCD_HSYNC 011: LVDS_VP3
  // 100: RGMII_TXCTL/MII_TXEN/RMII_TXEN 101: Reserved
  // 110: Reserved  111: IO Disable
  *pd_cfg2_reg = 
    (*pd_cfg2_reg & ~(0b111 << 16))  // Clear the bits
    | (0b001 << 16);                 // Set the bits for Output
  printf("pd_cfg2_reg=0x%x\n", *pd_cfg2_reg);

  // Write to PD Data Register (PD_DATA_REG)
  // Offset: 0x7C
  uint32_t *pd_data_reg = (uint32_t *)
    (PIO_BASE_ADDRESS + 0x7C);

  // Bits 24 to 0: PD_DAT (Default 0)
  // If the port is configured as input, the corresponding bit is the pin state. If
  // the port is configured as output, the pin state is the same as the
  // corresponding bit. The read bit value is the value setup by software. If the
  // port is configured as functional pin, the undefined value will be read.
  *pd_data_reg |= (1 << 18);  // Set Bit 18 for PD18
  *pd_data_reg |= (1 << 19);  // Set Bit 19 for PD19
  *pd_data_reg |= (1 << 20);  // Set Bit 20 for PD20
  printf("pd_data_reg=0x%x\n", *pd_data_reg);
}
```

The Red, Green and Blue LEDs turn on (appearing as white) and the output shows...

```text
pd_cfg2_reg=0x77711177
pd_data_reg=0x1c0000
```

[__Watch the Demo on YouTube__](https://youtu.be/MJDxCcKAv0g)

Here's the complete log for [examples/hello/hello_main.c](https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/examples/hello/hello_main.c)...

```text
nsh> hello
task_spawn: name=hello entry=0x4009b1a4 file_actions=0x400c9580 attr=0x400c9588 argv=0x400c96d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
ABHello, World!!
ph_cfg1_reg=0x7177
ph_data_reg=0x400
pd_cfg2_reg=0x77711177
pd_data_reg=0x1c0000
tcon_gctl_reg=0x80000000
tcon0_3d_fifo_reg=0x80000631
tcon0_ctl_reg=0x80000000
tcon0_basic0_reg=0x630063
tcon0_lvds_if_reg=0x80000000
nsh> 
```

# BASIC Blinks The LEDs

In the previous section we lit up PinePhone's Red, Green and Blue LEDs. Below are the values we wrote to the Allwinner A64 Port Controller...

```text
pd_cfg2_reg=0x77711177
pd_data_reg=0x1c0000
```

Let's do the same in BASIC! Which is great for interactive experimenting with PinePhone Hardware.

This will enable GPIO Output for PD18 (Red), PD19 (Green), PD20 (Blue) in the Register `pd_cfg2_reg` (0x1C20874)...

```text
poke &h1C20874, &h77711177
```

This will light up Red, Green and Blue LEDs via the Register `pd_data_reg` (0x1C2087C)...

```text
poke &h1C2087C, &h1C0000
```

And this will turn off all 3 LEDs via `pd_data_reg` (0x1C2087C)...

```text
poke &h1C2087C, &h0000
```

Install the BASIC Interpreter in NuttX...

-   ["Enable BASIC"](https://lupyuen.github.io/articles/nuttx#enable-basic)

And enter these commands to blink the PinePhone LEDs (off and on)...

[__Watch the Demo on YouTube__](https://youtu.be/OTIHMIRd1s4)

```text
nsh> bas
task_spawn: name=bas entry=0x4009b340 file_actions=0x400f3580 attr=0x400f3588 argv=0x400f36d0
spawn_execattrs: Setting policy=2 priority=100 for pid=7
bas 2.4
Copyright 1999-2014 Michael Haardt.
This is free software with ABSOLUTELY NO WARRANTY.

> print peek(&h1C20874)
 2004316535 

> poke &h1C20874, &h77711177

> print peek(&h1C20874)
 2003898743 

> print peek(&h1C2087C)
 262144 

> poke &h1C2087C, &h0000

> print peek(&h1C2087C)
 0 

> poke &h1C2087C, &h1C0000

> print peek(&h1C2087C)
 1835008  
```

Or run it in a loop like so...

```text
10 'Enable GPIO Output for PD18, PD19 and PD20
20 poke &h1C20874, &h77711177
30 'Turn off GPIOs PD18, PD19 and PD20
40 poke &h1C2087C, &h0
50 sleep 5
60 'Turn on GPIOs PD18, PD19 and PD20
70 poke &h1C2087C, &h1C0000
80 sleep 5
90 goto 40
run
```

We patched NuttX BASIC so that it supports `peek` and `poke`: [interpreters/bas/bas_fs.c](https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/interpreters/bas/bas_fs.c#L1862-L1889)

```c
int FS_memInput(int address)
{
  //  Return the 32-bit word at the specified address.
  //  TODO: Quit if address is invalid.
  return *(int *)(uint64_t) address;

  //  Previously:
  //  FS_errmsg = _("Direct memory access not available");
  //  return -1;
}

int FS_memOutput(int address, int value)
{
  //  Set the 32-bit word at the specified address
  //  TODO: Quit if address is invalid.
  *(int *)(uint64_t) address = value;
  return 0;

  //  Previously:
  //  FS_errmsg = _("Direct memory access not available");
  //  return -1;
}
```

Note that addresses are passed as 32-bit `int`, so some 64-bit addresses will not be accessible via `peek` and `poke`.

# PinePhone Device Tree

Let's figure out how Allwinner A64's Display Timing Controller (TCON0) talks to PinePhone's MIPI DSI Display. (So we can build NuttX Drivers)

More info on PinePhone Display...

-   ["Genode Operating System Framework 22.05"](https://genode.org/documentation/genode-platforms-22-05.pdf), pages 171 to 197.

We tried tweaking the TCON0 Controller but the display is still blank (maybe backlight is off?)

-   [examples/hello/hello_main.c](https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/examples/hello/hello_main.c#L75-L234)

Below is the Device Tree for PinePhone's Linux Kernel...

-   [PinePhone Device Tree: sun50i-a64-pinephone-1.2.dts](sun50i-a64-pinephone-1.2.dts)

We converted the Device Tree with this command...

```
## Convert Device Tree to text format
dtc \
  -o sun50i-a64-pinephone-1.2.dts \
  -O dts \
  -I dtb \
  sun50i-a64-pinephone-1.2.dtb
```

`sun50i-a64-pinephone-1.2.dtb` came from the [Jumpdrive microSD](https://lupyuen.github.io/articles/uboot#pinephone-jumpdrive).

High-level doc of Linux Drivers...

-   [devicetree/bindings/display/sunxi/sun4i-drm.txt](https://www.kernel.org/doc/Documentation/devicetree/bindings/display/sunxi/sun4i-drm.txt)

PinePhone Schematic shows the connections for Display, Touch Panel and Backlight...

-   [PinePhone v1.2b Released Schematic](https://files.pine64.org/doc/PinePhone/PinePhone%20v1.2b%20Released%20Schematic.pdf)

Here are the interesting bits from the PinePhone Linux Device Tree: [sun50i-a64-pinephone-1.2.dts](sun50i-a64-pinephone-1.2.dts)

## LCD Controller (TCON0)

```text
lcd-controller@1c0c000 {
  compatible = "allwinner,sun50i-a64-tcon-lcd\0allwinner,sun8i-a83t-tcon-lcd";
  reg = <0x1c0c000 0x1000>;
  interrupts = <0x00 0x56 0x04>;
  clocks = <0x02 0x2f 0x02 0x64>;
  clock-names = "ahb\0tcon-ch0";
  clock-output-names = "tcon-pixel-clock";
  #clock-cells = <0x00>;
  resets = <0x02 0x18 0x02 0x23>;
  reset-names = "lcd\0lvds";

  ports {
    #address-cells = <0x01>;
    #size-cells = <0x00>;

    // TCON0: MIPI DSI Display
    port@0 {
      #address-cells = <0x01>;
      #size-cells = <0x00>;
      reg = <0x00>;

      endpoint@0 {
        reg = <0x00>;
        remote-endpoint = <0x22>;
        phandle = <0x1e>;
      };

      endpoint@1 {
        reg = <0x01>;
        remote-endpoint = <0x23>;
        phandle = <0x20>;
      };
    };

    // TCON1: HDMI
    port@1 { ... };
  };
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L446-L492)

## MIPI DSI Interface

```text
dsi@1ca0000 {
  compatible = "allwinner,sun50i-a64-mipi-dsi";
  reg = <0x1ca0000 0x1000>;
  interrupts = <0x00 0x59 0x04>;
  clocks = <0x02 0x1c>;
  resets = <0x02 0x05>;
  phys = <0x53>;
  phy-names = "dphy";
  status = "okay";
  #address-cells = <0x01>;
  #size-cells = <0x00>;
  vcc-dsi-supply = <0x45>;

  port {

    endpoint {
      remote-endpoint = <0x54>;
      phandle = <0x24>;
    };
  };

  panel@0 {
    compatible = "xingbangda,xbd599";
    reg = <0x00>;
    reset-gpios = <0x2b 0x03 0x17 0x01>;
    iovcc-supply = <0x55>;
    vcc-supply = <0x48>;
    backlight = <0x56>;
  };
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L1327-L1356)

## Display PHY

```text
d-phy@1ca1000 {
  compatible = "allwinner,sun50i-a64-mipi-dphy\0allwinner,sun6i-a31-mipi-dphy";
  reg = <0x1ca1000 0x1000>;
  clocks = <0x02 0x1c 0x02 0x71>;
  clock-names = "bus\0mod";
  resets = <0x02 0x05>;
  status = "okay";
  #phy-cells = <0x00>;
  phandle = <0x53>;
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L1358-L1367)

## Backlight PWM

```text
backlight {
  compatible = "pwm-backlight";
  pwms = <0x62 0x00 0xc350 0x01>;
  enable-gpios = <0x2b 0x07 0x0a 0x00>;
  power-supply = <0x48>;
  brightness-levels = <0x1388 0x1480 0x1582 0x16e2 0x18c9 0x1b4b 0x1e7d 0x2277 0x274e 0x2d17 0x33e7 0x3bd5 0x44f6 0x4f5f 0x5b28 0x6864 0x7729 0x878e 0x99a7 0xad8b 0xc350>;
  num-interpolated-steps = <0x32>;
  default-brightness-level = <0x1f4>;
  phandle = <0x56>;
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L1832-L1841)

From [PinePhone Schematic](https://files.pine64.org/doc/PinePhone/PinePhone%20v1.2b%20Released%20Schematic.pdf)...

-   Backlight Enable: GPIO PH10 (PH10-LCD-BL-EN)

-   Backlight PWM: PWM PL10 (PL10-LCD-PWM)

## LED

```text
leds {
  compatible = "gpio-leds";

  blue {
    function = "indicator";
    color = <0x03>;
    gpios = <0x2b 0x03 0x14 0x00>;
    retain-state-suspended;
  };

  green {
    function = "indicator";
    color = <0x02>;
    gpios = <0x2b 0x03 0x12 0x00>;
    retain-state-suspended;
  };

  red {
    function = "indicator";
    color = <0x01>;
    gpios = <0x2b 0x03 0x13 0x00>;
    retain-state-suspended;
  };
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L1940-L1963)

From [PinePhone Schematic](https://files.pine64.org/doc/PinePhone/PinePhone%20v1.2b%20Released%20Schematic.pdf)...

-   Red LED: GPIO PD18 (PD18-LED-R)

-   Green LED: GPIO PD19 (PD19-LED-G)

-   Blue LED: GPIO PD20 (PD20-LED-B)

## Framebuffer

```text
framebuffer-lcd {
  compatible = "allwinner,simple-framebuffer\0simple-framebuffer";
  allwinner,pipeline = "mixer0-lcd0";
  clocks = <0x02 0x64 0x03 0x06>;
  status = "disabled";
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L16-L21)

## Display Engine

```text
display-engine {
  compatible = "allwinner,sun50i-a64-display-engine";
  allwinner,pipelines = <0x07 0x08>;
  status = "okay";
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L98-L102)

## Touch Panel

```text
touchscreen@5d {
  compatible = "goodix,gt917s";
  reg = <0x5d>;
  interrupt-parent = <0x2b>;
  interrupts = <0x07 0x04 0x04>;
  irq-gpios = <0x2b 0x07 0x04 0x00>;
  reset-gpios = <0x2b 0x07 0x0b 0x00>;
  AVDD28-supply = <0x48>;
  VDDIO-supply = <0x48>;
  touchscreen-size-x = <0x2d0>;
  touchscreen-size-y = <0x5a0>;
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L1125-L1136)

## Video Codec

```text
video-codec@1c0e000 {
  compatible = "allwinner,sun50i-a64-video-engine";
  reg = <0x1c0e000 0x1000>;
  clocks = <0x02 0x2e 0x02 0x6a 0x02 0x5f>;
  clock-names = "ahb\0mod\0ram";
  resets = <0x02 0x17>;
  interrupts = <0x00 0x3a 0x04>;
  allwinner,sram = <0x28 0x01>;
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L539-L547)

## GPU

```text
gpu@1c40000 {
  compatible = "allwinner,sun50i-a64-mali\0arm,mali-400";
  reg = <0x1c40000 0x10000>;
  interrupts = <0x00 0x61 0x04 0x00 0x62 0x04 0x00 0x63 0x04 0x00 0x64 0x04 0x00 0x66 0x04 0x00 0x67 0x04 0x00 0x65 0x04>;
  interrupt-names = "gp\0gpmmu\0pp0\0ppmmu0\0pp1\0ppmmu1\0pmu";
  clocks = <0x02 0x35 0x02 0x72>;
  clock-names = "bus\0core";
  resets = <0x02 0x1f>;
  assigned-clocks = <0x02 0x72>;
  assigned-clock-rates = <0x1dcd6500>;
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L1246-L1256)

## Deinterlace

```text
deinterlace@1e00000 {
  compatible = "allwinner,sun50i-a64-deinterlace\0allwinner,sun8i-h3-deinterlace";
  reg = <0x1e00000 0x20000>;
  clocks = <0x02 0x31 0x02 0x66 0x02 0x61>;
  clock-names = "bus\0mod\0ram";
  resets = <0x02 0x1a>;
  interrupts = <0x00 0x5d 0x04>;
  interconnects = <0x57 0x09>;
  interconnect-names = "dma-mem";
};
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx/blob/main/sun50i-a64-pinephone-1.2.dts#L1369-L1378)

# Zig on PinePhone

Let's run this Zig App on NuttX for PinePhone: [display.zig](display.zig)

In NuttX, enable the Null Example App: make menuconfig, select "Application Configuration" > "Examples" > "Null Example"

Compile the Zig App (based on the GCC Compiler Options, see below)...

```bash
#  Change "$HOME/nuttx" for your NuttX Project Directory
cd $HOME/nuttx

#  Download the Zig App
git clone --recursive https://github.com/lupyuen/pinephone-nuttx
cd pinephone-nuttx

#  Compile the Zig App for PinePhone 
#  (armv8-a with cortex-a53)
#  TODO: Change "$HOME/nuttx" to your NuttX Project Directory
zig build-obj \
  -target aarch64-freestanding-none \
  -mcpu cortex_a53 \
  -isystem "$HOME/nuttx/nuttx/include" \
  -I "$HOME/nuttx/apps/include" \
  display.zig

#  Copy the compiled app to NuttX and overwrite `null.o`
#  TODO: Change "$HOME/nuttx" to your NuttX Project Directory
cp display.o \
  $HOME/nuttx/apps/examples/null/*null.o

#  Build NuttX to link the Zig Object from `null.o`
#  TODO: Change "$HOME/nuttx" to your NuttX Project Directory
cd $HOME/nuttx/nuttx
make
```

Run the Zig App...

```text
nsh> null
HELLO ZIG ON PINEPHONE!
```

_How did we get the Zig Compiler options `-target`, `-mcpu`, `-isystem` and `-I`?_

`make --trace` shows these GCC Compiler Options when building Nuttx for PinePhone...

```bash
aarch64-none-elf-gcc
  -c
  -fno-common
  -Wall
  -Wstrict-prototypes
  -Wshadow
  -Wundef
  -Werror
  -Os
  -fno-strict-aliasing
  -fomit-frame-pointer
  -g
  -march=armv8-a
  -mtune=cortex-a53
  -isystem "/Users/Luppy/PinePhone/nuttx/nuttx/include"
  -D__NuttX__ 
  -pipe
  -I "/Users/Luppy/PinePhone/nuttx/apps/include"
  -Dmain=hello_main  hello_main.c
  -o  hello_main.c.Users.Luppy.PinePhone.nuttx.apps.examples.hello.o
```

We copied and modified these GCC Compiler Options for Zig.

_What about `-D__NuttX__`?_

The Zig Compiler won't let us specify C Macros at the Command Line, so we defined the macro `__NuttX__` in our Zig App...

https://github.com/lupyuen/pinephone-nuttx/blob/2d938b9f09a165c0ff82b5dbbb12f1c4c6db61f2/display.zig#L27-L42

# Zig Driver for PinePhone MIPI DSI

With Zig, we create a Quick Prototype of the NuttX Driver for MIPI DSI: [display.zig](display.zig)

https://github.com/lupyuen/pinephone-nuttx/blob/4840d2f1bd42d6bc596040f5417fd8cf8a6dcfeb/display.zig#L62-L167

This MIPI DSI Interface is compatible with Zephyr MIPI DSI...

-   [zephyr/drivers/mipi_dsi.h](https://github.com/zephyrproject-rtos/zephyr/blob/main/include/zephyr/drivers/mipi_dsi.h)

_Why Zig for the MIPI DSI Driver?_

We're doing Quick Prototyping, so it's great to have Zig catch any Runtime Problems caused by our Bad Coding. (Underflow / Overflow / Array Out Of Bounds)

And yet Zig is so similar to C that we can test the Zig Driver with the rest of the C code.

Also `comptime` Compile-Time Expressions in Zig will be helpful when we initialise the ST7703 LCD Controller. [(See this)](https://lupyuen.github.io/articles/dsi#initialise-lcd-controller)

# Compose MIPI DSI Long Packet in Zig

To initialise PinePhone's ST7703 LCD Controller, our PinePhone Display Driver for NuttX shall send MIPI DSI Long Packets to ST7703...

-   ["Long Packet for MIPI DSI"](https://lupyuen.github.io/articles/dsi#long-packet-for-mipi-dsi)

This is how our Zig Driver composes a MIPI DSI Long Packet...

https://github.com/lupyuen/pinephone-nuttx/blob/1262f46622dc07442cf2aa59a4bbc57871308ed1/display.zig#L140-L204

# Compose MIPI DSI Short Packet in Zig

For 1 or 2 bytes of data, our PinePhone Display Driver shall send MIPI DSI Short Packets (instead of Long Packets)...

-   ["Short Packet for MIPI DSI"](https://lupyuen.github.io/articles/dsi#appendix-short-packet-for-mipi-dsi)

This is how our Zig Driver composes a MIPI DSI Short Packet...

https://github.com/lupyuen/pinephone-nuttx/blob/1262f46622dc07442cf2aa59a4bbc57871308ed1/display.zig#L206-L261

# Compute Error Correction Code in Zig

In our PinePhone Display Driver for NuttX, this is how we compute the Error Correction Code for a MIPI DSI Packet...

https://github.com/lupyuen/pinephone-nuttx/blob/1262f46622dc07442cf2aa59a4bbc57871308ed1/display.zig#L263-L304

The Error Correction Code is the last byte of the 4-byte Packet Header for Long Packets and Short Packets.

# Compute Cyclic Redundancy Check in Zig

This is how our PinePhone Display Driver computes the 16-bit Cyclic Redundancy Check (CCITT) in Zig...

https://github.com/lupyuen/pinephone-nuttx/blob/1262f46622dc07442cf2aa59a4bbc57871308ed1/display.zig#L306-L366

The Cyclic Redundancy Check is the 2-byte Packet Footer for Long Packets.

# Test PinePhone MIPI DSI Driver with QEMU

The above Zig Code for composing Long Packets and Short Packets was tested in QEMU for Arm64 with GIC Version 2...

```bash
## TODO: Install Build Prerequisites
## https://lupyuen.github.io/articles/uboot#install-prerequisites

## Create NuttX Directory
mkdir nuttx
cd nuttx

## Download NuttX OS for QEMU with GIC Version 2
git clone \
    --recursive \
    --branch gicv2 \
    https://github.com/lupyuen/incubator-nuttx \
    nuttx

## Download NuttX Apps for QEMU
git clone \
    --recursive \
    --branch arm64 \
    https://github.com/lupyuen/incubator-nuttx-apps \
    apps

## We'll build NuttX inside nuttx/nuttx
cd nuttx

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

Follow these steps to compile our Zig App and link into NuttX...

-   ["Zig on PinePhone"](https://github.com/lupyuen/pinephone-nuttx#zig-on-pinephone)

Start NuttX on QEMU Arm64...

```bash
## Run GIC v2 with QEMU
qemu-system-aarch64 \
  -smp 4 \
  -cpu cortex-a53 \
  -nographic \
  -machine virt,virtualization=on,gic-version=2 \
  -net none \
  -chardev stdio,id=con,mux=on \
  -serial chardev:con \
  -mon chardev=con,mode=readline \
  -kernel ./nuttx
```

Here's the NuttX Test Log for our Zig App on QEMU Arm64...

```text
NuttShell (NSH) NuttX-11.0.0-RC2
nsh> uname -a
NuttX 11.0.0-RC2 c938291 Oct  7 2022 16:54:31 arm64 qemu-a53

nsh> null
HELLO ZIG ON PINEPHONE!
Testing Compose Short Packet (Without Parameter)...
composeShortPacket: channel=0, cmd=0x5, len=1
Result:
05 11 00 36 
Testing Compose Short Packet (With Parameter)...
composeShortPacket: channel=0, cmd=0x15, len=2
Result:
15 bc 4e 35 
Testing Compose Long Packet...
composeLongPacket: channel=0, cmd=0x39, len=64
Result:
39 40 00 25 e9 82 10 06 
05 a2 0a a5 12 31 23 37 
83 04 bc 27 38 0c 00 03 
00 00 00 0c 00 03 00 00 
00 75 75 31 88 88 88 88 
88 88 13 88 64 64 20 88 
88 88 88 88 88 02 88 00 
00 00 00 00 00 00 00 00 
00 00 00 00 65 03 
```

# Test Case for PinePhone MIPI DSI Driver

This is how we write a Test Case for the PinePhone MIPI DSI Driver on NuttX...

https://github.com/lupyuen/pinephone-nuttx/blob/aaf0ed0fb3e8ada663fe9c64f16ea9cb1e3235ed/display.zig#L593-L639

The above Test Case shows this output on QEMU Arm64...

```text
Testing Compose Long Packet...
composeLongPacket: channel=0, cmd=0x39, len=64
Result:
39 40 00 25 e9 82 10 06 
05 a2 0a a5 12 31 23 37 
83 04 bc 27 38 0c 00 03 
00 00 00 0c 00 03 00 00 
00 75 75 31 88 88 88 88 
88 88 13 88 64 64 20 88 
88 88 88 88 88 02 88 00 
00 00 00 00 00 00 00 00 
00 00 00 00 65 03 
```

# Initialise ST7703 LCD Controller in Zig

PinePhone's ST7703 LCD Controller needs to be initialised with these 20 Commands...

-   ["Initialise LCD Controller"](https://lupyuen.github.io/articles/dsi#initialise-lcd-controller)

This is how we send the 20 Commands with our NuttX Driver in Zig, as DCS Short Writes and DCS Long Writes...

https://github.com/lupyuen/pinephone-nuttx/blob/40098cd9ea37ab5e0192b2dc006a98630fa6a7e8/display.zig#L62-L429

To send a command, `writeDcs` executes a DCS Short Write or DCS Long Write, depending on the length of the command...

https://github.com/lupyuen/pinephone-nuttx/blob/40098cd9ea37ab5e0192b2dc006a98630fa6a7e8/display.zig#L431-L453

# Test Zig Display Driver for PinePhone

To test our Zig Display Driver with NuttX on PinePhone, we'll run this p-boot Display Code...

-   [p-boot Display Code](https://gist.github.com/lupyuen/ee3adf76e76881609845d0ab0f768a95)

Here are the steps to download these files and build the Zig Display Driver for PinePhone...

```text
nuttx
├── apps (NuttX Apps for PinePhone including Display Engine)
│   ├── Application.mk
│   ├── DISCLAIMER
│   ├── Directory.mk
...
├── nuttx (NuttX OS for PinePhone)
│   ├── AUTHORS
│   ├── CONTRIBUTING.md
│   ├── DISCLAIMER
...
├── p-boot (Modified p-boot Display Code)
│   ├── HACKING
│   ├── LICENSE
│   ├── NEWS
...
├── pinephone-nuttx (Zig Display Driver for PinePhone)
│   ├── LICENSE
│   ├── README.md
│   ├── display.o
│   └── display.zig
...
└── test_display.c (Test Zig Display Driver)
```

1.  Create the NuttX Directory...

    ```bash
    mkdir nuttx
    cd nuttx
    ```

1.  Download `test-display.c` into the `nuttx` folder...

    [`test-display.c`](https://gist.github.com/lupyuen/ee3adf76e76881609845d0ab0f768a95)

1.  Download the Modified p-boot Display Code `p-boot.4.zip` from...

    [pinephone-nuttx/releases/tag/pboot4](https://github.com/lupyuen/pinephone-nuttx/releases/tag/pboot4)

    Extract into the `nuttx` folder and rename as `p-boot`

1.  Download and build NuttX for PinePhone inside the `nuttx` folder...

    ```bash
    ## TODO: Install Build Prerequisites
    ## https://lupyuen.github.io/articles/uboot#install-prerequisites

    ## Download NuttX OS for PinePhone
    git clone \
        --recursive \
        --branch pinephone \
        https://github.com/lupyuen/incubator-nuttx \
        nuttx

    ## Download NuttX Apps for PinePhone including Display Engine
    git clone \
        --recursive \
        --branch de \
        https://github.com/lupyuen/incubator-nuttx-apps \
        apps

    ## We'll build NuttX inside nuttx/nuttx
    cd nuttx

    ## Configure NuttX for Single Core
    ./tools/configure.sh -l qemu-a53:nsh

    ## Build NuttX. Ignore the Linker Errors
    make
    ```

1.  Follow these steps to compile our Zig App and link into NuttX...

    -   ["Zig on PinePhone"](https://github.com/lupyuen/pinephone-nuttx#zig-on-pinephone)

1.  Compress the NuttX Binary Image...

    ```bash
    cp nuttx.bin Image
    rm -f Image.gz
    gzip Image
    ```

1.  Copy the compressed NuttX Binary Image to Jumpdrive microSD...

    ```bash
    ## Copy compressed NuttX Binary Image to Jumpdrive microSD.
    ## How to create Jumpdrive microSD: https://lupyuen.github.io/articles/uboot#pinephone-jumpdrive
    ## TODO: Change the microSD Path
    cp Image.gz "/Volumes/NO NAME"
    ```

1.  To access the UART Port on PinePhone, we'll connect this USB Serial Debug Cable (at 115.2 kbps)...

    [PinePhone Serial Debug Cable](https://wiki.pine64.org/index.php/PinePhone#Serial_console)

1.  Insert the Jumpdrive microSD into PinePhone and power up

1.  At the NuttX Shell, enter `hello`

We should see...

```text
HELLO NUTTX ON PINEPHONE!
...
Shell (NSH) NuttX-11.0.0-RC2
nsh> hello
...
writeDcs: len=4
b9 f1 12 83 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=4
composeLongPacket: channel=0, cmd=0x39, len=4
packet: len=10
39 04 00 2c b9 f1 12 83 
84 5d 
modifyreg32: addr=0x300, val=0x2c000439
modifyreg32: addr=0x304, val=0x8312f1b9
modifyreg32: addr=0x308, val=0x00005d84
modifyreg32: addr=0x200, val=0x00000009
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
...
```

[(Source)](https://github.com/lupyuen/pinephone-nuttx#testing-nuttx-zig-driver-for-mipi-dsi-on-pinephone)

Our NuttX Zig Display Driver powers on the PinePhone Display and works exactly like the C Driver! 🎉

![Apache NuttX RTOS on PinePhone](https://lupyuen.github.io/images/dsi2-title.jpg)

_Can our driver render graphics on PinePhone Display?_

Our PinePhone Display Driver isn't complete. It handles MIPI DSI (for initialising ST7703) but doesn't support Allwinner A64's Display Engine (DE) and Timing Controller (TCON), which are needed for rendering graphics.

We'll implement DE and TCON next.

![Apache NuttX RTOS on PinePhone](https://lupyuen.github.io/images/de-title.jpg)

# Display Engine in Allwinner A64

Let's look inside PinePhone's Allwinner A64 Display Engine ... And render some graphics with Apache NuttX RTOS.

Here's the doc for the Display Engine...

-   [__Allwinner Display Engine 2.0 Specifications__](https://linux-sunxi.org/images/7/7b/Allwinner_DE2.0_Spec_V1.0.pdf)

_Which Display Engine for A64 (sun50iw1): H8, H3, H5 or A83?_

PinePhone's A64 Display Engine is hidden in the Allwinner H3 Docs, because Allwinner A64 is actually a H3 upgraded with 64-bit Cores...

> The A64 is basically an Allwinner H3 with the Cortex-A7 cores replaced with Cortex-A53 cores (ARM64 architecture). They share most of the memory map, clocks, interrupts and also uses the same IP blocks.

[(Source)](https://linux-sunxi.org/A64)

According to the doc, DE Base Address is 0x0100 0000 (Page 24)

Let's look at the DE Mixers...

# Display Engine Mixers

_What's a Display Engine Mixer?_

__DE RT-MIXER:__ (Page 87)
> The RT-mixer Core consist of dma, overlay, scaler and blender block. It supports 4 layers overlay in one pipe, and its result can scaler up or down to blender in the next processing.

The Display Engine has 2 Mixers: RT-MIXER0 and RT-MIXER1...

__DE RT-MIXER0__ has 4 Channels (DE Offset 0x10 0000, Page 87)
-   Channel 0 for Video: DMA0, Video Overlay, Video Scaler
-   Channels 1, 2, 3 for UI: DMA1 / 2 / 3, UI Overlays, UI Scalers, UI Blenders
-   4 Overlay Layers per Channel
-   Layer priority is Layer 3 > Layer2 > Layer 1 > Layer 0 (Page 89)
-   Channel 0 is unused (we don't use video right now)
-   Channel 1 has format XRGB 8888
-   Channels 2 and 3 have format ARGB 8888
-   MIXER0 Registers:
    -   GLB at MIXER0 Offset 0x00000 (de_glb_regs)
    -   BLD (Blender) at MIXER0 Offset 0x01000 (de_bld_regs)
    -   OVL_V(CH0) (Video Overlay / Channel 0) at MIXER0 Offset 0x2000 (Unused)
    -   OVL_UI(CH1) (UI Overlay / Channel 1) at MIXER0 Offset 0x3000
    -   OVL_UI(CH2) (UI Overlay / Channel 2) at MIXER0 Offset 0x4000
    -   OVL_UI(CH3) (UI Overlay / Channel 3) at MIXER0 Offset 0x5000
    -   POST_PROC2 at MIXER0 Offset 0xB0000 (de_csc_regs)

__DE RT-MIXER1__ has 2 Channels (DE Offset 0x20 0000, Page 23)
-   Channel 0 for Video: DMA0, Video Overlay, Video Scaler
-   Channel 1 for UI: DMA1, UI Overlay, UI Scaler, UI Blender
-   We don't use MIXER1 right now

RT-MIXER0 and RT-MIXER1 are multiplexed to Timing Controller TCON0.

(TCON0 is connected to ST7703 over MIPI DSI)

So MIXER0 mixes 1 Video Channel with 3 UI Channels over DMA ... And pumps the pixels continuously to ST7703 LCD Controller (via the Timing Controller)

Let's use the 3 UI Channels to render: 1️⃣ Mandelbrot Set 2️⃣ Blue Square 3️⃣ Green Circle

![Apache NuttX RTOS on PinePhone](https://lupyuen.github.io/images/de-overlay.jpg)

_Why 2 mixers?_

Maybe because A64 (or H3) was designed for [Set-Top Boxes](https://linux-sunxi.org/H3) with Picture-In-Picture Overlay Videos?

The 3 UI Overlay Channels would be useful for overlaying a Text UI on top of a Video Channel.

(Is that why Allwinner calls them "Channels"?)

# Display Engine Usage

Here are the steps to render 3 UI Channels (1 to 3) with the Display Engine, based on the log captured from [test_display.c](https://github.com/lupyuen/incubator-nuttx-apps/blob/de2/examples/hello/test_display.c)...

1.  Configure Blender...
    -   BLD BkColor (BLD_BK_COLOR Offset 0x88): BLD background color register
    -   BLD Premultiply (BLD_PREMUL_CTL Offset 0x84): BLD pre-multiply control register

    ```text
    Configure Blender
    BLD BkColor:     0x110 1088 = 0xff000000
    BLD Premultiply: 0x110 1084 = 0x0
    ```

1.  For Channels 1 to 3...

    1.  If Channel is unused, disable Overlay, Pipe and Scaler. Skip to next Channel

        -   UI Config Attr (OVL_UI_ATTCTL @ OVL_UI Offset 0x00): OVL_UI attribute control register
        -   Mixer (??? @ 0x113 0000 + 0x10000 * Channel)

        ```text
        Channel 2: Disable Overlay and Pipe
        UI Config Attr: 0x110 4000 = 0x0

        Channel 3: Disable Overlay and Pipe
        UI Config Attr: 0x110 5000 = 0x0

        Channel 2: Disable Scaler
        Mixer: 0x115 0000 = 0x0

        Channel 3: Disable Scaler
        Mixer: 0x116 0000 = 0x0
        ```

    1.  Channel 1 has format XRGB 8888, Channel 2 and 3 have format ARGB 8888

    1.  Set Overlay (Assume Layer = 0)
        -   UI Config Attr (OVL_UI_ATTCTL @ OVL_UI Offset 0x00): OVL_UI attribute control register
        -   UI Config Top LAddr (OVL_UI_TOP_LADD @ OVL_UI Offset 0x10): OVL_UI top field memory block low address register
        -   UI Config Pitch (OVL_UI_PITCH @ OVL_UI Offset 0x0C): OVL_UI memory pitch register
        -   UI Config Size (OVL_UI_MBSIZE @ OVL_UI Offset 0x04): OVL_UI memory block size register
        -   UI Overlay Size (OVL_UI_SIZE @ OVL_UI Offset 0x88): OVL_UI overlay window size register
        -   IO Config Coord (OVL_UI_COOR @ OVL_UI Offset 0x08): OVL_UI memory block coordinate register

        ```text
        Channel 1: Set Overlay
        UI Config Attr:      0x110 3000 = 0xff00 0405
        UI Config Top LAddr: 0x110 3010 = 0x4064 a6ac
        UI Config Pitch:     0x110 300c = 0xb40
        UI Config Size:      0x110 3004 = 0x59f 02cf
        UI Overlay Size:     0x110 3088 = 0x59f 02cf
        IO Config Coord:     0x110 3008 = 0x0

        Channel 2: Set Overlay
        UI Config Attr:      0x110 4000 = 0xff00 0005
        UI Config Top LAddr: 0x110 4010 = 0x404e adac
        UI Config Pitch:     0x110 400c = 0x960
        UI Config Size:      0x110 4004 = 0x257 0257
        UI Overlay Size:     0x110 4088 = 0x257 0257
        IO Config Coord:     0x110 4008 = 0x0

        Channel 3: Set Overlay
        UI Config Attr:      0x110 5000 = 0x7f00 0005
        UI Config Top LAddr: 0x110 5010 = 0x400f 65ac
        UI Config Pitch:     0x110 500c = 0xb40
        UI Config Size:      0x110 5004 = 0x59f 02cf
        UI Overlay Size:     0x110 5088 = 0x59f 02cf
        IO Config Coord:     0x110 5008 = 0x0
        ```

    1.  For Channel 1: Set Blender Output
        -   BLD Output Size (BLD_SIZE @ BLD Offset 0x08C): BLD output size setting register
        -   GLB Size (GLB_SIZE @ GLB Offset 0x00C): Global size register

        ```text
        Channel 1: Set Blender Output
        BLD Output Size: 0x110 108c = 0x59f 02cf
        GLB Size:        0x110 000c = 0x59f 02cf
        ```

    1.  Set Blender Input Pipe (N = Pipe Number, from 0 to 2 for Channels 1 to 3)
        -   BLD Pipe InSize (BLD_CH_ISIZE @ BLD Offset 0x008 + N*0x14): BLD input memory size register(N=0,1,2,3,4)
        -   BLD Pipe FColor (BLD_FILL_COLOR @ BLD Offset 0x004 + N*0x14): BLD fill color register(N=0,1,2,3,4)
        -   BLD Pipe Offset (BLD_CH_OFFSET @ BLD Offset 0x00C + N*0x14): BLD input memory offset register(N=0,1,2,3,4)
        -   BLD Pipe Mode (BLD_CTL @ BLD Offset 0x090 – 0x09C): BLD control register

        (Should `N*0x14` be `N*0x10` instead?)

        ```text
        Channel 1: Set Blender Input Pipe 0
        BLD Pipe InSize: 0x110 1008 = 0x59f 02cf
        BLD Pipe FColor: 0x110 1004 = 0xff00 0000
        BLD Pipe Offset: 0x110 100c = 0x0
        BLD Pipe Mode:   0x110 1090 = 0x301 0301

        Channel 2: Set Blender Input Pipe 1
        BLD Pipe InSize: 0x110 1018 = 0x257 0257
        BLD Pipe FColor: 0x110 1014 = 0xff00 0000
        BLD Pipe Offset: 0x110 101c = 0x34 0034
        BLD Pipe Mode:   0x110 1094 = 0x301 0301

        Channel 3: Set Blender Input Pipe 2
        BLD Pipe InSize: 0x110 1028 = 0x59f 02cf
        BLD Pipe FColor: 0x110 1024 = 0xff00 0000
        BLD Pipe Offset: 0x110 102c = 0x0
        BLD Pipe Mode:   0x110 1098 = 0x301 0301
        ```

    1.  Disable Scaler (assuming we're not using Scaler)

        ```text
        Channel 1: Disable Scaler
        Mixer: 0x114 0000 = 0x0

        Channel 2: Disable Scaler
        Mixer: 0x115 0000 = 0x0

        Channel 3: Disable Scaler
        Mixer: 0x116 0000 = 0x0
        ```

1.  Set BLD Route and BLD FColor Control
    -   BLD Route (BLD_CH_RTCTL @ BLD Offset 0x080): BLD routing control register
    -   BLD FColor Control (BLD_FILLCOLOR_CTL @ BLD Offset 0x000): BLD fill color control register

    ```text
    Set BLD Route and BLD FColor Control
    BLD Route:          0x110 1080 = 0x321
    BLD FColor Control: 0x110 1000 = 0x701
    ```

1.  Apply Settings: GLB DBuff
    -   GLB DBuff (GLB_DBUFFER @ GLB Offset 0x008): Global double buffer control register

    ```text
    Apply Settings
    GLB DBuff: 0x110 0008 = 0x1
    ```

[(See the Complete Log)](https://github.com/lupyuen/pinephone-nuttx#testing-p-boot-display-engine-on-pinephone)

(See Memory Mapping List and Register List at Page 90)

# Other Display Engine Features

__DE RT-WB:__ (Page 116)
> The Real-time write-back controller (RT-WB) provides data capture function for display engine. It captures data from RT-mixer module, performs the image resizing function, and then write-back to SDRAM.

(For screen capture?)

__DE VSU:__ (Page 128)
> The Video Scaler (VS) provides YUV format image resizing function for display engine. It receives data from overlay module, performs the image resizing function, and outputs to video post-processing modules. 

__DE Rotation:__ (Page 137)
> There are several types of rotation: clockwise 0/90/180/270 degree Rotation and H-Flip/V-Flip. Operation of Copy is the same as a 0 degree rotation.

# Timing Controller in Allwinner A64

TODO

# Test Logs

PinePhone Logs captured from various tests...

## Testing p-boot Display Engine on PinePhone

```text
...DRAM: 2048 MiB
Trying to boot from MMC1
NOTICE:  BL31: v2.2(release):v2.2-904-gf9ea3a629
NOTICE:  BL31: Built : 15:32:12, Apr  9 2020
NOTICE:  BL31: Detected Allwinner A64/H64/R18 SoC (1689)
NOTICE:  BL31: Found U-Boot DTB at 0x4064410, model: PinePhone
NOTICE:  PSCI: System suspend is unavailable


U-Boot 2020.07 (Nov 08 2020 - 00:15:12 +0100)

DRAM:  2 GiB
MMC:   Device 'mmc@1c11000': seq 1 is in use by 'mmc@1c10000'
mmc@1c0f000: 0, mmc@1c10000: 2, mmc@1c11000: 1
Loading Environment from FAT... *** Warning - bad CRC, using default environment

starting USB...
No working controllers found
Hit any key to stop autoboot:  0 
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
653 bytes read in 3 ms (211.9 KiB/s)
## Executing script at 4fc00000
gpio: pin 114 (gpio 114) value is 1
214380 bytes read in 14 ms (14.6 MiB/s)
Uncompressed size: 10240000 = 0x9C4000
36162 bytes read in 5 ms (6.9 MiB/s)
1078500 bytes read in 50 ms (20.6 MiB/s)
## Flattened Device Tree blob at 4fa00000
   Booting using the fdt blob at 0x4fa00000
   Loading Ramdisk to 49ef8000, end 49fff4e4 ... OK
   Loading Device Tree to 0000000049eec000, end 0000000049ef7d41 ... OK

Starting kernel ...

HELLO NUTTX ON PINEPHONE!
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x40a44000, heap_size=0x75bc000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
arm64_gic_initialize: GIC Version is 2
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
up_timer_initialize: _vector_table=0x400d2000
up_timer_initialize: Before writing: vbar_el1=0x40252000
up_timer_initialize: After writing: vbar_el1=0x400d2000
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x400d2000 _einit: 0x400d2000 _stext: 0x40080000 _etext: 0x400d3000
nsh: sysinit: fopen failed: 2
nshn:x _msktfaarttf:s :C PcUo0m:m aBnedg innonti nfgo uInddl
e
 
L
oNoupt
t
Shell (NSH) NuttX-11.0.0-RC2
nsh> hello
task_spawn: name=hello entry=0x4009d2fc file_actions=0x40a49580 attr=0x40a49588 argv=0x40a496d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
ABHello, World!!
ph_cfg1_reg=0x7177
ph_data_reg=0x400
pd_cfg2_reg=0x77711177
pd_data_reg=0x1c0000
struct reg_inst dsi_init_seq[] = {
.{ 0x0000, 0x00000001 },
.{ 0x0010, 0x00030000 },
.{ 0x0060, 0x0000000a },
.{ 0x0078, 0x00000000 },
.{ 0x0020, 0x0000001f },
.{ 0x0024, 0x10000001 },
.{ 0x0028, 0x20000010 },
.{ 0x002c, 0x2000000f },
.{ 0x0030, 0x30100001 },
.{ 0x0034, 0x40000010 },
.{ 0x0038, 0x0000000f },
.{ 0x003c, 0x5000001f },
.{ 0x004c, 0x00560001 },
.{ 0x02f8, 0x000000ff },
.{ 0x0014, 0x00005bc7 },
.{ 0x007c, 0x10000007 },
.{ 0x0040, 0x30000002 },
.{ 0x0044, 0x00310031 },
.{ 0x0054, 0x00310031 },
.{ 0x0090, 0x1308703e },
.{ 0x0098, 0x0000ffff },
.{ 0x009c, 0xffffffff },
.{ 0x0080, 0x00010008 },
display_malloc: size=2330
.{ 0x000c, 0x00000000 },
.{ 0x00b0, 0x12000021 },
.{ 0x00b4, 0x01000031 },
.{ 0x00b8, 0x07000001 },
.{ 0x00bc, 0x14000011 },
.{ 0x0018, 0x0011000a },
.{ 0x001c, 0x05cd05a0 },
.{ 0x00c0, 0x09004a19 },
.{ 0x00c4, 0x50b40000 },
.{ 0x00c8, 0x35005419 },
.{ 0x00cc, 0x757a0000 },
.{ 0x00d0, 0x09004a19 },
.{ 0x00d4, 0x50b40000 },
.{ 0x00e0, 0x0c091a19 },
.{ 0x00e4, 0x72bd0000 },
.{ 0x00e8, 0x1a000019 },
.{ 0x00ec, 0xffff0000 },
};

struct reg_inst dsi_panel_init_seq[] = {
nuttx_panel_init
writeDcs: len=4
b9 f1 12 83 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=4
composeLongPacket: channel=0, cmd=0x39, len=4
packet: len=10
39 04 00 2c b9 f1 12 83 
84 5d 
modifyreg32: addr=0x300, val=0x2c000439
modifyreg32: addr=0x304, val=0x8312f1b9
modifyreg32: addr=0x308, val=0x00005d84
modifyreg32: addr=0x200, val=0x00000009
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=28
ba 33 81 05 f9 0e 0e 20 
00 00 00 00 00 00 00 44 
25 00 91 0a 00 00 02 4f 
11 00 00 37 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=28
composeLongPacket: channel=0, cmd=0x39, len=28
packet: len=34
39 1c 00 2f ba 33 81 05 
f9 0e 0e 20 00 00 00 00 
00 00 00 44 25 00 91 0a 
00 00 02 4f 11 00 00 37 
2c e2 
modifyreg32: addr=0x300, val=0x2f001c39
modifyreg32: addr=0x304, val=0x058133ba
modifyreg32: addr=0x308, val=0x200e0ef9
modifyreg32: addr=0x30c, val=0x00000000
modifyreg32: addr=0x310, val=0x44000000
modifyreg32: addr=0x314, val=0x0a910025
modifyreg32: addr=0x318, val=0x4f020000
modifyreg32: addr=0x31c, val=0x37000011
modifyreg32: addr=0x320, val=0x0000e22c
modifyreg32: addr=0x200, val=0x00000021
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=5
b8 25 22 20 03 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=5
composeLongPacket: channel=0, cmd=0x39, len=5
packet: len=11
39 05 00 36 b8 25 22 20 
03 03 72 
modifyreg32: addr=0x300, val=0x36000539
modifyreg32: addr=0x304, val=0x202225b8
modifyreg32: addr=0x308, val=0x00720303
modifyreg32: addr=0x200, val=0x0000000a
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=11
b3 10 10 05 05 03 ff 00 
00 00 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=11
composeLongPacket: channel=0, cmd=0x39, len=11
packet: len=17
39 0b 00 2c b3 10 10 05 
05 03 ff 00 00 00 00 6f 
bc 
modifyreg32: addr=0x300, val=0x2c000b39
modifyreg32: addr=0x304, val=0x051010b3
modifyreg32: addr=0x308, val=0x00ff0305
modifyreg32: addr=0x30c, val=0x6f000000
modifyreg32: addr=0x310, val=0x000000bc
modifyreg32: addr=0x200, val=0x00000010
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=10
c0 73 73 50 50 00 c0 08 
70 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=10
composeLongPacket: channel=0, cmd=0x39, len=10
packet: len=16
39 0a 00 36 c0 73 73 50 
50 00 c0 08 70 00 1b 6a 

modifyreg32: addr=0x300, val=0x36000a39
modifyreg32: addr=0x304, val=0x507373c0
modifyreg32: addr=0x308, val=0x08c00050
modifyreg32: addr=0x30c, val=0x6a1b0070
modifyreg32: addr=0x200, val=0x0000000f
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=2
bc 4e 
mipi_dsi_dcs_write: channel=0, cmd=0x15, len=2
composeShortPacket: channel=0, cmd=0x15, len=2
packet: len=4
15 bc 4e 35 
modifyreg32: addr=0x300, val=0x354ebc15
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=2
cc 0b 
mipi_dsi_dcs_write: channel=0, cmd=0x15, len=2
composeShortPacket: channel=0, cmd=0x15, len=2
packet: len=4
15 cc 0b 22 
modifyreg32: addr=0x300, val=0x220bcc15
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=2
b4 80 
mipi_dsi_dcs_write: channel=0, cmd=0x15, len=2
composeShortPacket: channel=0, cmd=0x15, len=2
packet: len=4
15 b4 80 22 
modifyreg32: addr=0x300, val=0x2280b415
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=4
b2 f0 12 f0 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=4
composeLongPacket: channel=0, cmd=0x39, len=4
packet: len=10
39 04 00 2c b2 f0 12 f0 
51 86 
modifyreg32: addr=0x300, val=0x2c000439
modifyreg32: addr=0x304, val=0xf012f0b2
modifyreg32: addr=0x308, val=0x00008651
modifyreg32: addr=0x200, val=0x00000009
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=15
e3 00 00 0b 0b 10 10 00 
00 00 00 ff 00 c0 10 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=15
composeLongPacket: channel=0, cmd=0x39, len=15
packet: len=21
39 0f 00 0f e3 00 00 0b 
0b 10 10 00 00 00 00 ff 
00 c0 10 36 0f 
modifyreg32: addr=0x300, val=0x0f000f39
modifyreg32: addr=0x304, val=0x0b0000e3
modifyreg32: addr=0x308, val=0x0010100b
modifyreg32: addr=0x30c, val=0xff000000
modifyreg32: addr=0x310, val=0x3610c000
modifyreg32: addr=0x314, val=0x0000000f
modifyreg32: addr=0x200, val=0x00000014
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=6
c6 01 00 ff ff 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=6
composeLongPacket: channel=0, cmd=0x39, len=6
packet: len=12
39 06 00 30 c6 01 00 ff 
ff 00 8e 25 
modifyreg32: addr=0x300, val=0x30000639
modifyreg32: addr=0x304, val=0xff0001c6
modifyreg32: addr=0x308, val=0x258e00ff
modifyreg32: addr=0x200, val=0x0000000b
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=13
c1 74 00 32 32 77 f1 ff 
ff cc cc 77 77 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=13
composeLongPacket: channel=0, cmd=0x39, len=13
packet: len=19
39 0d 00 13 c1 74 00 32 
32 77 f1 ff ff cc cc 77 
77 69 e4 
modifyreg32: addr=0x300, val=0x13000d39
modifyreg32: addr=0x304, val=0x320074c1
modifyreg32: addr=0x308, val=0xfff17732
modifyreg32: addr=0x30c, val=0x77ccccff
modifyreg32: addr=0x310, val=0x00e46977
modifyreg32: addr=0x200, val=0x00000012
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=3
b5 07 07 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=3
composeLongPacket: channel=0, cmd=0x39, len=3
packet: len=9
39 03 00 09 b5 07 07 7b 
b3 
modifyreg32: addr=0x300, val=0x09000339
modifyreg32: addr=0x304, val=0x7b0707b5
modifyreg32: addr=0x308, val=0x000000b3
modifyreg32: addr=0x200, val=0x00000008
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=3
b6 2c 2c 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=3
composeLongPacket: channel=0, cmd=0x39, len=3
packet: len=9
39 03 00 09 b6 2c 2c 55 
04 
modifyreg32: addr=0x300, val=0x09000339
modifyreg32: addr=0x304, val=0x552c2cb6
modifyreg32: addr=0x308, val=0x00000004
modifyreg32: addr=0x200, val=0x00000008
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=4
bf 02 11 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=4
composeLongPacket: channel=0, cmd=0x39, len=4
packet: len=10
39 04 00 2c bf 02 11 00 
b5 e9 
modifyreg32: addr=0x300, val=0x2c000439
modifyreg32: addr=0x304, val=0x001102bf
modifyreg32: addr=0x308, val=0x0000e9b5
modifyreg32: addr=0x200, val=0x00000009
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=64
e9 82 10 06 05 a2 0a a5 
12 31 23 37 83 04 bc 27 
38 0c 00 03 00 00 00 0c 
00 03 00 00 00 75 75 31 
88 88 88 88 88 88 13 88 
64 64 20 88 88 88 88 88 
88 02 88 00 00 00 00 00 
00 00 00 00 00 00 00 00 

mipi_dsi_dcs_write: channel=0, cmd=0x39, len=64
composeLongPacket: channel=0, cmd=0x39, len=64
packet: len=70
39 40 00 25 e9 82 10 06 
05 a2 0a a5 12 31 23 37 
83 04 bc 27 38 0c 00 03 
00 00 00 0c 00 03 00 00 
00 75 75 31 88 88 88 88 
88 88 13 88 64 64 20 88 
88 88 88 88 88 02 88 00 
00 00 00 00 00 00 00 00 
00 00 00 00 65 03 
modifyreg32: addr=0x300, val=0x25004039
modifyreg32: addr=0x304, val=0x061082e9
modifyreg32: addr=0x308, val=0xa50aa205
modifyreg32: addr=0x30c, val=0x37233112
modifyreg32: addr=0x310, val=0x27bc0483
modifyreg32: addr=0x314, val=0x03000c38
modifyreg32: addr=0x318, val=0x0c000000
modifyreg32: addr=0x31c, val=0x00000300
modifyreg32: addr=0x320, val=0x31757500
modifyreg32: addr=0x324, val=0x88888888
modifyreg32: addr=0x328, val=0x88138888
modifyreg32: addr=0x32c, val=0x88206464
modifyreg32: addr=0x330, val=0x88888888
modifyreg32: addr=0x334, val=0x00880288
modifyreg32: addr=0x338, val=0x00000000
modifyreg32: addr=0x33c, val=0x00000000
modifyreg32: addr=0x340, val=0x00000000
modifyreg32: addr=0x344, val=0x00000365
modifyreg32: addr=0x200, val=0x00000045
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=62
ea 02 21 00 00 00 00 00 
00 00 00 00 00 02 46 02 
88 88 88 88 88 88 64 88 
13 57 13 88 88 88 88 88 
88 75 88 23 14 00 00 02 
00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 03 
0a a5 00 00 00 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=62
composeLongPacket: channel=0, cmd=0x39, len=62
packet: len=68
39 3e 00 1a ea 02 21 00 
00 00 00 00 00 00 00 00 
00 02 46 02 88 88 88 88 
88 88 64 88 13 57 13 88 
88 88 88 88 88 75 88 23 
14 00 00 02 00 00 00 00 
00 00 00 00 00 00 00 00 
00 00 00 03 0a a5 00 00 
00 00 24 1b 
modifyreg32: addr=0x300, val=0x1a003e39
modifyreg32: addr=0x304, val=0x002102ea
modifyreg32: addr=0x308, val=0x00000000
modifyreg32: addr=0x30c, val=0x00000000
modifyreg32: addr=0x310, val=0x02460200
modifyreg32: addr=0x314, val=0x88888888
modifyreg32: addr=0x318, val=0x88648888
modifyreg32: addr=0x31c, val=0x88135713
modifyreg32: addr=0x320, val=0x88888888
modifyreg32: addr=0x324, val=0x23887588
modifyreg32: addr=0x328, val=0x02000014
modifyreg32: addr=0x32c, val=0x00000000
modifyreg32: addr=0x330, val=0x00000000
modifyreg32: addr=0x334, val=0x00000000
modifyreg32: addr=0x338, val=0x03000000
modifyreg32: addr=0x33c, val=0x0000a50a
modifyreg32: addr=0x340, val=0x1b240000
modifyreg32: addr=0x200, val=0x00000043
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=35
e0 00 09 0d 23 27 3c 41 
35 07 0d 0e 12 13 10 12 
12 18 00 09 0d 23 27 3c 
41 35 07 0d 0e 12 13 10 
12 12 18 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=35
composeLongPacket: channel=0, cmd=0x39, len=35
packet: len=41
39 23 00 20 e0 00 09 0d 
23 27 3c 41 35 07 0d 0e 
12 13 10 12 12 18 00 09 
0d 23 27 3c 41 35 07 0d 
0e 12 13 10 12 12 18 93 
bf 
modifyreg32: addr=0x300, val=0x20002339
modifyreg32: addr=0x304, val=0x0d0900e0
modifyreg32: addr=0x308, val=0x413c2723
modifyreg32: addr=0x30c, val=0x0e0d0735
modifyreg32: addr=0x310, val=0x12101312
modifyreg32: addr=0x314, val=0x09001812
modifyreg32: addr=0x318, val=0x3c27230d
modifyreg32: addr=0x31c, val=0x0d073541
modifyreg32: addr=0x320, val=0x1013120e
modifyreg32: addr=0x324, val=0x93181212
modifyreg32: addr=0x328, val=0x000000bf
modifyreg32: addr=0x200, val=0x00000028
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=1
11 
mipi_dsi_dcs_write: channel=0, cmd=0x5, len=1
composeShortPacket: channel=0, cmd=0x5, len=1
packet: len=4
05 11 00 36 
modifyreg32: addr=0x300, val=0x36001105
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=1
29 
mipi_dsi_dcs_write: channel=0, cmd=0x5, len=1
composeShortPacket: channel=0, cmd=0x5, len=1
packet: len=4
05 29 00 1c 
modifyreg32: addr=0x300, val=0x1c002905
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
};
.{ 0x0048, 0x00000f02 },
.{ MAGIC_COMMIT, 0 },
dsi_update_bits: 0x01ca0020 : 0000001f -> (00000010) 00000000
.{ 0x0048, 0x63f07006 },
.{ MAGIC_COMMIT, 0 },
display_commit

Configure Blender
  BLD BkColor: 0x1101088 = 0xff000000
  BLD Premultiply: 0x1101084 = 0x0

Channel 1: Set Overlay
  UI Config Attr: 0x1103000 = 0xff000405
  UI Config Top LAddr: 0x1103010 = 0x4064a6ac
  UI Config Pitch: 0x110300c = 0xb40
  UI Config Size: 0x1103004 = 0x59f02cf
  UI Overlay Size: 0x1103088 = 0x59f02cf
  IO Config Coord: 0x1103008 = 0x0

Channel 1: Set Blender Output
  BLD Output Size: 0x110108c = 0x59f02cf
  GLB Size: 0x110000c = 0x59f02cf

Channel 1: Set Blender Input Pipe 0
  BLD Pipe InSize: 0x1101008 = 0x59f02cf
  BLD Pipe FColor: 0x1101004 = 0xff000000
  BLD Pipe Offset: 0x110100c = 0x0
  BLD Pipe Mode: 0x1101090 = 0x3010301

Channel 1: Disable Scaler
  Mixer: 0x1140000 = 0x0

Channel 2: Set Overlay
  UI Config Attr: 0x1104000 = 0xff000005
  UI Config Top LAddr: 0x1104010 = 0x404eadac
  UI Config Pitch: 0x110400c = 0x960
  UI Config Size: 0x1104004 = 0x2570257
  UI Overlay Size: 0x1104088 = 0x2570257
  IO Config Coord: 0x1104008 = 0x0

Channel 2: Set Blender Input Pipe 1
  BLD Pipe InSize: 0x1101018 = 0x2570257
  BLD Pipe FColor: 0x1101014 = 0xff000000
  BLD Pipe Offset: 0x110101c = 0x340034
  BLD Pipe Mode: 0x1101094 = 0x3010301

Channel 2: Disable Scaler
  Mixer: 0x1150000 = 0x0

Channel 3: Set Overlay
  UI Config Attr: 0x1105000 = 0x7f000005
  UI Config Top LAddr: 0x1105010 = 0x400f65ac
  UI Config Pitch: 0x110500c = 0xb40
  UI Config Size: 0x1105004 = 0x59f02cf
  UI Overlay Size: 0x1105088 = 0x59f02cf
  IO Config Coord: 0x1105008 = 0x0

Channel 3: Set Blender Input Pipe 2
  BLD Pipe InSize: 0x1101028 = 0x59f02cf
  BLD Pipe FColor: 0x1101024 = 0xff000000
  BLD Pipe Offset: 0x110102c = 0x0
  BLD Pipe Mode: 0x1101098 = 0x3010301

Channel 3: Disable Scaler
  Mixer: 0x1160000 = 0x0

Set BLD Route and BLD FColor Control
  BLD Route: 0x1101080 = 0x321
  BLD FColor Control: 0x1101000 = 0x701

Apply Settings
  GLB DBuff: 0x1100008 = 0x1
```

If we enable Channel 1 and disable Channels 2 and 3...

```text
display_commit

Configure Blender
  BLD BkColor: 0x1101088 = 0xff000000
  BLD Premultiply: 0x1101084 = 0x0

Channel 1: Set Overlay
  UI Config Attr: 0x1103000 = 0xff000405
  UI Config Top LAddr: 0x1103010 = 0x400f65ac
  UI Config Pitch: 0x110300c = 0xb40
  UI Config Size: 0x1103004 = 0x59f02cf
  UI Overlay Size: 0x1103088 = 0x59f02cf
  IO Config Coord: 0x1103008 = 0x0

Channel 1: Set Blender Output
  BLD Output Size: 0x110108c = 0x59f02cf
  GLB Size: 0x110000c = 0x59f02cf

Channel 1: Set Blender Input Pipe 0
  BLD Pipe InSize: 0x1101008 = 0x59f02cf
  BLD Pipe FColor: 0x1101004 = 0xff000000
  BLD Pipe Offset: 0x110100c = 0x0
  BLD Pipe Mode: 0x1101090 = 0x3010301

Channel 1: Disable Scaler
  Mixer: 0x1140000 = 0x0

Channel 2: Disable Overlay and Pipe
  UI Config Attr: 0x1104000 = 0x0

Channel 2: Disable Scaler
  Mixer: 0x1150000 = 0x0

Channel 3: Disable Overlay and Pipe
  UI Config Attr: 0x1105000 = 0x0

Channel 3: Disable Scaler
  Mixer: 0x1160000 = 0x0

Set BLD Route and BLD FColor Control
  BLD Route: 0x1101080 = 0x1
  BLD FColor Control: 0x1101000 = 0x101

Apply Settings
  GLB DBuff: 0x1100008 = 0x1
```

## Testing NuttX Zig Driver for MIPI DSI on PinePhone

Testing our [NuttX Zig Driver for MIPI DSI](https://github.com/lupyuen/pinephone-nuttx#zig-driver-for-pinephone-mipi-dsi) on PinePhone...

(Screen lights up and shows a test pattern)

```text
DRAM: 2048 MiB
Trying to boot from MMC1
NOTICE:  BL31: v2.2(release):v2.2-904-gf9ea3a629
NOTICE:  BL31: Built : 15:32:12, Apr  9 2020
NOTICE:  BL31: Detected Allwinner A64/H64/R18 SoC (1689)
NOTICE:  BL31: Found U-Boot DTB at 0x4064410, model: PinePhone
NOTICE:  PSCI: System suspend is unavailable


U-Boot 2020.07 (Nov 08 2020 - 00:15:12 +0100)

DRAM:  2 GiB
MMC:   Device 'mmc@1c11000': seq 1 is in use by 'mmc@1c10000'
mmc@1c0f000: 0, mmc@1c10000: 2, mmc@1c11000: 1
Loading Environment from FAT... *** Warning - bad CRC, using default environment

starting USB...
No working controllers found
Hit any key to stop autoboot:  0 
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
653 bytes read in 3 ms (211.9 KiB/s)
## Executing script at 4fc00000
gpio: pin 114 (gpio 114) value is 1
207379 bytes read in 13 ms (15.2 MiB/s)
Uncompressed size: 4653056 = 0x470000
36162 bytes read in 4 ms (8.6 MiB/s)
1078500 bytes read in 50 ms (20.6 MiB/s)
## Flattened Device Tree blob at 4fa00000
   Booting using the fdt blob at 0x4fa00000
   Loading Ramdisk to 49ef8000, end 49fff4e4 ... OK
   Loading Device Tree to 0000000049eec000, end 0000000049ef7d41 ... OK

Starting kernel ...

HELLO NUTTX ON PINEPHONE!
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x404f0000, heap_size=0x7b10000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
arm64_gic_initialize: GIC Version is 2
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
up_timer_initialize: _vector_table=0x400d2000
up_timer_initialize: Before writing: vbar_el1=0x40252000
up_timer_initialize: After writing: vbar_el1=0x400d2000
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x400d2000 _einit: 0x400d2000 _stext: 0x40080000 _etext: 0x400d3000
nsh: sysinit: fopen failed: 2
nshn:x _msktfaarttf:s :C PcUo0m:m aBnedg innonti nfgo uInddl
e
 
L
oNoupt
t
Shell (NSH) NuttX-11.0.0-RC2
nsh> hello
task_spawn: name=hello entry=0x4009ce64 file_actions=0x404f5580 attr=0x404f5588 argv=0x404f56d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
ABHello, World!!
ph_cfg1_reg=0x7177
ph_data_reg=0x400
pd_cfg2_reg=0x77711177
pd_data_reg=0x1c0000
struct reg_inst dsi_init_seq[] = {
.{ 0x0000, 0x00000001 },
.{ 0x0010, 0x00030000 },
.{ 0x0060, 0x0000000a },
.{ 0x0078, 0x00000000 },
.{ 0x0020, 0x0000001f },
.{ 0x0024, 0x10000001 },
.{ 0x0028, 0x20000010 },
.{ 0x002c, 0x2000000f },
.{ 0x0030, 0x30100001 },
.{ 0x0034, 0x40000010 },
.{ 0x0038, 0x0000000f },
.{ 0x003c, 0x5000001f },
.{ 0x004c, 0x00560001 },
.{ 0x02f8, 0x000000ff },
.{ 0x0014, 0x00005bc7 },
.{ 0x007c, 0x10000007 },
.{ 0x0040, 0x30000002 },
.{ 0x0044, 0x00310031 },
.{ 0x0054, 0x00310031 },
.{ 0x0090, 0x1308703e },
.{ 0x0098, 0x0000ffff },
.{ 0x009c, 0xffffffff },
.{ 0x0080, 0x00010008 },
display_malloc: size=2330
.{ 0x000c, 0x00000000 },
.{ 0x00b0, 0x12000021 },
.{ 0x00b4, 0x01000031 },
.{ 0x00b8, 0x07000001 },
.{ 0x00bc, 0x14000011 },
.{ 0x0018, 0x0011000a },
.{ 0x001c, 0x05cd05a0 },
.{ 0x00c0, 0x09004a19 },
.{ 0x00c4, 0x50b40000 },
.{ 0x00c8, 0x35005419 },
.{ 0x00cc, 0x757a0000 },
.{ 0x00d0, 0x09004a19 },
.{ 0x00d4, 0x50b40000 },
.{ 0x00e0, 0x0c091a19 },
.{ 0x00e4, 0x72bd0000 },
.{ 0x00e8, 0x1a000019 },
.{ 0x00ec, 0xffff0000 },
};

struct reg_inst dsi_panel_init_seq[] = {
nuttx_panel_init
writeDcs: len=4
b9 f1 12 83 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=4
composeLongPacket: channel=0, cmd=0x39, len=4
packet: len=10
39 04 00 2c b9 f1 12 83 
84 5d 
modifyreg32: addr=0x300, val=0x2c000439
modifyreg32: addr=0x304, val=0x8312f1b9
modifyreg32: addr=0x308, val=0x00005d84
modifyreg32: addr=0x200, val=0x00000009
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=28
ba 33 81 05 f9 0e 0e 20 
00 00 00 00 00 00 00 44 
25 00 91 0a 00 00 02 4f 
11 00 00 37 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=28
composeLongPacket: channel=0, cmd=0x39, len=28
packet: len=34
39 1c 00 2f ba 33 81 05 
f9 0e 0e 20 00 00 00 00 
00 00 00 44 25 00 91 0a 
00 00 02 4f 11 00 00 37 
2c e2 
modifyreg32: addr=0x300, val=0x2f001c39
modifyreg32: addr=0x304, val=0x058133ba
modifyreg32: addr=0x308, val=0x200e0ef9
modifyreg32: addr=0x30c, val=0x00000000
modifyreg32: addr=0x310, val=0x44000000
modifyreg32: addr=0x314, val=0x0a910025
modifyreg32: addr=0x318, val=0x4f020000
modifyreg32: addr=0x31c, val=0x37000011
modifyreg32: addr=0x320, val=0x0000e22c
modifyreg32: addr=0x200, val=0x00000021
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=5
b8 25 22 20 03 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=5
composeLongPacket: channel=0, cmd=0x39, len=5
packet: len=11
39 05 00 36 b8 25 22 20 
03 03 72 
modifyreg32: addr=0x300, val=0x36000539
modifyreg32: addr=0x304, val=0x202225b8
modifyreg32: addr=0x308, val=0x00720303
modifyreg32: addr=0x200, val=0x0000000a
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=11
b3 10 10 05 05 03 ff 00 
00 00 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=11
composeLongPacket: channel=0, cmd=0x39, len=11
packet: len=17
39 0b 00 2c b3 10 10 05 
05 03 ff 00 00 00 00 6f 
bc 
modifyreg32: addr=0x300, val=0x2c000b39
modifyreg32: addr=0x304, val=0x051010b3
modifyreg32: addr=0x308, val=0x00ff0305
modifyreg32: addr=0x30c, val=0x6f000000
modifyreg32: addr=0x310, val=0x000000bc
modifyreg32: addr=0x200, val=0x00000010
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=10
c0 73 73 50 50 00 c0 08 
70 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=10
composeLongPacket: channel=0, cmd=0x39, len=10
packet: len=16
39 0a 00 36 c0 73 73 50 
50 00 c0 08 70 00 1b 6a 

modifyreg32: addr=0x300, val=0x36000a39
modifyreg32: addr=0x304, val=0x507373c0
modifyreg32: addr=0x308, val=0x08c00050
modifyreg32: addr=0x30c, val=0x6a1b0070
modifyreg32: addr=0x200, val=0x0000000f
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=2
bc 4e 
mipi_dsi_dcs_write: channel=0, cmd=0x15, len=2
composeShortPacket: channel=0, cmd=0x15, len=2
packet: len=4
15 bc 4e 35 
modifyreg32: addr=0x300, val=0x354ebc15
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=2
cc 0b 
mipi_dsi_dcs_write: channel=0, cmd=0x15, len=2
composeShortPacket: channel=0, cmd=0x15, len=2
packet: len=4
15 cc 0b 22 
modifyreg32: addr=0x300, val=0x220bcc15
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=2
b4 80 
mipi_dsi_dcs_write: channel=0, cmd=0x15, len=2
composeShortPacket: channel=0, cmd=0x15, len=2
packet: len=4
15 b4 80 22 
modifyreg32: addr=0x300, val=0x2280b415
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=4
b2 f0 12 f0 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=4
composeLongPacket: channel=0, cmd=0x39, len=4
packet: len=10
39 04 00 2c b2 f0 12 f0 
51 86 
modifyreg32: addr=0x300, val=0x2c000439
modifyreg32: addr=0x304, val=0xf012f0b2
modifyreg32: addr=0x308, val=0x00008651
modifyreg32: addr=0x200, val=0x00000009
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=15
e3 00 00 0b 0b 10 10 00 
00 00 00 ff 00 c0 10 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=15
composeLongPacket: channel=0, cmd=0x39, len=15
packet: len=21
39 0f 00 0f e3 00 00 0b 
0b 10 10 00 00 00 00 ff 
00 c0 10 36 0f 
modifyreg32: addr=0x300, val=0x0f000f39
modifyreg32: addr=0x304, val=0x0b0000e3
modifyreg32: addr=0x308, val=0x0010100b
modifyreg32: addr=0x30c, val=0xff000000
modifyreg32: addr=0x310, val=0x3610c000
modifyreg32: addr=0x314, val=0x0000000f
modifyreg32: addr=0x200, val=0x00000014
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=6
c6 01 00 ff ff 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=6
composeLongPacket: channel=0, cmd=0x39, len=6
packet: len=12
39 06 00 30 c6 01 00 ff 
ff 00 8e 25 
modifyreg32: addr=0x300, val=0x30000639
modifyreg32: addr=0x304, val=0xff0001c6
modifyreg32: addr=0x308, val=0x258e00ff
modifyreg32: addr=0x200, val=0x0000000b
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=13
c1 74 00 32 32 77 f1 ff 
ff cc cc 77 77 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=13
composeLongPacket: channel=0, cmd=0x39, len=13
packet: len=19
39 0d 00 13 c1 74 00 32 
32 77 f1 ff ff cc cc 77 
77 69 e4 
modifyreg32: addr=0x300, val=0x13000d39
modifyreg32: addr=0x304, val=0x320074c1
modifyreg32: addr=0x308, val=0xfff17732
modifyreg32: addr=0x30c, val=0x77ccccff
modifyreg32: addr=0x310, val=0x00e46977
modifyreg32: addr=0x200, val=0x00000012
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=3
b5 07 07 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=3
composeLongPacket: channel=0, cmd=0x39, len=3
packet: len=9
39 03 00 09 b5 07 07 7b 
b3 
modifyreg32: addr=0x300, val=0x09000339
modifyreg32: addr=0x304, val=0x7b0707b5
modifyreg32: addr=0x308, val=0x000000b3
modifyreg32: addr=0x200, val=0x00000008
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=3
b6 2c 2c 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=3
composeLongPacket: channel=0, cmd=0x39, len=3
packet: len=9
39 03 00 09 b6 2c 2c 55 
04 
modifyreg32: addr=0x300, val=0x09000339
modifyreg32: addr=0x304, val=0x552c2cb6
modifyreg32: addr=0x308, val=0x00000004
modifyreg32: addr=0x200, val=0x00000008
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=4
bf 02 11 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=4
composeLongPacket: channel=0, cmd=0x39, len=4
packet: len=10
39 04 00 2c bf 02 11 00 
b5 e9 
modifyreg32: addr=0x300, val=0x2c000439
modifyreg32: addr=0x304, val=0x001102bf
modifyreg32: addr=0x308, val=0x0000e9b5
modifyreg32: addr=0x200, val=0x00000009
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=64
e9 82 10 06 05 a2 0a a5 
12 31 23 37 83 04 bc 27 
38 0c 00 03 00 00 00 0c 
00 03 00 00 00 75 75 31 
88 88 88 88 88 88 13 88 
64 64 20 88 88 88 88 88 
88 02 88 00 00 00 00 00 
00 00 00 00 00 00 00 00 

mipi_dsi_dcs_write: channel=0, cmd=0x39, len=64
composeLongPacket: channel=0, cmd=0x39, len=64
packet: len=70
39 40 00 25 e9 82 10 06 
05 a2 0a a5 12 31 23 37 
83 04 bc 27 38 0c 00 03 
00 00 00 0c 00 03 00 00 
00 75 75 31 88 88 88 88 
88 88 13 88 64 64 20 88 
88 88 88 88 88 02 88 00 
00 00 00 00 00 00 00 00 
00 00 00 00 65 03 
modifyreg32: addr=0x300, val=0x25004039
modifyreg32: addr=0x304, val=0x061082e9
modifyreg32: addr=0x308, val=0xa50aa205
modifyreg32: addr=0x30c, val=0x37233112
modifyreg32: addr=0x310, val=0x27bc0483
modifyreg32: addr=0x314, val=0x03000c38
modifyreg32: addr=0x318, val=0x0c000000
modifyreg32: addr=0x31c, val=0x00000300
modifyreg32: addr=0x320, val=0x31757500
modifyreg32: addr=0x324, val=0x88888888
modifyreg32: addr=0x328, val=0x88138888
modifyreg32: addr=0x32c, val=0x88206464
modifyreg32: addr=0x330, val=0x88888888
modifyreg32: addr=0x334, val=0x00880288
modifyreg32: addr=0x338, val=0x00000000
modifyreg32: addr=0x33c, val=0x00000000
modifyreg32: addr=0x340, val=0x00000000
modifyreg32: addr=0x344, val=0x00000365
modifyreg32: addr=0x200, val=0x00000045
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=62
ea 02 21 00 00 00 00 00 
00 00 00 00 00 02 46 02 
88 88 88 88 88 88 64 88 
13 57 13 88 88 88 88 88 
88 75 88 23 14 00 00 02 
00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 03 
0a a5 00 00 00 00 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=62
composeLongPacket: channel=0, cmd=0x39, len=62
packet: len=68
39 3e 00 1a ea 02 21 00 
00 00 00 00 00 00 00 00 
00 02 46 02 88 88 88 88 
88 88 64 88 13 57 13 88 
88 88 88 88 88 75 88 23 
14 00 00 02 00 00 00 00 
00 00 00 00 00 00 00 00 
00 00 00 03 0a a5 00 00 
00 00 24 1b 
modifyreg32: addr=0x300, val=0x1a003e39
modifyreg32: addr=0x304, val=0x002102ea
modifyreg32: addr=0x308, val=0x00000000
modifyreg32: addr=0x30c, val=0x00000000
modifyreg32: addr=0x310, val=0x02460200
modifyreg32: addr=0x314, val=0x88888888
modifyreg32: addr=0x318, val=0x88648888
modifyreg32: addr=0x31c, val=0x88135713
modifyreg32: addr=0x320, val=0x88888888
modifyreg32: addr=0x324, val=0x23887588
modifyreg32: addr=0x328, val=0x02000014
modifyreg32: addr=0x32c, val=0x00000000
modifyreg32: addr=0x330, val=0x00000000
modifyreg32: addr=0x334, val=0x00000000
modifyreg32: addr=0x338, val=0x03000000
modifyreg32: addr=0x33c, val=0x0000a50a
modifyreg32: addr=0x340, val=0x1b240000
modifyreg32: addr=0x200, val=0x00000043
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=35
e0 00 09 0d 23 27 3c 41 
35 07 0d 0e 12 13 10 12 
12 18 00 09 0d 23 27 3c 
41 35 07 0d 0e 12 13 10 
12 12 18 
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=35
composeLongPacket: channel=0, cmd=0x39, len=35
packet: len=41
39 23 00 20 e0 00 09 0d 
23 27 3c 41 35 07 0d 0e 
12 13 10 12 12 18 00 09 
0d 23 27 3c 41 35 07 0d 
0e 12 13 10 12 12 18 93 
bf 
modifyreg32: addr=0x300, val=0x20002339
modifyreg32: addr=0x304, val=0x0d0900e0
modifyreg32: addr=0x308, val=0x413c2723
modifyreg32: addr=0x30c, val=0x0e0d0735
modifyreg32: addr=0x310, val=0x12101312
modifyreg32: addr=0x314, val=0x09001812
modifyreg32: addr=0x318, val=0x3c27230d
modifyreg32: addr=0x31c, val=0x0d073541
modifyreg32: addr=0x320, val=0x1013120e
modifyreg32: addr=0x324, val=0x93181212
modifyreg32: addr=0x328, val=0x000000bf
modifyreg32: addr=0x200, val=0x00000028
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=1
11 
mipi_dsi_dcs_write: channel=0, cmd=0x5, len=1
composeShortPacket: channel=0, cmd=0x5, len=1
packet: len=4
05 11 00 36 
modifyreg32: addr=0x300, val=0x36001105
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
writeDcs: len=1
29 
mipi_dsi_dcs_write: channel=0, cmd=0x5, len=1
composeShortPacket: channel=0, cmd=0x5, len=1
packet: len=4
05 29 00 1c 
modifyreg32: addr=0x300, val=0x1c002905
modifyreg32: addr=0x200, val=0x00000003
modifyreg32: addr=0x010, val=0x00000000
modifyreg32: addr=0x010, val=0x00000001
};
.{ 0x0048, 0x00000f02 },
.{ MAGIC_COMMIT, 0 },
dsi_update_bits: 0x01ca0020 : 0000001f -> (00000010) 00000000
.{ 0x0048, 0x63f07006 },
.{ MAGIC_COMMIT, 0 },
HELLO ZIG ON PINEPHONE!
Testing Compose Short Packet (Without Parameter)...
composeShortPacket: channel=0, cmd=0x5, len=1
Result:
05 11 00 36 
Testing Compose Short Packet (With Parameter)...
composeShortPacket: channel=0, cmd=0x15, len=2
Result:
15 bc 4e 35 
Testing Compose Long Packet...
composeLongPacket: channel=0, cmd=0x39, len=64
Result:
39 40 00 25 e9 82 10 06 
05 a2 0a a5 12 31 23 37 
83 04 bc 27 38 0c 00 03 
00 00 00 0c 00 03 00 00 
00 75 75 31 88 88 88 88 
88 88 13 88 64 64 20 88 
88 88 88 88 88 02 88 00 
00 00 00 00 00 00 00 00 
00 00 00 00 65 03 
nsh> 
nsh> uname -a
NuttX 11.0.0-RC2 a33f82d Oct  6 2022 19:36:13 arm64 qemu-a53
nsh> 
nsh> 
```

## Testing NuttX Zig Driver for MIPI DSI on QEMU

Testing our [NuttX Zig Driver for MIPI DSI](https://github.com/lupyuen/pinephone-nuttx#zig-driver-for-pinephone-mipi-dsi) on PinePhone...

```text
+ aarch64-none-elf-gcc -v
Using built-in specs.
COLLECT_GCC=aarch64-none-elf-gcc
COLLECT_LTO_WRAPPER=/Applications/ArmGNUToolchain/11.3.rel1/aarch64-none-elf/bin/../libexec/gcc/aarch64-none-elf/11.3.1/lto-wrapper
Target: aarch64-none-elf
Configured with: /Volumes/data/jenkins/workspace/GNU-toolchain/arm-11/src/gcc/configure --target=aarch64-none-elf --prefix=/Volumes/data/jenkins/workspace/GNU-toolchain/arm-11/build-aarch64-none-elf/install --with-gmp=/Volumes/data/jenkins/workspace/GNU-toolchain/arm-11/build-aarch64-none-elf/host-tools --with-mpfr=/Volumes/data/jenkins/workspace/GNU-toolchain/arm-11/build-aarch64-none-elf/host-tools --with-mpc=/Volumes/data/jenkins/workspace/GNU-toolchain/arm-11/build-aarch64-none-elf/host-tools --with-isl=/Volumes/data/jenkins/workspace/GNU-toolchain/arm-11/build-aarch64-none-elf/host-tools --disable-shared --disable-nls --disable-threads --disable-tls --enable-checking=release --enable-languages=c,c++,fortran --with-newlib --with-gnu-as --with-gnu-ld --with-sysroot=/Volumes/data/jenkins/workspace/GNU-toolchain/arm-11/build-aarch64-none-elf/install/aarch64-none-elf --with-pkgversion='Arm GNU Toolchain 11.3.Rel1' --with-bugurl=https://bugs.linaro.org/
Thread model: single
Supported LTO compression algorithms: zlib
gcc version 11.3.1 20220712 (Arm GNU Toolchain 11.3.Rel1) 
+ zig version
0.10.0-dev.2351+b64a1d5ab
+ build_zig
+ pushd ../pinephone-nuttx
~/gicv2/nuttx/pinephone-nuttx ~/gicv2/nuttx/nuttx
+ git pull
Already up-to-date.
+ zig build-obj -target aarch64-freestanding-none -mcpu cortex_a53 -isystem /Users/Luppy/gicv2/nuttx/nuttx/include -I /Users/Luppy/gicv2/nuttx/apps/include display.zig
+ cp display.o /Users/Luppy/gicv2/nuttx/apps/examples/null/null_main.c.Users.Luppy.gicv2.nuttx.apps.examples.null.o
+ popd
~/gicv2/nuttx/nuttx
+ make -j
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/apps'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/libs/libxx'
make[1]: 'libxx.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/libs/libxx'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/examples/hello'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/builtin'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/examples/null'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/system'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/readline'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/testing/getprime'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/platform'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/nsh'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/nshlib'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/testing/ostest'
make[2]: Nothing to be done for 'depend'.
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/nshlib'
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/system'
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/examples/hello'
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/readline'
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/testing/getprime'
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/examples/null'
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/platform'
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/builtin'
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/nsh'
make[2]: Nothing to be done for 'depend'.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/testing/ostest'
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/sched'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/sched'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/drivers'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/drivers'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/boards'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/boards'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/arch/arm64/src'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/arch/arm64/src'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/fs'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/fs'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/binfmt'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/binfmt'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/libs/libc'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/libs/libc'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/mm'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/mm'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/libs/libxx'
make[1]: Nothing to be done for 'depend'.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/libs/libxx'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/sched'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/drivers'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/libs/libc'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/boards'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/mm'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/arch/arm64/src'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/apps'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/fs'
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/binfmt'
make[1]: 'libboards.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/boards'
make[1]: 'libdrivers.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/drivers'
make[1]: 'libmm.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/mm'
make[1]: 'libsched.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/sched'
make[1]: 'libfs.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/fs'
make[1]: 'libbinfmt.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/binfmt'
rm -f /Users/Luppy/gicv2/nuttx/apps/libapps.a
make /Users/Luppy/gicv2/nuttx/apps/libapps.a
make[1]: 'libarch.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/arch/arm64/src'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/apps'
make[1]: 'libc.a' is up to date.
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/libs/libc'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/builtin'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/nshlib'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/testing/getprime'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/examples/null'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/platform'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/examples/hello'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/system'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/testing/ostest'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/nsh'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/readline'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/examples/hello'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/builtin'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/platform'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/nsh'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/system'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/testing/ostest'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/nshlib'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/testing/getprime'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/examples/null'
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/readline'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/builtin'
AR (add): libapps.a    builtin_list.c.Users.Luppy.gicv2.nuttx.apps.builtin.o exec_builtin.c.Users.Luppy.gicv2.nuttx.apps.builtin.o       
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/builtin'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/examples/hello'
AR (add): libapps.a        hello_main.c.Users.Luppy.gicv2.nuttx.apps.examples.hello.o   
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/examples/hello'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/examples/null'
AR (add): libapps.a        null_main.c.Users.Luppy.gicv2.nuttx.apps.examples.null.o   
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/examples/null'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/nshlib'
AR (add): libapps.a    nsh_init.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_parse.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_console.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_script.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_system.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_command.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_fscmds.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_ddcmd.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_proccmds.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_mmcmds.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_timcmds.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_envcmds.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_syscmds.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_dbgcmds.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_session.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_fsutils.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_builtin.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_romfsetc.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_mntcmds.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_consolemain.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_printf.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o nsh_test.c.Users.Luppy.gicv2.nuttx.apps.nshlib.o       
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/nshlib'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/platform'
AR (add): libapps.a    dummy.c.Users.Luppy.gicv2.nuttx.apps.platform.o       
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/platform'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/nsh'
AR (add): libapps.a        nsh_main.c.Users.Luppy.gicv2.nuttx.apps.system.nsh.o sh_main.c.Users.Luppy.gicv2.nuttx.apps.system.nsh.o   
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/nsh'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/readline'
AR (add): libapps.a    readline.c.Users.Luppy.gicv2.nuttx.apps.system.readline.o readline_fd.c.Users.Luppy.gicv2.nuttx.apps.system.readline.o readline_common.c.Users.Luppy.gicv2.nuttx.apps.system.readline.o       
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/readline'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/system/system'
AR (add): libapps.a    system.c.Users.Luppy.gicv2.nuttx.apps.system.system.o       
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/system/system'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/testing/getprime'
AR (add): libapps.a        getprime_main.c.Users.Luppy.gicv2.nuttx.apps.testing.getprime.o   
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/testing/getprime'
make[3]: Entering directory '/Users/Luppy/gicv2/nuttx/apps/testing/ostest'
AR (add): libapps.a    getopt.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o dev_null.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o restart.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o sigprocmask.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o sighand.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o signest.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o fpu.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o setvbuf.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o tls.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o waitpid.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o cancel.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o cond.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o mutex.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o timedmutex.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o sem.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o semtimed.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o barrier.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o timedwait.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o pthread_rwlock.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o pthread_rwlock_cancel.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o specific.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o robust.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o roundrobin.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o mqueue.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o timedmqueue.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o posixtimer.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o vfork.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o    ostest_main.c.Users.Luppy.gicv2.nuttx.apps.testing.ostest.o   
make[3]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps/testing/ostest'
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps'
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/apps'
IN: /Users/Luppy/gicv2/nuttx/apps/libapps.a -> staging/libapps.a
make[1]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/arch/arm64/src'
make[2]: Entering directory '/Users/Luppy/gicv2/nuttx/nuttx/boards/arm64/qemu/qemu-a53/src'
make[2]: 'libboard.a' is up to date.
make[2]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/boards/arm64/qemu/qemu-a53/src'
LD: nuttx
make[1]: Leaving directory '/Users/Luppy/gicv2/nuttx/nuttx/arch/arm64/src'
CP: nuttx.hex
CP: nuttx.bin
+ aarch64-none-elf-size nuttx
   text    data     bss     dec     hex filename
 253075   12624   48504  314203   4cb5b nuttx
+ aarch64-none-elf-objdump -t -S --demangle --line-numbers --wide nuttx
+ qemu-system-aarch64 -smp 4 -cpu cortex-a53 -nographic -machine virt,virtualization=on,gic-version=2 -net none -chardev stdio,id=con,mux=on -serial chardev:con -mon chardev=con,mode=readline -kernel ./nuttx
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x402cf000, heap_size=0x7d31000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x8000000
arm64_gic_initialize: CONFIG_GICR_BASE=0x8010000
arm64_gic_initialize: GIC Version is 2
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 62.50MHz, cycle 62500
up_timer_initialize: _vector_table=0x402b1000
up_timer_initialize: Before writing: vbar_el1=0x402b1000
up_timer_initialize: After writing: vbar_el1=0x402b1000
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x402b1000 _einit: 0x402b1000 _stext: 0x40280000 _etext: 0x402b2000
nsh: sysinit: fopen failed: 2
nsh: mkfatfs: command not found

NuttShell (NSH) NuttX-11.0.0-RC2
nsh> nx_start: CPU0: Beginning Idle Loop

nsh> null
task_spawn: name=null entry=0x4029c9d0 file_actions=0x402d4580 attr=0x402d4588 argv=0x402d46d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
HELLO ZIG ON PINEPHONE!
Testing Compose Short Packet (Without Parameter)...
composeShortPacket: channel=0, cmd=0x5, len=1
Result:
05 11 00 36 
Testing Compose Short Packet (With Parameter)...
composeShortPacket: channel=0, cmd=0x15, len=2
Result:
15 bc 4e 35 
Testing Compose Long Packet...
composeLongPacket: channel=0, cmd=0x39, len=64
Result:
39 40 00 25 e9 82 10 06 
05 a2 0a a5 12 31 23 37 
83 04 bc 27 38 0c 00 03 
00 00 00 0c 00 03 00 00 
00 75 75 31 88 88 88 88 
88 88 13 88 64 64 20 88 
88 88 88 88 88 02 88 00 
00 00 00 00 00 00 00 00 
00 00 00 00 65 03 
nsh> qemu-system-aarch64: terminating on signal 2 from pid 5928 (<unknown process>)
 *  Terminal will be reused by tasks, press any key to close it. 
```

## Testing p-boot Driver for MIPI DSI (with logging)

Testing [PinePhone p-boot Display Code](https://gist.github.com/lupyuen/ee3adf76e76881609845d0ab0f768a95) with logging...

```text
DRAM: 2048 MiB
Trying to boot from MMC1
NOTICE:  BL31: v2.2(release):v2.2-904-gf9ea3a629
NOTICE:  BL31: Built : 15:32:12, Apr  9 2020
NOTICE:  BL31: Detected Allwinner A64/H64/R18 SoC (1689)
NOTICE:  BL31: Found U-Boot DTB at 0x4064410, model: PinePhone
NOTICE:  PSCI: System suspend is unavailable


U-Boot 2020.07 (Nov 08 2020 - 00:15:12 +0100)

DRAM:  2 GiB
MMC:   Device 'mmc@1c11000': seq 1 is in use by 'mmc@1c10000'
mmc@1c0f000: 0, mmc@1c10000: 2, mmc@1c11000: 1
Loading Environment from FAT... *** Warning - bad CRC, using default environment

starting USB...
No working controllers found
Hit any key to stop autoboot:  0 
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
653 bytes read in 3 ms (211.9 KiB/s)
## Executing script at 4fc00000
gpio: pin 114 (gpio 114) value is 1
205024 bytes read in 13 ms (15 MiB/s)
Uncompressed size: 4640768 = 0x46D000
36162 bytes read in 4 ms (8.6 MiB/s)
1078500 bytes read in 51 ms (20.2 MiB/s)
## Flattened Device Tree blob at 4fa00000
   Booting using the fdt blob at 0x4fa00000
   Loading Ramdisk to 49ef8000, end 49fff4e4 ... OK
   Loading Device Tree to 0000000049eec000, end 0000000049ef7d41 ... OK

Starting kernel ...

HELLO NUTTX ON PINEPHONE!
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x404ed000, heap_size=0x7b13000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
arm64_gic_initialize: GIC Version is 2
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
up_timer_initialize: _vector_table=0x400cf000
up_timer_initialize: Before writing: vbar_el1=0x4024f000
up_timer_initialize: After writing: vbar_el1=0x400cf000
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x400cf000 _einit: 0x400cf000 _stext: 0x40080000 _etext: 0x400d0000
nsh: sysinit: fopen failed: 2
nshn:x _msktfaarttf:s :C PcUo0m:m aBnedg innonti nfgo uInddl
e
 
L
oNoupt
t
Shell (NSH) NuttX-11.0.0-RC2
nsh> hello
task_spawn: name=hello entry=0x4009cf58 file_actions=0x404f2580 attr=0x404f2588 argv=0x404f26d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
ABHello, World!!
ph_cfg1_reg=0x7177
ph_data_reg=0x400
pd_cfg2_reg=0x77711177
pd_data_reg=0x1c0000
struct reg_inst dsi_init_seq[] = {
.{ 0x0000, 0x00000001 },
.{ 0x0010, 0x00030000 },
.{ 0x0060, 0x0000000a },
.{ 0x0078, 0x00000000 },
.{ 0x0020, 0x0000001f },
.{ 0x0024, 0x10000001 },
.{ 0x0028, 0x20000010 },
.{ 0x002c, 0x2000000f },
.{ 0x0030, 0x30100001 },
.{ 0x0034, 0x40000010 },
.{ 0x0038, 0x0000000f },
.{ 0x003c, 0x5000001f },
.{ 0x004c, 0x00560001 },
.{ 0x02f8, 0x000000ff },
.{ 0x0014, 0x00005bc7 },
.{ 0x007c, 0x10000007 },
.{ 0x0040, 0x30000002 },
.{ 0x0044, 0x00310031 },
.{ 0x0054, 0x00310031 },
.{ 0x0090, 0x1308703e },
.{ 0x0098, 0x0000ffff },
.{ 0x009c, 0xffffffff },
.{ 0x0080, 0x00010008 },
display_malloc: size=2330
.{ 0x000c, 0x00000000 },
.{ 0x00b0, 0x12000021 },
.{ 0x00b4, 0x01000031 },
.{ 0x00b8, 0x07000001 },
.{ 0x00bc, 0x14000011 },
.{ 0x0018, 0x0011000a },
.{ 0x001c, 0x05cd05a0 },
.{ 0x00c0, 0x09004a19 },
.{ 0x00c4, 0x50b40000 },
.{ 0x00c8, 0x35005419 },
.{ 0x00cc, 0x757a0000 },
.{ 0x00d0, 0x09004a19 },
.{ 0x00d4, 0x50b40000 },
.{ 0x00e0, 0x0c091a19 },
.{ 0x00e4, 0x72bd0000 },
.{ 0x00e8, 0x1a000019 },
.{ 0x00ec, 0xffff0000 },
};

struct reg_inst dsi_panel_init_seq[] = {
mipi_dsi_dcs_write: long len=4
b9 f1 12 83 
.{ 0x0300, 0x2c000439 },
header: 2c000439
display_zalloc: size=10
.{ 0x0304, 0x8312f1b9 },
.{ 0x0308, 0x00005d84 },
payload[0]: 8312f1b9
payload[1]: 00005d84
.{ 0x0200, 0x00000009 },
len: 9
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=28
ba 33 81 05 f9 0e 0e 20 
00 00 00 00 00 00 00 44 
25 00 91 0a 00 00 02 4f 
11 00 00 37 
.{ 0x0300, 0x2f001c39 },
header: 2f001c39
display_zalloc: size=34
.{ 0x0304, 0x058133ba },
.{ 0x0308, 0x200e0ef9 },
.{ 0x030c, 0x00000000 },
.{ 0x0310, 0x44000000 },
.{ 0x0314, 0x0a910025 },
.{ 0x0318, 0x4f020000 },
.{ 0x031c, 0x37000011 },
.{ 0x0320, 0x0000e22c },
payload[0]: 058133ba
payload[1]: 200e0ef9
payload[2]: 00000000
payload[3]: 44000000
payload[4]: 0a910025
payload[5]: 4f020000
payload[6]: 37000011
payload[7]: 0000e22c
.{ 0x0200, 0x00000021 },
len: 33
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=5
b8 25 22 20 03 
.{ 0x0300, 0x36000539 },
header: 36000539
display_zalloc: size=11
.{ 0x0304, 0x202225b8 },
.{ 0x0308, 0x00720303 },
payload[0]: 202225b8
payload[1]: 00720303
.{ 0x0200, 0x0000000a },
len: 10
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=11
b3 10 10 05 05 03 ff 00 
00 00 00 
.{ 0x0300, 0x2c000b39 },
header: 2c000b39
display_zalloc: size=17
.{ 0x0304, 0x051010b3 },
.{ 0x0308, 0x00ff0305 },
.{ 0x030c, 0x6f000000 },
.{ 0x0310, 0x000000bc },
payload[0]: 051010b3
payload[1]: 00ff0305
payload[2]: 6f000000
payload[3]: 000000bc
.{ 0x0200, 0x00000010 },
len: 16
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=10
c0 73 73 50 50 00 c0 08 
70 00 
.{ 0x0300, 0x36000a39 },
header: 36000a39
display_zalloc: size=16
.{ 0x0304, 0x507373c0 },
.{ 0x0308, 0x08c00050 },
.{ 0x030c, 0x6a1b0070 },
payload[0]: 507373c0
payload[1]: 08c00050
payload[2]: 6a1b0070
.{ 0x0200, 0x0000000f },
len: 15
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: short len=2
bc 4e 
.{ 0x0300, 0x354ebc15 },
header: 354ebc15
.{ 0x0200, 0x00000003 },
len: 3
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: short len=2
cc 0b 
.{ 0x0300, 0x220bcc15 },
header: 220bcc15
.{ 0x0200, 0x00000003 },
len: 3
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: short len=2
b4 80 
.{ 0x0300, 0x2280b415 },
header: 2280b415
.{ 0x0200, 0x00000003 },
len: 3
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=4
b2 f0 12 f0 
.{ 0x0300, 0x2c000439 },
header: 2c000439
display_zalloc: size=10
.{ 0x0304, 0xf012f0b2 },
.{ 0x0308, 0x00008651 },
payload[0]: f012f0b2
payload[1]: 00008651
.{ 0x0200, 0x00000009 },
len: 9
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=15
e3 00 00 0b 0b 10 10 00 
00 00 00 ff 00 c0 10 
.{ 0x0300, 0x0f000f39 },
header: 0f000f39
display_zalloc: size=21
.{ 0x0304, 0x0b0000e3 },
.{ 0x0308, 0x0010100b },
.{ 0x030c, 0xff000000 },
.{ 0x0310, 0x3610c000 },
.{ 0x0314, 0x0000000f },
payload[0]: 0b0000e3
payload[1]: 0010100b
payload[2]: ff000000
payload[3]: 3610c000
payload[4]: 0000000f
.{ 0x0200, 0x00000014 },
len: 20
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=6
c6 01 00 ff ff 00 
.{ 0x0300, 0x30000639 },
header: 30000639
display_zalloc: size=12
.{ 0x0304, 0xff0001c6 },
.{ 0x0308, 0x258e00ff },
payload[0]: ff0001c6
payload[1]: 258e00ff
.{ 0x0200, 0x0000000b },
len: 11
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=13
c1 74 00 32 32 77 f1 ff 
ff cc cc 77 77 
.{ 0x0300, 0x13000d39 },
header: 13000d39
display_zalloc: size=19
.{ 0x0304, 0x320074c1 },
.{ 0x0308, 0xfff17732 },
.{ 0x030c, 0x77ccccff },
.{ 0x0310, 0x00e46977 },
payload[0]: 320074c1
payload[1]: fff17732
payload[2]: 77ccccff
payload[3]: 00e46977
.{ 0x0200, 0x00000012 },
len: 18
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=3
b5 07 07 
.{ 0x0300, 0x09000339 },
header: 09000339
display_zalloc: size=9
.{ 0x0304, 0x7b0707b5 },
.{ 0x0308, 0x000000b3 },
payload[0]: 7b0707b5
payload[1]: 000000b3
.{ 0x0200, 0x00000008 },
len: 8
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=3
b6 2c 2c 
.{ 0x0300, 0x09000339 },
header: 09000339
display_zalloc: size=9
.{ 0x0304, 0x552c2cb6 },
.{ 0x0308, 0x00000004 },
payload[0]: 552c2cb6
payload[1]: 00000004
.{ 0x0200, 0x00000008 },
len: 8
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=4
bf 02 11 00 
.{ 0x0300, 0x2c000439 },
header: 2c000439
display_zalloc: size=10
.{ 0x0304, 0x001102bf },
.{ 0x0308, 0x0000e9b5 },
payload[0]: 001102bf
payload[1]: 0000e9b5
.{ 0x0200, 0x00000009 },
len: 9
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=64
e9 82 10 06 05 a2 0a a5 
12 31 23 37 83 04 bc 27 
38 0c 00 03 00 00 00 0c 
00 03 00 00 00 75 75 31 
88 88 88 88 88 88 13 88 
64 64 20 88 88 88 88 88 
88 02 88 00 00 00 00 00 
00 00 00 00 00 00 00 00 

.{ 0x0300, 0x25004039 },
header: 25004039
display_zalloc: size=70
.{ 0x0304, 0x061082e9 },
.{ 0x0308, 0xa50aa205 },
.{ 0x030c, 0x37233112 },
.{ 0x0310, 0x27bc0483 },
.{ 0x0314, 0x03000c38 },
.{ 0x0318, 0x0c000000 },
.{ 0x031c, 0x00000300 },
.{ 0x0320, 0x31757500 },
.{ 0x0324, 0x88888888 },
.{ 0x0328, 0x88138888 },
.{ 0x032c, 0x88206464 },
.{ 0x0330, 0x88888888 },
.{ 0x0334, 0x00880288 },
.{ 0x0338, 0x00000000 },
.{ 0x033c, 0x00000000 },
.{ 0x0340, 0x00000000 },
.{ 0x0344, 0x00000365 },
payload[0]: 061082e9
payload[1]: a50aa205
payload[2]: 37233112
payload[3]: 27bc0483
payload[4]: 03000c38
payload[5]: 0c000000
payload[6]: 00000300
payload[7]: 31757500
payload[8]: 88888888
payload[9]: 88138888
payload[10]: 88206464
payload[11]: 88888888
payload[12]: 00880288
payload[13]: 00000000
payload[14]: 00000000
payload[15]: 00000000
payload[16]: 00000365
.{ 0x0200, 0x00000045 },
len: 69
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=62
ea 02 21 00 00 00 00 00 
00 00 00 00 00 02 46 02 
88 88 88 88 88 88 64 88 
13 57 13 88 88 88 88 88 
88 75 88 23 14 00 00 02 
00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 03 
0a a5 00 00 00 00 
.{ 0x0300, 0x1a003e39 },
header: 1a003e39
display_zalloc: size=68
.{ 0x0304, 0x002102ea },
.{ 0x0308, 0x00000000 },
.{ 0x030c, 0x00000000 },
.{ 0x0310, 0x02460200 },
.{ 0x0314, 0x88888888 },
.{ 0x0318, 0x88648888 },
.{ 0x031c, 0x88135713 },
.{ 0x0320, 0x88888888 },
.{ 0x0324, 0x23887588 },
.{ 0x0328, 0x02000014 },
.{ 0x032c, 0x00000000 },
.{ 0x0330, 0x00000000 },
.{ 0x0334, 0x00000000 },
.{ 0x0338, 0x03000000 },
.{ 0x033c, 0x0000a50a },
.{ 0x0340, 0x1b240000 },
payload[0]: 002102ea
payload[1]: 00000000
payload[2]: 00000000
payload[3]: 02460200
payload[4]: 88888888
payload[5]: 88648888
payload[6]: 88135713
payload[7]: 88888888
payload[8]: 23887588
payload[9]: 02000014
payload[10]: 00000000
payload[11]: 00000000
payload[12]: 00000000
payload[13]: 03000000
payload[14]: 0000a50a
payload[15]: 1b240000
.{ 0x0200, 0x00000043 },
len: 67
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: long len=35
e0 00 09 0d 23 27 3c 41 
35 07 0d 0e 12 13 10 12 
12 18 00 09 0d 23 27 3c 
41 35 07 0d 0e 12 13 10 
12 12 18 
.{ 0x0300, 0x20002339 },
header: 20002339
display_zalloc: size=41
.{ 0x0304, 0x0d0900e0 },
.{ 0x0308, 0x413c2723 },
.{ 0x030c, 0x0e0d0735 },
.{ 0x0310, 0x12101312 },
.{ 0x0314, 0x09001812 },
.{ 0x0318, 0x3c27230d },
.{ 0x031c, 0x0d073541 },
.{ 0x0320, 0x1013120e },
.{ 0x0324, 0x93181212 },
.{ 0x0328, 0x000000bf },
payload[0]: 0d0900e0
payload[1]: 413c2723
payload[2]: 0e0d0735
payload[3]: 12101312
payload[4]: 09001812
payload[5]: 3c27230d
payload[6]: 0d073541
payload[7]: 1013120e
payload[8]: 93181212
payload[9]: 000000bf
.{ 0x0200, 0x00000028 },
len: 40
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: short len=1
11 
.{ 0x0300, 0x36001105 },
header: 36001105
.{ 0x0200, 0x00000003 },
len: 3
.{ MAGIC_COMMIT, 0 },
mipi_dsi_dcs_write: short len=1
29 
.{ 0x0300, 0x1c002905 },
header: 1c002905
.{ 0x0200, 0x00000003 },
len: 3
.{ MAGIC_COMMIT, 0 },
};
.{ 0x0048, 0x00000f02 },
.{ MAGIC_COMMIT, 0 },
dsi_update_bits: 0x01ca0020 : 0000001f -> (00000010) 00000000
.{ 0x0048, 0x63f07006 },
.{ MAGIC_COMMIT, 0 },
HELLO ZIG ON PINEPHONE!
mipi_dsi_dcs_write: channel=0, cmd=0x39, len=64
composeLongPacket: channel=0, cmd=0x39, len=64
computeCrc: len=64, crc=0x365
e9 82 10 06 05 a2 0a a5 
12 31 23 37 83 04 bc 27 
38 0c 00 03 00 00 00 0c 
00 03 00 00 00 75 75 31 
88 88 88 88 88 88 13 88 
64 64 20 88 88 88 88 88 
88 02 88 00 00 00 00 00 
00 00 00 00 00 00 00 00 

packet: len=70
39 40 00 25 e9 82 10 06 
05 a2 0a a5 12 31 23 37 
83 04 bc 27 38 0c 00 03 
00 00 00 0c 00 03 00 00 
00 75 75 31 88 88 88 88 
88 88 13 88 64 64 20 88 
88 88 88 88 88 02 88 00 
00 00 00 00 00 00 00 00 
00 00 00 00 65 03 
modifyreg32: addr=0x300, val=0x25004039
modifyreg32: addr=0x304, val=0x061082e9
modifyreg32: addr=0x308, val=0xa50aa205
modifyreg32: addr=0x30c, val=0x37233112
modifyreg32: addr=0x310, val=0x27bc0483
modifyreg32: addr=0x314, val=0x03000c38
modifyreg32: addr=0x318, val=0x0c000000
modifyreg32: addr=0x31c, val=0x00000300
modifyreg32: addr=0x320, val=0x31757500
modifyreg32: addr=0x324, val=0x88888888
modifyreg32: addr=0x328, val=0x88138888
modifyreg32: addr=0x32c, val=0x88206464
modifyreg32: addr=0x330, val=0x88888888
modifyreg32: addr=0x334, val=0x00880288
modifyreg32: addr=0x338, val=0x00000000
modifyreg32: addr=0x33c, val=0x00000000
modifyreg32: addr=0x340, val=0x00000000
modifyreg32: addr=0x344, val=0x00000365
modifyreg32: addr=0x200, val=0x00000045
nsh> 
nsh> 
```

## Testing p-boot Driver for MIPI DSI (without logging)

Testing [PinePhone p-boot Display Code](https://gist.github.com/lupyuen/ee3adf76e76881609845d0ab0f768a95) without logging...

```text
nsh> hello
task_spawn: name=hello entry=0x4009ce04 file_actions=0x404ea580 attr=0x404ea588 argv=0x404ea6d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
ABHello, World!!
ph_cfg1_reg=0x7177
ph_data_reg=0x400
pd_cfg2_reg=0x77711177
pd_data_reg=0x1c0000
struct reg_inst dsi_init_seq[] = {
{ 0x0000, 0x00000001 },
{ 0x0010, 0x00030000 },
{ 0x0060, 0x0000000a },
{ 0x0078, 0x00000000 },
{ 0x0020, 0x0000001f },
{ 0x0024, 0x10000001 },
{ 0x0028, 0x20000010 },
{ 0x002c, 0x2000000f },
{ 0x0030, 0x30100001 },
{ 0x0034, 0x40000010 },
{ 0x0038, 0x0000000f },
{ 0x003c, 0x5000001f },
{ 0x004c, 0x00560001 },
{ 0x02f8, 0x000000ff },
{ 0x0014, 0x00005bc7 },
{ 0x007c, 0x10000007 },
{ 0x0040, 0x30000002 },
{ 0x0044, 0x00310031 },
{ 0x0054, 0x00310031 },
{ 0x0090, 0x1308703e },
{ 0x0098, 0x0000ffff },
{ 0x009c, 0xffffffff },
{ 0x0080, 0x00010008 },
display_malloc: size=2330
{ 0x000c, 0x00000000 },
{ 0x00b0, 0x12000021 },
{ 0x00b4, 0x01000031 },
{ 0x00b8, 0x07000001 },
{ 0x00bc, 0x14000011 },
{ 0x0018, 0x0011000a },
{ 0x001c, 0x05cd05a0 },
{ 0x00c0, 0x09004a19 },
{ 0x00c4, 0x50b40000 },
{ 0x00c8, 0x35005419 },
{ 0x00cc, 0x757a0000 },
{ 0x00d0, 0x09004a19 },
{ 0x00d4, 0x50b40000 },
{ 0x00e0, 0x0c091a19 },
{ 0x00e4, 0x72bd0000 },
{ 0x00e8, 0x1a000019 },
{ 0x00ec, 0xffff0000 },
};

struct reg_inst dsi_panel_init_seq[] = {
{ 0x0300, 0x2c000439 },
display_zalloc: size=10
{ 0x0304, 0x8312f1b9 },
{ 0x0308, 0x00005d84 },
{ 0x0200, 0x00000009 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x2f001c39 },
display_zalloc: size=34
{ 0x0304, 0x058133ba },
{ 0x0308, 0x200e0ef9 },
{ 0x030c, 0x00000000 },
{ 0x0310, 0x44000000 },
{ 0x0314, 0x0a910025 },
{ 0x0318, 0x4f020000 },
{ 0x031c, 0x37000011 },
{ 0x0320, 0x0000e22c },
{ 0x0200, 0x00000021 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x36000539 },
display_zalloc: size=11
{ 0x0304, 0x202225b8 },
{ 0x0308, 0x00720303 },
{ 0x0200, 0x0000000a },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x2c000b39 },
display_zalloc: size=17
{ 0x0304, 0x051010b3 },
{ 0x0308, 0x00ff0305 },
{ 0x030c, 0x6f000000 },
{ 0x0310, 0x000000bc },
{ 0x0200, 0x00000010 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x36000a39 },
display_zalloc: size=16
{ 0x0304, 0x507373c0 },
{ 0x0308, 0x08c00050 },
{ 0x030c, 0x6a1b0070 },
{ 0x0200, 0x0000000f },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x354ebc15 },
{ 0x0200, 0x00000003 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x220bcc15 },
{ 0x0200, 0x00000003 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x2280b415 },
{ 0x0200, 0x00000003 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x2c000439 },
display_zalloc: size=10
{ 0x0304, 0xf012f0b2 },
{ 0x0308, 0x00008651 },
{ 0x0200, 0x00000009 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x0f000f39 },
display_zalloc: size=21
{ 0x0304, 0x0b0000e3 },
{ 0x0308, 0x0010100b },
{ 0x030c, 0xff000000 },
{ 0x0310, 0x3610c000 },
{ 0x0314, 0x0000000f },
{ 0x0200, 0x00000014 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x30000639 },
display_zalloc: size=12
{ 0x0304, 0xff0001c6 },
{ 0x0308, 0x258e00ff },
{ 0x0200, 0x0000000b },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x13000d39 },
display_zalloc: size=19
{ 0x0304, 0x320074c1 },
{ 0x0308, 0xfff17732 },
{ 0x030c, 0x77ccccff },
{ 0x0310, 0x00e46977 },
{ 0x0200, 0x00000012 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x09000339 },
display_zalloc: size=9
{ 0x0304, 0x7b0707b5 },
{ 0x0308, 0x000000b3 },
{ 0x0200, 0x00000008 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x09000339 },
display_zalloc: size=9
{ 0x0304, 0x552c2cb6 },
{ 0x0308, 0x00000004 },
{ 0x0200, 0x00000008 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x2c000439 },
display_zalloc: size=10
{ 0x0304, 0x001102bf },
{ 0x0308, 0x0000e9b5 },
{ 0x0200, 0x00000009 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x25004039 },
display_zalloc: size=70
{ 0x0304, 0x061082e9 },
{ 0x0308, 0xa50aa205 },
{ 0x030c, 0x37233112 },
{ 0x0310, 0x27bc0483 },
{ 0x0314, 0x03000c38 },
{ 0x0318, 0x0c000000 },
{ 0x031c, 0x00000300 },
{ 0x0320, 0x31757500 },
{ 0x0324, 0x88888888 },
{ 0x0328, 0x88138888 },
{ 0x032c, 0x88206464 },
{ 0x0330, 0x88888888 },
{ 0x0334, 0x00880288 },
{ 0x0338, 0x00000000 },
{ 0x033c, 0x00000000 },
{ 0x0340, 0x00000000 },
{ 0x0344, 0x00000365 },
{ 0x0200, 0x00000045 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x1a003e39 },
display_zalloc: size=68
{ 0x0304, 0x002102ea },
{ 0x0308, 0x00000000 },
{ 0x030c, 0x00000000 },
{ 0x0310, 0x02460200 },
{ 0x0314, 0x88888888 },
{ 0x0318, 0x88648888 },
{ 0x031c, 0x88135713 },
{ 0x0320, 0x88888888 },
{ 0x0324, 0x23887588 },
{ 0x0328, 0x02000014 },
{ 0x032c, 0x00000000 },
{ 0x0330, 0x00000000 },
{ 0x0334, 0x00000000 },
{ 0x0338, 0x03000000 },
{ 0x033c, 0x0000a50a },
{ 0x0340, 0x1b240000 },
{ 0x0200, 0x00000043 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x20002339 },
display_zalloc: size=41
{ 0x0304, 0x0d0900e0 },
{ 0x0308, 0x413c2723 },
{ 0x030c, 0x0e0d0735 },
{ 0x0310, 0x12101312 },
{ 0x0314, 0x09001812 },
{ 0x0318, 0x3c27230d },
{ 0x031c, 0x0d073541 },
{ 0x0320, 0x1013120e },
{ 0x0324, 0x93181212 },
{ 0x0328, 0x000000bf },
{ 0x0200, 0x00000028 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x36001105 },
{ 0x0200, 0x00000003 },
{ MAGIC_COMMIT, 0 },
{ 0x0300, 0x1c002905 },
{ 0x0200, 0x00000003 },
{ MAGIC_COMMIT, 0 },
};
{ 0x0048, 0x00000f02 },
{ MAGIC_COMMIT, 0 },
dsi_update_bits: 0x01ca0020 : 0000001f -> (00000010) 00000000
{ 0x0048, 0x63f07006 },
{ MAGIC_COMMIT, 0 },
nsh> 
```

## Testing Zig on PinePhone

```text
DRAM: 2048 MiB
Trying to boot from MMC1
NOTICE:  BL31: v2.2(release):v2.2-904-gf9ea3a629
NOTICE:  BL31: Built : 15:32:12, Apr  9 2020
NOTICE:  BL31: Detected Allwinner A64/H64/R18 SoC (1689)
NOTICE:  BL31: Found U-Boot DTB at 0x4064410, model: PinePhone
NOTICE:  PSCI: System suspend is unavailable


U-Boot 2020.07 (Nov 08 2020 - 00:15:12 +0100)

DRAM:  2 GiB
MMC:   Device 'mmc@1c11000': seq 1 is in use by 'mmc@1c10000'
mmc@1c0f000: 0, mmc@1c10000: 2, mmc@1c11000: 1
Loading Environment from FAT... *** Warning - bad CRC, using default environment

starting USB...
No working controllers found
Hit any key to stop autoboot:  0 
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
653 bytes read in 3 ms (211.9 KiB/s)
## Executing script at 4fc00000
gpio: pin 114 (gpio 114) value is 1
200596 bytes read in 12 ms (15.9 MiB/s)
Uncompressed size: 4624384 = 0x469000
36162 bytes read in 4 ms (8.6 MiB/s)
1078500 bytes read in 50 ms (20.6 MiB/s)
## Flattened Device Tree blob at 4fa00000
   Booting using the fdt blob at 0x4fa00000
   Loading Ramdisk to 49ef8000, end 49fff4e4 ... OK
   Loading Device Tree to 0000000049eec000, end 0000000049ef7d41 ... OK

Starting kernel ...

HELLO NUTTX ON PINEPHONE!
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x404e9000, heap_size=0x7b17000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
arm64_gic_initialize: GIC Version is 2
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
up_timer_initialize: _vector_table=0x400cc000
up_timer_initialize: Before writing: vbar_el1=0x4024c000
up_timer_initialize: After writing: vbar_el1=0x400cc000
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x400cc000 _einit: 0x400cc000 _stext: 0x40080000 _etext: 0x400cd000
nsh: sysinit: fopen failed: 2
nshn:x _msktfaarttf:s :C PcUo0m:m aBnedg innonti nfgo uInddl
e
 
L
oNoupt
t
Shell (NSH) NuttX-11.0.0-RC2
nsh> null
task_spawn: name=null entry=0x4009d340 file_actions=0x404ee580 attr=0x404ee588 argv=0x404ee6d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
HELLO ZIG ON PINEPHONE!
mipi_dsi_dcs_write: channel=0, cmd=29, len=0

!ZIG PANIC!
nuttx_mipi_dsi_dcs_write not implemented™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™
Stack Trace:
0x4009d7d4
0x4009d340
0x4009d2f4
0x4009d39c
0x4009d358
0x400852fc
nsh> 
nsh> 
```

## Testing GIC Version 2 on PinePhone

```text
HELLO NUTTX ON PINEPHONE!
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x400c4000, heap_size=0x7f3c000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x1c81000
arm64_gic_initialize: CONFIG_GICR_BASE=0x1c82000
arm64_gic_initialize: GIC Version is 2
up_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
up_timer_initialize: _vector_table=0x400a7000
up_timer_initialize: Before writing: vbar_el1=0x40227000
up_timer_initialize: After writing: vbar_el1=0x400a7000
uart_register: Registering /dev/console
uart_register: Registering /dev/ttyS0
work_start_highpri: Starting high-priority kernel worker thread(s)
nx_start_application: Starting init thread
lib_cxx_initialize: _sinit: 0x400a7000 _einit: 0x400a7000 _stext: 0x40080000 _etext: 0x400a8000
nsh: sysinit: fopen failed: 2
nshn:x _msktfaarttf:s :C PcUo0m:m aBnedg innonti nfgo uInddl
e
  
L
 oNoupt
t
 Shell (NSH) NuttX-10.3.0-RC2
nsh> uname -a
NuttX 10.3.0-RC2 fc909c6-dirty Sep  1 2022 17:05:44 arm64 qemu-a53
nsh> helo
nsh: helo: command not found
nsh> help
help usage:  help [-v] [<cmd>]

  .         cd        dmesg     help      mount     rmdir     true      xd        
  [         cp        echo      hexdump   mv        set       truncate  
  ?         cmp       exec      kill      printf    sleep     uname     
  basename  dirname   exit      ls        ps        source    umount    
  break     dd        false     mkdir     pwd       test      unset     
  cat       df        free      mkrd      rm        time      usleep    

Builtin Apps:
  getprime  hello     nsh       ostest    sh        
nsh> hello
task_spawn: name=hello entry=0x4009b1a0 file_actions=0x400c9580 attr=0x400c9588 argv=0x400c96d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
Hello, World!!
nsh> ls /dev
/dev:
 console
 null
 ram0
 ram2
 ttyS0
 zero
nsh> 
[7mReally kill this window [y/n][27m
nsh>
```

## Testing GIC Version 2 on QEMU

```text
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x402c4000, heap_size=0x7d3c000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: CONFIG_GICD_BASE=0x8000000
arm64_gic_initialize: CONFIG_GICR_BASE=0x8010000
arm64_gic_initialize: GIC Version is 2
EFGHup_timer_initialize: up_timer_initialize: cp15 timer(s) running at 62.50MHz, cycle 62500
up_timer_initialize: ARM_ARCH_TIMER_IRQ=27
up_timer_initialize: arm64_arch_timer_compare_isr=0x4029b2ac
up_timer_initialize: irq_unexpected_isr=0x402823ec
up_timer_initialize: g_irqvector[0].handler=0x402823ec
up_timer_initialize: g_irqvector[1].handler=0x402823ec
up_timer_initialize: g_irqvector[2].handler=0x402823ec
up_timer_initialize: g_irqvector[3].handler=0x402823ec
up_timer_initialize: g_irqvector[4].handler=0x402823ec
up_timer_initialize: g_irqvector[5].handler=0x402823ec
up_timer_initialize: g_irqvector[6].handler=0x402823ec
up_timer_initialize: g_irqvector[7].handler=0x402823ec
up_timer_initialize: g_irqvector[8].handler=0x402823ec
up_timer_initialize: g_irqvector[9].handler=0x402823ec
up_timer_initialize: g_irqvector[10].handler=0x402823ec
up_timer_initialize: g_irqvector[11].handler=0x402823ec
up_timer_initialize: g_irqvector[12].handler=0x402823ec
up_timer_initialize: g_irqvector[13].handler=0x402823ec
up_timer_initialize: g_irqvector[14].handler=0x402823ec
up_timer_initialize: g_irqvector[15].handler=0x402823ec
up_timer_initialize: g_irqvector[16].handler=0x402823ec
up_timer_initialize: g_irqvector[17].handler=0x402823ec
up_timer_initialize: g_irqvector[18].handler=0x402823ec
up_timer_initialize: g_irqvector[19].handler=0x402823ec
up_timer_initialize: g_irqvector[20].handler=0x402823ec
up_timer_initialize: g_irqvector[21].handler=0x402823ec
up_timer_initialize: g_irqvector[22].handler=0x402823ec
up_timer_initialize: g_irqvector[23].handler=0x402823ec
up_timer_initialize: g_irqvector[24].handler=0x402823ec
up_timer_initialize: g_irqvector[25].handler=0x402823ec
up_timer_initialize: g_irqvector[26].handler=0x402823ec
up_timer_initialize: g_irqvector[27].handler=0x4029b2ac
up_timer_initialize: g_irqvector[28].handler=0x402823ec
up_timer_initialize: g_irqvector[29].handler=0x402823ec
up_timer_initialize: g_irqvector[30].handler=0x402823ec
up_timer_initialize: g_irqvector[31].handler=0x402823ec
up_timer_initialize: g_irqvector[32].handler=0x402823ec
up_timer_initialize: g_irqvector[33].handler=0x402823ec
up_timer_initialize: g_irqvector[34].handler=0x402823ec
up_timer_initialize: g_irqvector[35].handler=0x402823ec
up_timer_initialize: g_irqvector[36].handler=0x402823ec
up_timer_initialize: g_irqvector[37].handler=0x402823ec
up_timer_initialize: g_irqvector[38].handler=0x402823ec
up_timer_initialize: g_irqvector[39].handler=0x402823ec
up_timer_initialize: g_irqvector[40].handler=0x402823ec
up_timer_initialize: g_irqvector[41].handler=0x402823ec
up_timer_initialize: g_irqvector[42].handler=0x402823ec
up_timer_initialize: g_irqvector[43].handler=0x402823ec
up_timer_initialize: g_irqvector[44].handler=0x402823ec
up_timer_initialize: g_irqvector[45].handler=0x402823ec
up_timer_initialize: g_irqvector[46].handler=0x402823ec
up_timer_initialize: g_irqvector[47].handler=0x402823ec
up_timer_initialize: g_irqvector[48].handler=0x402823ec
up_timer_initialize: g_irqvector[49].handler=0x402823ec
up_timer_initialize: g_irqvector[50].handler=0x402823ec
up_timer_initialize: g_irqvector[51].handler=0x402823ec
up_timer_initialize: g_irqvector[52].handler=0x402823ec
up_timer_initialize: g_irqvector[53].handler=0x402823ec
up_timer_initialize: g_irqvector[54].handler=0x402823ec
up_timer_initialize: g_irqvector[55].handler=0x402823ec
up_timer_initialize: g_irqvector[56].handler=0x402823ec
up_timer_initialize: g_irqvector[57].handler=0x402823ec
up_timer_initialize: g_irqvector[58].handler=0x402823ec
up_timer_initialize: g_irqvector[59].handler=0x402823ec
up_timer_initialize: g_irqvector[60].handler=0x402823ec
up_timer_initialize: g_irqvector[61].handler=0x402823ec
up_timer_initialize: g_irqvector[62].handler=0x402823ec
up_timer_initialize: g_irqvector[63].handler=0x402823ec
up_timer_initialize: g_irqvector[64].handler=0x402823ec
up_timer_initialize: g_irqvector[65].handler=0x402823ec
up_timer_initialize: g_irqvector[66].handler=0x402823ec
up_timer_initialize: g_irqvector[67].handler=0x402823ec
up_timer_initialize: g_irqvector[68].handler=0x402823ec
up_timer_initialize: g_irqvector[69].handler=0x402823ec
up_timer_initialize: g_irqvector[70].handler=0x402823ec
up_timer_initialize: g_irqvector[71].handler=0x402823ec
up_timer_initialize: g_irqvector[72].handler=0x402823ec
up_timer_initialize: g_irqvector[73].handler=0x402823ec
up_timer_initialize: g_irqvector[74].handler=0x402823ec
up_timer_initialize: g_irqvector[75].handler=0x402823ec
up_timer_initialize: g_irqvector[76].handler=0x402823ec
up_timer_initialize: g_irqvector[77].handler=0x402823ec
up_timer_initialize: g_irqvector[78].handler=0x402823ec
up_timer_initialize: g_irqvector[79].handler=0x402823ec
up_timer_initialize: g_irqvector[80].handler=0x402823ec
up_timer_initialize: g_irqvector[81].handler=0x402823ec
up_timer_initialize: g_irqvector[82].handler=0x402823ec
up_timer_initialize: g_irqvector[83].handler=0x402823ec
up_timer_initialize: g_irqvector[84].handler=0x402823ec
up_timer_initialize: g_irqvector[85].handler=0x402823ec
up_timer_initialize: g_irqvector[86].handler=0x402823ec
up_timer_initialize: g_irqvector[87].handler=0x402823ec
up_timer_initialize: g_irqvector[88].handler=0x402823ec
up_timer_initialize: g_irqvector[89].handler=0x402823ec
up_timer_initialize: g_irqvector[90].handler=0x402823ec
up_timer_initialize: g_irqvector[91].handler=0x402823ec
up_timer_initialize: g_irqvector[92].handler=0x402823ec
up_timer_initialize: g_irqvector[93].handler=0x402823ec
up_timer_initialize: g_irqvector[94].handler=0x402823ec
up_timer_initialize: g_irqvector[95].handler=0x402823ec
up_timer_initialize: g_irqvector[96].handler=0x402823ec
up_timer_initialize: g_irqvector[97].handler=0x402823ec
up_timer_initialize: g_irqvector[98].handler=0x402823ec
up_timer_initialize: g_irqvector[99].handler=0x402823ec
up_timer_initialize: g_irqvector[100].handler=0x402823ec
up_timer_initialize: g_irqvector[101].handler=0x402823ec
up_timer_initialize: g_irqvector[102].handler=0x402823ec
up_timer_initialize: g_irqvector[103].handler=0x402823ec
up_timer_initialize: g_irqvector[104].handler=0x402823ec
up_timer_initialize: g_irqvector[105].handler=0x402823ec
up_timer_initialize: g_irqvector[106].handler=0x402823ec
up_timer_initialize: g_irqvector[107].handler=0x402823ec
up_timer_initialize: g_irqvector[108].handler=0x402823ec
up_timer_initialize: g_irqvector[109].handler=0x402823ec
up_timer_initialize: g_irqvector[110].handler=0x402823ec
up_timer_initialize: g_irqvector[111].handler=0x402823ec
up_timer_initialize: g_irqvector[112].handler=0x402823ec
up_timer_initialize: g_irqvector[113].handler=0x402823ec
up_timer_initialize: g_irqvector[114].handler=0x402823ec
up_timer_initialize: g_irqvector[115].handler=0x402823ec
up_timer_initialize: g_irqvector[116].handler=0x402823ec
up_timer_initialize: g_irqvector[117].handler=0x402823ec
up_timer_initialize: g_irqvector[118].handler=0x402823ec
up_timer_initialize: g_irqvector[119].handler=0x402823ec
up_timer_initialize: g_irqvector[120].handler=0x402823ec
up_timer_initialize: g_irqvector[121].handler=0x402823ec
up_timer_initialize: g_irqvector[122].handler=0x402823ec
up_timer_initialize: g_irqvector[123].handler=0x402823ec
up_timer_initialize: g_irqvector[124].handler=0x402823ec
up_timer_initialize: g_irqvector[125].handler=0x402823ec
up_timer_initialize: g_irqvector[126].handler=0x402823ec
up_timer_initialize: g_irqvector[127].handler=0x402823ec
up_timer_initialize: g_irqvector[128].handler=0x402823ec
up_timer_initialize: g_irqvector[129].handler=0x402823ec
up_timer_initialize: g_irqvector[130].handler=0x402823ec
up_timer_initialize: g_irqvector[131].handler=0x402823ec
up_timer_initialize: g_irqvector[132].handler=0x402823ec
up_timer_initialize: g_irqvector[133].handler=0x402823ec
up_timer_initialize: g_irqvector[134].handler=0x402823ec
up_timer_initialize: g_irqvector[135].handler=0x402823ec
up_timer_initialize: g_irqvector[136].handler=0x402823ec
up_timer_initialize: g_irqvector[137].handler=0x402823ec
up_timer_initialize: g_irqvector[138].handler=0x402823ec
up_timer_initialize: g_irqvector[139].handler=0x402823ec
up_timer_initialize: g_irqvector[140].handler=0x402823ec
up_timer_initialize: g_irqvector[141].handler=0x402823ec
up_timer_initialize: g_irqvector[142].handler=0x402823ec
up_timer_initialize: g_irqvector[143].handler=0x402823ec
up_timer_initialize: g_irqvector[144].handler=0x402823ec
up_timer_initialize: g_irqvector[145].handler=0x402823ec
up_timer_initialize: g_irqvector[146].handler=0x402823ec
up_timer_initialize: g_irqvector[147].handler=0x402823ec
up_timer_initialize: g_irqvector[148].handler=0x402823ec
up_timer_initialize: g_irqvector[149].handler=0x402823ec
up_timer_initialize: g_irqvector[150].handler=0x402823ec
up_timer_initialize: g_irqvector[151].handler=0x402823ec
up_timer_initialize: g_irqvector[152].handler=0x402823ec
up_timer_initialize: g_irqvector[153].handler=0x402823ec
up_timer_initialize: g_irqvector[154].handler=0x402823ec
up_timer_initialize: g_irqvector[155].handler=0x402823ec
up_timer_initialize: g_irqvector[156].handler=0x402823ec
up_timer_initialize: g_irqvector[157].handler=0x402823ec
up_timer_initialize: g_irqvector[158].handler=0x402823ec
up_timer_initialize: g_irqvector[159].handler=0x402823ec
up_timer_initialize: g_irqvector[160].handler=0x402823ec
up_timer_initialize: g_irqvector[161].handler=0x402823ec
up_timer_initialize: g_irqvector[162].handler=0x402823ec
up_timer_initialize: g_irqvector[163].handler=0x402823ec
up_timer_initialize: g_irqvector[164].handler=0x402823ec
up_timer_initialize: g_irqvector[165].handler=0x402823ec
up_timer_initialize: g_irqvector[166].handler=0x402823ec
up_timer_initialize: g_irqvector[167].handler=0x402823ec
up_timer_initialize: g_irqvector[168].handler=0x402823ec
up_timer_initialize: g_irqvector[169].handler=0x402823ec
up_timer_initialize: g_irqvector[170].handler=0x402823ec
up_timer_initialize: g_irqvector[171].handler=0x402823ec
up_timer_initialize: g_irqvector[172].handler=0x402823ec
up_timer_initialize: g_irqvector[173].handler=0x402823ec
up_timer_initialize: g_irqvector[174].handler=0x402823ec
up_timer_initialize: g_irqvector[175].handler=0x402823ec
up_timer_initialize: g_irqvector[176].handler=0x402823ec
up_timer_initialize: g_irqvector[177].handler=0x402823ec
up_timer_initialize: g_irqvector[178].handler=0x402823ec
up_timer_initialize: g_irqvector[179].handler=0x402823ec
up_timer_initialize: g_irqvector[180].handler=0x402823ec
up_timer_initialize: g_irqvector[181].handler=0x402823ec
up_timer_initialize: g_irqvector[182].handler=0x402823ec
up_timer_initialize: g_irqvector[183].handler=0x402823ec
up_timer_initialize: g_irqvector[184].handler=0x402823ec
up_timer_initialize: g_irqvector[185].handler=0x402823ec
up_timer_initialize: g_irqvector[186].handler=0x402823ec
up_timer_initialize: g_irqvector[187].handler=0x402823ec
up_timer_initialize: g_irqvector[188].handler=0x402823ec
up_timer_initialize: g_irqvector[189].handler=0x402823ec
up_timer_initialize: g_irqvector[190].handler=0x402823ec
up_timer_initialize: g_irqvector[191].handler=0x402823ec
up_timer_initialize: g_irqvector[192].handler=0x402823ec
up_timer_initialize: g_irqvector[193].handler=0x402823ec
up_timer_initialize: g_irqvector[194].handler=0x402823ec
up_timer_initialize: g_irqvector[195].handler=0x402823ec
up_timer_initialize: g_irqvector[196].handler=0x402823ec
up_timer_initialize: g_irqvector[197].handler=0x402823ec
up_timer_initialize: g_irqvector[198].handler=0x402823ec
up_timer_initialize: g_irqvector[199].handler=0x402823ec
up_timer_initialize: g_irqvector[200].handler=0x402823ec
up_timer_initialize: g_irqvector[201].handler=0x402823ec
up_timer_initialize: g_irqvector[202].handler=0x402823ec
up_timer_initialize: g_irqvector[203].handler=0x402823ec
up_timer_initialize: g_irqvector[204].handler=0x402823ec
up_timer_initialize: g_irqvector[205].handler=0x402823ec
up_timer_initialize: g_irqvector[206].handler=0x402823ec
up_timer_initialize: g_irqvector[207].handler=0x402823ec
up_timer_initialize: g_irqvector[208].handler=0x402823ec
up_timer_initialize: g_irqvector[209].handler=0x402823ec
up_timer_initialize: g_irqvector[210].handler=0x402823ec
up_timer_initialize: g_irqvector[211].handler=0x402823ec
up_timer_initialize: g_irqvector[212].handler=0x402823ec
up_timer_initialize: g_irqvector[213].handler=0x402823ec
up_timer_initialize: g_irqvector[214].handler=0x402823ec
up_timer_initialize: g_irqvector[215].handler=0x402823ec
up_timer_initialize: g_irqvector[216].handler=0x402823ec
up_timer_initialize: g_irqvector[217].handler=0x402823ec
up_timer_initialize: g_irqvector[218].handler=0x402823ec
up_timer_initialize: g_irqvector[219].handler=0x402823ec
AKLMNOPBIJQRQRuart_register: Registering /dev/console
QRuart_register: Registering /dev/ttyS0
QRAKLMNOPBIJQRQRQRwork_start_highpri: Starting high-priority kernel worker thread(s)
QRQRQRnx_start_application: StartinQRg init thread
QRQRQRlib_cxx_initialize: _sinit: 0x402a7000 _einit: 0x402a700QR0 _stext: 0x40280000 _etext: 0x402a8000
QRQRQRQRQRQRQRQnsh: sysinit: fopen failed: 2
QRQRQRQRQRQRQRQRQRQRQRQRQnsh: mkfatfs: command not found
QRQRQRQRQ
QNuttShell (NSH) NuttX-10.3.0-RC2
Qnsh> QQRnx_start: CPU0: Beginning Idle Loop
QRQRQRQRRRRRRR
```

## Boot Files for Manjaro Phosh on PinePhone

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

# GIC Register Dump

Below is the dump of PinePhone's registers for [Arm Generic Interrupt Controller version 2](https://developer.arm.com/documentation/ihi0048/latest/)...

```text
HELLO NUTTX ON PINEPHONE!
- Ready to Boot CPU
- Boot from EL2
- Boot from EL1
- Boot to C runtime for OS Initialize
nx_start: Entry
up_allocate_heap: heap_start=0x0x400c4000, heap_size=0x7f3c000
arm64_gic_initialize: TODO: Init GIC for PinePhone
arm64_gic_initialize: GIC Version is 2
Earm_gic_dump: GIC: Entry arm_gic0_initialize NLINES=224
arm_gic_dump_cpu:   CPU Interface Registers:
arm_gic_dump_cpu:        ICR: 00000060    PMR: 000000f0    BPR: 00000003    IAR: 000003ff
arm_gic_dump_cpu:        RPR: 000000ff   HPIR: 000003ff   ABPR: 00000000
arm_gic_dump_cpu:       AIAR: 00000000  AHPIR: 00000000    IDR: 0202143b
arm_gic_dump_cpu:       APR1: 00000000   APR2: 00000000   APR3: 00000000   APR4: 00000000
arm_gic_dump_cpu:     NSAPR1: 00000000 NSAPR2: 00000000 NSAPR3: 00000000 NSAPR4: 00000000
arm_gic_dump_distributor:   Distributor Registers:
arm_gic_dump_distributor:        DCR: 00000000   ICTR: 0000fc66   IIDR: 0200143b
arm_gic_dump32:        ISR[01c81080]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        ISER/ICER[01c81100]
arm_gic_dumpregs:          0000ffff 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        ISPR/ICPR[01c81200]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        SAR/CAR[01c81300]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump4:        IPR[01c81400]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump4:        IPTR[01c81800]
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          00000000 00000000 01010100 01010101
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump16:        ICFR[01c81c00]
arm_gic_dumpregs:          aaaaaaaa 55540000 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 00000000 00000000
arm_gic_dump32:        PPSIR/SPISR[01c81d00]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        NSACR[01c81e00]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump8:        SCPR/SSPR[01c81f10]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump_distributor:        PIDR[01c81fd0]:
arm_gic_dump_distributor:          00000004 00000000 00000000 00000000
arm_gic_dump_distributor:          00000090 000000b4 0000002b
arm_gic_dump_distributor:        CIDR[01c81ff0]:
arm_gic_dump_distributor:          0000000d 000000f0 00000005 000000b1
arm_gic_dump: GIC: Exit arm_gic0_initialize NLINES=224
arm_gic_dump_cpu:   CPU Interface Registers:
arm_gic_dump_cpu:        ICR: 00000060    PMR: 000000f0    BPR: 00000003    IAR: 000003ff
arm_gic_dump_cpu:        RPR: 000000ff   HPIR: 000003ff   ABPR: 00000000
arm_gic_dump_cpu:       AIAR: 00000000  AHPIR: 00000000    IDR: 0202143b
arm_gic_dump_cpu:       APR1: 00000000   APR2: 00000000   APR3: 00000000   APR4: 00000000
arm_gic_dump_cpu:     NSAPR1: 00000000 NSAPR2: 00000000 NSAPR3: 00000000 NSAPR4: 00000000
arm_gic_dump_distributor:   Distributor Registers:
arm_gic_dump_distributor:        DCR: 00000000   ICTR: 0000fc66   IIDR: 0200143b
arm_gic_dump32:        ISR[01c81080]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        ISER/ICER[01c81100]
arm_gic_dumpregs:          0000ffff 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        ISPR/ICPR[01c81200]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        SAR/CAR[01c81300]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump4:        IPR[01c81400]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dump4:        IPTR[01c81800]
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          00000000 00000000 01010100 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dump16:        ICFR[01c81c00]
arm_gic_dumpregs:          aaaaaaaa 55540000 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 00000000 00000000
arm_gic_dump32:        PPSIR/SPISR[01c81d00]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        NSACR[01c81e00]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump8:        SCPR/SSPR[01c81f10]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump_distributor:        PIDR[01c81fd0]:
arm_gic_dump_distributor:          00000004 00000000 00000000 00000000
arm_gic_dump_distributor:          00000090 000000b4 0000002b
arm_gic_dump_distributor:        CIDR[01c81ff0]:
arm_gic_dump_distributor:          0000000d 000000f0 00000005 000000b1
FGarm_gic_dump: GIC: Entry arm_gic_initialize NLINES=224
arm_gic_dump_cpu:   CPU Interface Registers:
arm_gic_dump_cpu:        ICR: 00000060    PMR: 000000f0    BPR: 00000003    IAR: 000003ff
arm_gic_dump_cpu:        RPR: 000000ff   HPIR: 000003ff   ABPR: 00000000
arm_gic_dump_cpu:       AIAR: 00000000  AHPIR: 00000000    IDR: 0202143b
arm_gic_dump_cpu:       APR1: 00000000   APR2: 00000000   APR3: 00000000   APR4: 00000000
arm_gic_dump_cpu:     NSAPR1: 00000000 NSAPR2: 00000000 NSAPR3: 00000000 NSAPR4: 00000000
arm_gic_dump_distributor:   Distributor Registers:
arm_gic_dump_distributor:        DCR: 00000000   ICTR: 0000fc66   IIDR: 0200143b
arm_gic_dump32:        ISR[01c81080]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        ISER/ICER[01c81100]
arm_gic_dumpregs:          0000ffff 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        ISPR/ICPR[01c81200]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        SAR/CAR[01c81300]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump4:        IPR[01c81400]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dump4:        IPTR[01c81800]
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          00000000 00000000 01010100 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dump16:        ICFR[01c81c00]
arm_gic_dumpregs:          aaaaaaaa 55540000 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 00000000 00000000
arm_gic_dump32:        PPSIR/SPISR[01c81d00]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        NSACR[01c81e00]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump8:        SCPR/SSPR[01c81f10]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump_distributor:        PIDR[01c81fd0]:
arm_gic_dump_distributor:          00000004 00000000 00000000 00000000
arm_gic_dump_distributor:          00000090 000000b4 0000002b
arm_gic_dump_distributor:        CIDR[01c81ff0]:
arm_gic_dump_distributor:          0000000d 000000f0 00000005 000000b1
arm_gic_dump: GIC: Exit arm_gic_initialize NLINES=224
arm_gic_dump_cpu:   CPU Interface Registers:
arm_gic_dump_cpu:        ICR: 00000061    PMR: 000000f0    BPR: 00000007    IAR: 000003ff
arm_gic_dump_cpu:        RPR: 000000ff   HPIR: 000003ff   ABPR: 00000000
arm_gic_dump_cpu:       AIAR: 00000000  AHPIR: 00000000    IDR: 0202143b
arm_gic_dump_cpu:       APR1: 00000000   APR2: 00000000   APR3: 00000000   APR4: 00000000
arm_gic_dump_cpu:     NSAPR1: 00000000 NSAPR2: 00000000 NSAPR3: 00000000 NSAPR4: 00000000
arm_gic_dump_distributor:   Distributor Registers:
arm_gic_dump_distributor:        DCR: 00000001   ICTR: 0000fc66   IIDR: 0200143b
arm_gic_dump32:        ISR[01c81080]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        ISER/ICER[01c81100]
arm_gic_dumpregs:          0000ffff 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        ISPR/ICPR[01c81200]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        SAR/CAR[01c81300]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump4:        IPR[01c81400]
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          00000000 00000000 80000000 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dumpregs:          80808080 80808080 80808080 80808080
arm_gic_dump4:        IPTR[01c81800]
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          00000000 00000000 01010100 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dumpregs:          01010101 01010101 01010101 01010101
arm_gic_dump16:        ICFR[01c81c00]
arm_gic_dumpregs:          aaaaaaaa 55540000 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 55555555 55555555
arm_gic_dumpregs:          55555555 55555555 00000000 00000000
arm_gic_dump32:        PPSIR/SPISR[01c81d00]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump32:        NSACR[01c81e00]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump8:        SCPR/SSPR[01c81f10]
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dumpregs:          00000000 00000000 00000000 00000000
arm_gic_dump_distributor:        PIDR[01c81fd0]:
arm_gic_dump_distributor:          00000004 00000000 00000000 00000000
arm_gic_dump_distributor:          00000090 000000b4 0000002b
arm_gic_dump_distributor:        CIDR[01c81ff0]:
arm_gic_dump_distributor:          0000000d 000000f0 00000005 000000b1
Hup_timer_initialize: up_timer_initialize: cp15 timer(s) running at 24.00MHz, cycle 24000
AMarm_gic_dump: GIC: Exit up_prioritize_irq IRQ=27
arm_gic_dump_cpu:   CPU Interface Registers:
arm_gic_dump_cpu:        ICR: 00000061    PMR: 000000f0    BPR: 00000007    IAR: 000003ff
arm_gic_dump_cpu:        RPR: 000000ff   HPIR: 000003ff   ABPR: 00000000
arm_gic_dump_cpu:       AIAR: 00000000  AHPIR: 00000000    IDR: 0202143b
arm_gic_dump_cpu:       APR1: 00000000   APR2: 00000000   APR3: 00000000   APR4: 00000000
arm_gic_dump_cpu:     NSAPR1: 00000000 NSAPR2: 00000000 NSAPR3: 00000000 NSAPR4: 00000000
arm_gic_dump_distributor:   Distributor Registers:
arm_gic_dump_distributor:        DCR: 00000001   ICTR: 0000fc66   IIDR: 0200143b
arm_gic_dump_distributor:        ISR: 00000000   ISER: 0000ffff   ISPR: 00000000    SAR: 00000000
arm_gic_dump_distributor:        IPR: a0000000   IPTR: 01010100   ICFR: 55540000  SPISR: 00000000
arm_gic_dump_distributor:      NSACR: 00000000   SCPR: 00000000
arm_gic_dump_distributor:        PIDR[01c81fd0]:
arm_gic_dump_distributor:          00000004 00000000 00000000 00000000
arm_gic_dump_distributor:          00000090 000000b4 0000002b
arm_gic_dump_distributor:        CIDR[01c81ff0]:
arm_gic_dump_distributor:          0000000d 000000f0 00000005 000000b1
NOPBIarm_gic_du
```

