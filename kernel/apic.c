/* kernel/apic.c
 * Language: C17 freestanding
 * Purpose: Local APIC placeholder for the future ACPI MADT path.
 */
#include <kernel/types.h>

static bool apic_available;

void apic_init(void) {
    apic_available = false;
}

bool apic_is_available(void) {
    return apic_available;
}
