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

//! PinePhone MIPI DSI Driver for Apache NuttX RTOS.
//! This MIPI DSI Interface is compatible with Zephyr MIPI DSI:
//! https://github.com/zephyrproject-rtos/zephyr/blob/main/include/zephyr/drivers/mipi_dsi.h

/// Import the Zig Standard Library
const std = @import("std");

/// Import the LoRaWAN Library from C
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

/// MIPI DSI Processor-to-Peripheral transaction types
const MIPI_DSI_DCS_LONG_WRITE = 0x39;

/// Write to MIPI DSI. See https://lupyuen.github.io/articles/dsi#transmit-packet-over-mipi-dsi
pub export fn nuttx_mipi_dsi_dcs_write(
    dev: [*c]const mipi_dsi_device,  // MIPI DSI Host Device
    channel: u8,  // Virtual Channel ID
    cmd: u8,      // DCS Command
    buf: [*c]const u8,  // Transmit Buffer
    len: usize          // Buffer Length
) isize {  // On Success: Return number of written bytes. On Error: Return negative error code
    _ = dev;
    debug("mipi_dsi_dcs_write: channel={}, cmd=0x{x}, len={}", .{ channel, cmd, len });
    assert(cmd == MIPI_DSI_DCS_LONG_WRITE);  // Only DCS Long Write supported

    // Compose Long Packet
    var pkt_buf = std.mem.zeroes([128]u8);
    const pkt = composeLongPacket(&pkt_buf, channel, cmd, buf, len);

    // Dump the packet
    debug("packet: len={}", .{ pkt.len });
    dump_buffer(&pkt[0], pkt.len);

    // TODO
    // - Write the Long Packet to DSI_CMD_TX_REG 
    //   (DSI Low Power Transmit Package Register) at Offset 0x300 to 0x3FC.
    //
    // - Set Packet Length - 1 in Bits 0 to 7 (TX_Size) of
    //   DSI_CMD_CTL_REG (DSI Low Power Control Register) at Offset .0x200.
    //
    // - Set DSI_INST_JUMP_SEL_REG (Offset 0x48, undocumented) 
    //   to begin the Low Power Transmission.
    //
    // - Disable DSI Processing: Set Instru_En to 0.
    // - Then Enable DSI Processing: Set Instru_En to 1.
    //
    // - To check whether the transmission is complete, we poll on Instru_En.
    //
    // Instru_En is Bit 0 of DSI_BASIC_CTL0_REG 
    // (DSI Configuration Register 0) at Offset 0x10.
    return 0;
}

