// Test PinePhone Display with Apache NuttX RTOS
// Called by https://github.com/lupyuen/incubator-nuttx-apps/blob/de2/examples/hello/hello_main.c
// Download the Modified p-boot Display Code `p-boot.4.zip` from...
// https://github.com/lupyuen/pinephone-nuttx/releases/tag/pboot4
// Extract into the `nuttx` folder and rename as `p-boot`

// From p-boot/build/build.ninja
#define DUMP_DSI_INIT 1
#define DSI_FULL_INIT 1 
#define DE2_RESIZE 1
#define __KERNEL__
#define __UBOOT__
#define __ARM__
#define __LINUX_ARM_ARCH__ 8 
#define CONFIG_ARM64
#define CONFIG_MACH_SUN50I
#define CONFIG_SUNXI_GEN_SUN6I
#define CONFIG_SPL_BUILD
#define CONFIG_CONS_INDEX 1
#define CONFIG_SUNXI_DE2
#define CONFIG_SUNXI_A64_TIMER_ERRATUM
#define CONFIG_SYS_HZ 1000
#define CONFIG_SUNXI_DRAM_DW
#define CONFIG_SUNXI_DRAM_LPDDR3_STOCK
#define CONFIG_SUNXI_DRAM_LPDDR3
#define CONFIG_DRAM_CLK 552
#define CONFIG_DRAM_ZQ 3881949
#define CONFIG_NR_DRAM_BANKS 1
#define CONFIG_SUNXI_DRAM_DW_32BIT
#define CONFIG_SUNXI_DRAM_MAX_SIZE 0xC0000000
#define CONFIG_DRAM_ODT_EN
#define CONFIG_SYS_CLK_FREQ 816000000
#define CONFIG_SYS_SDRAM_BASE 0x40000000
#define CONFIG_SUNXI_SRAM_ADDRESS 0x10000
#define CONFIG_SYS_CACHE_SHIFT_6
#define CONFIG_SYS_CACHELINE_SIZE 64
#define CONFIG_MMC2_BUS_WIDTH 8
#define CONFIG_MMC_SUNXI_HAS_NEW_MODE
#define CONFIG_ARCH_FIXUP_FDT_MEMORY
#define FDT_ASSUME_MASK 0xff 

#define u8  uint8_t
#define u16 uint16_t
#define u32 uint32_t
#define u64 uint64_t

#define __u8  uint8_t
#define __u16 uint16_t
#define __u32 uint32_t
#define __u64 uint64_t

#define __le16 __u16
#define __be16 __u16
#define __le32 __u32
#define __be32 __u32
#define __le64 __u64
#define __be64 __u64
#define __sum16 __u16
#define __wsum __u32

// sizeof(long)=8
// sizeof(long long)=8
#define BITS_PER_LONG 64
#define BITS_PER_LONG_LONG 64

#define noinline
#define __force
#define udelay(us) usleep(us)
//#define ARRAY_SIZE(array) (sizeof(array) / sizeof(array[0]))
//#define BIT(n) (0x1U << (n))

#define min(x, y) (				\
	(x) < (y) ? (x) : (y) )

#define max(x, y) (				\
	(x) > (y) ? (x) : (y) )

////TODO: Implement barriers. From p-boot/src/uboot/arch/arm/include/asm/io.h
////TODO: #define mb()		dsb()
////TODO: #define __iormb()	dmb()
////TODO: #define __iowmb()	dmb()
#define mb()
#define __iormb()
#define __iowmb()

////TODO
static ulong timer_get_boot_us(void) {
    usleep(1);
    static ulong microsecs = 0;
    return microsecs++;
}

////TODO
#define hang display_hang
#define malloc display_malloc
#define zalloc display_zalloc

static void display_hang(void) {
    puts("***display_hang"); 
    for(;;) {} 
}

////TODO
static void *display_malloc(size_t size) {
    printf("display_malloc: size=%ld\n", size);
    static uint8_t buf[2330];
    assert(size <= sizeof(buf));
    memset(buf, 0, sizeof(buf));
    return buf;
}

