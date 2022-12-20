// Test Code for Allwinner A64 Display Engine
// Add `#include "../../pinephone-nuttx/test/test_a64_rsb.c"` to the end of this file:
// https://github.com/apache/nuttx/blob/master/arch/arm64/src/a64/a64_rsb.c

/// PIO Base Address (CPUx-PORT) (A64 Page 376)
#define PIO_BASE_ADDRESS 0x01C20800

/// Address of AXP803 PMIC on Reduced Serial Bus
#define AXP803_RT_ADDR 0x2d

static int pmic_write(
  uint8_t reg,
  uint8_t val
);
static int pmic_clrsetbits(
  uint8_t reg, 
  uint8_t clr_mask, 
  uint8_t set_mask
);

/// Init PMIC.
/// Based on https://lupyuen.github.io/articles/de#appendix-power-management-integrated-circuit
int pinephone_pmic_init(void)
{
  // Reset LCD Panel at PD23 (Active Low)
  // assert reset: GPD(23), 0  // PD23 - LCD-RST (active low)

  // Configure PD23 for Output
  // Register PD_CFG2_REG (PD Configure Register 2)
  // At PIO Offset 0x74 (A64 Page 387)
  // Set PD23_SELECT (Bits 28 to 30) to 1 (Output)
  // sunxi_gpio_set_cfgpin: pin=0x77, val=1
  // sunxi_gpio_set_cfgbank: bank_offset=119, val=1
  //   clrsetbits 0x1c20874, 0xf0000000, 0x10000000
  // TODO: Should 0xf0000000 be 0x70000000 instead?
  ginfo("Configure PD23 for Output\n");
  #define PD_CFG2_REG (PIO_BASE_ADDRESS + 0x74)
  DEBUGASSERT(PD_CFG2_REG == 0x1c20874);
  #define PD23_SELECT (0b001 << 28)
  #define PD23_MASK (0b111 << 28)
  DEBUGASSERT(PD23_SELECT == 0x10000000);
  DEBUGASSERT(PD23_MASK   == 0x70000000);
  modreg32(PD23_SELECT, PD23_MASK, PD_CFG2_REG);  // TODO: DMB

  // Set PD23 to Low
  // Register PD_DATA_REG (PD Data Register)
  // At PIO Offset 0x7C (A64 Page 388)
  // Set PD23 (Bit 23) to 0 (Low)
  // sunxi_gpio_output: pin=0x77, val=0
  //   before: 0x1c2087c = 0x1c0000
  //   after: 0x1c2087c = 0x1c0000 (DMB)
  ginfo("Set PD23 to Low\n");
  #define PD_DATA_REG (PIO_BASE_ADDRESS + 0x7C)
  DEBUGASSERT(PD_DATA_REG == 0x1c2087c);
  #define PD23 (1 << 23)
  modreg32(0, PD23, PD_DATA_REG);  // TODO: DMB

  // Set DLDO1 Voltage to 3.3V
  // DLDO1 powers the Front Camera / USB HSIC / I2C Sensors
  // Register 0x15: DLDO1 Voltage Control (AXP803 Page 52)
  // Set Voltage (Bits 0 to 4) to 26 (2.6V + 0.7V = 3.3V)
  ginfo("Set DLDO1 Voltage to 3.3V\n");
  #define DLDO1_Voltage_Control 0x15
  #define DLDO1_Voltage (26 << 0)
  int ret1 = pmic_write(DLDO1_Voltage_Control, DLDO1_Voltage);
  assert(ret1 == 0);

  // Power on DLDO1
  // Register 0x12: Output Power On-Off Control 2 (AXP803 Page 51)
  // Set DLDO1 On-Off Control (Bit 3) to 1 (Power On)
  #define Output_Power_On_Off_Control2 0x12
  #define DLDO1_On_Off_Control (1 << 3)
  int ret2 = pmic_clrsetbits(Output_Power_On_Off_Control2, 0, DLDO1_On_Off_Control);
  assert(ret2 == 0);

  // Set LDO Voltage to 3.3V
  // GPIO0LDO powers the Capacitive Touch Panel
  // Register 0x91: GPIO0LDO and GPIO0 High Level Voltage Setting (AXP803 Page 77)
  // Set GPIO0LDO and GPIO0 High Level Voltage (Bits 0 to 4) to 26 (2.6V + 0.7V = 3.3V)
  ginfo("Set LDO Voltage to 3.3V\n");
  #define GPIO0LDO_High_Level_Voltage_Setting 0x91
  #define GPIO0LDO_High_Level_Voltage (26 << 0)
  int ret3 = pmic_write(GPIO0LDO_High_Level_Voltage_Setting, GPIO0LDO_High_Level_Voltage);
  assert(ret3 == 0);

  // Enable LDO Mode on GPIO0
  // Register 0x90: GPIO0 (GPADC) Control (AXP803 Page 76)
  // Set GPIO0 Pin Function Control (Bits 0 to 2) to 0b11 (Low Noise LDO on)
  ginfo("Enable LDO mode on GPIO0\n");
  #define GPIO0_Control 0x90
  #define GPIO0_Pin_Function (0b11 << 0)
  int ret4 = pmic_write(GPIO0_Control, GPIO0_Pin_Function);
  assert(ret4 == 0);

  // Set DLDO2 Voltage to 1.8V
  // DLDO2 powers the MIPI DSI Connector
  // Register 0x16: DLDO2 Voltage Control (AXP803 Page 52)
  // Set Voltage (Bits 0 to 4) to 11 (1.1V + 0.7V = 1.8V)
  ginfo("Set DLDO2 Voltage to 1.8V\n");
  #define DLDO2_Voltage_Control 0x16
  #define DLDO2_Voltage (11 << 0)
  int ret5 = pmic_write(DLDO2_Voltage_Control, DLDO2_Voltage);
  assert(ret5 == 0);

  // Power on DLDO2
  // Register 0x12: Output Power On-Off Control 2 (AXP803 Page 51)
  // Set DLDO2 On-Off Control (Bit 4) to 1 (Power On)
  DEBUGASSERT(Output_Power_On_Off_Control2 == 0x12);
  #define DLDO2 (1 << 4)
  int ret6 = pmic_clrsetbits(Output_Power_On_Off_Control2, 0x0, DLDO2);
  assert(ret6 == 0);

  return OK;
}

