#ifndef _STDDEF_H
#define _STDDEF_H

#include <stdint.h>

#define NULL ((void *)0)

typedef uint64_t size_t;
typedef int64_t ptrdiff_t;
typedef int64_t wchar_t;

#define offsetof(type, member) ((size_t)&(((type *)0)->member))

#endif
