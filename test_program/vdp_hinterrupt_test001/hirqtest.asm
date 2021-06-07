; -----------------------------------------------------------------------------
;	VDP Register Test Program
; =============================================================================
;	2021/6/6	t.hara
; -----------------------------------------------------------------------------

VDP_IO_PORT0	= 0x98
VDP_IO_PORT1	= 0x99
VDP_IO_PORT2	= 0x9A
VDP_IO_PORT3	= 0x9B

RG0SAV			= 0xF3DF

		; BSAVE header
		db		0xFE
		dw		start_address
		dw		end_address
		dw		start_address

		; Program body
		org		0xC000

start_address::
; =====================================================================
;	N = 300, 299, ... , 1 で繰り返す
; =====================================================================
		scope	main_loop
		ld		hl, 300
main_loop::
		call	sub_proc
		dec		hl
		ld		a, h
		or		a, l
		jp		nz, main_loop
		ret
		endscope

; =====================================================================
;	N = HL で処理
; =====================================================================
		scope	sub_proc
sub_proc::
		push	hl
		ld		e, l
		ld		d, h

		di							; 割り込み禁止

		ld		a, 128				; R#19 = 128
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 19
		out		[VDP_IO_PORT1], a

		ld		a, [RG0SAV]			; R#0 = R#0 | 0x10
		or		a, 0x10
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 0
		out		[VDP_IO_PORT1], a

		; V-Blanking を抜けるのを待つ
		ld		a, 2				; R#15 = 2
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 15
		out		[VDP_IO_PORT1], a
wait_non_v_blank:
		in		a, [VDP_IO_PORT1]
		and		a, 0x40
		jp		nz, wait_non_v_blank

		; V-Blanking に入るのを待つ
wait_v_blank:
		in		a, [VDP_IO_PORT1]
		and		a, 0x40
		jp		z, wait_v_blank

		; S#0, S#1 を読んでステータスクリア
		ld		a, 0				; R#15 = 0
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 15
		out		[VDP_IO_PORT1], a
		in		a, [VDP_IO_PORT1]

		ld		a, 1				; R#15 = 1
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 15
		out		[VDP_IO_PORT1], a
		in		a, [VDP_IO_PORT1]

		ld		a, 2				; R#15 = 2
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 15
		out		[VDP_IO_PORT1], a

		; N回 H-Blank 発生を待つ
count_h_blank_loop:
wait_non_h_blank:
		in		a, [VDP_IO_PORT1]
		and		a, 0x20
		jp		nz, wait_non_h_blank

		; H-Blanking に入るのを待つ
wait_h_blank:
		in		a, [VDP_IO_PORT1]
		and		a, 0x20
		jp		z, wait_h_blank

		dec		hl
		ld		a, h
		or		a, l
		jp		nz, count_h_blank_loop

		; S#1 を読む
		ld		a, 1				; R#15 = 1
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 15
		out		[VDP_IO_PORT1], a
		in		a, [VDP_IO_PORT1]

		; 結果を result に格納
		ld		hl, result
		add		hl, de
		ld		[hl], a

		; S#0 を読んでステータスクリア
		ld		a, 0				; R#15 = 0
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 15
		out		[VDP_IO_PORT1], a
		in		a, [VDP_IO_PORT1]

		ld		a, [RG0SAV]			; R#0 = R#0 & ~0x10
		and		a, ~0x10
		out		[VDP_IO_PORT1], a
		ld		a, 0x80 | 0
		out		[VDP_IO_PORT1], a

		pop		hl
		ei							; 割り込み許可
		ret
		endscope

; =====================================================================
;	結果格納先
; =====================================================================
result::
		space	300
end_address::
