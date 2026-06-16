/* kernel/main.c
 * Language: C17 freestanding
 * Purpose: Future C kernel initialization sequence.
 * Build: x86_64-elf-gcc -std=c17 -ffreestanding -mno-red-zone -c kernel/main.c
 */
#include <kernel/boot.h>
#include <kernel/gdt.h>
#include <kernel/idt.h>
#include <kernel/mm.h>
#include <kernel/printk.h>
#include <kernel/process.h>

static bool boot_info_valid(const NavineBootInfo *bi) {
    return bi != NULL && bi->magic == NAVINE_BOOT_MAGIC;
}

void kernel_main(NavineBootInfo *bi) {
    early_console_init(bi);

    if (!boot_info_valid(bi)) {
        kernel_panic("invalid boot info");
    }

    early_puts("Navine C kernel scaffold\n");
    gdt_init();
    idt_init();
    pmm_init(bi->mmap_addr, bi->mmap_count, bi->kernel_end);
    vmm_init();
    heap_init();
    scheduler_init();

    for (;;) {
        __asm__ volatile("hlt");
    }
}
