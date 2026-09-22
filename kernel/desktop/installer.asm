; Navine OS - Graphical Installer

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern font_draw_string
extern keyboard_read
extern mouse_x
extern mouse_y
extern mouse_buttons
extern fb_width
extern fb_height
extern ata_read_sectors
extern ata_write_sectors
extern wallpaper_draw
extern compat_set_profile
extern gamemode_enable
extern devmode_enable
extern kernel_services_init
%endif

global init_installer
global installer_load_disk_flag
global installer_render
global installer_poll
global installer_handle_mouse
global installer_mark_dirty
global installer_completed
global install_mode
global install_focus
global install_user
global install_username
global install_user_len

section .bss
installer_completed:    resb 1
installer_phase:        resb 1
install_mode:           resb 1
install_focus:          resb 1
install_user:           resb 1
install_user_len:       resb 1
install_pass_len:       resb 1
installer_auth_field:   resb 1
installer_show_pass:    resb 1
installer_remember:     resb 1
installer_dirty:        resb 1
installer_key_ext:      resb 1
installer_mouse_last:   resb 1
install_username:       resb 16
install_password:       resb 16
install_password_mask:  resb 16
install_sector_buf:     resb 512

section .text
init_installer:
    mov byte [installer_phase], 0
    mov byte [installer_completed], 0
    mov byte [install_mode], INSTALL_MODE_HYBRID
    mov byte [install_focus], 2
    mov byte [install_user], 1
    mov byte [install_user_len], 0
    mov byte [install_pass_len], 0
    mov byte [installer_auth_field], 0
    mov byte [installer_show_pass], 0
    mov byte [installer_remember], 1
    lea rdi, [install_username]
    xor eax, eax
    mov ecx, 16
    rep stosb
    lea rdi, [install_password]
    xor eax, eax
    mov ecx, 16
    rep stosb
    lea rdi, [install_password_mask]
    xor eax, eax
    mov ecx, 16
    rep stosb
    mov byte [installer_dirty], 1
    mov byte [installer_key_ext], 0
    mov byte [installer_mouse_last], 0
    ret

installer_load_disk_flag:
    mov rdi, INSTALL_FLAG_SECTOR
    lea rsi, [install_sector_buf]
    mov rdx, 1
    call ata_read_sectors
    lea rax, [install_sector_buf]
    cmp dword [rax], INSTALL_MAGIC
    jne .done
    cmp byte [rax + 4], 1
    jne .done
    mov byte [installer_completed], 1
    mov cl, [rax + 5]
    and cl, 3
    mov [install_mode], cl
    mov cl, [rax + 6]
    and cl, 3
    mov [install_focus], cl
    mov cl, [rax + 7]
    and cl, 3
    mov [install_user], cl
    mov cl, [rax + 8]
    cmp cl, 15
    jbe .len_ok
    mov cl, 15
.len_ok:
    mov [install_user_len], cl
    lea rsi, [rax + 9]
    lea rdi, [install_username]
    movzx ecx, cl
    rep movsb
    mov byte [rdi], 0
    mov rcx, INSTALL_FLAG_PHYS
    mov edx, [rax]
    mov [rcx], edx
    mov edx, [rax + 4]
    mov [rcx + 4], edx
.done:
    ret

installer_save_disk_flag:
    lea rdi, [install_sector_buf]
    xor rax, rax
    mov ecx, 512
    rep stosb
    lea rdi, [install_sector_buf]
    mov dword [rdi], INSTALL_MAGIC
    mov byte [rdi + 4], 1
    mov al, [install_mode]
    mov [rdi + 5], al
    mov al, [install_focus]
    mov [rdi + 6], al
    mov al, [install_user]
    mov [rdi + 7], al
    mov al, [install_user_len]
    mov [rdi + 8], al
    lea rsi, [install_username]
    lea rdi, [install_sector_buf + 9]
    mov ecx, 16
    rep movsb
    lea rdi, [install_sector_buf]
    mov rcx, INSTALL_FLAG_PHYS
    mov eax, [rdi]
    mov [rcx], eax
    mov eax, [rdi + 4]
    mov [rcx + 4], eax
    mov rdi, INSTALL_FLAG_SECTOR
    lea rsi, [install_sector_buf]
    mov rdx, 1
    call ata_write_sectors
    ret

installer_render:
    cmp byte [installer_completed], 1
    je .done
    call render_installer_page
.done:
    ret

