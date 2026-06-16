; Navine OS - Desktop Environment (Dock, Menu Bar, Spotlight)

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern font_draw_string
extern pit_ticks
extern install_mode
extern install_focus
extern install_user
extern install_username
extern install_user_len
extern mouse_x
extern mouse_y
extern mouse_buttons
extern windows
extern files_toggle
extern cppapp_launch
extern doom_launch
extern terminal_write
extern app_open_settings
extern app_open_browser
extern app_open_store
extern app_open_notes
extern app_open_calc
extern app_open_monitor
extern app_open_assistant
extern app_open_editor
extern app_open_plugins
extern app_open_studio
%endif

global init_desktop
global desktop_render
global desktop_render_overlay
global desktop_handle_key
global desktop_handle_mouse
global desktop_toggle_spotlight

section .bss
current_space:  resd 1
dock_visible:   resb 1
spotlight_open: resb 1
desktop_mouse_last: resb 1
clock_buf:      resb 6

%ifndef NAVINE_LINK_BUILD
extern fb_width
%endif

section .text
init_desktop:
    mov dword [current_space], 0
    mov byte [dock_visible], 1
    mov byte [spotlight_open], 0
    mov byte [desktop_mouse_last], 0
    mov dword [clock_buf], "00:0"
    mov word [clock_buf + 4], "0"
    ret

desktop_render:
    movzx eax, byte [install_mode]
    cmp al, 1
    je render_linux_desktop
    cmp al, 2
    je render_windows_desktop
    cmp al, 3
    je render_hybrid_desktop
    call render_menubar
    call render_core_apps
    call render_desktop_apps
    call render_dock
    cmp byte [spotlight_open], 1
    jne .done
    call render_spotlight
.done:
    ret

render_linux_desktop:
    call render_linux_panel
    call render_linux_launcher
    call render_core_apps
    call render_desktop_apps
    cmp byte [spotlight_open], 1
    jne .done
    call render_spotlight
.done:
    ret

render_windows_desktop:
    call render_desktop_apps
    call render_core_apps
    call render_windows_taskbar
    cmp byte [spotlight_open], 1
    jne .done
    call render_windows_search
.done:
    ret

render_hybrid_desktop:
    call render_menubar
    call render_core_apps
    call render_desktop_apps
    call render_windows_taskbar
    call render_dock
    cmp byte [spotlight_open], 1
    jne .done
    call render_spotlight
.done:
    ret

desktop_render_overlay:
    cmp byte [spotlight_open], 1
    jne .done
    call render_spotlight
.done:
    ret

render_menubar:
    mov edi, 0
    mov esi, 0
    mov edx, [fb_width]
    mov ecx, 34
    mov r8d, 0xE8171D28
    call fb_fill_rect
    mov edi, 0
    mov esi, 34
    mov edx, [fb_width]
    mov ecx, 2
    mov r8d, 0xAA65D6FF
    call fb_fill_rect
    mov edi, 16
    mov esi, 10
    call user_label_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 124
    mov esi, 10
    lea rdx, [menu_file]
    mov ecx, 0xFFDFE7EF
    call font_draw_string
    mov edi, 176
    mov esi, 10
    lea rdx, [menu_edit]
    mov ecx, 0xFFDFE7EF
    call font_draw_string
    mov edi, 230
    mov esi, 10
    lea rdx, [menu_view]
    mov ecx, 0xFFDFE7EF
    call font_draw_string
    mov eax, [fb_width]
    sub eax, 270
    cmp eax, 140
    jae .clock_ok
    mov eax, 140
.clock_ok:
    push rax
    call update_clock
    pop rax
    mov edi, eax
    mov esi, 10
    lea rdx, [status_left]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov eax, [fb_width]
    sub eax, 84
    mov edi, eax
    mov esi, 10
    lea rdx, [clock_buf]
    mov ecx, COLOR_WHITE
    call font_draw_string
    ret

render_dock:
    cmp byte [dock_visible], 0
    je .out
    push rbx
    mov eax, [fb_width]
    cmp eax, 820
    jae .dock_wide
    sub eax, 20
    jmp .dock_w_ok
