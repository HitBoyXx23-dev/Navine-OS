; Navine OS - Kernel Main Loop

[BITS 64]

%ifndef NAVINE_LINK_BUILD
extern compositor_clear
extern compositor_flip
extern compositor_mark_dirty
extern wm_render
extern wm_handle_input
extern desktop_render
extern desktop_render_overlay
extern desktop_handle_key
extern desktop_handle_mouse
extern terminal_render
extern terminal_handle_input
extern keyboard_read
extern keyboard_has_data
extern ps2_poll_all
extern doom_launch
extern doom_render
extern doom_handle_key
extern doom_handle_mouse
extern files_toggle
extern files_render
extern files_handle_key
extern files_handle_mouse
extern files_visible
extern discord_render
extern discord_handle_key
extern discord_handle_mouse
extern textviewer_render
extern textviewer_handle_mouse
extern apps_render
extern apps_handle_mouse
extern apps_handle_key
extern filetype_run
extern installer_render
extern installer_poll
extern installer_handle_mouse
extern installer_completed
extern mouse_render
extern mission_control_render
extern gamemode_render_overlay
extern devmode_render_overlay
extern net_poll
extern init_network
%endif

global kernel_main

extern kernel_late_init

section .text
kernel_main:
    mov byte [net_started], 0
.loop:
    call ps2_poll_all
    cmp byte [installer_completed], 0
    je .installer
    cmp byte [net_irq_pending], 0
    je .no_net_irq
    mov byte [net_irq_pending], 0
    call net_poll
.no_net_irq:
    call kernel_late_init
    call wm_handle_input
    call doom_handle_mouse
    call textviewer_handle_mouse
    call files_handle_mouse
    call discord_handle_mouse
    call apps_handle_mouse
    test eax, eax
    jnz .render
    call desktop_handle_mouse
.render:
    call compositor_clear
    call desktop_render
    call wm_render
    call terminal_render
    call files_render
    call textviewer_render
    call apps_render
    call discord_render
    call doom_render
    call desktop_render_overlay
    call mission_control_render
    call gamemode_render_overlay
    call devmode_render_overlay
    call mouse_render
    call compositor_mark_dirty
    call compositor_flip
    cmp byte [net_started], 0
    jne .poll_kb
    call init_network
    mov byte [net_started], 1
.poll_kb:
    call terminal_handle_input
    call poll_keyboard
    jmp .loop

.installer:
    call installer_handle_mouse
    call fb_clear_screen
    call installer_render
    call mouse_render
    call compositor_mark_dirty
    call compositor_flip
    call installer_poll
    call poll_keyboard
    jmp .loop

section .bss
net_started:   resb 1

section .text
poll_keyboard:
    call keyboard_has_data
    test rax, rax
    jz .done
    call keyboard_read
    mov dl, al
    call doom_handle_key
    test eax, eax
    jnz .done
    call apps_handle_key
    test eax, eax
    jnz .done
    call discord_handle_key
    test eax, eax
    jnz .done
    call desktop_handle_key
    call files_handle_key
.done:
    ret
