#include "idt.h"

extern void isr0(void);

static IdtEntry idt[IDT_ENTRIES];

void idt_set_gate(
    uint8_t vector,
    void (*handler)(void),
    uint16_t selector,
    uint8_t type_attributes
)
{
    uint32_t address = (uint32_t)(uintptr_t)handler;

    idt[vector].offset_low = address & 0xFFFF;
    idt[vector].selector = selector;
    idt[vector].reserved = 0;
    idt[vector].type_attributes = type_attributes;
    idt[vector].offset_high = (address >> 16) & 0xFFFF;
}

void idt_init(void)
{
    IdtDescriptor descriptor;

    descriptor.limit = sizeof(idt) - 1;
    descriptor.base = (uint32_t)(uintptr_t)idt;

    idt_set_gate(0, isr0, 0x08, 0x8E);

    __asm__ volatile ("lidt %0" : : "m"(descriptor));
}