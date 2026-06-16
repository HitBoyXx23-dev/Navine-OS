/* kernel/proc/syscall.c
 * Language: C17 freestanding
 * Purpose: Syscall dispatch table for the future userspace ABI.
 */
#include <kernel/syscall.h>
#include <kernel/process.h>

uint64_t syscall_dispatch(uint64_t num, uint64_t a0, uint64_t a1,
                          uint64_t a2, uint64_t a3, uint64_t a4,
                          uint64_t a5) {
    (void)a0;
    (void)a1;
    (void)a2;
    (void)a3;
    (void)a4;
    (void)a5;
    switch (num) {
    case SYS_EXIT:
        if (task_current()) {
            task_current()->state = TASK_ZOMBIE;
        }
        return 0;
    case SYS_READ:
    case SYS_WRITE:
    case SYS_OPEN:
    case SYS_CLOSE:
        return (uint64_t)-38;
    case SYS_NAVINE_GUI:
    case SYS_NAVINE_IPC:
        return 0;
    default:
        return (uint64_t)-38;
    }
}
