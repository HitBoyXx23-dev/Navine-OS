/* kernel/include/kernel/types.h
 * Language: C17
 * Purpose: Freestanding fixed-width types and common kernel aliases.
 * Build: included by freestanding kernel C files.
 */
#ifndef NAVINE_KERNEL_TYPES_H
#define NAVINE_KERNEL_TYPES_H

typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

typedef signed char        int8_t;
typedef signed short       int16_t;
typedef signed int         int32_t;
typedef signed long long   int64_t;

typedef uint64_t size_t;
typedef int64_t  ssize_t;
typedef int32_t  pid_t;
typedef uint32_t uid_t;
typedef uint32_t gid_t;
typedef uint64_t uintptr_t;
typedef int64_t  intptr_t;

typedef enum {
    false = 0,
    true = 1
} bool;

#define NULL ((void *)0)

#define NAVINE_PACKED __attribute__((packed))
#define NAVINE_ALIGNED(n) __attribute__((aligned(n)))
#define NAVINE_NORETURN __attribute__((noreturn))

#endif
