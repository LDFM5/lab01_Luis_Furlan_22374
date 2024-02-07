;******************************************************************************
; Universidad del Valle de Guatemala
; Programación de Microcrontroladores
; Proyecto: Lab1 Contador
; Archivo: main.asm
; Hardware: ATMEGA328p
; Created: 30/01/2024
; Author : Luis Furlán
;******************************************************************************
; Encabezado: Contadores binario de 4 bits y suma con carry
;******************************************************************************

.include "M328PDEF.inc"
.cseg //Indica inicio del código
.org 0x00 //Indica el RESET
;******************************************************************************
; Stack
;******************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16 
LDI R17, HIGH(RAMEND)
OUT SPH, R17
;******************************************************************************
; Configuración
;******************************************************************************
Setup:
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 ;HABILITAMOS EL PRESCALER
	LDI R16, 0b0000_0100
	STS CLKPR, R16 ; DEFINIMOS UNA FRECUENCIA DE 1MGHz

	LDI R16, 0x1F ; CONFIGURAMOS LOS PULLUPS en PORTC
	OUT PORTC, R16	; HABILITAMOS EL PULLUPS
	LDI R16, 0b0010_0000 ;CONFIGURAMOS las entradas y salidas en PORTC
	OUT DDRC, R16	;Puertos C (entradas y salidas)

	LDI R16, 0xFF	;CONFIGURAMOS las entradas y salidas en PORTD
	OUT DDRD, R16	;Puertos D (entradas y salidas)
	LDI R16, 0x2F	;CONFIGURAMOS las entradas y salidas en PORTB
	OUT DDRB, R16	;Puertos B (entradas y salidas)

	;Limpiar registros
	CLR R16
	CLR R17
	CLR R18
	CLR R19

Loop:
	;----Chequeo de antirebote----
	MOV R18, R16
	IN R16, PINC
	CP R16, R18
	BREQ Loop
	CALL Delay
	IN R16, PINC
	CP R18, R16
	BREQ Loop
	;------------Menu-------------
	SBRS R16, PC0	;botón 1
	RJMP incrementar
	SBRS R16, PC1	;botón 2
	RJMP decrementar
	SBRS R16, PC2	;botón 3
	RJMP incrementar2
	SBRS R16, PC3	;botón 4
	RJMP decrementar2
	SBRS R16, PC4	;botón 5
	RJMP suma
	RJMP Loop
;******************************************************************************
; Subrutinas (funciones)
;******************************************************************************
incrementar: ; incremento de contador 1
	INC R17 ; incrementa el primer contador
	; si se habilita el bit 4 se reinicia el contador.
	SBRC R17, 4	
	CLR R17
	; se corre el registro para que corresponda a los puertos respectivos de las leds
	MOV R18, R17
	LSL R18
	LSL R18
	OUT PORTD, R18
	; no deja que los bits de la suma sean afectados
	SBRC R20, 1
	SBI PORTD, PD6
	SBRC R20, 2
	SBI PORTD, PD7
	RJMP Loop

;******************************************************************************

incrementar2: ; incremento de contador 2
	INC R19	; incrementa el segundo contador
	; Si el bit 4 está habilitado reinicia el contador
	SBRC R19, 4
	CLR R19
	; muestra el contador en las leds
	OUT PORTB, R19
	; no deja que los bits de la suma ni el carry sean afectados
	SBRC R20, 0
	SBI PORTB, PB4 
	SBRC R22, 0
	SBI PORTB, PB5
	RJMP Loop

;******************************************************************************

decrementar: ; decremento de contador 2
	DEC R17 ; decrementa el primer contador
	; Si el contador pasa de 0 hace que continue con los primero 4 bits encendidos
	CPI R17, 0b1111_1111
	BRNE decr
	LDI R17, 0b0000_1111
decr:
	; se corre el registro para que corresponda a los puertos respectivos de las leds 
	MOV R18, R17
	LSL R18
	LSL R18
	OUT PORTD, R18
	; no deja que los bits de la suma sean afectados
	SBRC R20, 1
	SBI PORTD, PD6 
	SBRC R20, 2
	SBI PORTD, PD7
	RJMP Loop

;******************************************************************************

decrementar2: ; decremento de contador 2
	DEC R19 ; decrementa el segundo contador
	; Si el contador pasa de 0 hace que continue con los primero 4 bits encendidos
	CPI R19, 0b1111_1111
	BRNE decr2
	LDI R19, 0b0000_1111
decr2:
	OUT PORTB, R19
	; no deja que los bits de la suma ni el carry sean afectados
	SBRC R20, 0
	SBI PORTB, PB4
	SBRC R22, 0
	SBI PORTB, PB5
	RJMP Loop

;******************************************************************************

suma:
	MOV R20, R17
	ADD R20, R19
;--------Resta 15 a la suma para ver si hay carry o no----------
	MOV R21, R20
	SUBI R21, 0x0F
	BRBC 2, carry
;--------Si no hay carry----------
	CBI PORTB, PB5
	SBRC R20, 0
	SBI PORTB, PB4
	SBRS R20, 0
	CBI PORTB, PB4
	SBRC R20, 1
	SBI PORTD, PD6
	SBRS R20, 1
	CBI PORTD, PD6
	SBRC R20, 2
	SBI PORTD, PD7
	SBRS R20, 2
	CBI PORTD, PD7
	SBRC R20, 3
	SBI PORTC, PC5
	SBRS R20, 3
	CBI PORTC, PC5
	LDI R22, 0x00
	RJMP Loop
;--------Si hay carry----------
carry:
	SBI PORTB, PB5
	LDI R22, 0x01
	SBRC R21, 0
	SBI PORTB, PB4
	SBRS R21, 0
	CBI PORTB, PB4
	SBRC R21, 1
	SBI PORTD, PD6
	SBRS R21, 1
	CBI PORTD, PD6
	SBRC R21, 2
	SBI PORTD, PD7
	SBRS R21, 2
	CBI PORTD, PD7
	SBRC R21, 3
	SBI PORTC, PC5
	SBRS R21, 3
	CBI PORTC, PC5
	MOV R20, R21
	RJMP Loop

;******************************************************************************

delay:
	LDI R16, 100
Ldelay:
	DEC R16
	BRNE Ldelay ; Se repite si no es igual a 0
	RET