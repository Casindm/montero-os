bits 32

section .text

global isr0
extern exception_divide_by_zero

isr0:
    cli
    call exception_divide_by_zero

.hang:
    hlt
    jmp .hang
