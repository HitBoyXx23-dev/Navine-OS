/* kernel/ipc/futex.c */
int futex_wait(int *addr, int expected) { return addr && *addr == expected ? 0 : -1; }
