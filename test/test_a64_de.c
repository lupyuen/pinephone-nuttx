// Test Code for Allwinner A64 Display Engine
// Add `#include "../../pinephone-nuttx/test/test_a64_de.c"` to the end of this file:
// https://github.com/apache/nuttx/blob/master/arch/arm64/src/a64/a64_de.c

#define CONFIG_FB_OVERLAY y

#include <nuttx/video/fb.h>
#include "a64_tcon0.h"

#ifdef TODO
/// NuttX Video Controller for PinePhone (3 UI Channels)
static struct fb_videoinfo_s videoInfo =
{
  .fmt       = FB_FMT_RGBA32,  // Pixel format (XRGB 8888)
  .xres      = A64_TCON0_PANEL_WIDTH,      // Horizontal resolution in pixel columns
  .yres      = A64_TCON0_PANEL_HEIGHT,     // Vertical resolution in pixel rows
  .nplanes   = 1,     // Number of color planes supported (Base UI Channel)
  .noverlays = 2      // Number of overlays supported (2 Overlay UI Channels)
};
#endif  // TODO

// Framebuffer 0: (Base UI Channel)
// Fullscreen 720 x 1440 (4 bytes per XRGB 8888 pixel)
static uint32_t fb0[A64_TCON0_PANEL_WIDTH * A64_TCON0_PANEL_HEIGHT];

// Framebuffer 1: (First Overlay UI Channel)
// Square 600 x 600 (4 bytes per ARGB 8888 pixel)
#define FB1_WIDTH  600
#define FB1_HEIGHT 600
static uint32_t fb1[FB1_WIDTH * FB1_HEIGHT];

// Framebuffer 2: (Second Overlay UI Channel)
// Fullscreen 720 x 1440 (4 bytes per ARGB 8888 pixel)
static uint32_t fb2[A64_TCON0_PANEL_WIDTH * A64_TCON0_PANEL_HEIGHT];

/// NuttX Color Plane for PinePhone (Base UI Channel):
/// Fullscreen 720 x 1440 (4 bytes per XRGB 8888 pixel)
static struct fb_planeinfo_s planeInfo =
{
  .fbmem   = &fb0,     // Start of frame buffer memory
  .fblen   = sizeof(fb0),  // Length of frame buffer memory in bytes
  .stride  = A64_TCON0_PANEL_WIDTH * 4,  // Length of a line in bytes (4 bytes per pixel)
  .display = 0,        // Display number (Unused)
  .bpp     = 32,       // Bits per pixel (XRGB 8888)
  .xres_virtual = A64_TCON0_PANEL_WIDTH,   // Virtual Horizontal resolution in pixel columns
  .yres_virtual = A64_TCON0_PANEL_HEIGHT,  // Virtual Vertical resolution in pixel rows
  .xoffset      = 0,     // Offset from virtual to visible resolution
  .yoffset      = 0      // Offset from virtual to visible resolution
};

/// NuttX Overlays for PinePhone (2 Overlay UI Channels)
static struct fb_overlayinfo_s overlayInfo[2] =
{
  // First Overlay UI Channel:
  // Square 600 x 600 (4 bytes per ARGB 8888 pixel)
  {
    .fbmem     = &fb1,     // Start of frame buffer memory
    .fblen     = sizeof(fb1),  // Length of frame buffer memory in bytes
    .stride    = FB1_WIDTH * 4,  // Length of a line in bytes
    .overlay   = 0,        // Overlay number (First Overlay)
    .bpp       = 32,       // Bits per pixel (ARGB 8888)
    .blank     = 0,        // TODO: Blank or unblank
    .chromakey = 0,        // TODO: Chroma key argb8888 formatted
    .color     = 0,        // TODO: Color argb8888 formatted
    .transp    = { .transp = 0, .transp_mode = 0 },  // TODO: Transparency
    .sarea     = { .x = 52, .y = 52, .w = FB1_WIDTH, .h = FB1_HEIGHT },  // Selected area within the overlay
    .accl      = 0         // TODO: Supported hardware acceleration
  },
  // Second Overlay UI Channel:
  // Fullscreen 720 x 1440 (4 bytes per ARGB 8888 pixel)
  {
    .fbmem     = &fb2,     // Start of frame buffer memory
    .fblen     = sizeof(fb2),  // Length of frame buffer memory in bytes
    .stride    = A64_TCON0_PANEL_WIDTH * 4,  // Length of a line in bytes
    .overlay   = 1,        // Overlay number (Second Overlay)
    .bpp       = 32,       // Bits per pixel (ARGB 8888)
    .blank     = 0,        // TODO: Blank or unblank
    .chromakey = 0,        // TODO: Chroma key argb8888 formatted
    .color     = 0,        // TODO: Color argb8888 formatted
    .transp    = { .transp = 0, .transp_mode = 0 },  // TODO: Transparency
    .sarea     = { .x = 0, .y = 0, .w = A64_TCON0_PANEL_WIDTH, .h = A64_TCON0_PANEL_HEIGHT },  // Selected area within the overlay
    .accl      = 0         // TODO: Supported hardware acceleration
  },
};

int render_graphics(void)
{
  // Init the UI Blender for PinePhone's A64 Display Engine
  int ret = a64_de_blender_init();
  assert(ret == OK);

#ifndef __NuttX__
  // For Local Testing: Only 32-bit addresses allowed
  planeInfo.fbmem = (void *)0x12345678;
  overlayInfo[0].fbmem = (void *)0x23456789;
  overlayInfo[1].fbmem = (void *)0x34567890;
#endif // !__NuttX__

  // Init the Base UI Channel
  ret = a64_de_ui_channel_init(
    1,  // UI Channel Number (1 for Base UI Channel)
    planeInfo.fbmem,    // Start of frame buffer memory
    planeInfo.fblen,    // Length of frame buffer memory in bytes
    planeInfo.stride,   // Length of a line in bytes (4 bytes per pixel)
    planeInfo.xres_virtual,  // Horizontal resolution in pixel columns
    planeInfo.yres_virtual,  // Vertical resolution in pixel rows
    planeInfo.xoffset,  // Horizontal offset in pixel columns
    planeInfo.yoffset  // Vertical offset in pixel rows
  );
  assert(ret == OK);

  // Init the 2 Overlay UI Channels
  #define CHANNELS 3
  for (int i = 0; i < sizeof(overlayInfo) / sizeof(overlayInfo[0]); i++)
  {
    const struct fb_overlayinfo_s *ov = &overlayInfo[i];
    ret = a64_de_ui_channel_init(
      i + 2,  // UI Channel Number (2 and 3 for Overlay UI Channels)
      (CHANNELS == 3) ? ov->fbmem : NULL,  // Start of frame buffer memory
      ov->fblen,    // Length of frame buffer memory in bytes
      ov->stride,   // Length of a line in bytes (4 bytes per pixel)
      ov->sarea.w,  // Horizontal resolution in pixel columns
      ov->sarea.h,  // Vertical resolution in pixel rows
      ov->sarea.x,  // Horizontal offset in pixel columns
      ov->sarea.y  // Vertical offset in pixel rows
    );
    assert(ret == OK);
  }

  // Set UI Blender Route, enable Blender Pipes and apply the settings
  ret = a64_de_enable(CHANNELS);
  assert(ret == OK);    

  return OK;
}

void test_pattern(void)
{
  memset(fb0, 0, sizeof(fb0));
  memset(fb1, 0, sizeof(fb1));
  memset(fb2, 0, sizeof(fb2));

  memset(fb0, 0, 0b10101010);
  memset(fb1, 0, 0b11001100);
  memset(fb2, 0, 0b11100111);
}