render_installer_page:
    mov edi, 20
    mov esi, 20
    lea rdx, [prompt_title]
    mov ecx, COLOR_WHITE
    call font_draw_string
    call wallpaper_draw
    mov eax, [fb_width]
    cmp eax, 620
    jb installer_compact
    mov eax, [fb_height]
    cmp eax, 460
    jb installer_compact
    cmp byte [installer_phase], 0
    je render_prompt_installer_page
    cmp byte [installer_phase], 1
    je render_prompt_focus_page
    jmp render_navine_auth_page

render_prompt_installer_page:
    mov eax, [fb_width]
    sub eax, 880
    shr eax, 1
    mov r12d, eax
    mov eax, [fb_height]
    sub eax, 560
    shr eax, 1
    mov r13d, eax

    mov edi, r12d
    mov esi, r13d
    mov edx, 880
    mov ecx, 560
    mov r8d, 0xF0121624
    call fb_fill_rect
    mov edi, r12d
    mov esi, r13d
    mov edx, 880
    mov ecx, 74
    mov r8d, 0xEE1B2436
    call fb_fill_rect
    mov edi, r12d
    mov esi, r13d
    mov edx, 8
    mov ecx, 560
    mov r8d, 0xFF65D6FF
    call fb_fill_rect

    mov edi, r12d
    add edi, 32
    mov esi, r13d
    add esi, 22
    lea rdx, [prompt_title]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 32
    mov esi, r13d
    add esi, 104
    lea rdx, [prompt_subtitle]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov esi, r13d
    add esi, 154
    xor ebx, ebx
.prompt_loop:
    cmp bl, 4
    jge .prompt_apps
    mov edi, r12d
    add edi, 42
    mov edx, 360
    mov ecx, 58
    cmp bl, [install_mode]
    jne .prompt_dim_box
    mov r8d, 0xFF183B55
    jmp .prompt_box
.prompt_dim_box:
    mov r8d, 0xCC0D1117
.prompt_box:
    call fb_fill_rect
    mov edi, r12d
    add edi, 62
    add esi, 18
    movzx eax, bl
    mov rdx, [prompt_mode_ptrs + rax * 8]
    cmp bl, [install_mode]
    jne .prompt_dim_text
    mov ecx, 0xFF65D6FF
    jmp .prompt_text
.prompt_dim_text:
    mov ecx, 0xFFDFE7EF
.prompt_text:
    call font_draw_string
    sub esi, 18
    add esi, 74
    inc bl
    jmp .prompt_loop
.prompt_apps:
    mov edi, r12d
    add edi, 470
    mov esi, r13d
    add esi, 154
    lea rdx, [prompt_apps_title]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 470
    mov esi, r13d
    add esi, 194
    lea rdx, [prompt_apps_1]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 470
    mov esi, r13d
    add esi, 228
    lea rdx, [prompt_apps_2]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 470
    mov esi, r13d
    add esi, 262
    lea rdx, [prompt_apps_3]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 470
    mov esi, r13d
    add esi, 296
    lea rdx, [prompt_apps_4]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 470
    mov esi, r13d
    add esi, 356
    lea rdx, [prompt_hint]
    mov ecx, 0xFFDFE7EF
    call font_draw_string
    mov edi, r12d
    add edi, 626
    mov esi, r13d
    add esi, 448
    mov edx, 190
    mov ecx, 48
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
    mov edi, r12d
    add edi, 654
    mov esi, r13d
    add esi, 464
    lea rdx, [prompt_continue]
    mov ecx, 0xFF101624
    call font_draw_string
    ret

render_prompt_focus_page:
    mov eax, [fb_width]
    sub eax, 620
    shr eax, 1
    mov r12d, eax
    mov eax, [fb_height]
    sub eax, 440
    shr eax, 1
    mov r13d, eax

    mov edi, r12d
    mov esi, r13d
    mov edx, 620
    mov ecx, 440
    mov r8d, 0xEE111820
    call fb_fill_rect
    mov edi, r12d
    mov esi, r13d
    mov edx, 620
    mov ecx, 72
    mov r8d, 0xFF0B6FD3
    call fb_fill_rect
    mov edi, r12d
    mov esi, r13d
    mov edx, 10
    mov ecx, 440
    mov r8d, 0xFF00D7FF
    call fb_fill_rect

    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 20
    lea rdx, [title_setup]
    mov ecx, COLOR_WHITE
    call font_draw_string

    movzx eax, byte [installer_phase]
    cmp al, 1
    je .focus_text
    cmp al, 2
    je .account_text
    lea rdx, [subtitle_desktop]
    lea r14, [mode_ptrs]
    lea r15, [install_mode]
    lea rbx, [label_mode]
    jmp .draw_text