.dock_wide:
    mov eax, 780
.dock_w_ok:
    mov edx, eax
    mov eax, [fb_width]
    sub eax, edx
    shr eax, 1
    mov ebx, eax
    mov edi, eax
    mov eax, [fb_height]
    cmp eax, 56
    jb .dock_top
    sub eax, 112
    jmp .dock_y_ok
.dock_top:
    xor eax, eax
.dock_y_ok:
    mov esi, eax
    push rsi
    mov ecx, 78
    mov r8d, 0xD8141A24
    call fb_fill_rect
    pop rsi
    mov edi, ebx
    add edi, 10
    add esi, 8
    mov edx, 760
    mov ecx, 2
    mov r8d, 0x8865D6FF
    call fb_fill_rect
    mov edi, ebx
    add edi, 20
    mov esi, [fb_height]
    sub esi, 100
    mov edx, 76
    mov ecx, 54
    mov r8d, 0xFF177DDC
    call fb_fill_rect
    mov edi, ebx
    add edi, 120
    mov esi, [fb_height]
    sub esi, 100
    mov edx, 76
    mov ecx, 54
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, ebx
    add edi, 220
    mov esi, [fb_height]
    sub esi, 100
    mov edx, 76
    mov ecx, 54
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, ebx
    add edi, 320
    mov esi, [fb_height]
    sub esi, 100
    mov edx, 96
    mov ecx, 54
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, ebx
    add edi, 430
    mov esi, [fb_height]
    sub esi, 100
    mov edx, 96
    mov ecx, 54
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, ebx
    add edi, 48
    mov esi, [fb_height]
    sub esi, 94
    lea rdx, [icon_console]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 148
    mov esi, [fb_height]
    sub esi, 94
    lea rdx, [icon_vault]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 248
    mov esi, [fb_height]
    sub esi, 94
    lea rdx, [icon_settings]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 354
    mov esi, [fb_height]
    sub esi, 94
    lea rdx, [icon_focus1]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 466
    mov esi, [fb_height]
    sub esi, 94
    lea rdx, [icon_focus2]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 32
    mov esi, [fb_height]
    sub esi, 62
    lea rdx, [dock_terminal]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 137
    mov esi, [fb_height]
    sub esi, 62
    lea rdx, [dock_files]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 230
    mov esi, [fb_height]
    sub esi, 62
    lea rdx, [dock_settings]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 350
    mov esi, [fb_height]
    sub esi, 62
    call focus_app1_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 460
    mov esi, [fb_height]
    sub esi, 62
    call focus_app2_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop rbx
.out:
    ret

render_core_apps:
    push rbx
    mov eax, [fb_width]
    cmp eax, 900
    jb .small
    mov ebx, 86
    jmp .x_ready
.small:
    mov ebx, 16
.x_ready:
    mov eax, [install_mode]
    cmp al, 1
    je .linux_y
    cmp al, 2
    je .windows_y
    cmp al, 3
    je .hybrid_y
    mov esi, 58
    mov r8d, 0xB8171D28
    jmp .draw_bg
.linux_y:
    mov esi, 58
    mov r8d, 0xC0182024
    jmp .draw_bg
.windows_y:
    mov esi, 46
    mov r8d, 0xD0101824
    jmp .draw_bg
.hybrid_y:
    mov esi, 56
    mov r8d, 0xCC121A28
.draw_bg:
    mov edi, ebx
    mov edx, 560
    mov ecx, 56
    call fb_fill_rect
    mov edi, ebx
    add edi, 8
    add esi, 6
    mov edx, 544
    mov ecx, 2
    mov r8d, 0x6665D6FF
    call fb_fill_rect
    mov eax, [install_mode]
    cmp al, 2
    je .win_text_y
    mov esi, 78
    jmp .text_y_ready
.win_text_y:
    mov esi, 66
