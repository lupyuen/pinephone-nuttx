#include <stdbool.h>
#include <stdio.h>

#define ARM64_DMB()
#define ARM64_DSB()
#define ARM64_ISB()
#define CONFIG_BOARD_LOOPSPERMSEC 5000
#define DEBUGASSERT assert
#define DEBUGPANIC() assert(false)
#define ERROR -1
#define FAR
#define OK 0
