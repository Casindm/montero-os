bits 32
org 0x8000

start:
    ; Preparar la dirección de nuestro mensaje
    mov esi, message

    ; Dirección de memoria VGA
    mov edi, 0xB8000

    ; Blanco brillante sobre negro
    mov ah, 0x0F

print:
    lodsb
    cmp al, 0
    je halt

    mov [edi], ax
    add edi, 2
    jmp print

halt:
    cli

hang:
    hlt
    jmp hang

message db 'Hola desde nuestro segundo sector!', 0

times 512 - ($ - $$) db 0
