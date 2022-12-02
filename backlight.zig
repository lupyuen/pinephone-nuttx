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

    //// TODO

    // Configure PL10 for PWM

    // Register PL_CFG1 (Port L Configure Register 1)
    // At R_PIO Offset 4 (A64 Page 412)
    // Set PL10_SELECT (Bits 8 to 10) to 2 (S_PWM)

    // backlight_enable: pct=0x5a
    // 1.0 has incorrectly documented non-presence of PH10, the circuit is in fact the same as on 1.1+
    // configure pwm: GPL(10), GPL_R_PWM
    // sunxi_gpio_set_cfgpin: pin=0x16a, val=2
    // sunxi_gpio_set_cfgbank: bank_offset=362, val=2
    // clrsetbits 0x1f02c04, 0xf00, 0x200

    // Disable R_PWM (Undocumented)

    // Register R_PWM_CTRL_REG? (R_PWM Control Register?)
    // At R_PWM Offset 0 (A64 Page 194)
    // Clear 0x40: SCLK_CH0_GATING (0=mask)
    // clrbits 0x1f03800, 0x40

    // Configure R_PWM Period (Undocumented)

    // Register R_PWM_CH0_PERIOD? (R_PWM Channel 0 Period Register?)
    // At R_PWM Offset 4 (A64 Page 195)
    // PWM_CH0_ENTIRE_CYS (Upper 16 Bits) = Period (0x4af)
    // PWM_CH0_ENTIRE_ACT_CYS (Lower 16 Bits) = Period * Percent / 100 (0x0437)
    // Period = 0x4af (1199)
    // Percent = 0x5a

    // 0x1f03804 = 0x4af0437

    // Enable R_PWM (Undocumented)

    // Register R_PWM_CTRL_REG? (R_PWM Control Register?)
    // At R_PWM Offset 0 (A64 Page 194)
    // 0x5f = SCLK_CH0_GATING (1=pass) + PWM_CH0_EN (1=enable) + PWM_CH0_PRESCAL (Prescalar 1)

    // 0x1f03800 = 0x5f

    // Configure PH10 for Output

    // Register PH_CFG1 (PH Configure Register 1)
    // At PIO Offset 0x100 (A64 Page 401)
    // Set PH10_SELECT (Bits 8 to 10) to 1 (Output)

    // enable backlight: GPH(10), 1
    // sunxi_gpio_set_cfgpin: pin=0xea, val=1
    // sunxi_gpio_set_cfgbank: bank_offset=234, val=1
    // clrsetbits 0x1c20900, 0xf00, 0x100
    // TODO: Should 0xf00 be 0x700 instead?

    // Set PH10 to High

    // Register PH_DATA (PH Data Register)
    // At PIO Offset 0x10C (A64 Page 403)
    // Set PH10 (Bit 10) to 1 (High)

    // sunxi_gpio_output: pin=0xea, val=1
    // TODO: Set Bit 10 of PH_DATA (0x1c2090c)
}

/// Modify the specified bits in a memory mapped register.
/// Note: Parameters are different from modifyreg32
/// Based on https://github.com/apache/nuttx/blob/master/arch/arm64/src/common/arm64_arch.h#L473
fn modreg32(
    val: u32,   // Bits to set, like (1 << bit)
    mask: u32,  // Bits to clear, like (1 << bit)
    addr: u64   // Address to modify
) void {
    debug("  0x{x}: clear 0x{x}, set 0x{x}", .{ addr, mask, val & mask });
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
    const ptr = @intToPtr(*volatile u32, addr);
    ptr.* = val;
}

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
