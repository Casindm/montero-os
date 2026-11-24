# Toolchain
NASM := nasm
CC := i686-elf-gcc
LD := i686-elf-ld
OBJCOPY := i686-elf-objcopy

# Directorio de construcción
BUILD := build

# Opciones de compilación C
CFLAGS := -m32 -std=gnu11 -ffreestanding -fno-pie -fno-pic \
          -fno-stack-protector -fno-builtin \
          -Wall -Wextra -O0

# Tamaños máximos
BOOT_SIZE := 512
LOADER_SIZE := 2048
KERNEL_SIZE := 32768

.PHONY: all clean

# Objetivo por defecto
all: $(BUILD)/os-image.bin

# BOOT
$(BUILD)/boot.bin: boot/boot.asm | $(BUILD)
	$(NASM) -f bin $< -o $@
	@if [ "$$(wc -c < $@ | tr -d '[:space:]')" -ne $(BOOT_SIZE) ]; then \
		echo "ERROR: El Boot Sector debe ocupar exactamente $(BOOT_SIZE) bytes"; \
		rm -f $@; \
		exit 1; \
	fi

# LOADER
$(BUILD)/loader_entry.o: loader/entry.asm | $(BUILD)
	$(NASM) -f elf32 $< -o $@

$(BUILD)/loader.o: loader/loader.c loader/elf.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/loader.elf: $(BUILD)/loader_entry.o $(BUILD)/loader.o loader/linker.ld
	$(LD) -m elf_i386 -T loader/linker.ld -o $@ \
		$(BUILD)/loader_entry.o $(BUILD)/loader.o

$(BUILD)/loader.bin: $(BUILD)/loader.elf
	$(OBJCOPY) -O binary $< $@
	@size=$$(wc -c < $@ | tr -d '[:space:]'); \
	if [ "$$size" -gt $(LOADER_SIZE) ]; then \
		echo "ERROR: El Loader supera $(LOADER_SIZE) bytes"; \
		rm -f $@; \
		exit 1; \
	fi
	truncate -s $(LOADER_SIZE) $@

# KERNEL
$(BUILD)/kernel_entry.o: kernel/entry.asm | $(BUILD)
	$(NASM) -f elf32 $< -o $@

$(BUILD)/kernel.o: kernel/kernel.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/kernel.elf: $(BUILD)/kernel_entry.o $(BUILD)/kernel.o kernel/linker.ld
	$(LD) -m elf_i386 -T kernel/linker.ld -o $@ \
		$(BUILD)/kernel_entry.o $(BUILD)/kernel.o
	@size=$$(wc -c < $@ | tr -d '[:space:]'); \
	if [ "$$size" -gt $(KERNEL_SIZE) ]; then \
		echo "ERROR: El Kernel ELF supera $(KERNEL_SIZE) bytes"; \
		rm -f $@; \
		exit 1; \
	fi
	truncate -s $(KERNEL_SIZE) $@

# OS IMAGE
$(BUILD)/os-image.bin: $(BUILD)/boot.bin $(BUILD)/loader.bin $(BUILD)/kernel.elf
	cat $^ > $@

# BUILD DIRECTORY
$(BUILD):
	mkdir -p $@

# CLEAN
clean:
	rm -rf $(BUILD)
