; DATA
	.data

	;GLOBALS
	.global startPrompt
	.global step1
	.global step2
	.global step3
	.global step4
	.global step5
	.global step6
	.global decimalRes
	.global num1Res
	.global num2Res

;PROMPTS
startPrompt:		.string		27, "[2J", 27, "[1;1H", 27, "[37;40m"
					.string		0xC,"Welcome to Floating Point Calculator"
					.string 	0xA, 0xD, "Instructions:"
					.string 	0xA, 0xD, "	- Specify the maximum number of decimal places; this number should not exceed the number of decimal places of an answer itself"
					.string 	0xA, 0xD, "	- All numbers for operation MUST contain a decimal point and number after it"
					.string 	0xA, 0xD, "	- Enter the first floating point number"
					.string 	0xA, 0xD, "	- Enter the operation symbol from the options below"
					.string 	0xA, 0xD, "	- Enter the second floating point number (only for operations 1-4)"
					.string 	0xA, 0xD, "	- Note: some values may have an inaccuracy due a limited amount of precision for those values in base 2"
					.string 	0xA, 0xD, 0xA, 0xD, "Possible operations and their symbol:"
					.string 	0xA, 0xD, 0x9, "1. '+' 	- Addition"
					.string 	0xA, 0xD, 0x9, "2. '-'	- Subtraction"
					.string 	0xA, 0xD, 0x9, "3. '*'	- Multiplication"
					.string 	0xA, 0xD, 0x9, "4. '/'	- Division"
					.string 	0xA, 0xD, 0x9, "5. '#'	- Square Root"
					.string 	0xA, 0xD, 0x9, "6. '^'	- Square",0

step1:				.string 0xA, 0xD, 0xA, 0xD, 0xA, 0xD, "Enter maximum number of decimal places (int 1+): ", 0
step2:				.string 0xA, 0xD, 0xA, 0xD, "Enter first number (float): ", 0
step3:				.string 0xA, 0xD, "Enter operation: ", 0
step4:				.string 0xA, 0xD, "Enter second number (float): ", 0
step5:				.string 0xA, 0xD, 0xA, 0xD, "Result: ", 0
step6:				.string	0xA, 0xD, 0xA, 0xD, 0xA, 0xD, "Press 'c' to continue, 'q' to quit",0

decimalRes:			.string "---------------------------------------------", 0
num1Res:			.string "---------------------------------------------", 0
num2Res:			.string "---------------------------------------------", 0
returnRes:			.string "---------------------------------------------", 0


; TEXT
	.text
	.global project1
	.global uart_init
	.global int2string
	.global string2int
	.global read_string
	.global output_string
	.global read_character
	.global output_character

ptr_to_startPrompt:	.word startPrompt
ptr_to_step1:		.word step1
ptr_to_step2:		.word step2
ptr_to_step3:		.word step3
ptr_to_step4:		.word step4
ptr_to_step5:		.word step5
ptr_to_step6:		.word step6
ptr_to_decimalRes:	.word decimalRes
ptr_to_num1Res:		.word num1Res
ptr_to_num2Res:		.word num2Res
ptr_to_returnRes:	.word returnRes


