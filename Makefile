CC=avr-gcc
CFLAGS=-Wall -Os -DF_CPU=$(F_CPU) -mmcu=$(MCU)
MCU=attiny2313
F_CPU=20480000UL

OBJCOPY=avr-objcopy
BIN_FORMAT=ihex

#PORT=/dev/cuaU0
BAUD=19200
PROTOCOL=usbtiny
PART=t2313#$(MCU)
AVRDUDE=avrdude -F -V

RM=rm -f

.PHONY: all
all: blink.hex

blink.hex: blink.elf

blink.elf: blink.s

blink.s: blink.c

.PHONY: clean
clean:
	$(RM) blink.elf blink.hex blink.s

.PHONY: upload
upload: blink.hex
	$(AVRDUDE) -c $(PROTOCOL) -p $(PART)  -b $(BAUD) -U flash:w:$< #-P $(PORT)
%.elf: %.s ; $(CC) $(CFLAGS) -s -o $@ $<

%.s: %.c ; $(CC) $(CFLAGS) -S -o $@ $<

%.hex: %.elf ; $(OBJCOPY) -O $(BIN_FORMAT) -R .eeprom $< $@
