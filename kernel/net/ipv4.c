/* kernel/net/ipv4.c */
#include <kernel/net.h>
uint8_t ipv4_header_length(const uint8_t *packet) { return packet ? (uint8_t)((packet[0] & 0x0Fu) * 4u) : 0; }