; START OF FLOATING POINT CALCULATOR
project1:
	PUSH {r4-r12, lr}

	; Initializations
	bl uart_init							; allow user input

	ldr r0, ptr_to_startPrompt				; display instructions at the top
	bl output_string

	ldr r0, ptr_to_step1					; request decimal places
	bl output_string
	ldr r0, ptr_to_decimalRes				; store entered string
	bl read_string

	ldr r0, ptr_to_step2					; request first number
	bl output_string
	ldr r0, ptr_to_num1Res					; store first number
	bl read_string

	ldr r0, ptr_to_step3
	bl output_string						; request operation number
	bl read_character						; read the entered operation character
	bl output_character						; display what character they pressed
	mov r10, r0								; r10 - operation character

	mov r4, #0x2B							; ASCII plus
	mov r5, #0x2D							; ASCII minus
	mov r6, #0x2A							; ASCII *
	mov r7, #0x2F							; ASCII /
	mov r8, #0x5E							; ASCII ^
	mov r9, #0x23							; ASCII #

	cmp r10, r8
	beq square								; square the entered number

	cmp r10, r9
	beq square_root							; square root the entered number

	ldr r0, ptr_to_step4
	bl output_string						; prompt second number
	ldr r0, ptr_to_num2Res
	bl read_string							; store second number

	ldr r0, ptr_to_num1Res
	bl string2float							; convert the first number to a float
	vmov s4, r0								; store first number in s4

	ldr r0, ptr_to_num2Res
	bl string2float							; convert the second number to a float
	vmov s5, r0								; store second number in s5

	cmp r10, r4
	beq addition							; add the two entered numbers

	cmp r10, r5
	beq subtraction							; subtract the two entered numbers

	cmp r10, r6
	beq multiply							; multiply the two entered numbers

	cmp r10, r7
	beq divide								; divide the two entered numbers

	bne project1							; restart the calculator if invalid character is entered

square:
	ldr r0, ptr_to_num1Res
	bl string2float							; convert the entered number to a float

	vmov s4, r0
	vmul.f32 s4, s4, s4						; square the float value

	vmov r0, s4
	ldr r1, ptr_to_returnRes
	bl float2string							; store the square of the float as a string at returnRes

	b end_of_operation						; branch to end of routine

square_root:
	ldr r0, ptr_to_num1Res
	bl string2float							; convert the entered number to a float

	vmov s4, r0
	vsqrt.f32 s4, s4						; square root the float value

	vmov r0, s4
	ldr r1, ptr_to_returnRes
	bl float2string							; store the square root of the float as a string at returnRes

	b end_of_operation						; branch to end of routine

; s4 - first float value
; s5 - second float value

addition:
	vadd.f32 s6, s4, s5						; add the float values

	vmov r0, s6
	ldr r1, ptr_to_returnRes
	bl float2string							; store the sum of the floats as a string at returnRes

	b end_of_operation						; branch to end of routine

subtraction:
	vsub.f32 s6, s4, s5						; subtract the float values

	vmov r0, s6
	ldr r1, ptr_to_returnRes
	bl float2string							; store the difference of the floats as a string at returnRes

	b end_of_operation						; branch to end of routine

multiply:
	vmul.f32 s6, s4, s5						; multiply the float values

	vmov r0, s6
	ldr r1, ptr_to_returnRes
	bl float2string							; store the product of the floats as a string at returnRes

	b end_of_operation						; branch to end of routine

divide:
	vdiv.f32 s6, s4, s5						; divide the float values

	vmov r0, s6
	ldr r1, ptr_to_returnRes
	bl float2string							; store the quotient of the floats as a string at returnRes

end_of_operation:

	ldr r0, ptr_to_step5
	bl output_string						; display result string

	ldr r0, ptr_to_decimalRes
	bl string2int							; get the integer of the decimal rounding factor
	mov r4, r0								; decimal rounding int

	ldr r0, ptr_to_returnRes
	bl string2float							; gets the float in r0
	mov r1, r4								; ensure the number of decimals is preserved across calls
	bl enforce_decimal						; rounds the float in r0

	ldr r0, ptr_to_returnRes				; store the correct address in r0
	bl output_string						; display the result of the operation

	ldr r0, ptr_to_step6					; Stores continue prompt into r0
	bl output_string						; Outputs continue prompt
	bl read_character						; Reads user input
	bl output_character						; Displays user input

	mov r1, #99								; Move ASCII 'c' into r1
	cmp r0, r1								; Compare entered character to 'c'
	beq project1							; Run program again if user presses 'c'

	POP {r4-r12,lr}
	mov pc, lr


