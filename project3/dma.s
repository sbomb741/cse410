; DATA
	.data

	;GLOBALS
	.global dma_channel_control
	.global source_data
	.global source_data_end

;PROMPTS
source_data:			.byte 2,4,2,4,2,4,2,4,2,4,2,4,2,4,2
source_data_end:		.byte 14
dma_channel_control:	.align 1024
						.space 1024

; ==========================================================
; TEXT
	.text
	.global dma
	.global Timer0A_Handler

	.global dma_RGB_init
	.global timer_interrupt_init

; POINTERS
ptr2source_data:			.word source_data
ptr2source_data_end:		.word source_data_end
ptr2destination_end:		.word 0x400253FC
ptr2dma_channel_control:	.word dma_channel_control

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

; ==========================================================
;SUBROUTINE - main dma routine
dma:
	PUSH {r4-r12,lr}

	; Initialize peripheral - RGB and trigger - timer
	bl timer_interrupt_init		; initialize timer
	bl dma_RGB_init				; initialize rgb on tiva

	; STEP 1: Module Initializations
	bl dma_module_init					; initialize module dma values

	; STEP 2: Configure a Memory to Memory Transfer
	bl dma_configure_channel			; configure the channel for dma

	; STEP 3 Start a Transfer
	; transfer is started in Timer Handler (when timer interrupts every .25seconds)
	; sets the xfersize, xfermode, and sets DMAENASET to begin the dma

; infinite loop.
; in real world, processor would be doing other things!
loop:
	b loop

	POP {r4-r12,lr}
	mov pc,lr


;SUBROUTINE - STEP 1: dma module initializations
dma_module_init:
	PUSH {r4-r12,lr}

	; STEP 1: Module Initializations
	; STEP 1a: enable clock
	mov r0, #0xE000
    movt r0, #0x400F			; r0 set as Clock base address.
    ldrb r4, [r0, #RCGCDMA]		; Load Clock Pin Data.
    orr r4, r4, #0x1			; ORR 0x1 with Clock Pin Data to enable clock.
    strb r4, [r0, #RCGCDMA]		; Store new Clock Pin Data.

    ; STEP 1b: enable dma controller (master enable)
    mov r0, #0xF000
    movt r0, #0x400F			; r0 set as controller base address.
    ldrb r4, [r0, #DMACFG]		; Load dma configuration.
    orr r4, r4, #0x1			; ORR 0x1 with DMACFG.
    strb r4, [r0, #DMACFG]		; Store new Clock Pin Data.

    ; STEP 1c: set channel control base register
    ldr r1, ptr2dma_channel_control
    str r1, [r0, #DMACTLBASE]			; store the ptr to dma channel control

    POP {r4-r12,lr}
   	mov pc, lr


; SUBROUTINE - STEP 2: dma configure channel
dma_configure_channel:
	PUSH {r4-r12, lr}

    ; STEP 2a: Configure the Channel Attributes
    ; optionally configure DMAPRIOSET/DMAPRIOCLR to set channel priority (0 default - default priority level)
    ; optionally configure DMAALTSET/DMAALTCLR to use the primary or alternative (secondary) channel control structure
    ; optionally configure DMAUSEBURSTSET/DMAUSEBURSTCLR to set burst only, or 'single or burst' (0 default - single or burst)
    ; optionally configure DMAREQMASKSET/DMAREQMASKCLR to allow dma to recognize requests for this channel (0 default - all channels enabled)
    ; optionally configure DMACHMAP2 to enable a specific peripheral for channel access to dma (default - peripheral 0)

	; STEP 2b: Configure the Channel Control Structure
	ldr r0, ptr2dma_channel_control		; channel control base address
	mov r1, #18							; channel 18
	ldr r2, ptr2source_data_end			; end of source data
	ldr r3, ptr2destination_end			; destination location
	; word 0 - source end pointer
	lsl r1, r1, #4				; gets the channel offset; each channel has four words = 16 bytes; lsl #4 = * 16
	str r2, [r0, r1]			; store the source address END pointer
	; word 1 - destination end pointer
	add r1, r1, #4				; increment offset to word 1
	str r3, [r0, r1]			; store the destination address END pointer
	; word 2 - control word
	add r1, r1, #4				; increment offset to word 2
	mov r2, #3					; destination increment; 3 = no increment
	mov r3, #0					; item size for dst and src; 0 = byte
	mov r4, #0					; source increment; 0 = byte increment
	mov r5, #0					; arbitration size; will reconsider channel priority after each transfer
	mov r6, #15					; transfer size; number of items in source_data to transfer - 1
	mov r7, #1					; transfer mode (0 - Stop, 1 - Basic, 2 - Auto, ...)/word 2, channel control register
	;DSTINC
	lsl r2, r2, #30				; shift value to correct spot
	orr r7, r7, r2				; insert value into word 2
	;DSTSIZE
	lsl r3, r3, #28				; shift value to correct spot
	orr r7, r7, r3				; insert value into word 2
	;SRCINC
	lsl r4, r4, #26				; shift value to correct spot
	orr r7, r7, r4				; insert value into word 2
	;SRCSIZE
	lsl r3, r3, #24				; shift value to correct spot
	orr r7, r7, r3				; insert value into word 2
	;Reserved
	ldr r8, [r0, r1]
	ubfx r8, r8, #18, #6		; extract reserved bits 23:18
	lsl r8, r8, #22				; shift value to correct spot
	orr r7, r7, r8				; insert value into word 2
	;ARBSIZE
	lsl r5, r5, #16				; shift value to correct spot
	orr r7, r7, r5				; insert value into word 2
	;XFERSIZE
	lsl r6, r6, #4				; shift value to correct spot
	orr r7, r7, r6				; insert value into word 2
	;NXTUSEBURST
	; optionally configure to 1 to use burst transfer to complete the last transfer
	;XFERMODE
	; initially set with r7 value
	str r7, [r0, r1]			; store word 2 into proper spot in dma channel control

	POP {r4-r12, lr}
	mov pc, lr


;SUBROUTINE - STEP 3: Timer 0A Handler
Timer0A_Handler:
	PUSH {r4-r12, lr}

	; clear the interrupt
	mov r4, #0x0000
	movt r4, #0x4003				; Set r4 = Timer Interrupt Clear Register
	ldrb r5, [r4, #GPTMICR]			; Load byte from Clear register
	orr r5, r5, #0x01				; Set bit 0 to disable.
	strb r5, [r4, #GPTMICR]			; Store new data back into register.

	; STEP 2: reset xfersize and xfermode (goes to 0 after dma transfer)
	ldr r0, ptr2dma_channel_control		; channel control base address
	mov r1, #18							; channel 18
	lsl r1, r1, #4						; gets the channel offset; each channel has four words = 16 bytes; lsl #4 = * 16
	add r1, r1, #8						; increment offset to word 2
	ldrb r2, [r0, r1]					; load the last bye of word 2 for channel in r1=18
	orr r2, r2, #0xF1					; set xfersize to F and xfermode to basic
	strb r2, [r0, r1]					; store the byte

	; STEP 3a: enable dma channel enable set
 	mov r0, #0xF000
    movt r0, #0x400F			; r0 set as dma base address.
    ldr r4, [r0, #DMAENASET]	; Load dma channel enable
    mov r5, #0x1
    bfi r4, r5, #18, #1			; enable channel 18
    str r4, [r0, #DMAENASET]	; Store enabled channel Data

    ; STEP 3b: [optionally] issue a software transfer request


	POP {r4-r12,lr}
	bx lr


	.end
