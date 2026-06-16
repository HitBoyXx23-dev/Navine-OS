; Navine OS - Monolithic Kernel Link (flat binary, NASM-only native build)
; Build: nasm -f bin -I include/ -I kernel/ -o build/kernel.bin kernel/link.asm

[BITS 64]
[ORG 0x10000]

%define NAVINE_LINK_BUILD

%include "constants.inc"
%include "macros.inc"

section .text

global _start
_start:
kernel_entry:
    cld
    mov rbp, rsp
    and rsp, 0xFFFFFFFFFFFFFFF0
    call early_framebuffer_paint

    call init_idt
    call init_pic
    call init_framebuffer
    call init_installer
    call init_keyboard
    call installer_load_disk_flag
    call init_wallpaper
    call init_compositor
    call init_desktop
    call init_wm
    call init_terminal
    call init_filetypes
    call init_launcher
    call init_textviewer
    call init_files
    call init_doom
    call init_cppapp
    call init_simpleapps

    sti
    call kernel_main

.kernel_halt:
    cli
    hlt
    jmp .kernel_halt

%include "mm/pmm.asm"
%include "mm/vmm.asm"
%include "mm/heap.asm"
%include "arch/idt.asm"
%include "arch/syscalls.asm"
%include "drivers/pic.asm"
%include "drivers/pit.asm"
%include "drivers/ps2_keyboard.asm"
%include "drivers/ps2_mouse.asm"
%include "drivers/ata.asm"
%include "drivers/ahci.asm"
%include "gfx/early_fb.asm"
%include "drivers/vga_bga.asm"
%include "drivers/pci.asm"
%include "drivers/rtl8139.asm"
%include "drivers/e1000.asm"
%include "proc/scheduler.asm"
%include "proc/ipc.asm"
%include "proc/signals.asm"
%include "elf/loader.asm"
%include "security/security.asm"
%include "compat/compat.asm"
%include "fs/vfs.asm"
%include "fs/navinefs.asm"
%include "fs/fat32.asm"
%include "fs/ext2.asm"
%include "fs/iso9660.asm"
%include "fs/procfs.asm"
%include "fs/devfs.asm"
%include "gfx/framebuffer.asm"
%include "gfx/font.asm"
%include "gfx/compositor.asm"
%include "wm/window.asm"
%include "desktop/wallpaper.asm"
%include "desktop/installer.asm"
%include "desktop/login.asm"
%include "desktop/desktop.asm"
%include "desktop/theme.asm"
%include "desktop/plugin.asm"
%include "terminal/terminal.asm"
%include "net/stack.asm"
%include "fs/filetypes.asm"
%include "apps/launcher.asm"
%include "apps/textviewer.asm"
%include "apps/files.asm"
%include "apps/doom.asm"
%include "apps/cppapp.asm"
%include "apps/simpleapps.asm"
%include "main.asm"

section .data
fb_info_ptr: dq FB_INFO_PHYS
