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

//! PinePhone Display Backlight Driver for Apache NuttX RTOS
//! See https://lupyuen.github.io/articles/de#appendix-display-backlight
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

// PIO Base Address (CPUx-PORT) (A64 Page 376)
const PIO_BASE_ADDRESS = 0x01C2_0800;

// PWM Base Address (CPUx-PWM?) (A64 Page 194)
const PWM_BASE_ADDRESS = 0x01C2_1400;

// R_PIO Base Address (CPUs-PORT) (A64 Page 410)
const R_PIO_BASE_ADDRESS = 0x01F0_2C00;

// R_PWM Base Address (CPUs-PWM?) (CPUs Domain, A64 Page 256)
const R_PWM_BASE_ADDRESS = 0x01F0_3800;

/// Turn on PinePhone Display Backlight.
/// Based on https://lupyuen.github.io/articles/de#appendix-display-backlight
pub export fn backlight_enable(
    percent: u32  // Percent brightness
) void {
    debug("backlight_enable: start, percent={}", .{ percent });
    defer { debug("backlight_enable: end", .{}); }

    // Configure PL10 for PWM
    // Register PL_CFG1 (Port L Configure Register 1)
    // At R_PIO Offset 4 (A64 Page 412)
    // Set PL10_SELECT (Bits 8 to 10) to 2 (S_PWM)
    const PL_CFG1 = R_PIO_BASE_ADDRESS + 4;
    comptime { assert(PL_CFG1 == 0x1f02c04); }
    modreg32(2 << 8, 0b111 << 8, PL_CFG1);

    // Disable R_PWM (Undocumented)
    // Register R_PWM_CTRL_REG? (R_PWM Control Register?)
    // At R_PWM Offset 0 (A64 Page 194)
    // Set SCLK_CH0_GATING (Bit 6) to 0 (Mask)
    const R_PWM_CTRL_REG = R_PWM_BASE_ADDRESS + 0;
    comptime { assert(R_PWM_CTRL_REG == 0x1f03800); }
    modreg32(0, 1 << 6, R_PWM_CTRL_REG);

    // Configure R_PWM Period (Undocumented)
    // Register R_PWM_CH0_PERIOD? (R_PWM Channel 0 Period Register?)
    // At R_PWM Offset 4 (A64 Page 195)
    // PWM_CH0_ENTIRE_CYS (Upper 16 Bits) = Period (0x4af)
    // PWM_CH0_ENTIRE_ACT_CYS (Lower 16 Bits) = Period * Percent / 100 (0x0437)
    // Period = 0x4af (1199)
    // Percent = 0x5a
    const R_PWM_CH0_PERIOD = R_PWM_BASE_ADDRESS + 4;
    comptime { assert(R_PWM_CH0_PERIOD == 0x1f03804); }
    const PERIOD = 0x4af;
    const PERCENT = 0x5a;
    const PWM_CH0_ENTIRE_CYS: u32 = PERIOD << 16;
    const PWM_CH0_ENTIRE_ACT_CYS: u16 = PERIOD * PERCENT / 100;
    const val = PWM_CH0_ENTIRE_CYS 
        | PWM_CH0_ENTIRE_ACT_CYS;
    comptime { assert(val == 0x4af0437); }
    putreg32(val, R_PWM_CH0_PERIOD);
    assert(percent == PERCENT);

    // Enable R_PWM (Undocumented)
    // Register R_PWM_CTRL_REG? (R_PWM Control Register?)
    // At R_PWM Offset 0 (A64 Page 194)
    // Set SCLK_CH0_GATING (Bit 6) to 1 (Pass)
    // Set PWM_CH0_EN (Bit 4) to 1 (Enable)
    // Set PWM_CH0_PRESCAL (Bits 0 to 3) to 0b1111 (Prescalar 1)
    comptime { assert(R_PWM_CTRL_REG == 0x1f03800); }
    const SCLK_CH0_GATING: u7 = 1 << 6;
    const PWM_CH0_EN:      u5 = 1 << 4;
    const PWM_CH0_PRESCAL: u4 = 0b1111 << 0;
    const ctrl = SCLK_CH0_GATING
        | PWM_CH0_EN
        | PWM_CH0_PRESCAL;
    comptime { assert(ctrl == 0x5f); }
    putreg32(ctrl, R_PWM_CTRL_REG);

    // Configure PH10 for Output
    // Register PH_CFG1 (PH Configure Register 1)
    // At PIO Offset 0x100 (A64 Page 401)
    // Set PH10_SELECT (Bits 8 to 10) to 1 (Output)
    const PH_CFG1 = PIO_BASE_ADDRESS + 0x100;
    comptime { assert(PH_CFG1 == 0x1c20900); }
    const PH10_SELECT: u11 = 1 << 8;
    const PH10_MASK:   u11 = 0b111 << 8;
    comptime { assert(PH10_SELECT == 0x100); }
    comptime { assert(PH10_MASK   == 0x700); }
    modreg32(PH10_SELECT, PH10_MASK, PH_CFG1);

    // Set PH10 to High
    // Register PH_DATA (PH Data Register)
    // At PIO Offset 0x10C (A64 Page 403)
    // Set PH10 (Bit 10) to 1 (High)
    const PH_DATA = PIO_BASE_ADDRESS + 0x10C;
    comptime { assert(PH_DATA == 0x1c2090c); }
    const PH10: u11 = 1 << 10;
    modreg32(PH10, PH10, PH_DATA);
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
