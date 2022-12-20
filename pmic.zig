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

//! PinePhone Power Management IC Driver for Apache NuttX RTOS
//! See https://lupyuen.github.io/articles/de#appendix-power-management-integrated-circuit
//! "A64 Page ???" refers to Allwinner A64 User Manual: https://github.com/lupyuen/pinephone-nuttx/releases/download/doc/Allwinner_A64_User_Manual_V1.1.pdf
//! "A80 Page ???" refers to Allwinner A80 User Manual: https://github.com/lupyuen/pinephone-nuttx/releases/download/doc/A80_User_Manual_v1.3.1_20150513.pdf
//! "AXP803 Page ???" refers to X-Powers AXP803 PMIC Datasheet: https://files.pine64.org/doc/datasheet/pine64/AXP803_Datasheet_V1.0.pdf

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

/// PIO Base Address (CPUx-PORT) (A64 Page 376)
const PIO_BASE_ADDRESS = 0x01C2_0800;

/// Address of AXP803 PMIC on Reduced Serial Bus
const AXP803_RT_ADDR = 0x2d;

/// Reduced Serial Bus Base Address (R_RSB) (A64 Page 75)
const R_RSB_BASE_ADDRESS = 0x01f03400;

/// Reduced Serial Bus Offsets (A80 Page 922)
const RSB_CTRL   = 0x00;  // RSB Control Register
const RSB_STAT   = 0x0c;  // RSB Status Register
const RSB_AR     = 0x10;  // RSB Address Register
const RSB_DATA   = 0x1c;  // RSB Data Buffer Register
const RSB_CMD    = 0x2c;  // RSB Command Register
const RSB_DAR    = 0x30;  // RSB Device Address Register

/// Read a byte from Reduced Serial Bus (A80 Page 918)
const RSBCMD_RD8 = 0x8B;

/// Write a byte to Reduced Serial Bus (A80 Page 918)
const RSBCMD_WR8 = 0x4E;

/// Init Display Board.
/// Based on https://lupyuen.github.io/articles/de#appendix-power-management-integrated-circuit
pub export fn display_board_init() void {
    debug("display_board_init: start", .{});
    defer { debug("display_board_init: end", .{}); }

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
    debug("Configure PD23 for Output", .{});
    const PD_CFG2_REG = PIO_BASE_ADDRESS + 0x74;
    comptime { assert(PD_CFG2_REG == 0x1c20874); }
    const PD23_SELECT: u31 = 0b001 << 28;
    const PD23_MASK:   u31 = 0b111 << 28;
    comptime { assert(PD23_SELECT == 0x10000000); }
    comptime { assert(PD23_MASK   == 0x70000000); }
    modreg32(PD23_SELECT, PD23_MASK, PD_CFG2_REG);  // TODO: DMB

    // Set PD23 to Low
    // Register PD_DATA_REG (PD Data Register)
    // At PIO Offset 0x7C (A64 Page 388)
    // Set PD23 (Bit 23) to 0 (Low)
    // sunxi_gpio_output: pin=0x77, val=0
    //   before: 0x1c2087c = 0x1c0000
    //   after: 0x1c2087c = 0x1c0000 (DMB)
    debug("Set PD23 to Low", .{});
    const PD_DATA_REG = PIO_BASE_ADDRESS + 0x7C;
    comptime { assert(PD_DATA_REG == 0x1c2087c); }
    const PD23: u24 = 1 << 23;
    modreg32(0, PD23, PD_DATA_REG);  // TODO: DMB

    // Set DLDO1 Voltage to 3.3V
    // DLDO1 powers the Front Camera / USB HSIC / I2C Sensors
    // Register 0x15: DLDO1 Voltage Control (AXP803 Page 52)
    // Set Voltage (Bits 0 to 4) to 26 (2.6V + 0.7V = 3.3V)
    debug("Set DLDO1 Voltage to 3.3V", .{});
    const DLDO1_Voltage_Control = 0x15;
    const DLDO1_Voltage: u5 = 26 << 0;
    const ret1 = pmic_write(DLDO1_Voltage_Control, DLDO1_Voltage);
    assert(ret1 == 0);

    // Power on DLDO1
    // Register 0x12: Output Power On-Off Control 2 (AXP803 Page 51)
    // Set DLDO1 On-Off Control (Bit 3) to 1 (Power On)
    const Output_Power_On_Off_Control2 = 0x12;
    const DLDO1_On_Off_Control: u4 = 1 << 3;
    const ret2 = pmic_clrsetbits(Output_Power_On_Off_Control2, 0, DLDO1_On_Off_Control);
    assert(ret2 == 0);

    // Set LDO Voltage to 3.3V
    // GPIO0LDO powers the Capacitive Touch Panel
    // Register 0x91: GPIO0LDO and GPIO0 High Level Voltage Setting (AXP803 Page 77)
    // Set GPIO0LDO and GPIO0 High Level Voltage (Bits 0 to 4) to 26 (2.6V + 0.7V = 3.3V)
    debug("Set LDO Voltage to 3.3V", .{});
    const GPIO0LDO_High_Level_Voltage_Setting = 0x91;
    const GPIO0LDO_High_Level_Voltage: u5 = 26 << 0;
    const ret3 = pmic_write(GPIO0LDO_High_Level_Voltage_Setting, GPIO0LDO_High_Level_Voltage);
    assert(ret3 == 0);

    // Enable LDO Mode on GPIO0
    // Register 0x90: GPIO0 (GPADC) Control (AXP803 Page 76)
    // Set GPIO0 Pin Function Control (Bits 0 to 2) to 0b11 (Low Noise LDO on)
    debug("Enable LDO mode on GPIO0", .{});
    const GPIO0_Control = 0x90;
    const GPIO0_Pin_Function: u3 = 0b11 << 0;
    const ret4 = pmic_write(GPIO0_Control, GPIO0_Pin_Function);
    assert(ret4 == 0);

    // Set DLDO2 Voltage to 1.8V
    // DLDO2 powers the MIPI DSI Connector
    // Register 0x16: DLDO2 Voltage Control (AXP803 Page 52)
    // Set Voltage (Bits 0 to 4) to 11 (1.1V + 0.7V = 1.8V)
    debug("Set DLDO2 Voltage to 1.8V", .{});
    const DLDO2_Voltage_Control = 0x16;
    const DLDO2_Voltage: u5 = 11 << 0;
    const ret5 = pmic_write(DLDO2_Voltage_Control, DLDO2_Voltage);
    assert(ret5 == 0);

    // Power on DLDO2
    // Register 0x12: Output Power On-Off Control 2 (AXP803 Page 51)
    // Set DLDO2 On-Off Control (Bit 4) to 1 (Power On)
    comptime { assert(Output_Power_On_Off_Control2 == 0x12); }
    const DLDO2: u5 = 1 << 4;
    const ret6 = pmic_clrsetbits(Output_Power_On_Off_Control2, 0x0, DLDO2);
    assert(ret6 == 0);

    // Wait for power supply and power-on init
    debug("Wait for power supply and power-on init", .{});
    _ = c.usleep(15000);
}

