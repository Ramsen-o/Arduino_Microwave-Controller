;
; main.asm
;
; Created: 2024-11-12 2:47:31 PM
; Author: Ramsen Oraha
;

; States
.equ STARTS = 0
.equ IDLES = 1
.equ DATAS = 2
.equ COOKS = 3
.equ SUSPENDS = 4

; Constants
.equ CLOSED = 0
.equ OPEN = 1
.equ ON = 1
.equ OFF = 0
.equ YES = 1
.equ NO = 0
.equ JCTR = 125 ; Joystick centre value

; Port Pins
.equ LIGHT = 7 ; Door Light WHITE LED PORTD pin 7
.equ TTABLE = 6 ; Turntable PORTD pin 6 PWM
.equ BEEPER = 5 ; Beeper PORTD pin 5
.equ CANCEL = 4 ; Cancel switch PORTD pin 4
.equ DOOR = 3 ; Door latching switch PORTD pin 3
.equ STSP = 2 ; Start/Stop switch PORTD pin 2
.equ HEATER = 0 ; Heater RED LED PORTB pin 0

; Global Data
.dseg
cstate: .byte 1 ; Current State
inputs: .byte 1 ; Current input settings
joyx: .byte 1 ; Raw joystick x-axis
joyy: .byte 1 ; Raw joystick y-axis
joys: .byte 1 ; Joystick status bits 0-not centred,1- centred
tascii: .byte 8 ; Reserve 8 bytes for tascii

seconds:
.byte 2 ; Cook time in seconds 16-bit
sec1:
.byte 1 ; minor tick time (100 ms)

.cseg

.org 0x0000

; Interrupt Vector Table	
jmp	start	
jmp	ISR_INT0	; External IRQ0 Handler
jmp	ISR_INT1	; External IRQ1 Handler
jmp	ISR_PCINT0	; PCINT0 Handler
jmp	ISR_PCINT1	; PCINT1 Handler
jmp	ISR_PCINT2	; PCINT2 Handler
jmp	ISR_WDT	; Watchdog Timeout Handler
jmp	ISR_TIM2_COMPA	; Timer2 CompareA Handler
jmp	ISR_TIM2_COMPB	; Timer2 CompareB Handler
jmp	ISR_TIM2_OVF	; Timer2 Overflow Handler
jmp	ISR_TIM1_CAPT	; Timer1 Capture Handler
jmp	ISR_TIM1_COMPA	; Timer1 CompareA Handler
jmp	ISR_TIM1_COMPB	; Timer1 CompareB Handler
jmp	ISR_TIM1_OVF	; Timer1 Overflow Handler
jmp	ISR_TIM0_COMPA	; Timer0 CompareA Handler
jmp	ISR_TIM0_COMPB	; Timer0 CompareB Handler
jmp	ISR_TIM0_OVF	; Timer0 Overflow Handler
jmp	ISR_SPI_STC	; SPI Transfer Complete Handler
jmp	ISR_USART0_RXC	; USART0 RX Complete Handler
jmp	ISR_USART0_UDRE	; USART0,UDR Empty Handler
jmp	ISR_USART0_TXC	; USART0 TX Complete Handler
jmp	ISR_ADC	; ADC Conversion Complete Handler
jmp	ISR_EE_RDY	; EEPROM Ready Handler
jmp	ISR_ANALOGC	; Analog comparator
jmp	ISR_TWI	; 2-wire Serial Handler
jmp	ISR_SPM_RDY	; SPM Ready Handler


jmp start

; Start after interrupt vector table

.org 0xF6

; Dummy Interrupt routines	
ISR_INT0:	; External IRQ0 Handler
ISR_INT1:	; External IRQ1 Handler
ISR_PCINT0:	; PCINT0 Handler
ISR_PCINT1:	; PCINT1 Handler
ISR_PCINT2:	; PCINT2 Handler
ISR_WDT:	; Watchdog Timeout Handler
ISR_TIM2_COMPA:	; Timer2 CompareA Handler
ISR_TIM2_COMPB:	; Timer2 CompareB Handler
ISR_TIM2_OVF:	; Timer2 Overflow Handler
ISR_TIM1_CAPT:	; Timer1 Capture Handler
ISR_TIM1_COMPB:	; Timer1 CompareB Handler
ISR_TIM1_OVF:	; Timer1 Overflow Handler
ISR_TIM0_COMPA:	; Timer0 CompareA Handler
ISR_TIM0_COMPB:	; Timer0 CompareB Handler
ISR_TIM0_OVF:	; Timer0 Overflow Handler
ISR_SPI_STC:	; SPI Transfer Complete Handler
ISR_USART0_RXC:	; USART0 RX Complete Handler
ISR_USART0_UDRE:	; USART0,UDR Empty Handler
ISR_USART0_TXC:	; USART0 TX Complete Handler
ISR_ADC:	; ADC Conversion Complete Handler
ISR_EE_RDY:	; EEPROM Ready Handler
ISR_ANALOGC:	; Analog comparator
ISR_TWI:	; 2-wire Serial Handler
ISR_SPM_RDY: 
reti	; SPM Ready Handler
; Timer1 Interrupt CompareA Handler 
ISR_TIM1_COMPA:
	push r0		;save context of PC
	in r0,SREG	;get status register
	push r0

	;rest of ISR code here
	cbi PORTD,BEEPER

	pop r0	;restore status register
	out SREG,r0
	pop r0
