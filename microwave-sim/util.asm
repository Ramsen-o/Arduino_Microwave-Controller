/*
* util.asm
*
* Created: 2024-10-04 6:14:03 PM
* Author: Ramsen Oraha
*/

delay100ms:

ldi r18, 0xFF ; 255
ldi r24, 0xE1 ; 225
ldi r25, 0x04 ;

d100:

subi r18, 0x01 ; 1
sbci r24, 0x00 ; 0
sbci r25, 0x00 ; 0
brne d100
ret
; Packed BCD To ASCII
; Number to convert in r17
; Converted output in r17 (upper nibble),r18 (lower nibble)
pBCDToASCII:

mov r18,r17
andi r18, 0x0F
ori r18, 0x30
swap r17
andi r17, 0x0F
ori r17, 0x30
ret

; Byte To Hexadecimal ASCII
; Number to convert in r17
; Converted output in r17 (lower nibble),r18 (upper nibble)
byteToHexASCII:
mov r18,r17
andi r17, 0x0F
ldi r16, 0x30
cpi r17, 10
brlo b1
ldi r16, 0x37
b1:
Add r17,r16
swap r18

andi r18,0x0F
ldi r16,0x30
cpi r18,10
brlo b2
ldi r16, 0x37
b2:
add r18,r16
ret

; 1 Second Delay
delay1s:
ldi r20,64
d1: ldi r21,200
d2: ldi r22,250
d3:
nop
nop
dec r22
brne d3
dec r21
brne d2
dec r20
brne d1
ret

; Converts unsigned integer value of r17:r16 to ASCII string tascii[5]
itoa_short:
	ldi zl,low(dectab*2) ; pointer to 10^x power compare value
	ldi zh,high(dectab*2)
	ldi xl,low(tascii) ; pointer to array to store string
	ldi xh,high(tascii)
itoa_lext:
	ldi r18,'0'-1 ; (ASCII 0) -1
	lpm r2,z+ ; load 10^x word, point to next
	lpm r3,z+
itoa_lint:
	inc r18 ; start with '0' ASCII
	sub r16,r2 ; (## - 10^x
	sbc r17,r3
	brsh itoa_lint
	add r16,r2 ; if negative reconstruct
	adc r17,r3
	st x+,r18 ; save 1/10^x count, point to next location to save
	lpm ; read last ZX pointed at from 10^x table in (r0)
	tst r0 ; LAST WORD YET?=0x00
	brne itoa_lext
	ret
		
dectab: .dw 10000,1000,100,10,1,0