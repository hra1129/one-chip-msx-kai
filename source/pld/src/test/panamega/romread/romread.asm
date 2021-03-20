; =============================================================================
;	Panasonic MegaROM Controller Test Program
; -----------------------------------------------------------------------------
;	2020/07/17	t.hara
; =============================================================================

	include		"msx.asm"

	bsave_header	start_address, end_address, start_address

PMEGA_LOWER_BANK0	:= 0x6000		; Bank register for 0000h-1FFFh
PMEGA_LOWER_BANK1	:= 0x6400		; Bank register for 2000h-3FFFh
PMEGA_LOWER_BANK2	:= 0x6800		; Bank register for 4000h-5FFFh
PMEGA_LOWER_BANK3	:= 0x6C00		; Bank register for 6000h-7FFFh
PMEGA_LOWER_BANK4	:= 0x7000		; Bank register for 8000h-9FFFh
PMEGA_LOWER_BANK5	:= 0x7400		; Bank register for A000h-BFFFh
PMEGA_LOWER_BANK6	:= 0x7800		; Bank register for C000h-DFFFh
PMEGA_LOWER_BANK7	:= 0x7C00		; Bank register for E000h-FFFFh
PMEGA_UPPER_BANK	:= 0x7FF8

	org			0xA000

start_address::

; =============================================================================
;	Read Command
; =============================================================================
read_command::
	; Get USR argument
	inc			hl
	inc			hl
	ld			[result_address], hl
	ld			e, [hl]
	inc			hl
	ld			d, [hl]
	ld			[target_address], de

	; Set Slot#3-3 at page1
	ld			a, 0b1_000_11_11
	ld			hl, 0x4000
	call		ENASLT

	; Change upper bank
	ld			a, [target_bank + 1]
	and			a, 0x01
	rlca
	rlca
	ld			[PMEGA_UPPER_BANK], a

	; Change lower bank
	ld			a, [target_bank + 0]
	ld			[PMEGA_LOWER_BANK2], a

	; Read target address
	ld			hl, [target_address]
	ld			a, [hl]
	ld			[read_data], a

	; Set MAIN-ROM at page1
	ld			a, [EXPTBL0]
	ld			hl, 0x4000
	call		ENASLT

	; Return value
	ld			hl, [result_address]
	ld			a, [read_data]
	ld			[hl], a
	inc			hl
	xor			a, a
	ld			[hl], a
	ret

; =============================================================================
;	Write Command
; =============================================================================
write_command::
	; Get USR argument
	inc			hl
	inc			hl
	ld			[result_address], hl
	ld			e, [hl]
	inc			hl
	ld			d, [hl]
	ld			[target_address], de

	; Set Slot#3-3 at page1
	ld			a, 0b1_000_11_11
	ld			hl, 0x4000
	call		ENASLT

	; Change upper bank
	ld			a, [target_bank + 1]
	and			a, 0x01
	rlca
	rlca
	ld			[PMEGA_UPPER_BANK], a

	; Change lower bank
	ld			a, [target_bank + 0]
	ld			[PMEGA_LOWER_BANK2], a

	; Write target address
	ld			hl, [target_address]
	ld			a, [write_data]
	ld			[hl], a

	; Set MAIN-ROM at page1
	ld			a, [EXPTBL0]
	ld			hl, 0x4000
	call		ENASLT

	; Return value
	ld			hl, [result_address]
	ld			a, [write_data]
	ld			[hl], a
	inc			hl
	xor			a, a
	ld			[hl], a
	ret

result_address::
	dw			0
target_address::
	dw			0
target_bank::
	dw			0
read_data::
	db			0
write_data::
	db			0
end_address::
