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
//! "A64 Page ???" refers to Allwinner A64 User Manual: https://github.com/lupyuen/pinephone-nuttx/releases/download/doc/Allwinner_A64_User_Manual_V1.1.pdf
//! "A31 Page ???" refers to Allwinner A31 User Manual: https://github.com/lupyuen/pinephone-nuttx/releases/download/doc/A31_User_Manual_v1.3_20150510.pdf
//! This MIPI DSI Interface is compatible with Zephyr MIPI DSI:
//! https://github.com/zephyrproject-rtos/zephyr/blob/main/include/zephyr/drivers/mipi_dsi.h

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

///////////////////////////////////////////////////////////////////////////////
//  MIPI DSI Long and Short Packets

// Compose MIPI DSI Long Packet. See https://lupyuen.github.io/articles/dsi#long-packet-for-mipi-dsi
fn composeLongPacket(
    pkt: []u8,    // Buffer for the Returned Long Packet
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
    assert(channel < 4);
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
    // - Data Identifier + Word Count + Error Correction Code
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

// Compose MIPI DSI Short Packet. See https://lupyuen.github.io/articles/dsi#appendix-short-packet-for-mipi-dsi
fn composeShortPacket(
    pkt: []u8,    // Buffer for the Returned Short Packet
    channel: u8,  // Virtual Channel ID
    cmd: u8,      // DCS Command
    buf: [*c]const u8,  // Transmit Buffer
    len: usize          // Buffer Length
) []const u8 {          // Returns the Short Packet
    debug("composeShortPacket: channel={}, cmd=0x{x}, len={}", .{ channel, cmd, len });
    assert(len == 1 or len == 2);

    // From BL808 Reference Manual (Page 201): https://files.pine64.org/doc/datasheet/ox64/BL808_RM_en_1.0(open).pdf
    //   A Short Packet consists of 8-bit data identification (DI),
    //   two bytes of commands or data, and 8-bit ECC.
    //   The length of a short packet is 4 bytes including ECC.
    // Thus a MIPI DSI Short Packet (compared with Long Packet)...
    // - Doesn't have Packet Payload and Packet Footer (CRC)
    // - Instead of Word Count (WC), the Packet Header now has 2 bytes of data
    // Everything else is the same.

    // Data Identifier (DI) (1 byte):
    // - Virtual Channel Identifier (Bits 6 to 7)
    // - Data Type (Bits 0 to 5)
    // (Virtual Channel should be 0, I think)
    assert(channel < 4);
    assert(cmd < (1 << 6));
    const vc: u8 = channel;
    const dt: u8 = cmd;
    const di: u8 = (vc << 6) | dt;

    // Data (2 bytes), fill with 0 if Second Byte is missing
    const data = [2]u8 {
        buf[0],                       // First Byte
        if (len == 2) buf[1] else 0,  // Second Byte
    };

    // Data Identifier + Data (3 bytes): For computing Error Correction Code (ECC)
    const di_data = [3]u8 { di, data[0], data[1] };

    // Compute Error Correction Code (ECC) for Data Identifier + Word Count
    const ecc: u8 = computeEcc(di_data);

    // Packet Header (4 bytes):
    // - Data Identifier + Data + Error Correction Code
    const header = [4]u8 { di_data[0], di_data[1], di_data[2], ecc };

    // Packet:
    // - Packet Header (4 bytes)
    const pktlen = header.len;
    assert(pktlen <= pkt.len);  // Increase `pkt` size
    std.mem.copy(u8, pkt[0..header.len], &header); // 4 bytes

    // Return the packet
    const result = pkt[0..pktlen];
    return result;
}

/// Compute the Error Correction Code (ECC) (1 byte):
/// Allow single-bit errors to be corrected and 2-bit errors to be detected in the Packet Header
/// See "12.3.6.12: Error Correction Code", Page 208 of BL808 Reference Manual:
/// https://files.pine64.org/doc/datasheet/ox64/BL808_RM_en_1.0(open).pdf
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
/// https://files.pine64.org/doc/datasheet/ox64/BL808_RM_en_1.0(open).pdf
fn computeCrc(
    data: []const u8
) u16 {
    // Use CRC-16-CCITT (x^16 + x^12 + x^5 + 1)
    const crc = crc16ccitt(data, 0xffff);

    // debug("computeCrc: len={}, crc=0x{x}", .{ data.len, crc });
    // dump_buffer(&data[0], data.len);
    return crc;
}

/// Return a 16-bit CRC-CCITT of the contents of the `src` buffer.
/// Based on https://github.com/lupyuen/incubator-nuttx/blob/pinephone/libs/libc/misc/lib_crc16.c
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
const crc16ccitt_tab = [256]u16 {
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
//  MIPI DSI Operations for Allwinner A64

/// MIPI DSI Virtual Channel
const VIRTUAL_CHANNEL = 0;

/// MIPI DSI Processor-to-Peripheral transaction types:
/// DCS Long Write. See https://lupyuen.github.io/articles/dsi#display-command-set-for-mipi-dsi
const MIPI_DSI_DCS_LONG_WRITE = 0x39;

/// DCS Short Write (Without Parameter)
const MIPI_DSI_DCS_SHORT_WRITE = 0x05;

/// DCS Short Write (With Parameter)
const MIPI_DSI_DCS_SHORT_WRITE_PARAM = 0x15;

/// Base Address of Allwinner A64 CCU Controller (A64 Page 82)
const CCU_BASE_ADDRESS = 0x01C2_0000;

/// Base Address of Allwinner A64 MIPI DSI Controller (A31 Page 842)
const DSI_BASE_ADDRESS = 0x01CA_0000;

/// Instru_En is Bit 0 of DSI_BASIC_CTL0_REG 
/// (DSI Configuration Register 0) at Offset 0x10
const DSI_BASIC_CTL0_REG = DSI_BASE_ADDRESS + 0x10;
const Instru_En = 1 << 0;

/// Write the DCS Command to MIPI DSI
fn writeDcs(buf: []const u8) void {
    debug("writeDcs: len={}", .{ buf.len });
    dump_buffer(buf);
    assert(buf.len > 0);

    // Do DCS Short Write or Long Write depending on command length
    const res = switch (buf.len) {

        // DCS Short Write (without parameter)
        1 => nuttx_mipi_dsi_dcs_write(null, VIRTUAL_CHANNEL, 
            MIPI_DSI_DCS_SHORT_WRITE, 
            &buf[0], buf.len),

        // DCS Short Write (with parameter)
        2 => nuttx_mipi_dsi_dcs_write(null, VIRTUAL_CHANNEL, 
            MIPI_DSI_DCS_SHORT_WRITE_PARAM, 
            &buf[0], buf.len),

        // DCS Long Write
        else => nuttx_mipi_dsi_dcs_write(null, VIRTUAL_CHANNEL, 
            MIPI_DSI_DCS_LONG_WRITE, 
            &buf[0], buf.len),
    };
    assert(res == buf.len);
}

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
    if (cmd == MIPI_DSI_DCS_SHORT_WRITE)       { assert(len == 1); }
    if (cmd == MIPI_DSI_DCS_SHORT_WRITE_PARAM) { assert(len == 2); }

    // Allocate Packet Buffer
    var pkt_buf = std.mem.zeroes([128]u8);

    // Compose Short or Long Packet depending on DCS Command
    const pkt = switch (cmd) {

        // For DCS Long Write: Compose Long Packet
        MIPI_DSI_DCS_LONG_WRITE =>
            composeLongPacket(&pkt_buf, channel, cmd, buf, len),

        // For DCS Short Write (with and without parameter):
        // Compose Short Packet
        MIPI_DSI_DCS_SHORT_WRITE,
        MIPI_DSI_DCS_SHORT_WRITE_PARAM =>
            composeShortPacket(&pkt_buf, channel, cmd, buf, len),

        // DCS Command not supported
        else => unreachable,
    };

    // Dump the packet
    debug("packet: len={}", .{ pkt.len });
    dump_buffer(pkt);

    // Set the following bits to 1 in DSI_CMD_CTL_REG (DSI Low Power Control Register) at Offset 0x200:
    // RX_Overflow (Bit 26): Clear flag for "Receive Overflow"
    // RX_Flag (Bit 25): Clear flag for "Receive has started"
    // TX_Flag (Bit 9): Clear flag for "Transmit has started"
    // All other bits must be set to 0.
    const DSI_CMD_CTL_REG = DSI_BASE_ADDRESS + 0x200;
    const RX_Overflow = 1 << 26;
    const RX_Flag     = 1 << 25;
    const TX_Flag     = 1 << 9;
    putreg32(
        RX_Overflow | RX_Flag | TX_Flag,
        DSI_CMD_CTL_REG
    );

    // Write the Long Packet to DSI_CMD_TX_REG 
    // (DSI Low Power Transmit Package Register) at Offset 0x300 to 0x3FC
    const DSI_CMD_TX_REG = DSI_BASE_ADDRESS + 0x300;
    var addr: u64 = DSI_CMD_TX_REG;
    var i: usize = 0;
    while (i < pkt.len) : (i += 4) {
        // Fetch the next 4 bytes, fill with 0 if not available
        const b = [4]u32 {
            pkt[i],
            if (i + 1 < pkt.len) pkt[i + 1] else 0,
            if (i + 2 < pkt.len) pkt[i + 2] else 0,
            if (i + 3 < pkt.len) pkt[i + 3] else 0,
        };

        // Merge the next 4 bytes into a 32-bit value
        const v: u32 =
            b[0]
            + (b[1] << 8)
            + (b[2] << 16)
            + (b[3] << 24);

        // Write the 32-bit value
        assert(addr <= DSI_BASE_ADDRESS + 0x3FC);
        modreg32(v, 0xFFFF_FFFF, addr);  // TODO: DMB
        addr += 4;
    }

    // Set Packet Length - 1 in Bits 0 to 7 (TX_Size) of
    // DSI_CMD_CTL_REG (DSI Low Power Control Register) at Offset 0x200
    modreg32(@intCast(u32, pkt.len) - 1, 0xFF, DSI_CMD_CTL_REG);  // TODO: DMB

    // Set DSI_INST_JUMP_SEL_REG (Offset 0x48, undocumented) 
    // to begin the Low Power Transmission (LPTX)
    const DSI_INST_JUMP_SEL_REG = DSI_BASE_ADDRESS + 0x48;
    const DSI_INST_ID_LPDT = 4;
    const DSI_INST_ID_LP11 = 0;
    const DSI_INST_ID_END  = 15;
    putreg32(
        DSI_INST_ID_LPDT << (4 * DSI_INST_ID_LP11) |
        DSI_INST_ID_END  << (4 * DSI_INST_ID_LPDT),
        DSI_INST_JUMP_SEL_REG
    );

    // Disable DSI Processing then Enable DSI Processing
    disableDsiProcessing();
    enableDsiProcessing();

    // Wait for transmission to complete
    const res = waitForTransmit();
    if (res < 0) {
        disableDsiProcessing();
        return res;
    }

    // Return number of written bytes
    return @intCast(isize, len);
}

/// Wait for transmit to complete. Returns 0 if completed, -1 if timeout.
/// See https://lupyuen.github.io/articles/dsi#transmit-packet-over-mipi-dsi
fn waitForTransmit() isize {
    // Wait up to 5,000 microseconds
    var i: usize = 0;
    while (i < 5_000) : (i += 1) {
        // To check whether the transmission is complete, we poll on Instru_En
        if ((getreg32(DSI_BASIC_CTL0_REG) & Instru_En) == 0) {
            // If Instru_En is 0, then transmission is complete
            return 0;
        }
        // Sleep 1 microsecond
        _ = c.usleep(1);
    }
    // Return Timeout
    std.log.err("waitForTransmit: timeout", .{});
    return -1;
}

/// Disable DSI Processing. See https://lupyuen.github.io/articles/dsi#transmit-packet-over-mipi-dsi
fn disableDsiProcessing() void {
    // Set Instru_En to 0
    modreg32(0, Instru_En, DSI_BASIC_CTL0_REG);  // TODO: DMB
}

/// Enable DSI Processing. See https://lupyuen.github.io/articles/dsi#transmit-packet-over-mipi-dsi
fn enableDsiProcessing() void {
    // Set Instru_En to 1
    modreg32(Instru_En, Instru_En, DSI_BASIC_CTL0_REG);  // TODO: DMB
}

/// Modify the specified bits in a memory mapped register.
/// Based on https://github.com/apache/nuttx/blob/master/arch/arm64/src/common/arm64_arch.h#L473
fn modreg32(
    val: u32,   // Bits to set, like (1 << bit)
    comptime mask: u32,  // Bits to clear, like (1 << bit)
    addr: u64  // Address to modify
) void {
    debug("  *0x{x}: clear 0x{x}, set 0x{x}", .{ addr, mask, val & mask });
    assert(val & mask == val);
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
//  ST7703 LCD Controller

/// Initialise the ST7703 LCD Controller in Xingbangda XBD599 LCD Panel.
/// See https://lupyuen.github.io/articles/dsi#initialise-lcd-controller
pub export fn panel_init() void {
    debug("panel_init: start", .{});
    defer { debug("panel_init: end", .{}); }
    enableLog = false;  // Disable putreg32 log

    // Most of these commands are documented in the ST7703 Datasheet:
    // https://files.pine64.org/doc/datasheet/pinephone/ST7703_DS_v01_20160128.pdf

    // Command #1
    writeDcs(&[_]u8 { 
        0xB9,  // SETEXTC (Page 131): Enable USER Command
        0xF1,  // Enable User command
        0x12,  // (Continued)
        0x83   // (Continued)
    });

    // Command #2
    writeDcs(&[_]u8 { 
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
    });

    // Command #3
    writeDcs(&[_]u8 { 
        0xB8,  // SETPOWER_EXT (Page 142): Set display related register
        0x25,  // External power IC or PFM: VSP = FL1002, VSN = FL1002 (PCCS = 2) ; VCSW1 / VCSW2 Frequency for Pumping VSP / VSN = 1/4 Hsync (ECP_DC_DIV = 5)
        0x22,  // VCSW1/VCSW2 soft start time = 15 ms (DT = 2) ; Pumping ratio of VSP / VSN with VCI = x2 (XDK_ECP = 1)
        0x20,  // PFM operation frequency FoscD = Fosc/1 (PFM_DC_DIV = 0)
        0x03   // Enable power IC pumping frequency synchronization = Synchronize with external Hsync (ECP_SYNC_EN = 1) ; Enable VGH/VGL pumping frequency synchronization = Synchronize with external Hsync (VGX_SYNC_EN = 1)
    });

    // Command #4
    writeDcs(&[_]u8 { 
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
    });

    // Command #5
    writeDcs(&[_]u8 { 
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
    });

    // Command #6
    writeDcs(&[_]u8 { 
        0xBC,  // SETVDC (Page 146): Control NVDDD/VDDD Voltage
        0x4E   // NVDDD voltage = -1.8 V (NVDDD_SEL = 4) ; VDDD voltage = 1.9 V (VDDD_SEL = 6)
    });

    // Command #7
    writeDcs(&[_]u8 { 
        0xCC,  // SETPANEL (Page 154): Set display related register
        0x0B   // Enable reverse the source scan direction (SS_PANEL = 1) ; Normal vertical scan direction (GS_PANEL = 0) ; Normally black panel (REV_PANEL = 1) ; S1:S2:S3 = B:G:R (BGR_PANEL = 1)
    });

    // Command #8
    writeDcs(&[_]u8 { 
        0xB4,  // SETCYC (Page 135): Control display inversion type
        0x80   // Extra source for Zig-Zag Inversion = S2401 (ZINV_S2401_EN = 1) ; Row source data dislocates = Even row (ZINV_G_EVEN_EN = 0) ; Disable Zig-Zag Inversion (ZINV_EN = 0) ; Enable Zig-Zag1 Inversion (ZINV2_EN = 0) ; Normal mode inversion type = Column inversion (N_NW = 0)
    });

    // Command #9
    writeDcs(&[_]u8 {
        0xB2,  // SETDISP (Page 132): Control the display resolution
        0xF0,  // Gate number of vertical direction = 480 + (240*4) (NL = 240)
        0x12,  // (RES_V_LSB = 0) ; Non-display area source output control: Source output = VSSD (BLK_CON = 1) ; Channel number of source direction = 720RGB (RESO_SEL = 2)
        0xF0   // Source voltage during Blanking Time when accessing Sleep-Out / Sleep-In command = GND (WHITE_GND_EN = 1) ; Blank timing control when access sleep out command: Blank Frame Period = 7 Frames (WHITE_FRAME_SEL = 7) ; Source output refresh control: Refresh Period = 0 Frames (ISC = 0)
    });

    // Command #10
    writeDcs(&[_]u8 { 
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
    });

    // Command #11
    writeDcs(&[_]u8 { 
        0xC6,  // Undocumented
        0x01,  // Undocumented
        0x00,  // Undocumented
        0xFF,  // Undocumented
        0xFF,  // Undocumented
        0x00   // Undocumented
    });

    // Command #12
    writeDcs(&[_]u8 { 
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
    });

    // Command #13
    writeDcs(&[_]u8 { 
        0xB5,  // SETBGP (Page 136): Internal reference voltage setting
        0x07,  // VREF Voltage: 4.2 V (VREF_SEL = 7)
        0x07   // NVREF Voltage: 4.2 V (NVREF_SEL = 7)
    });

    // Command #14
    writeDcs(&[_]u8 { 
        0xB6,  // SETVCOM (Page 137): Set VCOM Voltage
        0x2C,  // VCOMDC voltage at "GS_PANEL=0" = -0.67 V (VCOMDC_F = 0x2C)
        0x2C   // VCOMDC voltage at "GS_PANEL=1" = -0.67 V (VCOMDC_B = 0x2C)
    });

    // Command #15
    writeDcs(&[_]u8 { 
        0xBF,  // Undocumented
        0x02,  // Undocumented
        0x11,  // Undocumented
        0x00   // Undocumented
    });

    // Command #16
    writeDcs(&[_]u8 { 
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
    });

    // Command #17
    writeDcs(&[_]u8 { 
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
    });

    // Command #18
    writeDcs(&[_]u8 { 
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
    });

    // Command #19    
    writeDcs(&[_]u8 {
        0x11  // SLPOUT (Page 89): Turns off sleep mode (MIPI_DCS_EXIT_SLEEP_MODE)
    });

    // Wait 120 milliseconds
    _ = c.usleep(120 * 1000);

    // Command #20
    writeDcs(&[_]u8 {
        0x29  // Display On (Page 97): Recover from DISPLAY OFF mode (MIPI_DCS_SET_DISPLAY_ON)
    });    
}

///////////////////////////////////////////////////////////////////////////////
//  MIPI DSI Block

/// Enable MIPI DSI Block.
/// Based on https://lupyuen.github.io/articles/dsi#appendix-enable-mipi-dsi-block
pub export fn enable_dsi_block() void {
    debug("enable_dsi_block: start", .{});
    defer { debug("enable_dsi_block: end", .{}); }
    enableLog = true;  // Enable putreg32 log

    // Enable MIPI DSI Bus
    // BUS_CLK_GATING_REG0: CCU Offset 0x60 (A64 Page 100)
    // Set MIPIDSI_GATING (Bit 1) to 1 (Pass Gating Clock for MIPI DSI)
    debug("Enable MIPI DSI Bus", .{});
    const BUS_CLK_GATING_REG0 = CCU_BASE_ADDRESS + 0x60;
    comptime{ assert(BUS_CLK_GATING_REG0 == 0x1c20060); }

    const MIPIDSI_GATING: u2 = 1 << 1;
    comptime{ assert(MIPIDSI_GATING == 2); }
    modreg32(MIPIDSI_GATING, MIPIDSI_GATING, BUS_CLK_GATING_REG0);  // TODO: DMB

    // BUS_SOFT_RST_REG0: CCU Offset 0x2C0 (A64 Page 138)
    // Set MIPI_DSI_RST (Bit 1) to 1 (Deassert MIPI DSI Reset)
    const BUS_SOFT_RST_REG0 = CCU_BASE_ADDRESS + 0x2C0;
    comptime{ assert(BUS_SOFT_RST_REG0 == 0x1c202c0); }

    const MIPI_DSI_RST: u2 = 1 << 1;
    comptime{ assert(MIPI_DSI_RST == 2); }
    modreg32(MIPI_DSI_RST, MIPI_DSI_RST, BUS_SOFT_RST_REG0);  // TODO: DMB

    // Enable DSI Block
    // DSI_CTL_REG: DSI Offset 0x0 (A31 Page 843)
    // Set DSI_En (Bit 0) to 1 (Enable DSI)
    debug("Enable DSI Block", .{});
    const DSI_CTL_REG = DSI_BASE_ADDRESS + 0x0;
    comptime{ assert(DSI_CTL_REG == 0x1ca0000); }

    const DSI_En: u1 = 1 << 0;
    comptime{ assert(DSI_En == 1); }
    putreg32(DSI_En, DSI_CTL_REG);  // TODO: DMB

    // DSI_BASIC_CTL0_REG: DSI Offset 0x10 (A31 Page 845)
    // Set CRC_En (Bit 17) to 1 (Enable CRC)
    // Set ECC_En (Bit 16) to 1 (Enable ECC)
    comptime{ assert(DSI_BASIC_CTL0_REG == 0x1ca0010); }

    const CRC_En: u18 = 1 << 17;
    const ECC_En: u17 = 1 << 16;
    const DSI_BASIC_CTL0 = CRC_En
        | ECC_En;
    comptime{ assert(DSI_BASIC_CTL0 == 0x30000); }
    putreg32(DSI_BASIC_CTL0, DSI_BASIC_CTL0_REG);  // TODO: DMB

    // DSI_TRANS_START_REG: DSI Offset 0x60 (Undocumented)
    // Set to 10
    const DSI_TRANS_START_REG = DSI_BASE_ADDRESS + 0x60;
    comptime{ assert(DSI_TRANS_START_REG == 0x1ca0060); }
    putreg32(10, DSI_TRANS_START_REG);  // TODO: DMB

    // DSI_TRANS_ZERO_REG: DSI Offset 0x78 (Undocumented)
    // Set to 0
    const DSI_TRANS_ZERO_REG = DSI_BASE_ADDRESS + 0x78;
    comptime{ assert(DSI_TRANS_ZERO_REG == 0x1ca0078); }
    putreg32(0, DSI_TRANS_ZERO_REG);  // TODO: DMB

    // Set Instructions (Undocumented)
    // DSI_INST_FUNC_REG(0): DSI Offset 0x20
    // Set to 0x1f
    // Index 0 is DSI_INST_ID_LP11
    debug("Set Instructions", .{});
    const DSI_INST_ID_LP11 = 0;
    comptime{ assert(DSI_INST_FUNC_REG(DSI_INST_ID_LP11) == 0x1ca0020); }
    putreg32(0x1f, DSI_INST_FUNC_REG(DSI_INST_ID_LP11));  // TODO: DMB

    // DSI_INST_FUNC_REG(1): DSI Offset 0x24
    // Set to 0x1000 0001
    // Index 1 is DSI_INST_ID_TBA
    const DSI_INST_ID_TBA = 1;
    comptime{ assert(DSI_INST_FUNC_REG(DSI_INST_ID_TBA) == 0x1ca0024); }
    putreg32(0x1000_0001, DSI_INST_FUNC_REG(DSI_INST_ID_TBA));  // TODO: DMB

    // DSI_INST_FUNC_REG(2): DSI Offset 0x28
    // Set to 0x2000 0010
    // Index 2 is DSI_INST_ID_HSC
    const DSI_INST_ID_HSC = 2;
    comptime{ assert(DSI_INST_FUNC_REG(DSI_INST_ID_HSC) == 0x1ca0028); }
    putreg32(0x2000_0010, DSI_INST_FUNC_REG(DSI_INST_ID_HSC));  // TODO: DMB

    // DSI_INST_FUNC_REG(3): DSI Offset 0x2c
    // Set to 0x2000 000f
    // Index 3 is DSI_INST_ID_HSD
    const DSI_INST_ID_HSD = 3;
    comptime{ assert(DSI_INST_FUNC_REG(DSI_INST_ID_HSD) == 0x1ca002c); }
    putreg32(0x2000_000f, DSI_INST_FUNC_REG(DSI_INST_ID_HSD));  // TODO: DMB

    // DSI_INST_FUNC_REG(4): DSI Offset 0x30
    // Set to 0x3010 0001
    // Index 4 is DSI_INST_ID_LPDT
    const DSI_INST_ID_LPDT = 4;
    comptime{ assert(DSI_INST_FUNC_REG(DSI_INST_ID_LPDT) == 0x1ca0030); }
    putreg32(0x3010_0001, DSI_INST_FUNC_REG(DSI_INST_ID_LPDT));  // TODO: DMB

    // DSI_INST_FUNC_REG(5): DSI Offset 0x34
    // Set to 0x4000 0010
    // Index 5 is DSI_INST_ID_HSCEXIT
    const DSI_INST_ID_HSCEXIT = 5;
    comptime{ assert(DSI_INST_FUNC_REG(DSI_INST_ID_HSCEXIT) == 0x1ca0034); }
    putreg32(0x4000_0010, DSI_INST_FUNC_REG(DSI_INST_ID_HSCEXIT));  // TODO: DMB

    // DSI_INST_FUNC_REG(6): DSI Offset 0x38
    // Set to 0xf
    // Index 6 is DSI_INST_ID_NOP
    const DSI_INST_ID_NOP = 6;
    comptime{ assert(DSI_INST_FUNC_REG(DSI_INST_ID_NOP) == 0x1ca0038); }
    putreg32(0xf, DSI_INST_FUNC_REG(DSI_INST_ID_NOP));  // TODO: DMB

    // DSI_INST_FUNC_REG(7): DSI Offset 0x3c
    // Set to 0x5000 001f
    // Index 7 is DSI_INST_ID_DLY
    const DSI_INST_ID_DLY = 7;
    comptime{ assert(DSI_INST_FUNC_REG(DSI_INST_ID_DLY) == 0x1ca003c); }
    putreg32(0x5000_001f, DSI_INST_FUNC_REG(DSI_INST_ID_DLY));  // TODO: DMB

    // Configure Jump Instructions (Undocumented)
    // DSI_INST_JUMP_CFG_REG(0): DSI Offset 0x4c
    // Set to 0x56 0001    
    // Index 0 is DSI_INST_JUMP_CFG
    debug("Configure Jump Instructions", .{});
    const DSI_INST_JUMP_CFG = 0;
    comptime{ assert(DSI_INST_JUMP_CFG_REG(DSI_INST_JUMP_CFG) == 0x1ca004c); }
    putreg32(0x56_0001, DSI_INST_JUMP_CFG_REG(DSI_INST_JUMP_CFG));  // TODO: DMB

    // DSI_DEBUG_DATA_REG: DSI Offset 0x2f8
    // Set to 0xff
    const DSI_DEBUG_DATA_REG = DSI_BASE_ADDRESS + 0x2f8;
    comptime{ assert(DSI_DEBUG_DATA_REG == 0x1ca02f8); }
    putreg32(0xff, DSI_DEBUG_DATA_REG);  // TODO: DMB

    // Set Video Start Delay
    // DSI_BASIC_CTL1_REG: DSI Offset 0x14 (A31 Page 846)
    // Set Video_Start_Delay (Bits 4 to 16) to 1468 (Line Delay)
    // Set Video_Precision_Mode_Align (Bit 2) to 1 (Fill Mode)
    // Set Video_Frame_Start (Bit 1) to 1 (Precision Mode)
    // Set DSI_Mode (Bit 0) to 1 (Video Mode)
    // TODO: Video_Start_Delay is actually 13 bits, not 8 bits as documented in the A31 User Manual
    debug("Set Video Start Delay", .{});
    const DSI_BASIC_CTL1_REG = DSI_BASE_ADDRESS + 0x14;
    comptime{ assert(DSI_BASIC_CTL1_REG == 0x1ca0014); }

    const Video_Start_Delay:          u17 = 1468 << 4;
    const Video_Precision_Mode_Align: u3  = 1    << 2;
    const Video_Frame_Start:          u2  = 1    << 1;
    const DSI_Mode:                   u1  = 1    << 0;
    const DSI_BASIC_CTL1 = Video_Start_Delay
        | Video_Precision_Mode_Align
        | Video_Frame_Start
        | DSI_Mode;
    comptime{ assert(DSI_BASIC_CTL1 == 0x5bc7); }
    putreg32(DSI_BASIC_CTL1, DSI_BASIC_CTL1_REG);  // TODO: DMB

    // Set Burst (Undocumented)
    // DSI_TCON_DRQ_REG: DSI Offset 0x7c
    // Set to 0x1000 0007
    debug("Set Burst", .{});
    const DSI_TCON_DRQ_REG = DSI_BASE_ADDRESS + 0x7c;
    comptime{ assert(DSI_TCON_DRQ_REG == 0x1ca007c); }
    putreg32(0x1000_0007, DSI_TCON_DRQ_REG);  // TODO: DMB

    // Set Instruction Loop (Undocumented)
    // DSI_INST_LOOP_SEL_REG: DSI Offset 0x40
    // Set to 0x3000 0002
    debug("Set Instruction Loop", .{});
    const DSI_INST_LOOP_SEL_REG = DSI_BASE_ADDRESS + 0x40;
    comptime{ assert(DSI_INST_LOOP_SEL_REG == 0x1ca0040); }
    putreg32(0x3000_0002, DSI_INST_LOOP_SEL_REG);  // TODO: DMB

    // DSI_INST_LOOP_NUM_REG(0): DSI Offset 0x44
    // Set to 0x31 0031
    comptime{ assert(DSI_INST_LOOP_NUM_REG(0) == 0x1ca0044); }
    putreg32(0x310031, DSI_INST_LOOP_NUM_REG(0));  // TODO: DMB

    // DSI_INST_LOOP_NUM_REG(1): DSI Offset 0x54
    // Set to 0x31 0031
    comptime{ assert(DSI_INST_LOOP_NUM_REG(1) == 0x1ca0054); }
    putreg32(0x310031, DSI_INST_LOOP_NUM_REG(1));  // TODO: DMB

    // Set Pixel Format
    // DSI_PIXEL_PH_REG: DSI Offset 0x90 (A31 Page 848)
    // Set ECC (Bits 24 to 31) to 19
    // Set WC (Bits 8 to 23) to 2160 (Byte Numbers of PD in a Pixel Packet)
    // Set VC (Bits 6 to 7) to 0 (Virtual Channel)
    // Set DT (Bits 0 to 5) to 0x3E (24-bit Video Mode)
    debug("Set Pixel Format", .{});
    const DSI_PIXEL_PH_REG = DSI_BASE_ADDRESS + 0x90;
    comptime{ assert(DSI_PIXEL_PH_REG == 0x1ca0090); }
    {
        const ECC: u32 = 19   << 24;
        const WC:  u24 = 2160 << 8;
        const VC:  u8  = VIRTUAL_CHANNEL << 6;
        const DT:  u6  = 0x3E << 0;
        const DSI_PIXEL_PH = ECC
            | WC
            | VC
            | DT;
        comptime{ assert(DSI_PIXEL_PH == 0x1308703e); }
        putreg32(DSI_PIXEL_PH, DSI_PIXEL_PH_REG);  // TODO: DMB
    }

    // DSI_PIXEL_PF0_REG: DSI Offset 0x98 (A31 Page 849)
    // Set CRC_Force (Bits 0 to 15) to 0xffff (Force CRC to this value)
    const DSI_PIXEL_PF0_REG = DSI_BASE_ADDRESS + 0x98;
    comptime{ assert(DSI_PIXEL_PF0_REG == 0x1ca0098); }
    const CRC_Force: u16 = 0xffff;
    putreg32(CRC_Force, DSI_PIXEL_PF0_REG);  // TODO: DMB

    // DSI_PIXEL_PF1_REG: DSI Offset 0x9c (A31 Page 849)
    // Set CRC_Init_LineN (Bits 16 to 31) to 0xffff (CRC initial to this value in transmitions except 1st one)
    // Set CRC_Init_Line0 (Bits 0 to 15) to 0xffff (CRC initial to this value in 1st transmition every frame)
    const DSI_PIXEL_PF1_REG = DSI_BASE_ADDRESS + 0x9c;
    comptime{ assert(DSI_PIXEL_PF1_REG == 0x1ca009c); }

    const CRC_Init_LineN: u32 = 0xffff << 16;
    const CRC_Init_Line0: u16 = 0xffff << 0;
    const DSI_PIXEL_PF1 = CRC_Init_LineN
        | CRC_Init_Line0;
    comptime{ assert(DSI_PIXEL_PF1 == 0xffffffff); }
    putreg32(DSI_PIXEL_PF1, DSI_PIXEL_PF1_REG);  // TODO: DMB

    // DSI_PIXEL_CTL0_REG: DSI Offset 0x80 (A31 Page 847)
    // Set PD_Plug_Dis (Bit 16) to 1 (Disable PD plug before pixel bytes)
    // Set Pixel_Endian (Bit 4) to 0 (LSB first)
    // Set Pixel_Format (Bits 0 to 3) to 8 (24-bit RGB888)
    const DSI_PIXEL_CTL0_REG = DSI_BASE_ADDRESS + 0x80;
    comptime{ assert(DSI_PIXEL_CTL0_REG == 0x1ca0080); }

    const PD_Plug_Dis:  u17 = 1 << 16;
    const Pixel_Endian: u5  = 0 << 4;
    const Pixel_Format: u4  = 8 << 0;
    const DSI_PIXEL_CTL0 = PD_Plug_Dis
        | Pixel_Endian
        | Pixel_Format;
    comptime{ assert(DSI_PIXEL_CTL0 == 0x10008); }
    putreg32(DSI_PIXEL_CTL0, DSI_PIXEL_CTL0_REG);  // TODO: DMB

    // Set Sync Timings
    // DSI_BASIC_CTL_REG: DSI Offset 0x0c (Undocumented)
    // Set to 0
    debug("Set Sync Timings", .{});
    const DSI_BASIC_CTL_REG = DSI_BASE_ADDRESS + 0x0c;
    comptime{ assert(DSI_BASIC_CTL_REG == 0x1ca000c); }
    putreg32(0x0, DSI_BASIC_CTL_REG);  // TODO: DMB

    // DSI_SYNC_HSS_REG: DSI Offset 0xb0 (A31 Page 850)
    // Set ECC (Bits 24 to 31) to 0x12
    // Set D1 (Bits 16 to 23) to 0
    // Set D0 (Bits 8 to 15) to 0
    // Set VC (Bits 6 to 7) to 0 (Virtual Channel)
    // Set DT (Bits 0 to 5) to 0x21 (HSS)
    const DSI_SYNC_HSS_REG = DSI_BASE_ADDRESS + 0xb0;
    comptime{ assert(DSI_SYNC_HSS_REG == 0x1ca00b0); }
    {
        const ECC: u32 = 0x12 << 24;
        const D1:  u24 = 0    << 16;
        const D0:  u16 = 0    << 8;
        const VC:  u8  = VIRTUAL_CHANNEL << 6;
        const DT:  u6  = 0x21 << 0;
        const DSI_SYNC_HSS = ECC
            | D1
            | D0
            | VC
            | DT;
        comptime{ assert(DSI_SYNC_HSS == 0x12000021); }
        putreg32(DSI_SYNC_HSS, DSI_SYNC_HSS_REG);  // TODO: DMB
    }

    // DSI_SYNC_HSE_REG: DSI Offset 0xb4 (A31 Page 850)
    // Set ECC (Bits 24 to 31) to 1
    // Set D1 (Bits 16 to 23) to 0
    // Set D0 (Bits 8 to 15) to 0
    // Set VC (Bits 6 to 7) to 0 (Virtual Channel)
    // Set DT (Bits 0 to 5) to 0x31 (HSE)
    const DSI_SYNC_HSE_REG = DSI_BASE_ADDRESS + 0xb4;
    comptime{ assert(DSI_SYNC_HSE_REG == 0x1ca00b4); }
    {
        const ECC: u32 = 1    << 24;
        const D1:  u24 = 0    << 16;
        const D0:  u16 = 0    << 8;
        const VC:  u8  = VIRTUAL_CHANNEL << 6;
        const DT:  u6  = 0x31 << 0;
        const DSI_SYNC_HSE = ECC
            | D1
            | D0
            | VC
            | DT;
        comptime{ assert(DSI_SYNC_HSE == 0x1000031); }
        putreg32(DSI_SYNC_HSE, DSI_SYNC_HSE_REG);  // TODO: DMB
    }

    // DSI_SYNC_VSS_REG: DSI Offset 0xb8 (A31 Page 851)
    // Set ECC (Bits 24 to 31) to 7
    // Set D1 (Bits 16 to 23) to 0
    // Set D0 (Bits 8 to 15) to 0
    // Set VC (Bits 6 to 7) to 0 (Virtual Channel)
    // Set DT (Bits 0 to 5) to 1 (VSS)
    const DSI_SYNC_VSS_REG = DSI_BASE_ADDRESS + 0xb8;
    comptime{ assert(DSI_SYNC_VSS_REG == 0x1ca00b8); }
    {
        const ECC: u32 = 7 << 24;
        const D1:  u24 = 0 << 16;
        const D0:  u16 = 0 << 8;
        const VC:  u8  = VIRTUAL_CHANNEL << 6;
        const DT:  u6  = 1 << 0;
        const DSI_SYNC_VSS = ECC
            | D1
            | D0
            | VC
            | DT;
        comptime{ assert(DSI_SYNC_VSS == 0x7000001); }
        putreg32(DSI_SYNC_VSS, DSI_SYNC_VSS_REG);  // TODO: DMB
    }

    // DSI_SYNC_VSE_REG: DSI Offset 0xbc (A31 Page 851)
    // Set ECC (Bits 24 to 31) to 0x14
    // Set D1 (Bits 16 to 23) to 0
    // Set D0 (Bits 8 to 15) to 0
    // Set VC (Bits 6 to 7) to 0 (Virtual Channel)
    // Set DT (Bits 0 to 5) to 0x11 (VSE)
    const DSI_SYNC_VSE_REG = DSI_BASE_ADDRESS + 0xbc;
    comptime{ assert(DSI_SYNC_VSE_REG == 0x1ca00bc); }
    {
        const ECC: u32 = 0x14 << 24;
        const D1:  u24 = 0    << 16;
        const D0:  u16 = 0    << 8;
        const VC:  u8  = VIRTUAL_CHANNEL << 6;
        const DT:  u6  = 0x11 << 0;
        const DSI_SYNC_VSE = ECC
            | D1
            | D0
            | VC
            | DT;
        comptime{ assert(DSI_SYNC_VSE == 0x14000011); }
        putreg32(DSI_SYNC_VSE, DSI_SYNC_VSE_REG);  // TODO: DMB
    }

    // Set Basic Size (Undocumented)
    // DSI_BASIC_SIZE0_REG: DSI Offset 0x18
    // Set Video_VBP (Bits 16 to 27) to 17
    // Set Video_VSA (Bits 0 to 11) to 10
    debug("Set Basic Size", .{});
    const DSI_BASIC_SIZE0_REG = DSI_BASE_ADDRESS + 0x18;
    comptime{ assert(DSI_BASIC_SIZE0_REG == 0x1ca0018); }

    const Video_VBP: u28 = 17 << 16;
    const Video_VSA: u12 = 10 << 0;
    const DSI_BASIC_SIZE0 = Video_VBP
        | Video_VSA;
    comptime{ assert(DSI_BASIC_SIZE0 == 0x11000a); }
    putreg32(DSI_BASIC_SIZE0, DSI_BASIC_SIZE0_REG);  // TODO: DMB

    // DSI_BASIC_SIZE1_REG: DSI Offset 0x1c
    // Set Video_VT (Bits 16 to 28) to 1485
    // Set Video_VACT (Bits 0 to 11) to 1440
    const DSI_BASIC_SIZE1_REG = DSI_BASE_ADDRESS + 0x1c;
    comptime{ assert(DSI_BASIC_SIZE1_REG == 0x1ca001c); }

    const Video_VT:   u28 = 1485 << 16;
    const Video_VACT: u12 = 1440 << 0;
    const DSI_BASIC_SIZE1 = Video_VT
        | Video_VACT;
    comptime{ assert(DSI_BASIC_SIZE1 == 0x5cd05a0); }
    putreg32(DSI_BASIC_SIZE1, DSI_BASIC_SIZE1_REG);  // TODO: DMB

    // Set Horizontal Blanking
    // DSI_BLK_HSA0_REG: DSI Offset 0xc0 (A31 Page 852)
    // Set HSA_PH (Bits 0 to 31) to 0x900 4a19
    debug("Set Horizontal Blanking", .{});
    const DSI_BLK_HSA0_REG = DSI_BASE_ADDRESS + 0xc0;
    comptime{ assert(DSI_BLK_HSA0_REG == 0x1ca00c0); }
    const DSI_BLK_HSA0 = 0x9004a19;
    putreg32(DSI_BLK_HSA0, DSI_BLK_HSA0_REG);  // TODO: DMB

    // DSI_BLK_HSA1_REG: DSI Offset 0xc4 (A31 Page 852)
    // Set HSA_PF (Bits 16 to 31) to 0x50b4
    // Set HSA_PD (Bits 0 to 7) to 0
    const DSI_BLK_HSA1_REG = DSI_BASE_ADDRESS + 0xc4;
    comptime{ assert(DSI_BLK_HSA1_REG == 0x1ca00c4); }

    const HSA_PF: u32 = 0x50b4 << 16;
    const HSA_PD: u8  = 0      << 0;
    const DSI_BLK_HSA1 = HSA_PF
        | HSA_PD;
    comptime{ assert(DSI_BLK_HSA1 == 0x50b40000); }
    putreg32(DSI_BLK_HSA1, DSI_BLK_HSA1_REG);  // TODO: DMB

    // DSI_BLK_HBP0_REG: DSI Offset 0xc8 (A31 Page 852)
    // Set HBP_PH (Bits 0 to 31) to 0x3500 5419
    const DSI_BLK_HBP0_REG = DSI_BASE_ADDRESS + 0xc8;
    comptime{ assert(DSI_BLK_HBP0_REG == 0x1ca00c8); }
    putreg32(0x35005419, DSI_BLK_HBP0_REG);  // TODO: DMB

    // DSI_BLK_HBP1_REG: DSI Offset 0xcc (A31 Page 852)
    // Set HBP_PF (Bits 16 to 31) to 0x757a
    // Set HBP_PD (Bits 0 to 7) to 0
    const DSI_BLK_HBP1_REG = DSI_BASE_ADDRESS + 0xcc;
    comptime{ assert(DSI_BLK_HBP1_REG == 0x1ca00cc); }

    const HBP_PF: u32 = 0x757a << 16;
    const HBP_PD: u8  = 0      << 0;
    const DSI_BLK_HBP1 = HBP_PF
        | HBP_PD;
    comptime{ assert(DSI_BLK_HBP1 == 0x757a0000); }
    putreg32(DSI_BLK_HBP1, DSI_BLK_HBP1_REG);  // TODO: DMB

    // DSI_BLK_HFP0_REG: DSI Offset 0xd0 (A31 Page 852)
    // Set HFP_PH (Bits 0 to 31) to 0x900 4a19
    const DSI_BLK_HFP0_REG = DSI_BASE_ADDRESS + 0xd0;
    comptime{ assert(DSI_BLK_HFP0_REG == 0x1ca00d0); }
    putreg32(0x9004a19,  DSI_BLK_HFP0_REG);  // TODO: DMB

    // DSI_BLK_HFP1_REG: DSI Offset 0xd4 (A31 Page 853)
    // Set HFP_PF (Bits 16 to 31) to 0x50b4
    // Set HFP_PD (Bits 0 to 7) to 0
    const DSI_BLK_HFP1_REG = DSI_BASE_ADDRESS + 0xd4;
    comptime{ assert(DSI_BLK_HFP1_REG == 0x1ca00d4); }

    const HFP_PF: u32 = 0x50b4 << 16;
    const HFP_PD: u8  = 0      << 0;
    const DSI_BLK_HFP1 = HFP_PF
        | HFP_PD;
    comptime{ assert(DSI_BLK_HFP1 == 0x50b40000); }
    putreg32(DSI_BLK_HFP1, DSI_BLK_HFP1_REG);  // TODO: DMB

    // DSI_BLK_HBLK0_REG: DSI Offset 0xe0 (A31 Page 853)
    // Set HBLK_PH (Bits 0 to 31) to 0xc09 1a19
    const DSI_BLK_HBLK0_REG = DSI_BASE_ADDRESS + 0xe0;
    comptime{ assert(DSI_BLK_HBLK0_REG == 0x1ca00e0); }
    putreg32(0xc091a19,  DSI_BLK_HBLK0_REG);  // TODO: DMB

    // DSI_BLK_HBLK1_REG: DSI Offset 0xe4 (A31 Page 853)
    // Set HBLK_PF (Bits 16 to 31) to 0x72bd
    // Set HBLK_PD (Bits 0 to 7) to 0
    const DSI_BLK_HBLK1_REG = DSI_BASE_ADDRESS + 0xe4;
    comptime{ assert(DSI_BLK_HBLK1_REG == 0x1ca00e4); }

    const HBLK_PF: u32 = 0x72bd << 16;
    const HBLK_PD: u8  = 0      << 0;
    const DSI_BLK_HBLK1 = HBLK_PF
        | HBLK_PD;
    comptime{ assert(DSI_BLK_HBLK1 == 0x72bd0000); }
    putreg32(DSI_BLK_HBLK1, DSI_BLK_HBLK1_REG);  // TODO: DMB

    // Set Vertical Blanking
    // DSI_BLK_VBLK0_REG: DSI Offset 0xe8 (A31 Page 854)
    // Set VBLK_PH (Bits 0 to 31) to 0x1a00 0019
    debug("Set Vertical Blanking", .{});
    const DSI_BLK_VBLK0_REG = DSI_BASE_ADDRESS + 0xe8;
    comptime{ assert(DSI_BLK_VBLK0_REG == 0x1ca00e8); }
    putreg32(0x1a000019, DSI_BLK_VBLK0_REG);  // TODO: DMB

    // DSI_BLK_VBLK1_REG: DSI Offset 0xec (A31 Page 854)
    // Set VBLK_PF (Bits 16 to 31) to 0xffff
    // Set VBLK_PD (Bits 0 to 7) to 0
    const DSI_BLK_VBLK1_REG = DSI_BASE_ADDRESS + 0xec;
    comptime{ assert(DSI_BLK_VBLK1_REG == 0x1ca00ec); }

    const VBLK_PF: u32 = 0xffff << 16;
    const VBLK_PD: u8  = 0      << 0;
    const DSI_BLK_VBLK1 = VBLK_PF
        | VBLK_PD;
    comptime{ assert(DSI_BLK_VBLK1 == 0xffff0000); }
    putreg32(DSI_BLK_VBLK1, DSI_BLK_VBLK1_REG);  // TODO: DMB
}

/// DSI_INST_FUNC_REG(n) is (0x020 + (n) * 0x04)
fn DSI_INST_FUNC_REG(n: u8) u64 {
    return DSI_BASE_ADDRESS 
        + (0x020 + @intCast(u64, n) * 0x04);
}

/// DSI_INST_JUMP_CFG_REG(n) is (0x04c + (n) * 0x04)
fn DSI_INST_JUMP_CFG_REG(n: u8) u64 {
    return DSI_BASE_ADDRESS 
        + (0x04c + @intCast(u64, n) * 0x04);
}

/// DSI_INST_LOOP_NUM_REG(n) is (0x044 + (n) * 0x10)
fn DSI_INST_LOOP_NUM_REG(n: u8) u64 {
    return DSI_BASE_ADDRESS 
        + (0x044 + @intCast(u64, n) * 0x10);
}

///////////////////////////////////////////////////////////////////////////////
//  MIPI DSI HSC / HSD

/// Start MIPI DSI HSC and HSD. (High Speed Clock Mode and High Speed Data Transmission)
/// Based on https://lupyuen.github.io/articles/dsi#appendix-start-mipi-dsi-hsc-and-hsd
pub export fn start_dsi() void {
    debug("start_dsi: start", .{});
    defer { debug("start_dsi: end", .{}); }
    enableLog = true;  // Enable putreg32 log

    // Start HSC (Undocumented)
    // DSI_INST_JUMP_SEL_REG: DSI Offset 0x48
    // Set to 0xf02
    debug("Start HSC", .{});
    const DSI_INST_JUMP_SEL_REG = DSI_BASE_ADDRESS + 0x48;
    comptime{ assert(DSI_INST_JUMP_SEL_REG == 0x1ca0048); }
    putreg32(0xf02, DSI_INST_JUMP_SEL_REG);  // TODO: DMB

    // Commit
    // DSI_BASIC_CTL0_REG: DSI Offset 0x10 (A31 Page 845)
    // Set Instru_En (Bit 0) to 1 (Enable DSI Processing from Instruction 0)
    debug("Commit", .{});
    comptime{ assert(DSI_BASIC_CTL0_REG == 0x1ca0010); }
    comptime{ assert(Instru_En == 0x1); }
    modreg32(Instru_En, Instru_En, DSI_BASIC_CTL0_REG);  // TODO: DMB

    // (DSI_INST_FUNC_REG(n) is (0x020 + (n) * 0x04))

    // Instruction Function Lane (Undocumented)
    // DSI_INST_FUNC_REG(0): DSI Offset 0x20
    // Set DSI_INST_FUNC_LANE_CEN (Bit 4) to 0
    // Index 0 is DSI_INST_ID_LP11
    debug("Instruction Function Lane", .{});
    comptime{ assert(DSI_INST_FUNC_REG(0) == 0x1ca0020); }

    const DSI_INST_FUNC_LANE_CEN: u5 = 1 << 4;
    comptime { assert(DSI_INST_FUNC_LANE_CEN == 0x10); }
    modreg32(0x0, DSI_INST_FUNC_LANE_CEN, DSI_INST_FUNC_REG(0) );  // TODO: DMB

    // Wait 1,000 microseconds
    _ = c.usleep(1000);

    // Start HSD (Undocumented)
    // DSI_INST_JUMP_SEL_REG: DSI Offset 0x48
    // Set to 0x63f0 7006
    debug("Start HSD", .{});
    comptime{ assert(DSI_INST_JUMP_SEL_REG == 0x1ca0048); }
    putreg32(0x63f07006, DSI_INST_JUMP_SEL_REG);  // TODO: DMB

    // Commit
    // DSI_BASIC_CTL0_REG: DSI Offset 0x10 (A31 Page 845)
    // Set Instru_En (Bit 0) to 1 (Enable DSI Processing from Instruction 0)
    debug("Commit", .{});
    comptime{ assert(DSI_BASIC_CTL0_REG == 0x1ca0010); }
    comptime{ assert(Instru_En == 0x1); }
    modreg32(Instru_En, Instru_En, DSI_BASIC_CTL0_REG);  // TODO: DMB
}

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

// Dump the buffer as hex
fn dump_buffer(data: []const u8) void {
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        _ = printf("%02x ", data[i]);
        if ((i + 1) % 8 == 0) { _ = printf("\n"); }
    }
    _ = printf("\n");
}

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
    debug("test_zig: start", .{});
    defer { debug("test_zig: end", .{}); }

    // Allocate Packet Buffer
    var pkt_buf = std.mem.zeroes([128]u8);

    // Test Compose Short Packet (Without Parameter)
    debug("Testing Compose Short Packet (Without Parameter)...", .{});
    const short_pkt = [_]u8 {
        0x11,
    };
    const short_pkt_result = composeShortPacket(
        &pkt_buf,  //  Packet Buffer
        0,         //  Virtual Channel
        MIPI_DSI_DCS_SHORT_WRITE, // DCS Command
        &short_pkt,    // Transmit Buffer
        short_pkt.len  // Buffer Length
    );
    debug("Result:", .{});
    dump_buffer(short_pkt_result);
    assert(  //  Verify result
        std.mem.eql(
            u8,
            short_pkt_result,
            &[_]u8 { 
                0x05, 0x11, 0x00, 0x36 
            }
        )
    );

    // Write to MIPI DSI
    // _ = nuttx_mipi_dsi_dcs_write(
    //     null,  //  Device
    //     0,     //  Virtual Channel
    //     MIPI_DSI_DCS_SHORT_WRITE, // DCS Command
    //     &short_pkt,    // Transmit Buffer
    //     short_pkt.len  // Buffer Length
    // );

    // Test Compose Short Packet (With Parameter)
    debug("Testing Compose Short Packet (With Parameter)...", .{});
    const short_pkt_param = [_]u8 {
        0xbc, 0x4e,
    };
    const short_pkt_param_result = composeShortPacket(
        &pkt_buf,  //  Packet Buffer
        0,         //  Virtual Channel
        MIPI_DSI_DCS_SHORT_WRITE_PARAM, // DCS Command
        &short_pkt_param,    // Transmit Buffer
        short_pkt_param.len  // Buffer Length
    );
    debug("Result:", .{});
    dump_buffer(short_pkt_param_result);
    assert(  //  Verify result
        std.mem.eql(
            u8,
            short_pkt_param_result,
            &[_]u8 { 
                0x15, 0xbc, 0x4e, 0x35 
            }
        )
    );

    // Write to MIPI DSI
    // _ = nuttx_mipi_dsi_dcs_write(
    //     null,  //  Device
    //     0,     //  Virtual Channel
    //     MIPI_DSI_DCS_SHORT_WRITE_PARAM, // DCS Command
    //     &short_pkt_param,    // Transmit Buffer
    //     short_pkt_param.len  // Buffer Length
    // );

    // Test Compose Long Packet
    debug("Testing Compose Long Packet...", .{});
    const long_pkt = [_]u8 {
        0xe9, 0x82, 0x10, 0x06, 0x05, 0xa2, 0x0a, 0xa5,
        0x12, 0x31, 0x23, 0x37, 0x83, 0x04, 0xbc, 0x27,
        0x38, 0x0c, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0c,
        0x00, 0x03, 0x00, 0x00, 0x00, 0x75, 0x75, 0x31,
        0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x13, 0x88,
        0x64, 0x64, 0x20, 0x88, 0x88, 0x88, 0x88, 0x88,
        0x88, 0x02, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };
    const long_pkt_result = composeLongPacket(
        &pkt_buf,  //  Packet Buffer
        0,         //  Virtual Channel
        MIPI_DSI_DCS_LONG_WRITE, // DCS Command
        &long_pkt,    // Transmit Buffer
        long_pkt.len  // Buffer Length
    );
    debug("Result:", .{});
    dump_buffer(long_pkt_result);
    assert(  //  Verify result
        std.mem.eql(
            u8,
            long_pkt_result,
            &[_]u8 {
                0x39, 0x40, 0x00, 0x25, 0xe9, 0x82, 0x10, 0x06,
                0x05, 0xa2, 0x0a, 0xa5, 0x12, 0x31, 0x23, 0x37,
                0x83, 0x04, 0xbc, 0x27, 0x38, 0x0c, 0x00, 0x03,
                0x00, 0x00, 0x00, 0x0c, 0x00, 0x03, 0x00, 0x00,
                0x00, 0x75, 0x75, 0x31, 0x88, 0x88, 0x88, 0x88,
                0x88, 0x88, 0x13, 0x88, 0x64, 0x64, 0x20, 0x88,
                0x88, 0x88, 0x88, 0x88, 0x88, 0x02, 0x88, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x65, 0x03,
            }
        )
    );

    // Write to MIPI DSI
    // _ = nuttx_mipi_dsi_dcs_write(
    //     null,  //  Device
    //     0,     //  Virtual Channel
    //     MIPI_DSI_DCS_LONG_WRITE, // DCS Command
    //     &long_pkt,    // Transmit Buffer
    //     long_pkt.len  // Buffer Length
    // );
}

