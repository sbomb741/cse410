; DATA
	.data

	;GLOBALS
	.global startPrompt
	.global buttonPrompt
	.global continuePrompt
	.global k0
	.global k1
	.global k2
	.global k3
	.global k4
	.global k5
	.global k6
	.global k7
	.global k8
	.global k9
	.global k10
	.global k11
	.global k12
	.global k13
	.global k14
	.global k15
	.global unknownKey

;PROMPTS
startPrompt:		.string		27, "[2J", 27, "[1;1H", 27, "[37;40m"
					.string		0xC,"Welcome to Display That Keypad Button"
					.string 	0xA, 0xD, "Instructions:"
					.string 	0xA, 0xD, "	- When ready, hit the Enter key to begin"
					.string 	0xA, 0xD, "	- Once entered, press any key on the keypad"
					.string 	0xA, 0xD, "	- You will be shown which key and which symbol for that key you pressed"
					.string 	0xA, 0xD, "	- Press 'c' to press another keypad button, 'q' to quit"
					.string 	0xA, 0xD, 0xA, 0xD, "Hit 'Enter' when ready",0

buttonPrompt:		.string		0xA, 0xD, 0xA, 0xD, 0xA, 0xD, "Press a keypad button...  ",0
continuePrompt:		.string		0xA, 0xD, "Press 'c' to press another keypad button, 'q' to quit",0

k0:					.string "'1' was pressed (K0)",0
k1:					.string "'2' was pressed (K1)",0
k2:					.string "'3' was pressed (K2)",0
k3:					.string "'A' was pressed (K3)",0
k4:					.string "'4' was pressed (K4)",0
k5:					.string "'5' was pressed (K5)",0
k6:					.string "'6' was pressed (K6)",0
k7:					.string "'B' was pressed (K7)",0
k8:					.string "'7' was pressed (K8)",0
k9:					.string "'8' was pressed (K9)",0
k10:				.string "'9' was pressed (K10)",0
k11:				.string "'C' was pressed (K11)",0
k12:				.string "'*' was pressed (K12)",0
k13:				.string "'0' was pressed (K13)",0
k14:				.string "'#' was pressed (K14)",0
k15:				.string "'D' was pressed (K15)",0
unknownKey:			.string 0xA, 0xD, "Could not determine which key was pressed, please try again.",0

; TEXT
	.text
	.global project2
	.global uart_init
	.global gpio_keypad_init
	.global int2string
	.global string2int
	.global read_string
	.global output_string
	.global read_character
	.global output_character

ptr_to_startPrompt:			.word startPrompt
ptr_to_buttonPrompt:		.word buttonPrompt
ptr_to_continuePrompt:		.word continuePrompt

ptr_to_k0:			.word k0
ptr_to_k1:			.word k1
ptr_to_k2:			.word k2
ptr_to_k3:			.word k3
ptr_to_k4:			.word k4
ptr_to_k5:			.word k5
ptr_to_k6:			.word k6
ptr_to_k7:			.word k7
ptr_to_k8:			.word k8
ptr_to_k9:			.word k9
ptr_to_k10:			.word k10
ptr_to_k11:			.word k11
ptr_to_k12:			.word k12
ptr_to_k13:			.word k13
ptr_to_k14:			.word k14
ptr_to_k15:			.word k15
ptr_to_unknownKey:	.word unknownKey

DATA: 		.equ 0x3FC				; Data Register (LOW/HIGH)

;Main SUBROUTINE to operate the functionality of project2
project2:
	PUSH {r4-r12, lr}

	; Initializations
	bl uart_init
	bl gpio_keypad_init

	ldr r0, ptr_to_startPrompt
	bl output_string
check_enter_key:
	bl read_character
	cmp r0, #0xD
	bne check_enter_key			; see if 'Enter' was pressed
request_keypad_button:
	ldr r0, ptr_to_buttonPrompt
	bl output_string			; prompt user to hit a button on keypad
	bl determine_keypad_button	; print out when the user hits keypad button

	ldr r0, ptr_to_continuePrompt
	bl output_string			; ask the user to continue or quit
	bl read_character			; read the user input

	cmp r0, #99
	beq request_keypad_button	; start over if user enters 'c'

	POP {r4-r12, lr}
	mov pc,lr


;DETERMINE_KEYPAD_BUTTON SUBROUTINE (r0 - returns a decimal value of which key was pressed; prints it out as well)
determine_keypad_button:
	PUSH {r4-r12,lr}
	; Port D (Alice EduBase - Driving this port)
	mov r4, #0x7000
	movt r4, #0x4000			; r4 set as Port D base address.
	mov r5, #0x01				; initial value for port D
	mov r6, #31					; loop counter
