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
global scheduler_set_game_boost
global scheduler_set_priority
global process_exit

section .bss
process_table:  resb MAX_PROCESSES * 128
current_process: resq 1
current_slot:   resd 1
next_pid:       resd 1
schedule_index: resd 1
scheduler_game_boost: resb 1
saved_rsp:      resq 1

section .text
init_proc:
    mov dword [next_pid], 1
    mov dword [current_slot], 0
    lea rax, [process_table]
    mov [current_process], rax
    mov dword [process_table], 1
    mov qword [process_table + 8], PROC_KERNEL_STACK + PROC_STACK_SIZE
    mov dword [process_table + 16], 10
    mov byte [process_table + 24], 1
    lea rax, [process_table + 128]
    mov dword [rax], 2
    mov qword [rax + 8], PROC_USER_STACK_BASE + PROC_STACK_SIZE
    mov dword [rax + 16], 5
    mov byte [rax + 24], 1
    ret

init_scheduler:
    mov dword [schedule_index], 0
    mov byte [scheduler_game_boost], 0
    ret

scheduler_set_game_boost:
    mov [scheduler_game_boost], al
    ret

scheduler_set_priority:
    mov ecx, edi
    imul rcx, 128
    add rcx, process_table
    mov [rcx + 16], esi
    ret

scheduler_tick:
    cmp byte [scheduler_game_boost], 0
    je .normal
    add qword [pit_ticks], 2
    inc dword [schedule_index]
    jmp .maybe_switch
.normal:
    inc qword [pit_ticks]
    inc dword [schedule_index]
.maybe_switch:
    mov eax, [schedule_index]
    and eax, 127
    cmp eax, 0
    jne .out
    call scheduler_yield
.out:
    ret

scheduler_switch:
    mov eax, [current_slot]
    inc eax
    cmp eax, MAX_PROCESSES
    jge .wrap
    jmp .try
.wrap:
    xor eax, eax
.try:
    imul rcx, rax, 128
    lea rdx, [process_table + rcx]
    cmp byte [rdx + 24], 0
    je .next
    mov [current_slot], eax
    mov [current_process], rdx
    mov eax, [rdx]
    ret
.next:
    inc eax
    cmp eax, MAX_PROCESSES
    jl .try
    xor eax, eax
    ret

scheduler_yield:
    call scheduler_switch
    ret

process_create:
    mov eax, [next_pid]
    inc dword [next_pid]
    ret

current_pid:
    mov rax, [current_process]
    mov eax, [rax]
    ret

process_exit:
    mov rax, [current_process]
    mov byte [rax + 24], 0
    call scheduler_switch
    ret
