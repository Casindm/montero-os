#include "idt.h"

void print_message(const char *message);
void exception_divide_by_zero(void);
void halt(void);

int global_counter = 10;
int global_status;

static const char kernel_name[] = "MonteroOS";

void kernel_main(void)
{
    idt_init();
    print_message("Hola desde nuestro primer kernel en C!");

    halt();
}

void print_message(const char *message) 
{
    volatile unsigned short *video = (volatile unsigned short *)0xB8000;

    for (unsigned int i = 0; message[i] != '\0'; i++) {
        video[i] = (0x0F << 8) | (unsigned char)message[i];
    }
}

void exception_divide_by_zero(void)
{
    print_message("EXCEPTION: Division By Zero");
    halt();
}

void halt(void)
{
    while (1) {
        __asm__ volatile ("hlt");
    }
}
