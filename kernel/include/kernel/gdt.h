/* kernel/include/kernel/gdt.h
 * Language: C17
 * Purpose: GDT and TSS descriptors for x86-64.
 * Build: included by kernel/gdt.c.
 */
#ifndef NAVINE_KERNEL_GDT_H
#define NAVINE_KERNEL_GDT_H

#include <kernel/types.h>

#define GDT_NULL        0x00u
#define GDT_KERNEL_CODE 0x08u
#define GDT_KERNEL_DATA 0x10u
#define GDT_USER_CODE   0x18u
#define GDT_USER_DATA   0x20u
#define GDT_TSS_LOW     0x28u
#define GDT_TSS_HIGH    0x30u

typedef struct NAVINE_PACKED {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t base_mid;
    uint8_t access;
    uint8_t granularity;
    uint8_t base_high;
} GDTEntry;

typedef struct NAVINE_PACKED {
    uint16_t limit;
    uint64_t base;
} GDTPointer;

typedef struct NAVINE_PACKED {
    uint32_t reserved0;
    uint64_t rsp[3];
    uint64_t reserved1;
    uint64_t ist[7];
    uint64_t reserved2;
    uint16_t reserved3;
    uint16_t iomap_base;
} TSS;

void gdt_init(void);
void gdt_set_kernel_stack(uint64_t rsp0);

#endif
