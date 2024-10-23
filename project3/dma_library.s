; TEXT
	.text
	.global timer_interrupt_init
	.global dma_RGB_init

; DATA OFFSETS
U0FR: 		.equ 0x18				; UART0 Flag Register
CLK: 		.equ 0x608				; Clock Offset
DIR: 		.equ 0x400				; Data Direction Offset (Input/Output)
DEN: 		.equ 0x51C				; Digital Enable Offset
DATA: 		.equ 0x3FC				; Data Register (LOW/HIGH)
PUR:		.equ 0x510				; Pull-up Register
EN0: 		.equ 0x100				; Interrupt Enable Register
UARTIM:		.equ 0x038				; UART Interrupt Mask Register
UARTICR:	.equ 0x044				; UART Interrupt Clear Register
GPIOIS:		.equ 0x404				; GPIO Interrupt Sense Register (Edge Sensitivity)
GPIOIBE:	.equ 0x408				; GPIO Interrupt Both Edges Register
GPIOIV:		.equ 0x40C				; GPIO Interrupt Event Register (On Press[LOW] = 0, On Release[HIGH] = 1)
GPIOIM:		.equ 0x410				; GPIO Interrupt Mask Register
GPIOICR:	.equ 0x41C				; GPIO Interrupt Clear Register
RCGCTIMER:  .equ 0x604				; Connect clock to timer
GPTMCTL: 	.equ 0x00C				; Clock enable/disable
GPTMTAMR:	.equ 0x004				; Periodic mode
GPTMTAILR:	.equ 0x028				; Interval period
GPTMIMR:	.equ 0x018				; Allow Timer to Interrupt
GPTMICR:	.equ 0x024				; Timer Interrupt Clear Register


;TIMER INTERRUPT INITIALIZATION (.25s second interval)
timer_interrupt_init:
	PUSH {r4-r12, lr}

	; provide clock for timer 0
	MOV r4, #0xE000
	MOVT r4, #0x400F				; Set r4 = RCGCTIMER
	LDRB r5, [r4, #RCGCTIMER]		; Load byte from RCGCTIMER.
	ORR r5, r5, #0x01				; Set bit 0 of RCGCTIMER.
	STRB r5, [r4, #RCGCTIMER]		; Store new data back into register.

	; disable clock during setup
	MOV r4, #0x0000
	MOVT r4, #0x4003				; Set r4 = GPTMCTL
	LDRB r5, [r4, #GPTMCTL]			; Load byte from Clock enable/disable register
	AND r5, r5, #0xFE				; Clear bit 0 to disable.
	STRB r5, [r4, #GPTMCTL]			; Store new data back into register.

	; set to config 0
	LDRB r5, [r4]					; Load byte from from Timer Configuration Register
	AND r5, r5, #0xF8				; Clear bits 2:0 for configuration 0.
	STRB r5, [r4]					; Store new data back into register.

	; set to periodic mode
	LDRB r5, [r4, #GPTMTAMR]		; Load byte from Timer Mode Register
	AND r5, r5, #0xFE				; Clear bit 0.
	ORR r5, r5, #0x02				; Set bit 1. '10' = 2 for Periodic Mode
	STRB r5, [r4, #GPTMTAMR]		; Store new data back into register.

	; set timer interval
	MOV r5, #0x0900					; Set interval value for 4 million, or .25s
	MOVT r5, #0x003D
	STR r5, [r4, #GPTMTAILR]		; Store new data back into Interval Period Register.

	; allow timer interrupts
	LDRB r5, [r4, #GPTMIMR]			; Load byte from Allow Timer to Interrupt Register
	ORR r5, r5, #0x01				; Set bit 0.
	STRB r5, [r4, #GPTMIMR]			; Store new data back into register.

	; enable interrupts processor side
	MOV r4, #0xE000
	MOVT r4, #0xE000				; Set r4 = Interrupt Enable base address.
	LDR r5, [r4, #EN0]				; Load byte of Interrupt Enable Register.
	MOV r6, #0x0000
	MOVT r6, #0x0008
	ORR r5, r5, r6					; Set Timer0A Bit 19 (0x00080000).
	STR r5, [r4, #EN0]				; Store new data back into register.

	; enable timer
	MOV r4, #0x0000
	MOVT r4, #0x4003				; Set r4 = GPTMCTL
	LDRB r5, [r4, #GPTMCTL]			; Load byte from Clock enable/disable register
	ORR r5, r5, #0x01				; Set bit 0 to enable.
	STRB r5, [r4, #GPTMCTL]			; Store new data back into register.

	POP {r4-r12, lr}
	MOV pc, lr


;SUBROUTINE - dma_RGB_init
dma_RGB_init:
	PUSH {r4-r12,lr}

	; enable clock for gpio port F
	mov r0, #0xE000
	movt r0, #0x400F			; base address for gpio clock control
	mov r1, #0x20				; port f bin
	strb r1, [r0, #CLK]		; store pin 5 to enable clock for port f

	; set pins 1-3 RGB pins to outputs - allows you to drive the value
    mov r0, #0x5000
    movt r0, #0x4002			; r0 set as Port F base address.
    ldrb r4, [r0, #DIR]			; Load Port F Direction Pin Data.
    orr r4, r4, #0x0E			; ORR 0x0E with Direction Pin Data to set Pins 1-3 as Outputs.
    strb r4, [r0, #DIR]			; Store new Direction Pin Data.

   	; configure to digital pins - 0 or 1
   	ldrb r4, [r0, #DEN]			; Load Port F Digital Enable Pin Data.
   	orr r4, r4, #0xE			; ORR 0xE with Digital Enable Pin Data to set Pins 1-3 to Digital.
   	strb r4, [r0, #DEN]			; Store new Digital Enable Pin Data.

   	POP {r4-r12,lr}
   	mov pc, lr


	.end
