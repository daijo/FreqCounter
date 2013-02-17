;ATtiny2313-20 Freq Counter 26 Nov 2009
;
;cd Desktop/qq-fc-project/
;cd ~/Desktop/Dropbox/w8diz.com/qq-fc-project/fc-code
;avra fc.asm

;avrdude -P usb -p attiny2313 -c avrispv2 -U fc.hex
;avrdude -P usb -p t2313 -c avrispv2 -U fc.hex
;avrdude -P usb -p t2313 -c avrispv2 -U lfuse:w:0xFF:m
;avrdude -P usb -p t2313 -c avrispv2 -U hfuse:w:0x9F:m

.include "ATtiny2313def.inc"

;Define register name
.def fr0  =r2  ;1st byte - low for output
.def fr1  =r3  ;2nd byte
.def fr2  =r4  ;3rd byte
.def fr3  =r5  ;4rd byte - high

.def fr4  =r6  ;1st byte - last count
.def fr5  =r7  ;2nd byte - last count
.def fr6  =r8  ;3rd byte - last count
.def fr7  =r9  ;4th byte - last count

.def fr8  =r10 ;1st byte - current count
.def fr9  =r11  ;2nd byte - current count
.def fr10  =r12  ;3rd byte - current count
.def fr11  =r13  ;4rd byte - current count

.def fready =r15  ;ready flag, 1=ready
.def temp1 =r16
.def temp2 =r17
.def temp3 =r18
.def temp4 =r19
.def temp5 =r20
.def temp6 =r21
.def prescale=r22
.def gate =r23
.def delay =r24
.def  W  =r25
.def	XL	= r26
.def	XH	= r27
.def	YL	= r28
.def	YH	= r29
.def	ZL	= r30
.def	ZH	= r31

.equ PORTLCD =PORTB
.equ DDRLCD =DDRB
.equ PINLCD =PINB

;establish the 74HC4040 prescale factor
.equ PRESCALE0 = 0 ; no prescale
.equ PRESCALE1 = 1 ; div by 2
.equ PRESCALE2 = 2 ; div by 4
.equ PRESCALE_IC = PRESCALE2

;set PRESCALE(value shift) dependent upon GATE time
.equ FULLSECONDGATEPRESCALE = 0
.equ HALFSECONDGATEPRESCALE = 1
.equ QUARTERSECONDGATEPRESCALE = 2
 
.equ FULLSECONDGATE = $C8
.equ HALFSECONDGATE = $64
.equ QUARTERSECONDGATE = $32
;set GATE time
.equ GATETIME = HALFSECONDGATE

;set actual number of shifts to the display data
.equ PRESCALER = HALFSECONDGATEPRESCALE + PRESCALE_IC

.equ NO_OFFSET = 0
.equ POS_OFFSET = 1
.equ NEG_OFFSET = -1
.equ OFFSET = NO_OFFSET

.dseg ;Data segment, SRAM area
.org  $60
FIND:
.byte 10 ;Work area of freq data
.org  $6A
IFO: 
.byte 4  ;IF offset least signif first

.cseg ;This tells the assembler that what follows is code, and goes in ROMspace
.org $000
 rjmp RESET
 reti ; IRQ0
 reti ; IRQ1
 reti ; Timer1 Capture
 reti ; Timer1 Compare
 rjmp TIM1_OVF ; Timer1 Overflow
 rjmp TIM0_OVF ; Timer0 Overflow
 reti ; UART Receive
 reti ; UART empty
 reti ; UART Transmit
 reti ; Analog comparator
 reti ; Pin Change
 reti ; Timer1 Compare B
 reti ; Timer0 Compare A
 reti ; Timer0 Compare B
 reti ; USI Start
 reti ; USI Overflow
 reti ; EEPROM Ready
 reti ; Watchdog Overflow
 
