/* kernel/include/kernel/printk.h
 * Language: C17
 * Purpose: Early console and panic API.
 * Build: included by kernel diagnostics code.
 */
#ifndef NAVINE_KERNEL_PRINTK_H
#define NAVINE_KERNEL_PRINTK_H

#include <kernel/boot.h>
#include <kernel/types.h>

void early_console_init(const NavineBootInfo *boot_info);
void early_puts(const char *text);
void printk(const char *fmt, ...);
NAVINE_NORETURN void kernel_panic(const char *reason);

#endif
