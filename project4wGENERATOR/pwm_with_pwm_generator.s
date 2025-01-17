; ==========================================================
; DATA
	.data

;PROMPTS
status:			.short 0x0
colorCode:		.byte 0x1		; initialize first color to orange
rainbowFlag:	.byte 0x0

startPrompt:		.string		27, "[2J", 27, "[1;1H", 27, "[37;40m"
					.string		0xC,"Welcome to Pulse Width Modulation (PWM) - Timer Driven"
					.string 	0xA, 0xD, "Instructions:"
					.string 	0xA, 0xD, "	- When ready, enter a number that corresponds to a color code"
					.string 	0xA, 0xD, "	- At any time, press 'q' to quit"
					.string 	0xA, 0xD, "	- Code 0 - rainbow, will gradually cycle through each color"
					.string 	0xA, 0xD, 0x9, "	- Note that any invalid keystroke will pause the rainbow"
					.string 	0xA, 0xD, 0x9, "	- Note that the rainbow may resume in a different spot if code 0 is re-entered"
					.string		0xA, 0xD, 0xA, 0xD, "Color Codes:"
					.string 	0xA, 0xD, 0x9, "1 - Orange"
					.string 	0xA, 0xD, 0x9, "2 - Magenta"
					.string 	0xA, 0xD, 0x9, "3 - Light Pink"
					.string 	0xA, 0xD, 0x9, "4 - Purple"
					.string 	0xA, 0xD, 0x9, "5 - Capri Blue"
					.string 	0xA, 0xD, 0x9, "6 - Light Purple"
					.string 	0xA, 0xD, 0x9, "7 - Yellow-Green"
					.string 	0xA, 0xD, 0x9, "8 - Light Sea Green"
					.string 	0xA, 0xD, 0x9, "9 - Light Emerald"
					.string 	0xA, 0xD, 0x9, "0 - Rainbow", 0xA, 0xD, 0xA, 0xD, 0

colorPrompt:		.string		0xA, 0xD, "Enter a color code...  ",0
k1:					.string 	"'1' was pressed (Orange)",0
k2:					.string 	"'2' was pressed (Magenta)",0
k3:					.string 	"'3' was pressed (Light Pink)",0
k4:					.string 	"'4' was pressed (Purple)",0
k5:					.string 	"'5' was pressed (Capri Blue)",0
k6:					.string 	"'6' was pressed (Light Purple)",0
k7:					.string 	"'7' was pressed (Yellow-Green)",0
k8:					.string 	"'8' was pressed (Light Sea Green)",0
k9:					.string 	"'9' was pressed (Light Emerald)",0
k0:					.string 	"'0' was pressed (Rainbow)",0

; ==========================================================
; TEXT
	.text

	; GLOBALS
	.global pwm_project
	.global Timer0A_Handler
	.global UART0_Handler

	; GLOBALS (import)
	.global pwm_RGB_LED_init
	.global RGB_LED_init
	.global pwm_timer_interrupt_init
	.global uart_init
	.global uart_interrupt_init
	.global nops
	.global output_string

; POINTERS
ptr2status:			.word status
ptr2colorCode:		.word colorCode
ptr2rainbowFlag:	.word rainbowFlag

ptr2startPrompt:	.word startPrompt
ptr2colorPrompt:	.word colorPrompt

ptr2k0:				.word k0
ptr2k1:				.word k1
ptr2k2:				.word k2
ptr2k3:				.word k3
ptr2k4:				.word k4
ptr2k5:				.word k5
ptr2k6:				.word k6
ptr2k7:				.word k7
ptr2k8:				.word k8
ptr2k9:				.word k9

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
; SUBROUTINE - main pwm project
pwm_project:
	PUSH {r4-r12, lr}

	; initializations
	bl uart_init					; must come first, otherwise RGB doesn't init properly
	bl uart_interrupt_init
	bl RGB_LED_init
	bl pwm_RGB_LED_init

	; display start prompt
	ldr r0, ptr2startPrompt
	bl output_string

	; display color code prompt
	ldr r0, ptr2colorPrompt
	bl output_string

	; activate timer interrupt
	bl pwm_timer_interrupt_init


