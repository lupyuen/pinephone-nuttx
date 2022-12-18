// Test Code for Allwinner A64 Display Engine
// Add `#include "../../pinephone-nuttx/test/test_a64_de.c"` to the end of this file:
// https://github.com/apache/nuttx/blob/master/arch/arm64/src/a64/a64_de.c

#define CONFIG_FB_OVERLAY y
#define CHANNELS 3

#include <nuttx/video/fb.h>
#include "a64_tcon0.h"

static void test_pattern(void);

/// NuttX Video Controller for PinePhone (3 UI Channels)
static struct fb_videoinfo_s videoInfo =
{
  .fmt       = FB_FMT_RGBA32,  // Pixel format (XRGB 8888)
  .xres      = A64_TCON0_PANEL_WIDTH,      // Horizontal resolution in pixel columns
  .yres      = A64_TCON0_PANEL_HEIGHT,     // Vertical resolution in pixel rows
  .nplanes   = 1,     // Number of color planes supported (Base UI Channel)
  .noverlays = 2      // Number of overlays supported (2 Overlay UI Channels)
};

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
  // Validate the Framebuffer Sizes at Compile Time
  // ginfo("fb0=%p, fb1=%p, fb2=%p\n", fb0, fb1, fb2);
  DEBUGASSERT(CHANNELS == 1 || CHANNELS == 3);
  DEBUGASSERT(planeInfo.xres_virtual == videoInfo.xres);
  DEBUGASSERT(planeInfo.yres_virtual == videoInfo.yres);
  DEBUGASSERT(planeInfo.fblen  == planeInfo.xres_virtual * planeInfo.yres_virtual * 4);
  DEBUGASSERT(planeInfo.stride == planeInfo.xres_virtual * 4);
  DEBUGASSERT(overlayInfo[0].fblen  == (overlayInfo[0].sarea.w) * overlayInfo[0].sarea.h * 4);
  DEBUGASSERT(overlayInfo[0].stride == overlayInfo[0].sarea.w * 4);
  DEBUGASSERT(overlayInfo[1].fblen  == (overlayInfo[1].sarea.w) * overlayInfo[1].sarea.h * 4);
  DEBUGASSERT(overlayInfo[1].stride == overlayInfo[1].sarea.w * 4);

  // Init the UI Blender for PinePhone's A64 Display Engine
  int ret = a64_de_blender_init();
  DEBUGASSERT(ret == OK);

#ifndef __NuttX__
#warning Local Testing Only
  // For Local Testing: Only 32-bit addresses allowed
  planeInfo.fbmem = (void *)0x12345678;
  overlayInfo[0].fbmem = (void *)0x23456789;
  overlayInfo[1].fbmem = (void *)0x34567890;
#endif // !__NuttX__

  // Init the Base UI Channel
  // https://github.com/lupyuen2/wip-pinephone-nuttx/blob/tcon2/arch/arm64/src/a64/a64_de.c
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
  DEBUGASSERT(ret == OK);

  // Init the 2 Overlay UI Channels
  // https://github.com/lupyuen2/wip-pinephone-nuttx/blob/tcon2/arch/arm64/src/a64/a64_de.c
  int i;
  for (i = 0; i < sizeof(overlayInfo) / sizeof(overlayInfo[0]); i++)
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
    DEBUGASSERT(ret == OK);
  }

  // Set UI Blender Route, enable Blender Pipes and apply the settings
  // https://github.com/lupyuen2/wip-pinephone-nuttx/blob/tcon2/arch/arm64/src/a64/a64_de.c
  ret = a64_de_enable(CHANNELS);
  DEBUGASSERT(ret == OK);    

  // Fill Framebuffer with Test Pattern.
  // Must be called after Display Engine is Enabled, or black rows will appear.
  test_pattern();

  return OK;
}

// Fill the Framebuffers with a Test Pattern.
// Must be called after Display Engine is Enabled, or black rows will appear.
static void test_pattern(void)
{
  // Zero the Framebuffers
  memset(fb0, 0, sizeof(fb0));
  memset(fb1, 0, sizeof(fb1));
  memset(fb2, 0, sizeof(fb2));

  // Init Framebuffer 0:
  // Fill with Blue, Green and Red
  int i;
  const int fb0_len = sizeof(fb0) / sizeof(fb0[0]);
  for (i = 0; i < fb0_len; i++)
    {
      // Colours are in XRGB 8888 format
      if (i < fb0_len / 4)
        {
          // Blue for top quarter
          fb0[i] = 0x80000080;
        }
      else if (i < fb0_len / 2)
        {
          // Green for next quarter
          fb0[i] = 0x80008000;
        }
      else
        {
          // Red for lower half
          fb0[i] = 0x80800000;
        }

      // Needed to fix black rows, not sure why
      ARM64_DMB();
      ARM64_DSB();
      ARM64_ISB();
    }

  // Init Framebuffer 1:
  // Fill with Semi-Transparent White
  const int fb1_len = sizeof(fb1) / sizeof(fb1[0]);
  for (i = 0; i < fb1_len; i++)
    {
      // Colours are in ARGB 8888 format
      fb1[i] = 0x40FFFFFF;

      // Needed to fix black rows, not sure why
      ARM64_DMB();
      ARM64_DSB();
      ARM64_ISB();
    }

  // Init Framebuffer 2:
  // Fill with Semi-Transparent Green Circle
  const int fb2_len = sizeof(fb2) / sizeof(fb2[0]);
  int y;
  for (y = 0; y < A64_TCON0_PANEL_HEIGHT; y++)
    {
      int x;
      for (x = 0; x < A64_TCON0_PANEL_WIDTH; x++)
        {
          // Get pixel index
          const int p = (y * A64_TCON0_PANEL_WIDTH) + x;
          DEBUGASSERT(p < fb2_len);

          // Shift coordinates so that centre of screen is (0,0)
          const int half_width  = A64_TCON0_PANEL_WIDTH  / 2;
          const int half_height = A64_TCON0_PANEL_HEIGHT / 2;
          const int x_shift = x - half_width;
          const int y_shift = y - half_height;

          // If x^2 + y^2 < radius^2, set the pixel to Semi-Transparent Green
          if (x_shift*x_shift + y_shift*y_shift < half_width*half_width) {
              fb2[p] = 0x80008000;  // Semi-Transparent Green in ARGB 8888 Format
          } else {  // Otherwise set to Transparent Black
              fb2[p] = 0x00000000;  // Transparent Black in ARGB 8888 Format
          }

          // Needed to fix black rows, not sure why
          ARM64_DMB();
          ARM64_DSB();
          ARM64_ISB();
        }
    }
}