Reti


start:

	ldi r16,HIGH(RAMEND) ; Initialize the stack pointer
	out sph,r16
	ldi r16,LOW(RAMEND)
	out spl,r16

	;initialization calls
	call initPorts
	call initUSART0
	call i2cInit
	call ds1307Init ; <------comment out for debugging purposes
	call anInit
	call initADC


	ldi r24,STARTS ;start state
	sts cstate,r24

	;test by loading seconds with 10
	ldi r16,10
	sts seconds,r16
	ldi r16,0
	sts seconds+1,r16



	rjmp startstate

loop:
	call updateTick ;<------comment out for debugging purposes

;If DOOR open jump to suspend
	sbis PIND,DOOR
	rjmp suspend
	cbi PORTD,LIGHT ;turn off light if door is closed

;CANCEL key pressed?
	sbic PIND,CANCEL
	jmp Stsp0	;jump to check Stsp if cancel is NOT pressed

	cbi PORTD,LIGHT ;turn off light if pressed
	sbi PORTD,BEEPER ;beep if pressed
	call wait_0	;wait until cancel is not pressed, clear beeper, then continue

	jmp idle
	
;Start/Stop key pressed?
Stsp0:
	lds r24,cstate

	sbic PIND,STSP
	jmp ch_joy ;jump to ch_joy if stsp is NOT pressed

	;otherwise if stsp is pressed,
	sbi PORTD,BEEPER ;set beeper
	call wait_1 ;wait until not pressed, then clear beeper and continue

	cpi r24,COOKS ;compare cstate to COOKS, if equal branch to suspend. otherwise continue
	breq suspend

	lds r16,seconds
	lds r17,seconds+1
	add r16,r17
	cpi r16,0
	breq idle	;if cook time is zero, force jump to idle, otherwise jump to cook
	jmp cook	

ch_joy:
	lds r24,cstate ;if we are currently cooking, loop
	cpi r24,COOKS
	breq loop

	cbi PORTB,HEATER ;if we arent cooking, clear the heater
	ldi r16,0x00 ; Turntable off
	out OCR0A,r16

	call joystickinputs ;if joystick is not centred, jump to dataentry, otherwise loop
	cpi r25,0
	breq dataentry

	jmp loop


;idle state
idle:
	ldi r24, IDLES
	sts cstate,r24
	call displayTOD ;display the time of day
	cbi PORTB,HEATER ;turn off heater when idle
	ldi r16,0x00 ; Turntable off
	out OCR0A,r16
	ldi r24,0	;reset cooking time 
	sts seconds,r24
	sts seconds+1,r24
	rjmp loop

;cook state
cook:
	ldi r24,COOKS
	sts cstate,r24
	sbi PORTB,HEATER ;turn on heater when cooking
	ldi r16,0x23 ; Turntable on
	out OCR0A,r16
	rjmp loop

;suspend state
suspend:
	ldi r24,SUSPENDS
	sts cstate,r24
	cbi PORTB,HEATER ;turn off the heater when suspended
	sbis PIND,DOOR
	sbi PORTD,LIGHT ;turn on the light when suspended, and door is closed
	ldi r16,0x00 ; Turntable off
	out OCR0A,r16
	rjmp loop

;data entry state
dataentry:
	ldi r24,DATAS
	sts cstate,r24

	cbi PORTB,HEATER ;clear heater
	cbi PORTD,LIGHT	;clear light
	ldi r16,0x00 ; Turntable off
	out OCR0A,r16

	lds r26,seconds
	lds r27,seconds+1	;load seconds bytes into r27:r26 (upper:lower) bytes
	lds r21,joyx	;load the x-value of joystick into r21
	cpi r21,135	;check if joystick is moved right, if so branch to de1 to add 10 to seconds
	brsh de1

	;the following lines execute if joyx is moved left.
	cpi r27,0
	brne de0	;if upper byte of seconds is not zero, subtract 10 seconds.

	cpi r26,0
	breq de2	;if lower byte is zero,  check again if joystick is centred. if so jump suspend

	cpi r26,10
	brsh de0	;if lower byte is 10, subtract 10

	ldi r26,0	;otherwise load r26 with 0 and jump to suspend
	jmp de2
de0:
	sbiw r27:r26,10
	jmp de2
