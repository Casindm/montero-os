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

    ;_____________________    
    ; CARGAMOS loader.bin ;
    ;---------------------
    mov [boot_drive], dl

    ; Dirección física destino: 0x10000
    mov ax, 0x0800
    mov es, ax
    xor bx, bx

    ; Cargar el kernel desde los sectores 2-5.
    mov ah, 0x02
    mov al, 4    ; Nº sectores
    mov ch, 0    ; Cilindro
    mov cl, 2    ; Sector inicio
    mov dh, 0    ; Cabezal

    mov dl, [boot_drive]
    int 0x13

    jc disk_error

    ; Preparar la transición a modo protegido.
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax

    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp dword 0x08:protected_mode

bits 32

protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000

    ; Transferir el control al kernel.
    jmp 0x8000

bits 16

disk_error:
    mov si, error_message

print_error:
    lodsb
    test al, al
    jz halt

    mov ah, 0x0E
    int 0x10
    jmp print_error

halt:
    cli

hang:
    hlt
    jmp hang

boot_drive db 0
error_message db 'Error loading kernel!', 0

align 8

gdt:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt - 1
    dd gdt

times 510 - ($ - $$) db 0
dw 0xAA55
