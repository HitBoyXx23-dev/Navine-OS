#include "navine_compat.h"
#include <stdint.h>

typedef struct {
    uint64_t base;
    uint32_t width;
    uint32_t height;
    uint32_t pitch;
    uint32_t bpp;
} navine_fb_info_t;

static inline uint8_t navine_inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline uint32_t navine_get_ticks(void) {
    static uint32_t ticks;
    ticks++;
    return ticks * 16;
}

static inline navine_fb_info_t *navine_fb(void) {
    return (navine_fb_info_t *)(uintptr_t)NAVINE_FB_INFO_PHYS;
}

static inline uint8_t *navine_wad_base(void) {
    return (uint8_t *)(uintptr_t)NAVINE_WAD_PHYS;
}

static inline uint32_t navine_wad_size(void) {
    return *(volatile uint32_t *)(uintptr_t)NAVINE_WAD_SIZE_PHYS;
}