// Compose MIPI DSI Long Packet. See https://lupyuen.github.io/articles/dsi#long-packet-for-mipi-dsi
fn composeLongPacket(
    pkt: []u8,    // Buffer for the Long Packet
    channel: u8,  // Virtual Channel ID
    cmd: u8,      // DCS Command
    buf: [*c]const u8,  // Transmit Buffer
    len: usize          // Buffer Length
) []const u8 {          // Returns the Long Packet
    debug("composeLongPacket: channel={}, cmd=0x{x}, len={}", .{ channel, cmd, len });
    // Data Identifier (DI) (1 byte):
    // - Virtual Channel Identifier (Bits 6 to 7)
    // - Data Type (Bits 0 to 5)
    // (Virtual Channel should be 0, I think)
    assert(cmd < (1 << 6));
    const vc: u8 = channel;
    const dt: u8 = cmd;
    const di: u8 = (vc << 6) | dt;

    // Word Count (WC) (2 bytes)：
    // - Number of bytes in the Packet Payload
    const wc: u16 = @intCast(u16, len);
    const wcl: u8 = @intCast(u8, wc & 0xff);
    const wch: u8 = @intCast(u8, wc >> 8);

    // Data Identifier + Word Count (3 bytes): For computing Error Correction Code (ECC)
    const di_wc = [3]u8 { di, wcl, wch };

    // Compute Error Correction Code (ECC) for Data Identifier + Word Count
    const ecc: u8 = computeEcc(di_wc);

    // Packet Header (4 bytes):
    // - Data Identifier + Word Count + Error Correction COde
    const header = [4]u8 { di_wc[0], di_wc[1], di_wc[2], ecc };

    // Packet Payload:
    // - Data (0 to 65,541 bytes):
    // Number of data bytes should match the Word Count (WC)
    assert(len <= 65_541);
    const payload = buf[0..len];

    // Checksum (CS) (2 bytes):
    // - 16-bit Cyclic Redundancy Check (CRC) of the Payload (not the entire packet)
    const cs: u16 = computeCrc(payload);
    const csl: u8 = @intCast(u8, cs & 0xff);
    const csh: u8 = @intCast(u8, cs >> 8);

    // Packet Footer (2 bytes)
    // - Checksum (CS)
    const footer = [2]u8 { csl, csh };

    // Packet:
    // - Packet Header (4 bytes)
    // - Payload (`len` bytes)
    // - Packet Footer (2 bytes)
    const pktlen = header.len + len + footer.len;
    assert(pktlen <= pkt.len);  // Increase `pkt` size
    std.mem.copy(u8, pkt[0..header.len], &header); // 4 bytes
    std.mem.copy(u8, pkt[header.len..], payload);  // `len` bytes
    std.mem.copy(u8, pkt[(header.len + len)..], &footer);  // 2 bytes

    // Return the packet
    const result = pkt[0..pktlen];
    return result;
}

/// Compute the Error Correction Code (ECC) (1 byte):
/// Allow single-bit errors to be corrected and 2-bit errors to be detected in the Packet Header
/// See "12.3.6.12: Error Correction Code", Page 208 of BL808 Reference Manual:
/// https://github.com/sipeed/sipeed2022_autumn_competition/blob/main/assets/BL808_RM_en.pdf
fn computeEcc(
    di_wc: [3]u8  // Data Identifier + Word Count (3 bytes)
) u8 {
    // Combine DI and WC into a 24-bit word
    var di_wc_word: u32 = 
        di_wc[0] 
        | (@intCast(u32, di_wc[1]) << 8)
        | (@intCast(u32, di_wc[2]) << 16);

    // Extract the 24 bits from the word
    var d = std.mem.zeroes([24]u1);
    var i: usize = 0;
    while (i < 24) : (i += 1) {
        d[i] = @intCast(u1, di_wc_word & 1);
        di_wc_word >>= 1;
    }

    // Compute the ECC bits
    var ecc = std.mem.zeroes([8]u1);
    ecc[7] = 0;
    ecc[6] = 0;
    ecc[5] = d[10] ^ d[11] ^ d[12] ^ d[13] ^ d[14] ^ d[15] ^ d[16] ^ d[17] ^ d[18] ^ d[19] ^ d[21] ^ d[22] ^ d[23];
    ecc[4] = d[4]  ^ d[5]  ^ d[6]  ^ d[7]  ^ d[8]  ^ d[9]  ^ d[16] ^ d[17] ^ d[18] ^ d[19] ^ d[20] ^ d[22] ^ d[23];
    ecc[3] = d[1]  ^ d[2]  ^ d[3]  ^ d[7]  ^ d[8]  ^ d[9]  ^ d[13] ^ d[14] ^ d[15] ^ d[19] ^ d[20] ^ d[21] ^ d[23];
    ecc[2] = d[0]  ^ d[2]  ^ d[3]  ^ d[5]  ^ d[6]  ^ d[9]  ^ d[11] ^ d[12] ^ d[15] ^ d[18] ^ d[20] ^ d[21] ^ d[22];
    ecc[1] = d[0]  ^ d[1]  ^ d[3]  ^ d[4]  ^ d[6]  ^ d[8]  ^ d[10] ^ d[12] ^ d[14] ^ d[17] ^ d[20] ^ d[21] ^ d[22] ^ d[23];
    ecc[0] = d[0]  ^ d[1]  ^ d[2]  ^ d[4]  ^ d[5]  ^ d[7]  ^ d[10] ^ d[11] ^ d[13] ^ d[16] ^ d[20] ^ d[21] ^ d[22] ^ d[23];

    // Merge the ECC bits
    return @intCast(u8, ecc[0])
        | (@intCast(u8, ecc[1]) << 1)
        | (@intCast(u8, ecc[2]) << 2)
        | (@intCast(u8, ecc[3]) << 3)
        | (@intCast(u8, ecc[4]) << 4)
        | (@intCast(u8, ecc[5]) << 5)
        | (@intCast(u8, ecc[6]) << 6)
        | (@intCast(u8, ecc[7]) << 7);
}

