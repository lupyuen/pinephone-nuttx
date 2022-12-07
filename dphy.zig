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
//! See https://lupyuen.github.io/articles/dsi#appendix-enable-mipi-display-physical-layer-dphy
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

/// Base Address of Allwinner A64 CCU Controller (A64 Page 82)
const CCU_BASE_ADDRESS = 0x01C2_0000;

/// Base Address of Allwinner A64 MIPI DPHY Controller (A64 Page 74)
const DPHY_BASE_ADDRESS = 0x01CA_1000;

/// Enable MIPI Display Physical Layer (DPHY).
/// Based on https://lupyuen.github.io/articles/dsi#appendix-enable-mipi-display-physical-layer-dphy
pub export fn dphy_enable() void {
    debug("dphy_enable: start", .{});
    defer { debug("dphy_enable: end", .{}); }

    // Set DSI Clock to 150 MHz (600 MHz / 4)
    // MIPI_DSI_CLK_REG: CCU Offset 0x168 (A64 Page 122)
    // Set DSI_DPHY_GATING (Bit 15) to 1 (DSI DPHY Clock is On)
    // Set DSI_DPHY_SRC_SEL (Bits 8 to 9) to 0b10 (DSI DPHY Clock Source is PLL_PERIPH0(1X))
    // Set DPHY_CLK_DIV_M (Bits 0 to 3) to 3 (DSI DPHY Clock divide ratio - 1)
    debug("Set DSI Clock to 150 MHz", .{});
    const MIPI_DSI_CLK_REG = CCU_BASE_ADDRESS + 0x168;
    comptime{ assert(MIPI_DSI_CLK_REG == 0x1c20168); }

    const MIPI_DSI_CLK = 0x8203;
    comptime{ assert(MIPI_DSI_CLK == 0x8203); }
    putreg32(MIPI_DSI_CLK, MIPI_DSI_CLK_REG);  // TODO: DMB

    // Power on DPHY Tx (Undocumented)
    // DPHY_TX_CTL_REG: DPHY Offset 0x04
    // Set to 0x1000 0000
    debug("Power on DPHY Tx", .{});
    const DPHY_TX_CTL_REG = DPHY_BASE_ADDRESS + 0x04;
    comptime{ assert(DPHY_TX_CTL_REG == 0x1ca1004); }
    putreg32(0x10000000, DPHY_TX_CTL_REG);  // TODO: DMB

    // DPHY_TX_TIME0_REG: DPHY Offset 0x10
    // Set to 0xa06 000e
    const DPHY_TX_TIME0_REG = DPHY_BASE_ADDRESS + 0x10;
    comptime{ assert(DPHY_TX_TIME0_REG == 0x1ca1010); }
    putreg32(0xa06000e,  DPHY_TX_TIME0_REG);  // TODO: DMB

    // DPHY_TX_TIME1_REG: DPHY Offset 0x14
    // Set to 0xa03 3207
    const DPHY_TX_TIME1_REG = DPHY_BASE_ADDRESS + 0x14;
    comptime{ assert(DPHY_TX_TIME1_REG == 0x1ca1014); }
    putreg32(0xa033207,  DPHY_TX_TIME1_REG);  // TODO: DMB

    // DPHY_TX_TIME2_REG: DPHY Offset 0x18
    // Set to 0x1e
    const DPHY_TX_TIME2_REG = DPHY_BASE_ADDRESS + 0x18;
    comptime{ assert(DPHY_TX_TIME2_REG == 0x1ca1018); }
    putreg32(0x1e,       DPHY_TX_TIME2_REG);  // TODO: DMB

    // DPHY_TX_TIME3_REG: DPHY Offset 0x1c
    // Set to 0x0
    const DPHY_TX_TIME3_REG = DPHY_BASE_ADDRESS + 0x1c;
    comptime{ assert(DPHY_TX_TIME3_REG == 0x1ca101c); }
    putreg32(0x0,        DPHY_TX_TIME3_REG);  // TODO: DMB

    // DPHY_TX_TIME4_REG: DPHY Offset 0x20
    // Set to 0x303
    const DPHY_TX_TIME4_REG = DPHY_BASE_ADDRESS + 0x20;
    comptime{ assert(DPHY_TX_TIME4_REG == 0x1ca1020); }
    putreg32(0x303,      DPHY_TX_TIME4_REG);  // TODO: DMB

    // Enable DPHY (Undocumented)
    // DPHY_GCTL_REG: DPHY Offset 0x00 (Enable DPHY)
    // Set to 0x31
    debug("Enable DPHY", .{});
    const DPHY_GCTL_REG = DPHY_BASE_ADDRESS + 0x00;
    comptime{ assert(DPHY_GCTL_REG == 0x1ca1000); }
    putreg32(0x31,       DPHY_GCTL_REG);  // TODO: DMB

    // DPHY_ANA0_REG: DPHY Offset 0x4c (PWS)
    // Set to 0x9f00 7f00
    const DPHY_ANA0_REG = DPHY_BASE_ADDRESS + 0x4c;
    comptime{ assert(DPHY_ANA0_REG == 0x1ca104c); }
    putreg32(0x9f007f00, DPHY_ANA0_REG);  // TODO: DMB

    // DPHY_ANA1_REG: DPHY Offset 0x50 (CSMPS)
    // Set to 0x1700 0000
    const DPHY_ANA1_REG = DPHY_BASE_ADDRESS + 0x50;
    comptime{ assert(DPHY_ANA1_REG == 0x1ca1050); }
    putreg32(0x17000000, DPHY_ANA1_REG);  // TODO: DMB

    // DPHY_ANA4_REG: DPHY Offset 0x5c (CKDV)
    // Set to 0x1f0 1555
    const DPHY_ANA4_REG = DPHY_BASE_ADDRESS + 0x5c;
    comptime{ assert(DPHY_ANA4_REG == 0x1ca105c); }
    putreg32(0x1f01555,  DPHY_ANA4_REG);  // TODO: DMB

    // DPHY_ANA2_REG: DPHY Offset 0x54 (ENIB)
    // Set to 0x2
    const DPHY_ANA2_REG = DPHY_BASE_ADDRESS + 0x54;
    comptime{ assert(DPHY_ANA2_REG == 0x1ca1054); }
    putreg32(0x2,        DPHY_ANA2_REG);  // TODO: DMB

    // Wait 5 microseconds
    _ = c.usleep(5);

    // Enable LDOR, LDOC, LDOD (Undocumented)
    // DPHY_ANA3_REG: DPHY Offset 0x58 (Enable LDOR, LDOC, LDOD)
    // Set to 0x304 0000
    debug("Enable LDOR, LDOC, LDOD", .{});
    const DPHY_ANA3_REG = DPHY_BASE_ADDRESS + 0x58;
    comptime{ assert(DPHY_ANA3_REG == 0x1ca1058); }
    putreg32(0x3040000, DPHY_ANA3_REG);  // TODO: DMB

    // Wait 1 microsecond
    _ = c.usleep(1);

    // DPHY_ANA3_REG: DPHY Offset 0x58 (Enable VTTC, VTTD)
    // Set bits 0xf800 0000
    comptime{ assert(DPHY_ANA3_REG == 0x1ca1058); }
    const EnableVTTC = 0xf8000000;
    modreg32(EnableVTTC, EnableVTTC, DPHY_ANA3_REG);  // TODO: DMB

    // Wait 1 microsecond
    _ = c.usleep(1);

    // DPHY_ANA3_REG: DPHY Offset 0x58 (Enable DIV)
    // Set bits 0x400 0000
    comptime{ assert(DPHY_ANA3_REG == 0x1ca1058); }
    const EnableDIV = 0x4000000;
    modreg32(EnableDIV, EnableDIV, DPHY_ANA3_REG);  // TODO: DMB

    // Wait 1 microsecond
    _ = c.usleep(1);

    // DPHY_ANA2_REG: DPHY Offset 0x54 (Enable CK_CPU)
    comptime{ assert(DPHY_ANA2_REG == 0x1ca1054); }
    const EnableCKCPU = 0x10;
    modreg32(EnableCKCPU, EnableCKCPU, DPHY_ANA2_REG);  // TODO: DMB

    // Set bits 0x10
    // Wait 1 microsecond
    _ = c.usleep(1);

    // DPHY_ANA1_REG: DPHY Offset 0x50 (VTT Mode)
    // Set bits 0x8000 0000
    comptime{ assert(DPHY_ANA1_REG == 0x1ca1050); }
    const VTTMode = 0x80000000;
    modreg32(VTTMode, VTTMode, DPHY_ANA1_REG);  // TODO: DMB

    // DPHY_ANA2_REG: DPHY Offset 0x54 (Enable P2S CPU)
    // Set bits 0xf00 0000
    comptime{ assert(DPHY_ANA2_REG == 0x1ca1054); }
    const EnableP2SCPU = 0xf000000;
    modreg32(EnableP2SCPU,  EnableP2SCPU,  DPHY_ANA2_REG);  // TODO: DMB
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
