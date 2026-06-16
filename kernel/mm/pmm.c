/* kernel/mm/pmm.c
 * Language: C17 freestanding
 * Purpose: Bitmap physical page allocator scaffold.
 */
#include <kernel/mm.h>

#define PMM_MAX_PAGES 32768ull

static uint8_t pmm_bitmap[PMM_MAX_PAGES / 8u];
static uint64_t pmm_total_pages;
static uint64_t pmm_free_pages;

static void bit_set(uint64_t page) {
    pmm_bitmap[page / 8u] |= (uint8_t)(1u << (page & 7u));
}

static void bit_clear(uint64_t page) {
    pmm_bitmap[page / 8u] &= (uint8_t)~(1u << (page & 7u));
}

static bool bit_test(uint64_t page) {
    return (pmm_bitmap[page / 8u] & (uint8_t)(1u << (page & 7u))) != 0;
}

void pmm_init(uint64_t mmap_addr, uint32_t mmap_count, uint64_t kernel_end) {
    for (uint64_t i = 0; i < sizeof(pmm_bitmap); ++i) {
        pmm_bitmap[i] = 0xFFu;
    }
    pmm_total_pages = PMM_MAX_PAGES;
    pmm_free_pages = 0;

    const NavineE820Entry *map = (const NavineE820Entry *)(uintptr_t)mmap_addr;
    for (uint32_t i = 0; map && i < mmap_count; ++i) {
        if (map[i].type != NAVINE_E820_USABLE) {
            continue;
        }
        uint64_t first = (map[i].base + PAGE_SIZE - 1u) / PAGE_SIZE;
        uint64_t last = (map[i].base + map[i].length) / PAGE_SIZE;
        if (last > PMM_MAX_PAGES) {
            last = PMM_MAX_PAGES;
        }
        for (uint64_t page = first; page < last; ++page) {
            bit_clear(page);
            ++pmm_free_pages;
        }
    }

    uint64_t reserved_pages = (kernel_end + PAGE_SIZE - 1u) / PAGE_SIZE;
    if (reserved_pages > PMM_MAX_PAGES) {
        reserved_pages = PMM_MAX_PAGES;
    }
    for (uint64_t page = 0; page < reserved_pages; ++page) {
        if (!bit_test(page)) {
            bit_set(page);
            --pmm_free_pages;
        }
    }
}

uint64_t pmm_alloc(void) {
    for (uint64_t page = 1; page < PMM_MAX_PAGES; ++page) {
        if (!bit_test(page)) {
            bit_set(page);
            --pmm_free_pages;
            return page * PAGE_SIZE;
        }
    }
    return 0;
}

uint64_t pmm_alloc_n(size_t pages) {
    if (pages == 0 || pages > PMM_MAX_PAGES) {
        return 0;
    }
    for (uint64_t start = 1; start + pages <= PMM_MAX_PAGES; ++start) {
        bool free_run = true;
        for (uint64_t off = 0; off < pages; ++off) {
            if (bit_test(start + off)) {
                free_run = false;
                start += off;
                break;
            }
        }
        if (!free_run) {
            continue;
        }
        for (uint64_t off = 0; off < pages; ++off) {
            bit_set(start + off);
        }
        pmm_free_pages -= pages;
        return start * PAGE_SIZE;
    }
    return 0;
}

void pmm_free(uint64_t phys) {
    pmm_free_n(phys, 1);
}

void pmm_free_n(uint64_t phys, size_t pages) {
    uint64_t start = phys / PAGE_SIZE;
    for (uint64_t off = 0; off < pages && start + off < PMM_MAX_PAGES; ++off) {
        if (bit_test(start + off)) {
            bit_clear(start + off);
            ++pmm_free_pages;
        }
    }
}

uint64_t pmm_free_count(void) {
    return pmm_free_pages;
}

uint64_t pmm_total_count(void) {
    return pmm_total_pages;
}
