/* kernel/net/udp.c */
#include <kernel/net.h>
uint16_t udp_length(const uint8_t *packet) { return packet ? (uint16_t)((packet[4] << 8) | packet[5]) : 0; }