;ENFORCE DECIMAL SUBROUTINE - standard rounding (r0 - floating point value (IEEE) [input], r0 - rounded fp value [output], r1 - number of decimal places (INT))
enforce_decimal:
	PUSH {r4-r12, lr}

	vmov s0, r0								; IEEE floating point to round

	vmov.f32 s2, #10.0						; factor to multiply value by
	vcvt.s32.f32 s3, s3						; convert
	vmov.f32 s4, #10.0						; 10 ^ r1 value
	mov r4, #1								; comparison end point for loop
	mov r6, r1								; number of decimal places preserved across calls

enf_dec_loop:
	cmp r1, r4
	ble enf_dec_done						; End loop once decimal rounding value has "crossed" the decimal point

	vmul.f32 s4, s4, s2						; move decimal point one place to the right (multiply floating point value by a factor of 10)
	sub r1, r1, r4							; decrement exponent
	b enf_dec_loop							; loop

enf_dec_done:
	vmul.f32 s0, s0, s4						; move decimal point number of places to the right, that the user declared to round to
	vcmp.f32 s0, #0.0						;
	blt sub_five
	vmov.f32 s5, #0.5
	vadd.f32 s0, s0, s5
	b convert

sub_five:
	vmov.f32 s5, #-0.5
	vadd.f32 s0, s0, s5

convert:
	vcvt.s32.f32 s0, s0						; "Round" value after moving decimal point
	vcvt.f32.s32 s0, s0						; convert rounded value back into IEEE format
	vdiv.f32 s0, s0, s4						; move the decimal point back to where it belongs with the correctly rounded value

	; computer math correction
	vmov.f32 s5, #1.0
	vdiv.f32 s5, s5, s2
	vdiv.f32 s5, s5, s4
	vadd.f32 s0, s0, s5

	vmov r0, s0								; return the rounded value in r1
	ldr r1, ptr_to_returnRes				; gets address to store the rounded float
	bl float2string							; store the rounded float in r0 into r1 location

	ldr r1, ptr_to_returnRes
	mov r7, #1

truncate_string:
	ldrb r5, [r1], #1
	cmp r5, #0x2E							; compare to decimal
	beq enf_after_dec
	b truncate_string

enf_after_dec:
	add r1, r1, r7							; increment r1 address
	cmp r6, r7								; have we reached the number of decimals to display yet
	ble store_null
	sub r6, r6, r7							; decrement number of decimals to display
	b enf_after_dec

store_null:
	mov r8, #0
	strb r8, [r1]							; null terminate string after correctly rounded float
	POP {r4-r12,lr}
	mov pc, lr


;STRING2FLOAT SUBROUTINE (r0 - address of string, r0 - returned float value (IEEE))
string2float:
	PUSH {r4-r12,lr}
; Intializations
	mov r4, #0						; offset counter
	mov r6, #0						; whole number of the string value
	mov r7, #10						; multiplication factor
	mov r8, #0x2E					; ASCII Decimal
	mov r9, #0x2D					; ASCII Dash


string_byte_loop:
	ldrb r5, [r0, r4]				; get the byte from r4 offset of the string

	cmp r5, r8						; branch to reached_decimal when the decimal is reached
	beq reached_decimal

	cmp r5, r9						; change r9 to one if the number should be negative, and increment to next byte
	bne ascii_string_conversion
	mov r9, #1
	b increment_string_byte

ascii_string_conversion:
	mul r6, r6, r7					; multiply number by a factor of 10 (converting to base 10)
	sub r5, r5, #0x30				; if didn't reach the decimal, convert from ASCII to int
	add r6, r6, r5					; add int to total value

increment_string_byte:
	add r4, r4, #1
	b string_byte_loop


reached_decimal:
	add r4, r4, #1
	mov r10, #0						; null terminator
	mov r11, #0						; decimal portion
	mov r12, #1						; multiplication factor for decimal portion

