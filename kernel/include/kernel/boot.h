/* kernel/include/kernel/boot.h
 * Language: C17
 * Purpose: Bootloader-to-kernel handoff structures.
 * Build: included by kernel/main.c and early platform code.
 */
#ifndef NAVINE_KERNEL_BOOT_H
#define NAVINE_KERNEL_BOOT_H

#include <kernel/types.h>

#define NAVINE_BOOT_MAGIC 0x4956414Eu /* "NAVI" little-endian */
#define NAVINE_E820_USABLE 1u

typedef struct NAVINE_PACKED {
    uint64_t base;
    uint64_t length;
    uint32_t type;
    uint32_t attr;
} NavineE820Entry;

typedef struct NAVINE_PACKED {
    uint32_t magic;
    uint64_t fb_base;
    uint32_t fb_width;
    uint32_t fb_height;
    uint32_t fb_pitch;
    uint32_t fb_bpp;
    uint64_t mmap_addr;
    uint32_t mmap_count;
    uint64_t kernel_start;
    uint64_t kernel_end;
    uint64_t initrd_start;
    uint64_t initrd_end;
    uint64_t rsdp_addr;
    uint64_t cmdline_addr;
} NavineBootInfo;

#endif
