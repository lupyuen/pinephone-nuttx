// Test Code for Allwinner A64 MIPI DSI
// Add `#include "../../pinephone-nuttx/test/a64_mipi_dsi_inc.c"` to the end of this file:
// https://github.com/lupyuen2/wip-pinephone-nuttx/blob/dsi/arch/arm64/src/a64/a64_mipi_dsi.c

/// Write the DCS Command to MIPI DSI
static int write_dcs(FAR const uint8_t *buf, size_t len)
{
  int ret = -1;
  ginfo("writeDcs: len=%d\n", (int) len);
  ginfodumpbuffer("buf", buf, len);
  assert(len > 0);

  // Do DCS Short Write or Long Write depending on command length
  switch (len)
  {
    // DCS Short Write (without parameter)
    case 1:
      ret = a64_mipi_dsi_write(VIRTUAL_CHANNEL, 
        MIPI_DSI_DCS_SHORT_WRITE, 
        buf, len);
      break;

    // DCS Short Write (with parameter)
    case 2:
      ret = a64_mipi_dsi_write(VIRTUAL_CHANNEL, 
        MIPI_DSI_DCS_SHORT_WRITE_PARAM, 
        buf, len);
      break;

    // DCS Long Write
    default:
      ret = a64_mipi_dsi_write(VIRTUAL_CHANNEL, 
        MIPI_DSI_DCS_LONG_WRITE, 
        buf, len);
      break;
  };
  ginfo("ret=%d\n", ret);
  DEBUGASSERT(ret == len);

  return OK;
}

