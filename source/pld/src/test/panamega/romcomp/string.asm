; =============================================================================
;	string
; -----------------------------------------------------------------------------
;	2019/9/30	t.hara
; =============================================================================

; =============================================================================
;	file_name_to_fcb
;	input)
;		hl ..... 読み込むファイル名のアドレス
;		de ..... オープンしていないFCBのアドレス
;	output)
;		none
;	break)
;		all
; =============================================================================
				scope	file_name_to_fcb
file_name_to_fcb::
				; check drive name
				push	hl
				ld		a, [hl]
				call	is_alpha
				jr		nc, has_no_drive_name
				inc		hl
				ld		b, a
				ld		a, [hl]
				cp		a, ':'					; if a == ':'
				pop		hl
				jr		nz, has_no_drive_name
				inc		hl
				inc		hl
				ld		a, b
				call	tolower					; a = tolower(a) - 'a' + 1
				sub		a, 0x60
				ld		[de], a
				inc		de
				jr		copy_file_name

	has_no_drive_name:
				xor		a, a
				ld		[de], a					; set current drive
				inc		de

	copy_file_name:
				ld		b, 8
	copy_file_name_loop:
				ld		a, [hl]
				cp		a, 0x21
				jr		c, zero_fill_file_name	; Is current char control code?
				cp		a, '.'
				jr		z, zero_fill_file_name	; Is current char '.'?
				inc		hl
				call	toupper
				ld		[de], a
				inc		de
				djnz	copy_file_name_loop
				jr		skip_zero_fill_file_name

	zero_fill_file_name:
				ld		a, 0x20
	zero_fill_file_name_loop:
				ld		[de], a
				inc		de
				djnz	zero_fill_file_name_loop

	skip_zero_fill_file_name:
				ld		a, [hl]
				cp		a, '.'
				jr		nz, copy_ext_name
				inc		hl

	copy_ext_name:
				ld		b, 3
	copy_ext_name_loop:
				ld		a, [hl]
				cp		a, 0x21
				jr		c, zero_fill_ext_name	; Is current char control code?
				inc		hl
				cp		a, 0x2E
				jr		z, zero_fill_ext_name	; Is current char '.'?
				call	toupper
				ld		[de], a
				inc		de
				djnz	copy_ext_name_loop
				jr		skip_zero_fill_ext_name

	zero_fill_ext_name:
				ld		a, 0x20
	zero_fill_ext_name_loop:
				ld		[de], a
				inc		de
				djnz	zero_fill_ext_name_loop
	skip_zero_fill_ext_name:
				ret
				endscope

; =============================================================================
;	is_alpha
;	input)
;		a ...... 調べる文字コード
;	output)
;		cy ..... 0: アルファベットではない, 1: アルファベットである
;	break)
;		f
; =============================================================================
				scope	is_alpha
is_alpha::
				cp		a, 0x41
				jr		c, is_not_alpha
				cp		a, 0x5A + 1
				ret		c
				cp		a, 0x61
				jr		c, is_not_alpha
				cp		a, 0x7A + 1
				ret
	is_not_alpha:
				or		a, a
				ret
				endscope

; =============================================================================
;	toupper
;	input)
;		a ...... 文字コード
;	output)
;		a ...... 大文字に変換したコード
;	break)
;		f
; =============================================================================
				scope	toupper
toupper::
				call	is_alpha
				ret		nc
				and		a, ~0x20
				ret
				endscope

; =============================================================================
;	tolower
;	input)
;		a ...... 文字コード
;	output)
;		a ...... 大文字に変換したコード
;	break)
;		f
; =============================================================================
				scope	tolower
tolower::
				call	is_alpha
				ret		nc
				or		a, 0x20
				ret
				endscope

; =============================================================================
;	memset
;	input)
;		hl ..... フィルする領域の先頭アドレス
;		a ...... フィルする値
;		b ...... フィルする byte数
;	output)
;		hl ..... フィルした領域の次のアドレス
;		b ...... 0
;	break)
;		f, b, hl
; =============================================================================
				scope	memset
memset::
	memset_loop:
				ld		[hl], a
				inc		hl
				djnz	memset_loop
				ret
				endscope
