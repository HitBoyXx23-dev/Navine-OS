ENTRY(_start)

SECTIONS
{
    . = 0x10000;

    .text ALIGN(16) :
    {
        KEEP(*(.text))
        *(.text*)
    }

    .rdata ALIGN(16) :
    {
        *(.rdata*)
        *(.rodata*)
    }

    .data ALIGN(16) :
    {
        *(.data*)
    }

    .bss ALIGN(16) :
    {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    }
}
