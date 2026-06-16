/* kernel/proc/scheduler.c
 * Language: C17 freestanding
 * Purpose: Minimal round-robin scheduler interface.
 */
#include <kernel/process.h>

static uint64_t ticks;

extern void process_table_init(void);

void scheduler_init(void) {
    ticks = 0;
    process_table_init();
}

void scheduler_tick(void) {
    ++ticks;
    Task *task = task_current();
    if (task) {
        ++task->cpu_time_ns;
        ++task->vruntime;
    }
}

void scheduler_yield(void) {
    __asm__ volatile("" ::: "memory");
}
