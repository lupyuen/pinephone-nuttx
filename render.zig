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

//! PinePhone Display Engine Driver for Apache NuttX RTOS, based on NuttX Framebuffers:
//! https://github.com/apache/incubator-nuttx/blob/master/include/nuttx/video/fb.h
//! "DE Page ???" refers to Allwinner Display Engine 2.0 Specification: https://linux-sunxi.org/images/7/7b/Allwinner_DE2.0_Spec_V1.0.pdf
//! "A64 Page ???" refers to Allwinner A64 User Manual: https://linux-sunxi.org/images/b/b4/Allwinner_A64_User_Manual_V1.1.pdf
//! "A31 Page ???" refers to Allwinner A31 User Manual: https://github.com/allwinner-zh/documents/raw/master/A31/A31_User_Manual_v1.3_20150510.pdf

/// Import the Zig Standard Library
const std = @import("std");

/// Import the MIPI Display Serial Interface Module
const dsi = @import("./display.zig");

/// Import NuttX Functions from C
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

/// Number of UI Channels to test: 1 or 3
const NUM_CHANNELS = 3;

/// Render a Test Pattern on PinePhone's Display.
/// Calls Allwinner A64 Display Engine, Timing Controller and MIPI Display Serial Interface.
/// See https://lupyuen.github.io/articles/de#appendix-programming-the-allwinner-a64-display-engine
pub export fn test_render() void {
    debug("test_render: start", .{});
    defer { debug("test_render: end", .{}); }

    // Validate the Framebuffer Sizes at Compile Time
    comptime {
        assert(NUM_CHANNELS == 1 or NUM_CHANNELS == 3);
        assert(planeInfo.xres_virtual == videoInfo.xres);
        assert(planeInfo.yres_virtual == videoInfo.yres);
        assert(planeInfo.fblen  == planeInfo.xres_virtual * planeInfo.yres_virtual * 4);
        assert(planeInfo.stride == planeInfo.xres_virtual * 4);
        assert(overlayInfo[0].fblen  == @intCast(usize, overlayInfo[0].sarea.w) * overlayInfo[0].sarea.h * 4);
        assert(overlayInfo[0].stride == overlayInfo[0].sarea.w * 4);
        assert(overlayInfo[1].fblen  == @intCast(usize, overlayInfo[1].sarea.w) * overlayInfo[1].sarea.h * 4);
        assert(overlayInfo[1].stride == overlayInfo[1].sarea.w * 4);
    }

    // TODO: Handle non-relaxed write

    // TODO: Init PinePhone's Allwinner A64 Timing Controller TCON0 (tcon0_init)
    // https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#tcon0_init

    // TODO: Init PinePhone's Allwinner A64 MIPI Display Serial Interface (dsi_init)
    // Call https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#dsi_init

    // TODO: Init PinePhone's Allwinner A64 Display Engine (de2_init)
    // https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#de2_init

    // TODO: Turn on PinePhone's Backlight (backlight_enable)
    // https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#backlight_enable

    // Init Framebuffer 0:
    // Fill with Blue, Green and Red
    var i: usize = 0;
    while (i < fb0.len) : (i += 1) {
        // Colours are in XRGB 8888 format
        if (i < fb0.len / 4) {
            // Blue for top quarter
            fb0[i] = 0x80000080;
        } else if (i < fb0.len / 2) {
            // Green for next quarter
            fb0[i] = 0x80008000;
        } else {
            // Red for lower half
            fb0[i] = 0x80800000;
        }
    }

    // Init Framebuffer 1:
    // Fill with Semi-Transparent Blue
    i = 0;
    while (i < fb1.len) : (i += 1) {
        // Colours are in ARGB 8888 format
        fb1[i] = 0x80000080;
    }

    // Init Framebuffer 2:
    // Fill with Semi-Transparent Green Circle
    var y: usize = 0;
    while (y < 1440) : (y += 1) {
        var x: usize = 0;
        while (x < 720) : (x += 1) {
            // Get pixel index
            const p = (y * 720) + x;
            assert(p < fb2.len);

            // Shift coordinates so that centre of screen is (0,0)
            const x_shift = @intCast(isize, x) - 360;
            const y_shift = @intCast(isize, y) - 720;

            // If x^2 + y^2 < radius^2, set the pixel to Semi-Transparent Green
            if (x_shift*x_shift + y_shift*y_shift < 360*360) {
                fb2[p] = 0x80008000;  // Semi-Transparent Green in ARGB 8888 Format
            } else {  // Otherwise set to Transparent Black
                fb2[p] = 0x00000000;  // Transparent Black in ARGB 8888 Format
            }
        }
    }

    // Init the UI Blender for PinePhone's A64 Display Engine
    initUiBlender();

    // Init the Base UI Channel
    initUiChannel(
        1,  // UI Channel Number (1 for Base UI Channel)
        planeInfo.fbmem,    // Start of frame buffer memory
        planeInfo.fblen,    // Length of frame buffer memory in bytes
        planeInfo.stride,   // Length of a line in bytes (4 bytes per pixel)
        planeInfo.xres_virtual,  // Horizontal resolution in pixel columns
        planeInfo.yres_virtual,  // Vertical resolution in pixel rows
        planeInfo.xoffset,  // Horizontal offset in pixel columns
        planeInfo.yoffset,  // Vertical offset in pixel rows
    );

    // Init the 2 Overlay UI Channels
    for (overlayInfo) | ov, ov_index | {
        initUiChannel(
            @intCast(u8, ov_index + 2),  // UI Channel Number (2 and 3 for Overlay UI Channels)
            if (NUM_CHANNELS == 3) ov.fbmem else null,  // Start of frame buffer memory
            ov.fblen,    // Length of frame buffer memory in bytes
            ov.stride,   // Length of a line in bytes (4 bytes per pixel)
            ov.sarea.w,  // Horizontal resolution in pixel columns
            ov.sarea.h,  // Vertical resolution in pixel rows
            ov.sarea.x,  // Horizontal offset in pixel columns
            ov.sarea.y,  // Vertical offset in pixel rows
        );
    }

    // TODO
    applySettings(NUM_CHANNELS);
}