fractional_loop:
	ldrb r5, [r0, r4]				; stop iterating when string ends
	cmp r5, r10
	beq end_of_string

	mul r11, r11, r7				; multiply number by a factor of 10 (converting to base 10)
	sub r5, r5, #0x30				; if didn't reach the decimal, convert from ASCII to int
	add r11, r11, r5				; add int to total value
	mul r12, r12, r7				; division factor int to total value

	add r4, r4, #1					; increment to next byte
	b fractional_loop				; loop

end_of_string:
	vmov s6, r6						; move the whole number to fp
	vmov s11, r11					; move the fractional number to fp
	vmov s12, r12					; move the decimal division factor to fp

	vcvt.f32.u32 s6, s6				; convert whole number to IEEE format
	vcvt.f32.u32 s11, s11			; convert fractional number to IEEE format
	vcvt.f32.u32 s12, s12			; convert decimal division factor to IEEE format

	vdiv.f32 s11, s11, s12			; make the fractional number an actual fraction
	vadd.f32 s6, s6, s11			; add the whole number and fractional component in IEEE format
	vmov r0, s6						; return the IEEE number in r0

	cmp r9, #1
	bne return_from_string2float
	ror r9, r9, r9
	orr r0, r0, r9					; make r0 value negative

return_from_string2float:
	POP {r4-r12,lr}
	mov pc, lr


;FLOAT2STRING SUBROUTINE (r0 - single precision floating point number (IEEE), r1 - address)
float2string:
	PUSH {r4-r12,lr}

	vmov s0, r0
	vcvt.s32.f32 s4, s0				; floor the floating point value
	vcvt.f32.s32 s4, s4				; convert the floored value into IEEE format

	mov r5, #31
	ror r4, r0, r5					; get the sign bit at bit 0
	mov r6, #0x1
	and r6, r6, r4

	cmp r6, #1						; see if the number is negative
	bne after_dash
	mov r8, #0x2D
	strb r8, [r1], #1				; store a '-' in memory and increment the string address


after_dash:
	vsub.f32 s5, s0, s4
	vabs.f32 s5, s5					; get the abs value of the decimal portion

	vabs.f32 s4, s4					; make the floored whole number positive
	mov r0, r1						; send address in r0
	vcvt.s32.f32 s7, s4				; convert IEEE to int
	vmov r1, s7						; send positive integer part in r1
	bl int2string					; store the whole number portion

	; r0 has the original address sent
	; r2 has the address location right after the integer

	mov r8, #0x2E					; ASCII period '.'
	strb r8, [r2], #1				; Store decimal point
	mov r8, #0x30					; ASCII difference

	vmov.f32 s6, #10.0				; multiplier factor
	vmov.f32 s8, #1.0				; store conversion error factor
	vdiv.f32 s8, s8, s6				; 0.1
	vdiv.f32 s8, s8, s6				; 0.01
	vdiv.f32 s8, s8, s6				; 0.001
	vdiv.f32 s8, s8, s6				; 0.0001
	vdiv.f32 s8, s8, s6				; 0.00001

decimal_loop:
	vmul.f32 s5, s5, s6				; move the decimal one place to the right
	vcvt.s32.f32 s7, s5				; floor the decimal portion value

	vmov r9, s7						; move floored decimal into r8
	add r9, r8, r9					; convert int to ASCII
	strb r9, [r2], #1				; store the ascii value at address and increment after

	vcvt.f32.s32 s7, s7				; convert the floored value into IEEE format
	vsub.f32 s9, s5, s7				; get difference between decimal and floored decimal value

	vmov.f32 s5, s9					; move the decimal remainder into s5 for repeated call
	vcmp.f32 s9, s8
	vmrs APSR_nzcv, FPSCR        	; Move the comparison result to APSR
	vmul.f32 s8, s8, s6				; increment the decimal error by a multiple of 10 each loop
	bgt decimal_loop				; if the difference is more than s8, loop again. might be a bug here for a long high decimal

	mov r8, #0
	strb r8, [r2]					; store NULL terminator

	POP {r4-r12,lr}
	mov pc,lr

	.end
