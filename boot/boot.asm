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

    ; 1. Cargar la GDT
    lgdt [gdt_descriptor]

    ; 2. Activar el modo protegido (CR0.PE = 1)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 3. Salto lejano: selector de codigo + direccion
    jmp dword 0x08:protected_mode

bits 32

protected_mode:
    ; 4. Cargar el selector de datos en los segmentos
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; 5. Preparar la pila de 32 bits
    mov esp, 0x90000

    ; 6. Escribir directamente en la memoria VGA
    mov esi, message
    mov edi, 0xB8000

    ; Atributo VGA: blanco brillante sobre negro
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

; GDT: descriptor nulo, codigo de 32 bits y datos de 32 bits
align 8
gdt:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt - 1
    dd gdt

message db 'Hola desde modo protegido!', 0

times 510 - ($ - $$) db 0
dw 0xAA55
