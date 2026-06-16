/* kernel/linker.elf.ld
 * Purpose: Linker script for the future ELF/C kernel path.
 */
ENTRY(_start)

SECTIONS {
    . = 0x100000;

    .text : ALIGN(4096) {
        *(.text .text.*)
    }

    .rodata : ALIGN(4096) {
        *(.rodata .rodata.*)
    }

    .data : ALIGN(4096) {
        *(.data .data.*)
    }

    __bss_start = .;
    .bss : ALIGN(4096) {
        *(COMMON)
        *(.bss .bss.*)
    }
    __bss_end = .;
}
