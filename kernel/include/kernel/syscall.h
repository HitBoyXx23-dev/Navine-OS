/* kernel/include/kernel/syscall.h
 * Language: C17
 * Purpose: System call numbers and dispatch declaration.
 * Build: included by syscall_entry.asm and syscall.c.
 */
#ifndef NAVINE_KERNEL_SYSCALL_H
#define NAVINE_KERNEL_SYSCALL_H

#include <kernel/types.h>

#define SYS_EXIT 1ull
#define SYS_READ 3ull
#define SYS_WRITE 4ull
#define SYS_OPEN 5ull
#define SYS_CLOSE 6ull
#define SYS_NAVINE_GUI 0x1000ull
#define SYS_NAVINE_IPC 0x1001ull

uint64_t syscall_dispatch(uint64_t num, uint64_t a0, uint64_t a1,
                          uint64_t a2, uint64_t a3, uint64_t a4,
                          uint64_t a5);

#endif
