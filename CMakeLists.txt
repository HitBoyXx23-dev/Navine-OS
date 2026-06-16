cmake_minimum_required(VERSION 3.20)
project(NavineOS LANGUAGES C CXX ASM_NASM)

set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 20)

add_library(navine_kernel_scaffold OBJECT
    kernel/main.c
    kernel/printk.c
    kernel/gdt.c
    kernel/idt.c
    kernel/pic.c
    kernel/apic.c
    kernel/mm/pmm.c
    kernel/mm/vmm.c
    kernel/mm/heap.c
    kernel/mm/mmap.c
    kernel/proc/process.c
    kernel/proc/scheduler.c
    kernel/proc/syscall.c
)
target_include_directories(navine_kernel_scaffold PRIVATE kernel/include)

add_library(navine_gui_scaffold OBJECT
    gui/libgfx/canvas.cpp
    gui/libgfx/font.cpp
    gui/window.cpp
    gui/compositor.cpp
)
target_include_directories(navine_gui_scaffold PRIVATE gui/include)
