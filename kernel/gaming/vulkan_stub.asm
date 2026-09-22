; Navine OS - Vulkan userspace driver stub

[BITS 64]

global vulkan_init
global vulkan_is_available
global vulkan_optimize_for_gaming
global vulkan_device_name

section .bss
vulkan_ready: resb 1
vulkan_boost: resb 1

section .text
vulkan_init:
    mov byte [vulkan_ready], 1
    mov byte [vulkan_boost], 0
    ret

vulkan_is_available:
    movzx rax, byte [vulkan_ready]
    ret

vulkan_optimize_for_gaming:
    mov byte [vulkan_boost], 1
    mov rax, 1
    ret

vulkan_device_name:
    lea rax, [dev_name]
    ret

section .rodata
dev_name: db "NavineVK (software)", 0
