; -----------------------------------------------------------------------------
;	VDP Command Test Program
; =============================================================================
;	2021/5/25	t.hara
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

		; sprite off
		ld		c, VDP_IO_PORT1
		ld		a, [RG8SAV]
		or		a, 0x02
		di
		out		[c], a
		ld		a, 8 | 0x80
		out		[c], a

		; 192line mode
		ld		a, [RG9SAV]
		and		a, 0x7F
		out		[c], a
		ld		a, 9 | 0x80
		out		[c], a
		ei

		; initialize VRAM
		ld		hl, vc_copy_p0_to_p1
		call	exec_vdpc
		ld		hl, vc_save_background
		call	exec_vdpc
		ld		hl, vc_clear_message_area
		call	exec_vdpc

		ld		hl, message_top

main_loop::
		; clear background to drawing page
		push	hl
		ld		a, [draw_page]
		ld		[vc_clear_background_draw_page], a
		ld		[vc_copy1_message_draw_page], a
		ld		[vc_copy2_message_draw_page], a
		ld		hl, vc_clear_background
		call	exec_vdpc
		pop		hl

		; puts characters
		call	put_one_char
		call	put_one_char
		ld		a,[delay_count]
		inc		a
		cp		a, 3
		jp		c, draw_3rd_char
		xor		a, a
		ld		[delay_count], a
		jr		skip_delay_count
draw_3rd_char:
		ld		[delay_count], a
		call	put_one_char
skip_delay_count:

		; copy message area ---------------------------------------------------
		push	hl

		ld		a, [vc_copy1_message_ny]
		or		a, a
		jr		z, skip_copy1
		ld		hl, vc_copy1_message
		call	exec_vdpc
skip_copy1:

		ld		a, [vc_copy2_message_ny]
		or		a, a
		jr		z, skip_copy2
		ld		hl, vc_copy2_message
		call	exec_vdpc
skip_copy2:

		; care of vc_copy1_message_sy
		ld		a, [vc_copy1_message_sy]
		inc		a
		jr		nz, skip_rewind1
		ld		a, 64
skip_rewind1:
		ld		[vc_copy1_message_sy], a		; 64, 65, 66, ..., 255, 64, 65, ...

		; care of vc_copy1_message_ny
		sub		a, 64
		ld		b, a
		ld		a, 192
		sub		a, b
		ld		[vc_copy1_message_ny], a
		cp		a, 129
		jr		c, skip_vc_copy1_message_ny
		ld		a, 128
		ld		[vc_copy1_message_ny], a
skip_vc_copy1_message_ny:

		; care of vc_copy2_message_dy
		add		a, 32
		ld		[vc_copy2_message_dy], a

		; care of vc_copy2_message_ny
		ld		a, [vc_copy1_message_ny]
		ld		b, a
		ld		a, 128
		sub		a, b
		ld		[vc_copy2_message_ny], a

skip_update_pos:
		; wait complete VDP command
		call	wait_vdpc

		; flip screen
		ld		c, VDP_IO_PORT1
		ld		a, [draw_page]
		add		a, a
		add		a, a
		add		a, a
		add		a, a
		add		a, a
		or		a, 0b00011111
		di
		out		[c], a
		ld		a, 2 | 0x80
		out		[c], a
		ei

		ld		a, [draw_page]
		xor		a, 1
		ld		[draw_page], a

		pop		hl
		jp		main_loop

; -----------------------------------------------------------------------------
;	put one character
		scope	put_one_char
put_one_char::
		; get a character number
		ld		a, [hl]
		inc		hl
		or		a, a
		jr		nz, skip0
		ld		hl, message_top
		ld		a, [hl]

skip0:
		push	hl
		; convert character position
		sub		a, 'a'
		ld		c, 12
		jr		nc, skip1
		ld		c, 0
skip1:
		and		a, 0x1F
		add		a, a
		ld		b, a
		add		a, a
		add		a, b
		ld		[vc_put_char_x], a
		ld		a, c
		ld		[vc_put_char_y], a

		; copy the character
		ld		hl, vc_put_char
		call	exec_vdpc

		; set next put character position
		ld		a, [vc_put_char_pos_x]
		add		a, 6
		cp		a, 224
		jr		c, skip2

		ld		a, [vc_put_char_pos_y]
		add		a, 12
		jp		nz, skip3
		ld		a, 64
skip3:
		ld		[vc_put_char_pos_y], a
		ld		a, 32
skip2:
		ld		[vc_put_char_pos_x], a
		pop		hl
		ret
		endscope

; -----------------------------------------------------------------------------
		scope	wait_vdpc
wait_vdpc::
		; VDPコマンド実行中なら、完了するまで待つ
		ld		c, VDP_IO_PORT1
		ld		de, 15 | 0x80					; d = 0, e = 15 | 0x80
		; R#15 = 2 (S#2 を読むための設定)
		di
		ld		a, 2
		out		[c], a
		out		[c], e
		; a = S#2
wait_ce_flag:
		in		a, [c]
		rrca					; Cy = CE bit
		jr		c, wait_ce_flag
		; R#15 = 0
		out		[c], d
		out		[c], e
		ei
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
		di
		otir

		; 必要ないが、問題のゲームではやってるので真似る 
		xor		a, a
		out		[c], a			; 間違えて VDP_IO_PORT3 に出力している
		ld		a, 0x8F
		out		[c], a

		ei
		ret
		endscope

; -----------------------------------------------------------------------------
;	VDP command table
; -----------------------------------------------------------------------------
		; COPY( 0, 0 )-step( 256, 192 ),0 to ( 0, 0 ),1
