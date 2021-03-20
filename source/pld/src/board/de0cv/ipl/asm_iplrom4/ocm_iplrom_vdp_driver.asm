; --------------------------------------------------------------------
;	IPLROM4 for OCM booting from MMC/SD/SDHC card
;	without data compression
; ====================================================================
;	History
;	ver 3.0.0	caro
;	ver	4.0.0	t.hara
; --------------------------------------------------------------------

; --------------------------------------------------------------------
;	VDP ports
; --------------------------------------------------------------------
vdp_port0			:= 0x98				; Port#0: VRAM access
vdp_port1			:= 0x99				; Port#1: Control Register access, VRAM address setting
vdp_port2			:= 0x9A				; Port#2: Palette Register write
vdp_port3			:= 0x9B				; Port#3: Indirect Control Register access

; --------------------------------------------------------------------
;	VDP initializer
; --------------------------------------------------------------------
		scope	vdp_initialize
vdp_initialize::
		;	Set VDP mode and color palette
		ld		hl, vdp_control_regs
		ld		bc, ((vdp_control_regs_end - vdp_control_regs) << 8) | vdp_port1
		otir
		ld		bc, ((vdp_palette_regs_end - vdp_palette_regs) << 8) | vdp_port2
		otir

		;	Initialize the first 16KB of VRAM.
		ld		hl, 0x0000
		call	vdp_set_vram_address

		ld		bc, 0x4000
		xor		a, a
		call	vdp_fill_vram

		ld		hl, 0x0800 + 32*8
		call	vdp_set_vram_address
		ld		hl, font_data
		ld		bc, (0x00 << 8) | vdp_port0
		otir
		otir
		otir
		ret
		endscope

; --------------------------------------------------------------------
;	set VRAM address for write
;	input)
;		hl .... target VRAM address
;	output)
;		none
;	break)
;		af, c
; --------------------------------------------------------------------
		scope	vdp_set_vram_address
vdp_set_vram_address::
		ld		c, vdp_port1
		out		[c], l
		ld		a, h
		or		a, 0x40
		out		[c], a
		ret
		endscope

; --------------------------------------------------------------------
;	fill VRAM
;	input)
;		de .... target area size (bytes)
;		a ..... fill data
;	output)
;		none
;	break)
;		af, bc, de, hl
; --------------------------------------------------------------------
		scope	vdp_fill_vram
vdp_fill_vram::
		ld		c, vdp_port0
		ld		b, e
		dec		b
		inc		b
		jr		z, skip1
loop1:
		out		[c], a
		djnz	loop1
skip1:
		inc		d
loop2:
		dec		d
		ret		z
loop3:
		out		[c], a
		djnz	loop3
		jr		loop2
		endscope

; --------------------------------------------------------------------
;	VDP datas
; --------------------------------------------------------------------
vdp_control_regs:
		db		0x00, 0x80				; 0x00 -> R#0 : SCREEN0 (40X24, TEXT Mode)
		db		0x50, 0x81				; 0x50 -> R#1 : SCREEN0 (40X24, TEXT Mode)
		db		0x00, 0x82				; 0x00 -> R#2 : Pattern Name Table is 0x0000
		db		0x01, 0x84				; 0x01 -> R#4 : Pattern Generator Table is 0x0800
		db		0xF4, 0x87				; 0xF4 -> R#7 : Set Color (White on Blue)
		db		0x00, 0x90				; 0x00 -> R#16: Palette selector #0
vdp_control_regs_end:

vdp_palette_regs:
		db		0x00, 0x00				; 0
		db		0x00, 0x00				; 1
		db		0x33, 0x05				; 2
		db		0x44, 0x06				; 3
		db		0x37, 0x02				; 4
		db		0x47, 0x03				; 5
		db		0x52, 0x03				; 6
		db		0x36, 0x05				; 7
		db		0x62, 0x03				; 8
		db		0x63, 0x04				; 9
		db		0x53, 0x06				; 10
		db		0x64, 0x06				; 11
		db		0x21, 0x04				; 12
		db		0x55, 0x03				; 13
		db		0x55, 0x05				; 14
		db		0x77, 0x07				; 15
vdp_palette_regs_end:

include "zg6x8_font.asm"