.text_y_ready:
    mov edi, ebx
    add edi, 12
    lea rdx, [core_settings]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    add edi, 96
    push rsi
    lea rdx, [core_browser]
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop rsi
    mov edi, ebx
    add edi, 180
    push rsi
    lea rdx, [core_store]
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop rsi
    mov edi, ebx
    add edi, 250
    push rsi
    lea rdx, [app_prod1]
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop rsi
    mov edi, ebx
    add edi, 320
    push rsi
    lea rdx, [app_prod2]
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop rsi
    mov edi, ebx
    add edi, 390
    push rsi
    lea rdx, [app_game1]
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop rsi
    mov edi, ebx
    add edi, 460
    lea rdx, [dock_terminal]
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop rbx
    ret

render_spotlight:
    push r12
    push r13
    push r14
    mov eax, [fb_width]
    cmp eax, 760
    jae .spot_wide
    sub eax, 20
    jmp .spot_w_ok
.spot_wide:
    mov eax, 720
.spot_w_ok:
    mov r14d, eax
    mov eax, [fb_width]
    sub eax, r14d
    shr eax, 1
    mov r12d, eax
    mov eax, [fb_height]
    cmp eax, 360
    jae .spot_mid
    mov eax, 24
    jmp .spot_y_ok
.spot_mid:
    sub eax, 300
    shr eax, 1
.spot_y_ok:
    mov r13d, eax
    mov edi, r12d
    mov esi, r13d
    mov edx, r14d
    mov ecx, 300
    mov r8d, 0xF0111820
    call fb_fill_rect

    mov edi, r12d
    add edi, 18
    mov esi, r13d
    add esi, 18
    lea rdx, [spotlight_prompt]
    mov ecx, COLOR_WHITE
    call font_draw_string

    mov edi, r12d
    add edi, 16
    mov esi, r13d
    add esi, 58
    mov edx, r14d
    sub edx, 32
    mov ecx, 2
    mov r8d, 0xFF0B6FD3
    call fb_fill_rect

    mov edi, r12d
    add edi, 34
    mov esi, r13d
    add esi, 88
    lea rdx, [spotlight_line1]
    mov ecx, COLOR_WHITE
    call font_draw_string

    mov edi, r12d
    add edi, 34
    mov esi, r13d
    add esi, 122
    lea rdx, [spotlight_line2]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov edi, r12d
    add edi, 34
    mov esi, r13d
    add esi, 156
    lea rdx, [spotlight_line3]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov edi, r12d
    add edi, 34
    mov esi, r13d
    add esi, 190
    lea rdx, [spotlight_line5a]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov edi, r12d
    add edi, 98
    mov esi, r13d
    add esi, 190
    call focus_app1_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string

    mov edi, r12d
    add edi, 34
    mov esi, r13d
    add esi, 224
    lea rdx, [spotlight_line6a]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov edi, r12d
    add edi, 98
    mov esi, r13d
    add esi, 224
    call focus_app2_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop r14
    pop r13
    pop r12
    ret

render_desktop_apps:
    push rbx
    mov ebx, [fb_width]
    sub ebx, 150
    mov edi, ebx
    mov esi, 86
    mov edx, 112
    mov ecx, 42
    mov r8d, 0xCC111820
    call fb_fill_rect
    mov edi, ebx
    add edi, 12
    mov esi, 100
    call focus_app1_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    mov esi, 144
    mov edx, 112
    mov ecx, 42
    mov r8d, 0xCC111820
    call fb_fill_rect
    mov edi, ebx
    add edi, 12
    mov esi, 158
    call focus_app2_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, ebx
    mov esi, 202
    mov edx, 112
    mov ecx, 42
    mov r8d, 0xCC111820
    call fb_fill_rect
    mov edi, ebx
    add edi, 12
    mov esi, 216
    call focus_app3_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    pop rbx
    ret

focus_app1_ptr:
    movzx eax, byte [install_focus]
    cmp al, 0
    je .game
    cmp al, 1
    je .prod
    cmp al, 3
    je .creative
    lea rdx, [app_code1]
    ret
.game:
    lea rdx, [app_game1]
    ret
