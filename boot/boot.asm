bits 16
org 0x7C00

start:
    jmp 0x0000:normalized           ; Normalizamos el segmento de codigo

normalized:
    cli
    cld

    xor ax, ax                      ; Establecemos AX a 0
    mov ds, ax                      ; Normalizamos segmentos de datos
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00                  ; Establecemos pila de Boot Loader
    mov [boot_drive], dl            ; Almacenamos dispositivo de arranque

    ; 1. Cargar 4 sectores para Loader en 0x8000
    mov ax, 0x0800                  ; Inicializamos el segmento Loader
    mov es, ax
    xor bx, bx                      ; Reseteamos el offset para la direccion

    mov [floppy_sectors], 4         ; Numero de sectores a cargar
    mov [floppy_cylinder], 0        ; Indicamos el cilindro de las pistas
    mov [floppy_start], 2           ; Indicamos sector de inicio dentro de la pista
    mov [floppy_head], 0            ; Indicamos el cabezal (0 - 1)
    add [current_sector], 4         ; Actualizamos el sector actual
    call load_floppy                ; Efectuamos la carga de sectores

    ; 2. Cargar 64 sectores para ELF raw en 0x10000
    mov ax, 0x1000                  ; Inicializamos el segmento ELF
    mov es, ax

    mov si, 0                       ; Inicializamos total de sectores
    mov al, 1                       ; Inicializamos cabezal
    mov ah, -1                      ; Inicializamos cilindro
load_loop:
    mov bx, [current_address]       ; Establecemos el offset de la direccion de carga
    movzx di, byte [current_sector] ; Contamos desde el ultimo sector cargado
    mov cl, 0                       ; Reseteamos el numero de sectores a solicitar
    xor al, 1                       ; Alternamos cabezal
    jne inc_sector                  ; Si volvemos al cabezal 0
    inc ah                          ; Incrementamos cilindro

inc_sector:
    inc si                          ; Numero total de sectores cargados
    inc di                          ; Numero de sector dentro de la pista
    inc cl                          ; Numero de sectores a solicitar en la lectura BIOS

    cmp si, 64                      ; Comprobamos si se ha alcanzado el total de sectores
    je finish_load                  ; Saltamos a la carga de los ultimos sectores

    cmp di, 18                      ; Si no se alcanza el maximo de sectores por pista
    jne inc_sector                  ; Volvemos a contabilizar

    call set_load                   ; Se cargan los sectores contabilizados
    mov [current_sector], 0         ; Reinicializamos el sector de inicio
    jmp load_loop                   ; Reiniciamos la cuenta de sectores

finish_load:
    call set_load                   ; Cargamos los ultimos sectores restantes

    ; 3. Preparar la transición a modo protegido
    cli

    xor ax, ax                      ; Establecemos AX a 0
    mov ds, ax                      ; Restablecemos los valores de los
    mov es, ax                      ; segmentos de datos

    lgdt [gdt_descriptor]           ; Cargamos la tabla de descriptores

    mov eax, cr0                    ; Obtenemos el valor de CR0
    or eax, 1                       ; Activamos el primer bit (Modo protegido)
    mov cr0, eax                    ; Devolvemos el valor a CR0

    jmp dword 0x08:protected_mode   ; Salto lejano para establecer segmento de codigo

bits 32

protected_mode:
    mov ax, 0x10                    ; Cargamos el descriptor para la nueva
    mov ds, ax                      ; segmentación de datos segun la GDT
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000                ; Establecemos pila de Loader ELF

    jmp 0x8000                      ; Transferimos el control al loader

bits 16

disk_error:
    mov si, error_message

print_error:
    lodsb                           ; Contenido de SI a AL, aumentamos SI
    test al, al                     ; Comprobamos final de string (0x00)
    jz halt                         ; Finalizamos rutina

    mov ah, 0x0E                    ; Establecemos contraste de terminal
    int 0x10                        ; Funcion BIOS para imprimir pantalla
    jmp print_error

halt:
    cli

hang:
    hlt
    jmp hang

set_load:
    mov [floppy_sectors], cl        ; Almacenamos el numero de sectores a cargar
    movzx cx, cl                    ; Limpiamos el contenido de CH
    shl cx, 9                       ; Multiplicamos por 512 (Shift 9 posiciones)
    add [current_address], cx       ; Acumulamos el total de direcciones
    mov dl, [current_sector]        ; Almacenamos el sector de pista actual
    inc dl                          ; Obtenemos el sector siguiente (sector de inicio)
    mov [floppy_start], dl          ; Establecemos el sector de inicio
    mov [floppy_head], al           ; Establecemos el cabezal
    mov [floppy_cylinder], ah       ; Establecemos el cilindro

load_floppy:
    push ax                         ; Almacenamos AX en la pila (Cabezal y Cilindro)
    push si                         ; Almacenamos SI en la pila (Total de sectores)
    mov ah, 0x02                    ; Establecemos parametros para rutina
    mov al, [floppy_sectors]
    mov ch, [floppy_cylinder]
    mov cl, [floppy_start]
    mov dh, [floppy_head]
    mov dl, [boot_drive]

    int 0x13                        ; Llamamos a rutina de BIOS
    jc disk_error                   ; Saltamos a rutina de error
    pop si                          ; Recuperamos el Total de sectores cargados
    pop ax                          ; Recuperamos el Cabezal y Cilindro del floppy
    ret

boot_drive db 0                     ; Identificador dispositivo de arranque
floppy_sectors db 0                 ; Sectores de pista (1 - 18)
floppy_cylinder db 0                ; Cilindro (0 - 79)
floppy_head db 0                    ; Cabezal (0 - 1)
floppy_start db 0                   ; Sector de inicio para la carga
current_sector db 1                 ; Ultimo sector cargado
current_address dw 0
error_message db 'Error loading kernel!', 0

align 8
gdt:
    dq 0x0000000000000000           ; Segmento 0x00
    dq 0x00CF9A000000FFFF           ; Segmento 0x08
    dq 0x00CF92000000FFFF           ; Segmento 0x10
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt - 1            ; Limite de GDT (8 * numero de segmentos - 1)
    dd gdt                          ; Direccion de GDT

times 510 - ($ - $$) db 0           ; Completamos con 0 el resto del sector
dw 0xAA55                           ; Firma de Boot Loader
