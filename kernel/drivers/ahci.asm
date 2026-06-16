; Navine OS - AHCI Driver (stub initialization)

[BITS 64]

global init_ahci
global ahci_read_sectors

section .text
init_ahci:
    ret

ahci_read_sectors:
    xor rax, rax
    ret
