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

//! PinePhone Display Engine Driver for Apache NuttX RTOS.
//! This Framebuffer Interface is compatible with NuttX Framebuffers:
//! https://github.com/lupyuen/incubator-nuttx/blob/master/include/nuttx/video/fb.h

/// Import the Zig Standard Library
const std = @import("std");

/// Import the MIPI Display Serial Interface Module
const dsi = @import("./display.zig");

/// Import the LoRaWAN Library from C
const c = @cImport({
    // NuttX Defines
    @cDefine("__NuttX__",  "");
    @cDefine("NDEBUG",     "");
    @cDefine("FAR",        "");

    // NuttX Framebuffer Defines
    @cDefine("CONFIG_FB_OVERLAY", "");

    // NuttX Header Files
    @cInclude("arch/types.h");
    @cInclude("../../nuttx/include/limits.h");
    @cInclude("nuttx/config.h");
    @cInclude("inttypes.h");
    @cInclude("unistd.h");
    @cInclude("stdlib.h");
    @cInclude("stdio.h");

    // NuttX Framebuffer Header Files
    @cInclude("nuttx/video/fb.h");
});

/// Render a Test Pattern on PinePhone's Display.
/// Calls Allwinner A64 Display Engine, Timing Controller and MIPI Display Serial Interface.
pub export fn test_render() void {
    _ = videoInfo;
    _ = planeInfo;
    _ = overlayInfo;
}

/// Force MIPI DSI Interface to be exported to C. (Why is this needed?)
pub export fn export_dsi() void {
    dsi.nuttx_panel_init();
}

/// NuttX Video Controller (3 UI Channels)
const videoInfo = c.fb_videoinfo_s {
    .fmt       = c.FB_FMT_RGBA32,  // Pixel format (RGBA 8888)
    .xres      = 720,   // Horizontal resolution in pixel columns
    .yres      = 1440,  // Vertical resolution in pixel rows
    .nplanes   = 1,     // Number of color planes supported (Base UI Channel)
    .noverlays = 2,     // Number of overlays supported (2 Overlay UI Channels)
};

/// NuttX Color Plane (Base UI Channel)
const planeInfo = c.fb_planeinfo_s {
  .fbmem   = &fb0,     // Start of frame buffer memory
  .fblen   = fb0.len,  // Length of frame buffer memory in bytes
  .stride  = 720 * 4,  // Length of a line in bytes (4 bytes per pixel)
  .display = 0,        // Display number (Unused)
  .bpp     = 32,       // Bits per pixel (ARGB 8888)
  .xres_virtual = 720,   // Virtual Horizontal resolution in pixel columns
  .yres_virtual = 1440,  // Virtual Vertical resolution in pixel rows
  .xoffset      = 0,     // Offset from virtual to visible resolution
  .yoffset      = 0,     // Offset from virtual to visible resolution
};

/// NuttX Overlays (2 Overlay UI Channels)
const overlayInfo = [2] c.fb_overlayinfo_s {
    // First Overlay UI Channel:
    // Square 600 x 600 (4 bytes per ARGB pixel)
    .{
        .fbmem     = &fb1,     // Start of frame buffer memory
        .fblen     = fb1.len,  // Length of frame buffer memory in bytes
        .stride    = 600 * 4,  // Length of a line in bytes
        .overlay   = 0,        // Overlay number (First Overlay)
        .bpp       = 32,       // Bits per pixel
        .blank     = 0,        // TODO: Blank or unblank
        .chromakey = 0,        // TODO: Chroma key argb8888 formatted
        .color     = 0,        // TODO: Color argb8888 formatted
        .transp    = c.fb_transp_s { .transp = 0, .transp_mode = 0 },  // TODO: Transparency
        .sarea     = c.fb_area_s { .x = 52, .y = 52, .w = 600, .h = 600 },  // Selected area within the overlay
        .accl      = 0,        // TODO: Supported hardware acceleration
    },
    // Second Overlay UI Channel:
    // Fullscreen 720 x 1440 (4 bytes per ARGB pixel)
    .{
        .fbmem     = &fb2,     // Start of frame buffer memory
        .fblen     = fb2.len,  // Length of frame buffer memory in bytes
        .stride    = 720 * 4,  // Length of a line in bytes
        .overlay   = 1,        // Overlay number (Second Overlay)
        .bpp       = 32,       // Bits per pixel
        .blank     = 0,        // TODO: Blank or unblank
        .chromakey = 0,        // TODO: Chroma key argb8888 formatted
        .color     = 0,        // TODO: Color argb8888 formatted
        .transp    = c.fb_transp_s { .transp = 0, .transp_mode = 0 },  // TODO: Transparency
        .sarea     = c.fb_area_s { .x = 0, .y = 0, .w = 720, .h = 1440 },  // Selected area within the overlay
        .accl      = 0,        // TODO: Supported hardware acceleration
    },
};

// Framebuffer 0: (Base UI Channel)
// Fullscreen 720 x 1440 (4 bytes per XRGB pixel)
var fb0 = std.mem.zeroes([720 * 1440] u32);

// Framebuffer 1: (First Overlay UI Channel)
// Square 600 x 600 (4 bytes per ARGB pixel)
var fb1 = std.mem.zeroes([600 * 600] u32);

// Framebuffer 2: (Second Overlay UI Channel)
// Fullscreen 720 x 1440 (4 bytes per ARGB pixel)
var fb2 = std.mem.zeroes([720 * 1440] u32);