/// Render a Test Pattern on PinePhone's Display. Framebuffer passed from C.
/// Calls Allwinner A64 Display Engine, Timing Controller and MIPI Display Serial Interface.
/// See https://lupyuen.github.io/articles/de#appendix-programming-the-allwinner-a64-display-engine
pub export fn test_render2(p0: [*c]u8) void {
    debug("test_render2: start", .{});
    defer { debug("test_render2: end", .{}); }

    // Validate the Framebuffer Sizes at Compile Time
    comptime {
        assert(NUM_CHANNELS == 1 or NUM_CHANNELS == 3);
        assert(planeInfo.xres_virtual == videoInfo.xres);
        assert(planeInfo.yres_virtual == videoInfo.yres);
        assert(planeInfo.fblen  == planeInfo.xres_virtual * planeInfo.yres_virtual * 4);
        assert(planeInfo.stride == planeInfo.xres_virtual * 4);
        assert(overlayInfo[0].fblen  == @intCast(usize, overlayInfo[0].sarea.w) * overlayInfo[0].sarea.h * 4);
        assert(overlayInfo[0].stride == overlayInfo[0].sarea.w * 4);
        assert(overlayInfo[1].fblen  == @intCast(usize, overlayInfo[1].sarea.w) * overlayInfo[1].sarea.h * 4);
        assert(overlayInfo[1].stride == overlayInfo[1].sarea.w * 4);
    }

    // TODO: Handle non-relaxed write

    // TODO: Init PinePhone's Allwinner A64 Timing Controller TCON0 (tcon0_init)
    // https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#tcon0_init

    // TODO: Init PinePhone's Allwinner A64 MIPI Display Serial Interface (dsi_init)
    // Call https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#dsi_init

    // TODO: Init PinePhone's Allwinner A64 Display Engine (de2_init)
    // https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#de2_init

    // TODO: Turn on PinePhone's Backlight (backlight_enable)
    // https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#backlight_enable

    // Init the UI Blender for PinePhone's A64 Display Engine
    initUiBlender();

    // Init the Base UI Channel
    initUiChannel(
        1,  // UI Channel Number (1 for Base UI Channel)
        p0,    // Start of frame buffer memory
        planeInfo.fblen,    // Length of frame buffer memory in bytes
        planeInfo.stride,   // Length of a line in bytes (4 bytes per pixel)
        planeInfo.xres_virtual,  // Horizontal resolution in pixel columns
        planeInfo.yres_virtual,  // Vertical resolution in pixel rows
        planeInfo.xoffset,  // Horizontal offset in pixel columns
        planeInfo.yoffset,  // Vertical offset in pixel rows
    );

    // Init the 2 Overlay UI Channels
    for (overlayInfo) | ov, ov_index | {
        initUiChannel(
            @intCast(u8, ov_index + 2),  // UI Channel Number (2 and 3 for Overlay UI Channels)
            if (NUM_CHANNELS == 3) ov.fbmem else null,  // Start of frame buffer memory
            ov.fblen,    // Length of frame buffer memory in bytes
            ov.stride,   // Length of a line in bytes (4 bytes per pixel)
            ov.sarea.w,  // Horizontal resolution in pixel columns
            ov.sarea.h,  // Vertical resolution in pixel rows
            ov.sarea.x,  // Horizontal offset in pixel columns
            ov.sarea.y,  // Vertical offset in pixel rows
        );
    }

    // TODO
    applySettings(NUM_CHANNELS);
}

/// Hardware Registers for PinePhone's A64 Display Engine.
/// See https://lupyuen.github.io/articles/de#appendix-overview-of-allwinner-a64-display-engine
/// Display Engine Base Address is 0x0100 0000
const DISPLAY_ENGINE_BASE_ADDRESS = 0x0100_0000;

/// RT-MIXER0 is at DE Offset 0x10 0000 (Page 87)
const MIXER0_BASE_ADDRESS = DISPLAY_ENGINE_BASE_ADDRESS + 0x10_0000;

// |GLB | 0x0000
const GLB_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x0000;

// |BLD (Blender) | 0x1000
const BLD_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x1000;

// |OVL_UI(CH1) (UI Overlay / Channel 1) | 0x3000
// |OVL_UI(CH2) (UI Overlay / Channel 2) | 0x4000
// |OVL_UI(CH3) (UI Overlay / Channel 3) | 0x5000
const OVL_UI_CH1_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x3000;

/// Initialise the UI Blender for PinePhone's A64 Display Engine.
/// See https://lupyuen.github.io/articles/de#appendix-programming-the-allwinner-a64-display-engine
fn initUiBlender() void {
    debug("initUiBlender: start", .{});
    defer { debug("initUiBlender: end", .{}); }

    // BLD_BK_COLOR @ BLD Offset 0x88: BLD background color register
    // Set to 0xff00 0000 (Why?)
    debug("Configure Blender", .{});
    const BLD_BK_COLOR = BLD_BASE_ADDRESS + 0x88;
    putreg32(0xff00_0000, BLD_BK_COLOR);

    // BLD_PREMUL_CTL @ BLD Offset 0x84: BLD pre-multiply control register
    // Set to 0
    const BLD_PREMUL_CTL = BLD_BASE_ADDRESS + 0x84;
    putreg32(0, BLD_PREMUL_CTL);
}

