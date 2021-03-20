; =============================================================================
;	XEVI”ð‚¯ for MSX2
; -----------------------------------------------------------------------------
;	2019/8/30	t.hara
; =============================================================================

; =============================================================================
;	run vdp command
;	input)
;		hl ... register table address (VDP R#32...R#46)
; =============================================================================
	scope		run_vdp_command
run_vdp_command::
	;	VDP R#17 = 32
	ld			a, 32
	di
	out			[IO_VDP_PORT1], a
	ld			a, 0x80 | 17
	out			[IO_VDP_PORT1], a
	;	R#32~46 (15 registers)
	ld			bc, (15 << 8) | IO_VDP_PORT3
	otir
	ei
	ret
	endscope

; =============================================================================
;	wait vdp command
; =============================================================================
	scope		wait_vdp_command
wait_vdp_command::
loop:
	di
	;	VDP R#15 = 2
	ld			a, 2
	ld			bc, ((0x80 | 15) << 8) | IO_VDP_PORT1
	out			[c], a
	out			[c], b
	in			a, [c]
	and			a, 1
	jp			nz, loop

	;	VDP R#15 = 0
	xor			a, a
	out			[c], a
	out			[c], b
	ei
	ret
	endscope

; =============================================================================
;	set VRAM address
;	input)
;		hl ....... VRAM address (A13...A0: MSB2bit must set be 0b01)
;	output)
;		c ........ VDP Port#0 address
;	break)
;		none
;	note)
;		disable interrupt
; =============================================================================
	scope		set_vram_address
set_vram_address::
	ld			c, IO_VDP_PORT1
	di
	out			[c], l
	out			[c], h
	ei
	dec			c
	ret
	endscope