RESET: ;init everything here
 ldi temp1,low(RAMEND)
 out SPL,temp1  ; Set stack pointer to last internal RAM location
 ldi temp1,high(RAMEND)
 out SPH,temp1

 ldi temp1,5  ;set timer0 prescale divisor to 1024
 out TCCR0B,temp1 ;using 20.48 XTAL
 ldi temp1,$82
 out TIMSK,temp1 ;enable TIMER0 & TIMER1 overflow interrupts

 ldi temp1,7   ;External Pin T1, rising edge
 out TCCR1B,temp1

 ldi temp1,0
 out DDRD,temp1 ;set PORTD as inputs
 ldi temp1,$7F
 out PORTD,temp1 ;enable pullup resistors
 
 ldi XH,$00
 ldi XL,GATETIME

 ;init OFFSET
 ldi temp1,$00
 sts $6A,temp1
 ldi temp1,$00
 sts $6B,temp1
 ldi temp1,$4B
 sts $6C,temp1
 ldi temp1,$00
 sts $6D,temp1
 
EI: 
 sei ;global all interrupt enable

 rcall initlcd
 rcall lcdclear
 
 ldi ZH,high(2*msg1)
 ldi ZL,low(2*msg1)
 rcall loadbytes
 ;wait for 1 second (200 * 5mS)
 ldi delay,200
 rcall WaitForDelay 
 
 rcall lcdhome

 ldi temp1,$C0
 rcall lcdcmd

 ldi ZH,high(2*msg2)
 ldi ZL,low(2*msg2)
 rcall loadbytes
 ;wait for 1 second (200 * 5mS)
 ldi delay,200
 rcall WaitForDelay
 
menu: ;main program
 tst fready
 breq menu
 
 ;multiply results by PRESCALER
 ldi prescale,PRESCALER
M0: 
 tst prescale
 breq M1
 lsl fr0
 rol fr1
 rol fr2
 rol fr3
 dec prescale
 rjmp M0

M1: 
 ldi temp1,OFFSET
 tst temp1
 breq M7
 brmi M2

 lds temp1,$6A ;add IF offset
 add fr0,temp1
 lds temp1,$6B
 adc fr1,temp1
 lds temp1,$6C
 adc fr2,temp1
 lds temp1,$6D
 adc fr3,temp1
 rjmp M7

M2: 
 lds temp1,$6A ;subtract IF offset
 sub fr0,temp1
 lds temp1,$6B
 sbc fr1,temp1
 lds temp1,$6C
 sbc fr2,temp1
 lds temp1,$6D
 sbc fr3,temp1
 
M7:
 clr fready

 mov temp1,fr3
 andi temp1,$80
 tst temp1
 breq M9
 com fr3
 com fr2
 com fr1
 neg fr0

M9: 
 rcall BINBCD
 rcall dispfreq
 ldi ZH,high(2*msg3)
 ldi ZL,low(2*msg3)
 rcall loadbytes
 rjmp menu

initlcd:
 ldi temp1,0
 out PORTLCD,temp1 ;turn off any pullup resistors
 ldi temp1,$7F
 out DDRLCD, temp1 ;set LCD port for output
 ldi delay,5   ;wait at least 20ms after Vcc=4.5V
 rcall WaitForDelay
 ldi temp1,3  ;function set
 out PORTLCD,temp1
 rcall ToggleE
 ldi delay,2  ;wait at least 4 ms
 rcall WaitForDelay
 ldi temp1,2  ;function set, 4 line interface
 out PORTLCD,temp1
 rcall ToggleE
 ldi temp1,$70 ;make 4 data lines inputs
 out DDRLCD,temp1
 ldi temp1,$28 ;function set 4-wire, 2-line, 5x7
 rcall lcdcmd
 ldi temp1,$0C ;display on, cursor off, blink off
 rcall lcdcmd
 ldi temp1,$06 ;address inc, no scroll
 rcall lcdcmd
 ret

lcdwait:    ;wait for lcd not busy
 push temp1
 push temp2
 ldi temp1,$F0  ;make 4 data lines input
 out PORTLCD,temp1
 sbi PORTLCD,PB5  ;set r/w to read
 cbi PORTLCD,PB6  ;set register select to command
waitloop:
 nop     ;wait for data setup time
 nop     ;delay 140 ns
 sbi PORTLCD,PB4  ;set E high
 nop     ;delay 250 ns
 nop
 nop
 cbi PORTLCD,PB4  ;set E low
 in  temp2,PINLCD ;read busy flag
 nop
 nop
 nop
 sbi PORTLCD,PB4  ;set E high
 nop     ;delay 250 ns
 nop
 nop
 cbi PORTLCD,PB4
 sbrc temp2,3 ;loop until done
 rjmp waitloop
 pop temp2
 pop temp1
 ret

