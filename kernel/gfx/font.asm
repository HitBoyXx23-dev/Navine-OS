; Navine OS - 8x16 UI Font

[BITS 64]

global font_draw_char
global font_draw_string
global font_init
global font_advance
global font_line_height
global font_text_width
global font_scale

%ifndef NAVINE_LINK_BUILD
extern fb_put_pixel
extern fb_width
%endif

section .rodata
%include "gfx/font_data.inc"

section .bss
font_scale: resd 1

section .text
font_init:
    mov dword [font_scale], 1
    mov eax, [fb_width]
    cmp eax, 1920
    jb .done
    mov dword [font_scale], 2
.done:
    ret

font_advance:
    mov eax, [font_scale]
    test eax, eax
    jnz .have
    mov eax, 1
.have:
    imul eax, FONT_CELL_W
    ret

font_line_height:
    mov eax, [font_scale]
    test eax, eax
    jnz .have
    mov eax, 1
.have:
    imul eax, FONT_CELL_H
    ret

font_text_width:
    push rbx
    mov rbx, rdi
    xor ecx, ecx
.count:
    cmp byte [rbx], 0
    je .done
    inc ecx
    inc rbx
    jmp .count
.done:
    call font_advance
    imul eax, ecx
    pop rbx
    ret

font_draw_char:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rcx

    mov r12d, edi
    mov r13d, esi
    mov r14d, ecx
    movzx eax, dl
    cmp al, FONT_FIRST_CHAR
    jb .out
    cmp al, FONT_LAST_CHAR
    ja .out
    sub eax, FONT_FIRST_CHAR
    imul eax, FONT_CELL_H
    lea rbx, [font_glyphs]
    add rbx, rax
    mov r11d, [font_scale]
    test r11d, r11d
    jnz .have_scale
    mov r11d, 1
.have_scale:
    xor r15d, r15d
.row:
    cmp r15d, FONT_CELL_H
    jae .out
    movzx eax, byte [rbx + r15]
    test eax, eax
    jz .next_row
    xor r10d, r10d
.col:
    cmp r10d, FONT_CELL_W
    jae .next_row
    mov ecx, r10d
    mov edx, 0x80
    shr edx, cl
    test eax, edx
    jz .skip
    push rax
    mov edi, r10d
    imul edi, r11d
    add edi, r12d
    mov esi, r15d
    imul esi, r11d
    add esi, r13d
    mov edx, r14d
    call fb_put_pixel
    cmp r11d, 2
    jb .drawn
    mov edi, r10d
    imul edi, r11d
    add edi, r12d
    inc edi
    mov esi, r15d
    imul esi, r11d
    add esi, r13d
    mov edx, r14d
    call fb_put_pixel
    mov edi, r10d
    imul edi, r11d
    add edi, r12d
    mov esi, r15d
    imul esi, r11d
    add esi, r13d
    inc esi
    mov edx, r14d
    call fb_put_pixel
    mov edi, r10d
    imul edi, r11d
    add edi, r12d
    inc edi
    mov esi, r15d
    imul esi, r11d
    add esi, r13d
    inc esi
    mov edx, r14d
    call fb_put_pixel
.drawn:
    pop rax
.skip:
    inc r10d
    jmp .col
.next_row:
    inc r15d
    jmp .row
.out:
    pop rcx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

font_draw_string:
    push rbx
    push r12
    push r13
    push r14
    push rcx

    mov r12d, edi
    mov r13d, esi
    mov r14d, ecx
    mov rbx, rdx
.loop:
    movzx eax, byte [rbx]
    test al, al
    jz .out
    mov edi, r12d
    mov esi, r13d
    mov dl, al
    mov ecx, r14d
    call font_draw_char
    call font_advance
    add r12d, eax
    inc rbx
    jmp .loop
.out:
    pop rcx
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
