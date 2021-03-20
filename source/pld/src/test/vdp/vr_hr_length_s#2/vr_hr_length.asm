; =============================================================================
;	Test to measure VR / HR length for TurboR/OCM-Kai
; -----------------------------------------------------------------------------
;	2020/01/18	t.hara
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
	call		check_cpu
	call		measure_vr
	call		measure_hr
	call		measure_hr_begin
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
;	measurement of VR
; =============================================================================
	scope		measure_vr
measure_vr::
	ld			hl, result_vr
	ld			c, 0xE6			; System Timer Port
	ld			b, 16

measure_vr_loop:
	di
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
	in			e, [c]

wait_vr_low2:
	in			a, [0x99]
	and			a, 0x40
	jp			nz, wait_vr_low2
	in			d, [c]

	xor			a, a
	out			[0x99], a
	ld			a, 0x80 | 15
	out			[0x99], a
	ei

	ld			a, d
	sub			a, e
	ld			[hl], a
	inc			hl
	djnz		measure_vr_loop
	ret
	endscope

; =============================================================================
;	measurement of HR
; =============================================================================
	scope		measure_hr
measure_hr::
	ld			hl, result_hr
	ld			c, 0xE6			; System Timer Port
	ld			b, 16

measure_hr_loop:
	di
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

wait_vr_low2:
	in			a, [0x99]
	and			a, 0x40
	jp			nz, wait_vr_low2

wait_hr_low1:
	in			a, [0x99]
	and			a, 0x20
	jp			nz, wait_hr_low1

wait_hr_high:
	in			a, [0x99]
	and			a, 0x20
	jp			z, wait_hr_high
	in			e, [c]

wait_hr_low2:
	in			a, [0x99]
	and			a, 0x20
	jp			nz, wait_hr_low2
	in			d, [c]

	xor			a, a
	out			[0x99], a
	ld			a, 0x80 | 15
	out			[0x99], a
	ei

	ld			a, d
	sub			a, e
	ld			[hl], a
	inc			hl
	djnz		measure_hr_loop
	ret
	endscope

; =============================================================================
;	measurement of HR begin
; =============================================================================
	scope		measure_hr_begin
measure_hr_begin::
	ld			hl, result_hr_begin
	ld			c, 0xE6			; System Timer Port
	ld			b, 16

measure_hr_loop:
	di
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

wait_vr_low2:
	in			a, [0x99]
	and			a, 0x40
	jp			nz, wait_vr_low2
	in			e, [c]

wait_hr_high:
	in			a, [0x99]
	and			a, 0x20
	jp			z, wait_hr_high
	in			d, [c]

	xor			a, a
	out			[0x99], a
	ld			a, 0x80 | 15
	out			[0x99], a
	ei

	ld			a, d
	sub			a, e
	ld			[hl], a
	inc			hl
	djnz		measure_hr_loop
	ret
	endscope

result_vr:
	db			0, 0, 0, 0, 0, 0, 0, 0
	db			0, 0, 0, 0, 0, 0, 0, 0
result_hr:
	db			0, 0, 0, 0, 0, 0, 0, 0
	db			0, 0, 0, 0, 0, 0, 0, 0
result_hr_begin:
	db			0, 0, 0, 0, 0, 0, 0, 0
	db			0, 0, 0, 0, 0, 0, 0, 0
end_address::