lcdcmd: ;send cmd in temp1
 mov temp2,temp1
 rcall lcdwait
 ldi temp1,$7F
 out DDRLCD,temp1 ;set LCD port for output
 mov temp1,temp2
 mov temp2,temp1
 swap temp1
 andi temp1,$0F
 out PORTLCD,temp1
 rcall toggleE
 mov temp1,temp2
 andi temp1,$0F  ;strip off upper bits
 out PORTLCD,temp1
 rcall toggleE
 ldi temp1,$70  ;make 4 data lines input
 out DDRLCD,temp1
 ret

lcdput:
 push temp1
 push temp2
 mov temp2,temp1
 rcall lcdwait
 ldi temp1,$7F
 out DDRLCD,temp1 ;set LCD port for output
 mov temp1,temp2
 mov temp2,temp1
 swap temp1
 andi temp1,$0F  ;send upper nibble data
 out PORTLCD,temp1 ;send data to LCD
 sbi PORTLCD,PB6  ;set register select to data
 rcall toggleE
 mov temp1,temp2
 andi temp1,$0F  ;send lower nibble data
 out PORTLCD,temp1 ;send data to LCD
 sbi PORTLCD,PB6  ;set register select to data
 rcall toggleE
 ldi temp1,$70  ;make 4 data lines input
 out DDRLCD,temp1
 pop temp2
 pop temp1
 ret

toggleE:
 nop     ;wait for data setup time
 nop     ;delay 140 ns
 sbi PORTLCD,PB4  ;set E high
 nop     ;delay 450 ns
 nop
 nop
 nop
 nop
 cbi PORTLCD,PB4  ;set E low
 ret

lcdclear:
 ldi temp1,1
 rcall lcdcmd
 ret

lcdhome:
 ldi temp1,2
 rcall lcdcmd
 ret

dispfreq:
 rcall lcdhome
 ldi temp1,$C0
 rcall lcdcmd
 ldi temp2,0
 lds temp1,$67
 cpi temp1,$30
 brne df1
 ldi temp1,' ' ;blank leading zero
 rjmp df2
df1:
 ldi temp2,1
df2:
 rcall lcdput
 lds temp1,$66
 tst temp2
 brne df4
 cpi temp1,$30
 brne df3
 ldi temp1,' ' ;blank leading zero
 rjmp df4
df3:
 ldi temp2,1
df4:
 rcall lcdput
 ldi temp1,','
 tst temp2
 brne df5
 ldi temp1,' ' ;blank leading zero
df5:
 rcall lcdput
 lds temp1,$65
 tst temp2
 brne df8
 cpi temp1,$30
 brne df7
 ldi temp1,' ' ;blank leading zero
 rjmp df8
df7:
 ldi temp2,1
df8:
 rcall lcdput
 lds temp1,$64
 tst temp2
 brne df9
 cpi temp1,$30
 brne df9
 ldi temp1,' ' ;blank leading zero
df9:
 rcall lcdput
 lds temp1,$63
 rcall lcdput
 ldi temp1,'.'
 rcall lcdput
 lds temp1,$62
 rcall lcdput
 lds temp1,$61
 rcall lcdput
 lds temp1,$60
 rcall lcdput

 in temp1,PIND ;get jumper pin settings
 andi temp1,$04 ;mask off OFFSET enable bit
 ldi temp1,' '
 brne df11
 in temp1,PIND ;get jumper pin settings
 andi temp1,$08 ;mask off +/- enable bit
 brne df10
 ldi temp1,'+'
 rjmp df11
df10:
 ldi temp1,'-'
df11:
 rcall lcdput
 ret

loadbytes:
 lpm
 tst r0
 breq bytesloaded
 mov temp1,r0
 rcall lcdput
 adiw ZL,1
 rjmp loadbytes
bytesloaded:
 ret

WaitForDelay:
 tst delay ; changes every 5.0 mSec
 brne WaitForDelay
 ret

EXT_INT0:
 push temp1
 in  temp1,SREG ;save the status register
 out  SREG,temp1 ;restore the status register
 pop  temp1
 reti

EXT_INT1:
 push temp1
 in temp1,SREG
 out SREG,temp1
 pop  temp1
 reti

