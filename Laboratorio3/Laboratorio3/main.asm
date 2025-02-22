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
.org	OVF0addr
	RJMP	CONTADOR_DISPLAY
.def contador_ciclos = R20
.def CONTADOR7 = R21
.def SALIDA7 = R22
// Tabla de valores del display de 7 segmentos
Tabla7seg: .db 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10
SETUP:
	CLI			// Deshabilita interrupciones globales
	// Configuración de la PILA
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16
	// Configuración del PRESCALER
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16				// Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16				// Configurar Prescaler a 16 F_cpu = 1MHz
	// INICIA TEMPORIZADOR
	LDI		R16, (1 << CS01) | (1 << CS00)  // Prescaler es 64
	OUT		TCCR0B, R16
	LDI		R16, 60							// Valor inicial del TCNT0
	OUT		TCNT0, R16
	// HABILITAR INTERRUPCIONES DEL TOV0
	LDI		R16, (1 << TOIE0)			// Habilita interrupciones por desbordamiento
	STS		TIMSK0, R16
	// CONFIGURACIÓN DE ENTRADAS Y SALIDAS
	// Configuración PORT C como entrada con pull-up habilitado
	LDI		R16, 0x00
	OUT		DDRC, R16				// Activa al PORTC como entrada
	LDI		R16, (1 << PC0) | (1 << PC1)
	OUT		PORTC, R16				// Habilita pull-ups
	// Configuración PORT B como salida inicialmente apagada
	LDI		R16, 0x0F
	OUT		DDRB, R16				// Activa los 4 bits menos significativos como salidas
	LDI		R16, 0x00
	OUT		PORTB, R16				// Apaga la salida
	// Configuración PORT D como salida inicialmente apagada
	LDI		R16, 0xFF
	OUT		DDRD, R16				// Activa los bits como salida
	LDI		R16, 0x40
	OUT		PORTD, R16				// Muestra "0" en el display
	// CONFIGURACION DE INTERRUPCIONES
	LDI		R16, (1 << PCIE1)
    STS		PCICR, R16				// Habilita interrupciones en PORTC
    LDI		R16, (1 << PCINT8) | (1 << PCINT9)
    STS		PCMSK1, R16				// Habilita interrupciones en PC0 y PC1

    ; Inicialización del contador
    LDI		R16, 0x00
    STS		CONTADOR, R16
	LDI		CONTADOR7, 0x00
	LDI		contador_ciclos, 0x00

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

CONTADOR_DISPLAY:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	
	INC		contador_ciclos
	CPI		contador_ciclos, 100
	BRNE	SALIDA_DISPLAY
	CLR		contador_ciclos
	INC		CONTADOR7
	CPI		CONTADOR7, 0x0A
	BRNE	SALIDA_DISPLAY
	CLR		CONTADOR7
SALIDA_DISPLAY:
	LDI		ZH, HIGH(Tabla7seg<<1)	// Parte alta de Tabla7seg que esta en la Flash
	LDI		ZL, LOW(Tabla7seg<<1)	// Parte baja de la tabla
	ADD		ZL, CONTADOR7			// Suma el contador al puntero Z
	LPM		SALIDA7, Z				// Copia el valor del puntero
	OUT		PORTD, SALIDA7			// Muestra la salida en PORT B

	POP		R16
	OUT		SREG, R16
	POP		R16

	RETI