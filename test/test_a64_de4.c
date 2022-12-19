// Test Code for Allwinner A64 Display Engine
// Add `#include "../../pinephone-nuttx/test/test_a64_de4.c"` to the end of a64_de_ui_channel_init(), before `return OK` in this file:
// https://github.com/apache/nuttx/blob/master/arch/arm64/src/a64/a64_de.c

{
  DEBUGASSERT(OVL_UI_ATTR_CTL(channel) == 0x1103000 || OVL_UI_ATTR_CTL(channel) == 0x1104000 || OVL_UI_ATTR_CTL(channel) == 0x1105000);
  DEBUGASSERT(UIS_CTRL_REG(channel) == 0x1140000 || UIS_CTRL_REG(channel) == 0x1150000 || UIS_CTRL_REG(channel) == 0x1160000);
  DEBUGASSERT(attr == 0xFF000405 || attr == 0xFF000005 || attr == 0x7F000005);

  DEBUGASSERT(OVL_UI_TOP_LADD(channel) == 0x1103010 || OVL_UI_TOP_LADD(channel) == 0x1104010 || OVL_UI_TOP_LADD(channel) == 0x1105010);
  DEBUGASSERT(OVL_UI_PITCH(channel) == 0x110300C || OVL_UI_PITCH(channel) == 0x110400C || OVL_UI_PITCH(channel) == 0x110500C);
  DEBUGASSERT(OVL_UI_MBSIZE(channel) == 0x1103004 || OVL_UI_MBSIZE(channel) == 0x1104004 || OVL_UI_MBSIZE(channel) == 0x1105004);
  DEBUGASSERT(OVL_UI_SIZE(channel) == 0x1103088 || OVL_UI_SIZE(channel) == 0x1104088 || OVL_UI_SIZE(channel) == 0x1105088);
  DEBUGASSERT(OVL_UI_COOR(channel) == 0x1103008 || OVL_UI_COOR(channel) == 0x1104008 || OVL_UI_COOR(channel) == 0x1105008);

  DEBUGASSERT(BLD_SIZE == 0x110108C);
  DEBUGASSERT(GLB_SIZE == 0x110000C);

  DEBUGASSERT(BLD_CH_ISIZE(pipe) == 0x1101008 || BLD_CH_ISIZE(pipe) == 0x1101018 || BLD_CH_ISIZE(pipe) == 0x1101028);
  DEBUGASSERT(BLD_FILL_COLOR(pipe) == 0x1101004 || BLD_FILL_COLOR(pipe) == 0x1101014 || BLD_FILL_COLOR(pipe) == 0x1101024);
  DEBUGASSERT(color == 0xFF000000);

  DEBUGASSERT(BLD_CH_OFFSET(pipe) == 0x110100C || BLD_CH_OFFSET(pipe) == 0x110101C || BLD_CH_OFFSET(pipe) == 0x110102C);
  DEBUGASSERT(offset == 0 || offset == 0x340034);

  DEBUGASSERT(BLD_CTL(pipe) == 0x1101090 || BLD_CTL(pipe) == 0x1101094 || BLD_CTL(pipe) == 0x1101098);
  DEBUGASSERT(UIS_CTRL_REG(channel) == 0x1140000 || UIS_CTRL_REG(channel) == 0x1150000 || UIS_CTRL_REG(channel) == 0x1160000);
}
