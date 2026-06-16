/* kernel/net/dns.c */
#include <kernel/net.h>
int dns_resolve_a(const char *name, Ipv4Address *out) { (void)name; if (out) out->bytes[0] = 0; return -1; }
