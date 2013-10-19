#include <avr/io.h>
#include "uart.h"

/* UART pins:
 *  (RXD) PD0
 *  (TXD) PD1
 */

void delay_ms(uint8_t ms) {
	uint16_t delay_count = F_CPU / 20480;
	volatile uint16_t i;

	while (ms != 0) {
		for (i=0; i != delay_count; i++);
			ms--;
	}
}

int main(void) {

	uart_init();
	stdout = &uart_output;
	stdin  = &uart_input;

	puts("Frequency Counter\n");

	DDRD |= _BV(DDD4);

	while (1) {

		puts("Loop Begin\n");

		PORTD ^= _BV(PD4);
		delay_ms(200);
	}
}

