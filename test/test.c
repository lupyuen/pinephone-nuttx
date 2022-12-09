#include <nuttx/config.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <debug.h>

#include <nuttx/arch.h>
#include "arm64_arch.h"
#include "mipi_dsi.h"
#include "a64_mipi_dsi.h"
#include "a64_mipi_dphy.h"

/// MIPI DSI Virtual Channel
#define VIRTUAL_CHANNEL 0

int pinephone_panel_init(void);

int main()
{
  int ret;

  ginfo("TODO: Turn on Display Backlight\n");

  ginfo("TODO: Init Timing Controller TCON0\n");
  
  ginfo("TODO: Init PMIC\n");

  // Enable MIPI DSI Block
  ret = a64_mipi_dsi_enable();
  assert(ret == OK);

  // Enable MIPI Display Physical Layer (DPHY)
  ret = a64_mipi_dphy_enable();
  assert(ret == OK);

  ginfo("TODO: Reset LCD Panel\n");

  // Initialise LCD Controller (ST7703)
  ret = pinephone_panel_init();
  assert(ret == OK);

  // Start MIPI DSI HSC and HSD
  ret = a64_mipi_dsi_start();
  assert(ret == OK);

  ginfo("TODO: Render Graphics with Display Engine\n");

  // Test MIPI DSI
  void mipi_dsi_test(void);
  mipi_dsi_test();
}

void dump_buffer(const uint8_t *data, size_t len)
{
    char buf[8 * 3];
    memset(buf, ' ', sizeof(buf));
    buf[sizeof(buf) - 1] = 0;

	for (int i = 0; i < len; i++) {
        const int mod = i % 8;
        const int d1 = data[i] >> 4;
        const int d2 = data[i] & 0b1111;
        buf[mod * 3] = (d1 < 10) ? ('0' + d1) : ('a' + d1 - 10);
        buf[mod * 3 + 1] = (d2 < 10) ? ('0' + d2) : ('a' + d2 - 10);

        if ((i + 1) % 8 == 0 || i == len - 1) {
            ginfo("%s\n", buf);
            if (i == len - 1) { break; }

            memset(buf, ' ', sizeof(buf));
            buf[sizeof(buf) - 1] = 0;
        }
	}
}

/// Modify the specified bits in a memory mapped register.
/// Based on https://github.com/apache/nuttx/blob/master/arch/arm64/src/common/arm64_arch.h#L473
void modreg32(
    uint32_t val,   // Bits to set, like (1 << bit)
    uint32_t mask,  // Bits to clear, like (1 << bit)
    unsigned long addr  // Address to modify
)
{
  ginfo("  *0x%lx: clear 0x%x, set 0x%x\n", addr, mask, val & mask);
  assert((val & mask) == val);
}

uint32_t getreg32(unsigned long addr)
{
  return 0;
}

void putreg32(uint32_t data, unsigned long addr)
{
  ginfo("  *0x%lx = 0x%x\n", addr, data);
}

void up_mdelay(unsigned int milliseconds)
{
  ginfo("  up_mdelay %d ms\n", milliseconds);
}
