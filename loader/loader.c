#include "elf.h"
#include <stdint.h>

void loader_main(void)
{
    // Interpretamos el comienzo del archivo como un ELF Header.
    Elf32Header *header = (Elf32Header *)0x10000;

    // Comprobamos si estamos apuntando a un ELF valido
    if (elf_validate_header(header) == 0)
    {
        const char *message = "ERROR: Detectado ELF invalido!";
        print_message(message);

        halt();
    }

    // Localizamos la tabla de Program Headers.
    Elf32ProgramHeader *program_headers = elf_get_program_headers(header);

    const char *message = "Loader ejecutado!";
    print_message(message);

    halt();
}

void print_message(const char *message) 
{
    volatile unsigned short *video = (volatile unsigned short *)0xB8000;

    for (unsigned int i = 0; message[i] != '\0'; i++) {
        video[i] = (0x0F << 8) | (unsigned char)message[i];
    }
}

void halt(void)
{
    while (1) {
        __asm__ volatile ("hlt");
    }
}
