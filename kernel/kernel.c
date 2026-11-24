void print_message(const char *message);
void halt(void);

int global_counter = 10;
int global_status;

static const char kernel_name[] = "MonteroOS";

void kernel_main(void)
{
    const char *message = "Hola desde nuestro primer kernel en C!";
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
