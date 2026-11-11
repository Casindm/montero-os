bits 32

section .text

global _load
extern loader_main

_load:
    cli

    mov esp, 0x88000
    call loader_main

.hang:
    htl
    jmp .hang
