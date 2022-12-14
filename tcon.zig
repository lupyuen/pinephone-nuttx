//***************************************************************************
//
// Licensed to the Apache Software Foundation (ASF) under one or more
// contributor license agreements.  See the NOTICE file distributed with
// this work for additional information regarding copyright ownership.  The
// ASF licenses this file to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//
//***************************************************************************

//! PinePhone Allwinner A64 Timing Controller (TCON0) Driver for Apache NuttX RTOS
//! See https://lupyuen.github.io/articles/de#appendix-timing-controller-tcon0
//! "A64 Page ???" refers to Allwinner A64 User Manual: https://github.com/lupyuen/pinephone-nuttx/releases/download/doc/Allwinner_A64_User_Manual_V1.1.pdf

/// Import the Zig Standard Library
const std = @import("std");

/// Import NuttX Functions from C
const c = @cImport({
    // NuttX Defines
    @cDefine("__NuttX__",  "");
    @cDefine("NDEBUG",     "");
    @cDefine("FAR",        "");

    // NuttX Header Files
    @cInclude("arch/types.h");
    @cInclude("../../nuttx/include/limits.h");
    @cInclude("nuttx/config.h");
    @cInclude("inttypes.h");
    @cInclude("unistd.h");
    @cInclude("stdlib.h");
    @cInclude("stdio.h");
});

/// LCD Panel Width and Height (pixels)
const PANEL_WIDTH  = 720;
const PANEL_HEIGHT = 1440;

/// Base Address of Allwinner A64 TCON0 Controller (A64 Page 507)
const TCON0_BASE_ADDRESS = 0x01C0_C000;

/// Base Address of Allwinner A64 CCU Controller (A64 Page 82)
const CCU_BASE_ADDRESS = 0x01C2_0000;

