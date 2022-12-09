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

//! PinePhone LCD Panel Driver for Apache NuttX RTOS
//! See https://lupyuen.github.io/articles/de#appendix-reset-lcd-panel
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

/// PIO Base Address (CPUx-PORT) (A64 Page 376)
const PIO_BASE_ADDRESS = 0x01C2_0800;

/// Reset LCD Panel.
/// Based on https://lupyuen.github.io/articles/de#appendix-reset-lcd-panel
pub export fn panel_reset() void {
    debug("panel_reset: start", .{});
    defer { debug("panel_reset: end", .{}); }

    // Reset LCD Panel at PD23 (Active Low)
    // deassert reset: GPD(23), 1  // PD23 - LCD-RST (active low)

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

    // Set PD23 to High
    // Register PD_DATA_REG (PD Data Register)
    // At PIO Offset 0x7C (A64 Page 388)
    // Set PD23 (Bit 23) to 1 (High)
    // sunxi_gpio_output: pin=0x77, val=1
    //   before: 0x1c2087c = 0x1c0000
    //   after: 0x1c2087c = 0x9c0000 (DMB)
    debug("Set PD23 to High", .{});
    const PD_DATA_REG = PIO_BASE_ADDRESS + 0x7C;
    comptime { assert(PD_DATA_REG == 0x1c2087c); }
    const PD23: u24 = 1 << 23;
    modreg32(PD23, PD23, PD_DATA_REG);  // TODO: DMB

    // wait for initialization
    // udelay 15000    
    debug("wait for initialization", .{});
    _ = c.usleep(15000);
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
