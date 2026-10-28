bits 16
org 0x7C00

start:
    jmp 0x0000:normalized

normalized:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    cld
    sti

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
