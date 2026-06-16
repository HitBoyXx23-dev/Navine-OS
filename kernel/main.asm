; Navine OS - Kernel Main Loop

[BITS 64]

%ifndef NAVINE_LINK_BUILD
extern compositor_clear
extern compositor_flip
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
extern doom_launch
extern doom_render
extern doom_handle_key
extern doom_handle_mouse
extern files_toggle
extern files_render
extern files_handle_key
extern files_handle_mouse
extern files_visible
extern textviewer_render
extern textviewer_handle_mouse
extern apps_render
extern apps_handle_mouse
extern apps_handle_key
extern filetype_run
extern installer_render
extern installer_poll
extern installer_handle_mouse
extern installer_mark_dirty
extern installer_completed
extern init_mouse
extern mouse_render
extern mouse_poll
%endif

global kernel_main

section .bss
desktop_drawn: resb 1
mouse_started: resb 1

section .text
kernel_main:
    mov byte [desktop_drawn], 0
    mov byte [mouse_started], 0
.loop:
    cmp byte [mouse_started], 1
    je .mouse_ready
    call init_mouse
    mov byte [mouse_started], 1
.mouse_ready:
    call mouse_poll
    cmp byte [installer_completed], 0
    jne .desktop
    call installer_handle_mouse
    call installer_render
    call mouse_render
    call compositor_flip
    call installer_poll
    jmp .loop

.desktop:
    call wm_handle_input
    call doom_handle_mouse
    call textviewer_handle_mouse
    call files_handle_mouse
    call apps_handle_mouse
    test eax, eax
    jnz .desktop_render_frame
    call desktop_handle_mouse
.desktop_render_frame:
    call compositor_clear
    call desktop_render
    call wm_render
    call terminal_render
    call files_render
    call textviewer_render
    call apps_render
    call doom_render
    call desktop_render_overlay
    call mouse_render
    call compositor_flip
.desktop_input:
    call terminal_handle_input
    jmp .desktop

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
    call desktop_handle_key
    call files_handle_key
.done:
    ret
