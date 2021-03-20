; =============================================================================
;	XEVI”ð‚¯ for MSX2
; -----------------------------------------------------------------------------
;	2019/9/15	t.hara
; =============================================================================

; =============================================================================
;	interrupt
; =============================================================================
	scope		interrupt_process
interrupt_initializer::
	; initialize interrupt hooks
	di
	;	h_keyi
	ld			hl, h_keyi						; Source address
	ld			de, h_keyi_next					; Destination address
	ld			bc, 5							; Transfer length
	ldir										; Block transfer

	ld			a, 0xC3							; 'jp xxxx' code
	ld			[h_keyi], a						; hook update
	ld			hl, h_keyi_interrupt_handler	; set interrupt handler
	ld			[h_keyi + 1], hl

	;	h_timi
	ld			hl, h_timi						; Source address
	ld			de, h_timi_next					; Destination address
	ld			bc, 5							; Transfer length
	ldir										; Block transfer

	ld			a, 0xC3							; 'jp xxxx' code
	ld			[h_timi], a						; hook update
	ld			hl, h_timi_interrupt_handler	; set interrupt handler
	ld			[h_timi + 1], hl
	ei
	ret
	endscope

; =============================================================================
;	H.TIMI interrupt handler
; =============================================================================
	scope		h_timi_interrupt_handler
h_timi_interrupt_handler::

	ld			c, IO_VDP_PORT1

	; -- R#5 = 0b1110_1111
	ld			a, 0b1110_1111
	out			[c], a
	ld			a, 0x80 | 5
	out			[c], a

	; -- R#11 = 0b0000_0000
	ld			a, 0b0000_0000
	out			[c], a
	ld			a, 0x80 | 11
	out			[c], a

h_timi_next::
	ret
	ret
	ret
	ret
	ret
	endscope

; =============================================================================
;	H.KEYI interrupt handler
; =============================================================================
	scope		h_keyi_interrupt_handler
h_keyi_interrupt_handler::

	; Is this Horizontal sync interrupt?
	ld			c, IO_VDP_PORT1
	;	R#15 = 1  : This is status register pointer.
	ld			a, 1					; S#1
	out			[c], a
	ld			a, 0x80 | 15
	out			[c], a
	in			a, [c]

	;	R#15 = 0
	ld			b, 0					; S#0
	out			[c], b
	ld			b, 0x80 | 15
	out			[c], b

	;	Check FH bit (bit0).
	rrca
	jp			nc, h_keyi_next			; Goto old h_keyi hook when this is not Horizontal interrupt.

	; -- R#5 = 0b1110_1111
	ld			a, 0b1110_1111
	out			[c], a
	ld			a, 0x80 | 5
	out			[c], a

	; -- R#11 = 0b0000_0001
	ld			a, 0b0000_0001
	out			[c], a
	ld			a, 0x80 | 11
	out			[c], a

h_keyi_next::
	ret
	ret
	ret
	ret
	ret
	endscope
