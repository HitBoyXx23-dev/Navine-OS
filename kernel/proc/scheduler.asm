; Navine OS - Process and Scheduler

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern pit_ticks
%endif

global init_proc
global init_scheduler
global scheduler_tick
global scheduler_yield
global process_create
global current_pid

section .bss
process_table:  resb MAX_PROCESSES * 128
current_process: resq 1
next_pid:       resd 1
schedule_index: resd 1

section .text
init_proc:
    mov dword [next_pid], 1
    mov qword [current_process], process_table
    mov dword [process_table], 1
    mov qword [process_table + 8], 0
    ret

init_scheduler:
    mov dword [schedule_index], 0
    ret

scheduler_tick:
    inc qword [pit_ticks]
    inc dword [schedule_index]
    ret

scheduler_yield:
    ret

process_create:
    mov eax, [next_pid]
    inc dword [next_pid]
    ret

current_pid:
    mov eax, [process_table]
    ret