.focus_text:
    lea rdx, [subtitle_focus]
    lea r14, [focus_ptrs]
    lea r15, [install_focus]
    lea rbx, [label_focus]
    jmp .draw_text
.account_text:
    lea rdx, [subtitle_account]
    lea r14, [user_ptrs]
    lea r15, [install_user]
    lea rbx, [label_account]
.draw_text:
    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 94
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 136
    mov rdx, rbx
    mov ecx, COLOR_WHITE
    call font_draw_string

    mov esi, r13d
    add esi, 184
    xor ebx, ebx
.opt:
    cmp bl, 4
    jge .options_done
    mov edi, r12d
    add edi, 44
    movzx eax, bl
    mov rdx, [r14 + rax * 8]
    cmp bl, [r15]
    je .sel
    mov ecx, 0xFFB8B8B8
    jmp .draw_opt
.sel:
    mov ecx, COLOR_NAVINE_BLUE
.draw_opt:
    call font_draw_string
    add esi, 40
    inc bl
    jmp .opt

.options_done:
    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 360
    lea rdx, [hint_keys]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 360
    mov edx, 250
    mov ecx, 46
    mov r8d, 0xFF0B6FD3
    call fb_fill_rect
    mov edi, r12d
    add edi, 48
    mov esi, r13d
    add esi, 376
    cmp byte [installer_phase], 2
    je .finish_btn
    lea rdx, [btn_next]
    jmp .btn
.finish_btn:
    lea rdx, [btn_finish]
.btn:
    mov ecx, COLOR_WHITE
    call font_draw_string
    cmp byte [installer_phase], 2
    jne .no_name
    mov edi, r12d
    add edi, 310
    mov esi, r13d
    add esi, 376
    lea rdx, [install_username]
    cmp byte [install_user_len], 0
    jne .draw_name
    lea rdx, [username_empty]
.draw_name:
    mov ecx, 0xFFB8D7F0
    call font_draw_string
.no_name:
    ret

installer_compact:
    mov edi, 12
    mov esi, 12
    lea rdx, [title_setup]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 12
    mov esi, 40
    lea rdx, [compact_hint]
    mov ecx, COLOR_NAVINE_BLUE
    call font_draw_string
    ret

render_navine_auth_page:
    mov eax, [fb_width]
    sub eax, 760
    shr eax, 1
    mov r12d, eax
    mov eax, [fb_height]
    sub eax, 480
    shr eax, 1
    mov r13d, eax

    mov edi, r12d
    mov esi, r13d
    mov edx, 760
    mov ecx, 480
    mov r8d, 0xF0121624
    call fb_fill_rect
    mov edi, r12d
    mov esi, r13d
    mov edx, 220
    mov ecx, 480
    mov r8d, 0xE71B2436
    call fb_fill_rect
    mov edi, r12d
    add edi, 220
    mov esi, r13d
    mov edx, 3
    mov ecx, 480
    mov r8d, 0xFF65D6FF
    call fb_fill_rect

    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 26
    lea rdx, [auth_header]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 62
    lea rdx, [auth_tagline]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov edi, r12d
    add edi, 56
    mov esi, r13d
    add esi, 130
    mov edx, 96
    mov ecx, 96
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
    mov edi, r12d
    add edi, 72
    mov esi, r13d
    add esi, 170
    lea rdx, [auth_avatar]
    mov ecx, 0xFF101624
    call font_draw_string

    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 282
    lea rdx, [auth_secure_label]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 28
    mov esi, r13d
    add esi, 316
    lea rdx, [auth_workspace_label]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 42
    lea rdx, [auth_title]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 78
    lea rdx, [auth_subtitle]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 126
    lea rdx, [auth_username_label]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 154
    mov edx, 420
    mov ecx, 46
    cmp byte [installer_auth_field], 0
    jne .user_idle
    mov r8d, 0xFF18263A
    jmp .user_box
.user_idle:
    mov r8d, 0xFF0D1117
.user_box:
    call fb_fill_rect
    mov edi, r12d
    add edi, 278
    mov esi, r13d
    add esi, 170
    lea rdx, [install_username]
    cmp byte [install_user_len], 0
    jne .draw_auth_name
    lea rdx, [auth_username_placeholder]
.draw_auth_name:
    mov ecx, 0xFFDFE7EF
    call font_draw_string
    cmp byte [installer_auth_field], 0
    jne .no_user_caret
    movzx eax, byte [install_user_len]
    imul eax, 7
    mov edi, r12d
    add edi, 278
    add edi, eax
    mov esi, r13d
    add esi, 166
    mov edx, 2
    mov ecx, 22
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
.no_user_caret:

    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 226
    lea rdx, [auth_password_label]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 254
    mov edx, 420
    mov ecx, 46
    cmp byte [installer_auth_field], 1
    jne .pass_idle
    mov r8d, 0xFF18263A
    jmp .pass_box
