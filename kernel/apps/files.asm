; Navine OS - File Browser

[BITS 64]

global init_files
global files_toggle
global files_render
global files_handle_key
global files_handle_mouse
global files_visible

extern mouse_x
extern mouse_y
extern mouse_buttons

section .bss
files_visible:   resb 1
files_selection: resd 1
files_mouse_last: resb 1

section .text
init_files:
    mov byte [files_visible], 0
    mov dword [files_selection], 0
    mov byte [files_mouse_last], 0
    ret

files_toggle:
    xor byte [files_visible], 1
    ret

files_render:
    cmp byte [files_visible], 0
    je .done
    mov edi, 80
    mov esi, 80
    mov edx, 360
    mov ecx, 420
    mov r8d, 0xE0282828
    call fb_fill_rect
    mov edi, 96
    mov esi, 96
    lea rdx, [title_files]
    mov ecx, 0xFFFFFFFF
    call font_draw_string
    mov edi, 414
    mov esi, 96
    lea rdx, [files_close_x]
    mov ecx, 0xFFFF5F57
    call font_draw_string
    mov edi, 96
    mov esi, 130
    lea rdx, [file_1]
    call font_draw_string
    mov edi, 96
    mov esi, 150
    lea rdx, [file_2]
    call font_draw_string
    mov edi, 96
    mov esi, 170
    lea rdx, [file_3]
    call font_draw_string
    mov edi, 96
    mov esi, 190
    lea rdx, [file_4]
    call font_draw_string
    mov edi, 96
    mov esi, 210
    lea rdx, [file_5]
    call font_draw_string
    mov edi, 96
    mov esi, 230
    lea rdx, [file_6]
    call font_draw_string
    mov edi, 96
    mov esi, 250
    lea rdx, [file_7]
    call font_draw_string
    mov edi, 96
    mov esi, 270
    lea rdx, [file_8]
    call font_draw_string
    mov edi, 96
    mov esi, 290
    lea rdx, [file_9]
    call font_draw_string
    mov edi, 96
    mov esi, 310
    lea rdx, [file_10]
    call font_draw_string
    mov edi, 96
    mov esi, 340
    lea rdx, [hint_files]
    mov ecx, 0xFFAAAAAA
    call font_draw_string
.done:
    ret

files_handle_key:
    cmp byte [files_visible], 0
    je .done
    cmp dl, 0x02
    jb .done
    cmp dl, 0x0A
    jbe .digit
    cmp dl, 0x0B
    jne .done
    mov eax, 9
    jmp .open
.digit:
    movzx eax, dl
    sub eax, 0x02
.open:
    cmp eax, 9
    ja .done
    lea rdi, [file_ptrs]
    shl rax, 3
    add rdi, rax
    mov rdi, [rdi]
    call filetype_run
    mov byte [files_visible], 0
.done:
    ret

files_handle_mouse:
    cmp byte [files_visible], 0
    je .done
    mov al, [mouse_buttons]
    mov bl, [files_mouse_last]
    mov [files_mouse_last], al
    test al, 1
    jz .done
    test bl, 1
    jnz .done
    mov eax, [mouse_x]
    cmp eax, 408
    jl .maybe_file
    cmp eax, 432
    jg .maybe_file
    mov eax, [mouse_y]
    cmp eax, 90
    jl .maybe_file
    cmp eax, 118
    jg .maybe_file
    mov byte [files_visible], 0
    jmp .done
.maybe_file:
    mov eax, [mouse_x]
    cmp eax, 80
    jl .done
    cmp eax, 440
    jg .done
    mov eax, [mouse_y]
    cmp eax, 126
    jl .done
    cmp eax, 324
    jg .done
    sub eax, 126
    xor edx, edx
    mov ecx, 20
    div ecx
    cmp eax, 9
    ja .done
    lea rdi, [file_ptrs]
    shl rax, 3
    add rdi, rax
    mov rdi, [rdi]
    call filetype_run
    mov byte [files_visible], 0
.done:
    ret

section .rodata
title_files: db "Navine Vault", 0
files_close_x: db "X", 0
hint_files:  db "Press 1-0 to open, F8 to close", 0
file_1:  db "1 Welcome Note", 0
file_2:  db "2 Team Memo", 0
file_3:  db "3 Workspace Config", 0
file_4:  db "4 Portal Page", 0
file_5:  db "5 Automation Script", 0
file_6:  db "6 Navine Grid", 0
file_7:  db "7 Aurora Theme", 0
file_8:  db "8 Insight Plugin", 0
file_9:  db "9 Navine App", 0
file_10: db "0 Archive Bundle", 0

file_name_1:  db "readme.txt", 0
file_name_2:  db "hello.txt", 0
file_name_3:  db "config.json", 0
file_name_4:  db "page.html", 0
file_name_5:  db "script.sh", 0
file_name_6:  db "doom1.wad", 0
file_name_7:  db "default.navinetheme", 0
file_name_8:  db "sample.nplugin", 0
file_name_9:  db "app.navapp", 0
file_name_10: db "archive.zip", 0

file_ptrs:
    dq file_name_1, file_name_2, file_name_3, file_name_4, file_name_5
    dq file_name_6, file_name_7, file_name_8, file_name_9, file_name_10
