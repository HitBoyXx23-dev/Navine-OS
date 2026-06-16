/* kernel/net/ethernet.c */
#include <kernel/net.h>
uint16_t ethernet_type(const uint8_t *frame) { return frame ? (uint16_t)((frame[12] << 8) | frame[13]) : 0; }
