/* kernel/idt.c
 * Language: C17 freestanding
 * Purpose: IDT setup and IRQ handler registry.
 */
#include <kernel/idt.h>
#include <kernel/printk.h>

static IDTEntry idt[256];
static IDTPointer idt_ptr;
static IrqHandler irq_handlers[256];

static void default_interrupt(void) {
    __asm__ volatile("iretq");
}

void idt_set_gate(uint8_t vector, void (*handler)(void), uint8_t flags) {
    uint64_t addr = (uint64_t)(uintptr_t)handler;
    idt[vector].offset_low = (uint16_t)(addr & 0xFFFFu);
    idt[vector].selector = 0x08u;
    idt[vector].ist = 0;
    idt[vector].type_attr = flags;
    idt[vector].offset_mid = (uint16_t)((addr >> 16) & 0xFFFFu);
    idt[vector].offset_high = (uint32_t)(addr >> 32);
    idt[vector].zero = 0;
}

void irq_register(uint8_t irq, IrqHandler handler) {
    irq_handlers[irq] = handler;
}

void idt_init(void) {
    for (uint32_t i = 0; i < 256; ++i) {
        idt_set_gate((uint8_t)i, default_interrupt, 0x8Eu);
        irq_handlers[i] = 0;
    }
    idt_ptr.limit = sizeof(idt) - 1u;
    idt_ptr.base = (uint64_t)(uintptr_t)&idt[0];
    __asm__ volatile("lidt %0" : : "m"(idt_ptr));
}
