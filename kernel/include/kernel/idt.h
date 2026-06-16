/* kernel/include/kernel/idt.h
 * Language: C17
 * Purpose: Interrupt descriptor table API.
 * Build: included by interrupt and driver code.
 */
#ifndef NAVINE_KERNEL_IDT_H
#define NAVINE_KERNEL_IDT_H

#include <kernel/types.h>

typedef struct NAVINE_PACKED {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t ist;
    uint8_t type_attr;
    uint16_t offset_mid;
    uint32_t offset_high;
    uint32_t zero;
} IDTEntry;

typedef struct NAVINE_PACKED {
    uint16_t limit;
    uint64_t base;
} IDTPointer;

typedef struct NAVINE_PACKED {
    uint64_t r15, r14, r13, r12, r11, r10, r9, r8;
    uint64_t rsi, rdi, rbp, rdx, rcx, rbx, rax;
    uint64_t vector, error;
    uint64_t rip, cs, rflags, rsp, ss;
} CpuTrapFrame;

typedef void (*IrqHandler)(CpuTrapFrame *frame);

void idt_init(void);
void idt_set_gate(uint8_t vector, void (*handler)(void), uint8_t flags);
void irq_register(uint8_t irq, IrqHandler handler);

#endif
