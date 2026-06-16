/* kernel/include/kernel/security.h */
#ifndef NAVINE_KERNEL_SECURITY_H
#define NAVINE_KERNEL_SECURITY_H
#include <kernel/types.h>
void security_init(void);
bool security_check_syscall(uint64_t syscall_number);
#endif