/// Compute 16-bit Cyclic Redundancy Check (CRC).
/// See "12.3.6.13: Packet Footer", Page 210 of BL808 Reference Manual:
/// https://github.com/sipeed/sipeed2022_autumn_competition/blob/main/assets/BL808_RM_en.pdf
fn computeCrc(
    data: []const u8
) u16 {
    // Use CRC-16-CCITT (x^16 + x^12 + x^5 + 1)
    const crc = crc16ccitt(data, 0xffff);

    debug("computeCrc: len={}, crc=0x{x}", .{ data.len, crc });
    dump_buffer(&data[0], data.len);
    return crc;
}

/// Return a 16-bit CRC-CCITT of the contents of the `src` buffer.
/// Based on nuttx/libs/libc/misc/lib_crc16.c
fn crc16ccitt(src: []const u8, crc16val: u16) u16 {
    var i: usize = 0;
    var v = crc16val;
    while (i < src.len) : (i += 1) {
      v = (v >> 8)
        ^ crc16ccitt_tab[(v ^ src[i]) & 0xff];
    }
    return v;
}

/// From CRC-16-CCITT (x^16 + x^12 + x^5 + 1)
const crc16ccitt_tab: [256]u16 = .{
    0x0000, 0x1189, 0x2312, 0x329b, 0x4624, 0x57ad, 0x6536, 0x74bf,
    0x8c48, 0x9dc1, 0xaf5a, 0xbed3, 0xca6c, 0xdbe5, 0xe97e, 0xf8f7,
    0x1081, 0x0108, 0x3393, 0x221a, 0x56a5, 0x472c, 0x75b7, 0x643e,
    0x9cc9, 0x8d40, 0xbfdb, 0xae52, 0xdaed, 0xcb64, 0xf9ff, 0xe876,
    0x2102, 0x308b, 0x0210, 0x1399, 0x6726, 0x76af, 0x4434, 0x55bd,
    0xad4a, 0xbcc3, 0x8e58, 0x9fd1, 0xeb6e, 0xfae7, 0xc87c, 0xd9f5,
    0x3183, 0x200a, 0x1291, 0x0318, 0x77a7, 0x662e, 0x54b5, 0x453c,
    0xbdcb, 0xac42, 0x9ed9, 0x8f50, 0xfbef, 0xea66, 0xd8fd, 0xc974,
    0x4204, 0x538d, 0x6116, 0x709f, 0x0420, 0x15a9, 0x2732, 0x36bb,
    0xce4c, 0xdfc5, 0xed5e, 0xfcd7, 0x8868, 0x99e1, 0xab7a, 0xbaf3,
    0x5285, 0x430c, 0x7197, 0x601e, 0x14a1, 0x0528, 0x37b3, 0x263a,
    0xdecd, 0xcf44, 0xfddf, 0xec56, 0x98e9, 0x8960, 0xbbfb, 0xaa72,
    0x6306, 0x728f, 0x4014, 0x519d, 0x2522, 0x34ab, 0x0630, 0x17b9,
    0xef4e, 0xfec7, 0xcc5c, 0xddd5, 0xa96a, 0xb8e3, 0x8a78, 0x9bf1,
    0x7387, 0x620e, 0x5095, 0x411c, 0x35a3, 0x242a, 0x16b1, 0x0738,
    0xffcf, 0xee46, 0xdcdd, 0xcd54, 0xb9eb, 0xa862, 0x9af9, 0x8b70,
    0x8408, 0x9581, 0xa71a, 0xb693, 0xc22c, 0xd3a5, 0xe13e, 0xf0b7,
    0x0840, 0x19c9, 0x2b52, 0x3adb, 0x4e64, 0x5fed, 0x6d76, 0x7cff,
    0x9489, 0x8500, 0xb79b, 0xa612, 0xd2ad, 0xc324, 0xf1bf, 0xe036,
    0x18c1, 0x0948, 0x3bd3, 0x2a5a, 0x5ee5, 0x4f6c, 0x7df7, 0x6c7e,
    0xa50a, 0xb483, 0x8618, 0x9791, 0xe32e, 0xf2a7, 0xc03c, 0xd1b5,
    0x2942, 0x38cb, 0x0a50, 0x1bd9, 0x6f66, 0x7eef, 0x4c74, 0x5dfd,
    0xb58b, 0xa402, 0x9699, 0x8710, 0xf3af, 0xe226, 0xd0bd, 0xc134,
    0x39c3, 0x284a, 0x1ad1, 0x0b58, 0x7fe7, 0x6e6e, 0x5cf5, 0x4d7c,
    0xc60c, 0xd785, 0xe51e, 0xf497, 0x8028, 0x91a1, 0xa33a, 0xb2b3,
    0x4a44, 0x5bcd, 0x6956, 0x78df, 0x0c60, 0x1de9, 0x2f72, 0x3efb,
    0xd68d, 0xc704, 0xf59f, 0xe416, 0x90a9, 0x8120, 0xb3bb, 0xa232,
    0x5ac5, 0x4b4c, 0x79d7, 0x685e, 0x1ce1, 0x0d68, 0x3ff3, 0x2e7a,
    0xe70e, 0xf687, 0xc41c, 0xd595, 0xa12a, 0xb0a3, 0x8238, 0x93b1,
    0x6b46, 0x7acf, 0x4854, 0x59dd, 0x2d62, 0x3ceb, 0x0e70, 0x1ff9,
    0xf78f, 0xe606, 0xd49d, 0xc514, 0xb1ab, 0xa022, 0x92b9, 0x8330,
    0x7bc7, 0x6a4e, 0x58d5, 0x495c, 0x3de3, 0x2c6a, 0x1ef1, 0x0f78,
};

