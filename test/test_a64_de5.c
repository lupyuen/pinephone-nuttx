// Test Code for Allwinner A64 Display Engine
// Add `#include "../../pinephone-nuttx/test/test_a64_de5.c"` to the end of a64_de_enable(), before `return OK` in this file:
// https://github.com/apache/nuttx/blob/master/arch/arm64/src/a64/a64_de.c

{
  DEBUGASSERT(route == 0x321 || route == 1);
  DEBUGASSERT(BLD_CH_RTCTL == 0x1101080);

  DEBUGASSERT(fill == 0x701 || fill == 0x101);
  DEBUGASSERT(BLD_FILL_COLOR_CTL == 0x1101000);

  DEBUGASSERT(DOUBLE_BUFFER_RDY == 1);
  DEBUGASSERT(GLB_DBUFFER == 0x1100008);
}
