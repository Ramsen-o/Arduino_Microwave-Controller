/*
 * rtcds1307.asm
 *
 *  Created: 2024-11-12 3:13:02 PM
 *  Author: Ramsen Oraha
 */ 

 ;Constants
.equ RTCADR = 0xd0
.equ SECONDS_REGISTER = 0x00
.equ MINUTES_REGISTER = 0x01
.equ HOURS_REGISTER = 0x02
.equ DAYOFWK_REGISTER = 0x03
.equ DAYS_REGISTER = 0x04
.equ MONTHS_REGISTER = 0x05
.equ YEARS_REGISTER = 0x06
.equ CONTROL_REGISTER = 0x07
.equ RAM_BEGIN = 0x08
.equ RAM_END = 0x3F

;initialize ds1307
ds1307Init:
	ldi r23,RTCADR ; RTC Setup
	call i2cStart
	ldi r23,RTCADR ; Initialize DS1307
	ldi r25,CONTROL_REGISTER
	ldi r22,0x00
	call i2cWriteRegister

	ldi r25,HOURS_REGISTER
	ldi r22,0x01 ;set hours_register to 1
	call i2cWriteRegister

	ldi r25, MINUTES_REGISTER
	ldi r22,0x00 ;set minutes_register to 0
	call i2cWriteRegister

	ldi r25,SECONDS_REGISTER
	ldi r22,0x00
	call i2cWriteRegister

	ret

; r23 RTC Address, r25 ds1307 Register, Return Data r24
ds1307GetDateTime:
	ldi r23,RTCADR
	call i2cReadRegister
	ret