#include <avr/io.h>

#define LED PD4

#define output_low(port,pin) port &= ~(1<<pin)
#define output_high(port,pin) port |= (1<<pin)
#define set_input(portdir,pin) portdir &= ~(1<<pin)
#define set_output(portdir,pin) portdir |= (1<<pin)

void delay_ms(uint8_t ms) {
	uint16_t delay_count = F_CPU / 20480;
	volatile uint16_t i;

	while (ms != 0) {
		for (i=0; i != delay_count; i++);
			ms--;
	}
}

int main(void) {
	set_output(DDRD, LED);  

	while (1) {
		output_high(PORTD, LED);
		delay_ms(200);
		output_low(PORTD, LED);
		delay_ms(200);
	}
}
