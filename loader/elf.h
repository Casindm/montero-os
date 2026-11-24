#ifndef ELF_H
#define ELF_H

#define ELF_MAGIC_0 0x7F
#define ELF_MAGIC_1 'E'
#define ELF_MAGIC_2 'L'
#define ELF_MAGIC_3 'F'

#define ELFCLASS32 1
#define ELFDATA2LSB 1
#define EV_CURRENT 1

#define ET_EXEC 2
#define EM_386 3

#define EI_CLASS 4
#define EI_DATA 5
#define EI_VERSION 6

#define PT_LOAD 1

#define PF_X 1
#define PF_W 2
#define PF_R 4

#define KERNEL_ELF_SIZE 32768
#define KERNEL_MIN_ADDR 0x20000
#define KERNEL_MAX_ADDR 0x80000

#include <stdint.h>

typedef struct {
    uint8_t  e_ident[16];

    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint32_t e_entry;
    uint32_t e_phoff;
    uint32_t e_shoff;
    uint32_t e_flags;

    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
} Elf32Header;

typedef struct {
    uint32_t p_type;
    uint32_t p_offset;
    uint32_t p_vaddr;
    uint32_t p_paddr;
    uint32_t p_filesz;
    uint32_t p_memsz;
    uint32_t p_flags;
    uint32_t p_align;
} Elf32ProgramHeader;

typedef void (*KernelEntryPoint)(void);

// Devuelve 1 si es un ELF32 valido para i386
// En caso contrario devuelve 0
static inline int elf_validate_header(Elf32Header *header)
{
// Que el header apunte a una direccion valida
    if (header == 0)
    {
        return 0;
    }

// Que la firma mágica sea correcta
    if (header->e_ident[0] != ELF_MAGIC_0 ||
        header->e_ident[1] != ELF_MAGIC_1 ||
        header->e_ident[2] != ELF_MAGIC_2 ||
        header->e_ident[3] != ELF_MAGIC_3 ) 
    {
        return 0;
    }

// Que el archivo sea ELF32
    if (header->e_ident[EI_CLASS] != ELFCLASS32)
    {
        return 0;
    }

// Que utilice little endian
    if (header->e_ident[EI_DATA] != ELFDATA2LSB)
    {
        return 0;
    }

// Que las versiones sean las esperadas
    if (header->e_ident[EI_VERSION] != EV_CURRENT ||
        header->e_version != EV_CURRENT)
    {
        return 0;
    }

// Que se corresponda con el tipo EXEC
    if (header->e_type != ET_EXEC)
    {
        return 0;
    }

// Que sea un ejecutable para Intel 80386
    if (header->e_machine != EM_386)
    {
        return 0;
    }

// Que el tamaño declarado del ELF Header coincida con nuestra estructura
    if (header->e_ehsize != sizeof(Elf32Header))
    {
        return 0;
    }

// Que el tamaño declarado de cada Program Header coincida con nuestra estructura
    if (header->e_phentsize != sizeof(Elf32ProgramHeader))
    {
        return 0;
    }

// Que exista al menos un Program Header
    if (header->e_phnum == 0)
    {
        return 0;
    }

// Que el inicio del Program Header este dentro del espacio resrvado al ELF
    if (header->e_phoff > KERNEL_ELF_SIZE)
    {
        return 0;
    }

// Que la longitud de todos los segmentos esten incluidos en el espacio reservado
    if (header->e_phnum > (KERNEL_ELF_SIZE - header->e_phoff) / header->e_phentsize)
    {
        return 0;
    }

    return 1;
}


// Devuelve 1 si el segmento se ha formado correctamente
// En caso contrario devuelve 0
static inline int elf_validate_program_header(
    Elf32Header *header,
    Elf32ProgramHeader *program_header)
{
// Que ninguno de los punteros sea nulo
    if (header == 0 || program_header == 0)
    {
        return 0;
    }

// Que FileSiz no sea mayor que MemSiz
    if (program_header->p_filesz > program_header->p_memsz)
    {
        return 0;
    }

// Que el inicio del segmento este dentro del espacio reservado para el ELF
    if (KERNEL_ELF_SIZE < program_header->p_offset)
    {
        return 0;
    }

// Que el contenido del segmento no exceda el tamaño reservado para el ELF
    if ((KERNEL_ELF_SIZE - program_header->p_offset) < program_header->p_filesz)
    {
        return 0;
    }

// Que la dirección de carga no exceda el limite establecido para el Kernel
    if (KERNEL_MAX_ADDR < program_header->p_paddr)
    {
        return 0;
    }

// Que el espacio de memoria este dentro del designado para el Kernel
    if (KERNEL_MIN_ADDR > program_header->p_paddr ||
       (KERNEL_MAX_ADDR - program_header->p_paddr) < program_header->p_memsz)
    {
        return 0;
    }

// Que la paginacion este desactivada
    if (program_header->p_vaddr != program_header->p_paddr)
    {
        return 0;
    }

    return 1;
}


// Comprueba que el punto de entrada del ELF se encuentre
// en el segmento designado
static inline int elf_validate_entry_point(
    Elf32Header *header, 
    Elf32ProgramHeader* program_header)
{
// Que el punto de entrada este dentro del segmento
    if (header->e_entry < program_header->p_vaddr)
    {
        return 0;
    }

// Que el punto de entrada no exceda el espacio definido del segmento
    if (header->e_entry - program_header->p_vaddr >= program_header->p_memsz)
    {
        return 0;
    }

    return 1;
}


static inline Elf32ProgramHeader *
elf_get_program_headers(Elf32Header *header)
{
    if (header == 0) {
        return 0;
    } 

    uint8_t *elf = (uint8_t *)header;

    return (Elf32ProgramHeader *)(elf + header->e_phoff);
}


static inline Elf32ProgramHeader *
elf_get_program_header(Elf32Header *header, uint32_t index)
{
    if (header == 0 || index >= header->e_phnum) {
        return 0;
    } 

    Elf32ProgramHeader *program_headers =
        elf_get_program_headers(header);

    return &program_headers[index];
}

_Static_assert(sizeof(Elf32Header) == 52, "Invalid ELF header size");
_Static_assert(sizeof(Elf32ProgramHeader) == 32, "Invalid ELF program header size");

#endif