.pass_idle:
    mov r8d, 0xFF0D1117
.pass_box:
    call fb_fill_rect
    mov edi, r12d
    add edi, 278
    mov esi, r13d
    add esi, 270
    lea rdx, [install_password_mask]
    cmp byte [install_pass_len], 0
    jne .draw_auth_pass
    lea rdx, [auth_password_placeholder]
.draw_auth_pass:
    mov ecx, 0xFFDFE7EF
    call font_draw_string
    cmp byte [installer_auth_field], 1
    jne .no_pass_caret
    movzx eax, byte [install_pass_len]
    imul eax, 7
    mov edi, r12d
    add edi, 278
    add edi, eax
    mov esi, r13d
    add esi, 266
    mov edx, 2
    mov ecx, 22
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
.no_pass_caret:

    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 318
    lea rdx, [auth_show_off]
    cmp byte [installer_show_pass], 0
    je .show_label_ready
    lea rdx, [auth_show_on]
.show_label_ready:
    cmp byte [installer_auth_field], 2
    jne .show_dim
    mov ecx, 0xFF65D6FF
    jmp .show_draw
.show_dim:
    mov ecx, 0xFFB8D7F0
.show_draw:
    call font_draw_string

    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 352
    lea rdx, [auth_remember_on]
    cmp byte [installer_remember], 1
    je .remember_label_ready
    lea rdx, [auth_remember_off]
.remember_label_ready:
    cmp byte [installer_auth_field], 3
    jne .remember_dim
    mov ecx, 0xFF65D6FF
    jmp .remember_draw
.remember_dim:
    mov ecx, 0xFFB8D7F0
.remember_draw:
    call font_draw_string

    mov edi, r12d
    add edi, 260
    mov esi, r13d
    add esi, 386
    lea rdx, [auth_hint]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 490
    mov esi, r13d
    add esi, 386
    mov edx, 220
    mov ecx, 48
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
    mov edi, r12d
    add edi, 510
    mov esi, r13d
    add esi, 402
    lea rdx, [auth_login_button]
    mov ecx, 0xFF101624
    call font_draw_string
    ret

installer_poll:
    cmp byte [installer_completed], 1
    je .done
    call keyboard_read
    test al, al
    jz .done
    cmp al, 0xE0
    je .key_ext
    cmp byte [installer_key_ext], 1
    je .extended_key
    cmp byte [installer_phase], 2
    je .auth_only
    cmp al, 0x02
    je .set0
    cmp al, 0x03
    je .set1
    cmp al, 0x04
    je .set2
    cmp al, 0x05
    je .set3
    cmp al, 0x1C
    je .enter
    cmp byte [installer_phase], 2
    je .account_key
    jmp .done
.auth_only:
    cmp al, 0x0F
    je .tab_field
    cmp al, 0x39
    je .space_auth
    cmp al, 0x1C
    je .enter
    jmp .account_key
.key_ext:
    mov byte [installer_key_ext], 1
    jmp .done
.extended_key:
    mov byte [installer_key_ext], 0
    cmp al, 0x48
    je .arrow_up
    cmp al, 0x50
    je .arrow_down
    jmp .done
.arrow_up:
    call installer_selected_ptr
    cmp byte [rax], 0
    je .wrap3
    dec byte [rax]
    jmp .dirty
.arrow_down:
    call installer_selected_ptr
    cmp byte [rax], 3
    je .wrap0
    inc byte [rax]
    jmp .dirty
.wrap3:
    mov byte [rax], 3
    jmp .dirty
.wrap0:
    mov byte [rax], 0
    jmp .dirty
.set0:
    xor bl, bl
    jmp .setn
.set1:
    mov bl, 1
    jmp .setn
.set2:
    mov bl, 2
    jmp .setn
.set3:
    mov bl, 3
.setn:
    call installer_selected_ptr
    mov [rax], bl
    jmp .dirty
.account_key:
    cmp al, 0x0E
    je .backspace
    cmp byte [installer_auth_field], 1
    ja .done
    call installer_scancode_ascii
    test al, al
    jz .done
    cmp byte [installer_auth_field], 1
    je .password_key
    movzx ecx, byte [install_user_len]
    cmp ecx, 15
    jae .done
    lea rdi, [install_username]
    add rdi, rcx
    mov [rdi], al
    inc byte [install_user_len]
    mov byte [rdi + 1], 0
    jmp .dirty
