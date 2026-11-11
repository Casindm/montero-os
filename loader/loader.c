void loader_main(void)
{
    const char *message = "Loader ejecutado!";
    volatile unsigned short *video = (volatile unsigned short *)0xB8000;

    for (unsigned int i = 0; message[i] != '\0'; i++) {
        video[i] = (0x0F << 8) | (unsigned char)message[i];
    }

    while (1) {
        __asm__ volatile ("hlt");
    }
}