/// Init Timing Controller TCON0
/// Based on https://lupyuen.github.io/articles/de#appendix-timing-controller-tcon0
pub export fn tcon0_init() void {
    debug("tcon0_init: start", .{});
    defer { debug("tcon0_init: end", .{}); }

    // Configure PLL_VIDEO0
    // PLL_VIDEO0_CTRL_REG: CCU Offset 0x10 (A64 Page 86)
    // Set PLL_ENABLE (Bit 31) to 1 (Enable PLL)
    // Set PLL_MODE (Bit 30) to 0 (Manual Mode)
    // Set LOCK (Bit 28) to 0 (Unlocked)
    // Set FRAC_CLK_OUT (Bit 25) to 0
    // Set PLL_MODE_SEL (Bit 24) to 1 (Integer Mode)
    // Set PLL_SDM_EN (Bit 20) to 0 (Disable)
    // Set PLL_FACTOR_N (Bits 8 to 14) to 0x62 (PLL Factor N)
    // Set PLL_PREDIV_M (Bits 0 to 3) to 7 (PLL Pre Divider)
    debug("Configure PLL_VIDEO0", .{});
    const PLL_VIDEO0_CTRL_REG = CCU_BASE_ADDRESS + 0x10;
    comptime{ assert(PLL_VIDEO0_CTRL_REG == 0x1c20010); }
    {
        const PLL_ENABLE:   u32 = 1    << 31;
        const PLL_MODE:     u31 = 0    << 30;
        const LOCK:         u29 = 0    << 28;
        const FRAC_CLK_OUT: u26 = 0    << 25;
        const PLL_MODE_SEL: u25 = 1    << 24;
        const PLL_SDM_EN:   u21 = 0    << 20;
        const PLL_FACTOR_N: u15 = 0x62 << 8;
        const PLL_PREDIV_M: u4  = 7    << 0;
        const PLL_VIDEO0_CTRL = PLL_ENABLE
            | PLL_MODE
            | LOCK
            | FRAC_CLK_OUT
            | PLL_MODE_SEL
            | PLL_SDM_EN
            | PLL_FACTOR_N
            | PLL_PREDIV_M;
        comptime{ assert(PLL_VIDEO0_CTRL == 0x81006207); }
        putreg32(PLL_VIDEO0_CTRL, PLL_VIDEO0_CTRL_REG);  // TODO: DMB        
    }

    // Enable LDO1 and LDO2
    // PLL_MIPI_CTRL_REG: CCU Offset 0x40 (A64 Page 94)
    // Set LDO1_EN (Bit 23) to 1 (Enable On-chip LDO1)
    // Set LDO2_EN (Bit 22) to 1 (Enable On-chip LDO2)
    debug("Enable LDO1 and LDO2", .{});
    const PLL_MIPI_CTRL_REG = CCU_BASE_ADDRESS + 0x40;
    comptime{ assert(PLL_MIPI_CTRL_REG == 0x1c20040); }
    {
        const LDO1_EN: u24 = 1 << 23;
        const LDO2_EN: u23 = 1 << 22;
        const PLL_MIPI_CTRL = LDO1_EN
            | LDO2_EN;
        comptime{ assert(PLL_MIPI_CTRL == 0xc00000); }
        putreg32(PLL_MIPI_CTRL, PLL_MIPI_CTRL_REG);  // TODO: DMB
    }

    // Wait 100 microseconds
    _ = c.usleep(100);

    // Configure MIPI PLL
    // PLL_MIPI_CTRL_REG: CCU Offset 0x40 (A64 Page 94)
    // Set PLL_ENABLE (Bit 31) to 1 (Enable MIPI PLL)
    // Set LOCK (Bit 28) to 0 (Unlocked)
    // Set SINT_FRAC (Bit 27) to 0 (Integer Mode)
    // Set SDIV2 (Bit 26) to 0 (PLL Output)
    // Set S6P25_7P5 (Bit 25) to 0 (PLL Output=PLL Input*6.25)
    // Set LDO1_EN (Bit 23) to 1 (Enable On-chip LDO1)
    // Set LDO2_EN (Bit 22) to 1 (Enable On-chip LDO2)
    // Set PLL_SRC (Bit 21) to 0 (PLL Source is VIDEO0 PLL)
    // Set PLL_SDM_EN (Bit 20) to 0 (Disable SDM PLL)
    // Set PLL_FEEDBACK_DIV (Bit 17) to 0 (PLL Feedback Divider Control: Divide by 5)
    // Set VFB_SEL (Bit 16) to 0 (MIPI Mode)
    // Set PLL_FACTOR_N (Bits 8 to 11) to 7 (PLL Factor N)
    // Set PLL_FACTOR_K (Bits 4 to 5) to 1 (PLL Factor K)
    // Set PLL_PRE_DIV_M (Bits 0 to 3) to 10 (PLL Pre Divider)
    debug("Configure MIPI PLL", .{});
    comptime{ assert(PLL_MIPI_CTRL_REG == 0x1c20040); }
    {
        const PLL_ENABLE:       u32 = 1  << 31;
        const LOCK:             u29 = 0  << 28;
        const SINT_FRAC:        u28 = 0  << 27;
        const SDIV2:            u27 = 0  << 26;
        const S6P25_7P5:        u26 = 0  << 25;
        const LDO1_EN:          u24 = 1  << 23;
        const LDO2_EN:          u23 = 1  << 22;
        const PLL_SRC:          u22 = 0  << 21;
        const PLL_SDM_EN:       u21 = 0  << 20;
        const PLL_FEEDBACK_DIV: u18 = 0  << 17;
        const VFB_SEL:          u17 = 0  << 16;
        const PLL_FACTOR_N:     u12 = 7  << 8;
        const PLL_FACTOR_K:     u6  = 1  << 4;
        const PLL_PRE_DIV_M:    u6  = 10 << 0;
        const PLL_MIPI_CTRL = PLL_ENABLE
            | LOCK
            | SINT_FRAC
            | SDIV2
            | S6P25_7P5
            | LDO1_EN
            | LDO2_EN
            | PLL_SRC
            | PLL_SDM_EN
            | PLL_FEEDBACK_DIV
            | VFB_SEL
            | PLL_FACTOR_N
            | PLL_FACTOR_K
            | PLL_PRE_DIV_M;
        comptime{ assert(PLL_MIPI_CTRL == 0x80c0071a); }
        putreg32(PLL_MIPI_CTRL, PLL_MIPI_CTRL_REG);  // TODO: DMB
    }

    // Set TCON0 Clock Source to MIPI PLL
    // TCON0_CLK_REG: CCU Offset 0x118 (A64 Page 117)
    // Set SCLK_GATING (Bit 31) to 1 (Special Clock is On)
    // Set CLK_SRC_SEL (Bits 24 to 26) to 0 (Clock Source is MIPI PLL)
    debug("Set TCON0 Clock Source to MIPI PLL", .{});
    const TCON0_CLK_REG = CCU_BASE_ADDRESS + 0x118;
    comptime{ assert(TCON0_CLK_REG == 0x1c20118); }

    const SCLK_GATING: u32 = 1 << 31;
    const CLK_SRC_SEL: u27 = 0 << 24;
    const TCON0_CLK = SCLK_GATING
        | CLK_SRC_SEL;
    comptime{ assert(TCON0_CLK == 0x80000000); }
    putreg32(TCON0_CLK, TCON0_CLK_REG);  // TODO: DMB

    // Enable TCON0 Clock
    // BUS_CLK_GATING_REG1: CCU Offset 0x64 (A64 Page 102)
    // Set TCON0_GATING (Bit 3) to 1 (Pass Clock for TCON0)
    debug("Enable TCON0 Clock", .{});
    const BUS_CLK_GATING_REG1 = CCU_BASE_ADDRESS + 0x64;
    comptime{ assert(BUS_CLK_GATING_REG1 == 0x1c20064); }

    const TCON0_GATING: u4 = 1 << 3;
    const BUS_CLK_GATING = TCON0_GATING;
    comptime{ assert(BUS_CLK_GATING == 0x8); }
    putreg32(BUS_CLK_GATING, BUS_CLK_GATING_REG1);  // TODO: DMB

    // Deassert TCON0 Reset
    // BUS_SOFT_RST_REG1: CCU Offset 0x2c4 (A64 Page 140)
    // Set TCON0_RST (Bit 3) to 1 (Deassert TCON0 Reset)
    debug("Deassert TCON0 Reset", .{});
    const BUS_SOFT_RST_REG1 = CCU_BASE_ADDRESS + 0x2c4;
    comptime{ assert(BUS_SOFT_RST_REG1 == 0x1c202c4); }

    const TCON0_RST: u4 = 1 << 3;
    const BUS_SOFT_RST = TCON0_RST;
    comptime{ assert(BUS_SOFT_RST == 0x8); }
    putreg32(BUS_SOFT_RST, BUS_SOFT_RST_REG1);  // TODO: DMB

    // Disable TCON0 and Interrupts
    // TCON_GCTL_REG: TCON0 Offset 0x00 (A64 Page 508)
    // Set TCON_En (Bit 31) to 0 (Disable TCON0)
    debug("Disable TCON0 and Interrupts", .{});
    const TCON_GCTL_REG = TCON0_BASE_ADDRESS + 0x00;
    comptime{ assert(TCON_GCTL_REG == 0x1c0c000); }
    {
        const TCON_En: u32 = 0 << 31;
        const TCON_GCTL = TCON_En;
        comptime{ assert(TCON_GCTL == 0x0); }
        putreg32(TCON_GCTL, TCON_GCTL_REG);  // TODO: DMB
    }

    // TCON_GINT0_REG: TCON0 Offset 0x04 (A64 Page 509)
    // Set to 0 (Disable TCON0 Interrupts)
    const TCON_GINT0_REG = TCON0_BASE_ADDRESS + 0x04;
    comptime{ assert(TCON_GINT0_REG == 0x1c0c004); }
    putreg32(0x0, TCON_GINT0_REG);

    // TCON_GINT1_REG: TCON0 Offset 0x08 (A64 Page 510)
    // Set to 0 (Disable TCON0 Interrupts)
    const TCON_GINT1_REG = TCON0_BASE_ADDRESS + 0x08;
    comptime{ assert(TCON_GINT1_REG == 0x1c0c008); }
    putreg32(0x0, TCON_GINT1_REG);

    // Enable Tristate Output
    // TCON0_IO_TRI_REG: TCON0 Offset 0x8c (A64 Page 520)
    // Set to 0xffff ffff to Enable TCON0 Tristate Output
    debug("Enable Tristate Output", .{});
    const TCON0_IO_TRI_REG = TCON0_BASE_ADDRESS + 0x8c;
    comptime{ assert(TCON0_IO_TRI_REG == 0x1c0c08c); }
    putreg32(0xffffffff, TCON0_IO_TRI_REG);

    // TCON1_IO_TRI_REG: TCON0 Offset 0xf4
    // Set to 0xffff ffff to Enable TCON1 Tristate Output
    // Note: TCON1_IO_TRI_REG is actually in TCON0 Address Range, not in TCON1 Address Range as stated in A64 User Manual
    const TCON1_IO_TRI_REG = TCON0_BASE_ADDRESS + 0xf4;
    comptime{ assert(TCON1_IO_TRI_REG == 0x1c0c0f4); }
    putreg32(0xffffffff, TCON1_IO_TRI_REG);

    // Set DCLK to MIPI PLL / 6
    // TCON0_DCLK_REG: TCON0 Offset 0x44 (A64 Page 513)
    // Set TCON0_Dclk_En (Bits 28 to 31) to 8 (Enable TCON0 Clocks: DCLK, DCLK1, DCLK2, DCLKM2)
    // Set TCON0_Dclk_Div (Bits 0 to 6) to 6 (DCLK Divisor)
    debug("Set DCLK to MIPI PLL / 6", .{});
    const TCON0_DCLK_REG = TCON0_BASE_ADDRESS + 0x44;
    comptime{ assert(TCON0_DCLK_REG == 0x1c0c044); }

    const TCON0_Dclk_En:  u32 = 8 << 28;
    const TCON0_Dclk_Div: u7 = 6 << 0;
    const TCON0_DCLK = TCON0_Dclk_En
        | TCON0_Dclk_Div;
    comptime{ assert(TCON0_DCLK == 0x80000006); }
    putreg32(TCON0_DCLK, TCON0_DCLK_REG);

    // TCON0_CTL_REG: TCON0 Offset 0x40 (A64 Page 512)
    // Set TCON0_En (Bit 31) to 1 (Enable TCON0)
    // Set TCON0_Work_Mode (Bit 28) to 0 (Normal Work Mode)
    // Set TCON0_IF (Bits 24 to 25) to 1 (8080 Interface)
    // Set TCON0_RB_Swap (Bit 23) to 0 (No Red/Blue Swap)
    // Set TCON0_FIFO1_Rst (Bit 21) to 0 (No FIFO1 Reset)
    // Set TCON0_Start_Delay (Bits 4 to 8) to 0 (No STA Delay)
    // Set TCON0_SRC_SEL (Bits 0 to 2) to 0 (TCON0 Source is DE0)
    const TCON0_CTL_REG = TCON0_BASE_ADDRESS + 0x40;
    comptime{ assert(TCON0_CTL_REG == 0x1c0c040); }

    const TCON0_En:          u32 = 1 << 31;
    const TCON0_Work_Mode:   u29 = 0 << 28;
    const TCON0_IF:          u26 = 1 << 24;
    const TCON0_RB_Swap:     u24 = 0 << 23;
    const TCON0_FIFO1_Rst:   u22 = 0 << 21;
    const TCON0_Start_Delay: u9  = 0 << 4;
    const TCON0_SRC_SEL:     u3  = 0 << 0;
    const TCON0_CTL = TCON0_En
        | TCON0_Work_Mode
        | TCON0_IF
        | TCON0_RB_Swap
        | TCON0_FIFO1_Rst
        | TCON0_Start_Delay
        | TCON0_SRC_SEL;
    comptime{ assert(TCON0_CTL == 0x81000000); }
    putreg32(TCON0_CTL, TCON0_CTL_REG);

    // TCON0_BASIC0_REG: TCON0 Offset 0x48 (A64 Page 514)
    // Set TCON0_X (Bits 16 to 27) to 719 (Panel Width - 1)
    // Set TCON0_Y (Bits 0 to 11) to 1439 (Panel Height - 1)
    const TCON0_BASIC0_REG = TCON0_BASE_ADDRESS + 0x48;
    comptime{ assert(TCON0_BASIC0_REG == 0x1c0c048); }

    const TCON0_X: u28 = (PANEL_WIDTH  - 1) << 16;
    const TCON0_Y: u12 = (PANEL_HEIGHT - 1) << 0;
    const TCON0_BASIC0 = TCON0_X
        | TCON0_Y;
    comptime{ assert(TCON0_BASIC0 == 0x2cf059f); }
    putreg32(TCON0_BASIC0, TCON0_BASIC0_REG);

    // TCON0_ECC_FIFO: TCON0 Offset 0xf8 (Undocumented)
    // Set to 8
    const TCON0_ECC_FIFO = TCON0_BASE_ADDRESS + 0xf8;
    comptime{ assert(TCON0_ECC_FIFO == 0x1c0c0f8); }
    putreg32(0x8, TCON0_ECC_FIFO);

    // TCON0_CPU_IF_REG: TCON0 Offset 0x60 (A64 Page 516)
    // Set CPU_Mode (Bits 28 to 31) to 1 (24-bit DSI)
    // Set AUTO (Bit 17) to 0 (Disable Auto Transfer Mode)
    // Set FLUSH (Bit 16) to 1 (Enable Direct Transfer Mode)
    // Set Trigger_FIFO_Bist_En (Bit 3) to 0 (Disable FIFO Bist Trigger)
    // Set Trigger_FIFO_En (Bit 2) to 1 (Enable FIFO Trigger)
    // Set Trigger_En (Bit 0) to 1 (Enable Trigger Mode)
    const TCON0_CPU_IF_REG = TCON0_BASE_ADDRESS + 0x60;
    comptime{ assert(TCON0_CPU_IF_REG == 0x1c0c060); }

    const CPU_Mode:             u32 = 1 << 28;
    const AUTO:                 u18 = 0 << 17;
    const FLUSH:                u17 = 1 << 16;
    const Trigger_FIFO_Bist_En: u4  = 0 << 3;
    const Trigger_FIFO_En:      u3  = 1 << 2;
    const Trigger_En:           u1  = 1 << 0;
    const TCON0_CPU_IF = CPU_Mode
        | AUTO
        | FLUSH
        | Trigger_FIFO_Bist_En
        | Trigger_FIFO_En
        | Trigger_En;
    comptime{ assert(TCON0_CPU_IF == 0x10010005); }
    putreg32(TCON0_CPU_IF, TCON0_CPU_IF_REG);

    // Set CPU Panel Trigger
    // TCON0_CPU_TRI0_REG: TCON0 Offset 0x160 (A64 Page 521)
    // Set Block_Space (Bits 16 to 27) to 47 (Block Space)
    // Set Block_Size (Bits 0 to 11) to 719 (Panel Width - 1)
    debug("Set CPU Panel Trigger", .{});
    const TCON0_CPU_TRI0_REG = TCON0_BASE_ADDRESS + 0x160;
    comptime{ assert(TCON0_CPU_TRI0_REG == 0x1c0c160); }

    const Block_Space: u28 = 47  << 16;  // TODO: Compute this based on Panel Width and Height 
    const Block_Size:  u12 = (PANEL_WIDTH - 1) << 0;
    const TCON0_CPU_TRI0 = Block_Space
        | Block_Size;
    comptime{ assert(TCON0_CPU_TRI0 == 0x2f02cf); }
    putreg32(TCON0_CPU_TRI0, TCON0_CPU_TRI0_REG);

    // TCON0_CPU_TRI1_REG: TCON0 Offset 0x164 (A64 Page 522)
    // Set Block_Current_Num (Bits 16 to 31) to 0 (Block Current Number)
    // Set Block_Num (Bits 0 to 15) to 1439 (Panel Height - 1)
    const TCON0_CPU_TRI1_REG = TCON0_BASE_ADDRESS + 0x164;
    comptime{ assert(TCON0_CPU_TRI1_REG == 0x1c0c164); }

    const Block_Current_Num: u32 = 0    << 16;
    const Block_Num:         u16 = (PANEL_HEIGHT - 1) << 0;
    const TCON0_CPU_TRI1 = Block_Current_Num
        | Block_Num;
    comptime{ assert(TCON0_CPU_TRI1 == 0x59f); }
    putreg32(TCON0_CPU_TRI1, TCON0_CPU_TRI1_REG);

    // TCON0_CPU_TRI2_REG: TCON0 Offset 0x168 (A64 Page 522)
    // Set Start_Delay (Bits 16 to 31) to 7106 (Start Delay)
    // Set Trans_Start_Mode (Bit 15) to 0 (Trans Start Mode is ECC FIFO + TRI FIFO)
    // Set Sync_Mode (Bits 13 to 14) to 0 (Sync Mode is Auto)
    // Set Trans_Start_Set (Bits 0 to 12) to 10 (Trans Start Set)
    const TCON0_CPU_TRI2_REG = TCON0_BASE_ADDRESS + 0x168;
    comptime{ assert(TCON0_CPU_TRI2_REG == 0x1c0c168); }

    const Start_Delay:      u32 = 7106 << 16;
    const Trans_Start_Mode: u16 = 0    << 15;
    const Sync_Mode:        u15 = 0    << 13;
    const Trans_Start_Set:  u13 = 10   << 0;
    const TCON0_CPU_TRI2 = Start_Delay
        | Trans_Start_Mode
        | Sync_Mode
        | Trans_Start_Set;
    comptime{ assert(TCON0_CPU_TRI2 == 0x1bc2000a); }
    putreg32(TCON0_CPU_TRI2, TCON0_CPU_TRI2_REG);

    // Set Safe Period
    // TCON_SAFE_PERIOD_REG: TCON0 Offset 0x1f0 (A64 Page 525)
    // Set Safe_Period_FIFO_Num (Bits 16 to 28) to 3000
    // Set Safe_Period_Line (Bits 4 to 15) to 0
    // Set Safe_Period_Mode (Bits 0 to 2) to 3 (Safe Period Mode: Safe at 2 and safe at sync active)
    debug("Set Safe Period", .{});
    const TCON_SAFE_PERIOD_REG = TCON0_BASE_ADDRESS + 0x1f0;
    comptime{ assert(TCON_SAFE_PERIOD_REG == 0x1c0c1f0); }

    const Safe_Period_FIFO_Num: u29 = 3000 << 16;
    const Safe_Period_Line:     u16 = 0    << 4;
    const Safe_Period_Mode:     u3  = 3    << 0;
    const TCON_SAFE_PERIOD = Safe_Period_FIFO_Num
        | Safe_Period_Line
        | Safe_Period_Mode;
    comptime{ assert(TCON_SAFE_PERIOD == 0xbb80003); }
    putreg32(TCON_SAFE_PERIOD, TCON_SAFE_PERIOD_REG);

    // Enable Output Triggers
    // TCON0_IO_TRI_REG: TCON0 Offset 0x8c (A64 Page 520)
    // Set Reserved (Bits 29 to 31) to 0b111
    // Set RGB_Endian (Bit 28) to 0 (Normal RGB Endian)
    // Set IO3_Output_Tri_En (Bit 27) to 0 (Enable IO3 Output Tri)
    // Set IO2_Output_Tri_En (Bit 26) to 0 (Enable IO2 Output Tri)
    // Set IO1_Output_Tri_En (Bit 25) to 0 (Enable IO1 Output Tri)
    // Set IO0_Output_Tri_En (Bit 24) to 0 (Enable IO0 Output Tri)
    // Set Data_Output_Tri_En (Bits 0 to 23) to 0 (Enable TCON0 Output Port)
    debug("Enable Output Triggers", .{});
    comptime{ assert(TCON0_IO_TRI_REG == 0x1c0c08c); }

    const Reserved:           u32 = 0b111 << 29;
    const RGB_Endian:         u29 = 0     << 28;
    const IO3_Output_Tri_En:  u28 = 0     << 27;
    const IO2_Output_Tri_En:  u27 = 0     << 26;
    const IO1_Output_Tri_En:  u26 = 0     << 25;
    const IO0_Output_Tri_En:  u25 = 0     << 24;
    const Data_Output_Tri_En: u24 = 0     << 0;
    const TCON0_IO_TRI = Reserved
        | RGB_Endian
        | IO3_Output_Tri_En
        | IO2_Output_Tri_En
        | IO1_Output_Tri_En
        | IO0_Output_Tri_En
        | Data_Output_Tri_En;
    comptime{ assert(TCON0_IO_TRI == 0xe0000000); }
    putreg32(TCON0_IO_TRI, TCON0_IO_TRI_REG);  // TODO: DMB

    // Enable TCON0
    // TCON_GCTL_REG: TCON0 Offset 0x00 (A64 Page 508)
    // Set TCON_En (Bit 31) to 1 (Enable TCON0)
    debug("Enable TCON0", .{});
    comptime{ assert(TCON_GCTL_REG == 0x1c0c000); }
    {
        const TCON_En: u32 = 1 << 31;
        const TCON_GCTL = TCON_En;
        comptime{ assert(TCON_GCTL == 0x80000000); }
        modreg32(TCON_GCTL, TCON_GCTL, TCON_GCTL_REG);  // TODO: DMB
    }
}

