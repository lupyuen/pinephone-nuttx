// Test Code for Allwinner A64 Display Engine
// Add `#include "../../pinephone-nuttx/test/test_a64_de3.c"` to the end of a64_de_blender_init(), before `return OK` in this file:
// https://github.com/apache/nuttx/blob/master/arch/arm64/src/a64/a64_de.c

{
  DEBUGASSERT(color == 0xFF000000);
  DEBUGASSERT(BLD_BK_COLOR == 0x1101088);

  DEBUGASSERT(premultiply == 0);
  DEBUGASSERT(BLD_PREMUL_CTL == 0x1101084);
}
