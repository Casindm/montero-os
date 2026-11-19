#include "elf.h"
#include <stdint.h>

#define PT_LOAD 1

void memory_copy(uint8_t *destination,
                 const uint8_t *source,
                 uint32_t size);

void memory_set(uint8_t *destination,
                uint8_t value,
                uint32_t size);

void print_message(const char *message);
void halt(void);

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

    for (uint32_t i = 0; i < header->e_phnum; i++)
    {
        Elf32ProgramHeader *program_header = 
            elf_get_program_header(header, i);

        if (program_header->p_type == PT_LOAD)
        {
            // Por implementar
        }
    }

    const char *message = "Loader ejecutado!";
    print_message(message);

    halt();
}

void memory_copy(uint8_t *destination,
                 const uint8_t *source,
                 uint32_t size)
{
    for (uint32_t i = 0; i < size; i++)
    {
        destination[i] = source[i];
    }
}

void memory_set(uint8_t *destination,
                uint8_t value,
                uint32_t size)
{
    for (uint32_t i = 0; i < size; i++)
    {
        destination[i] = value;
    }
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
