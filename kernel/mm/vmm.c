/* kernel/mm/vmm.c
 * Language: C17 freestanding
 * Purpose: Early x86-64 page table mapping helpers.
 */
#include <kernel/mm.h>

#define PTE_PRESENT 1ull
#define PTE_WRITE   2ull
#define PTE_ADDR_MASK 0x000FFFFFFFFFF000ull

static uint64_t *active_pml4;

static uint64_t *ensure_table(uint64_t *table, uint64_t index) {
    if ((table[index] & PTE_PRESENT) == 0) {
        uint64_t phys = pmm_alloc();
        if (!phys) {
            return NULL;
        }
        uint64_t *new_table = (uint64_t *)(uintptr_t)phys;
        for (uint64_t i = 0; i < 512; ++i) {
            new_table[i] = 0;
        }
        table[index] = phys | PTE_PRESENT | PTE_WRITE;
    }
    return (uint64_t *)(uintptr_t)(table[index] & PTE_ADDR_MASK);
}

void vmm_init(void) {
    uint64_t cr3;
    __asm__ volatile("mov %%cr3, %0" : "=r"(cr3));
    active_pml4 = (uint64_t *)(uintptr_t)(cr3 & PTE_ADDR_MASK);
}

void vmm_map(uint64_t *pml4, uint64_t virt, uint64_t phys, uint64_t flags) {
    if (!pml4) {
        pml4 = active_pml4;
    }
    uint64_t pml4_i = (virt >> 39) & 511u;
    uint64_t pdpt_i = (virt >> 30) & 511u;
    uint64_t pd_i = (virt >> 21) & 511u;
    uint64_t pt_i = (virt >> 12) & 511u;

    uint64_t *pdpt = ensure_table(pml4, pml4_i);
    uint64_t *pd = pdpt ? ensure_table(pdpt, pdpt_i) : NULL;
    uint64_t *pt = pd ? ensure_table(pd, pd_i) : NULL;
    if (pt) {
        pt[pt_i] = (phys & PTE_ADDR_MASK) | flags | PTE_PRESENT;
    }
}

void vmm_unmap(uint64_t *pml4, uint64_t virt) {
    if (!pml4) {
        pml4 = active_pml4;
    }
    uint64_t *pdpt = (uint64_t *)(uintptr_t)(pml4[(virt >> 39) & 511u] & PTE_ADDR_MASK);
    if (!pdpt) return;
    uint64_t *pd = (uint64_t *)(uintptr_t)(pdpt[(virt >> 30) & 511u] & PTE_ADDR_MASK);
    if (!pd) return;
    uint64_t *pt = (uint64_t *)(uintptr_t)(pd[(virt >> 21) & 511u] & PTE_ADDR_MASK);
    if (!pt) return;
    pt[(virt >> 12) & 511u] = 0;
    __asm__ volatile("invlpg (%0)" : : "r"(virt) : "memory");
}

void vmm_switch(uint64_t *pml4_phys) {
    active_pml4 = pml4_phys;
    __asm__ volatile("mov %0, %%cr3" : : "r"(pml4_phys) : "memory");
}

void vmm_page_fault(uint64_t addr, uint64_t error) {
    (void)addr;
    (void)error;
    for (;;) {
        __asm__ volatile("cli; hlt");
    }
}
