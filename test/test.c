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

  _info("TODO: Turn on Display Backlight\n");

  _info("TODO: Init Timing Controller TCON0\n");
  
  _info("TODO: Init PMIC\n");

  // Enable MIPI DSI Block
  ret = a64_mipi_dsi_enable();
  assert(ret == OK);

  // Enable MIPI Display Physical Layer (DPHY)
  ret = a64_mipi_dphy_enable();
  assert(ret == OK);

  _info("TODO: Reset LCD Panel\n");

  // Initialise LCD Controller (ST7703)
  ret = pinephone_panel_init();
  assert(ret == OK);

  // Start MIPI DSI HSC and HSD
  ret = a64_mipi_dsi_start();
  assert(ret == OK);

  _info("TODO: Render Graphics with Display Engine\n");

  // Test MIPI DSI
  void mipi_dsi_test(void);
  mipi_dsi_test();
}

/// Modify the specified bits in a memory mapped register.
/// Based on https://github.com/apache/nuttx/blob/master/arch/arm64/src/common/arm64_arch.h#L473
void modreg32(
    uint32_t val,   // Bits to set, like (1 << bit)
    uint32_t mask,  // Bits to clear, like (1 << bit)
    unsigned long addr  // Address to modify
)
{
  _info("  *0x%lx: clear 0x%x, set 0x%x\n", addr, mask, val & mask);
  assert((val & mask) == val);
}

uint32_t getreg32(unsigned long addr)
{
  return 0;
}

void putreg32(uint32_t data, unsigned long addr)
{
  _info("  *0x%lx = 0x%x\n", addr, data);
}

#ifdef NOTUSED
void up_udelay(unsigned long microseconds)
{
  _info("  up_udelay %ld\n", microseconds);
}
#endif  // NOTUSED
