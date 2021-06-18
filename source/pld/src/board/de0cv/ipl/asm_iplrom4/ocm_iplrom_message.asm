; --------------------------------------------------------------------
;	IPLROM4 for OCM booting from MMC/SD/SDHC card
;	without data compression
; ====================================================================
;	History
;	ver 3.0.0	caro
;	ver	4.0.0	t.hara
;	ver	4.0.1	t.hara
;	ver	4.0.2	t.hara
;	ver	4.0.3	t.hara
;	ver	4.0.4	t.hara
; --------------------------------------------------------------------

; --------------------------------------------------------------------
;	putc
;	input)
;		a .... char code (ASCII code only, 0x20...0x7F)
;	output)
;		none
;	break)
;		none
; --------------------------------------------------------------------
		scope	putc
putc::
		nop
		out		[vdp_port0], a
		ret
		endscope

; --------------------------------------------------------------------
;	puts
;	input)
;		hl ... message address ( 0 terminated )
;	output)
;		hl ... next address
;	break)
;		af
; --------------------------------------------------------------------
		scope puts
puts::
		ld		a, [hl]
		inc		hl
		or		a, a
		ret		z
		call	putc
		jr		puts
		endscope

; --------------------------------------------------------------------
;	puthex
;	input)
;		a .... target number
;	output)
;		none
;	break)
;		af
; --------------------------------------------------------------------
		scope	puthex
puthex::
		push	af
		rrca
		rrca
		rrca
		rrca
		call	puthex1col
		pop		af

puthex1col:
		and		a, 0x0F
		cp		a, 10
		jr		c, put09
		add		a, 'A' - '0' - 10
put09:
		add		a, '0'
		jr		putc
		endscope

; --------------------------------------------------------------------
;	common messages
; --------------------------------------------------------------------
message_initial_text::
		ds		"Initial Program Loader for OneChipMSX.  "
		ds		"                         Revision 4.0.5 "
		ds		"       OCM-Kai Build date June.17th.2021 "
		db		0

message_sd_boot::
		ds		"Boot from SD Card"
		db		0

message_srom_boot::
		ds		"Boot from SerialROM"
		db		0

message_bios_read_error::
		ds		"[ERROR!] Cannot read BIOS image."
		db		0
