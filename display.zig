//! MIPI DSI Declarations are compatible with Zephyr MIPI DSI:
//! https://github.com/zephyrproject-rtos/zephyr/blob/main/include/zephyr/drivers/mipi_dsi.h

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

const std = @import("std");

// TODO:   -D__NuttX__ 

/// MIPI DSI Processor-to-Peripheral transaction types
const MIPI_DSI_GENERIC_LONG_WRITE = 0x29;

/// Write to MIPI DSI
pub export fn mipi_dsi_dcs_write(
    dev: [*c]const mipi_dsi_device,  // MIPI DSI Host Device
    channel: u8,  // Virtual Channel ID
	cmd: u8,      // DCS Command
    buf: [*c]u8,  // Transmission Buffer
    len: size_t        // Length of Buffer
) ssize_t {           // On Success: Return number of written bytes. On Error: Return negative error code
    return 0;
}

/// MIPI DSI Device
const mipi_dsi_device = struct {
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
const mipi_dsi_msg = struct {
	/// Payload Data Type
	type: u8,
	/// Flags controlling message transmission
	flags: u16,
	/// Command (only for DCS)
	cmd: u8,
	/// Transmission Buffer Length
	tx_len: size_t,
	/// Transmission Buffer
	tx_buf: [*c]const u8,
	/// Receive Buffer Length
	rx_len: size_t,
	/// Receive Buffer
	rx_buf: [*c]u8,
};

/// MIPI DSI Display Timings
const mipi_dsi_timings = struct {
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

pub extern fn printf(_format: [*:0]const u8) c_int;

pub export fn null_main(_argc: c_int, _argv: [*]const [*]const u8) c_int {
    _ = _argc;
    _ = _argv;
    test_zig();
    return 0;
}

pub export fn test_zig() void {
    _ = printf("HELLO ZIG ON PINEPHONE!\n");
}
