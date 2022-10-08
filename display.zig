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

/// MIPI DSI Processor-to-Peripheral transaction types:
/// DCS Long Write. See https://lupyuen.github.io/articles/dsi#display-command-set-for-mipi-dsi
const MIPI_DSI_DCS_LONG_WRITE = 0x39;

/// DCS Short Write (Without Parameter)
const MIPI_DSI_DCS_SHORT_WRITE = 0x05;

/// DCS Short Write (With Parameter)
const MIPI_DSI_DCS_SHORT_WRITE_PARAM = 0x15;

const MIPI_DCS_EXIT_SLEEP_MODE = 0x11;
const MIPI_DCS_SET_DISPLAY_ON  = 0x29;

/// Base Address of Allwinner A64 MIPI DSI Controller. See https://lupyuen.github.io/articles/dsi#a64-registers-for-mipi-dsi
const DSI_BASE_ADDRESS = 0x01CA_0000;

/// Instru_En is Bit 0 of DSI_BASIC_CTL0_REG 
/// (DSI Configuration Register 0) at Offset 0x10
const DSI_BASIC_CTL0_REG = DSI_BASE_ADDRESS + 0x10;
const Instru_En = 1 << 0;

/// Initialise the ST7703 LCD Controller in Xingbangda XBD599 LCD Panel.
/// See https://lupyuen.github.io/articles/dsi#initialise-lcd-controller
pub export fn nuttx_panel_init() void {
    debug("nuttx_panel_init", .{});

    // Most of these commands are documented in the ST7703 Datasheet:
    // https://files.pine64.org/doc/datasheet/pinephone/ST7703_DS_v01_20160128.pdf

    writeDcs(&[_]u8 { 
        0xB9,  // SETEXTC (Page 131): Enable USER Command
        0xF1,  // Enable User command
        0x12,  // (Continued)
        0x83   // (Continued)
    });
    writeDcs(&[_]u8 { 
        0xBA,  // SETMIPI (Page 144): Set MIPI related register
        0x33,  // Virtual Channel = 0, Number of Lanes = 4
        0x81,  // LDO = 1.7 V, Terminal Resistance = 90 Ohm
        0x05,  // MIPI Low High Speed driving ability = x6
        0xF9,  // TXCLK speed in DSI LP mode = fDSICLK / 16
        0x0E,  // Min HFP number in DSI mode = 14
        0x0E,  // Min HBP number in DSI mode = 14
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
    writeDcs(&[_]u8 { 
        0xB8,  // SETPOWER_EXT (Page 142): Set display related register
        0x25, 
        0x22, 
        0x20, 
        0x03 
    });
    writeDcs(&[_]u8 { 
        0xB3,  // SETRGBIF (Page 134): Control RGB I/F porch timing for internal use
        0x10, 
        0x10, 
        0x05, 
        0x05, 
        0x03, 
        0xFF, 
        0x00, 
        0x00,
        0x00, 
        0x00 
    });

    writeDcs(&[_]u8 { 
        0xC0,  // SETSCR (Page 147): Set related setting of Source driving
        0x73, 
        0x73, 
        0x50, 
        0x50, 
        0x00, 
        0xC0, 
        0x08, 
        0x70,
        0x00
    });
    writeDcs(&[_]u8 { 
        0xBC,  // SETVDC (Page 146): Control NVDDD/VDDD Voltage
        0x4E
    });
    writeDcs(&[_]u8 { 
        0xCC,  // SETPANEL (Page 154): Set display related register
        0x0B 
    });
    writeDcs(&[_]u8 { 
        0xB4,  // SETCYC (Page 135): Control display inversion type
        0x80 
    });
    writeDcs(&[_]u8 {
        0xB2,  // SETDISP (Page 132): Control the display resolution
        0xF0, 
        0x12, 
        0xF0
    });
    writeDcs(&[_]u8 { 
        0xE3,  // SETEQ (Page 159): Set EQ related register
        0x00, 
        0x00, 
        0x0B, 
        0x0B, 
        0x10, 
        0x10, 
        0x00, 
        0x00,
        0x00, 
        0x00, 
        0xFF, 
        0x00, 
        0xC0, 
        0x10 
    });
    writeDcs(&[_]u8 { 
        0xC6,  // Undocumented
        0x01, 0x00, 0xFF, 0xFF, 0x00 
    });
    writeDcs(&[_]u8 { 
        0xC1,  // SETPOWER (Page 149): Set related setting of power
        0x74, 
        0x00, 
        0x32, 
        0x32, 
        0x77, 
        0xF1, 
        0xFF, 
        0xFF,
        0xCC, 
        0xCC, 
        0x77, 
        0x77 
    });
    writeDcs(&[_]u8 { 
        0xB5,  // SETBGP (Page 136): Internal reference voltage setting
        0x07, 
        0x07 
    });
    writeDcs(&[_]u8 { 
        0xB6,  // SETVCOM (Page 137): Set VCOM Voltage
        0x2C, 
        0x2C 
    });
    writeDcs(&[_]u8 { 
        0xBF,  // Undocumented
        0x02, 0x11, 0x00 
    });

    writeDcs(&[_]u8 { 
        0xE9,  // SETGIP1 (Page 163): Set forward GIP timing
        0x82, 0x10, 0x06, 0x05, 0xA2, 0x0A, 0xA5, 0x12,
        0x31, 0x23, 0x37, 0x83, 0x04, 0xBC, 0x27, 0x38,
        0x0C, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0C, 0x00,
        0x03, 0x00, 0x00, 0x00, 0x75, 0x75, 0x31, 0x88,
        0x88, 0x88, 0x88, 0x88, 0x88, 0x13, 0x88, 0x64,
        0x64, 0x20, 0x88, 0x88, 0x88, 0x88, 0x88, 0x88,
        0x02, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
    });
    writeDcs(&[_]u8 { 
        0xEA,  // SETGIP2 (Page 170): Set backward GIP timing
        0x02, 0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x02, 0x46, 0x02, 0x88,
        0x88, 0x88, 0x88, 0x88, 0x88, 0x64, 0x88, 0x13,
        0x57, 0x13, 0x88, 0x88, 0x88, 0x88, 0x88, 0x88,
        0x75, 0x88, 0x23, 0x14, 0x00, 0x00, 0x02, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x0A,
        0xA5, 0x00, 0x00, 0x00, 0x00 
    });
    writeDcs(&[_]u8 { 
        0xE0,  // SETGAMMA (Page 158): Set the gray scale voltage to adjust the gamma characteristics of the TFT panel
        0x00, 0x09, 0x0D, 0x23, 0x27, 0x3C, 0x41, 0x35,
        0x07, 0x0D, 0x0E, 0x12, 0x13, 0x10, 0x12, 0x12,
        0x18, 0x00, 0x09, 0x0D, 0x23, 0x27, 0x3C, 0x41,
        0x35, 0x07, 0x0D, 0x0E, 0x12, 0x13, 0x10, 0x12,
        0x12, 0x18 
    });

    // TODO: Is this needed?
    // SLPOUT (Page 89): Turns off sleep mode
    writeDcs(&[_]u8 { MIPI_DCS_EXIT_SLEEP_MODE });

    // TODO: Verify the delay
    _ = c.usleep(120 * 1000);

    // TODO: Is this needed?
    // Display On (Page 97): Recover from DISPLAY OFF mode
    writeDcs(&[_]u8 { MIPI_DCS_SET_DISPLAY_ON });    
}

/// Write the DCS Command to MIPI DSI
fn writeDcs(buf: []const u8) void {
    debug("writeDcs: len={}", .{ buf.len });
    dump_buffer(&buf[0], buf.len);
    assert(buf.len > 0);

    // Do DCS Short Write or Long Write depending on command length
    const res = switch (buf.len) {

        // DCS Short Write (without parameter)
        1 => nuttx_mipi_dsi_dcs_write(null, 0, MIPI_DSI_DCS_SHORT_WRITE, 
            &buf[0], buf.len),

        // DCS Short Write (with parameter)
        2 => nuttx_mipi_dsi_dcs_write(null, 0, MIPI_DSI_DCS_SHORT_WRITE_PARAM, 
            &buf[0], buf.len),

        // DCS Long Write
        else => nuttx_mipi_dsi_dcs_write(null, 0, MIPI_DSI_DCS_LONG_WRITE, 
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
    dump_buffer(&pkt[0], pkt.len);

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
        modifyreg32(addr, 0xFFFF_FFFF, v);
        addr += 4;
    }

    // Set Packet Length - 1 in Bits 0 to 7 (TX_Size) of
    // DSI_CMD_CTL_REG (DSI Low Power Control Register) at Offset 0x200
    modifyreg32(DSI_CMD_CTL_REG, 0xFF, @intCast(u32, pkt.len) - 1);

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
    modifyreg32(DSI_BASIC_CTL0_REG, Instru_En, 0);
}

/// Enable DSI Processing. See https://lupyuen.github.io/articles/dsi#transmit-packet-over-mipi-dsi
fn enableDsiProcessing() void {
    // Set Instru_En to 1
    modifyreg32(DSI_BASIC_CTL0_REG, Instru_En, Instru_En);
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

// Compose MIPI DSI Short Packet. See https://lupyuen.github.io/articles/dsi#appendix-short-packet-for-mipi-dsi
fn composeShortPacket(
    pkt: []u8,    // Buffer for the Long Packet
    channel: u8,  // Virtual Channel ID
    cmd: u8,      // DCS Command
    buf: [*c]const u8,  // Transmit Buffer
    len: usize          // Buffer Length
) []const u8 {          // Returns the Short Packet
    debug("composeShortPacket: channel={}, cmd=0x{x}, len={}", .{ channel, cmd, len });
    assert(len == 1 or len == 2);

    // From BL808 Reference Manual (Page 201): https://github.com/sipeed/sipeed2022_autumn_competition/blob/main/assets/BL808_RM_en.pdf
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
    // - Data Identifier + Word Count + Error Correction COde
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

/// Atomically modify the specified bits in a memory mapped register.
/// Based on https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm/src/common/arm_modifyreg32.c#L38-L57
fn modifyreg32(
    addr: u64,       // Address to modify
    clearbits: u32,  // Bits to clear, like (1 << bit)
    setbits: u32     // Bit to set, like (1 << bit)
) void {
    debug("modifyreg32: addr=0x{x:0>3}, val=0x{x:0>8}", .{ addr - DSI_BASE_ADDRESS, setbits & clearbits });
    // TODO: flags = spin_lock_irqsave(NULL);
    var regval = getreg32(addr);
    regval &= ~clearbits;
    regval |= setbits;
    putreg32(regval, addr);
    // TODO: spin_unlock_irqrestore(NULL, flags);
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
    dump_buffer(&short_pkt_result[0], short_pkt_result.len);
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
    dump_buffer(&short_pkt_param_result[0], short_pkt_param_result.len);
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
    dump_buffer(&long_pkt_result[0], long_pkt_result.len);
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

/// From apps/examples/hello/hello_main.c
extern fn dump_buffer(data: [*c]const u8, len: usize) void;

/// For safety, we import these functions ourselves to enforce Null-Terminated Strings.
/// We changed `[*c]const u8` to `[*:0]const u8`
extern fn printf(format: [*:0]const u8, ...) c_int;
extern fn puts(str: [*:0]const u8) c_int;

/// Aliases for Zig Standard Library
const assert = std.debug.assert;
const debug  = std.log.debug;