////TODO
void *display_zalloc(size_t size) {
    printf("display_zalloc: size=%ld\n", size);
    static uint8_t buf[1024];
    assert(size <= sizeof(buf));
    memset(buf, 0, sizeof(buf));
    return buf;
}

#include "../../p-boot/src/uboot/arch/arm/include/asm/arch-sunxi/clock.h"
#include "../../p-boot/src/uboot/arch/arm/include/asm/arch-sunxi/clock_sun6i.h"
#include "../../p-boot/src/uboot/arch/arm/include/asm/arch-sunxi/cpu_sun4i.h"
#include "../../p-boot/src/uboot/arch/arm/include/asm/arch-sunxi/display2.h"
#include "../../p-boot/src/uboot/arch/arm/include/asm/arch-sunxi/gpio.h"
#include "../../p-boot/src/uboot/arch/arm/include/asm/arch-sunxi/lcdc.h"
#include "../../p-boot/src/uboot/arch/arm/include/asm/arch-sunxi/pwm.h"
#include "../../p-boot/src/uboot/arch/arm/include/asm/io.h"
#include "../../p-boot/src/uboot/arch/arm/include/asm/posix_types.h"

#include "../../p-boot/src/uboot/include/linux/byteorder/little_endian.h"
#include "../../p-boot/src/uboot/include/linux/byteorder/generic.h"
#include "../../p-boot/src/uboot/include/linux/bitops.h"
#include "../../p-boot/src/uboot/include/linux/kernel.h"
#include "../../p-boot/src/uboot/include/linux/kconfig.h"

#include "../../p-boot/src/ccu.h"
#include "../../p-boot/src/display.h"
#include "../../p-boot/src/pmic.h"

#include "../../p-boot/src/uboot/arch/arm/mach-sunxi/pinmux.c"
#include "../../p-boot/src/uboot/drivers/gpio/sunxi_gpio.c"
#include "../../p-boot/src/uboot/arch/arm/mach-sunxi/clock_sun6i.c"

#include "../../p-boot/src/pmic.c"
#include "../../p-boot/src/display.c"

// Based on https://megous.com/git/p-boot/tree/src/dtest.c#n221
static void test_display(void) {
    // Allocate display
    static struct display disp;
    memset(&disp, 0, sizeof(disp));
    struct display* d = &disp;

    // Allocate framebuffer, init with pattern
    static uint8_t fb[4 * 720 * 1440];
    for (int i = 0; i < sizeof(fb); i++) {
        fb[i] = i;
    }

	// Init PMIC
	pmic_init();
	udelay(500);

	// Init Display
	display_init();
	udelay(160000);

	// Enable Backlight
	backlight_enable(90);

	// Init Display Plane 0
	d->planes[0].fb_start = (uintptr_t)fb;
	d->planes[0].fb_pitch = 720 * 4;
	d->planes[0].src_w = 720;
	d->planes[0].src_h = 1440;
	d->planes[0].dst_w = 720;
	d->planes[0].dst_h = 1440;

	// Init Display Plane 1
	d->planes[1].fb_start = (uintptr_t)fb;
	d->planes[1].fb_pitch = 600 * 4;
	d->planes[1].src_w = 600;
	d->planes[1].src_h = 600;
	d->planes[1].dst_w = 600;
	d->planes[1].dst_h = 600;
	d->planes[1].dst_x = 52;
	d->planes[1].dst_y = 52;

	// Init Display Plane 2
	d->planes[2].fb_start = (uintptr_t)fb;
	d->planes[2].fb_pitch = 720 * 4;
	d->planes[2].src_w = 720;
	d->planes[2].src_h = 1440;
	d->planes[2].dst_w = 720;
	d->planes[2].dst_h = 1440;
	d->planes[2].dst_x = 0;
	d->planes[2].dst_y = 0;
	d->planes[2].alpha = 255;

	// Render the Display Planes
	display_commit(d);
}
