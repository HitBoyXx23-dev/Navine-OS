/* kernel/net/icmp.c */
#include <kernel/net.h>
int icmp_handle(const uint8_t *packet, size_t len) { (void)packet; return len >= 8u ? 0 : -1; }