.password_key:
    movzx ecx, byte [install_pass_len]
    cmp ecx, 15
    jae .done
    lea rdi, [install_password]
    add rdi, rcx
    mov [rdi], al
    lea rdi, [install_password_mask]
    add rdi, rcx
    mov byte [rdi], 'x'
    cmp byte [installer_show_pass], 0
    je .pass_mask_ready
    mov [rdi], al
.pass_mask_ready:
    inc byte [install_pass_len]
    mov byte [rdi + 1], 0
    jmp .dirty
.backspace:
    cmp byte [installer_auth_field], 1
    je .password_backspace
    movzx ecx, byte [install_user_len]
    test ecx, ecx
    jz .done
    dec ecx
    mov [install_user_len], cl
    lea rdi, [install_username]
    mov byte [rdi + rcx], 0
    jmp .dirty
.password_backspace:
    movzx ecx, byte [install_pass_len]
    test ecx, ecx
    jz .done
    dec ecx
    mov [install_pass_len], cl
    lea rdi, [install_password]
    mov byte [rdi + rcx], 0
    lea rdi, [install_password_mask]
    mov byte [rdi + rcx], 0
    jmp .dirty
.enter:
    cmp byte [installer_phase], 0
    je .prompt_done
    cmp byte [installer_phase], 2
    je .finish
    inc byte [installer_phase]
    jmp .dirty
.prompt_done:
    mov byte [installer_phase], 1
    jmp .dirty
.tab_field:
    inc byte [installer_auth_field]
    cmp byte [installer_auth_field], 4
    jb .dirty
    mov byte [installer_auth_field], 0
    jmp .dirty
.space_auth:
    cmp byte [installer_auth_field], 2
    je .toggle_show
    cmp byte [installer_auth_field], 3
    je .toggle_remember
    jmp .account_key
.toggle_show:
    xor byte [installer_show_pass], 1
    call installer_refresh_password_mask
    jmp .dirty
.toggle_remember:
    xor byte [installer_remember], 1
    jmp .dirty
.finish:
    call installer_try_finish
    jmp .done
.dirty:
    mov byte [installer_dirty], 1
.done:
    ret

installer_handle_mouse:
    cmp byte [installer_completed], 1
    je .done
    mov al, [mouse_buttons]
    mov bl, [installer_mouse_last]
    mov [installer_mouse_last], al
    test al, 1
    jz .done
    test bl, 1
    jnz .done
    cmp byte [installer_phase], 0
    je .prompt_mouse
    cmp byte [installer_phase], 1
    je .focus_mouse
    jmp .auth_mouse

.prompt_mouse:
    call installer_prompt_base
    mov eax, [mouse_x]
    cmp eax, r10d
    jl .done
    mov ecx, r10d
    add ecx, 880
    cmp eax, ecx
    jg .done
    mov eax, [mouse_y]
    cmp eax, r11d
    jl .done
    mov ecx, r11d
    add ecx, 560
    cmp eax, ecx
    jg .done
    call installer_prompt_continue_hit
    test eax, eax
    jnz .prompt_continue
    call installer_prompt_option_hit
    cmp eax, 4
    jae .done
    mov [install_mode], al
    jmp .dirty
.prompt_continue:
    mov byte [installer_phase], 1
    jmp .dirty

.focus_mouse:
    call installer_focus_base
    call installer_focus_continue_hit
    test eax, eax
    jnz .focus_continue
    call installer_focus_option_hit
    cmp eax, 4
    jae .done
    mov [install_focus], al
    jmp .dirty
.focus_continue:
    mov byte [installer_phase], 2
    mov byte [installer_auth_field], 0
    jmp .dirty

.auth_mouse:
    call installer_auth_base
    mov eax, [mouse_x]
    cmp eax, r10d
    jl .done
    mov ecx, r10d
    add ecx, 760
    cmp eax, ecx
    jg .done
    mov eax, [mouse_y]
    cmp eax, r11d
    jl .done
    mov ecx, r11d
    add ecx, 480
    cmp eax, ecx
    jg .done
    call installer_auth_hit
    cmp eax, 0
    je .auth_user
    cmp eax, 1
    je .auth_pass
    cmp eax, 2
    je .auth_show
    cmp eax, 3
    je .auth_remember
    cmp eax, 4
    je .auth_signin
    jmp .done
.auth_user:
    mov byte [installer_auth_field], 0
    jmp .dirty
.auth_pass:
    mov byte [installer_auth_field], 1
    jmp .dirty
.auth_show:
    mov byte [installer_auth_field], 2
    xor byte [installer_show_pass], 1
    call installer_refresh_password_mask
    jmp .dirty
