; Navine OS - Text Viewer

[BITS 64]

global init_textviewer
global textviewer_open
global textviewer_render
global textviewer_handle_mouse
global textviewer_active

extern mouse_x
extern mouse_y
extern mouse_buttons

section .bss
textviewer_active: resb 1
textviewer_mouse_last: resb 1
textviewer_title:  resb 64
textviewer_body:   resb 512

section .text
init_textviewer:
    mov byte [textviewer_active], 0
    mov byte [textviewer_mouse_last], 0
    ret

textviewer_open:
    push rbx
    mov byte [textviewer_active], 1
    mov rsi, rdi
    lea rdi, [textviewer_title]
    call copy_basename
    mov rsi, textviewer_title
    lea rdi, [textviewer_body]
    call lookup_content
    pop rbx
    ret

textviewer_render:
    cmp byte [textviewer_active], 0
    je .done
    mov edi, 140
    mov esi, 160
    mov edx, 440
    mov ecx, 280
    mov r8d, 0xFF1C1C1E
    call fb_fill_rect
    mov edi, 156
    mov esi, 172
    lea rdx, [textviewer_title]
    mov ecx, 0xFFFFFFFF
    call font_draw_string
    mov edi, 548
    mov esi, 172
    lea rdx, [textviewer_close_x]
    mov ecx, 0xFFFF5F57
    call font_draw_string
    mov edi, 156
    mov esi, 200
    lea rdx, [textviewer_body]
    mov ecx, 0xFFCCCCCC
    call font_draw_string
.done:
    ret

textviewer_handle_mouse:
    cmp byte [textviewer_active], 0
    je .done
    mov al, [mouse_buttons]
    mov bl, [textviewer_mouse_last]
    mov [textviewer_mouse_last], al
    test al, 1
    jz .done
    test bl, 1
    jnz .done
    mov eax, [mouse_x]
    cmp eax, 540
    jl .done
    cmp eax, 570
    jg .done
    mov eax, [mouse_y]
    cmp eax, 166
    jl .done
    cmp eax, 194
    jg .done
    mov byte [textviewer_active], 0
.done:
    ret

copy_basename:
    push rsi
    push rdi
    lea rdi, [textviewer_title]
    xor eax, eax
    mov rcx, 63
    rep stosb
    mov rax, rsi
    lea rdi, [textviewer_title]
.scan:
    movzx ecx, byte [rsi]
    test cl, cl
    jz .write
    inc rsi
    cmp cl, '/'
    je .set
    cmp cl, '\'
    je .set
    jmp .scan
.set:
    mov rax, rsi
    jmp .scan
.write:
    mov rsi, rax
.copy:
    movzx ecx, byte [rsi]
    mov [rdi], cl
    test cl, cl
    jz .out
    inc rsi
    inc rdi
    jmp .copy
.out:
    pop rdi
    pop rsi
    ret

lookup_content:
    push rbx
    lea rbx, [catalogue]
.loop:
    cmp byte [rbx], 0
    je .default
    push rbx
    mov rsi, rbx
    lea rdi, [textviewer_title]
    call str_eq
    pop rbx
    test rax, rax
    jnz .found
.skip_name:
    mov al, [rbx]
    test al, al
    jz .default
    inc rbx
    jmp .skip_name
.found:
.skip_to_content:
    mov al, [rbx]
    inc rbx
    test al, al
    jnz .skip_to_content
    mov rsi, rbx
    call str_copy
    jmp .out
.default:
    lea rsi, [default_text]
    call str_copy
.out:
    pop rbx
    ret

str_eq:
    push rsi
    push rdi
.cmp:
    movzx eax, byte [rsi]
    movzx ecx, byte [rdi]
    cmp al, cl
    jne .fail
    test al, al
    jz .ok
    inc rsi
    inc rdi
    jmp .cmp
.ok:
    mov rax, 1
    jmp .done
.fail:
    xor rax, rax
.done:
    pop rdi
    pop rsi
    ret

str_copy:
    push rsi
.copy:
    movzx eax, byte [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .copy
.done:
    pop rsi
    ret

section .rodata
textviewer_close_x: db "X", 0
catalogue:
    db "readme.txt", 0
    db "Navine OS supports common workspace items.", 10, "Use F8 Vault or Search.", 10, 0
    db "hello.txt", 0
    db "Hello from Navine OS!", 10, 0
    db "config.json", 0
    db "{ name: Navine, version: 1 }", 10, 0
    db "page.html", 0
    db "<html><body>Navine Browser</body></html>", 10, 0
    db "script.sh", 0
    db "#!/bin/sh", 10, "echo Navine", 10, 0
    db 0

default_text:
    db "Text file opened.", 10, "Content loaded by extension handler.", 10, 0
