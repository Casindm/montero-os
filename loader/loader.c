#include "elf.h"
#include <stdint.h>

void loader_main(void)
{
    // Interpretamos el comienzo del archivo como un ELF Header.
    Elf32Header *header = (Elf32Header *)0x10000;

    // Localizamos la tabla de Program Headers.
    Elf32ProgramHeader *program_headers = elf_get_program_headers(header);

    volatile uint32_t segment_address = program_headers[0].p_vaddr;

    const char *message = "Loader ejecutado!";
    volatile unsigned short *video = (volatile unsigned short *)0xB8000;

    for (unsigned int i = 0; message[i] != '\0'; i++) {
        video[i] = (0x0F << 8) | (unsigned char)message[i];
    }

    while (1) {
        __asm__ volatile ("hlt");
    }
}

