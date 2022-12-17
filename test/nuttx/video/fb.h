#define FB_FMT_RGBA32         21          /* BPP=32 Raw RGB with alpha */
typedef uint16_t fb_coord_t;

struct fb_videoinfo_s
{
  uint8_t    fmt;               /* see FB_FMT_*  */
  fb_coord_t xres;              /* Horizontal resolution in pixel columns */
  fb_coord_t yres;              /* Vertical resolution in pixel rows */
  uint8_t    nplanes;           /* Number of color planes supported */
#ifdef CONFIG_FB_OVERLAY
  uint8_t    noverlays;         /* Number of overlays supported */
#endif
#ifdef CONFIG_FB_MODULEINFO
  uint8_t    moduleinfo[128];   /* Module information filled by vendor */
#endif
};

struct fb_planeinfo_s
{
  FAR void  *fbmem;        /* Start of frame buffer memory */
  size_t     fblen;        /* Length of frame buffer memory in bytes */
  fb_coord_t stride;       /* Length of a line in bytes */
  uint8_t    display;      /* Display number */
  uint8_t    bpp;          /* Bits per pixel */
  uint32_t   xres_virtual; /* Virtual Horizontal resolution in pixel columns */
  uint32_t   yres_virtual; /* Virtual Vertical resolution in pixel rows */
  uint32_t   xoffset;      /* Offset from virtual to visible resolution */
  uint32_t   yoffset;      /* Offset from virtual to visible resolution */
};

struct fb_area_s
{
  fb_coord_t x;           /* x-offset of the area */
  fb_coord_t y;           /* y-offset of the area */
  fb_coord_t w;           /* Width of the area */
  fb_coord_t h;           /* Height of the area */
};

struct fb_transp_s
{
  uint8_t    transp;      /* Transparency */
  uint8_t    transp_mode; /* Transparency mode */
};

struct fb_overlayinfo_s
{
  FAR void   *fbmem;          /* Start of frame buffer memory */
  size_t     fblen;           /* Length of frame buffer memory in bytes */
  fb_coord_t stride;          /* Length of a line in bytes */
  uint8_t    overlay;         /* Overlay number */
  uint8_t    bpp;             /* Bits per pixel */
  uint8_t    blank;           /* Blank or unblank */
  uint32_t   chromakey;       /* Chroma key argb8888 formatted */
  uint32_t   color;           /* Color argb8888 formatted */
  struct fb_transp_s transp;  /* Transparency */
  struct fb_area_s sarea;     /* Selected area within the overlay */
  uint32_t   accl;            /* Supported hardware acceleration */
};
