/* kernel/proc/process.c
 * Language: C17 freestanding
 * Purpose: Static task table for early process management.
 */
#include <kernel/process.h>

#define MAX_TASKS 64u

static Task tasks[MAX_TASKS];
static Task *current_task;

Task *task_current(void) {
    return current_task;
}

Task *task_create_kernel(const char *name) {
    for (uint32_t i = 0; i < MAX_TASKS; ++i) {
        if (tasks[i].state == TASK_STOPPED) {
            tasks[i].pid = (pid_t)i + 1;
            tasks[i].state = TASK_READY;
            for (uint32_t j = 0; j < sizeof(tasks[i].name) - 1u && name && name[j]; ++j) {
                tasks[i].name[j] = name[j];
            }
            return &tasks[i];
        }
    }
    return NULL;
}

void process_table_init(void) {
    for (uint32_t i = 0; i < MAX_TASKS; ++i) {
        tasks[i].state = TASK_STOPPED;
        tasks[i].pid = 0;
    }
    current_task = &tasks[0];
    current_task->pid = 1;
    current_task->state = TASK_RUNNING;
}