/// Write value to PMIC Register
fn pmic_write(
    reg: u8,
    val: u8
) i32 {
    // Write to AXP803 PMIC on Reduced Serial Bus
    debug("  pmic_write: reg=0x{x}, val=0x{x}", .{ reg, val });
    const ret = rsb_write(AXP803_RT_ADDR, reg, val);
    if (ret != 0) { debug("  pmic_write Error: ret={}", .{ ret }); }
    return ret;
}

/// Read value from PMIC Register
fn pmic_read(
    reg_addr: u8
) i32 {
    // Read from AXP803 PMIC on Reduced Serial Bus
    debug("  pmic_read: reg_addr=0x{x}", .{ reg_addr });
    const ret = rsb_read(AXP803_RT_ADDR, reg_addr);
    if (ret < 0) { debug("  pmic_read Error: ret={}", .{ ret }); }
    return ret;
}

/// Clear and Set the PMIC Register Bits
fn pmic_clrsetbits(
    reg: u8, 
    clr_mask: u8, 
    set_mask: u8
) i32 {
    // Read from AXP803 PMIC on Reduced Serial Bus
    debug("  pmic_clrsetbits: reg=0x{x}, clr_mask=0x{x}, set_mask=0x{x}", .{ reg, clr_mask, set_mask });
    const ret = rsb_read(AXP803_RT_ADDR, reg);
    if (ret < 0) { return ret; }

    // Write to AXP803 PMIC on Reduced Serial Bus
    const regval = (@intCast(u8, ret) & ~clr_mask) | set_mask;
    return rsb_write(AXP803_RT_ADDR, reg, regval);
}

/// Read a byte from Reduced Serial Bus.
/// Returns -1 on error.
fn rsb_read(
    rt_addr: u8,
    reg_addr: u8
) i32 {
    // RSB Command Register (RSB_CMD) (A80 Page 928)
    // At RSB Offset 0x002C
    // Set to 0x8B (RD8) to read one byte
    debug("  rsb_read: rt_addr=0x{x}, reg_addr=0x{x}", .{ rt_addr, reg_addr });
    putreg32(RSBCMD_RD8, R_RSB_BASE_ADDRESS + RSB_CMD);   // TODO: DMB

    // RSB Device Address Register (RSB_DAR) (A80 Page 928)
    // At RSB Offset 0x0030
    // Set RTA (Bits 16 to 23) to the Run-Time Address (0x2D for AXP803 PMIC)
    const rt_addr_shift: u32 = @intCast(u32, rt_addr) << 16;
    putreg32(rt_addr_shift, R_RSB_BASE_ADDRESS + RSB_DAR);   // TODO: DMB

    // RSB Address Register (RSB_AR) (A80 Page 926)
    // At RSB Offset 0x0010
    // Set to the Register Address that we’ll read from AXP803 PMIC
    putreg32(reg_addr, R_RSB_BASE_ADDRESS + RSB_AR);    // TODO: DMB

    // RSB Control Register (RSB_CTRL) (A80 Page 923)
    // At RSB Offset 0x0000
    // Set START_TRANS (Bit 7) to 1 (Start Transaction)
    putreg32(0x80, R_RSB_BASE_ADDRESS + RSB_CTRL);  // TODO: DMB

    // Wait for RSB Status
    const ret = rsb_wait_stat("Read RSB");
    if (ret != 0) { return ret; }

    // RSB Data Buffer Register (RSB_DATA) (A80 Page 926)
    // At RSB Offset 0x001c
    // Contains the Register Value read from AXP803 PMIC
    return getreg8(R_RSB_BASE_ADDRESS + RSB_DATA);
}

