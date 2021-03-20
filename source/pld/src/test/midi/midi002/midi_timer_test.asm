; =============================================================================
;	MIDITEST for MSX2
; -----------------------------------------------------------------------------
;	2020/02/24	t.hara
; =============================================================================

	include		"msx.asm"

	bsave_header	start_address, end_address, entry_point

	org			0xA000
start_address:
; =============================================================================
;	entry point
; =============================================================================
	scope		entry_point
entry_point::
	call		initializer
main:
	;	screen 1
	ld			a, 1
	call		chgmod

loop:
	ld			hl, 0x1800
	call		setwrt

	ld			a, [ count_data_high ]
	ld			b, a
	srl			a
	srl			a
	srl			a
	srl			a
	call		write_char

	ld			a, b
	and			a, 0x0F
	call		write_char
	jp			loop

write_char:
	add			a, '0'
	cp			a, '9' + 1
	jp			c, skip_c1
	add			a, 'A' - '9' - 1
skip_c1:
	out			[ 0x98 ], a				; write VRAM
	ret
	endscope

; =============================================================================
;	initializer
; =============================================================================
	scope		initializer
initializer::

	di
	; --------------------------------------------------------------------------
	;	i8253 initialize
	; --------------------------------------------------------------------------
	ld			a, 0b00010110
	out			[ 0xef ], a			;	counter#0, LSB only, mode3, binary
	ld			a, 8
	out			[ 0xec ], a			;	counter#0 count = 8

	ld			a, 0b10110100
	out			[ 0xef ], a			;	counter#2, MSB&LSB, mode2, binary
	ld			a, 0x20
	out			[ 0xee ], a			;	counter#2 count = 20000
	ld			a, 0x4e
	out			[ 0xee ], a

	; --------------------------------------------------------------------------
	;	i8251 initialize
	; --------------------------------------------------------------------------
	xor			a, a
	out			[ 0xe9 ], a
	call		wait8251
	out			[ 0xe9 ], a
	call		wait8251
	out			[ 0xe9 ], a
	call		wait8251
	ld			a, 0x40
	out			[ 0xe9 ], a
	call		wait8251

	ld			a, 0b01001110		;	mode reg: stop bit = 1bit, parity = disable, char length = 8bit, baud rate = x1/16
	out			[ 0xe9 ], a
	call		wait8251
	ld			a, 0b00000011		;	cmd reg: recieve disable, MIDI-IN disable, timer interrupt enable, transmit enable
	out			[ 0xe9 ], a
	call		wait8251

	; --------------------------------------------------------------------------
	;	set timer hook
	; --------------------------------------------------------------------------

	;	check MSX version
	ld			a, [ 0x002d ]
	cp			a, 3
	jp			c, set_hkeyi

	;	check MSX-MIDI BIOS
	ld			a, [ 0x002e ]
	and			a, 0x01
	jp			z, set_hkeyi

set_hmdtm:
	ld			hl, 0xFF93			; H.MDTM
	ld			de, old_hook
	ld			bc, 5
	ldir

	ld			a, 0xc3
	ld			[ 0xFF93 ], a
	ld			hl, timer_interrupt
	ld			[ 0xFF93 + 1 ], hl
	ei
	ret

set_hkeyi:
	ld			hl, 0xFD9A			; H.KEYI
	ld			de, old_hook
	ld			bc, 5
	ldir

	ld			a, 0xc3
	ld			[ 0xFD9A ], a
	ld			hl, hkeyi_timer_interrupt
	ld			[ 0xFD9A + 1 ], hl
	ei
	ret
	endscope

	; --------------------------------------------------------------------------
	;	8251 access wait
	; --------------------------------------------------------------------------
	scope		wait8251
wait8251::
	ret
	endscope

	; --------------------------------------------------------------------------
	;	timer interrupt routine ( 5 micro-second interval )
	; --------------------------------------------------------------------------
	scope		timer_interrupt
hkeyi_timer_interrupt::
	;	Is this i8253 timer interrupt?
	ld			a, [ 0xe1 ]
	and			a, 0x80
	jp			z, old_hook						; Return when this is not i8253 timer interrupt.

timer_interrupt::
	out			[ 0xea ], a						; Clear interrupt.

	ld			a, [ count_data_low ]
	inc			a
	ld			[ count_data_low ], a
	cp			a, 200
	jp			nz, old_hook

	xor			a, a
	ld			[ count_data_low ], a
	ld			a, [ count_data_high ]
	inc			a
	ld			[ count_data_high ], a

old_hook::
	ret
	ret
	ret
	ret
	ret

count_data_low:
	db			0
count_data_high::
	db			0
	endscope
end_address::
