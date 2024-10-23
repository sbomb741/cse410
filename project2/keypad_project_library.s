	.text
	.global uart_init
	.global gpio_keypad_init
	.global output_string
	.global output_character
	.global read_character
	.global read_string
	.global int2string
	.global string2int
	.global div_and_mod

U0FR: 		.equ 0x18				; UART0 Flag Register
EN0: 		.equ 0x100				; Interrupt Enable Register
UARTIM:		.equ 0x038				; UART Interrupt Mask Register
UARTICR:	.equ 0x044				; UART Interrupt Clear Register
CLK: 		.equ 0x608				; Clock Offset
DIR: 		.equ 0x400				; Data Direction Offset (Input/Output)
DEN: 		.equ 0x51C				; Digital Enable Offset
DATA: 		.equ 0x3FC				; Data Register (LOW/HIGH)

;GPIO_KEYPAD_INIT SUBROUTINE
gpio_keypad_init:
	PUSH {r4-r12,lr}			; Spill registers to stack

    MOV r0, #0xE000
    MOVT r0, #0x400F			; r0 set as Clock base address.
    LDRB r4, [r0, #CLK]			; Load Clock Pin Data.
    ORR r4, r4, #0x9			; ORR 0x9 with Clock Pin Data to enable Ports D/A.
    STRB r4, [r0, #CLK]			; Store new Clock Pin Data.

	; Port D (Alice EduBase - Driving this port)
	MOV r0, #0x7000
	MOVT r0, #0x4000			; r0 set as Port D base address.
	LDRB r4, [r0, #DIR]			; Load Port D Direction Pin Data.
	ORR r4, r4, #0x0F			; ORR 0x0F with Direction Pin Data to set Pins 0-3 as Outputs FROM the processor.
	STRB r4, [r0, #DIR]			; Store new Direction Pin Data.
	LDRB r4, [r0, #DEN]			; Load Port D Digital Enable Pin Data.
   	ORR r4, r4, #0x0F			; ORR 0x0F with Digital Enable Pin Data to set Pins 0-3 to Digital.
   	STRB r4, [r0, #DEN]			; Store new Digital Enable Pin Data.

   	; Port A (Alice EduBase - Reading from this port)
   	MOV r0, #0x4000
   	MOVT r0, #0x4000			; r0 set as Port A base address.
   	LDRB r4, [r0, #DIR]			; Load Port A Direction Pin Data.
	AND r4, r4, #0xC3			; AND 0xC3 with Direction Pin Data to set Pins 2-5 as Inputs TO the processor.
	STRB r4, [r0, #DIR]			; Store new Direction Pin Data.
	LDRB r4, [r0, #DEN]			; Load Port A Digital Enable Pin Data.
	ORR r4, r4, #0x3C			; ORR 0x3C with Digital Enable Pin Data to set Pins 2-5 to Digital.
	STRB r4, [r0, #DEN]			; Store new Digital Enable Pin Data.

	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr


;UART_INTERRUPT_INIT
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


;UART_INIT SUBROUTINE
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


;OUTPUT_CHARACTER SUBROUTINE
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


;READ_CHARACTER SUBROUTINE
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


;READ_STRING SUBROUTINE
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

;OUTPUT_STRING SUBROUTINE
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

; INT2STRING SUBROUTINE (r0 = address, r1 = integer)
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



;STRING2INT SUBROUTINE
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


;DIV_AND_MOD SUBROUTINE
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
