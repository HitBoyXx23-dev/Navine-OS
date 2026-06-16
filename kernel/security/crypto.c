/* kernel/security/crypto.c */
#include <kernel/types.h>
uint32_t crypto_fnv1a(const void *data, size_t len) { const uint8_t *p = data; uint32_t h = 2166136261u; for (size_t i = 0; i < len; ++i) h = (h ^ p[i]) * 16777619u; return h; }
