;-----------------------------------------------
; Universidad del Valle de Guatemala
; IE2023: Programacion de Microcontroladores
; Laboratorio3.asm

; Autor: Alma Mata Ixcayau
; Proyecto: Laboratorio 3. Interrupciones
; Descripcion: Contador binario de 4 bits que cambia con interrupciones.
; Hardware: ATMEGA328P
; Creado: 20/02/2025
; Ultima modificacion: --
;-----------------------------------------------

// Encabezado. Define registros, variables y constantes.
.include "M328PDEF.inc"
// Variables en SRAM
.dseg
.org	SRAM_START
CONTADOR:	.byte	1		// Guarda el contador en la SRAM
// Código FLASH
.cseg
.org	0x0000
	RJMP	SETUP
.org	PCI1addr			// Pin Change Interrupt PORT C
	RJMP	CONTADOR_4BITS

SETUP:
	CLI			// Deshabilita interrupciones globales
	// Configuración de la PILA
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16
	// CONFIGURACIÓN DE ENTRADAS Y SALIDAS
	// Configuración PORT C como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRC, R16		// Activa al PORTC como entrada
	LDI		R16, (1 << PC0) | (1 << PC1)
	OUT		PORTC, R16		// Habilita pull-ups
	// Configuración PORT B como salida inicialmente apagada
	LDI		R16, 0x0F
	OUT		DDRB, R16		// Activa los 4 bits menos significativos como salidas
	LDI		R16, 0x00
	OUT		PORTB, R16		// Apaga la salida
	// CONFIGURACION DE INTERRUPCIONES
	LDI		R16, (1 << PCIE1)
    STS		PCICR, R16				// Habilita interrupciones en PORTC
    LDI		R16, (1 << PCINT8) | (1 << PCINT9)
    STS		PCMSK1, R16				// Habilita interrupciones en PC0 y PC1

    ; Inicialización del contador
    LDI		R16, 0x00
    STS		CONTADOR, R16

    SEI		// Habilita interrupciones globales

MAIN:
	RJMP	MAIN		// Bucle principal

CONTADOR_4BITS:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	IN		R16, PINC
	LDS		R17, CONTADOR
	SBRS	R16, 0
	INC		R17
	SBRS	R16, 1
	DEC		R17
	ANDI	R17, 0x0F
	STS		CONTADOR, R17
	OUT		PORTB, R17

	POP		R16
	OUT		SREG, R16
	POP		R16

	RETI