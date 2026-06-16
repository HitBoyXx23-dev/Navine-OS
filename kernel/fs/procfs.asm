; Navine OS - /proc Virtual Filesystem

[BITS 64]

global init_procfs
global procfs_read

section .data
procfs_cpuinfo: db "processor       : 0", 10, 0

section .text
init_procfs:
    ret

procfs_read:
    lea rax, [procfs_cpuinfo]
    ret
