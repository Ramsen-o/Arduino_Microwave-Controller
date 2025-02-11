/* serialio.asm
*
* Created: 2024-11-04 6:14:19 PM
* Author: Ramsen Oraha
*/

; Initializes the USART0 to operate in asynchronous mode with baud rate set to
; 9600. The USART0 is configured to transmit and receive 8-bit data.
; Initializes the USART0 to operate in asynchronous mode with baud rate set to
; 9600. The USART0 is configured to transmit and receive 8-bit data.
initUSART0:
ldi r20,0 ; set baud rate to 9600 with fOSC = 16MHz
sts UBRR0H,r20 ; "
ldi r20,0x67 ; "
sts UBRR0L,r20 ; "

ldi r20,0x18 ; enable transmitter (TXEN), receiver (RXEN), 8-bit data
sts UCSR0B,r20 ; "
ldi r20,0x06 ; asynchronous USART, disable parity
sts UCSR0C,r20 ; "
ret

; Outputs the character passed in r16 to MEGA device USART0
; using the polling method. The character is less than 9 bits.
putchUSART0:
lds r20,UCSR0A ; make sure data register is empty before
sbrs r20,UDRE0 ; outputting the character
rjmp putchUSART0 ; "
sts UDR0,r16 ; output the character (less than 9 bits)
ret
;Reading data uses a similar method polling the RXC0 bit (Bit 7) of the UCSR0A register to see
;if there is a
;character input into the data register UDR0. Add the following routine to your serialio.asm file to
;read a
;character:
; Reads a character from the USART0 module of the MEGA device using
; the polling method. The character is returned in r22.
getchUSART0:
lds r20,UCSR0A ; is there any data to be read?
sbrs r20,RXC0 ; "
rjmp getchUSART0 ; "
lds r22,UDR0 ; fetch the received character
ret
;New line subroutine
newline:
.equ CR=0x0D
.equ LF=0x0A
ldi r16, CR
call putchUSART0
ldi r16, LF
call putchUSART0
ret

; Outputs a string pointed to by Z to USART0. The string is stored in
; program memory or data memory. r16 indicates if the string is in program memory (=1)
; or data memory (=0).

putsUSART0:
cpi r16,1 ; is string in program memory?
breq pstr ; "
dstr:
ld r16,z+ ; string is in data memory
cpi r16,0
breq done ; reach the end of string?
rcall putchUSART0 ; output the next character
rjmp dstr
pstr:
lpm r16,z+ ; string is in program memory
cpi r16,0
breq done ; reach the end of string?
rcall putchUSART0 ; output the next character
rjmp pstr
done:
ret

; Reads a string from the USART0 of the MEGA device using the polling
; method by continuously calling putchUSART0 until the carriage return (CR) character is
; encountered. Register X points to the buffer that holds the received string.
getsUSART0:
.equ enter = 0x0D
ragain:
rcall getchUSART0
cpi r22,enter ; is it an enter character?
brne cont
ldi r19,0
st X,r19 ; terminate the string with a NULL character
ret
cont:
st X,r22 ; save the character in the buffer
mov r16,r22 ; copy r22 to r16
rcall putchUSART0 ; echo the character to USART0
cpi r22,0x08 ; is it a backspace character?
brne notBS
dec XL ; decrement the X pointer
sbci XH,0 ; "
ldi r16,0x20 ; output a space character
rcall putchUSART0 ; "
ldi r16,0x08 ; output a backspace character
rcall putchUSART0 ; "
rjmp ragain
notBS:

inc XL ; increment X pointer
ldi r20,0 ; "
adc XH,r20 ; "
rjmp ragain
ret