.prod:
    lea rdx, [app_prod1]
    ret
.creative:
    lea rdx, [app_creative1]
    ret

focus_app2_ptr:
    movzx eax, byte [install_focus]
    cmp al, 0
    je .game
    cmp al, 1
    je .prod
    cmp al, 3
    je .creative
    lea rdx, [app_code2]
    ret
.game:
    lea rdx, [app_game2]
    ret
.prod:
    lea rdx, [app_prod2]
    ret
.creative:
    lea rdx, [app_creative2]
    ret

focus_app3_ptr:
    movzx eax, byte [install_focus]
    cmp al, 0
    je .game
    cmp al, 1
    je .prod
    cmp al, 3
    je .creative
    lea rdx, [app_code3]
    ret
.game:
    lea rdx, [app_game3]
    ret
.prod:
    lea rdx, [app_prod3]
    ret
.creative:
    lea rdx, [app_creative3]
    ret

user_label_ptr:
    cmp byte [install_user_len], 0
    je .profile
    lea rdx, [install_username]
    ret
.profile:
    movzx eax, byte [install_user]
    cmp al, 0
    je .player
    cmp al, 1
    je .builder
    cmp al, 2
    je .creator
    lea rdx, [user_guest_label]
    ret
.player:
    lea rdx, [user_player_label]
    ret
.builder:
    lea rdx, [user_builder_label]
    ret
.creator:
    lea rdx, [user_creator_label]
    ret

desktop_handle_key:
    cmp byte [spotlight_open], 1
    jne .normal
    cmp dl, 0x02
    je .spot_terminal
    cmp dl, 0x03
    je .files
    cmp dl, 0x04
    je .system
    cmp dl, 0x05
    je .spot_focus_one
    cmp dl, 0x06
    je .spot_focus_two
.normal:
    cmp dl, 0x42
    je .files
    cmp dl, 0x3F
    je .system
    cmp dl, 0x43
    je .doom
    cmp dl, 0x39
    jne .done
    call desktop_toggle_spotlight
    mov eax, 1
    ret
.spot_terminal:
    mov byte [windows + 20], 1
    mov byte [spotlight_open], 0
    mov eax, 1
    ret
.spot_focus_one:
    call desktop_focus_one_action
    mov byte [spotlight_open], 0
    mov eax, 1
    ret
.spot_focus_two:
    call desktop_focus_two_action
    mov byte [spotlight_open], 0
    mov eax, 1
    ret
.files:
    call files_toggle
    mov byte [spotlight_open], 0
    mov eax, 1
    ret
.system:
    call app_open_settings
    mov byte [spotlight_open], 0
    mov eax, 1
    ret
.doom:
    call doom_launch
    mov byte [spotlight_open], 0
    mov eax, 1
    ret
.done:
    xor eax, eax
    ret

desktop_handle_mouse:
    mov al, [mouse_buttons]
    mov bl, [desktop_mouse_last]
    mov [desktop_mouse_last], al
    test al, 1
    jz .done
    test bl, 1
    jnz .done
    mov eax, [mouse_y]
    cmp eax, 28
    jl .menubar_click
    cmp byte [install_mode], 2
    jne .not_windows_bar
    mov ecx, [fb_height]
    sub ecx, 66
    cmp eax, ecx
    jge .windows_bar_click
.not_windows_bar:
    cmp eax, 46
    jl .dock_check
    cmp eax, 114
    jl .core_apps_click
    mov eax, [mouse_x]
    mov ecx, [fb_width]
    sub ecx, 150
    cmp eax, ecx
    jl .dock_check
    mov eax, [mouse_y]
    cmp eax, 86
    jl .dock_check
    cmp eax, 128
    jl .focus_one
    cmp eax, 144
    jl .dock_check
    cmp eax, 186
    jl .focus_two
    cmp eax, 202
    jl .dock_check
    cmp eax, 244
    jl .focus_three
    jmp .dock_check