/// TODO
fn applySettings(
    channels: u8  // Number of enabled UI Channels
) void {
    debug("applySettings: start", .{});
    defer { debug("applySettings: end", .{}); }
    assert(channels == 1 or channels == 3);

    // Set BLD Route and BLD FColor Control
    // -   BLD Route (BLD_CH_RTCTL @ BLD Offset 0x080): _BLD routing control register_
    //     For 3 UI Channels: Set to 0x321 (Why?)
    //     For 1 UI Channel: Set to 1 (Why?)
    debug("Set BLD Route and BLD FColor Control", .{});
    const BLD_CH_RTCTL = BLD_BASE_ADDRESS + 0x080;
    if (channels == 3) { putreg32(0x321, BLD_CH_RTCTL); }  // TODO: DMB
    else if (channels == 1) { putreg32(0x1, BLD_CH_RTCTL); }  // TODO: DMB
    else { unreachable; }

    // -   BLD FColor Control (BLD_FILLCOLOR_CTL @ BLD Offset 0x000): _BLD fill color control register_
    //     For 3 UI Channels: Set to 0x701 (Why?)
    //     For 1 UI Channel: Set to 0x101 (Why?)
    const BLD_FILLCOLOR_CTL = BLD_BASE_ADDRESS + 0x000;
    if (channels == 3) { putreg32(0x701, BLD_FILLCOLOR_CTL); }  // TODO: DMB
    else if (channels == 1) { putreg32(0x101, BLD_FILLCOLOR_CTL); }  // TODO: DMB
    else { unreachable; }

    // Apply Settings
    // -   GLB DBuff (GLB_DBUFFER @ GLB Offset 0x008): _Global double buffer control register_
    //     Set to 1 (Why?)
    debug("Apply Settings", .{});
    const GLB_DBUFFER = GLB_BASE_ADDRESS + 0x008;
    putreg32(1, GLB_DBUFFER);  // TODO: DMB
}

