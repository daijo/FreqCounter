# Toolchain setup
CC=avr-gcc
CFLAGS=-Wall -Os -DF_CPU=$(F_CPU) -DBAUD=$(UART_BAUD) -mmcu=$(MCU)
OBJCOPY=avr-objcopy
BIN_FORMAT=ihex
RM=rm -f

# Board setup
MCU=attiny2313
F_CPU=20480000UL
UART_BAUD=9600

# Programmer setup
#PORT=/dev/cuaU0
BAUD=19200
PROTOCOL=usbtiny
PART=t2313#$(MCU)
AVRDUDE=avrdude -F -V

SOURCES=fc.c uart.c
OBJECTS=$(SOURCES:.c=.s)

.PHONY: all
all: fc.hex

fc.hex: fc.elf

fc.elf: $(OBJECTS)

fc.s: fc.c

uart.s: uart.c

.PHONY: clean
clean:
	$(RM) fc.elf fc.hex $(OBJECTS)

.PHONY: upload
upload: fc.hex
	$(AVRDUDE) -c $(PROTOCOL) -p $(PART)  -b $(BAUD) -U flash:w:$< #-P $(PORT)
%.elf: %.s ; $(CC) $(CFLAGS) -s -o $@ $(OBJECTS)

%.s: %.c ; $(CC) $(CFLAGS) -S -o $@ $<

%.hex: %.elf ; $(OBJCOPY) -O $(BIN_FORMAT) -R .eeprom $< $@