.menubar_click:
    mov eax, [mouse_x]
    cmp eax, 86
    jl .done
    cmp eax, 124
    jl .open_files
    cmp eax, 168
    jl .open_system
    jmp .done
.windows_bar_click:
    mov eax, [mouse_x]
    cmp eax, 18
    jl .done
    cmp eax, 126
    jl .open_files
    cmp eax, 148
    jl .done
    cmp eax, 578
    jl .desktop_search_click
    cmp eax, 604
    jl .done
    cmp eax, 690
    jl .open_terminal
    cmp eax, 704
    jl .done
    cmp eax, 780
    jl .focus_one
    jmp .done
.desktop_search_click:
    call desktop_toggle_spotlight
    jmp .done
.core_apps_click:
    mov eax, [fb_width]
    cmp eax, 900
    jb .core_small
    mov edx, 86
    jmp .core_base_ready
.core_small:
    mov edx, 16
.core_base_ready:
    mov ecx, [mouse_x]
    sub ecx, edx
    cmp ecx, 0
    jl .done
    cmp ecx, 84
    jl .open_system
    cmp ecx, 168
    jl .browser_msg
    cmp ecx, 238
    jl .store_msg
    cmp ecx, 308
    jl .notes_msg
    cmp ecx, 378
    jl .calc_msg
    cmp ecx, 448
    jl .open_game
    cmp ecx, 548
    jl .open_terminal
    jmp .done
.dock_check:
    mov eax, [mouse_y]
    mov ecx, [fb_height]
    sub ecx, 112
    cmp eax, ecx
    jl .done
    mov eax, [fb_width]
    cmp eax, 820
    jae .wide
    sub eax, 20
    jmp .dock_w
.wide:
    mov eax, 780
.dock_w:
    mov edx, eax
    mov eax, [fb_width]
    sub eax, edx
    shr eax, 1
    mov ecx, [mouse_x]
    sub ecx, eax
    cmp ecx, 20
    jl .done
    cmp ecx, 90
    jl .open_terminal
    cmp ecx, 120
    jl .done
    cmp ecx, 190
    jl .open_files
    cmp ecx, 220
    jl .done
    cmp ecx, 290
    jl .open_system
    cmp ecx, 320
    jl .done
    cmp ecx, 410
    jl .focus_one
    cmp ecx, 430
    jl .done
    cmp ecx, 520
    jl .focus_two
    jmp .done
.open_terminal:
    mov byte [windows + 20], 1
    jmp .done
.open_files:
    call files_toggle
    jmp .done
.open_system:
    call app_open_settings
    jmp .done
.open_game:
    call doom_launch
    jmp .done
.browser_msg:
    call app_open_browser
    jmp .done
.store_msg:
    call app_open_store
    jmp .done
.notes_msg:
    call app_open_notes
    jmp .done
.calc_msg:
    call app_open_calc
    jmp .done
.focus_one:
    call desktop_focus_one_action
    jmp .done
.focus_two:
    call desktop_focus_two_action
    jmp .done
.focus_three:
    call desktop_focus_three_action
    jmp .done
.done:
    ret

desktop_focus_one_action:
    cmp byte [install_focus], 0
    je .run_doom
    cmp byte [install_focus], 1
    je .open_files
    cmp byte [install_focus], 2
    je .code_msg
    call app_open_studio
    ret
.open_files:
    call files_toggle
    ret
.run_doom:
    call doom_launch
    ret
.code_msg:
    call app_open_editor
    ret

desktop_focus_two_action:
    cmp byte [install_focus], 0
    je .fps_msg
    cmp byte [install_focus], 1
    je .prod_msg
    cmp byte [install_focus], 2
    je .system_msg
    call app_open_assistant
    ret
.fps_msg:
    call app_open_monitor
    ret
.prod_msg:
    call app_open_notes
    ret
.system_msg:
    call app_open_monitor
    ret

desktop_focus_three_action:
    cmp byte [install_focus], 0
    je .perf
    cmp byte [install_focus], 1
    je .prod
    cmp byte [install_focus], 2
    je .shell
    call app_open_studio
    ret
