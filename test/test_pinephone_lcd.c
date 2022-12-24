// Test Code for PinePhone LCD Panel
// Add `#include "../../pinephone-nuttx/test/test_pinephone_lcd.c"` to the end of pinephone_lcd_backlight_enable(), before `return OK` in this file:
// https://github.com/apache/nuttx/blob/master/boards/arm64/a64/pinephone/src/pinephone_lcd.c

{
  DEBUGASSERT(percent == 90);
  DEBUGASSERT(R_PWM_CTRL_REG == 0x1f03800);
  DEBUGASSERT(R_PWM_CH0_PERIOD == 0x1f03804);
  DEBUGASSERT(period == 0x4af0437);
  DEBUGASSERT(ctrl == 0x5f);
}
