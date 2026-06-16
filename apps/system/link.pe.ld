ENTRY(_start)

SECTIONS
{
    . = 0x00900000;

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
        *(.bss*)
        *(COMMON)
    }
}
