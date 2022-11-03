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
    debug("test_render", .{});

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
    debug("test_render2", .{});

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
    debug("initUiBlender\nConfigure Blender", .{});

    // BLD_BK_COLOR @ BLD Offset 0x88: BLD background color register
    // Set to 0xff00 0000 (Why?)
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
    debug("applySettings\nSet BLD Route and BLD FColor Control", .{});
    assert(channels == 1 or channels == 3);

    // Set BLD Route and BLD FColor Control
    // -   BLD Route (BLD_CH_RTCTL @ BLD Offset 0x080): _BLD routing control register_
    //     For 3 UI Channels: Set to 0x321 (Why?)
    //     For 1 UI Channel: Set to 1 (Why?)
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
    debug("initUiChannel", .{});
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

// Init PinePhone's Allwinner A64 Display Engine.
// Based on the log: https://gist.github.com/lupyuen/c12f64cf03d3a81e9c69f9fef49d9b70#de2_init
pub export fn de2_init() void {
    // Set SRAM for video use
    //   0x1c00004 = 0x0 (DMB)
    debug("Set SRAM for video use", .{});
    const _1c00004 = 0x1c00004;
    putreg32(0x0, _1c00004);  // TODO: DMB

    // Setup DE2 PLL
    // clock_set_pll_de: clk=297000000
    // PLL10 rate = 24000000 * n / m
    //   0x1c20048 = 0x81001701 (DMB)
    debug("Setup DE2 PLL", .{});
    const _1c20048 = 0x1c20048;
    putreg32(0x81001701, _1c20048);  // TODO: DMB

    //   while (!(readl(0x1c20048) & 0x10000000))
    while (getreg32(_1c20048) & 0x10000000 == 0) {}

    // Enable DE2 special clock
    //   clrsetbits 0x1c20104, 0x3000000, 0x81000000
    debug("Enable DE2 special clock", .{});
    const _1c20104 = 0x1c20104;
    modifyreg32(_1c20104, 0x3000000, 0x81000000);

    // Enable DE2 ahb
    //   setbits 0x1c202c4, 0x1000
    debug("Enable DE2 ahb", .{});
    const _1c202c4 = 0x1c202c4;
    modifyreg32(_1c202c4, 0, 0x1000);

    //   setbits 0x1c20064, 0x1000
    const _1c20064 = 0x1c20064;
    modifyreg32(_1c20064, 0, 0x1000);

    // Enable clock for mixer 0, set route MIXER0->TCON0
    //   setbits 0x1000000, 0x1
    debug("Enable clock for mixer 0, set route MIXER0->TCON0", .{});
    const _1000000 = 0x1000000;
    modifyreg32(_1000000, 0, 0x1);

    //   setbits 0x1000008, 0x1
    const _1000008 = 0x1000008;
    modifyreg32(_1000008, 0, 0x1);

    //   setbits 0x1000004, 0x1
    const _1000004 = 0x1000004;
    modifyreg32(_1000004, 0, 0x1);

    //   clrbits 0x1000010, 0x1
    const _1000010 = 0x1000010;
    modifyreg32(_1000010, 0x1, 0);

    // Clear all registers
    //   0x1100000 to 0x1105fff = 0x0
    debug("Clear all registers 0x1100000 to 0x1105fff", .{});
    const _1100000 = 0x1100000;
    var i: usize = 0;
    while (i < 0x6000) : (i += 1) {
        putreg32(0x0, _1100000 + i);
        enableLog = false;
    }
    enableLog = true;

    //   0x1120000 = 0x0
    const _1120000 = 0x1120000;
    putreg32(0x0, _1120000);

    //   0x1130000 = 0x0
    const _1130000 = 0x1130000;
    putreg32(0x0, _1130000);

    //   0x1140000 = 0x0
    const _1140000 = 0x1140000;
    putreg32(0x0, _1140000);

    //   0x1150000 = 0x0
    const _1150000 = 0x1150000;
    putreg32(0x0, _1150000);

    //   0x11a0000 = 0x0
    const _11a0000 = 0x11a0000;
    putreg32(0x0, _11a0000);

    //   0x11a2000 = 0x0
    const _11a2000 = 0x11a2000;
    putreg32(0x0, _11a2000);

    //   0x11a4000 = 0x0
    const _11a4000 = 0x11a4000;
    putreg32(0x0, _11a4000);

    //   0x11a6000 = 0x0
    const _11a6000 = 0x11a6000;
    putreg32(0x0, _11a6000);

    //   0x11a8000 = 0x0
    const _11a8000 = 0x11a8000;
    putreg32(0x0, _11a8000);

    //   0x11aa000 = 0x0
    const _11aa000 = 0x11aa000;
    putreg32(0x0, _11aa000);

    //   0x11b0000 = 0x0
    const _11b0000 = 0x11b0000;
    putreg32(0x0, _11b0000);

    // Enable mixer
    //   0x1100000 = 0x1 (DMB)    
    debug("Enable mixer", .{});
    const MIXER = 0x1100000;
    putreg32(0x1, MIXER);  // TODO: DMB
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
    debug("modifyreg32: addr=0x{x:0>3}, val=0x{x:0>8}", .{ addr, setbits & clearbits });
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