TIM1_CAPT:
 push temp1
 in temp1,SREG
 out SREG,temp1
 pop  temp1
 reti

TIM1_COMP:
 push temp1
 in temp1,SREG
 out SREG,temp1
 pop  temp1
 reti

TIM1_OVF:
 push temp1
 in temp1,SREG
 inc fr10
 brne TIM1_OVFX
 inc fr11

TIM1_OVFX:
 out SREG,temp1
 pop  temp1
 reti

TIM0_OVF:
 ; gets here every 5 mSec (.048828125 uS * 1024 * 100)
 ;1/20.48mhz = 0.048828125 uS
 ;prescale set to divide by 1024
 ;overflow set to interrupt at 100 count
 push temp1
 push temp2
 in temp1,SREG
 push temp1

 ldi temp1,256-100 ; count
 out TCNT0,temp1 ;set for next overflow

 dec delay	;used for delays only. Has no function with freq counting

 ;dec gate
 sbiw XH:XL,1
 brne TIM0_EXIT

;set gate time (count)
 ldi XH,$00
 ldi XL,GATETIME
 
 in fr8,TCNT1L
 in fr9,TCNT1H

 mov fr0,fr4 ;get last counts
 mov fr1,fr5
 mov fr2,fr6
 mov fr3,fr7

 mov fr4,fr8 ;save current counts
 mov fr5,fr9
 mov fr6,fr10
 mov fr7,fr11

 sub fr8,fr0 ;calculate difference
 sbc fr9,fr1
 sbc fr10,fr2
 sbc fr11,fr3

 mov fr0,fr8 ;move to display regs
 mov fr1,fr9
 mov fr2,fr10
 mov fr3,fr11

 mov fr8,fr4 ;restore current counts
 mov fr9,fr5
 mov fr10,fr6
 mov fr11,fr7

 ldi temp1,1
 mov fready,temp1

TIM0_EXIT:
 pop temp1
 out SREG,temp1
 pop  temp2
 pop  temp1
 reti

BINBCD: ;Convert 3 bytes binary (in fr0,fr1,fr2,fr3) to packed BCD
;ENT fr0,fr1,fr2,fr4
;RET gr0,gr1,gr2,gr3,gr5
;USE Z,W
  ldi W,32 ;4 bytes=32 bits
  mov temp6,W
  clr temp1
  clr temp2
  clr temp3
  clr temp4
  clr temp5
  clr ZH
bbcd1:
	lsl fr0 ;shift 32 bits
  rol fr1
  rol fr2
	rol fr3
  rol temp1
  rol temp2
  rol temp3
  rol temp4
	rol temp5
  dec temp6
  brne bbcd2
;Extract packed-BCD to ASCII and store into FLCD for 10 bytes
  ldi YL,low(FIND) ;LCD indication data buffer
  clr YH  ;Y <-- destination pointer
  ldi ZL,16  ;Z <-- source pointer
  ldi W,5  ;result of 4 bytes, gr0 - gr4.
  mov temp6,W
bbcdl:
	ld W,Z+
  push W
  andi W,$0F
  ori W,$30
  st Y+,W
  pop W
  swap W
  andi W,$0F
  ori W,$30
  st Y+,W
  dec temp6
  brne bbcdl
  ret

bbcd2:
  ldi ZL,21 ;to access gr4, gr3 ... gr0, Z=20+1 for pre-decrement
bbcd3:
  ld W,-Z  ;W <-- gr4,gr3,,gr2,gr1 or gr0
  subi W,-$03  ;W <-- W+$03 for lower nibble
  sbrc W,3  ;3rd bit ?
  st Z,W  ;W(3)=1, store back to gr..
  ld W,Z  ;W <-- gr4,gr3,gr2,gr1 or gr0
  subi W,-$30  ;add $30 for upper nibble
  sbrc W,7  ;MSB of W ?
  st Z,W
  cpi ZL,16  ;=r16=gr0. done from gr4 to gr0 ?
  brne bbcd3
  rjmp bbcd1

msg1:
;    1234567890123456789012345678901234567890
;.db "QQ FC v.02 W8DIZ",0,0
.db "Freq Cntr KC9LIF",0,0
msg2:
.db "kitsandparts.com",0,0
msg3:
.db "Khz  ",0