.perf:
    call app_open_monitor
    ret
.prod:
    call app_open_calc
    ret
.shell:
    mov byte [windows + 20], 1
    ret

update_clock:
    mov al, 0x04
    out 0x70, al
    in al, 0x71
    call bcd_to_ascii_pair
    mov [clock_buf], ah
    mov [clock_buf + 1], al
    mov byte [clock_buf + 2], ':'
    mov al, 0x02
    out 0x70, al
    in al, 0x71
    call bcd_to_ascii_pair
    mov [clock_buf + 3], ah
    mov [clock_buf + 4], al
    mov byte [clock_buf + 5], 0
    ret

bcd_to_ascii_pair:
    mov ah, al
    and al, 0x0F
    add al, '0'
    shr ah, 4
    and ah, 0x0F
    add ah, '0'
    ret

render_linux_panel:
    mov edi, 0
    mov esi, 0
    mov edx, [fb_width]
    mov ecx, 40
    mov r8d, 0xF014191F
    call fb_fill_rect
    mov edi, 0
    mov esi, 40
    mov edx, [fb_width]
    mov ecx, 2
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
    mov edi, 18
    mov esi, 13
    lea rdx, [linux_apps]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 142
    mov esi, 13
    lea rdx, [linux_places]
    mov ecx, 0xFFDFE7EF
    call font_draw_string
    mov edi, 274
    mov esi, 13
    lea rdx, [linux_terminal]
    mov ecx, 0xFFDFE7EF
    call font_draw_string
    mov eax, [fb_width]
    sub eax, 198
    mov edi, eax
    mov esi, 13
    lea rdx, [linux_status]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov eax, [fb_width]
    sub eax, 58
    mov edi, eax
    mov esi, 13
    call update_clock
    lea rdx, [clock_buf]
    mov ecx, COLOR_WHITE
    call font_draw_string
    ret

render_linux_launcher:
    mov edi, 0
    mov esi, 42
    mov edx, 76
    mov ecx, [fb_height]
    sub ecx, 42
    mov r8d, 0xE010151C
    call fb_fill_rect
    mov edi, 76
    mov esi, 42
    mov edx, 2
    mov ecx, [fb_height]
    sub ecx, 42
    mov r8d, 0x5565D6FF
    call fb_fill_rect
    mov edi, 12
    mov esi, 70
    mov edx, 52
    mov ecx, 44
    mov r8d, 0xFF0B6FD3
    call fb_fill_rect
    mov edi, 22
    mov esi, 84
    lea rdx, [dock_terminal]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 12
    mov esi, 132
    mov edx, 52
    mov ecx, 44
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, 23
    mov esi, 146
    lea rdx, [dock_files]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 12
    mov esi, 194
    mov edx, 52
    mov ecx, 44
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, 17
    mov esi, 208
    lea rdx, [app_game1]
    mov ecx, COLOR_WHITE
    call font_draw_string
    ret

render_windows_taskbar:
    mov eax, [fb_height]
    sub eax, 66
    mov edi, 0
    mov esi, eax
    mov edx, [fb_width]
    mov ecx, 66
    mov r8d, 0xF0121722
    call fb_fill_rect
    mov eax, [fb_height]
    sub eax, 54
    mov edi, 18
    mov esi, eax
    mov edx, 108
    mov ecx, 42
    mov r8d, 0xFF177DDC
    call fb_fill_rect
    mov edi, 42
    mov esi, [fb_height]
    sub esi, 40
    lea rdx, [win_start]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 148
    mov esi, [fb_height]
    sub esi, 54
    mov edx, 430
    mov ecx, 42
    mov r8d, 0xFF202A36
    call fb_fill_rect
    mov edi, 170
    mov esi, [fb_height]
    sub esi, 40
    lea rdx, [win_search]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, 604
    mov esi, [fb_height]
    sub esi, 54
    mov edx, 86
    mov ecx, 42
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, 626
    mov esi, [fb_height]
    sub esi, 40
    lea rdx, [dock_terminal]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 704
    mov esi, [fb_height]
    sub esi, 54
    mov edx, 76
    mov ecx, 42
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, 722
    mov esi, [fb_height]
    sub esi, 40
    lea rdx, [app_game1]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov eax, [fb_width]
    sub eax, 180
    mov edi, eax
    mov esi, [fb_height]
    sub esi, 40
    lea rdx, [win_status]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov eax, [fb_width]
    sub eax, 68
    mov edi, eax
    mov esi, [fb_height]
    sub esi, 40
    call update_clock
    lea rdx, [clock_buf]
    mov ecx, COLOR_WHITE
    call font_draw_string
    ret

