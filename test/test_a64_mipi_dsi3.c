// Test Code for Allwinner A64 MIPI DSI
// Add `#include "../../pinephone-nuttx/test/test_a64_mipi_dsi3.c"` to the end of a64_mipi_dsi_start() in this file:
// https://github.com/apache/nuttx/blob/master/arch/arm64/src/a64/a64_mipi_dsi.c

{
  DEBUGASSERT(DSI_INST_JUMP_SEL_REG == 0x1ca0048);
  DEBUGASSERT(DSI_BASIC_CTL0_REG == 0x1ca0010);
  DEBUGASSERT(INSTRU_EN == 0x1);

  DEBUGASSERT(DSI_INST_FUNC_REG(DSI_INST_ID_LP11) == 0x1ca0020);
  DEBUGASSERT(DSI_INST_FUNC_LANE_CEN == 0x10);

  DEBUGASSERT(DSI_INST_JUMP_SEL_REG == 0x1ca0048);
  DEBUGASSERT(DSI_BASIC_CTL0_REG == 0x1ca0010);
  DEBUGASSERT(INSTRU_EN == 0x1);
}
