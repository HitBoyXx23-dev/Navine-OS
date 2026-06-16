/* kernel/mm/heap.c
 * Language: C17 freestanding
 * Purpose: Simple early bump heap for the C kernel path.
 */
#include <kernel/mm.h>

#define HEAP_SIZE (1024ull * 1024ull)

static uint8_t heap_area[HEAP_SIZE];
static size_t heap_used;

static size_t align_up(size_t value, size_t align) {
    return (value + align - 1u) & ~(align - 1u);
}

void heap_init(void) {
    heap_used = 0;
}

void *kmalloc_aligned(size_t size, size_t align) {
    if (align < 8u) {
        align = 8u;
    }
    size_t start = align_up(heap_used, align);
    if (start + size > HEAP_SIZE) {
        return NULL;
    }
    heap_used = start + size;
    return &heap_area[start];
}

void *kmalloc(size_t size) {
    return kmalloc_aligned(size, 8u);
}

void *kzalloc(size_t size) {
    uint8_t *ptr = (uint8_t *)kmalloc(size);
    if (!ptr) {
        return NULL;
    }
    for (size_t i = 0; i < size; ++i) {
        ptr[i] = 0;
    }
    return ptr;
}

void *krealloc(void *ptr, size_t size) {
    void *next = kmalloc(size);
    (void)ptr;
    return next;
}

void kfree(void *ptr) {
    (void)ptr;
}
