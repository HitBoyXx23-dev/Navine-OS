/* kernel/include/kernel/process.h
 * Language: C17
 * Purpose: Process, task, and scheduler public types.
 * Build: included by process and syscall code.
 */
#ifndef NAVINE_KERNEL_PROCESS_H
#define NAVINE_KERNEL_PROCESS_H

#include <kernel/types.h>

typedef enum {
    TASK_RUNNING,
    TASK_READY,
    TASK_BLOCKED,
    TASK_ZOMBIE,
    TASK_STOPPED
} TaskState;

typedef struct NAVINE_PACKED {
    uint64_t r15, r14, r13, r12, rbx, rbp;
    uint64_t rip, rsp, rflags;
} CpuContext;

typedef struct Task {
    pid_t pid;
    pid_t ppid;
    pid_t pgid;
    pid_t sid;
    char name[256];
    TaskState state;
    uint64_t *pml4;
    CpuContext ctx;
    uint64_t kernel_stack;
    uint64_t user_stack_top;
    uint64_t heap_start;
    uint64_t heap_end;
    int exit_code;
    uid_t uid, euid, suid;
    gid_t gid, egid, sgid;
    uint64_t cpu_time_ns;
    int nice;
    uint64_t vruntime;
    uint64_t sleep_until;
    struct Task *parent;
    struct Task *next_sibling;
    struct Task *first_child;
    struct Task *sched_next;
} Task;

void scheduler_init(void);
void scheduler_tick(void);
void scheduler_yield(void);
Task *task_current(void);

#endif