// Test Case for DCS Short Write (Without Parameter):
// mipi_dsi_dcs_write: short len=1
// 11 
// .{ 0x0300, 0x36001105 },
// header: 36001105
// .{ 0x0200, 0x00000003 },
// len: 3

// Test Case for DCS Short Write (With Parameter):
// mipi_dsi_dcs_write: short len=2
// bc 4e 
// .{ 0x0300, 0x354ebc15 },
// header: 354ebc15
// .{ 0x0200, 0x00000003 },
// len: 3

// Test Case for DCS Long Write:
// mipi_dsi_dcs_write: long len=64
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

// Expected Result for DCS Long Write:
// packet: len=70
// 39 40 00 25 e9 82 10 06 
// 05 a2 0a a5 12 31 23 37 
// 83 04 bc 27 38 0c 00 03 
// 00 00 00 0c 00 03 00 00 
// 00 75 75 31 88 88 88 88 
// 88 88 13 88 64 64 20 88 
// 88 88 88 88 88 02 88 00 
// 00 00 00 00 00 00 00 00 
// 00 00 00 00 65 03 
// modifyreg32: addr=0x300, val=0x25004039
// modifyreg32: addr=0x304, val=0x061082e9
// modifyreg32: addr=0x308, val=0xa50aa205
// modifyreg32: addr=0x30c, val=0x37233112
// modifyreg32: addr=0x310, val=0x27bc0483
// modifyreg32: addr=0x314, val=0x03000c38
// modifyreg32: addr=0x318, val=0x0c000000
// modifyreg32: addr=0x31c, val=0x00000300
// modifyreg32: addr=0x320, val=0x31757500
// modifyreg32: addr=0x324, val=0x88888888
// modifyreg32: addr=0x328, val=0x88138888
// modifyreg32: addr=0x32c, val=0x88206464
// modifyreg32: addr=0x330, val=0x88888888
// modifyreg32: addr=0x334, val=0x00880288
// modifyreg32: addr=0x338, val=0x00000000
// modifyreg32: addr=0x33c, val=0x00000000
// modifyreg32: addr=0x340, val=0x00000000
// modifyreg32: addr=0x344, val=0x00000365
// modifyreg32: addr=0x200, val=0x00000045

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
