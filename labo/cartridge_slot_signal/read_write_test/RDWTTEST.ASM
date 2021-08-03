; ==============================================================================
;	READ/WRITE TEST
;
;  Copyright (C) 2021 Takayuki Hara (HRA!)
;  All rights reserved.
; ------------------------------------------------------------------------------
;	Date		Author	Ver		Description
;	2021/8/3	t.hara	1.0		1st release
; ==============================================================================

		include		"MSXBIOS.ASM"
		include		"MSXDOS1.ASM"

		org			0x100
; ==============================================================================
;	エントリーポイント
; ==============================================================================
entry::
		; page1 を SLOT#1-0 にする
		ld			a, 0x81
		ld			h, 0x40
		call		enaslt

		ld			hl, 0x4000
		ld			bc, 0x0102
		di

loop:
		ld			[hl], b
		ld			[hl], c
		ld			a, [hl]
		ld			[hl], b
		ld			[hl], c
		ld			a, [hl]
		ld			[hl], b
		ld			[hl], c
		ld			a, [hl]
		ld			[hl], b
		ld			[hl], c
		ld			a, [hl]
		jp			loop
