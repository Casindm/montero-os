bits 32

section .text

global _start
extern kernel_main

_start:
    cli

    ; Preparar la pila del kernel.
    mov esp, 0x90000

    ; Llamar a la función escrita en C.
    call kernel_main

.hang:
    hlt
    jmp .hang
