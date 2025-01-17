; ==========================================================
; TEXT
	.text

	; GLOBALS (export)
	.global pwm_RGB_LED_init
	.global RGB_LED_init
	.global pwm_timer_interrupt_init
	.global uart_init
	.global uart_interrupt_init
	.global nops
	.global output_string

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
RCGCDMA:	.equ 0x60C				; clock offset for DMA
DMACFG:		.equ 0x004				; DMA controller offset A
DMACTLBASE:	.equ 0x008				; DMA channel control base point
DMAENASET:	.equ 0x028				; DMA channel enable
DMASWREQ:	.equ 0x014				; DMA channel software request
; PWM Offsets
RCGCGPIO:	.equ 0x608
RCGCPWM:	.equ 0x640
GPIOAFSEL:	.equ 0x420
GPIOPCTL:	.equ 0x52C
RCC:		.equ 0x060
PWM2CTL:	.equ 0x0C0
PWM3CTL:	.equ 0x100
PWM2GENB:	.equ 0x0E4
PWM3GENA:	.equ 0x120
PWM3GENB:	.equ 0x124
PWM2LOAD:	.equ 0x0D0
PWM3LOAD:	.equ 0x110
PWM2CMPB:	.equ 0x0DC
PWM3CMPA:	.equ 0x118
PWM3CMPB:	.equ 0x11C
PWMENABLE:	.equ 0x008
DC1:		.equ 0x010


; ==========================================================


