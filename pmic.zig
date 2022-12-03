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
//! See https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#display_board_init
//! "A64 Page ???" refers to Allwinner A64 User Manual: https://linux-sunxi.org/images/b/b4/Allwinner_A64_User_Manual_V1.1.pdf

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

/// Reduced Serial Bus Base Address
const R_RSB_BASE_ADDRESS = 0x01f03400;

/// Reduced Serial Bus Offsets
const RSB_CTRL   = 0x00;
const RSB_STAT   = 0x0c;
const RSB_DADDR0 = 0x10;
const RSB_DATA0  = 0x1c;
const RSB_CMD    = 0x2c;
const RSB_SADDR  = 0x30;

/// Read a byte from Reduced Serial Bus
const RSBCMD_RD8 = 0x8B;

/// Write a byte to Reduced Serial Bus
const RSBCMD_WR8 = 0x4E;

/// Init Display Board.
/// Based on https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#display_board_init
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
    const PD_DATA_REG = PIO_BASE_ADDRESS + 0x7C;
    comptime { assert(PD_DATA_REG == 0x1c2087c); }
    const PD23: u24 = 1 << 23;
    modreg32(0, PD23, PD_DATA_REG);  // TODO: DMB

    {
        // Set DLDO1 Voltage to 3.3V
        //   pmic_write: reg=0x15, val=0x1a
        //   rsb_write: rt_addr=0x2d, reg_addr=0x15, value=0x1a
        const ret = pmic_write(0x15, 0x1a);
        assert(ret == 0);
    }
    {
        //   pmic_clrsetbits: reg=0x12, clr_mask=0x0, set_mask=0x8
        //   rsb_read: rt_addr=0x2d, reg_addr=0x12
        //   rsb_write: rt_addr=0x2d, reg_addr=0x12, value=0xd9
        const ret = pmic_clrsetbits(0x12, 0, 1 << 3);
        assert(ret == 0);
    }
    {
        // Set LDO Voltage to 3.3V
        //   pmic_write: reg=0x91, val=0x1a
        //   rsb_write: rt_addr=0x2d, reg_addr=0x91, value=0x1a
        const ret = pmic_write(0x91, 0x1a);
        assert(ret == 0);
    }
    {
        // Enable LDO mode on GPIO0
        //   pmic_write: reg=0x90, val=0x3
        //   rsb_write: rt_addr=0x2d, reg_addr=0x90, value=0x3
        const ret = pmic_write(0x90, 0x03);
        assert(ret == 0);
    }
    {
        // Set DLDO2 Voltage to 1.8V
        //   pmic_write: reg=0x16, val=0xb
        //   rsb_write: rt_addr=0x2d, reg_addr=0x16, value=0xb
        const ret = pmic_write(0x16, 0x0b);
        if (ret != 0) { debug("ret={}", .{ ret }); }
        assert(ret == 0);
    }
    {
        //   pmic_clrsetbits: reg=0x12, clr_mask=0x0, set_mask=0x10
        //   rsb_read: rt_addr=0x2d, reg_addr=0x12
        //   rsb_write: rt_addr=0x2d, reg_addr=0x12, value=0xd9
        const ret = pmic_clrsetbits(0x12, 0x0, 1 << 4);
        assert(ret == 0);
    }

    // Wait for power supply and power-on init
    _ = c.usleep(15000);
}

/// Write value to PMIC Register
fn pmic_write(
    reg: u8,
    val: u8
) i32 {
    debug("  pmic_write: reg=0x{x}, val=0x{x}", .{ reg, val });
    const ret = rsb_write(AXP803_RT_ADDR, reg, val);
    if (ret != 0) { debug("  pmic_write Error: ret={}", .{ ret }); }
    return ret;
}

/// Read value from PMIC Register
fn pmic_read(
    reg_addr: u8
) i32 {
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
    debug("  pmic_clrsetbits: reg=0x{x}, clr_mask=0x{x}, set_mask=0x{x}", .{ reg, clr_mask, set_mask });
    const ret = rsb_read(AXP803_RT_ADDR, reg);
    if (ret < 0) { return ret; }

    const regval = (@intCast(u8, ret) & ~clr_mask) | set_mask;
    return rsb_write(AXP803_RT_ADDR, reg, regval);
}

/// Write a byte to Reduced Serial Bus
fn rsb_read(
    rt_addr: u8,
    reg_addr: u8
) i32 {
    // Read a byte
    debug("  rsb_read: rt_addr=0x{x}, reg_addr=0x{x}", .{ rt_addr, reg_addr });
    const rt_addr_shift: u32 = @intCast(u32, rt_addr) << 16;
    putreg32(RSBCMD_RD8,    R_RSB_BASE_ADDRESS + RSB_CMD);     // TODO: DMB
    putreg32(rt_addr_shift, R_RSB_BASE_ADDRESS + RSB_SADDR);   // TODO: DMB
    putreg32(reg_addr,      R_RSB_BASE_ADDRESS + RSB_DADDR0);  // TODO: DMB

    // Start transaction
    putreg32(0x80,          R_RSB_BASE_ADDRESS + RSB_CTRL);    // TODO: DMB
    const ret = rsb_wait_stat("Read RSB");
    if (ret != 0) { return ret; }
    return getreg8(R_RSB_BASE_ADDRESS + RSB_DATA0);
}

/// Read a byte from Reduced Serial Bus
fn rsb_write(
    rt_addr: u8, 
    reg_addr: u8, 
    value: u8
) i32 {
    // Write a byte
    debug("  rsb_write: rt_addr=0x{x}, reg_addr=0x{x}, value=0x{x}", .{ rt_addr, reg_addr, value });
    const rt_addr_shift: u32 = @intCast(u32, rt_addr) << 16;
    putreg32(RSBCMD_WR8,    R_RSB_BASE_ADDRESS + RSB_CMD);     // TODO: DMB
    putreg32(rt_addr_shift, R_RSB_BASE_ADDRESS + RSB_SADDR);   // TODO: DMB
    putreg32(reg_addr,      R_RSB_BASE_ADDRESS + RSB_DADDR0);  // TODO: DMB
    putreg32(value,         R_RSB_BASE_ADDRESS + RSB_DATA0);   // TODO: DMB

    // Start transaction
    putreg32(0x80,          R_RSB_BASE_ADDRESS + RSB_CTRL);    // TODO: DMB
    return rsb_wait_stat("Write RSB");
}

/// Wait for Reduced Serial Bus and read Status
fn rsb_wait_stat(
    desc: []const u8
) i32 {
    const ret = rsb_wait_bit(desc, RSB_CTRL, 1 << 7);
    if (ret != 0) {
        debug("rsb_wait_stat Timeout ({s})", .{ desc });
        return ret;
    }

    const reg = getreg32(R_RSB_BASE_ADDRESS + RSB_STAT);
    if (reg == 0x01) { return 0; }

    debug("rsb_wait_stat Error ({s}): 0x{x}", .{ desc, reg });
    return -1;
}

/// Wait for Reduced Serial Bus Transaction to complete
fn rsb_wait_bit(
    desc: []const u8,
    offset: u32, 
    mask: u32
) i32 {
    // Wait for transaction to complete
    var tries: u32 = 100000;
    while (true) {
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