vc_copy_p0_to_p1::
		dw		0				; SX: R#32, R#33
		dw		0				; SY: R#34, R#35
		dw		0				; DX: R#36, R#37
		dw		256+0			; DY: R#38, R#39
		dw		256				; NX: R#40, R#41
		dw		192				; NY: R#42, R#43
		db		0				; CLR: R#44
		db		0b0000_0000		; ARG: R#45 DIY = 0, DIX = 0
		db		0b1101_0000		; CMR: R#46 HMMM

		; COPY( 0, 32 )-step( 256, 128 ),0 to ( 0, 192 ),1
vc_save_background::
		dw		0				; SX: R#32, R#33
		dw		32				; SY: R#34, R#35
		dw		0				; DX: R#36, R#37
		dw		256+192			; DY: R#38, R#39
		dw		256				; NX: R#40, R#41
		dw		128				; NY: R#42, R#43
		db		0				; CLR: R#44
		db		0b0000_0000		; ARG: R#45 DIY = 0, DIX = 0
		db		0b1101_0000		; CMR: R#46 HMMM

		; LINE( 0, 64 )-step( 256, 128 ),0,BF
vc_clear_message_area::
		dw		0				; SX: R#32, R#33
		dw		0				; SY: R#34, R#35
		dw		0				; DX: R#36, R#37
		dw		256+192+128		; DY: R#38, R#39
		dw		256				; NX: R#40, R#41
		dw		192				; NY: R#42, R#43
		db		0				; CLR: R#44
		db		0b0000_0000		; ARG: R#45 DIY = 0, DIX = 0
		db		0b1000_0000		; CMR: R#46 LMMV

		; COPY( 32, 192 )-step( 224, 128 ),1 to ( 32, 32 ),draw_page
vc_clear_background::
		dw		0				; SX: R#32, R#33
		dw		256+192			; SY: R#34, R#35
		dw		32				; DX: R#36, R#37
		db		32				; DYl: R#38
vc_clear_background_draw_page:
		db		0				; DYh: R#39
		dw		224				; NX: R#40, R#41
		dw		128				; NY: R#42, R#43
		db		0				; CLR: R#44
		db		0b0000_0000		; ARG: R#45 DIY = 0, DIX = 0
		db		0b1110_0000		; CMR: R#46 YMMM

		; COPY( x, y )-step( 6, 12 ),3 to ( pos_x, pos_y )
vc_put_char::
vc_put_char_x:
		db		0				; SXl: R#32
		db		0				; SXh: R#33
vc_put_char_y:
		db		0				; SYl: R#34		0 or 12
		db		3				; SYh: R#35
vc_put_char_pos_x:
		db		32				; DXl: R#36
		db		0				; DXh: R#37
vc_put_char_pos_y:
		db		64+144			; DYl: R#38
		db		2				; DYh: R#39
		dw		6				; NX: R#40, R#41
		dw		12				; NY: R#42, R#43
		db		0				; CLR: R#44
		db		0b0000_0000		; ARG: R#45 DIY = 0, DIX = 0
		db		0b1101_0000		; CMR: R#46 HMMM

		; COPY( 32, 64+n )-step( 192, n ),2 to ( 0, 32 ),draw_page, TPSET
vc_copy1_message::
		dw		32				; SX: R#32, R#33
vc_copy1_message_sy:
		db		64				; SYl: R#34			64...255
		db		2				; SYh: R#35
		dw		32				; DX: R#36, R#37
		db		32				; DYl: R#38
vc_copy1_message_draw_page:
		db		1				; DYh: R#39
		dw		192				; NX: R#40, R#41
vc_copy1_message_ny:
		db		128				; NYl: R#42
		db		0				; NYh: R#43
		db		0				; CLR: R#44
		db		0b0000_0000		; ARG: R#45 DIY = 0, DIX = 0
		db		0b1001_1000		; CMR: R#46 LMMM TIMP

		; COPY( 32, 64 )-step( 192, 128-n ),2 to ( 0, 32+n ),draw_page, TPSET
vc_copy2_message::
		dw		32				; SX: R#32, R#33
		db		64				; SYl: R#34
		db		2				; SYh: R#35
		dw		32				; DX: R#36, R#37
vc_copy2_message_dy:
		db		32				; DYl: R#38
vc_copy2_message_draw_page:
		db		1				; DYh: R#39
		dw		192				; NX: R#40, R#41
vc_copy2_message_ny:
		db		128				; NYl: R#42
		db		0				; NYh: R#43
		db		0				; CLR: R#44
		db		0b0000_0000		; ARG: R#45 DIY = 0, DIX = 0
		db		0b1001_1000		; CMR: R#46 LMMM TIMP


; -----------------------------------------------------------------------------
;	message string
; -----------------------------------------------------------------------------
message_top::
		;		 01234567890123456789012345678901
		ds		"This is a test program          "
		ds		"I love the MSX                  "
		ds		"       Hoooooooooooo            "
		ds		"Moge Moge       Hoge Hoge FooBar"
		ds		"This is a pen                   "
		ds		"I have a pen     hehehehehe     "
		ds		"             OTL       orz      "
		ds		"        What should I write     "
		ds		"THIS IS A TEST PROGRAM          "
		ds		"TEST TEST TEST TEST test TEST TE"
		ds		"wwwwwwwwwwwww KUSA wwwwwwwwwwwww"
		ds		"     THIS IS A TEST PROGRAM     "
		ds		"    THIS IS A TEST PROGRAM      "
		ds		"   THIS IS A TEST PROGRAM       "
		ds		"  THIS IS A TEST PROGRAM        "
		ds		" THIS IS A TEST PROGRAM         "
		db		0

; -----------------------------------------------------------------------------
;	work area
; -----------------------------------------------------------------------------
draw_page::
		db		1
delay_count::
		db		0

end_address::