/// Initialise a UI Channel for PinePhone's A64 Display Engine.
/// We use 3 UI Channels: Base UI Channel (#1) plus 2 Overlay UI Channels (#2, #3).
/// See https://lupyuen.github.io/articles/de#appendix-programming-the-allwinner-a64-display-engine
fn initUiChannel(
    channel: u8,            // UI Channel Number: 1, 2 or 3
    fbmem: ?*anyopaque,     // Start of frame buffer memory, or null if this channel should be disabled
    fblen: usize,           // Length of frame buffer memory in bytes
    stride:  c.fb_coord_t,  // Length of a line in bytes (4 bytes per pixel)
    xres:    c.fb_coord_t,  // Horizontal resolution in pixel columns
    yres:    c.fb_coord_t,  // Vertical resolution in pixel rows
    xoffset: c.fb_coord_t,  // Horizontal offset in pixel columns
    yoffset: c.fb_coord_t,  // Vertical offset in pixel rows
) void {
    debug("initUiChannel: start", .{});
    defer { debug("initUiChannel: end", .{}); }

    assert(channel >= 1 and channel <= 3);
    assert(fblen == @intCast(usize, xres) * yres * 4);
    assert(stride == @intCast(usize, xres) * 4);

    // |OVL_UI(CH1) (UI Overlay / Channel 1) | 0x3000
    // |OVL_UI(CH2) (UI Overlay / Channel 2) | 0x4000
    // |OVL_UI(CH3) (UI Overlay / Channel 3) | 0x5000
    const OVL_UI_BASE_ADDRESS = OVL_UI_CH1_BASE_ADDRESS +
        @intCast(u64, channel - 1) * 0x1000;

    // If UI Channel should be disabled...
    if (fbmem == null) {
        // Disable Overlay and Pipe:
        // UI Config Attr (OVL_UI_ATTCTL @ OVL_UI Offset 0x00): _OVL_UI attribute control register_
        // Set to 0
        debug("Channel {}: Disable Overlay and Pipe", .{ channel });
        const OVL_UI_ATTCTL = OVL_UI_BASE_ADDRESS + 0x00;
        putreg32(0, OVL_UI_ATTCTL);

        // Disable Scaler:
        // Mixer (??? @ 0x113 0000 + 0x10000 * Channel)
        // Set to 0
        debug("Channel {}: Disable Scaler", .{ channel });
        const MIXER = 0x113_0000 + 0x10000 * @intCast(u64, channel);
        putreg32(0, MIXER);
        
        // Skip to next UI Channel
        return;
    }

    // 1.  Set Overlay (Assume Layer = 0)
    //     -   UI Config Attr (OVL_UI_ATTCTL @ OVL_UI Offset 0x00): _OVL_UI attribute control register_
    //         For Channel 1: Set to 0xff00 0405 (Why?)
    //         For Channel 2: 0xff00 0005 (Why?)
    //         For Channel 3: 0x7f00 0005 (Why?)
    debug("Channel {}: Set Overlay ({} x {})", .{ channel, xres, yres });
    const OVL_UI_ATTCTL = OVL_UI_BASE_ADDRESS + 0x00;
    if (channel == 1) { putreg32(0xff00_0405, OVL_UI_ATTCTL); }
    else if (channel == 2) { putreg32(0xff00_0005, OVL_UI_ATTCTL); }
    else if (channel == 3) { putreg32(0x7f00_0005, OVL_UI_ATTCTL); }

    //     -   UI Config Top LAddr (OVL_UI_TOP_LADD @ OVL_UI Offset 0x10): _OVL_UI top field memory block low address register_
    //         Set to Framebuffer Address: fb0, fb1 or fb2
    const OVL_UI_TOP_LADD = OVL_UI_BASE_ADDRESS + 0x10;
    putreg32(@intCast(u32, @ptrToInt(fbmem.?)), OVL_UI_TOP_LADD);

    //     -   UI Config Pitch (OVL_UI_PITCH @ OVL_UI Offset 0x0C): _OVL_UI memory pitch register_
    //         Set to (width * 4)
    const OVL_UI_PITCH = OVL_UI_BASE_ADDRESS + 0x0C;
    putreg32(xres * 4, OVL_UI_PITCH);

    //     -   UI Config Size (OVL_UI_MBSIZE @ OVL_UI Offset 0x04): _OVL_UI memory block size register_
    //         Set to (height-1) << 16 + (width-1)
    const OVL_UI_MBSIZE = OVL_UI_BASE_ADDRESS + 0x04;
    const height_width: u32 = @intCast(u32, yres - 1) << 16
        | (xres - 1);
    putreg32(height_width, OVL_UI_MBSIZE);

    //     -   UI Overlay Size (OVL_UI_SIZE @ OVL_UI Offset 0x88): _OVL_UI overlay window size register_
    //         Set to (height-1) << 16 + (width-1)
    const OVL_UI_SIZE = OVL_UI_BASE_ADDRESS + 0x88;
    putreg32(height_width, OVL_UI_SIZE);

    //     -   IO Config Coord (OVL_UI_COOR @ OVL_UI Offset 0x08): _OVL_UI memory block coordinate register_
    //         Set to 0
    const OVL_UI_COOR = OVL_UI_BASE_ADDRESS + 0x08;
    putreg32(0, OVL_UI_COOR);

    // 1.  For Channel 1: Set Blender Output
    if (channel == 1) {
        //     -   BLD Output Size (BLD_SIZE @ BLD Offset 0x08C): _BLD output size setting register_
        //         Set to (height-1) << 16 + (width-1)
        debug("Channel {}: Set Blender Output", .{ channel });
        const BLD_SIZE = BLD_BASE_ADDRESS + 0x08C;
        putreg32(height_width, BLD_SIZE);
                
        //     -   GLB Size (GLB_SIZE @ GLB Offset 0x00C): _Global size register_
        //         Set to (height-1) << 16 + (width-1)
        const GLB_SIZE = GLB_BASE_ADDRESS + 0x00C;
        putreg32(height_width, GLB_SIZE);
    }

    // 1.  Set Blender Input Pipe (N = Pipe Number, from 0 to 2 for Channels 1 to 3)
    const pipe: u64 = channel - 1;
    debug("Channel {}: Set Blender Input Pipe {} ({} x {})", .{ channel, pipe, xres, yres });

    //     -   BLD Pipe InSize (BLD_CH_ISIZE @ BLD Offset 0x008 + N*0x10): _BLD input memory size register(N=0,1,2,3,4)_
    //         Set to (height-1) << 16 + (width-1)
    const BLD_CH_ISIZE = BLD_BASE_ADDRESS + 0x008 + pipe * 0x10;
    putreg32(height_width, BLD_CH_ISIZE);

    //     -   BLD Pipe FColor (BLD_FILL_COLOR @ BLD Offset 0x004 + N*0x10): _BLD fill color register(N=0,1,2,3,4)_
    //         Set to 0xff00 0000 (Why?)
    const BLD_FILL_COLOR = BLD_BASE_ADDRESS + 0x004 + pipe * 0x10;
    putreg32(0xff00_0000, BLD_FILL_COLOR);

    //     -   BLD Pipe Offset (BLD_CH_OFFSET @ BLD Offset 0x00C + N*0x10): _BLD input memory offset register(N=0,1,2,3,4)_
    //         For Channel 1: Set to 0 (Why?)
    //         For Channel 2: Set to 0x34 0034 (Why?)
    //         For Channel 3: Set to 0 (Why?)
    _ = xoffset; ////
    _ = yoffset; ////
    const BLD_CH_OFFSET = BLD_BASE_ADDRESS + 0x00C + pipe * 0x10;
    if (channel == 1) { putreg32(0, BLD_CH_OFFSET); }
    else if (channel == 2) { putreg32(0x34_0034, BLD_CH_OFFSET); }
    else if (channel == 3) { putreg32(0, BLD_CH_OFFSET); }

    //     -   BLD Pipe Mode (BLD_CTL @ BLD Offset 0x090 + N*4): _BLD control register_
    //         Set to 0x301 0301 (Why?)
    const BLD_CTL = BLD_BASE_ADDRESS + 0x090 + pipe * 4;
    putreg32(0x301_0301, BLD_CTL);

    //     Note: Log shows BLD_CH_ISIZE, BLD_FILL_COLOR and BLD_CH_OFFSET are at N*0x10, but doc says N*0x14

    // 1.  Disable Scaler (Assume we're not scaling)
    //     -   Mixer (??? @ 0x113 0000 + 0x10000 * Channel)
    //         Set to 0
    debug("Channel {}: Disable Scaler", .{ channel });
    const MIXER = 0x113_0000 + 0x10000 * @intCast(u64, channel);
    putreg32(0, MIXER);
}

/// NuttX Video Controller for PinePhone (3 UI Channels)
const videoInfo = c.fb_videoinfo_s {
    .fmt       = c.FB_FMT_RGBA32,  // Pixel format (XRGB 8888)
    .xres      = 720,   // Horizontal resolution in pixel columns
    .yres      = 1440,  // Vertical resolution in pixel rows
    .nplanes   = 1,     // Number of color planes supported (Base UI Channel)
    .noverlays = 2,     // Number of overlays supported (2 Overlay UI Channels)
};