///////////////////////////////////////////////////////////////////////////////
//  MIPI DSI Types

/// MIPI DSI Device
pub const mipi_dsi_device = extern struct {
    /// Number of Data Lanes
    data_lanes: u8,
    /// Display Timings
    timings: mipi_dsi_timings,
    /// Pixel Format
    pixfmt: u32,
    /// Mode Flags
    mode_flags: u32,
};

/// MIPI DSI Read / Write Message
pub const mipi_dsi_msg = extern struct {
    /// Payload Data Type
    type: u8,
    /// Flags controlling message transmission
    flags: u16,
    /// Command (only for DCS)
    cmd: u8,
    /// Transmit Buffer Length
    tx_len: usize,
    /// Transmit Buffer
    tx_buf: [*c]const u8,
    /// Receive Buffer Length
    rx_len: usize,
    /// Receive Buffer
    rx_buf: [*c]u8,
};

/// MIPI DSI Display Timings
pub const mipi_dsi_timings = extern struct {
    /// Horizontal active video
    hactive: u32,
    /// Horizontal front porch
    hfp: u32,
    /// Horizontal back porch
    hbp: u32,
    /// Horizontal sync length
    hsync: u32,
    /// Vertical active video
    vactive: u32,
    /// Vertical front porch
    vfp: u32,
    /// Vertical back porch
    vbp: u32,
    /// Vertical sync length
    vsync: u32,
};

