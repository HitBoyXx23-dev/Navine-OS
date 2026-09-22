; Navine OS - CLI edition main loop

[BITS 64]

%ifndef NAVINE_LINK_BUILD
extern fb_clear_screen
extern fb_fill_rect
extern fb_width
extern fb_height
extern terminal_render_cli
extern terminal_handle_input
extern ps2_poll_all
extern init_network
extern net_poll
extern kernel_services_init
%endif

global kernel_main

section .text
kernel_main:
    call kernel_services_init
    mov byte [net_started], 0
.loop:
    call ps2_poll_all
    cmp byte [net_irq_pending], 0
    je .no_net
    mov byte [net_irq_pending], 0
    call net_poll
.no_net:
    call fb_clear_screen
    call terminal_render_cli
    call terminal_handle_input
    cmp byte [net_started], 0
    jne .loop
    call init_network
    mov byte [net_started], 1
    jmp .loop

section .bss
net_started: resb 1
