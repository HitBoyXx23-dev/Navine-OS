/* kernel/include/kernel/mm.h
 * Language: C17
 * Purpose: Physical, virtual, and heap memory manager APIs.
 * Build: included by kernel memory users.
 */
#ifndef NAVINE_KERNEL_MM_H
#define NAVINE_KERNEL_MM_H

#include <kernel/boot.h>
#include <kernel/types.h>

#define PAGE_SIZE 4096ull

uint64_t pmm_alloc(void);
uint64_t pmm_alloc_n(size_t pages);
void pmm_free(uint64_t phys);
void pmm_free_n(uint64_t phys, size_t pages);
uint64_t pmm_free_count(void);
uint64_t pmm_total_count(void);
void pmm_init(uint64_t mmap_addr, uint32_t mmap_count, uint64_t kernel_end);

void vmm_init(void);
void vmm_map(uint64_t *pml4, uint64_t virt, uint64_t phys, uint64_t flags);
void vmm_unmap(uint64_t *pml4, uint64_t virt);
void vmm_switch(uint64_t *pml4_phys);
void vmm_page_fault(uint64_t addr, uint64_t error);

void heap_init(void);
void *kmalloc(size_t size);
void *kzalloc(size_t size);
void *krealloc(void *ptr, size_t size);
void kfree(void *ptr);
void *kmalloc_aligned(size_t size, size_t align);

#endif