.auth_remember:
    mov byte [installer_auth_field], 3
    xor byte [installer_remember], 1
    jmp .dirty
.auth_signin:
    call installer_try_finish
    jmp .done
.dirty:
    mov byte [installer_dirty], 1
.done:
    ret

installer_prompt_base:
    mov eax, [fb_width]
    sub eax, 880
    shr eax, 1
    mov r10d, eax
    mov eax, [fb_height]
    sub eax, 560
    shr eax, 1
    mov r11d, eax
    ret

installer_focus_base:
    mov eax, [fb_width]
    sub eax, 620
    shr eax, 1
    mov r10d, eax
    mov eax, [fb_height]
    sub eax, 440
    shr eax, 1
    mov r11d, eax
    ret

installer_auth_base:
    mov eax, [fb_width]
    sub eax, 760
    shr eax, 1
    mov r10d, eax
    mov eax, [fb_height]
    sub eax, 480
    shr eax, 1
    mov r11d, eax
    ret

installer_prompt_continue_hit:
    mov eax, [mouse_x]
    mov ecx, r10d
    add ecx, 626
    cmp eax, ecx
    jl .miss
    add ecx, 190
    cmp eax, ecx
    jg .miss
    mov eax, [mouse_y]
    mov ecx, r11d
    add ecx, 448
    cmp eax, ecx
    jl .miss
    add ecx, 48
    cmp eax, ecx
    jg .miss
    mov eax, 1
    ret
.miss:
    xor eax, eax
    ret

installer_prompt_option_hit:
    mov eax, [mouse_x]
    mov ecx, r10d
    add ecx, 42
    cmp eax, ecx
    jl .miss
    add ecx, 360
    cmp eax, ecx
    jg .miss
    mov eax, [mouse_y]
    mov ecx, r11d
    add ecx, 154
    cmp eax, ecx
    jl .opt1
    mov edx, ecx
    add edx, 58
    cmp eax, edx
    jle .hit0
.opt1:
    mov ecx, r11d
    add ecx, 228
    cmp eax, ecx
    jl .opt2
    mov edx, ecx
    add edx, 58
    cmp eax, edx
    jle .hit1
.opt2:
    mov ecx, r11d
    add ecx, 302
    cmp eax, ecx
    jl .opt3
    mov edx, ecx
    add edx, 58
    cmp eax, edx
    jle .hit2
.opt3:
    mov ecx, r11d
    add ecx, 376
    cmp eax, ecx
    jl .miss
    mov edx, ecx
    add edx, 58
    cmp eax, edx
    jle .hit3
.miss:
    mov eax, 4
    ret
.hit0:
    xor eax, eax
    ret
.hit1:
    mov eax, 1
    ret
.hit2:
    mov eax, 2
    ret
.hit3:
    mov eax, 3
    ret

installer_focus_continue_hit:
    mov eax, [mouse_x]
    mov ecx, r10d
    add ecx, 28
    cmp eax, ecx
    jl .miss
    add ecx, 250
    cmp eax, ecx
    jg .miss
    mov eax, [mouse_y]
    mov ecx, r11d
    add ecx, 360
    cmp eax, ecx
    jl .miss
    add ecx, 46
    cmp eax, ecx
    jg .miss
    mov eax, 1
    ret
.miss:
    xor eax, eax
    ret

installer_focus_option_hit:
    mov eax, [mouse_x]
    mov ecx, r10d
    add ecx, 44
    cmp eax, ecx
    jl .miss
    mov ecx, r10d
    add ecx, 360
    cmp eax, ecx
    jg .miss
    mov eax, [mouse_y]
    mov ecx, r11d
    add ecx, 184
    cmp eax, ecx
    jl .row1
    mov edx, ecx
    add edx, 24
    cmp eax, edx
    jle .hit0
.row1:
    mov ecx, r11d
    add ecx, 216
    cmp eax, ecx
    jl .row2
    mov edx, ecx
    add edx, 24
    cmp eax, edx
    jle .hit1
.row2:
    mov ecx, r11d
    add ecx, 248
    cmp eax, ecx
    jl .row3
    mov edx, ecx
    add edx, 24
    cmp eax, edx
    jle .hit2
.row3:
    mov ecx, r11d
    add ecx, 280
    cmp eax, ecx
    jl .miss
    mov edx, ecx
    add edx, 24
    cmp eax, edx
    jle .hit3
.miss:
    mov eax, 4
    ret
.hit0:
    xor eax, eax
    ret
.hit1:
    mov eax, 1
    ret
.hit2:
    mov eax, 2
    ret
.hit3:
    mov eax, 3
    ret

