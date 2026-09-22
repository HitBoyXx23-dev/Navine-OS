; Navine OS - ACPI power management stub

[BITS 64]

global acpi_init
global acpi_battery_percent
global acpi_on_ac_power
global acpi_set_power_profile

section .bss
acpi_battery:   resb 1
acpi_ac:        resb 1
acpi_profile:   resb 1

section .text
acpi_init:
    mov byte [acpi_battery], 85
    mov byte [acpi_ac], 1
    mov byte [acpi_profile], 1
    ret

acpi_battery_percent:
    movzx rax, byte [acpi_battery]
    ret

acpi_on_ac_power:
    movzx rax, byte [acpi_ac]
    ret

acpi_set_power_profile:
    mov [acpi_profile], al
    cmp al, 2
    jne .out
    mov byte [acpi_battery], 70
.out:
    ret
