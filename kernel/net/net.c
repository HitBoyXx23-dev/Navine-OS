/* kernel/net/net.c */
#include <kernel/net.h>
extern void tcp_init(void);
void net_init(void) { tcp_init(); }
