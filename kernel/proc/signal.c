/* kernel/proc/signal.c
 * Language: C17 freestanding
 * Purpose: Early signal delivery placeholders.
 */
#include <kernel/process.h>

int signal_send(Task *task, int signal) {
    if (!task || signal <= 0) {
        return -1;
    }
    if (signal == 9) {
        task->state = TASK_ZOMBIE;
    }
    return 0;
}
