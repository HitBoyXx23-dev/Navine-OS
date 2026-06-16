/* libs/navine-libc/navine_syscall.h */
#ifndef NAVINE_LIBC_SYSCALL_H
#define NAVINE_LIBC_SYSCALL_H
static inline long navine_syscall0(long n) { long r; __asm__ volatile("syscall" : "=a"(r) : "a"(n) : "rcx", "r11", "memory"); return r; }
#endif