/// Modify the specified bits in a memory mapped register.
/// Based on https://github.com/apache/nuttx/blob/master/arch/arm64/src/common/arm64_arch.h#L473
fn modreg32(
    comptime val: u32,   // Bits to set, like (1 << bit)
    comptime mask: u32,  // Bits to clear, like (1 << bit)
    addr: u64  // Address to modify
) void {
    comptime { assert(val & mask == val); }
    debug("  *0x{x}: clear 0x{x}, set 0x{x}", .{ addr, mask, val & mask });
    putreg32(
        (getreg32(addr) & ~(mask))
            | ((val) & (mask)),
        (addr)
    );
}

/// Get the 32-bit value at the address
fn getreg32(addr: u64) u32 {
    const ptr = @intToPtr(*const volatile u32, addr);
    return ptr.*;
}

/// Set the 32-bit value at the address
fn putreg32(val: u32, addr: u64) void {
    if (enableLog) { debug("  *0x{x} = 0x{x}", .{ addr, val }); }
    const ptr = @intToPtr(*volatile u32, addr);
    ptr.* = val;
}

/// Set to False to disable log 
var enableLog = true;

///////////////////////////////////////////////////////////////////////////////
//  Panic Handler

/// Called by Zig when it hits a Panic. We print the Panic Message, Stack Trace and halt. See 
/// https://andrewkelley.me/post/zig-stack-traces-kernel-panic-bare-bones-os.html
/// https://github.com/ziglang/zig/blob/master/lib/std/builtin.zig#L763-L847
pub fn panic(
    message: []const u8, 
    _stack_trace: ?*std.builtin.StackTrace
) noreturn {
    // Print the Panic Message
    _ = _stack_trace;
    _ = puts("\n!ZIG PANIC!");
    _ = puts(@ptrCast([*c]const u8, message));

    // Print the Stack Trace
    _ = puts("Stack Trace:");
    var it = std.debug.StackIterator.init(@returnAddress(), null);
    while (it.next()) |return_address| {
        _ = printf("%p\n", return_address);
    }

    // Halt
    c.exit(1);
}

