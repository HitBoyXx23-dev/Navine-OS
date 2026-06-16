/* kernel/gdt.c
 * Language: C17 freestanding
 * Purpose: GDT and TSS setup for x86-64.
 */
#include <kernel/gdt.h>

static GDTEntry gdt[7];
static TSS tss;
static GDTPointer gdt_ptr;

static void set_entry(uint32_t index, uint32_t base, uint32_t limit,
                      uint8_t access, uint8_t granularity) {
    gdt[index].limit_low = (uint16_t)(limit & 0xFFFFu);
    gdt[index].base_low = (uint16_t)(base & 0xFFFFu);
    gdt[index].base_mid = (uint8_t)((base >> 16) & 0xFFu);
    gdt[index].access = access;
    gdt[index].granularity = (uint8_t)(((limit >> 16) & 0x0Fu) | (granularity & 0xF0u));
    gdt[index].base_high = (uint8_t)((base >> 24) & 0xFFu);
}

static void set_tss(uint32_t index, uint64_t base, uint32_t limit) {
    set_entry(index, (uint32_t)base, limit, 0x89u, 0x00u);
    uint64_t *high = (uint64_t *)&gdt[index + 1];
    *high = base >> 32;
}

void gdt_set_kernel_stack(uint64_t rsp0) {
    tss.rsp[0] = rsp0;
}

void gdt_init(void) {
    set_entry(0, 0, 0, 0, 0);
    set_entry(1, 0, 0xFFFFFu, 0x9Au, 0xA0u);
    set_entry(2, 0, 0xFFFFFu, 0x92u, 0xA0u);
    set_entry(3, 0, 0xFFFFFu, 0xFAu, 0xA0u);
    set_entry(4, 0, 0xFFFFFu, 0xF2u, 0xA0u);
    set_tss(5, (uint64_t)(uintptr_t)&tss, sizeof(TSS) - 1u);

    gdt_ptr.limit = sizeof(gdt) - 1u;
    gdt_ptr.base = (uint64_t)(uintptr_t)&gdt[0];

    __asm__ volatile("lgdt %0" : : "m"(gdt_ptr));
    __asm__ volatile(
        "pushq $0x08\n"
        "leaq 1f(%%rip), %%rax\n"
        "pushq %%rax\n"
        "lretq\n"
        "1:\n"
        "movw $0x10, %%ax\n"
        "movw %%ax, %%ds\n"
        "movw %%ax, %%es\n"
        "movw %%ax, %%ss\n"
        "movw $0x28, %%ax\n"
        "ltr %%ax\n"
        :
        :
        : "rax", "memory");
}
