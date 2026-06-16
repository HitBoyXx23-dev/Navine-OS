ENTRY(_navine_crt_start)

SECTIONS
{
    . = 0x200000;

    .text : ALIGN(16) {
        *(.text*)
    }

    .rdata : ALIGN(16) {
        *(.rdata*)
        *(.rodata*)
    }

    .data : ALIGN(16) {
        *(.data*)
    }

    .bss : ALIGN(16) {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    }

    /DISCARD/ : {
        *(.pdata)
        *(.xdata)
        *(.eh_frame)
        *(.gcc_except_table)
    }
}
