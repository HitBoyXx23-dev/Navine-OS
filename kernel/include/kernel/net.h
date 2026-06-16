/* kernel/include/kernel/net.h */
#ifndef NAVINE_KERNEL_NET_H
#define NAVINE_KERNEL_NET_H
#include <kernel/types.h>
typedef struct { uint8_t bytes[6]; } MacAddress;
typedef struct { uint8_t bytes[4]; } Ipv4Address;
void net_init(void);
#endif