render_windows_search:
    mov eax, [fb_height]
    sub eax, 340
    mov edi, 126
    mov esi, eax
    mov edx, 560
    mov ecx, 280
    mov r8d, 0xF018202C
    call fb_fill_rect
    mov edi, 152
    add esi, 26
    lea rdx, [win_search_panel]
    mov ecx, COLOR_WHITE
    call font_draw_string
    ret

desktop_toggle_spotlight:
    xor byte [spotlight_open], 1
    ret

section .rodata
menu_navine:      db "Navine", 0
menu_file:        db "File", 0
menu_edit:        db "Edit", 0
menu_view:        db "View", 0
menu_clock:       db "12:00", 0
dock_terminal:    db "Console", 0
dock_files:       db "Vault", 0
dock_settings:    db "Settings", 0
icon_console:     db "CN", 0
icon_vault:       db "VA", 0
icon_settings:    db "ST", 0
icon_focus1:      db "A1", 0
icon_focus2:      db "A2", 0
status_left:      db "secure  audio  net", 0
user_player_label:  db "Navine OS", 0
user_builder_label: db "Navine OS", 0
user_creator_label: db "Navine OS", 0
user_guest_label:   db "Navine OS", 0
app_game1:       db "Game", 0
app_game2:       db "Pulse", 0
app_game3:       db "Metrics", 0
app_prod1:       db "Notes", 0
app_prod2:       db "Cal", 0
app_prod3:       db "Tasks", 0
app_code1:       db "Code", 0
app_code2:       db "Build", 0
app_code3:       db "Console", 0
app_creative1:   db "Photos", 0
app_creative2:   db "Music", 0
app_creative3:   db "Studio", 0
spotlight_prompt: db "Navine Search  Type 1-5 to launch", 0
spotlight_line1:  db "1  Console", 0
spotlight_line2:  db "2  Vault", 0
spotlight_line3:  db "3  Control Center", 0
spotlight_line5a: db "4  ", 0
spotlight_line6a: db "5  ", 0
linux_apps:       db "Launcher", 0
linux_places:     db "Workspace", 0
linux_terminal:   db "Console", 0
linux_status:     db "secure  audio", 0
core_settings:    db "Settings", 0
core_browser:     db "Browser", 0
core_store:       db "Store", 0
msg_fps:          db 10, "Pulse monitor enabled. Performance mode active.", 10, 0
msg_tasks:        db 10, "Tasks opened. Productivity profile active.", 10, 0
msg_code:         db 10, "Development tools ready.", 10, 0
msg_creative:     db 10, "Creative studio opened.", 10, 0
msg_music:        db 10, "Music workspace opened.", 10, 0
msg_perf:         db 10, "Performance monitor: frame pacing stable.", 10, 0
msg_calendar:     db 10, "Calendar opened. Tasks and reminders ready.", 10, 0
msg_studio:       db 10, "Studio tools opened.", 10, 0
msg_browser:      db 10, "Browser ready. Network services are staged.", 10, 0
msg_store:        db 10, "Store opened. Plugin catalog loaded.", 10, 0
msg_notes:        db 10, "Notes opened. Local workspace ready.", 10, 0
msg_calc:         db 10, "Calculator ready. Type expressions in Console.", 10, 0
win_start:        db "Navine", 0
win_search:       db "Search Navine OS", 0
win_status:       db "net audio", 0
win_search_panel: db "Search apps, settings, vault", 0