/// Write value to PMIC Register
static int pmic_write(
  uint8_t reg,
  uint8_t val
)
{
  // Write to AXP803 PMIC on Reduced Serial Bus
  ginfo("  pmic_write: reg=0x%x, val=0x%x\n", reg, val);
  int ret = a64_rsb_write(AXP803_RT_ADDR, reg, val);
  if (ret != 0) { gerr("  pmic_write Error: ret=%d\n", ret); }
  return ret;
}

#ifdef NOTUSED
/// Read value from PMIC Register
static int pmic_read(
  uint8_t reg_addr
)
{
  // Read from AXP803 PMIC on Reduced Serial Bus
  ginfo("  pmic_read: reg_addr=0x%x\n", reg_addr);
  int ret = a64_rsb_read(AXP803_RT_ADDR, reg_addr);
  if (ret < 0) { gerr("  pmic_read Error: ret=%d\n", ret); }
  return ret;
}
#endif

/// Clear and Set the PMIC Register Bits
static int pmic_clrsetbits(
  uint8_t reg, 
  uint8_t clr_mask, 
  uint8_t set_mask
)
{
  // Read from AXP803 PMIC on Reduced Serial Bus
  ginfo("  pmic_clrsetbits: reg=0x%x, clr_mask=0x%x, set_mask=0x%x\n", reg, clr_mask, set_mask);
  int ret = a64_rsb_read(AXP803_RT_ADDR, reg);
  if (ret < 0) { return ret; }

  // Write to AXP803 PMIC on Reduced Serial Bus
  uint8_t regval = (ret & ~clr_mask) | set_mask;
  return a64_rsb_write(AXP803_RT_ADDR, reg, regval);
}