/// NuttX Color Plane for PinePhone (Base UI Channel):
/// Fullscreen 720 x 1440 (4 bytes per XRGB 8888 pixel)
const planeInfo = c.fb_planeinfo_s {
    .fbmem   = &fb0,     // Start of frame buffer memory
    .fblen   = @sizeOf( @TypeOf(fb0) ),  // Length of frame buffer memory in bytes
    .stride  = 720 * 4,  // Length of a line in bytes (4 bytes per pixel)
    .display = 0,        // Display number (Unused)
    .bpp     = 32,       // Bits per pixel (XRGB 8888)
    .xres_virtual = 720,   // Virtual Horizontal resolution in pixel columns
    .yres_virtual = 1440,  // Virtual Vertical resolution in pixel rows
    .xoffset      = 0,     // Offset from virtual to visible resolution
    .yoffset      = 0,     // Offset from virtual to visible resolution
};

/// NuttX Overlays for PinePhone (2 Overlay UI Channels)
const overlayInfo = [2] c.fb_overlayinfo_s {
    // First Overlay UI Channel:
    // Square 600 x 600 (4 bytes per ARGB 8888 pixel)
    .{
        .fbmem     = &fb1,     // Start of frame buffer memory
        .fblen     = @sizeOf( @TypeOf(fb1) ),  // Length of frame buffer memory in bytes
        .stride    = 600 * 4,  // Length of a line in bytes
        .overlay   = 0,        // Overlay number (First Overlay)
        .bpp       = 32,       // Bits per pixel (ARGB 8888)
        .blank     = 0,        // TODO: Blank or unblank
        .chromakey = 0,        // TODO: Chroma key argb8888 formatted
        .color     = 0,        // TODO: Color argb8888 formatted
        .transp    = c.fb_transp_s { .transp = 0, .transp_mode = 0 },  // TODO: Transparency
        .sarea     = c.fb_area_s { .x = 52, .y = 52, .w = 600, .h = 600 },  // Selected area within the overlay
        .accl      = 0,        // TODO: Supported hardware acceleration
    },
    // Second Overlay UI Channel:
    // Fullscreen 720 x 1440 (4 bytes per ARGB 8888 pixel)
    .{
        .fbmem     = &fb2,     // Start of frame buffer memory
        .fblen     = @sizeOf( @TypeOf(fb2) ),  // Length of frame buffer memory in bytes
        .stride    = 720 * 4,  // Length of a line in bytes
        .overlay   = 1,        // Overlay number (Second Overlay)
        .bpp       = 32,       // Bits per pixel (ARGB 8888)
        .blank     = 0,        // TODO: Blank or unblank
        .chromakey = 0,        // TODO: Chroma key argb8888 formatted
        .color     = 0,        // TODO: Color argb8888 formatted
        .transp    = c.fb_transp_s { .transp = 0, .transp_mode = 0 },  // TODO: Transparency
        .sarea     = c.fb_area_s { .x = 0, .y = 0, .w = 720, .h = 1440 },  // Selected area within the overlay
        .accl      = 0,        // TODO: Supported hardware acceleration
    },
};

// Framebuffer 0: (Base UI Channel)
// Fullscreen 720 x 1440 (4 bytes per XRGB 8888 pixel)
// TODO: Does alignment prevent flickering?
var fb0 align(0x1000) = std.mem.zeroes([720 * 1440] u32);

// Framebuffer 1: (First Overlay UI Channel)
// Square 600 x 600 (4 bytes per ARGB 8888 pixel)
// TODO: Does alignment prevent flickering?
var fb1 align(0x1000) = std.mem.zeroes([600 * 600] u32);

// Framebuffer 2: (Second Overlay UI Channel)
// Fullscreen 720 x 1440 (4 bytes per ARGB 8888 pixel)
// TODO: Does alignment prevent flickering?
var fb2 align(0x1000) = std.mem.zeroes([720 * 1440] u32);

///////////////////////////////////////////////////////////////////////////////
//  Display Engine

// SRAM Registers Base Address is 0x01C0 0000 (A31 Page 191)
const SRAM_REGISTERS_BASE_ADDRESS = 0x01C0_0000;

// CCU (Clock Control Unit) Base Address is 0x01C2 0000 (A64 Page 81)
const CCU_BASE_ADDRESS = 0x01C2_0000;

// VIDEO_SCALER(CH0) is at MIXER0 Offset 0x02 0000 (DE Page 90, 0x112 0000)
const VIDEO_SCALER_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x02_0000;

// UI_SCALER1(CH1) is at MIXER0 Offset 0x04 0000 (DE Page 90, 0x114 0000)
const UI_SCALER1_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x04_0000;

// UI_SCALER2(CH2) is at MIXER0 Offset 0x05 0000 (DE Page 90, 0x115 0000)
const UI_SCALER2_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x05_0000;

// FCE (Fresh and Contrast Enhancement) is at MIXER0 Offset 0x0A 0000 (DE Page 61, 0x11A 0000)
const FCE_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x0A_0000;

// BWS (Black and White Stetch) is at MIXER0 Offset 0x0A 2000 (DE Page 42, 0x11A 2000)
const BWS_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x0A_2000;

// LTI (Luminance Transient Improvement) is at MIXER0 Offset 0x0A 4000 (DE Page 71, 0x11A 4000)
const LTI_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x0A_4000;

// PEAKING (Luma Peaking) is at MIXER0 Offset 0x0A 6000 (DE Page 80, 0x11A 6000)
const PEAKING_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x0A_6000;

// ASE (Adaptive Saturation Enhancement) is at MIXER0 Offset 0x0A 8000 (DE Page 40, 0x11A 8000)
const ASE_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x0A_8000;

// FCC (Fancy Color Curvature Change) is at MIXER0 Offset 0x0A A000 (DE Page 56, 0x11A A000)
const FCC_BASE_ADDRESS = MIXER0_BASE_ADDRESS + 0x0A_A000;

