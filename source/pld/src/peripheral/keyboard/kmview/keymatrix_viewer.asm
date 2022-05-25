; =============================================================================
;  Key Matrix Viewer
;  May/25th/2022  t.hara
; =============================================================================

			org		0xC000
start::
			di
			ld		a, 0xF0
			ld		c, 0xA9
			ld		hl, result
l1:
			out		[0xAA], a
			in		b, [c]
			ld		[hl], b
			inc		hl
			inc		a
			jr		nz, l1
			ei
			ret

result::
			space	16, 0			; 16bytes (0 fill)
