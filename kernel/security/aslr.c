/* kernel/security/aslr.c */
#include <kernel/types.h>
uint64_t aslr_slide(uint64_t seed) { return (seed & 0xFFFull) << 12; }
