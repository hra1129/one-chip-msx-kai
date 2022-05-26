; =============================================================================
;  OCM Status Monitor
;  for OCM-PLD Pack v3.1 or later
;  Programmed by t.hara
; =============================================================================

BDOS		:= 0x0005
_TERM0		:= 0x00
CALSLT		:= 0x001C
CHGMOD		:= 0x005F
ERAFNK		:= 0x00CC
FORCLR		:= 0xF3E9
BAKCLR		:= 0xF3EA
BDRCLR		:= 0xF3EB
EXPTBL		:= 0xFCC1

			org		0x100

; -----------------------------------------------------------------------------
			scope	main
main::
			call	check_switchio
			call	makeup_screen

exit_program::
			ld		c, _TERM0
			jp		bdos
			endscope

; -----------------------------------------------------------------------------
			scope	makeup_screen
makeup_screen::
			; COLOR 15,0,0
			ld		a, 15
			ld		[FORCLR], a
			xor		a, a
			ld		[BAKCLR], a
			ld		[BDRCLR], a
			; SCREEN0
			ld		iy, [EXPTBL - 1]
			ld		ix, CHGMOD
			ld		a, 0
			call	CALSLT
			; KEYOFF
			ld		iy, [EXPTBL - 1]
			ld		ix, ERAFNK
			ld		a, 0
			call	CALSLT
			ret
			endscope

; -----------------------------------------------------------------------------
			scope	check_switchio
check_switchio::
			ld		a, 212
			out		[0x40], a
			in		a, [0x40]
			cp		a, ~212
			ret		z
			; switchio is not found.
			
			
			
			endscope
