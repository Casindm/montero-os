#ifndef IDT_H
#define IDT_H

#define IDT_ENTRIES 256

#include <stdint.h>

typedef struct
{
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  reserved;
    uint8_t  type_attributes;
    uint16_t offset_high;
} __attribute__((packed)) IdtEntry;

typedef struct
{
    uint16_t limit;
    uint32_t base;
} __attribute__((packed)) IdtDescriptor;

void idt_init(void);

void idt_set_gate(
    uint8_t vector,
    void (*handler)(void),
    uint16_t selector,
    uint8_t type_attributes
);

_Static_assert(sizeof(IdtEntry) == 8, "IdtEntry must be 8 bytes");
_Static_assert(sizeof(IdtDescriptor) == 6, "IdtDescriptor must be 6 bytes");

#endif