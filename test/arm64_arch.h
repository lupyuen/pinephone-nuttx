/// Modify the specified bits in a memory mapped register.
/// Based on https://github.com/apache/nuttx/blob/master/arch/arm64/src/common/arm64_arch.h#L473
void modreg32(
    uint32_t val,   // Bits to set, like (1 << bit)
    uint32_t mask,  // Bits to clear, like (1 << bit)
    unsigned long addr  // Address to modify
);

uint32_t getreg32(unsigned long addr);

void putreg32(uint32_t data, unsigned long addr);
