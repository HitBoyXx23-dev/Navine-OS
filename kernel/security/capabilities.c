/* kernel/security/capabilities.c */
#include <kernel/types.h>
bool capability_has(uint64_t caps, uint64_t bit) { return (caps & (1ull << bit)) != 0; }
