bits 16
org 0x7C00

start:
    mov si, message

print:
    lodsb
    cmp al, 0
    je halt

    mov ah, 0x0E
    int 0x10
    jmp print

halt:
    cli

hang:
    hlt
    jmp hang

message db 'Hola desde nuestro SO!', 0

times 510 - ($ - $$) db 0
dw 0xAA55