installer_auth_hit:
    mov eax, [mouse_x]
    mov ecx, r10d
    add ecx, 260
    cmp eax, ecx
    jl .check_button
    mov edx, ecx
    add edx, 420
    cmp eax, edx
    jg .check_button
    mov eax, [mouse_y]
    mov ecx, r11d
    add ecx, 154
    cmp eax, ecx
    jl .pass_box
    mov edx, ecx
    add edx, 46
    cmp eax, edx
    jle .hit_user
.pass_box:
    mov ecx, r11d
    add ecx, 254
    cmp eax, ecx
    jl .show_row
    mov edx, ecx
    add edx, 46
    cmp eax, edx
    jle .hit_pass
.show_row:
    mov ecx, r11d
    add ecx, 312
    cmp eax, ecx
    jl .remember_row
    mov edx, ecx
    add edx, 28
    cmp eax, edx
    jle .hit_show
.remember_row:
    mov ecx, r11d
    add ecx, 346
    cmp eax, ecx
    jl .check_button
    mov edx, ecx
    add edx, 28
    cmp eax, edx
    jle .hit_remember
.check_button:
    mov eax, [mouse_x]
    mov ecx, r10d
    add ecx, 490
    cmp eax, ecx
    jl .miss
    add ecx, 220
    cmp eax, ecx
    jg .miss
    mov eax, [mouse_y]
    mov ecx, r11d
    add ecx, 386
    cmp eax, ecx
    jl .miss
    add ecx, 48
    cmp eax, ecx
    jg .miss
    mov eax, 4
    ret
.hit_user:
    xor eax, eax
    ret
.hit_pass:
    mov eax, 1
    ret
.hit_show:
    mov eax, 2
    ret
.hit_remember:
    mov eax, 3
    ret
.miss:
    mov eax, 255
    ret

installer_try_finish:
    cmp byte [install_user_len], 0
    jne .user_ok
    mov byte [installer_auth_field], 0
    mov byte [installer_dirty], 1
    ret
.user_ok:
    cmp byte [install_pass_len], 0
    jne .pass_ok
    mov byte [installer_auth_field], 1
    mov byte [installer_dirty], 1
    ret
.pass_ok:
    call kernel_services_init
    call installer_save_disk_flag
    call navinefs_format
    call installer_apply_profiles
    mov byte [installer_completed], 1
    mov byte [installer_dirty], 1
    ret

installer_apply_profiles:
    movzx eax, byte [install_mode]
    mov al, al
    call compat_set_profile
    cmp byte [install_mode], INSTALL_MODE_HYBRID
    je .hybrid
    cmp byte [install_mode], INSTALL_MODE_LINUX
    je .dev_only
    cmp byte [install_focus], 0
    jne .out
    call gamemode_enable
    jmp .out
.hybrid:
    call gamemode_enable
    call devmode_enable
    jmp .out
.dev_only:
    call devmode_enable
.out:
    ret

installer_selected_ptr:
    cmp byte [installer_phase], 1
    je installer_selected_focus
    cmp byte [installer_phase], 2
    je installer_selected_user
    lea rax, [install_mode]
    ret

installer_selected_focus:
    lea rax, [install_focus]
    ret

installer_selected_user:
    lea rax, [install_user]
    ret

installer_scancode_ascii:
    cmp al, 0x02
    jb .letters
    cmp al, 0x0B
    ja .letters
    movzx eax, al
    mov al, [installer_num_map + rax - 0x02]
    ret
.letters:
    cmp al, 0x10
    jb .punct
    cmp al, 0x32
    ja .punct
    movzx eax, al
    mov al, [installer_key_map + rax - 0x10]
    ret
.punct:
    cmp al, 0x0C
    je .minus
    cmp al, 0x0D
    je .equals
    cmp al, 0x33
    je .comma
    cmp al, 0x34
    je .dot
    cmp al, 0x35
    je .slash
    cmp al, 0x39
    je .space
.none:
    xor eax, eax
    ret
.minus:
    mov al, '-'
    ret
.equals:
    mov al, '='
    ret
.comma:
    mov al, ','
    ret
.dot:
    mov al, '.'
    ret
.slash:
    mov al, '/'
    ret
.space:
    mov al, ' '
    ret

installer_mark_dirty:
    mov byte [installer_dirty], 1
    ret

installer_refresh_password_mask:
    push rsi
    push rdi
    lea rsi, [install_password]
    lea rdi, [install_password_mask]
    movzx ecx, byte [install_pass_len]
    test ecx, ecx
    jz .zero
.loop:
    mov al, [rsi]
    cmp byte [installer_show_pass], 0
    jne .copy
    mov al, 'x'