; SUBROUTINE - PWM RGB INITIALIZATION
pwm_RGB_LED_init:
	PUSH {r4-r12, lr}

	; Adjust system clock
	mov r4, #0xE000
	movt r4, #0x400F				;
	ldr r5, [r4, #DC1]
	mov r6, #0x9					; System clock is 20MHz clock
	bfi r5, r6, #12, #4
	str r5, [r4, #DC1]
	bl nops							; nop 5 times

	; STEP 1: Enable PWM Clock
	mov r4, #0xE000
	movt r4, #0x400F
	ldrb r5, [r4, #RCGCPWM]
	mov r6, #0x02					; pwm module 0 is bit 0, module 1 is bit 1
	orr r5, r5, r6
	strb r5, [r4, #RCGCPWM]
	bl nops							; nop 5 times

	; STEP 2: Enable clock to GPIO module
	mov r4, #0xE000
	movt r4, #0x400F
	ldrb r5, [r4, #RCGCGPIO]
	mov r6, #0x20					; port f is bit 5
	orr r5, r5, r6
	strb r5, [r4, #RCGCGPIO]
	bl nops							; nop 5 times

	; STEP 3: Set GPIO pins to use alternate function (instead of standard GPIO)
	mov r4, #0x5000
	movt r4, #0x4002				; Port F Advanced Peripheral Bus (APB)
	ldrb r5, [r4, #GPIOAFSEL]
	mov r6, #0x0E					; set pins 1-3 to use alternate function (RGB pins)
	orr r5, r5, r6
	strb r5, [r4, #GPIOAFSEL]
	bl nops							; nop 5 times

	; STEP 4: Configure the alternate function to be PWM
	mov r4, #0x5000
	movt r4, #0x4002
	ldr r5, [r4, #GPIOPCTL]
	mov r6, #0x555
	bfi r5, r6, #4, #12				; connect pins 1-3 to M1PWM5-7 by setting 5 for each pin
	str r5, [r4, #GPIOPCTL]
	bl nops							; nop 5 times

	; STEP 5: Configure the Run-Mode Clock
	mov r4, #0xE000
	movt r4, #0x400F
	ldr r5, [r4, #RCC]
	mov r6, #0x8
	bfi r5, r6, #17, #4				; set USEPWMDIV to 1, and set PWMDIV to 000, which is divide by 2 ([system clk = 20MHz]/2 = 10MHz clk)
	str r5, [r4, #RCC]
	bl nops							; nop 5 times

	; STEP 6: Configure PWM generator for countdown mode
	; STEP 6a: Disable pwm
	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	mov r5, #0
	str r5, [r4, #PWM2CTL]			; disable pwm generation for pwm m1 generator2
	bl nops							; nop 5 times
	str r5, [r4, #PWM3CTL]			; disable pwm generation for pwm m1 generator3
	bl nops							; nop 5 times
	; STEP 6b: Configure the what pwm does at comparator values
	; pin 2
	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	ldr r5, [r4, #3]
	mov r6, #0x0C2					; ACTCMPAD drives pwm high, ACTZERO drives pwm low
	bfi r5, r6, #0, #12
	str r5, [r4, #PWM3GENA]
	bl nops							; nop 5 times
	; pin 1
	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	ldr r5, [r4, #PWM2GENB]
	mov r6, #0xC02					; ACTCMPBD drives pwm high, ACTZERO drives pwm low
	bfi r5, r6, #0, #12
	str r5, [r4, #PWM2GENB]
	bl nops							; nop 5 times
	; pin 3
	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	ldr r5, [r4, #PWM3GENB]
	mov r6, #0xC02					; ACTCMPBD drives pwm high, ACTZERO drives pwm low
	bfi r5, r6, #0, #12
	str r5, [r4, #PWM3GENB]
	bl nops							; nop 5 times

	; STEP 7: Load the timer value (desired period - 1)
	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	mov r5, #0x191					; (400-1 0x18F) clock ticks per period
	strh r5, [r4, #PWM2LOAD]
	bl nops							; nop 5 times
	strh r5, [r4, #PWM3LOAD]
	bl nops							; nop 5 times

	; STEP 8: Set the pulse width of each pin
	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	mov r5, #0x190					; keep red high
	strh r5, [r4, #PWM2CMPB]
	bl nops							; nop 5 times
	mov r5, #0x190					; keep blue high
	strh r5, [r4, #PWM3CMPA]
	bl nops							; nop 5 times
	mov r5, #0x190					; keep green high
	strh r5, [r4, #PWM3CMPB]
	bl nops							; nop 5 times

	; STEP 9: Start the Timers
	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	mov r5, #1
	strb r5, [r4, #PWM2CTL]			; enable pwm generation for pwm m1 generator2
	bl nops							; nop 5 times
	strb r5, [r4, #PWM3CTL]			; enable pwm generation for pwm m1 generator3
	bl nops							; nop 5 times

	; STEP 10: Enable PWM Outputs
	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	mov r5, #0xE0
	strb r5, [r4, #PWMENABLE]		; enable pwm generation for pwm5 pwm6 pwm7
	bl nops							; nop 5 times

	POP {r4-r12,lr}
	mov pc,lr


; SUBROUTINE - RGB LED INIT
RGB_LED_init:
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


; SUBROUTINE - PWM TIMER INTERRUPT INITIALIZATION (.1s second interval)
pwm_timer_interrupt_init:
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
	MOV r5, #0x6A00					; Set interval value for 1.6 million, or .1s
	MOVT r5, #0x0018
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


; SUBROUTINE - UART_INTERRUPT_INIT
uart_interrupt_init:
	PUSH {r4-r12, lr}

	MOV r4, #0xC000
	MOVT r4, #0x4000				; Set r4 = UART0 base address.
	LDRB r5, [r4, #UARTIM]			; Load byte of UART Interrupt Mask Register.
	ORR r5, r5, #0x10				; Set RXIM Bit 4.
	STRB r5, [r4, #UARTIM]			; Store new data back into register.

	MOV r4, #0xE000
	MOVT r4, #0xE000				; Set r4 = Interrupt Enable base address.
	LDRB r5, [r4, #EN0]				; Load byte of Interrupt Enable Register.
	ORR r5, r5, #0x20				; Set UART0 Bit 5.
	STRB r5, [r4, #EN0]				; Store new data back into register.

	POP {r4-r12, lr}
	MOV pc, lr


; SUBROUTINE - UART_INIT SUBROUTINE
; BUG - 10/21/24 - RGB init can't be called before this routine
uart_init:
	PUSH {r4-r12,lr}			; Spill registers to stack
	; Provide clock to UART0
	MOV r4, #1
	MOV r5, #0xE618
	MOVT r5, #0x400F
	STR r4, [r5]
	; Enable Clock to PortA
	MOV r4, #1
	MOV r5, #0xE608
	MOVT r5, #0x400F
	STR r4, [r5]
	; Disable UART0 Control
	MOV r4, #0
	MOV r6, #0xC030
	MOVT r6, #0x4000
	STR r4, [r6]
	; Set UART0_IBRD_R for 115,200 baud
	MOV r4, #8
	MOV r5, #0xC024
	MOVT r5, #0x4000
	STR r4, [r5]
	; Set UART0_FBRD_R for 115,200 baud
	MOV r4, #44
	MOV r5, #0xC028
	MOVT r5, #0x4000
	STR r4, [r5]
	; Use System Clock
	MOV r4, #0
	MOV r5, #0xCFC8
	MOVT r5, #0x4000
	STR r4, [r5]
	; Use 8-bit word length, 1 stop bit, no parity
	MOV r4, #0x60
	MOV r5, #0xC02C
	MOVT r5, #0x4000
	STR r4, [r5]
	; Enable UART0 Control
	MOV r4, #0x301
	STR r4, [r6]
	; The OR operation sets the bits that are OR'ed
	; with a 1. To translate the following lines
	; to assembly, load the data, OR the data with
	; the mask and store the result back.
	; Make PA0 and PA1 as Digital Ports
	MOV r4, #0x03
	MOV r6, #0x451C
	MOVT r6, #0x4000
	LDR r5, [r6]
	ORR r5, r5, r4
	STR r5, [r6]
	; Change PA0,PA1 to Use an Alternate Function
	MOV r4, #0x03
	MOV r6, #0x4420
	MOVT r6, #0x4000
	LDR r5, [r6]
	ORR r5, r5, r4
	STR r5, [r6]
	; Configure PA0 and PA1 for UART
	MOV r4, #0x11
	MOV r6, #0x452C
	MOVT r6, #0x4000
	LDR r5, [r6]
	ORR r5, r5, r4
	STR r5, [r6]
	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr


; SUBROUTINE - NOPS (5 no ops)
nops:
	PUSH {r4-r12, lr}
	nop
	nop
	nop
	nop
	POP {r4-r12,lr}
	mov pc,lr


; SUBROUTINE - OUTPUT_CHARACTER
output_character:
	PUSH {r4-r12,lr}			; Spill registers to stack
    MOV r4, #0xC000				; Copy the address of the Data Register into r3
	MOVT r4, #0x4000			; (r4 = 0x4000C000).
output_loop:
	LDRB r5, [r4, #U0FR]		; Load the contents of the Flag Register into r5.
	MOV r6, #0x20				; Copy #0x20 into r6 to use for masking
	AND r6, r5, r6				; Bitwise AND the Flag Register using #0x20 to extract the TxFF Bit (0020 0000).
	CMP r6, #0					; Compare the TxFF Bit held in r6 with 0. If TxFF Bit = 1, r6 = #0x20. If TxFF Bit = 0, r6 = #0.
	BNE output_loop				; If r6 != 0, branch back to the beginning of the loop, as the process should not
								; continue unless the TxFF Bit is found to be 0.
	STRB r0, [r4]				; Store the character stored in r0 into the Data Register to transmit the data.
	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr


; SUBROUTINE - READ_CHARACTER
read_character:
	PUSH {r4-r12,lr}			; Spill registers to stack
    MOV r4, #0xC000				; Copy the address of the Data Register into r3
	MOVT r4, #0x4000			; (r4 = 0x4000C000).
read_loop:
	LDRB r5, [r4, #U0FR]		; Load the contents of the Flag Register into r5.
	MOV r6, #0x10				; Copy #0x10 into r6 to use for masking.
	AND r6, r5, r6				; Bitwise AND the Flag Register using #0x10 to extract the RxFE Bit (0001 0000).
	CMP r6, #0					; Compare the RxFE Bit held in r6 with 0. If RxFE Bit = 1, r6 = #0x10. If RxFE Bit = 0, r6 = #0.
	BNE read_loop				; If r6 != 0, branch back to the beginning of the loop, as the process should not
								; continue unless the RxFE Bit is found to be 0.
	LDRB r0, [r4]				; Load the last byte (8 bits) of the Data Register into r0 to access
								; the byte of data which holds the information to be recieved.
	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr


; SUBROUTINE - READ_STRING
read_string:
	PUSH {r4-r12,lr}

	MOV r4, #13					; Initialize r4 as the ASCII value for a Carriage Return (Enter/Return).
	MOV r5, #0					; Initialize r5 as the offset counter with value 0.
	MOV r6, r0					; Initialize r6 as the base of the address where the string will be stored in memory.

read_string_loop:
	BL read_character			; Branch and Link to read_character. Returns the current character typed by the user into r0.
	BL output_character			; Branch and Link to output_character. Prints the current character typed by the user stored in r0.
	CMP r0, r4					; Compares the current character with Carriage Return (Enter/Return).
	BEQ read_string_done		; If the user types Enter/Return, branch to the end of the loop.
	STRB r0, [r6, r5]			; Stores the current character at the memory location given by r6, based on the offset r5.
	ADD r5, r5, #1				; Increment the offset counter so the next loop adds the next string character in the next location.
	B read_string_loop			; Branch back to the beginning of the loop.

read_string_done:
	MOV r0, #0					; After the loop is done, set r0 to 0 or the NULL ASCII value.
	STRB r0, [r6, r5]			; Store the NULL Terminating value at the end of the string
	MOV r0, r6					; Copy the base of the address to the string in memory at r0 and end the subroutine.

	POP {r4-r12,lr}
	mov pc, lr

; SUBROUTINE - OUTPUT_STRING
output_string:
	PUSH {r4-r12,lr}			; Spill registers to stack
    MOV r4, #0					; Initialize r4 as 0 or the NULL ASCII value.
	MOV r5, #0					; Initialize r5 as the offset counter with value 0.
	MOV r6, r0					; Initialize r6 as the base of the address where the string will be stored in memory.
output_string_loop:
	LDRB r0, [r6, r5]			; Load the first character in the string stored in memory, based on the offset counter r5.
	BL output_character			; Branch and Link to output_character to print the current character in the string.
	ADD r5, r5, #1				; Increment the offset counter r5 so the next loop loads the next character in the string.
	CMP r0, r4					; Compare the current character in the string with the NULL ASCII value.
	BNE output_string_loop		; If the current character is not a NULL terminator, return to the start of the loop.
	MOV r0, r6					; After the loop copy the value into r0 and finish the subroutine.
	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr

; SUBROUTINE - INT2STRING (r0 = address, r1 = integer)
storeASCII:
	cmp r9, #1					; if a number like 102/100, store the middle 0 as ascii
	bne int2string_dontstore
	ADD r7, r7, #0x30			; convert quotient to ASCII
	STRB r7, [r4, r5]			; Store the ASCII value into the correct address; with offset r5
	ADD r5, r5, #1				; Increment r5 (used for offset)
	b int2string_dontstore
int2string_zero:
	MOV r1, #0x30
	STRB r1, [r4, r5]
	ADD r5, r5, #1
	MOV r0, #0
	B int2string_done
int2string:
	PUSH {r4-r12,lr} 			; Store any registers in the range of r4 through r12
	MOV r4, r0					; Stores address into r4
	MOV r5, #0					; Loop counter used for storing from offset
	mov r9, #0
	CMP r1, #0					; Compare if number is negative
	BGT int2string_notNegative	; Skip RSB if number is positive
	BEQ int2string_zero
	RSB r1, r1, #0				; Convert r1 to positive if negative
	MOV r7, #0x2D				; Puts '-' as ASCII in r7
	STRB r7, [r4, r5]			; Store the ASCII value '-' into the correct address; with offset r5
	ADD r5, r5, #1				; Increment r5 (used for offset)
int2string_notNegative:
	MOV r11, r1					; Stores dividend into r11 for div_and_mod after finding divisor value
	mov r6, #1					; divisor starter value
	mov r10, #10				; multiplication factor
find_divisor:
	MOV r0, r11					; Stores dividend into r0 for div_and_mod
	mul r6, r6, r10				; multiply divisor by a factor of 10
	MOV r1, r6					; Stores divisor into r1 for div_and_mod
	bl div_and_mod
	cmp r0, #10
	bge find_divisor			; increment the divisor by a factor of 10 and try again
	mov r0, r11					; restore the original dividend value into r0 if divisor is big enough now
	mov r1, r6					; call div and mod with correct divisor value
int2string_loop:
	BL div_and_mod				; Calls div_and_mod with arguments r0 = dividend, r1 = divisor
	MOV r7, r0					; Stores Quotient in r7
	MOV r0, r1					; Stores ABS(Remainder) in r0
	CMP r7, #0					; Compares r7 to 0 (ex, if 27/100)
	BEQ storeASCII				; Dont store byte if quotient is 0
	ADD r7, r7, #0x30			; convert quotient to ASCII
	STRB r7, [r4, r5]			; Store the ASCII value into the correct address; with offset r5
	ADD r5, r5, #1				; Increment r5 (used for offset)
	mov r9, #1
int2string_dontstore:
	CMP r6, #1					; Compares if r6 is at the end (100 -> 10 -> 1)
	BEQ int2string_done			; Finish routine if r6 = 1
	MOV r8, r0					; Store remainder into r8
	MOV r0, r6					; Store divisor into r0
	MOV r1, #10					; Store 10 into r1
	BL div_and_mod				; Decrements divisor by multiple of 10 (100/10; 10/10)
	MOV r6, r0					; Stores Quotient into r6
	MOV r1, r0					; Stores Quotient into r1
	MOV r0, r8					; Restores original remainder back into r0
	B int2string_loop			; Loop back
int2string_done:
	STRB r0, [r4,r5]			; Stores NULL byte into the r5 offset of r4 address
	add r2, r4, r5				; store address location right after whole number (for cse410 float2string)
	MOV r0, r4					; Stores original address back into r0
	POP {r4-r12,lr}
	mov pc, lr


; SUBROUTINE - STRING2INT
string2int:
	PUSH {r4-r12,lr}

	MOV r4, #0					; Initialize r4 as 0 or the NULL ASCII value.
	MOV r5, #0					; Initialize r5 as the offset counter with value 0.
	MOV r6, #0					; Initialize r5 as the final integer value to be returned at the end of the subroutine.
	MOV r8, #10
	MOV r9, #0					; Initialize r8 as the negative integer flag.
	LDRB r7, [r0, r5]			; Given the address of the string r0, load the current character of the string into r7, based on the offset r5.
	CMP r7, r4					; Compare the current character of the string with the NULL ASCII value.
	BEQ string2int_done			; If the current character is equal to the NULL ASCII value, branch to the end of the subroutine.
	CMP r7, #0x2D				; Compare first character with the negative symbol "-".
	BNE string2int_loop			; If it is not a negative input, skip the following lines.
	ADD r9, r9, #1				; Set negative flag to ON.
	ADD r5, r5, #1				; Increment offset counter.
	LDRB r7, [r0, r5]			; Load the first integer input of the string.

string2int_loop:
	SUB r7, r7, #0x30			; Subtract the current character's value by #0x30, converting the character to an integer.
	ADD r6, r6, r7				; Add the current integer to the total integer value r6.
	ADD r5, r5, #1				; Increment the offset counter r5 so the next load takes the next character in the string.
	LDRB r7, [r0, r5]			; Given the address of the string r0, load the current character of the string into r7, based on the offset r5.
	CMP r7, r4					; Compare the current character of the string with the NULL ASCII value.
	BEQ string2int_done			; If the current character is equal to the NULL ASCII value, branch to the end of the subroutine.
	MUL r6, r6, r8				; Multiply the current total integer value by 10 to be able to add the next found character value.
								; For example, Given "123", r6 = 1 * 10 = 10 + 2 = 12 * 10 = 120 + 3 = 123.
	B string2int_loop			; Branch back to the the beginning of the loop.

string2int_done:
	MOV r0, r6					; Copy the final integer value in r6 into r0 and finish the subroutine.
	CMP r9, #0					; Compare negative flag to 0 (off).
	BEQ string2int_return		; If the negative flag is off, skip the following line.
	RSB r0, r0, #0				; Make integer value in r0 negative.

string2int_return:
	POP {r4-r12,lr}
	mov pc, lr


; SUBROUTINE - DIV_AND_MOD
div_and_mod:
	PUSH {r4-r12,lr}
	MOV r4, #0				; Flag (r4) is set to 0
	MOV r5, #0				; Quotient (r5) counter
	CMP r0, #0				; Compare the dividend to 0
	BGE cond1				; Branch to cond1 if dividend is not negative
	MVN r4, r4				; Flip bits of flag if dividend is negative
	RSB r0, r0, #0			; Make the dividend positive
cond1:
	CMP r1, #0				; Compare the divisor to 0
	BGE cond2				; Branch to cond2 if divisor is not negative
	MVN r4, r4				; Flip bits of flag if divisor is negative
							; Flag will be zero if remainder should be positive; otherwise, negative
	RSB r1, r1, #0			; Make the divisor positive
cond2:
	CMP r0, r1				; Compare dividend to divisor
	BLT noQuotient			; Branch to noQuotient (if r0 = 0)
div_mod_loop:
	SUB r0, r0, r1			; Subtract the divisor from the dividend
	ADD r5, r5, #1			; Increment r5 by 1
	CMP r0, r1				; Compare dividend to divisor
	BGE div_mod_loop		; Repeat the loop if the dividend isn't less than the divisor
	MOV r1, r0				; Store the remainder in r1
	CMP r4, #0				; Compare the flag to 0
	BEQ cond3				; Branch to cond3 if the Quotient is positive
	RSB r5, r5, #0			; Make Quotient negative if flag isn't 0
cond3:
	MOV r0, r5				; Store the Quotient in r0
	B exit					; Branch to exit
noQuotient:
	MOV r1, r0				; Store (positive) dividend as remainder
	MOV r0, #0				; Store zero in the Quotient
exit:
	POP {r4-r12,lr}
	mov pc, lr

	.end