/// Initialise the ST7703 LCD Controller in Xingbangda XBD599 LCD Panel.
/// See https://lupyuen.github.io/articles/dsi#initialise-lcd-controller
int pinephone_panel_init(void) {
  int ret;
  ginfo("panel_init: start\n");

  // Most of these commands are documented in the ST7703 Datasheet:
  // https://files.pine64.org/doc/datasheet/pinephone/ST7703_DS_v01_20160128.pdf

  // Command #1
  const uint8_t cmd1[] = { 
      0xB9,  // SETEXTC (Page 131): Enable USER Command
      0xF1,  // Enable User command
      0x12,  // (Continued)
      0x83   // (Continued)
  };
  ret = write_dcs(cmd1, sizeof(cmd1));
  assert(ret == OK);

  // Command #2
  const uint8_t cmd2[] = { 
      0xBA,  // SETMIPI (Page 144): Set MIPI related register
      0x33,  // Virtual Channel = 0 (VC_Main = 0) ; Number of Lanes = 4 (Lane_Number = 3)
      0x81,  // LDO = 1.7 V (DSI_LDO_SEL = 4) ; Terminal Resistance = 90 Ohm (RTERM = 1)
      0x05,  // MIPI Low High Speed driving ability = x6 (IHSRX = 5)
      0xF9,  // TXCLK speed in DSI LP mode = fDSICLK / 16 (Tx_clk_sel = 2)
      0x0E,  // Min HFP number in DSI mode = 14 (HFP_OSC = 14)
      0x0E,  // Min HBP number in DSI mode = 14 (HBP_OSC = 14)
      0x20,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x44,  // Undocumented
      0x25,  // Undocumented
      0x00,  // Undocumented
      0x91,  // Undocumented
      0x0a,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x02,  // Undocumented
      0x4F,  // Undocumented
      0x11,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x37   // Undocumented
  };
  ret = write_dcs(cmd2, sizeof(cmd2));
  assert(ret == OK);

  // Command #3
  const uint8_t cmd3[] = { 
      0xB8,  // SETPOWER_EXT (Page 142): Set display related register
      0x25,  // External power IC or PFM: VSP = FL1002, VSN = FL1002 (PCCS = 2) ; VCSW1 / VCSW2 Frequency for Pumping VSP / VSN = 1/4 Hsync (ECP_DC_DIV = 5)
      0x22,  // VCSW1/VCSW2 soft start time = 15 ms (DT = 2) ; Pumping ratio of VSP / VSN with VCI = x2 (XDK_ECP = 1)
      0x20,  // PFM operation frequency FoscD = Fosc/1 (PFM_DC_DIV = 0)
      0x03   // Enable power IC pumping frequency synchronization = Synchronize with external Hsync (ECP_SYNC_EN = 1) ; Enable VGH/VGL pumping frequency synchronization = Synchronize with external Hsync (VGX_SYNC_EN = 1)
  };
  ret = write_dcs(cmd3, sizeof(cmd3));
  assert(ret == OK);

  // Command #4
  const uint8_t cmd4[] = { 
      0xB3,  // SETRGBIF (Page 134): Control RGB I/F porch timing for internal use
      0x10,  // Vertical back porch HS number in Blank Frame Period  = Hsync number 16 (VBP_RGB_GEN = 16)
      0x10,  // Vertical front porch HS number in Blank Frame Period = Hsync number 16 (VFP_RGB_GEN = 16)
      0x05,  // HBP OSC number in Blank Frame Period = OSC number 5 (DE_BP_RGB_GEN = 5)
      0x05,  // HFP OSC number in Blank Frame Period = OSC number 5 (DE_FP_RGB_GEN = 5)
      0x03,  // Undocumented
      0xFF,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x00,  // Undocumented
      0x00   // Undocumented
  };
  ret = write_dcs(cmd4, sizeof(cmd4));
  assert(ret == OK);

  // Command #5
  const uint8_t cmd5[] = { 
      0xC0,  // SETSCR (Page 147): Set related setting of Source driving
      0x73,  // Source OP Amp driving period for positive polarity in Normal Mode: Source OP Period = 115*4/Fosc (N_POPON = 115)
      0x73,  // Source OP Amp driving period for negative polarity in Normal Mode: Source OP Period = 115*4/Fosc (N_NOPON = 115)
      0x50,  // Source OP Amp driving period for positive polarity in Idle mode: Source OP Period   = 80*4/Fosc (I_POPON = 80)
      0x50,  // Source OP Amp dirivng period for negative polarity in Idle Mode: Source OP Period   = 80*4/Fosc (I_NOPON = 80)
      0x00,  // (SCR Bits 24-31 = 0x00)
      0xC0,  // (SCR Bits 16-23 = 0xC0) 
      0x08,  // Gamma bias current fine tune: Current xIbias   = 4 (SCR Bits 9-13 = 4) ; (SCR Bits  8-15 = 0x08) 
      0x70,  // Source and Gamma bias current core tune: Ibias = 1 (SCR Bits 0-3 = 0) ; Source bias current fine tune: Current xIbias = 7 (SCR Bits 4-8 = 7) ; (SCR Bits  0-7  = 0x70)
      0x00   // Undocumented
  };
  ret = write_dcs(cmd5, sizeof(cmd5));
  assert(ret == OK);

  // Command #6
  const uint8_t cmd6[] = { 
      0xBC,  // SETVDC (Page 146): Control NVDDD/VDDD Voltage
      0x4E   // NVDDD voltage = -1.8 V (NVDDD_SEL = 4) ; VDDD voltage = 1.9 V (VDDD_SEL = 6)
  };
  ret = write_dcs(cmd6, sizeof(cmd6));
  assert(ret == OK);

  // Command #7
  const uint8_t cmd7[] = { 
      0xCC,  // SETPANEL (Page 154): Set display related register
      0x0B   // Enable reverse the source scan direction (SS_PANEL = 1) ; Normal vertical scan direction (GS_PANEL = 0) ; Normally black panel (REV_PANEL = 1) ; S1:S2:S3 = B:G:R (BGR_PANEL = 1)
  };
  ret = write_dcs(cmd7, sizeof(cmd7));
  assert(ret == OK);

  // Command #8
  const uint8_t cmd8[] = { 
      0xB4,  // SETCYC (Page 135): Control display inversion type
      0x80   // Extra source for Zig-Zag Inversion = S2401 (ZINV_S2401_EN = 1) ; Row source data dislocates = Even row (ZINV_G_EVEN_EN = 0) ; Disable Zig-Zag Inversion (ZINV_EN = 0) ; Enable Zig-Zag1 Inversion (ZINV2_EN = 0) ; Normal mode inversion type = Column inversion (N_NW = 0)
  };
  ret = write_dcs(cmd8, sizeof(cmd8));
  assert(ret == OK);

  // Command #9
  const uint8_t cmd9[] = { 
      0xB2,  // SETDISP (Page 132): Control the display resolution
      0xF0,  // Gate number of vertical direction = 480 + (240*4) (NL = 240)
      0x12,  // (RES_V_LSB = 0) ; Non-display area source output control: Source output = VSSD (BLK_CON = 1) ; Channel number of source direction = 720RGB (RESO_SEL = 2)
      0xF0   // Source voltage during Blanking Time when accessing Sleep-Out / Sleep-In command = GND (WHITE_GND_EN = 1) ; Blank timing control when access sleep out command: Blank Frame Period = 7 Frames (WHITE_FRAME_SEL = 7) ; Source output refresh control: Refresh Period = 0 Frames (ISC = 0)
  };
  ret = write_dcs(cmd9, sizeof(cmd9));
  assert(ret == OK);

  // Command #10
  const uint8_t cmd10[] = { 
      0xE3,  // SETEQ (Page 159): Set EQ related register
      0x00,  // Temporal spacing between HSYNC and PEQGND = 0*4/Fosc (PNOEQ = 0)
      0x00,  // Temporal spacing between HSYNC and NEQGND = 0*4/Fosc (NNOEQ = 0)
      0x0B,  // Source EQ GND period when Source up to positive voltage   = 11*4/Fosc (PEQGND = 11)
      0x0B,  // Source EQ GND period when Source down to negative voltage = 11*4/Fosc (NEQGND = 11)
      0x10,  // Source EQ VCI period when Source up to positive voltage   = 16*4/Fosc (PEQVCI = 16)
      0x10,  // Source EQ VCI period when Source down to negative voltage = 16*4/Fosc (NEQVCI = 16)
      0x00,  // Temporal period of PEQVCI1 = 0*4/Fosc (PEQVCI1 = 0)
      0x00,  // Temporal period of NEQVCI1 = 0*4/Fosc (NEQVCI1 = 0)
      0x00,  // (Reserved)
      0x00,  // (Reserved)
      0xFF,  // (Undocumented)
      0x00,  // (Reserved)
      0xC0,  // White pattern to protect GOA glass (ESD_DET_DATA_WHITE = 1) ; Enable ESD detection function to protect GOA glass (ESD_WHITE_EN = 1)
      0x10   // No Need VSYNC (additional frame) after Sleep-In command to display sleep-in blanking frame then into Sleep-In State (SLPIN_OPTION = 1) ; Enable video function detection (VEDIO_NO_CHECK_EN = 0) ; Disable ESD white pattern scanning voltage pull ground (ESD_WHITE_GND_EN = 0) ; ESD detection function period = 0 Frames (ESD_DET_TIME_SEL = 0)
  };
  ret = write_dcs(cmd10, sizeof(cmd10));
  assert(ret == OK);

  // Command #11
  const uint8_t cmd11[] = { 
      0xC6,  // Undocumented
      0x01,  // Undocumented
      0x00,  // Undocumented
      0xFF,  // Undocumented
      0xFF,  // Undocumented
      0x00   // Undocumented
  };
  ret = write_dcs(cmd11, sizeof(cmd11));
  assert(ret == OK);

  // Command #12
  const uint8_t cmd12[] = { 
      0xC1,  // SETPOWER (Page 149): Set related setting of power
      0x74,  // VGH Voltage Adjustment = 17 V (VBTHS = 7) ; VGL Voltage Adjustment = -11 V (VBTLS = 4)
      0x00,  // Enable VGH feedback voltage detection. Output voltage = VBTHS (FBOFF_VGH = 0) ; Enable VGL feedback voltage detection. Output voltage = VBTLS (FBOFF_VGL = 0)
      0x32,  // VSPROUT Voltage = (VRH[5:0] x 0.05 + 3.3) x (VREF/4.8) if VREF [4]=0 (VRP = 50)
      0x32,  // VSNROUT Voltage = (VRH[5:0] x 0.05 + 3.3) x (VREF/5.6) if VREF [4]=1 (VRN = 50)
      0x77,  // Undocumented
      0xF1,  // Enable VGL voltage Detect Function = VGL voltage Abnormal (VGL_DET_EN = 1) ; Enable VGH voltage Detect Function = VGH voltage Abnormal (VGH_DET_EN = 1) ; Enlarge VGL Voltage at "FBOFF_VGL=1" = "VGL=-15V" (VGL_TURBO = 1) ; Enlarge VGH Voltage at "FBOFF_VGH=1" = "VGH=20V" (VGH_TURBO = 1) ; (APS = 1)
      0xFF,  // Left side VGH stage 1 pumping frequency  = 1.5 MHz (VGH1_L_DIV = 15) ; Left side VGL stage 1 pumping frequency  = 1.5 MHz (VGL1_L_DIV = 15)
      0xFF,  // Right side VGH stage 1 pumping frequency = 1.5 MHz (VGH1_R_DIV = 15) ; Right side VGL stage 1 pumping frequency = 1.5 MHz (VGL1_R_DIV = 15)
      0xCC,  // Left side VGH stage 2 pumping frequency  = 2.6 MHz (VGH2_L_DIV = 12) ; Left side VGL stage 2 pumping frequency  = 2.6 MHz (VGL2_L_DIV = 12)
      0xCC,  // Right side VGH stage 2 pumping frequency = 2.6 MHz (VGH2_R_DIV = 12) ; Right side VGL stage 2 pumping frequency = 2.6 MHz (VGL2_R_DIV = 12)
      0x77,  // Left side VGH stage 3 pumping frequency  = 4.5 MHz (VGH3_L_DIV = 7)  ; Left side VGL stage 3 pumping frequency  = 4.5 MHz (VGL3_L_DIV = 7)
      0x77   // Right side VGH stage 3 pumping frequency = 4.5 MHz (VGH3_R_DIV = 7)  ; Right side VGL stage 3 pumping frequency = 4.5 MHz (VGL3_R_DIV = 7)
  };
  ret = write_dcs(cmd12, sizeof(cmd12));
  assert(ret == OK);

  // Command #13
  const uint8_t cmd13[] = { 
      0xB5,  // SETBGP (Page 136): Internal reference voltage setting
      0x07,  // VREF Voltage: 4.2 V (VREF_SEL = 7)
      0x07   // NVREF Voltage: 4.2 V (NVREF_SEL = 7)
  };
  ret = write_dcs(cmd13, sizeof(cmd13));
  assert(ret == OK);

  // Command #14
  const uint8_t cmd14[] = { 
      0xB6,  // SETVCOM (Page 137): Set VCOM Voltage
      0x2C,  // VCOMDC voltage at "GS_PANEL=0" = -0.67 V (VCOMDC_F = 0x2C)
      0x2C   // VCOMDC voltage at "GS_PANEL=1" = -0.67 V (VCOMDC_B = 0x2C)
  };
  ret = write_dcs(cmd14, sizeof(cmd14));
  assert(ret == OK);

  // Command #15
  const uint8_t cmd15[] = { 
      0xBF,  // Undocumented
      0x02,  // Undocumented
      0x11,  // Undocumented
      0x00   // Undocumented
  };
  ret = write_dcs(cmd15, sizeof(cmd15));
  assert(ret == OK);

  // Command #16
  const uint8_t cmd16[] = { 
      0xE9,  // SETGIP1 (Page 163): Set forward GIP timing
      0x82,  // SHR0, SHR1, CHR, CHR2 refer to Internal DE (REF_EN = 1) ; (PANEL_SEL = 2)
      0x10,  // Starting position of GIP STV group 0 = 4102 HSYNC (SHR0 Bits 8-12 = 0x10)
      0x06,  // (SHR0 Bits 0-7  = 0x06)
      0x05,  // Starting position of GIP STV group 1 = 1442 HSYNC (SHR1 Bits 8-12 = 0x05)
      0xA2,  // (SHR1 Bits 0-7  = 0xA2)
      0x0A,  // Distance of STV rising edge and HYSNC  = 10*2  Fosc (SPON  Bits 0-7 = 0x0A)
      0xA5,  // Distance of STV falling edge and HYSNC = 165*2 Fosc (SPOFF Bits 0-7 = 0xA5)
      0x12,  // STV0_1 distance with STV0_0 = 1 HSYNC (SHR0_1 = 1) ; STV0_2 distance with STV0_0 = 2 HSYNC (SHR0_2 = 2)
      0x31,  // STV0_3 distance with STV0_0 = 3 HSYNC (SHR0_3 = 3) ; STV1_1 distance with STV1_0 = 1 HSYNC (SHR1_1 = 1)
      0x23,  // STV1_2 distance with STV1_0 = 2 HSYNC (SHR1_2 = 2) ; STV1_3 distance with STV1_0 = 3 HSYNC (SHR1_3 = 3)
      0x37,  // STV signal high pulse width = 3 HSYNC (SHP = 3) ; Total number of STV signal = 7 (SCP = 7)
      0x83,  // Starting position of GIP CKV group 0 (CKV0_0) = 131 HSYNC (CHR = 0x83)
      0x04,  // Distance of CKV rising edge and HYSNC  = 4*2   Fosc (CON  Bits 0-7 = 0x04)
      0xBC,  // Distance of CKV falling edge and HYSNC = 188*2 Fosc (COFF Bits 0-7 = 0xBC)
      0x27,  // CKV signal high pulse width = 2 HSYNC (CHP = 2) ; Total period cycle of CKV signal = 7 HSYNC (CCP = 7)
      0x38,  // Extra gate counter at blanking area: Gate number = 56 (USER_GIP_GATE = 0x38)
      0x0C,  // Left side GIP output pad signal = ??? (CGTS_L Bits 16-21 = 0x0C)
      0x00,  // (CGTS_L Bits  8-15 = 0x00)
      0x03,  // (CGTS_L Bits  0-7  = 0x03)
      0x00,  // Normal polarity of Left side GIP output pad signal (CGTS_INV_L Bits 16-21 = 0x00)
      0x00,  // (CGTS_INV_L Bits  8-15 = 0x00)
      0x00,  // (CGTS_INV_L Bits  0-7  = 0x00)
      0x0C,  // Right side GIP output pad signal = ??? (CGTS_R Bits 16-21 = 0x0C)
      0x00,  // (CGTS_R Bits  8-15 = 0x00)
      0x03,  // (CGTS_R Bits  0-7  = 0x03)
      0x00,  // Normal polarity of Right side GIP output pad signal (CGTS_INV_R Bits 16-21 = 0x00)
      0x00,  // (CGTS_INV_R Bits  8-15 = 0x00)
      0x00,  // (CGTS_INV_R Bits  0-7  = 0x00)
      0x75,  // Left side GIP output pad signal = ??? (COS1_L = 7) ; Left side GIP output pad signal = ??? (COS2_L = 5)
      0x75,  // Left side GIP output pad signal = ??? (COS3_L = 7) ; (COS4_L = 5)
      0x31,  // Left side GIP output pad signal = ??? (COS5_L = 3) ; (COS6_L = 1)
      0x88,  // Reserved (Parameter 32)
      0x88,  // Reserved (Parameter 33)
      0x88,  // Reserved (Parameter 34)
      0x88,  // Reserved (Parameter 35)
      0x88,  // Reserved (Parameter 36)
      0x88,  // Left side GIP output pad signal  = ??? (COS17_L = 8) ; Left side GIP output pad signal  = ??? (COS18_L = 8)
      0x13,  // Left side GIP output pad signal  = ??? (COS19_L = 1) ; Left side GIP output pad signal  = ??? (COS20_L = 3)
      0x88,  // Left side GIP output pad signal  = ??? (COS21_L = 8) ; Left side GIP output pad signal  = ??? (COS22_L = 8)
      0x64,  // Right side GIP output pad signal = ??? (COS1_R  = 6) ; Right side GIP output pad signal = ??? (COS2_R  = 4)
      0x64,  // Right side GIP output pad signal = ??? (COS3_R  = 6) ; Right side GIP output pad signal = ??? (COS4_R  = 4)
      0x20,  // Right side GIP output pad signal = ??? (COS5_R  = 2) ; Right side GIP output pad signal = ??? (COS6_R  = 0)
      0x88,  // Reserved (Parameter 43)
      0x88,  // Reserved (Parameter 44)
      0x88,  // Reserved (Parameter 45)
      0x88,  // Reserved (Parameter 46)
      0x88,  // Reserved (Parameter 47)
      0x88,  // Right side GIP output pad signal = ??? (COS17_R = 8) ; Right side GIP output pad signal = ??? (COS18_R = 8)
      0x02,  // Right side GIP output pad signal = ??? (COS19_R = 0) ; Right side GIP output pad signal = ??? (COS20_R = 2)
      0x88,  // Right side GIP output pad signal = ??? (COS21_R = 8) ; Right side GIP output pad signal = ??? (COS22_R = 8)
      0x00,  // (TCON_OPT = 0x00)
      0x00,  // (GIP_OPT Bits 16-22 = 0x00)
      0x00,  // (GIP_OPT Bits  8-15 = 0x00)
      0x00,  // (GIP_OPT Bits  0-7  = 0x00)
      0x00,  // Starting position of GIP CKV group 1 (CKV1_0) = 0 HSYNC (CHR2 = 0x00)
      0x00,  // Distance of CKV1 rising edge and HYSNC  = 0*2 Fosc (CON2  Bits 0-7 = 0x00)
      0x00,  // Distance of CKV1 falling edge and HYSNC = 0*2 Fosc (COFF2 Bits 0-7 = 0x00)
      0x00,  // CKV1 signal high pulse width = 0 HSYNC (CHP2 = 0) ; Total period cycle of CKV1 signal = 0 HSYNC (CCP2 = 0)
      0x00,  // (CKS Bits 16-21 = 0x00)
      0x00,  // (CKS Bits  8-15 = 0x00)
      0x00,  // (CKS Bits  0-7  = 0x00)
      0x00,  // (COFF Bits 8-9 = 0) ; (CON Bits 8-9 = 0) ; (SPOFF Bits 8-9 = 0) ; (SPON Bits 8-9 = 0)
      0x00   // (COFF2 Bits 8-9 = 0) ; (CON2 Bits 8-9 = 0)
  };
  ret = write_dcs(cmd16, sizeof(cmd16));
  assert(ret == OK);

  // Command #17
  const uint8_t cmd17[] = { 
      0xEA,  // SETGIP2 (Page 170): Set backward GIP timing
      0x02,  // YS2 Signal Mode = INYS1/INYS2 (YS2_SEL = 0) ; YS2 Signal Mode = INYS1/INYS2 (YS1_SEL = 0) ; Don't reverse YS2 signal (YS2_XOR = 0) ; Don't reverse YS1 signal (YS1_XOR = 0) ; Enable YS signal function (YS_FLAG_EN = 1) ; Disable ALL ON function (ALL_ON_EN = 0)
      0x21,  // (GATE = 0x21)
      0x00,  // (CK_ALL_ON_EN = 0) ; (STV_ALL_ON_EN = 0) ; Timing of YS1 and YS2 signal = ??? (CK_ALL_ON_WIDTH1 = 0)
      0x00,  // Timing of YS1 and YS2 signal = ??? (CK_ALL_ON_WIDTH2 = 0)
      0x00,  // Timing of YS1 and YS2 signal = ??? (CK_ALL_ON_WIDTH3 = 0)
      0x00,  // (YS_FLAG_PERIOD = 0)
      0x00,  // (YS2_SEL_2 = 0) ; (YS1_SEL_2 = 0) ; (YS2_XOR_2 = 0) ; (YS_FLAG_EN_2 = 0) ; (ALL_ON_EN_2 = 0)
      0x00,  // Distance of GIP ALL On rising edge and DE = ??? (USER_GIP_GATE1_2 = 0)
      0x00,  // (CK_ALL_ON_EN_2 = 0) ; (STV_ALL_ON_EN_2 = 0) ; (CK_ALL_ON_WIDTH1_2 = 0)
      0x00,  // (CK_ALL_ON_WIDTH2_2 = 0)
      0x00,  // (CK_ALL_ON_WIDTH3_2 = 0)
      0x00,  // (YS_FLAG_PERIOD_2 = 0)
      0x02,  // (COS1_L_GS = 0) ; (COS2_L_GS = 2)
      0x46,  // (COS3_L_GS = 4) ; (COS4_L_GS = 6)
      0x02,  // (COS5_L_GS = 0) ; (COS6_L_GS = 2)
      0x88,  // Reserved (Parameter 16)
      0x88,  // Reserved (Parameter 17)
      0x88,  // Reserved (Parameter 18)
      0x88,  // Reserved (Parameter 19)
      0x88,  // Reserved (Parameter 20)
      0x88,  // (COS17_L_GS = 8) ; (COS18_L_GS = 8)
      0x64,  // (COS19_L_GS = 6) ; (COS20_L_GS = 4)
      0x88,  // (COS21_L_GS = 8) ; (COS22_L_GS = 8)
      0x13,  // (COS1_R_GS = 1) ; (COS2_R_GS = 3)
      0x57,  // (COS3_R_GS = 5) ; (COS4_R_GS = 7)
      0x13,  // (COS5_R_GS = 1) ; (COS6_R_GS = 3)
      0x88,  // Reserved (Parameter 27)
      0x88,  // Reserved (Parameter 28)
      0x88,  // Reserved (Parameter 29)
      0x88,  // Reserved (Parameter 30)
      0x88,  // Reserved (Parameter 31)
      0x88,  // (COS17_R_GS = 8) ; (COS18_R_GS = 8)
      0x75,  // (COS19_R_GS = 7) ; (COS20_R_GS = 5)
      0x88,  // (COS21_R_GS = 8) ; (COS22_R_GS = 8)
      0x23,  // GIP output EQ signal: P_EQ = Yes, N_EQ = No (EQOPT = 2) ;  GIP output EQ signal level: P_EQ = GND, N_EQ = GND (EQ_SEL = 3)
      0x14,  // Distance of EQ rising edge and HYSNC = 20 Fosc (EQ_DELAY = 0x14)
      0x00,  // Distance of EQ rising edge and HYSNC = 0 HSYNC (EQ_DELAY_HSYNC = 0)
      0x00,  // (HSYNC_TO_CL1_CNT10 Bits 8-9 = 0)
      0x02,  // GIP reference HSYNC between external HSYNC = 2 Fosc (HSYNC_TO_CL1_CNT10 Bits 0-7 = 2)
      0x00,  // Undocumented (Parameter 40)
      0x00,  // Undocumented (Parameter 41)
      0x00,  // Undocumented (Parameter 42)
      0x00,  // Undocumented (Parameter 43)
      0x00,  // Undocumented (Parameter 44)
      0x00,  // Undocumented (Parameter 45)
      0x00,  // Undocumented (Parameter 46)
      0x00,  // Undocumented (Parameter 47)
      0x00,  // Undocumented (Parameter 48)
      0x00,  // Undocumented (Parameter 49)
      0x00,  // Undocumented (Parameter 50)
      0x00,  // Undocumented (Parameter 51)
      0x00,  // Undocumented (Parameter 52)
      0x00,  // Undocumented (Parameter 53)
      0x00,  // Undocumented (Parameter 54)
      0x03,  // Undocumented (Parameter 55)
      0x0A,  // Undocumented (Parameter 56)
      0xA5,  // Undocumented (Parameter 57)
      0x00,  // Undocumented (Parameter 58)
      0x00,  // Undocumented (Parameter 59)
      0x00,  // Undocumented (Parameter 60)
      0x00   // Undocumented (Parameter 61)
  };
  ret = write_dcs(cmd17, sizeof(cmd17));
  assert(ret == OK);

  // Command #18
  const uint8_t cmd18[] = { 
      0xE0,  // SETGAMMA (Page 158): Set the gray scale voltage to adjust the gamma characteristics of the TFT panel
      0x00,  // (PVR0 = 0x00)
      0x09,  // (PVR1 = 0x09)
      0x0D,  // (PVR2 = 0x0D)
      0x23,  // (PVR3 = 0x23)
      0x27,  // (PVR4 = 0x27)
      0x3C,  // (PVR5 = 0x3C)
      0x41,  // (PPR0 = 0x41)
      0x35,  // (PPR1 = 0x35)
      0x07,  // (PPK0 = 0x07)
      0x0D,  // (PPK1 = 0x0D)
      0x0E,  // (PPK2 = 0x0E)
      0x12,  // (PPK3 = 0x12)
      0x13,  // (PPK4 = 0x13)
      0x10,  // (PPK5 = 0x10)
      0x12,  // (PPK6 = 0x12)
      0x12,  // (PPK7 = 0x12)
      0x18,  // (PPK8 = 0x18)
      0x00,  // (NVR0 = 0x00)
      0x09,  // (NVR1 = 0x09)
      0x0D,  // (NVR2 = 0x0D)
      0x23,  // (NVR3 = 0x23)
      0x27,  // (NVR4 = 0x27)
      0x3C,  // (NVR5 = 0x3C)
      0x41,  // (NPR0 = 0x41)
      0x35,  // (NPR1 = 0x35)
      0x07,  // (NPK0 = 0x07)
      0x0D,  // (NPK1 = 0x0D)
      0x0E,  // (NPK2 = 0x0E)
      0x12,  // (NPK3 = 0x12)
      0x13,  // (NPK4 = 0x13)
      0x10,  // (NPK5 = 0x10)
      0x12,  // (NPK6 = 0x12)
      0x12,  // (NPK7 = 0x12)
      0x18   // (NPK8 = 0x18)
  };
  ret = write_dcs(cmd18, sizeof(cmd18));
  assert(ret == OK);

  // Command #19    
  const uint8_t cmd19[] = { 
      0x11  // SLPOUT (Page 89): Turns off sleep mode (MIPI_DCS_EXIT_SLEEP_MODE)
  };
  ret = write_dcs(cmd19, sizeof(cmd19));
  assert(ret == OK);

  // Wait 120 milliseconds
  up_mdelay(120);

  // Command #20
  const uint8_t cmd20[] = { 
      0x29  // Display On (Page 97): Recover from DISPLAY OFF mode (MIPI_DCS_SET_DISPLAY_ON)
  };    
  ret = write_dcs(cmd20, sizeof(cmd20));
  assert(ret == OK);

  ginfo("panel_init: end\n");
  return OK;
}