; infinite loop; to be interrupted by timer
loop:
	ldr r4, ptr2status
	ldrb r4, [r4]
	cmp r4, #0x41
	beq program_over				; if user enters a 'q' (x71-x30), quit the program
	b loop

program_over:
	POP {r4-r12, lr}
	mov pc, lr


; SUBROUTINE - Advanced RGB LED (r0 - color code)
Advanced_RGB_LED:
	PUSH {r4-r12, lr}

	mov r4, #0x9000
	movt r4, #0x4002				; PWM M1
	mov r7, r0						; move color code into r7

	; Check which color the user specified last
	; RAINBOW
	cmp r7, #0
	beq rainbow
	; RED
	cmp r7, #1
	beq code1
	cmp r7, #2
	beq code2
	cmp r7, #3
	beq code3
	; BLUE
	cmp r7, #4
	beq code4
	cmp r7, #5
	beq code5
	cmp r7, #6
	beq code6
	; GREEN
	cmp r7, #7
	beq code7
	cmp r7, #8
	beq code8
	cmp r7, #9
	beq code9
	b advanced_RGB_LED_done			; end handler if invalid keystroke

; RED 100%
code1:
	; orange
	mov r5, #400					; red 100%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #0						; blue 0%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #200					; green 50%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

code2:
	; magenta
	mov r5, #400					; red 100%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #200					; blue 50%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #0						; green 0%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

code3:
	; light pink
	mov r5, #400					; red 100%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #200					; blue 50%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #200					; green 50%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

; BLUE 100%
code4:
	; purple
	mov r5, #200					; red 50%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #400					; blue 100%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #000					; green 0%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

code5:
	; capri blue
	mov r5, #000					; red 0%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #400					; blue 100%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #200					; green 50%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

code6:
	; light purple
	mov r5, #200					; red 50%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #400					; blue 100%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #200					; green 50%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

; GREEN ON
code7:
	; yellow green
	mov r5, #200					; red 50%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #000					; blue 0%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #400					; green 100%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

code8:
	; yellow green
	mov r5, #000					; red 0%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #200					; blue 50%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #400					; green 100%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

