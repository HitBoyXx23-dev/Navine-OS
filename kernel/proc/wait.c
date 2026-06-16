/* kernel/proc/wait.c
 * Language: C17 freestanding
 * Purpose: wait/waitpid scaffolding.
 */
#include <kernel/process.h>

pid_t wait_for_child(int *status) {
    if (status) {
        *status = 0;
    }
    return -1;
}
