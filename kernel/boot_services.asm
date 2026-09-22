; Navine OS - Core services (init on demand before installer finish)

[BITS 64]

global kernel_services_init

%ifndef NAVINE_LINK_BUILD
extern init_pmm
extern init_vmm
extern init_heap
extern init_ata
extern init_proc
extern init_scheduler
extern init_pit
extern init_vfs
extern init_navinefs
extern config_load
extern pic_unmask_timer
%endif

section .bss
services_init_done: resb 1

section .text
kernel_services_init:
    cmp byte [services_init_done], 1
    je .done
    call init_pmm
    call init_vmm
    call init_heap
    call init_ata
    call init_proc
    call init_scheduler
    call init_pit
    call init_vfs
    call init_navinefs
    call config_load
    call pic_unmask_timer
    mov byte [services_init_done], 1
.done:
    ret
