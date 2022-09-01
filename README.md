![Apache NuttX RTOS on PinePhone](https://lupyuen.github.io/images/uboot-title.png)

# Apache NuttX RTOS on PinePhone

Read the articles...

-   ["Apache NuttX RTOS on Arm Cortex-A53: How it might run on PinePhone"](https://lupyuen.github.io/articles/arm)

-   ["PinePhone boots Apache NuttX RTOS"](https://lupyuen.github.io/articles/uboot)

-   ["NuttX RTOS on PinePhone: Fixing the Interrupts"](https://lupyuen.github.io/articles/interrupt)

[Apache NuttX RTOS](https://nuttx.apache.org/docs/latest/) now runs on Arm Cortex-A53 with Multi-Core SMP...

-   [nuttx/boards/arm64/qemu/qemu-a53](https://github.com/apache/incubator-nuttx/tree/master/boards/arm64/qemu/qemu-a53)

PinePhone is based on [Allwinner A64 SoC](https://linux-sunxi.org/A64) with 4 Cores of Arm Cortex-A53...

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

# NuttX Boot Log

This is how we build NuttX for PinePhone...

```bash
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

## Copy compressed NuttX Binary Image to Jumpdrive microSD
## https://lupyuen.github.io/articles/uboot#pinephone-jumpdrive
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
eshn:x _msktfaarttf:s :C PcUo0m:m aBnedg innonti nfgo uInddl
L
SNoutpt
 hell (NSH) NuttX-10.3.0-RC2
nsh> 
```

The output is slightly garbled, the UART Driver needs fixing.

NuttX Shell won't work until we implement UART Input in the UART Driver.

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

See below for the GIC Register Dump.

Let's talk about NuttX's System Timer, which depends on the GIC...

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

This is how we copied the PinePhone GIC v2 Source Files into NuttX Arm64 for testing...

```bash
cp ~/PinePhone/nuttx/nuttx/arch/arm64/src/common/arm64_gicv3.c      ~/gicv2/nuttx/nuttx/arch/arm64/src/common/arm64_gicv3.c
cp ~/PinePhone/nuttx/nuttx/arch/arm/src/armv7-a/arm_gicv2.c         ~/gicv2/nuttx/nuttx/arch/arm/src/armv7-a/arm_gicv2.c
cp ~/PinePhone/nuttx/nuttx/arch/arm/src/armv7-a/gic.h               ~/gicv2/nuttx/nuttx/arch/arm/src/armv7-a/gic.h
cp ~/PinePhone/nuttx/nuttx/arch/arm/src/armv7-a/arm_gicv2_dump.c    ~/gicv2/nuttx/nuttx/arch/arm/src/armv7-a/arm_gicv2_dump.c
cp ~/PinePhone/nuttx/nuttx/arch/arm64/src/common/arm64_arch_timer.c ~/gicv2/nuttx/nuttx/arch/arm64/src/common/arm64_arch_timer.c
cp ~/PinePhone/nuttx/run.sh             ~/gicv2/nuttx/run.sh
cp ~/PinePhone/nuttx/.vscode/tasks.json ~/gicv2/nuttx/.vscode/tasks.json
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

TODO: sinfo (syslog) works, but printf (puts) doesn't! Must implement UART Transmit Interrupts

https://github.com/lupyuen/incubator-nuttx-apps/blob/pinephone/system/nsh/nsh_main.c#L88-L102

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

`main2` never appears in the output because `qemu_pl011_txint` is unimplemented...

```text
nsh_main: ****main
HH: qemu_pl011_txint
nsh_main: ****main3
```

This is the sequence of calls to `qemu_pl011_attach`, `qemu_pl011_rxint` and `qemu_pl011_txint`...

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

TODO: UART Interrupts (Page 565)

UART Interrupt Enable Register:

```text
Offset: 0x0004 
Register Name: UART_IER
Bit R/W Default/Hex Description

7 R/W
PTIME
Programmable THRE Interrupt Mode Enable
This is used to enable/disable the generation of THRE Interrupt.
0: Disable
1: Enable

2 R/W 0
ELSI
Enable Receiver Line Status Interrupt
This is used to enable/disable the generation of Receiver Line Status Interrupt. This is the highest priority interrupt.
0: Disable
1: Enable

1 R/W 0
ETBEI
Enable Transmit Holding Register Empty Interrupt
This is used to enable/disable the generation of Transmitter Holding Register Empty Interrupt. This is the third highest priority interrupt.
0: Disable
1: Enable

0 R/W 0
ERBFI
Enable Received Data Available Interrupt
This is used to enable/disable the generation of Received Data Available Interrupt and the Character Timeout Interrupt (if in FIFO mode and FIFOs enabled). These are the second highest priority interrupts.
0: Disable
1: Enable
```

UART Interrupt Identity Register:

```text
Offset: 0x0008 
Register Name: UART_IIR
Bit R/W Default/Hex Description

7:6 R 0
FEFLAG
FIFOs Enable Flag
This is used to indicate whether the FIFOs are enabled or disabled.
00: Disable
11: Enable

3:0 R 0x1
IID
Interrupt ID
This indicates the highest priority pending interrupt which can be one of
the following types:
0000: modem status
0001: no interrupt pending
0010: THR empty
0100: received data available
0110: receiver line status
0111: busy detect
1100: character timeout
Bit 3 indicates an interrupt can only occur when the FIFOs are enabled and used to distinguish a Character Timeout condition interrupt.
```

Interrupts:

```text
Interrupt ID
Priority Level
Interrupt Type 
Interrupt Source 
Interrupt Reset

0110 Highest 
Receiver line status
Overrun/parity/framing errors or break interrupt

Reading UART Line Status Register

0100 Second 
Received data available
Receiver data available (non-FIFO mode or FIFOs disabled) or RCVR FIFO trigger level reached (FIFO mode and FIFOs enabled)

Reading UART Receiver Buffer Register (non-FIFO mode or FIFOs disabled) or the FIFO drops below the trigger level (FIFO mode and FIFOs enabled)

1100 Second 
Character timeout indication
No characters in or out of the RCVR FIFO during the last 4 character times and there is at least 1character in it during This time

Reading UART Receiver Buffer Register

0010 Third 
Transmit holding register empty
Transmitter holding register empty (Program THRE Mode disabled) or XMIT FIFO at or below threshold (Program THRE Mode enabled)

Reading UART Interrupt Identity Register (if source of interrupt); or, writing into THR (FIFOs or THRE Mode not selected or disabled) or XMIT FIFO above threshold (FIFOs and THRE Mode selected and enabled).
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

# TODO

PinePhone:

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
nsh> [Kuname -a
NuttX 10.3.0-RC2 fc909c6-dirty Sep  1 2022 17:05:44 arm64 qemu-a53
nsh> [Khelo
nsh: helo: command not found
nsh> [Khelp
help usage:  help [-v] [<cmd>]

  .         cd        dmesg     help      mount     rmdir     true      xd        
  [         cp        echo      hexdump   mv        set       truncate  
  ?         cmp       exec      kill      printf    sleep     uname     
  basename  dirname   exit      ls        ps        source    umount    
  break     dd        false     mkdir     pwd       test      unset     
  cat       df        free      mkrd      rm        time      usleep    

Builtin Apps:
  getprime  hello     nsh       ostest    sh        
nsh> [Khello
task_spawn: name=hello entry=0x4009b1a0 file_actions=0x400c9580 attr=0x400c9588 argv=0x400c96d0
spawn_execattrs: Setting policy=2 priority=100 for pid=3
Hello, World!!
nsh> [Kls /dev
/dev:
 console
 null
 ram0
 ram2
 ttyS0
 zero
nsh> [K
[7mReally kill this window [y/n][27m[K
nsh>
```

QEMU:

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
