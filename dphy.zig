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

//! PinePhone Allwinner A64 MIPI DPHY (Display Physical Layer) Driver for Apache NuttX RTOS
//! See https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#dphy_enable
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

/// Enable MIPI Display Physical Layer (DPHY).
/// Based on https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#dphy_enable
pub export fn dphy_enable() void {
    debug("dphy_enable: start", .{});
    defer { debug("dphy_enable: end", .{}); }

    // TODO: Decode addresses and values

    // 150MHz (600 / 4)
    //   0x1c20168 = 0x8203 (DMB)
    //   0x1ca1004 = 0x10000000 (DMB)
    //   0x1ca1010 = 0xa06000e (DMB)
    //   0x1ca1014 = 0xa033207 (DMB)
    //   0x1ca1018 = 0x1e (DMB)
    debug("150MHz (600 / 4)", .{});
    putreg32(0x8203,     0x1c20168);  // TODO: DMB
    putreg32(0x10000000, 0x1ca1004);  // TODO: DMB
    putreg32(0xa06000e,  0x1ca1010);  // TODO: DMB
    putreg32(0xa033207,  0x1ca1014);  // TODO: DMB
    putreg32(0x1e,       0x1ca1018);  // TODO: DMB

    //   0x1ca101c = 0x0 (DMB)
    //   0x1ca1020 = 0x303 (DMB)
    //   0x1ca1000 = 0x31 (DMB)
    //   0x1ca104c = 0x9f007f00 (DMB)
    //   0x1ca1050 = 0x17000000 (DMB)
    putreg32(0x0,        0x1ca101c);  // TODO: DMB
    putreg32(0x303,      0x1ca1020);  // TODO: DMB
    putreg32(0x31,       0x1ca1000);  // TODO: DMB
    putreg32(0x9f007f00, 0x1ca104c);  // TODO: DMB
    putreg32(0x17000000, 0x1ca1050);  // TODO: DMB

    //   0x1ca105c = 0x1f01555 (DMB)
    //   0x1ca1054 = 0x2 (DMB)
    putreg32(0x1f01555, 0x1ca105c);  // TODO: DMB
    putreg32(0x2,       0x1ca1054);  // TODO: DMB

    //   udelay 5
    _ = c.usleep(5);

    //   0x1ca1058 = 0x3040000 (DMB)
    putreg32(0x3040000, 0x1ca1058);  // TODO: DMB

    //   udelay 1
    _ = c.usleep(1);

    //   update_bits addr=0x1ca1058, mask=0xf8000000, val=0xf8000000 (DMB)
    modreg32(0xf8000000, 0xf8000000, 0x1ca1058);  // TODO: DMB

    //   udelay 1
    _ = c.usleep(1);

    //   update_bits addr=0x1ca1058, mask=0x4000000, val=0x4000000 (DMB)
    modreg32(0x4000000, 0x4000000, 0x1ca1058);  // TODO: DMB

    //   udelay 1
    _ = c.usleep(1);

    //   update_bits addr=0x1ca1054, mask=0x10, val=0x10 (DMB)
    modreg32(0x10, 0x10, 0x1ca1054);  // TODO: DMB

    //   udelay 1
    _ = c.usleep(1);

    //   update_bits addr=0x1ca1050, mask=0x80000000, val=0x80000000 (DMB)
    //   update_bits addr=0x1ca1054, mask=0xf000000, val=0xf000000 (DMB)
    modreg32(0x80000000, 0x80000000, 0x1ca1050);  // TODO: DMB
    modreg32(0xf000000,  0xf000000,  0x1ca1054);  // TODO: DMB
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