.copy:
    mov [rdi], al
    inc rsi
    inc rdi
    loop .loop
.zero:
    mov byte [rdi], 0
    pop rdi
    pop rsi
    ret

section .rodata
title_setup:       db "Navine OS", 0
subtitle_desktop:  db "Prepare your workspace.", 0
subtitle_focus:    db "Choose an optimization profile.", 0
subtitle_account:  db "Secure sign in.", 0
label_mode:        db "Workspace:", 0
label_focus:       db "Launch set:", 0
label_account:     db "Identity:", 0
mode_mac:          db "1. macOS Style", 0
mode_linux:        db "2. Linux Style", 0
mode_win:          db "3. Windows Style", 0
mode_hybrid:       db "4. Hybrid Style", 0
focus_game:        db "1. Gaming", 0
focus_prod:        db "2. Productivity", 0
focus_code:        db "3. Development", 0
focus_create:      db "4. Creative", 0
user_player:       db "1. User", 0
user_builder:      db "2. User", 0
user_creator:      db "3. User", 0
user_guest:        db "4. User", 0
username_empty:    db "Username", 0
auth_header:       db "Navine OS", 0
auth_tagline:      db "Enterprise workspace", 0
auth_avatar:       db "NV", 0
auth_secure_label: db "Encrypted local profile", 0
auth_workspace_label: db "Navine workspace ready", 0
auth_title:        db "Secure sign in", 0
auth_subtitle:     db "Authenticate to open your Navine OS workspace.", 0
auth_username_label: db "Username", 0
auth_username_placeholder: db "enter username", 0
auth_password_label: db "Password", 0
auth_password_placeholder: db "enter password", 0
auth_hint:         db "Tab fields. Enter signs in.", 0
auth_login_button: db "Secure Sign In", 0
auth_show_off:     db "Show password: off", 0
auth_show_on:      db "Show password: on", 0
auth_remember_off: db "Remember me: off", 0
auth_remember_on:  db "Remember me: on", 0
prompt_title:      db "Navine OS Prompt Installer", 0
prompt_subtitle:   db "Select a workspace mode. Core apps stay available in every mode.", 0
prompt_mode_1:     db "1  macOS Style", 0
prompt_mode_2:     db "2  Linux Style", 0
prompt_mode_3:     db "3  Windows Style", 0
prompt_mode_4:     db "4  Hybrid Style", 0
prompt_apps_title: db "Core apps included", 0
prompt_apps_1:     db "Settings  Vault  Console  Browser", 0
prompt_apps_2:     db "Store  Notes  Calculator  Media", 0
prompt_apps_3:     db "Monitor  Assistant  Editor", 0
prompt_apps_4:     db "Plugin Manager  Developer Studio  Navine Grid", 0
prompt_hint:       db "Use arrows or 1-4. Enter continues to secure sign in.", 0
prompt_continue:   db "Continue", 0
linux_header:      db "Navine OS", 0
linux_tty:         db "Navine workspace", 0
linux_avatar:      db "NV", 0
linux_shell_label: db "Protected profile", 0
linux_home_label:  db "Workspace: ", 0
linux_default_user: db "user", 0
linux_create_title: db "Secure sign in", 0
linux_create_subtitle: db "Authenticate to open your Navine OS workspace.", 0
linux_login_label: db "Username", 0
linux_name_placeholder: db "enter username", 0
linux_role_label: db "Password", 0
linux_hint:        db "Tab switches fields. Enter signs in.", 0
linux_login_button: db "Secure Sign In", 0
linux_user_player:  db "", 0
linux_user_builder: db "", 0
linux_user_creator: db "", 0
linux_user_guest:   db "", 0
mode_ptrs:
    dq mode_mac, mode_linux, mode_win, mode_hybrid
prompt_mode_ptrs:
    dq prompt_mode_1, prompt_mode_2, prompt_mode_3, prompt_mode_4
focus_ptrs:
    dq focus_game, focus_prod, focus_code, focus_create
user_ptrs:
    dq user_player, user_builder, user_creator, user_guest
linux_user_ptrs:
    dq linux_user_player, linux_user_builder, linux_user_creator, linux_user_guest
hint_keys:         db "Use arrows or 1-4, Enter to continue", 0
btn_next:          db "Continue", 0
btn_finish:        db "Create Account", 0
compact_hint:      db "Use 1-4 and Enter to install.", 0
installer_num_map: db "1234567890"
installer_key_map:
    db "qwertyuiop", 0, 0, 0, 0, "asdfghjkl", 0, 0, 0, 0, 0, "zxcvbnm"
