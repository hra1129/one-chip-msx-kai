; =============================================================================
;	MIDITEST for MSX2
; -----------------------------------------------------------------------------
;	2020/02/21	t.hara
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
loop:
	jp			loop
	endscope

; =============================================================================
;	initializer
; =============================================================================
	scope		initializer
initializer::

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
	ld			a, 0b00000001		;	cmd reg: recieve disable, MIDI-IN disable, transmit enable
	out			[ 0xe9 ], a
	call		wait8251

	; --------------------------------------------------------------------------
	;	send MIDI note on
	; --------------------------------------------------------------------------
	ld			a, 0x90
	out			[ 0xe8 ], a
	call		wait8251tx

	ld			a, 60
	out			[ 0xe8 ], a
	call		wait8251tx

	ld			a, 100
	out			[ 0xe8 ], a
	call		wait8251tx
	ret
	endscope

	scope		wait8251
wait8251::
	ret

wait8251tx::
	ld			b, 50
l1:
	call		wait8251
	djnz		l1
	ret
	endscope
end_address::