drive_port_d:
	strb r5, [r4, #DATA]		; drive D0
	bl check_port_a				; r0 will return which column (1-4) the data is in; 0 if no/invalid data
	cmp r0, #0
	bgt keypad_button_pressed	; branch when button is pressed
	cmp r5, #0x8
	beq reset_counter			; reset r5 after going through all 4 rows, go back to row1
	ror r5, r5, r6				; increment r5 to drive the next pin
	b drive_port_d				; loop
reset_counter:
	mov r5, #1					; reset the data pin to check all rows again
	b drive_port_d				; loop
keypad_button_pressed:
	mov r6, #0
	strb r6, [r4, #DATA]		; undrive D0

row1:
	cmp r5, #0x1
	bgt row2					; check next row if not equal
	cmp r0, #0x1				; check first column
	bne r1c2					; check next column
	mov r8, #0					; store the number key being pressed
	ldr r0, ptr_to_k0
	b display_pressed_key		; display the pressed key
r1c2:
	cmp r0, #0x2				; check second column
	bne r1c3					; check next column
	mov r8, #0x01				; store the number key being pressed
	ldr r0, ptr_to_k1
	b display_pressed_key		; display the pressed key
r1c3:
	cmp r0, #0x3				; check third column
	bne r1c4					; check next column
	mov r8, #2					; store the number key being pressed
	ldr r0, ptr_to_k2
	b display_pressed_key		; display the pressed key
r1c4:
	cmp r0, #0x4				; check last column
	bne undetermined_key
	mov r8, #3					; store the number key being pressed
	ldr r0, ptr_to_k3
	b display_pressed_key		; display the pressed key

row2:
	cmp r5, #0x2
	bgt row3					; check next row if not equal
	cmp r0, #0x1				; check first column
	bne r2c2					; check next column
	mov r8, #4					; store the number key being pressed
	ldr r0, ptr_to_k4
	b display_pressed_key		; display the pressed key
r2c2:
	cmp r0, #0x2				; check second column
	bne r2c3					; check next column
	mov r8, #5					; store the number key being pressed
	ldr r0, ptr_to_k5
	b display_pressed_key		; display the pressed key
r2c3:
	cmp r0, #0x3				; check third column
	bne r2c4					; check next column
	mov r8, #6					; store the number key being pressed
	ldr r0, ptr_to_k6
	b display_pressed_key		; display the pressed key
r2c4:
	cmp r0, #0x4				; check last column
	bne undetermined_key
	mov r8, #7					; store the number key being pressed
	ldr r0, ptr_to_k7
	b display_pressed_key		; display the pressed key

row3:
	cmp r5, #0x4
	bgt row4					; check next row if not equal
	cmp r0, #0x1				; check first column
	bne r3c2					; check next column
	mov r8, #8					; store the number key being pressed
	ldr r0, ptr_to_k8
	b display_pressed_key		; display the pressed key
r3c2:
	cmp r0, #0x2				; check second column
	bne r3c3					; check next column
	mov r8, #9					; store the number key being pressed
	ldr r0, ptr_to_k9
	b display_pressed_key		; display the pressed key
r3c3:
	cmp r0, #0x3				; check third column
	bne r3c4					; check next column
	mov r8, #10					; store the number key being pressed
	ldr r0, ptr_to_k10
	b display_pressed_key		; display the pressed key
r3c4:
	cmp r0, #0x4				; check last column
	bne undetermined_key
	mov r8, #11					; store the number key being pressed
	ldr r0, ptr_to_k11
	b display_pressed_key		; display the pressed key

row4:
	cmp r0, #0x8
	bgt undetermined_key		; check next row if not equal
	cmp r0, #0x1				; check first column
	bne r4c2					; check next column
	mov r8, #12					; store the number key being pressed
	ldr r0, ptr_to_k12
	b display_pressed_key		; display the pressed key
r4c2:
	cmp r0, #0x2				; check second column
	bne r4c3					; check next column
	mov r8, #13					; store the number key being pressed
	ldr r0, ptr_to_k13
	b display_pressed_key		; display the pressed key
r4c3:
	cmp r0, #0x3				; check third column
	bne r4c4					; check next column
	mov r8, #14					; store the number key being pressed
	ldr r0, ptr_to_k14
	b display_pressed_key		; display the pressed key
r4c4:
	cmp r0, #0x4				; check last column
	bne undetermined_key
	mov r8, #15					; store the number key being pressed
	ldr r0, ptr_to_k15
	b display_pressed_key		; display the pressed key

undetermined_key:
	ldr r0, ptr_to_unknownKey
display_pressed_key:
	bl output_string
	mov r0, r8					; returns the decimal value of the pressed key in r0

	POP {r4-r12, lr}
	mov pc,lr


;CHECK_PORT_A SUBROUTINE (r0 - returns which column the button pressed is in (1-4))
check_port_a:
	PUSH {r4-r12,lr}

	mov r4, #0x4000
	movt r4, #0x4000			; r4 set as Port A base address.
	ldrb r6, [r4, #DATA]		; Load data out of port A
	ubfx r5, r6, #2, #4			; extract bits 2-5
; there's a range for each column because it's pins A2-A5 (leaving the last two
col1:
	cmp r5, #0x1				; check if A2 is a 1
	bne col2
	mov r0, #1					; return a 1 if A1 is a 1
	b end_check_port_a
col2:
	cmp r5, #0x2				; check if A3 is a 1
	bne col3
	mov r0, #2					; return a 2 if A2 is a 1
	b end_check_port_a
col3:
	cmp r5, #0x4				; check if A4 is a 1
	bne col4
	mov r0, #3					; return a 3 if A3 is a 1
	b end_check_port_a
col4:
	cmp r5, #0x8				; check if A5 is a 1
	bne invalid_data
	mov r0, #4					; return a 4 if A4 is a 1
	b end_check_port_a
invalid_data:
	mov r0, #0					; if data port A is some other value than the checked ones, return 0
end_check_port_a:
	POP {r4-r12,lr}
	mov pc, lr


	.end
