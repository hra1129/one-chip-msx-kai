; =============================================================================
;	Test to measure VR / HR length for TurboR/OCM-Kai
; -----------------------------------------------------------------------------
;	2020/01/22	t.hara
; =============================================================================

	include		"msx.asm"

	bsave_header	start_address, end_address, entry_point

	org			0xC000
start_address:
; =============================================================================
;	entry point
; =============================================================================
	scope		entry_point
entry_point::
	call		check_cpu
	call		polling_s2
	ret
	endscope

; =============================================================================
;	check cpu
; =============================================================================
	scope		check_cpu
check_cpu::
	ld			a, 0x002D
	cp			a, 3
	ret			c

	; change to Z80 mode
	ld			a, 0x80
	call		0x0180
	ret
	endscope

; =============================================================================
;	measurement
; =============================================================================
	scope		polling_s2
polling_s2::
	ld			hl, 0x4000		; Page 1
	ld			a, 0b10000011	; Slot #3-0
	call		ENASLT			; Change Slot and DI

	ld			hl, 0x4000
	ld			b, 0

measure_vr_loop:
	ld			a, 2			; Status Register #2
	out			[0x99], a
	ld			a, 0x80 | 15
	out			[0x99], a

wait_vr_low1:
	in			a, [0x99]
	and			a, 0x40
	jp			nz, wait_vr_low1

wait_vr_high:
	in			a, [0x99]
	and			a, 0x40
	jp			z, wait_vr_high

dump_loop:
	repeat 		i, 64
		in			a, [0x99]
		ld			[hl], a
		inc			hl
	endr
	dec			b
	jp			nz, dump_loop

	xor			a, a			; Status Register #0
	out			[0x99], a
	ld			a, 0x80 | 15
	out			[0x99], a

transfer_to_vram:
	xor			a, a
	out			[0x99], a
	ld			a, 0x80 | 14
	out			[0x99], a		; R#14 (VRAM Address[16:14]) = 0

	xor			a, a
	out			[0x99], a
	ld			a, 0x40
	out			[0x99], a

	ld			d, 0x40
	ld			hl, 0x4000
transfer_to_vram_loop:
	ld			bc, 0x0098
	otir
	dec			d
	jp			nz, transfer_to_vram_loop

	ld			hl, 0x4000		; Page 1
	ld			a, 0b10000000	; Slot #0-0
	call		ENASLT			; Change Slot and DI
	ei
	ret
	endscope
end_address::
