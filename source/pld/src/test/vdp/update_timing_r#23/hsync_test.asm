; =============================================================================
;	HSYNC_TEST for MSX2
; -----------------------------------------------------------------------------
;	2019/12/09	t.hara
; =============================================================================

	include		"msx.asm"

	bsave_header	start_address, end_address, entry_point

hsync_intr_adjust	:= 3

	org			0xA000
start_address:
; =============================================================================
;	entry point
; =============================================================================
	scope		entry_point
entry_point::
	call		initializer
loop:
	jp			loop
	endscope

; =============================================================================
;	initializer
; =============================================================================
	scope		initializer
initializer::
	; SCREEN5
	ld			a, 5
	call		chgmod

	ld			hl, clear_screen
	call		wait_vdp_command
	call		run_vdp_command

	ld			hl, bottom_fill
	call		wait_vdp_command
	call		run_vdp_command

	call	interrupt_initializer

	di
	; Initialize VDP
	ld			c, IO_VDP_PORT1

	; -- R#1 = R#1 | 0x03
	;   -- Sprite size: 16x16, Sprite magnifyer ON
	ld			a, [REG1SAV]
	or			a, 0x03
	out			[c], a
	ld			a, 0x80 | 1
	out			[c], a

	; -- R#19 = 112 - hsync_intr_adjust
	;   -- HSYNC interrupt line number
	ld			a, 112 - hsync_intr_adjust
	out			[c], a
	ld			a, 0x80 | 19
	out			[c], a

	; -- R#0 = R#0 | 0b0001_0000
	;   -- HSYNC interrupt ON
	ld			a, [REG0SAV]
	or			a, 0b0001_0000
	out			[c], a
	ld			a, 0x80 | 0
	out			[c], a

	; -- R#14 = 1
	;   -- VRAM address A16,A15,A14
	ld			a, 0x01
	out			[c], a
	ld			a, 0x80 | 14
	out			[c], a
	ei

	; Set VRAM address (A13-A0)
	ld			hl, 0x3600 | 0x4000
	call		set_vram_address

	; put sprite #0...#7
	ld			hl, sprite_attribute0
	ld			b, 4 * 8
	otir

	; Set VRAM address (A13-A0)
	ld			hl, 0x3400 | 0x4000
	call		set_vram_address

	; color sprite 
	ld			hl, sprite_color0
	ld			b, 16 * 8
	otir

	; Set VRAM address (A13-A0)
	ld			hl, 0x3800 | 0x4000
	call		set_vram_address

	; sprite pattern
	ld			hl, sprite_pattern
	ld			b, 32
	otir

	ret
	endscope

	include "vdp_control.asm"
	include "interrupt.asm"

clear_screen:					; line (0,0)-step(256,256),0,bf
	db			0				; R#32	SXl
	db			0				; R#33	SXh
	db			0				; R#34	SYl
	db			0				; R#35	SYh
	db			0				; R#36	DXl
	db			0				; R#37	DXh
	db			0				; R#38	DYl
	db			0				; R#39	DYh
	db			0				; R#40	NXl
	db			1				; R#41	NXh
	db			0				; R#42	NYl
	db			1				; R#43	NYh
	db			0x00			; R#44	CLR
	db			0				; R#45	ARG
	db			0b1100_0000		; R#46	CMD	HMMV

bottom_fill:
	db			0				; R#32	SXl
	db			0				; R#33	SXh
	db			0				; R#34	SYl
	db			0				; R#35	SYh
	db			0				; R#36	DXl
	db			0				; R#37	DXh
	db			112				; R#38	DYl
	db			0				; R#39	DYh
	db			0				; R#40	NXl
	db			1				; R#41	NXh
	db			112				; R#42	NYl
	db			0				; R#43	NYh
	db			0xCC			; R#44	CLR
	db			0				; R#45	ARG
	db			0b1100_0000		; R#46	CMD	HMMV

sprite_attribute0:
	db			112 - 32		; SP#0 Y
	db			32*0			; SP#0 X
	db			0				; SP#0 Pattern0
	db			0				; SP#0 N/A
	db			112 - 32		; SP#1 Y
	db			32*1			; SP#1 X
	db			0				; SP#1 Pattern0
	db			0				; SP#1 N/A
	db			112 - 32		; SP#2 Y
	db			32*2			; SP#2 X
	db			0				; SP#2 Pattern0
	db			0				; SP#2 N/A
	db			112 - 32		; SP#3 Y
	db			32*3			; SP#3 X
	db			0				; SP#3 Pattern0
	db			0				; SP#3 N/A
	db			112 - 32		; SP#4 Y
	db			32*4			; SP#4 X
	db			0				; SP#4 Pattern0
	db			0				; SP#4 N/A
	db			112 - 32		; SP#5 Y
	db			32*5			; SP#5 X
	db			0				; SP#5 Pattern0
	db			0				; SP#5 N/A
	db			112 - 32		; SP#6 Y
	db			32*6			; SP#6 X
	db			0				; SP#6 Pattern0
	db			0				; SP#6 N/A
	db			112 - 32		; SP#7 Y
	db			32*7			; SP#7 X
	db			0				; SP#7 Pattern0
	db			0				; SP#7 N/A

sprite_pattern:
	db			0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF
	db			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	db			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	db			0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF

sprite_color0:
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F

	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F

	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F

	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F

	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F

	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F

	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F

	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	db			0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
end_address::
