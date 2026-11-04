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

    ; Guardar el dispositivo de arranque
    mov [boot_drive], dl

    ; ------------------------------------------------
    ; 1. Leer el segundo sector del disco
    ; ------------------------------------------------

    sti

    mov ah, 0x02          ; Funcion BIOS: leer sectores
    mov al, 1             ; Leer un sector
    mov ch, 0             ; Cilindro 0
    mov cl, 2             ; Sector 2
    mov dh, 0             ; Cabezal 0
    mov dl, [boot_drive]  ; Dispositivo de arranque

    mov bx, 0x8000        ; Destino: ES:BX = 0000:8000

    int 0x13

    cli

    jc disk_error

    ; Restaurar segmentos y direccion de cadena
    xor ax, ax
    mov ds, ax
    mov es, ax
    cld

    ; ------------------------------------------------
    ; 2. Cargar la GDT
    ; ------------------------------------------------

    lgdt [gdt_descriptor]

    ; ------------------------------------------------
    ; 3. Activar el modo protegido
    ; ------------------------------------------------

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Salto lejano: cargar CS = 0x08
    jmp dword 0x08:protected_mode

; ----------------------------------------------------
; Codigo de 32 bits
; ----------------------------------------------------

bits 32

protected_mode:

    ; Cargar selectores de datos
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Preparar la pila
    mov esp, 0x90000

    ; Transferir el control al segundo sector
    jmp 0x8000

; ----------------------------------------------------
; Error de lectura del disco (modo real)
; ----------------------------------------------------

bits 16

disk_error:
    xor ax, ax
    mov ds, ax

    mov si, error_message

print_error:
    lodsb
    cmp al, 0
    je error_halt

    mov ah, 0x0E
    int 0x10
    jmp print_error

error_halt:
    cli

error_loop:
    hlt
    jmp error_loop

; ----------------------------------------------------
; Datos y GDT
; ----------------------------------------------------

boot_drive db 0

error_message db 'Error leyendo el segundo sector!', 0

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