///////////////////////////////////////////////////////////////////////////////
//  Logging

/// Called by Zig for `std.log.debug`, `std.log.info`, `std.log.err`, ...
/// https://gist.github.com/leecannon/d6f5d7e5af5881c466161270347ce84d
pub fn log(
    comptime _message_level: std.log.Level,
    comptime _scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = _message_level;
    _ = _scope;

    // Format the message
    var buf: [100]u8 = undefined;  // Limit to 100 chars
    var slice = std.fmt.bufPrint(&buf, format, args)
        catch { _ = puts("*** log error: buf too small"); return; };
    
    // Terminate the formatted message with a null
    var buf2: [buf.len + 1 : 0]u8 = undefined;
    std.mem.copy(
        u8, 
        buf2[0..slice.len], 
        slice[0..slice.len]
    );
    buf2[slice.len] = 0;

    // Print the formatted message
    _ = puts(&buf2);
}

///////////////////////////////////////////////////////////////////////////////
//  Imported Functions and Variables

/// For safety, we import these functions ourselves to enforce Null-Terminated Strings.
/// We changed `[*c]const u8` to `[*:0]const u8`
extern fn printf(format: [*:0]const u8, ...) c_int;
extern fn puts(str: [*:0]const u8) c_int;

/// Aliases for Zig Standard Library
const assert = std.debug.assert;
const debug  = std.log.debug;
