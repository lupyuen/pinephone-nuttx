// Test Code for MIPI DSI and DPHY, called by https://github.com/lupyuen/pinephone-nuttx/blob/main/render.zig
// Add `#include "../../pinephone-nuttx/test/pinephone_userleds_inc.c"` into board_userled_all() at:
// https://github.com/lupyuen2/wip-pinephone-nuttx/blob/dsi/boards/arm64/a64/pinephone/src/pinephone_userleds.c#L179-L207
{
  int a64_mipi_dsi_enable(void);
  int a64_mipi_dphy_enable(void);
  int pinephone_panel_init(void);
  int a64_mipi_dsi_start(void);
  switch (ledset)
    {
      // Enable MIPI DSI Block
      case 3: _info("a64_mipi_dsi_enable\n"); a64_mipi_dsi_enable(); break;
      // Enable MIPI Display Physical Layer
      case 4: _info("a64_mipi_dphy_enable\n"); a64_mipi_dphy_enable(); break;
      // Init LCD Panel
      case 6: _info("pinephone_panel_init\n"); pinephone_panel_init(); break;
      // Start MIPI DSI HSC and HSD
      case 7: _info("a64_mipi_dsi_start\n"); a64_mipi_dsi_start(); break;
      default: break;
    }
}