de1:
	adiw r27:r26,10	
de2:
	sts seconds,r26
	sts seconds+1,r27
	call displayState
	call delay1s
	call joystickinputs
	lds r21,joys
	cpi r21,0
	breq dataentry
	ldi r24,suspends
	sts cstate,r24
	jmp loop

;start state
startstate:
	ldi r24,STARTS
	sts cstate,r24
	ldi r24,0
	sts sec1,r24
	sts seconds,r24
	sts seconds+1,r24
	rjmp loop

	;display state
displaystate:
	call newline
	ldi ZL,LOW(msg1<<1)	;print msg1
	ldi ZH,HIGH(msg1<<1)
	ldi r16,1
	call putsUSART0
	;print msg2 
	ldi ZL,LOW(msg2<<1)
	ldi ZH,HIGH(msg2<<1)
	ldi r16,1
	call putsUSART0
	call displayCookTime
	;print msg3 - current state
	ldi ZL,LOW(msg3<<1)
	ldi ZH,HIGH(msg3<<1)
	ldi r16,1
	call putsUSART0
	lds r17,cstate ;load current state
	call pBCDToASCII
	mov r16,r18
	call putchUSART0 ;output current state	
	ret

;updateTick subroutine to time tasks
updateTick:
	call delay100ms
	lds r22,sec1
	cpi r22,10
	brne ut2

	ldi r22,0
	sts sec1,r22
	;if cstate is 3 (cooking), decrement seconds of cooktime
	lds r16,cstate
	cpi r16,COOKS
	brne ut1

	lds r26,seconds
	lds r27,seconds+1
	inc r26
	sbiw r27:r26,1
	brne ut3

	ldi r23,IDLES
	sts cstate,r23
	cbi PORTB,HEATER
	ldi r16,0x00
	out OCR0A,r16 ;turntable off
	rjmp ut1
ut3:
	sbiw r27:r26,1
	sts seconds,r26
	sts seconds+1,r27
ut1:
	call displaystate
ut2:
	lds r22,sec1
	inc r22
	sts sec1,r22
	ret

	jmp loop

; Save Most Significant 8 bits of Joystick X,Y
joystickInputs:
	ldi r24,0x00 ; Read ch 0 Joystick Y
	call readADCch
	swap r25
	lsl r25
	lsl r25
	lsr r24
	lsr r24
	or r24,r25
	sts joyy,r24
	ldi r24,0x01 ; Read ch 1 Joystick X
	call readADCch
	swap r25
	lsl r25
	lsl r25
	lsr r24
	lsr r24
	or r24,r25
	sts joyx,r24
	ldi r25,0 ; Not centred
	cpi r24,115
	brlo ncx
	cpi r24,135
	brsh ncx
	ldi r25,1 ; Centred
ncx:
	sts joys,r25
	ret

displayTOD:
	;i2c communication

	ldi r25,HOURS_REGISTER ;hours displayer
	call ds1307GetDateTime
	mov r17,r24
	call pBCDToASCII ;convert the hours to ASCII, r17(upper nibble) , r18(lower nibble)
	mov r16,r17
	mov r15,r18
	ldi r17,0
	call anWriteDigit
	ldi r17,1
	mov r16,r15
	call anWriteDigit

	ldi r25,MINUTES_REGISTER ;minutes displayer
	call ds1307GetDateTime
	mov r17,r24
	call pBCDToASCII ;convert the minutes to ASCII, r17(upper nibble) , r18(lower nibble)
	mov r16,r17
	mov r15,r18
	ldi r17,2
	call anWriteDigit
	ldi r17,3
	mov r16,r15
	call anWriteDigit

	ldi r25,SECONDS_REGISTER ;seconds displayer
	call ds1307GetDateTime
	mov r17,r24
	call pBCDToASCII ;convert the seconds to ASCII, r17(upper nibble) , r18(lower nibble)
	mov r16,r17
	call anWriteDigit
	mov r16,r18
	call anWriteDigit
	ret

;display cook time
displayCookTime:
	lds r16,seconds ;load low byte of 'seconds' into r16
	lds r17,seconds+1 ;load high byte of 'seconds' into r16
	call itoa_short	; Converts unsigned integer value of r17:r16 to ASCII string tascii[5]
	sts tascii+5,r16	;clear empty space in tascii
	sts tascii+6,r16
	sts tascii+7,r16
	ldi ZL,LOW(tascii)
	ldi ZH,HIGH(tascii)
	ldi r16,0
	call putsUSART0
	ret

msg1: .db "Ramsen Oraha, Current Time:  ",0
msg2: .db "		Cooking Time:    ",0
msg3: .db "		Current State:   ",0

.include "iopins.asm"
.include "util.asm"
.include "serialio.asm"
.include "adc.asm"
.include "i2c.asm"
.include "rtcds1307.asm"
.include "andisplay.asm"
.exit