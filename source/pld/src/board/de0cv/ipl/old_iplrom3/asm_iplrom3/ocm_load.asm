;		Loader for OCM
;--------------------------------------------
; VDP ports
DATP	=		0x98				; VDP Data port
CMDP	=		0x99				; VDP Command port
;--------------------------------------------
; Program starts here:
		org		0x0
;
begin:
		di
		jp		skip_message
;--------------------------------------------
header:
include "message.asm"						; < 4*40 symbols
skip_message:

;--------------------------------------------
		ld		sp, -1
; Set VDP mode and color palette
		ld		hl, dat_99
		ld		bc, 0x0E99					; 14 byte -> 0x99
		otir
		ld		bc, 0x209A					; 32 byte -> 0x9A
		otir
;--------------------------------------------
; Now let's clear first 16Kb of VDP memory
; Set
		xor		a, a						;Set LSB [00000000]
		out		[CMDP], a
		ld		a, 0x40 + 0					;Set MSB [01XXXXXX]
		out		[CMDP], a					;Bits 7&6 = 00 for reads,
											;			01 for writes
		ld		hl, CHCARS
		ld		bc, CHCARS_END - CHCARS
COPYCHCARS:
		ld		a, [hl]
		out		[DATP], a
		inc		hl
		dec		bc
		ld		a, b
		or		a, c
		jr		nz, COPYCHCARS
;============================================
		ld		bc, 0x4000 - (CHCARS_END - CHCARS)
CLEAR1:
		xor		a, a
		out		[DATP], a
		dec		bc
		ld		a, b
		or		a, c
		jr		nz,CLEAR1
;============================================
; Set VRAM adress for print text
		xor		a, a						;col=0
		out		[CMDP], a
		ld		a, 0x48 + 0					;str=0
		out		[CMDP], a					;Adress VRAM = 0x0800
		ld		hl, header
;=======  Send message to display
pr_str:
		ld		a,[hl]
		sub		a, 0x20
		jp		c, start					; end print message
		out		[DATP],a
		inc		hl
		jr		pr_str
;============================================
; VDP port 99H (set register)
dat_99:
		db		0x00, 0x80				; 0x00 -> R#0
		db		0x50, 0x81				; 0x50 -> R#1 (40X24, TEXT Mode)
		db		0x02, 0x82				; 0x02 -> R#2
		db		0x00, 0x84				; 0x00 -> R#4
		db		0xF4, 0x87				; 0xF0 -> R#7 Set Color (White on Blue)
		db		0x00, 0x89				; 0x00 -> R#9  (PAL-mode)
		db		0x00, 0x90				; 0x00 -> R#16 (Palette)

; VDP port 9Ah (set color palette)
;	   Red/Blue,Green
dat_9A:
		db		0x00, 0x00				; 0
		db		0x00, 0x00				; 1
		db		0x11, 0x06				; 2
		db		0x33, 0x07				; 3
		db		0x17, 0x01				; 4
		db		0x27, 0x03				; 5
		db		0x51, 0x01				; 6
		db		0x27, 0x06				; 7
		db		0x71, 0x01				; 8
		db		0x73, 0x03				; 9
		db		0x61, 0x06				; 10
		db		0x64, 0x06				; 11
		db		0x11, 0x04				; 12
		db		0x65, 0x02				; 13
		db		0x55, 0x05				; 14
		db		0x77, 0x07				; 15

;============================================
CHCARS:
include "ZG6x8_L.asm"
CHCARS_END:
;============================================
start:
include "iplrom3.asm"
;============================================
		repeat I, 0x800 - (( end_beg - begin ) + ( end_p - prog ))
			db	0xff
		endr

; check_message_length
		if (skip_message - header) > (4 * 40)
			error "[ERROR] Message.asm is too big!!"
		else
			message "Message.asm length is OK."
		endif
