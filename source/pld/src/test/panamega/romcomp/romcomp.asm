; =============================================================================
;	Panasonic MegaROM Controller Test Program
; -----------------------------------------------------------------------------
;	2020/07/14	t.hara
; =============================================================================

	include		"msx.asm"

	; This is MSX-DOS command.
	org			0x0100
start_address::
	; Message
	ld			de, message_romcomp
	ld			c, BDOS_FUNC_STR_OUT
	call		BDOS_ON_MSXDOS

	; Change page1 (4000h-7FFFh) to Panasonic MegaROM
	ld			a, 0b1_000_11_11
	ld			hl, 0x4000
	call		ENASLT

	call		exec_compare

	; Change page1 (4000h-7FFFh) to MainRAM
	ld			a, 0b1_000_11_00
	ld			hl, 0x4000
	call		ENASLT
	ret

exec_compare:
	; Compare 1st 1MB
	ld			hl, file001
	call		open_fcb
	or			a, a
	jp			z, error_exit

	ld			de, file001
	ld			c, BDOS_FUNC_STR_OUT
	call		BDOS_ON_MSXDOS

	ld			bc, 0x0000				; ROM Bank 0x000
	call		compare_1mb
	call		close_fcb

	; Compare 2nd 1MB
	ld			hl, file002
	call		open_fcb
	or			a, a
	jp			z, error_exit

	ld			de, file002
	ld			c, BDOS_FUNC_STR_OUT
	call		BDOS_ON_MSXDOS

	ld			bc, 0x0080				; ROM Bank 0x080
	call		compare_1mb
	call		close_fcb

	; Compare 3rd 1MB
	ld			hl, file003
	call		open_fcb
	or			a, a
	jp			z, error_exit

	ld			de, file003
	ld			c, BDOS_FUNC_STR_OUT
	call		BDOS_ON_MSXDOS

	ld			bc, 0x0100				; ROM Bank 0x100
	call		compare_1mb
	call		close_fcb

	; Compare 4th 1MB
	ld			hl, file004
	call		open_fcb
	or			a, a
	jp			z, error_exit

	ld			de, file004
	ld			c, BDOS_FUNC_STR_OUT
	call		BDOS_ON_MSXDOS

	ld			bc, 0x0180				; ROM Bank 0x180
	call		compare_1mb
	call		close_fcb

	ld			de, message_complete
	ld			c, BDOS_FUNC_STR_OUT
	call		BDOS_ON_MSXDOS
	ret

error_exit::
	ld			de, message_error
	ld			c, BDOS_FUNC_STR_OUT
	call		BDOS_ON_MSXDOS
	ret

; =============================================================================
;	Compare 1MB
; =============================================================================
	scope		compare_1mb
compare_1mb::
	ld			a, 128
loop:
	push		af
	push		bc
	call		load_8kb
	pop			bc
	push		bc
	call		compare_8kb
	call		nz, error_exit
	pop			bc
	pop			af
	inc			bc
	dec			a
	jr			nz, loop
	ret
	endscope

; =============================================================================
;	Compare 8KB
; =============================================================================
	scope		compare_8kb
compare_8kb::
	; Change ROM Bank (4000h-5FFFh)
	ld			a, c
	ld			[0x6800], a
	ld			a, b
	rlca
	rlca
	ld			[0x7ff8], a

	; Compare 8KB
	ld			bc, 8192
	ld			hl, dump_work
	ld			de, 0x4000
loop:
	ld			a, [de]
	cpi
	ret			nz
	inc			de
	ld			a, b
	or			a, c
	jr			nz, loop
	ret
	endscope

; =============================================================================
;	Load 8KB
;
;	Transfer from 8KB in file to dump_work
; =============================================================================
	scope		load_8kb
load_8kb::
	push		bc
	push		de
	push		hl

	ld			b, 8192 / 128
	ld			de, dump_work			; Destination Address
loop:
	push		bc
	push		de
	call		get_one_block_from_fcb
	pop			de

	ld			hl, 0x0080				; Source Address (DTA)
	ld			bc, 0x0080				; Transfer size (DTA size)
	ldir
	pop			bc
	djnz		loop

	pop			hl
	pop			de
	pop			bc
	ret
	endscope

; =============================================================================
;	Open FCB
;	input)
;		HL ... Address of target file name.
;	output)
;		A .... 0: Failed, 1: Success
; =============================================================================
	scope		open_fcb
open_fcb::
		; copy file name to FCB
		ld		de, fcb
		call	file_name_to_fcb
		; zero fill
		ld		hl, fcb_current_block
		ld		b, 25
		xor		a, a
		call	memset
		; open target file
		ld		de, fcb
		ld		c, BDOS_FUNC_FCB_OPEN_FILE
		call	BDOS_ON_MSXDOS
		inc		a
		ret		z
		; change read buffer
		ld		de, 0x80
		ld		c, BDOS_FUNC_SET_DTA
		call	BDOS_ON_MSXDOS
		ld		a, 1
		ret
	endscope

; =============================================================================
;	Close FCB
;	input)
;		None
;	output)
;		None
; =============================================================================
	scope		close_fcb
close_fcb::
		ld		de, fcb
		ld		c, BDOS_FUNC_FCB_CLOSE_FILE
		call	BDOS_ON_MSXDOS
		ret
	endscope

; =============================================================================
;	Get one block
; =============================================================================
	scope		get_one_block_from_fcb
get_one_block_from_fcb::
		ld		c, BDOS_FUNC_FCB_SEQ_READ
		ld		de, fcb
		call	BDOS_ON_MSXDOS
		ret
	endscope

		include	"string.asm"

; =============================================================================
;	work area
; =============================================================================
fcb:
fcb_drive_id:
		db		0					; 0: default drive, 1: A, 2: B ...
fcb_file_name:
		ds		"        "			; file name
fcb_ext_name:
		ds		"   "				; ext. file name
fcb_current_block:
		dw		0					; current block
		dw		0					; recode size
		dd		0					; file size
		dw		0					; date
		dw		0					; time
		db		0					; device ID
		db		0					; directory location
		dw		0					; top cluster
		dw		0					; last access cluster
		dw		0					; relative cluster number
		db		0					; current record
		dd		0					; random record
file001:
		ds		"A1GTFRM1.ROM"
		db		0x0D, 0x0A, '$'
file002:
		ds		"A1GTFRM2.ROM"
		db		0x0D, 0x0A, '$'
file003:
		ds		"A1GTFRM3.ROM"
		db		0x0D, 0x0A, '$'
file004:
		ds		"A1GTFRM4.ROM"
		db		0x0D, 0x0A, '$'

message_romcomp::
		ds		"ROM COMP v1.0"
		db		0x0D, 0x0A, '$'

message_complete::
		ds		"Completed."
		db		0x0D, 0x0A, '$'
message_error::
		ds		"Error."
		db		0x0D, 0x0A, '$'

dump_work::
end_address::
