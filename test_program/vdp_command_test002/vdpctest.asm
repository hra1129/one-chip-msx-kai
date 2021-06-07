; -----------------------------------------------------------------------------
;	VDP Command Test Program
; =============================================================================
;	2021/6/3	t.hara
; -----------------------------------------------------------------------------

VDP_IO_PORT1	= 0x99
VDP_IO_PORT2	= 0x9A
VDP_IO_PORT3	= 0x9B

RG8SAV			= 0xFFE7
RG9SAV			= 0xFFE8

		; BSAVE header
		db		0xFE
		dw		start_address
		dw		end_address
		dw		start_address

		; Program body
		org		0xC000

start_address::

		; initialize VRAM
		ld		hl, vc_fill
		call	exec_vdpc
		call	wait_vdpc
		ret

; -----------------------------------------------------------------------------
		scope	wait_vdpc
wait_vdpc::
		; VDPコマンド実行中なら、完了するまで待つ
		ld		c, VDP_IO_PORT1
		ld		de, 15 | 0x80					; d = 0, e = 15 | 0x80
wait_ce_flag:
		; R#15 = 2 (S#2 を読むための設定)
		di
		ld		a, 2
		out		[c], a
		out		[c], e
		; a = S#2
		in		a, [c]
		; R#15 = 0
		out		[c], d
		out		[c], e
		ei
		rrca					; Cy = CE bit
		jr		c, wait_ce_flag
		ret
		endscope

; -----------------------------------------------------------------------------
;	execute VDP command
;	input)
;		HL .... VDP command table
;	output)
;		none
;	break)
;		AF, BC, DE, HL
; -----------------------------------------------------------------------------
		scope	exec_vdpc
exec_vdpc::
		call	wait_vdpc
		; R#17 = 32 (R#32からの間接連続書き込み設定)
		ld		a, 32
		di
		out		[c], a
		ld		a, 17 | 0x80
		out		[c], a
		ei

		; R#32～R#46 に sx～cmr をまとめて書き込む
		ld		bc, (15 << 8) | VDP_IO_PORT3	; R#32～R#46 は 15個のレジスタ
		otir
		ret
		endscope

; -----------------------------------------------------------------------------
;	VDP command table
; -----------------------------------------------------------------------------
		; SET PAGE,1: LINE( 0, 0 )-step( 256, 212 ),0,BF
vc_fill::
		dw		0				; SX: R#32, R#33
		dw		256				; SY: R#34, R#35
		dw		0				; DX: R#36, R#37
		dw		256				; DY: R#38, R#39
		dw		256				; NX: R#40, R#41
		dw		212				; NY: R#42, R#43
		db		0				; CLR: R#44
		db		0b0000_0000		; ARG: R#45 DIY = 0, DIX = 0
		db		0b1100_0000		; CMR: R#46 HMMV

end_address::