code9:
	; yellow green
	mov r5, #200					; red 50%
	strh r5, [r4, #PWM2CMPB]
	mov r5, #200					; blue 50%
	strh r5, [r4, #PWM3CMPA]
	mov r5, #400					; green 100%
	strh r5, [r4, #PWM3CMPB]
	b advanced_RGB_LED_done

; RAINBOW
rainbow:
	; expected register values
	mov r5, #400					; max load value
	mov r7, #40						; increment/decrement value

	; jump to correct spot
	ldr r0, ptr2status
	ldrb r1, [r0]
	cmp r1, #8
	beq pwm_phase8
	cmp r1, #7
	beq pwm_phase7
	cmp r1, #6
	beq pwm_phase6
	cmp r1, #5
	beq pwm_phase5
	cmp r1, #4
	beq pwm_phase4
	cmp r1, #3
	beq pwm_phase3
	cmp r1, #2
	beq pwm_phase2
	cmp r1, #1
	beq pwm_phase1

; COLOR: WHITE 100% 
; decrement green and blue
pwm_phase0:
	; blue
	ldrh r6, [r4, #PWM3CMPA]
	sub r6, r6, r7
	strh r6, [r4, #PWM3CMPA]
	; green
	ldrh r6, [r4, #PWM3CMPB]
	sub r6, r6, r7
	strh r6, [r4, #PWM3CMPB]
	; cmp
	cmp r6, #0
	ble end_pwm_phase0
	b advanced_RGB_LED_done
end_pwm_phase0:
	; store status for next iteration
	mov r6, #0
	strh r6, [r4, #PWM3CMPA]
	strh r6, [r4, #PWM3CMPB]
	mov r1, #1
	strb r1, [r0]
	b advanced_RGB_LED_done

; COLOR: RED
; increment green
pwm_phase1:
	ldrh r6, [r4, #PWM3CMPB]
	add r6, r6, r7
	strh r6, [r4, #PWM3CMPB]
	cmp r6, r5
	bge end_pwm_phase1
	b advanced_RGB_LED_done
end_pwm_phase1:
	; store status for next iteration
	strh r5, [r4, #PWM3CMPB]
	mov r1, #2
	strb r1, [r0]
	b advanced_RGB_LED_done

; COLOR ORANGE/YELLOW
; decrement red
pwm_phase2:
	ldrh r6, [r4, #PWM2CMPB]
	sub r6, r6, r7
	strh r6, [r4, #PWM2CMPB]
	cmp r6, #0
	ble end_pwm_phase2
	b advanced_RGB_LED_done
end_pwm_phase2:
	; store status for next iteration
	mov r6, #0
	strh r6, [r4, #PWM2CMPB]
	mov r1, #3
	strb r1, [r0]
	b advanced_RGB_LED_done

; COLOR: GREEN
; increment blue
pwm_phase3:
	add r7, r7, r7						; change increment to double speed
	ldrh r6, [r4, #PWM3CMPA]
	add r6, r6, r7
	strh r6, [r4, #PWM3CMPA]
	cmp r6, r5
	bge end_pwm_phase3
	b advanced_RGB_LED_done
end_pwm_phase3:
	; store status for next iteration
	strh r5, [r4, #PWM3CMPA]
	mov r1, #4
	strb r1, [r0]
	b advanced_RGB_LED_done

; COLOR: CYAN
; decrement green
pwm_phase4:
	add r7, r7, r7						; change increment to double speed
	ldrh r6, [r4, #PWM3CMPB]
	sub r6, r6, r7
	strh r6, [r4, #PWM3CMPB]
	cmp r6, #0
	ble end_pwm_phase4
	b advanced_RGB_LED_done
end_pwm_phase4:
	; store status for next iteration
	mov r6, #0
	strh r6, [r4, #PWM3CMPB]
	mov r1, #5
	strb r1, [r0]
	b advanced_RGB_LED_done

; COLOR: BLUE
; increment red
pwm_phase5:
	ldrh r6, [r4, #PWM2CMPB]
	add r6, r6, r7
	strh r6, [r4, #PWM2CMPB]
	cmp r6, r5
	bge end_pwm_phase5
	b advanced_RGB_LED_done
end_pwm_phase5:
	; store status for next iteration
	strh r5, [r4, #PWM2CMPB]
	mov r1, #6
	strb r1, [r0]
	b advanced_RGB_LED_done

; COLOR PURPLE
; decrement blue to 50%
pwm_phase6:
	mov r8, #2
	udiv r8, r5, r8						; change cmp to 50% of r5 - max load value
	ldrh r6, [r4, #PWM3CMPA]
	sub r6, r6, r7
	strh r6, [r4, #PWM3CMPA]
	cmp r6, r8
	ble end_pwm_phase6
	b advanced_RGB_LED_done
end_pwm_phase6:
	; store status for next iteration
	mov r6, r8
	strh r6, [r4, #PWM3CMPA]			; store 50%
	mov r1, #7
	strb r1, [r0]
	b advanced_RGB_LED_done

; COLOR: PINK
; increment green to 50%
pwm_phase7:
	mov r8, #2
	udiv r8, r5, r8						; change cmp to 50% of r5 - max load value
	ldrh r6, [r4, #PWM3CMPB]
	add r6, r6, r7
	strh r6, [r4, #PWM3CMPB]
	cmp r6, r8
	bge end_pwm_phase7
	b advanced_RGB_LED_done
end_pwm_phase7:
	; store status for next iteration
	mov r6, r8
	strh r6, [r4, #PWM3CMPB]			; store 50%
	mov r1, #8
	strb r1, [r0]
	b advanced_RGB_LED_done

; COLOR: WHITE 67%
; increment green and blue
pwm_phase8:
	; blue
	ldrh r6, [r4, #PWM3CMPA]
	add r6, r6, r7
	strh r6, [r4, #PWM3CMPA]
	; green
	ldrh r6, [r4, #PWM3CMPB]
	add r6, r6, r7
	strh r6, [r4, #PWM3CMPB]
	cmp r6, r5
	bge end_pwm_phase8
	b advanced_RGB_LED_done
end_pwm_phase8:
	; store status for next iteration
	strh r5, [r4, #PWM3CMPA]
	strh r5, [r4, #PWM3CMPB]
	mov r1, #0
	strb r1, [r0]
	b advanced_RGB_LED_done

advanced_RGB_LED_done:
	POP{r4-r12, lr}
	mov pc, lr


; SUBROUTINE - TIMER HANDLER
Timer0A_Handler:
	PUSH {r4-r12, lr}

	; clear the interrupt
	mov r4, #0x0000
	movt r4, #0x4003				; Set r4 = Timer Interrupt Clear Register
	ldrb r5, [r4, #GPTMICR]			; Load byte from Clear register
	orr r5, r5, #0x01				; Set bit 0 to disable.
	strb r5, [r4, #GPTMICR]			; Store new data back into register.

	; load color code
	ldr r6, ptr2colorCode
	ldrb r0, [r6]					; colorCode byte
	bl Advanced_RGB_LED				; light up color based on color code

	; exit handler
timer_handler_done:
	POP {r4-r12, lr}
	bx lr


; SUBROUTINE - UART_HANDLER
UART0_Handler:
	PUSH {r4-r12, lr}

	; clear interrupt
	mov r4, #0xC000
	movt r4, #0x4000				; Copy UART0 base address into r4.
	ldrb r5, [r4, #UARTICR]			; Load byte of UART Clear Register into r5.
	orr r5, r5, #0x10				; Set UART Clear Register Bit 4 (RXIM).
	strb r5, [r4, #UARTICR]			; Store new data back into register.

	; store entered int
	ldrb r5, [r4]					; Entered key is in r5
	sub r5, r5, #0x30				; convert single digit ascii to int
	ldr r6, ptr2colorCode
	strb r5, [r6]					; store entered color code number

	; display correct uart prompt
u_p0:
	cmp r5, #0
	bne u_p1
	ldr r0, ptr2k0					; load prompt corresponding to entered digit
	b uart_handler_done
u_p1:
	cmp r5, #1
	bne u_p2
	ldr r0, ptr2k1					; load prompt corresponding to entered digit
	b uart_handler_done
u_p2:
	cmp r5, #2
	bne u_p3
	ldr r0, ptr2k2					; load prompt corresponding to entered digit
	b uart_handler_done
u_p3:
	cmp r5, #3
	bne u_p4
	ldr r0, ptr2k3					; load prompt corresponding to entered digit
	b uart_handler_done
u_p4:
	cmp r5, #4
	bne u_p5
	ldr r0, ptr2k4					; load prompt corresponding to entered digit
	b uart_handler_done
u_p5:
	cmp r5, #5
	bne u_p6
	ldr r0, ptr2k5					; load prompt corresponding to entered digit
	b uart_handler_done
u_p6:
	cmp r5, #6
	bne u_p7
	ldr r0, ptr2k6					; load prompt corresponding to entered digit
	b uart_handler_done
u_p7:
	cmp r5, #7
	bne u_p8
	ldr r0, ptr2k7					; load prompt corresponding to entered digit
	b uart_handler_done
u_p8:
	cmp r5, #8
	bne u_p9
	ldr r0, ptr2k8					; load prompt corresponding to entered digit
	b uart_handler_done
u_p9:
	cmp r5, #9
	bne u_quit
	ldr r0, ptr2k9					; load prompt corresponding to entered digit
	b uart_handler_done
u_quit:
	cmp r5, #0x41
	bne uart_handler_done
	ldr r7, ptr2status
	strb r5, [r7]

uart_handler_done:
	cmp r5, #9
	bgt u_skip_display				; don't print anything out on invalid keystroke

	bl output_string				; display what choice the user selected
	ldr r0, ptr2colorPrompt
	bl output_string				; display enter color code prompt for next iteration

u_skip_display:
	POP {r4-r12, lr}
	bx lr



	.end