///////////////////////////////////////////////////////////////////////////////
//  Test Functions

/// Main Function for Null App
pub export fn null_main(_argc: c_int, _argv: [*]const [*]const u8) c_int {
    _ = _argc;
    _ = _argv;
    test_zig();
    return 0;
}

/// Zig Test Function
pub export fn test_zig() void {
    _ = printf("HELLO ZIG ON PINEPHONE!\n");
    const buf = [_]u8 {
        0xe9, 0x82, 0x10, 0x06, 0x05, 0xa2, 0x0a, 0xa5,
        0x12, 0x31, 0x23, 0x37, 0x83, 0x04, 0xbc, 0x27,
        0x38, 0x0c, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0c,
        0x00, 0x03, 0x00, 0x00, 0x00, 0x75, 0x75, 0x31,
        0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x13, 0x88,
        0x64, 0x64, 0x20, 0x88, 0x88, 0x88, 0x88, 0x88,
        0x88, 0x02, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };
    _ = nuttx_mipi_dsi_dcs_write(
        null,  //  Device
        0,     //  Virtual Channel
        MIPI_DSI_DCS_LONG_WRITE, // DCS Command
        &buf,    // Transmit Buffer
        buf.len  // Buffer Length
    );
}

// mipi_dsi_dcs_write: len=64
// e9 82 10 06 05 a2 0a a5 
// 12 31 23 37 83 04 bc 27 
// 38 0c 00 03 00 00 00 0c 
// 00 03 00 00 00 75 75 31 
// 88 88 88 88 88 88 13 88 
// 64 64 20 88 88 88 88 88 
// 88 02 88 00 00 00 00 00 
// 00 00 00 00 00 00 00 00 
// .{ 0x0300, 0x25004039 },
// header: 25004039
// display_zalloc: size=70
// .{ 0x0304, 0x061082e9 },
// .{ 0x0308, 0xa50aa205 },
// .{ 0x030c, 0x37233112 },
// .{ 0x0310, 0x27bc0483 },
// .{ 0x0314, 0x03000c38 },
// .{ 0x0318, 0x0c000000 },
// .{ 0x031c, 0x00000300 },
// .{ 0x0320, 0x31757500 },
// .{ 0x0324, 0x88888888 },
// .{ 0x0328, 0x88138888 },
// .{ 0x032c, 0x88206464 },
// .{ 0x0330, 0x88888888 },
// .{ 0x0334, 0x00880288 },
// .{ 0x0338, 0x00000000 },
// .{ 0x033c, 0x00000000 },
// .{ 0x0340, 0x00000000 },
// .{ 0x0344, 0x00000365 },
// payload[0]: 061082e9
// payload[1]: a50aa205
// payload[2]: 37233112
// payload[3]: 27bc0483
// payload[4]: 03000c38
// payload[5]: 0c000000
// payload[6]: 00000300
// payload[7]: 31757500
// payload[8]: 88888888
// payload[9]: 88138888
// payload[10]: 88206464
// payload[11]: 88888888
// payload[12]: 00880288
// payload[13]: 00000000
// payload[14]: 00000000
// payload[15]: 00000000
// payload[16]: 00000365
// .{ 0x0200, 0x00000045 },
// len: 69
// .{ MAGIC_COMMIT, 0 },

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

/// From apps/examples/hello/hello_main.c
extern fn dump_buffer(data: [*c]const u8, len: usize) void;

/// For safety, we import these functions ourselves to enforce Null-Terminated Strings.
/// We changed `[*c]const u8` to `[*:0]const u8`
extern fn printf(format: [*:0]const u8, ...) c_int;
extern fn puts(str: [*:0]const u8) c_int;

/// Aliases for Zig Standard Library
const assert = std.debug.assert;
const debug  = std.log.debug;
