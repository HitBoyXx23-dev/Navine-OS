; Navine OS - ATA PIO Driver

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global init_ata
global ata_read_sectors
global ata_write_sectors

section .text
init_ata:
    ret

ata_read_sectors:
    push rbp
    mov rbp, rsp
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
.sector_loop:
    test r14, r14
    jz .done
    mov rdi, r12
    call ata_read_one
    add r13, 512
    inc r12
    dec r14
    jmp .sector_loop
.done:
    mov rsp, rbp
    pop rbp
    ret

ata_read_one:
    mov dx, ATA_PRIMARY_IO + 6
    mov al, 0xE0
    mov r8, rdi
    shr r8, 24
    and r8b, 0x0F
    or al, r8b
    out dx, al
    mov dx, ATA_PRIMARY_IO + 2
    mov al, 1
    out dx, al
    mov dx, ATA_PRIMARY_IO + 3
    mov rax, rdi
    out dx, al
    mov dx, ATA_PRIMARY_IO + 4
    shr rax, 8
    out dx, al
    mov dx, ATA_PRIMARY_IO + 5
    shr rax, 8
    out dx, al
    mov dx, ATA_PRIMARY_IO + 7
    mov al, 0x20
    out dx, al
    mov r9, 0x80000
.wait:
    dec r9
    jz .fail
    in al, dx
    cmp al, 0xFF
    je .fail
    test al, 0x80
    jnz .wait
    test al, 0x21
    jnz .fail
    test al, 0x08
    jz .wait
    mov dx, ATA_PRIMARY_IO
    mov rcx, 256
    mov rdi, r13
    rep insw
    ret
.fail:
    mov rdi, r13
    mov rcx, 128
    xor eax, eax
    rep stosd
    ret

ata_write_sectors:
    push rbp
    mov rbp, rsp
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
.sector_loop:
    test r14, r14
    jz .done
    mov rdi, r12
    mov rsi, r13
    call ata_write_one
    add r13, 512
    inc r12
    dec r14
    jmp .sector_loop
.done:
    mov rsp, rbp
    pop rbp
    ret

ata_write_one:
    mov dx, ATA_PRIMARY_IO + 6
    mov al, 0xE0
    mov r8, rdi
    shr r8, 24
    and r8b, 0x0F
    or al, r8b
    out dx, al
    mov dx, ATA_PRIMARY_IO + 2
    mov al, 1
    out dx, al
    mov dx, ATA_PRIMARY_IO + 3
    mov rax, rdi
    out dx, al
    mov dx, ATA_PRIMARY_IO + 4
    shr rax, 8
    out dx, al
    mov dx, ATA_PRIMARY_IO + 5
    shr rax, 8
    out dx, al
    mov dx, ATA_PRIMARY_IO + 7
    mov al, 0x30
    out dx, al
    mov r9, 0x80000
.wait:
    dec r9
    jz .fail
    in al, dx
    cmp al, 0xFF
    je .fail
    test al, 0x80
    jnz .wait
    test al, 0x21
    jnz .fail
    test al, 0x08
    jz .wait
    mov dx, ATA_PRIMARY_IO
    mov rcx, 256
    mov rsi, r13
    rep outsw
    ret
.fail:
    ret
