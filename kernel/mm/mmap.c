/* kernel/mm/mmap.c
 * Language: C17 freestanding
 * Purpose: Placeholder VMA API for future mmap/munmap/mprotect syscalls.
 */
#include <kernel/mm.h>

uint64_t mmap_anonymous(size_t pages, uint64_t flags) {
    uint64_t phys = pmm_alloc_n(pages);
    (void)flags;
    return phys;
}

void munmap_region(uint64_t virt, size_t pages) {
    for (size_t i = 0; i < pages; ++i) {
        vmm_unmap(NULL, virt + i * PAGE_SIZE);
    }
}