// DRC (Dynamic Range Controller) is at Address 0x011B 0000 (DE Page 48, 0x11B 0000)
const DRC_BASE_ADDRESS = 0x011B_0000;

// Init PinePhone's Allwinner A64 Display Engine.
// See https://lupyuen.github.io/articles/de#appendix-initialising-the-allwinner-a64-display-engine
pub export fn de2_init() void {
    debug("de2_init: start", .{});
    defer { debug("de2_init: end", .{}); }

    // Set High Speed SRAM to DMA Mode
    // Set BIST_DMA_CTRL_SEL to 0 for DMA (DMB) (A31 Page 191, 0x1C0 0004)
    // BIST_DMA_CTRL_SEL (Bist and DMA Control Select) is Bit 0 of SRAM_CTRL_REG1
    // SRAM_CTRL_REG1 (SRAM Control Register 1) is at SRAM Registers Offset 0x4
    debug("Set High Speed SRAM to DMA Mode", .{});
    const SRAM_CTRL_REG1 = SRAM_REGISTERS_BASE_ADDRESS + 0x4;
    comptime{ assert(SRAM_CTRL_REG1 == 0x1C0_0004); }
    putreg32(0x0, SRAM_CTRL_REG1);  // TODO: DMB

    // Set Display Engine PLL to 297 MHz
    // Set PLL_DE_CTRL_REG to 0x8100 1701 (DMB)
    //   PLL_ENABLE    (Bit 31)       = 1  (Enable PLL)
    //   PLL_MODE_SEL  (Bit 24)       = 1  (Integer Mode)
    //   PLL_FACTOR_N  (Bits 8 to 14) = 23 (N = 24)
    //   PLL_PRE_DIV_M (Bits 0 to 3)  = 1  (M = 2)
    // Actual PLL Output = 24 MHz * N / M = 288 MHz
    // (Slighltly below 297 MHz due to truncation)
    // PLL_DE_CTRL_REG (PLL Display Engine Control Register) is at CCU Offset 0x0048
    // (A64 Page 96, 0x1C2 0048)
    debug("Set Display Engine PLL to 297 MHz", .{});
    const PLL_ENABLE    = 1  << 31;  // Enable PLL
    const PLL_MODE_SEL  = 1  << 24;  // Integer Mode
    const PLL_FACTOR_N  = 23 <<  8;  // N = 24
    const PLL_PRE_DIV_M = 1  <<  0;  // M = 2
    const pll = PLL_ENABLE
        | PLL_MODE_SEL
        | PLL_FACTOR_N
        | PLL_PRE_DIV_M;
    comptime{ assert(pll == 0x8100_1701); }
    const PLL_DE_CTRL_REG = CCU_BASE_ADDRESS + 0x0048;
    comptime{ assert(PLL_DE_CTRL_REG == 0x1C2_0048); }
    putreg32(pll, PLL_DE_CTRL_REG);  // TODO: DMB

    // Wait for Display Engine PLL to be stable
    // Poll PLL_DE_CTRL_REG (from above) until LOCK (Bit 28) is 1
    // (PLL is Locked and Stable)
    debug("Wait for Display Engine PLL to be stable", .{});
    while (getreg32(PLL_DE_CTRL_REG) & (1 << 28) == 0) {}

    // Set Special Clock to Display Engine PLL
    // Clear DE_CLK_REG bits 0x0300 0000
    // Set DE_CLK_REG bits 0x8100 0000
    // SCLK_GATING (Bit 31) = 1 (Enable Special Clock)
    // CLK_SRC_SEL (Bits 24 to 26) = 1 (Clock Source is Display Engine PLL)
    // DE_CLK_REG (Display Engine Clock Register) is at CCU Offset 0x0104
    // (A64 Page 117, 0x1C2 0104)
    debug("Set Special Clock to Display Engine PLL", .{});
    const DE_CLK_REG = CCU_BASE_ADDRESS + 0x0104;
    comptime{ assert(DE_CLK_REG == 0x1C2_0104); }
    const SCLK_GATING = 1 << 31;  // Enable Special Clock
    const CLK_SRC_SEL = 1 << 24;  // Clock Source is Display Engine PLL
    const clk = SCLK_GATING
        | CLK_SRC_SEL;
    comptime{ assert(clk == 0x8100_0000); }
    modifyreg32(DE_CLK_REG, 0b11 << 24, clk);

    // Enable AHB (AMBA High-speed Bus) for Display Engine: De-Assert Display Engine
    // Set BUS_SOFT_RST_REG1 bits 0x1000
    // DE_RST (Bit 12) = 1 (De-Assert Display Engine)
    // BUS_SOFT_RST_REG1 (Bus Software Reset Register 1) is at CCU Offset 0x02C4
    // (A64 Page 140, 0x1C2 02C4)
    debug("Enable AHB for Display Engine: De-Assert Display Engine", .{});
    const DE_RST = 1 << 12;  // De-Assert Display Engine
    const BUS_SOFT_RST_REG1 = CCU_BASE_ADDRESS + 0x02C4;
    comptime{ assert(BUS_SOFT_RST_REG1 == 0x1C2_02C4); }
    modifyreg32(BUS_SOFT_RST_REG1, 0, DE_RST);

    // Enable AHB (AMBA High-speed Bus) for Display Engine: Pass Display Engine
    // Set BUS_CLK_GATING_REG1 bits 0x1000
    // DE_GATING (Bit 12) = 1 (Pass Display Engine)
    // BUS_CLK_GATING_REG1 (Bus Clock Gating Register 1) is at CCU Offset 0x0064
    // (A64 Page 102, 0x1C2 0064)
    debug("Enable AHB for Display Engine: Pass Display Engine", .{});
    const DE_GATING = 1 << 12;  // Pass Display Engine
    const BUS_CLK_GATING_REG1 = CCU_BASE_ADDRESS + 0x0064;
    comptime{ assert(BUS_CLK_GATING_REG1 == 0x1C2_0064); }
    modifyreg32(BUS_CLK_GATING_REG1, 0, DE_GATING);

    // Enable Clock for MIXER0: SCLK Clock Pass
    // Set SCLK_GATE bits 0x1
    // CORE0_SCLK_GATE (Bit 0) = 1 (Clock Pass)
    // SCLK_GATE is at DE Offset 0x000
    // (DE Page 25, 0x100 0000)
    debug("Enable Clock for MIXER0: SCLK Clock Pass", .{});
    const CORE0_SCLK_GATE = 1 << 0;  // Clock Pass
    const SCLK_GATE = DISPLAY_ENGINE_BASE_ADDRESS + 0x000;
    comptime{ assert(SCLK_GATE == 0x100_0000); }
    modifyreg32(SCLK_GATE, 0, CORE0_SCLK_GATE);

    // Enable Clock for MIXER0: HCLK Clock Reset Off
    // Set AHB_RESET bits 0x1
    // CORE0_HCLK_RESET (Bit 0) = 1 (Reset Off)
    // AHB_RESET is at DE Offset 0x008
    // (DE Page 25, 0x100 0008)
    debug("Enable Clock for MIXER0: HCLK Clock Reset Off", .{});
    const CORE0_HCLK_RESET = 1 << 0;  // Reset Off
    const AHB_RESET = DISPLAY_ENGINE_BASE_ADDRESS + 0x008;
    comptime{ assert(AHB_RESET == 0x100_0008); }
    modifyreg32(AHB_RESET, 0, CORE0_HCLK_RESET);

    // Enable Clock for MIXER0: HCLK Clock Pass
    // Set HCLK_GATE bits 0x1
    // CORE0_HCLK_GATE (Bit 0) = 1 (Clock Pass)
    // HCLK_GATE is at DE Offset 0x004
    // (DE Page 25, 0x100 0004)
    debug("Enable Clock for MIXER0: HCLK Clock Pass", .{});
    const CORE0_HCLK_GATE = 1 << 0;  // Clock Pass
    const HCLK_GATE = DISPLAY_ENGINE_BASE_ADDRESS + 0x004;
    comptime{ assert(HCLK_GATE == 0x100_0004); }
    modifyreg32(HCLK_GATE, 0, CORE0_HCLK_GATE);

    // Route MIXER0 to TCON0
    // Clear DE2TCON_MUX bits 0x1
    // DE2TCON_MUX (Bit 0) = 0
    // (Route MIXER0 to TCON0; Route MIXER1 to TCON1)
    // DE2TCON_MUX is at DE Offset 0x010
    // (DE Page 26, 0x100 0010)
    debug("Route MIXER0 to TCON0", .{});
    const DE2TCON_MUX_MASK = 1 << 0;  // Route MIXER0 to TCON0; Route MIXER1 to TCON1
    const DE2TCON_MUX = DISPLAY_ENGINE_BASE_ADDRESS + 0x010;
    comptime{ assert(DE2TCON_MUX == 0x100_0010); }
    modifyreg32(DE2TCON_MUX, DE2TCON_MUX_MASK, 0);

    // Clear MIXER0 Registers: Global Registers (GLB), Blender (BLD), Video Overlay (OVL_V), UI Overlay (OVL_UI)
    // Set MIXER0 Offsets 0x0000 - 0x5FFF to 0
    // GLB (Global Regisers) at MIXER0 Offset 0x0000
    // BLD (Blender) at MIXER0 Offset 0x1000
    // OVL_V(CH0) (Video Overlay) at MIXER0 Offset 0x2000
    // OVL_UI(CH1) (UI Overlay 1) at MIXER0 Offset 0x3000
    // OVL_UI(CH2) (UI Overlay 2) at MIXER0 Offset 0x4000
    // OVL_UI(CH3) (UI Overlay 3) at MIXER0 Offset 0x5000
    // (DE Page 90, 0x110 0000 - 0x110 5FFF)
    debug("Clear MIXER0 Registers: GLB, BLD, OVL_V, OVL_UI", .{});
    var i: usize = 0;
    while (i < 0x6000) : (i += 4) {
        putreg32(0, MIXER0_BASE_ADDRESS + i);
        enableLog = false;
    }
    enableLog = true;

    // Disable MIXER0 Video Scaler (VSU)
    // Set to 0: VS_CTRL_REG at VIDEO_SCALER(CH0) Offset 0
    // EN (Bit 0) = 0 (Disable Video Scaler)
    // (DE Page 130, 0x112 0000)
    debug("Disable MIXER0 VSU", .{});
    const VS_CTRL_REG = VIDEO_SCALER_BASE_ADDRESS + 0;
    comptime{ assert(VS_CTRL_REG == 0x112_0000); }
    putreg32(0, VS_CTRL_REG);

    // TODO: 0x113 0000 is undocumented
    // Is there a mixup with UI_SCALER3?
    debug("Disable MIXER0 Undocumented", .{});
    const _1130000 = 0x1130000;
    putreg32(0, _1130000);

    // Disable MIXER0 UI_SCALER1
    // Set to 0: UIS_CTRL_REG at UI_SCALER1(CH1) Offset 0
    // EN (Bit 0) = 0 (Disable UI Scaler)
    // (DE Page 66, 0x114 0000)
    debug("Disable MIXER0 UI_SCALER1", .{});
    const UIS_CTRL_REG1 = UI_SCALER1_BASE_ADDRESS + 0;
    comptime{ assert(UIS_CTRL_REG1 == 0x114_0000); }
    putreg32(0, UIS_CTRL_REG1);

    // Disable MIXER0 UI_SCALER2
    // Set to 0: UIS_CTRL_REG at UI_SCALER2(CH2) Offset 0
    // EN (Bit 0) = 0 (Disable UI Scaler)
    // (DE Page 66, 0x115 0000)
    debug("Disable MIXER0 UI_SCALER2", .{});
    const UIS_CTRL_REG2 = UI_SCALER2_BASE_ADDRESS + 0;
    comptime{ assert(UIS_CTRL_REG2 == 0x115_0000); }
    putreg32(0, UIS_CTRL_REG2);

    // TODO: Missing UI_SCALER3(CH3) at MIXER0 Offset 0x06 0000 (DE Page 90, 0x116 0000)
    // Is there a mixup with 0x113 0000 above?

    // Disable MIXER0 FCE
    // Set to 0: GCTRL_REG(FCE) at FCE Offset 0
    // EN (Bit 0) = 0 (Disable FCE)
    // (DE Page 62, 0x11A 0000)
    debug("Disable MIXER0 FCE", .{});
    const GCTRL_REG_FCE = FCE_BASE_ADDRESS + 0;
    comptime{ assert(GCTRL_REG_FCE == 0x11A_0000); }
    putreg32(0, GCTRL_REG_FCE);

    // Disable MIXER0 BWS
    // Set to 0: GCTRL_REG(BWS) at BWS Offset 0
    // EN (Bit 0) = 0 (Disable BWS)
    // (DE Page 42, 0x11A 2000)
    debug("Disable MIXER0 BWS", .{});
    const GCTRL_REG_BWS = BWS_BASE_ADDRESS + 0;
    comptime{ assert(GCTRL_REG_BWS == 0x11A_2000); }
    putreg32(0, GCTRL_REG_BWS);

    // Disable MIXER0 LTI
    // Set to 0: LTI_CTL at LTI Offset 0
    // LTI_EN (Bit 0) = 0 (Close LTI)
    // (DE Page 72, 0x11A 4000)
    debug("Disable MIXER0 LTI", .{});
    const LTI_CTL = LTI_BASE_ADDRESS + 0;
    comptime{ assert(LTI_CTL == 0x11A_4000); }
    putreg32(0, LTI_CTL);

    // Disable MIXER0 PEAKING
    // Set to 0: LP_CTRL_REG at PEAKING Offset 0
    // EN (Bit 0) = 0 (Disable PEAKING)
    // (DE Page 80, 0x11A 6000)
    debug("Disable MIXER0 PEAKING", .{});
    const LP_CTRL_REG = PEAKING_BASE_ADDRESS + 0;
    comptime{ assert(LP_CTRL_REG == 0x11A_6000); }
    putreg32(0, LP_CTRL_REG);

    // Disable MIXER0 ASE
    // Set to 0: ASE_CTL_REG at ASE Offset 0
    // ASE_EN (Bit 0) = 0 (Disable ASE)
    // (DE Page 40, 0x11A 8000)
    debug("Disable MIXER0 ASE", .{});
    const ASE_CTL_REG = ASE_BASE_ADDRESS + 0;
    comptime{ assert(ASE_CTL_REG == 0x11A_8000); }
    putreg32(0, ASE_CTL_REG);

    // Disable MIXER0 FCC
    // Set to 0: FCC_CTL_REG at FCC Offset 0
    // Enable (Bit 0) = 0 (Disable FCC)
    // (DE Page 56, 0x11A A000)
    debug("Disable MIXER0 FCC", .{});
    const FCC_CTL_REG = FCC_BASE_ADDRESS + 0;
    comptime{ assert(FCC_CTL_REG == 0x11A_A000); }
    putreg32(0, FCC_CTL_REG);

    // Disable MIXER0 DRC
    // Set to 0: GNECTL_REG at DRC Offset 0
    // BIST_EN (Bit 0) = 0 (Disable BIST)
    // (DE Page 49, 0x11B 0000)
    debug("Disable MIXER0 DRC", .{});
    const GNECTL_REG = DRC_BASE_ADDRESS + 0;
    comptime{ assert(GNECTL_REG == 0x11B_0000); }
    putreg32(0, GNECTL_REG);

    // Enable MIXER0
    // Set GLB_CTL to 1 (DMB)
    // EN (Bit 0) = 1 (Enable Mixer)
    // (DE Page 92)
    // GLB_CTL is at MIXER0 Offset 0
    // (DE Page 90, 0x110 0000)
    debug("Enable MIXER0", .{});
    const EN_MIXER = 1 << 0;  // Enable Mixer
    const GLB_CTL = MIXER0_BASE_ADDRESS + 0;
    comptime{ assert(GLB_CTL == 0x110_0000); }
    putreg32(EN_MIXER, GLB_CTL);  // TODO: DMB
}

/// Export MIPI DSI Functions to C. (Why is this needed?)
pub export fn export_dsi_functions() void {
    // Export Panel Init Function
    dsi.nuttx_panel_init();
}

/// Atomically modify the specified bits in a memory mapped register.
/// Based on https://github.com/lupyuen/incubator-nuttx/blob/pinephone/arch/arm/src/common/arm_modifyreg32.c#L38-L57
fn modifyreg32(
    addr: u64,       // Address to modify
    clearbits: u32,  // Bits to clear, like (1 << bit)
    setbits: u32     // Bit to set, like (1 << bit)
) void {
    debug("  0x{x}: clear 0x{x}, set 0x{x}", .{ addr, clearbits, setbits });
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
