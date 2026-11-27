#include "elf.h"
#include <stdint.h>


void memory_copy(uint8_t *destination, const uint8_t *source, uint32_t size);
void memory_set(uint8_t *destination, uint8_t value, uint32_t size);
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

    KernelEntryPoint kernel_entry = 0;

    for (uint32_t i = 0; i < header->e_phnum; i++)
    {
        Elf32ProgramHeader *program_header =  elf_get_program_header(header, i);

        if (program_header->p_type == PT_LOAD)
        {
            // Validacion del segmento
            if (elf_validate_program_header(header, program_header) == 0)
            {
                print_message("ERROR: Detectado segmento invalido");

                halt();
            }

            // Copia del segmento en memoria
            memory_copy((uint8_t *)program_header->p_paddr,
                        (uint8_t *)header + program_header->p_offset,
                        program_header->p_filesz);

            // Inicializacion a 0 de variables no declaradas
            memory_set((uint8_t *)program_header->p_paddr + program_header->p_filesz,
                       0,
                       program_header->p_memsz - program_header->p_filesz);

            // Comprobacion del punto de entrada
            if (elf_validate_entry_point(header, program_header) != 0 &&
               (program_header->p_flags & PF_X) != 0)
            {
                kernel_entry = (KernelEntryPoint)(uintptr_t)header->e_entry;
            }
        }
    }

    if (kernel_entry != 0)
    {
        kernel_entry();
    }

    halt();
}


// Copia byte a byte el contenido en memoria
void memory_copy(uint8_t *destination, const uint8_t *source, uint32_t size)
{
    for (uint32_t i = 0; i < size; i++)
    {
        destination[i] = source[i];
    }
}


// Establece el contenido en memoria al valor designado
void memory_set(uint8_t *destination, uint8_t value, uint32_t size)
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
