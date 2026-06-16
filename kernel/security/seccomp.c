/* kernel/security/seccomp.c */
#include <kernel/security.h>
bool security_check_syscall(uint64_t syscall_number) { (void)syscall_number; return true; }
