FreqCounter
===========

C code for W8DIZ's <http://www.kitsandparts.com/freqctr2.php> frequency counter board.

Features
--------

* Blink led on PD4.
* Standard in and out via UART (RX/PD0 - TX/PD1).

Backlog
-------

* Count pulses on PD5.

Dependecies
-----------

* Free Software toolchain for the Atmel AVR microcontrollers <http://www.nongnu.org/avr-libc/>.
* A AVR programmer like the USBtinyISP <http://www.ladyada.net/make/usbtinyisp/>.

Reference
---------

* Original asm implementation in ref/ <http://www.kitsandparts.com/freqctr2.php>
* ATtiny2313 reference <http://www.atmel.com/images/doc2543.pdf>
