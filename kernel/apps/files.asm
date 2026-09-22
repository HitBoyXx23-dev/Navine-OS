; Navine OS - File Browser

[BITS 64]

%include "constants.inc"

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
files_count:     resd 1
files_names:     resb 640

section .text
init_files:
    mov byte [files_visible], 0
    mov dword [files_selection], 0
    mov byte [files_mouse_last], 0
    call files_refresh
    ret

files_refresh:
    xor ebx, ebx
    mov dword [files_count], 0
    lea rdi, [files_names]
.clear:
    cmp ebx, 10
    jae .scan
    mov byte [rdi], 0
    add rdi, 64
    inc ebx
    jmp .clear
.scan:
    xor ebx, ebx
.loop:
    mov esi, ebx
    call navinefs_list_entry
    test rax, rax
    jz .next
    mov ecx, [files_count]
    cmp ecx, 10
    jae .done
    imul rdx, rcx, 64
    lea rdi, [files_names + rdx]
    mov byte [rdi], '1'
    add rdi, 2
    lea rsi, [rax]
.copy:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .next_entry
    inc rsi
    inc rdi
    jmp .copy
.next_entry:
    inc dword [files_count]
.next:
    inc ebx
    cmp ebx, NAVINEFS_MAX_INODES
    jb .loop
.done:
    ret

files_toggle:
    xor byte [files_visible], 1
    ret

files_render:
    cmp byte [files_visible], 0
    je .done
    call files_refresh
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
    xor ebx, ebx
.floop:
    cmp ebx, [files_count]
    jae .fend
    imul eax, ebx, 64
    lea rdx, [files_names + rax]
    call font_draw_string
    add esi, 20
    inc ebx
    jmp .floop
.fend:
    cmp dword [files_count], 0
    jne .hint
    lea rdx, [file_empty]
    call font_draw_string
.hint:
    mov edi, 96
    mov esi, 330
    lea rdx, [git_status]
    mov ecx, 0xFF7CFF9A
    call font_draw_string
    mov edi, 96
    mov esi, 350
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
hint_files:  db "Click entry or F8 to close", 0
file_empty:  db "No NavineFS files yet", 0

file_name_1:  db "readme.txt", 0
file_name_2:  db "hello.txt", 0
file_name_3:  db "config.json", 0
file_name_4:  db "page.html", 0
file_name_5:  db "script.sh", 0
file_name_6:  db "doom1.wad", 0
file_name_7:  db "sample.exe", 0
file_name_8:  db "sample.elf", 0
file_name_9:  db "app.navapp", 0
file_name_10: db "demo.dmg", 0

git_status: db "Git: main (clean)", 0

file_ptrs:
    dq file_name_1, file_name_2, file_name_3, file_name_4, file_name_5
    dq file_name_6, file_name_7, file_name_8, file_name_9, file_name_10