/// Write a byte to Reduced Serial Bus.
/// Returns -1 on error.
fn rsb_write(
    rt_addr: u8, 
    reg_addr: u8, 
    value: u8
) i32 {
    // RSB Command Register (RSB_CMD) (A80 Page 928)
    // At RSB Offset 0x002C
    // Set to 0x4E (WR8) to write one byte
    debug("  rsb_write: rt_addr=0x{x}, reg_addr=0x{x}, value=0x{x}", .{ rt_addr, reg_addr, value });
    putreg32(RSBCMD_WR8, R_RSB_BASE_ADDRESS + RSB_CMD);   // TODO: DMB

    // RSB Device Address Register (RSB_DAR) (A80 Page 928)
    // At RSB Offset 0x0030
    // Set RTA (Bits 16 to 23) to the Run-Time Address (0x2D for AXP803 PMIC)
    const rt_addr_shift: u32 = @intCast(u32, rt_addr) << 16;
    putreg32(rt_addr_shift, R_RSB_BASE_ADDRESS + RSB_DAR);   // TODO: DMB

    // RSB Address Register (RSB_AR) (A80 Page 926)
    // At RSB Offset 0x0010
    // Set to the Register Address that we’ll write to AXP803 PMIC
    putreg32(reg_addr, R_RSB_BASE_ADDRESS + RSB_AR);    // TODO: DMB

    // RSB Data Buffer Register (RSB_DATA) (A80 Page 926)
    // At RSB Offset 0x001c
    // Set to the Register Value that will be written to AXP803 PMIC
    putreg32(value, R_RSB_BASE_ADDRESS + RSB_DATA);  // TODO: DMB

    // RSB Control Register (RSB_CTRL) (A80 Page 923)
    // At RSB Offset 0x0000
    // Set START_TRANS (Bit 7) to 1 (Start Transaction)
    putreg32(0x80, R_RSB_BASE_ADDRESS + RSB_CTRL);  // TODO: DMB

    // Wait for RSB Status
    return rsb_wait_stat("Write RSB");
}

/// Wait for Reduced Serial Bus and read Status.
/// Returns -1 on error.
fn rsb_wait_stat(
    desc: []const u8
) i32 {
    // RSB Control Register (RSB_CTRL) (A80 Page 923)
    // At RSB Offset 0x0000
    // Wait for START_TRANS (Bit 7) to be 0 (Transaction Completed or Error)
    const ret = rsb_wait_bit(desc, RSB_CTRL, 1 << 7);
    if (ret != 0) {
        debug("rsb_wait_stat Timeout ({s})", .{ desc });
        return ret;
    }

    // RSB Status Register (RSB_STAT) (A80 Page 924)
    // At RSB Offset 0x000c
    // If TRANS_OVER (Bit 0) is 1, then RSB Transfer has completed without error
    const reg = getreg32(R_RSB_BASE_ADDRESS + RSB_STAT);
    if (reg == 0x01) { return 0; }

    debug("rsb_wait_stat Error ({s}): 0x{x}", .{ desc, reg });
    return -1;
}

/// Wait for Reduced Serial Bus Transaction to complete.
/// Returns -1 on error.
/// `offset` is RSB_CTRL
/// `mask`   is 1 << 7
fn rsb_wait_bit(
    desc: []const u8,
    offset: u32, 
    mask: u32
) i32 {
    // Wait for transaction to complete
    var tries: u32 = 100000;
    while (true) {
        // RSB Control Register (RSB_CTRL) (A80 Page 923)
        // At RSB Offset 0x0000
        // Wait for START_TRANS (Bit 7) to be 0 (Transaction Completed or Error)
        // `offset` is RSB_CTRL
        // `mask`   is 1 << 7
        const reg = getreg32(R_RSB_BASE_ADDRESS + offset); 
        if (reg & mask == 0) { break; }

        // Check for transaction timeout
        tries -= 1;
        if (tries == 0) {
            debug("rsb_wait_bit Timeout ({s})", .{ desc });
            return -1;
        }
    }
    return 0;
}

/// Modify the specified bits in a memory mapped register.
/// Note: Parameters are different from modifyreg32
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

/// Get the 8-bit value at the address
fn getreg8(addr: u64) u8 {
    const ptr = @intToPtr(*const volatile u8, addr);
    return ptr.*;
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
