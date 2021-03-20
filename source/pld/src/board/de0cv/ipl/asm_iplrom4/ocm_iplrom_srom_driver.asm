; --------------------------------------------------------------------
;	IPLROM4 for OCM booting from MMC/SD/SDHC card
;	without data compression
; ====================================================================
;	History
;	ver 3.0.0	caro
;	ver	4.0.0	t.hara
; --------------------------------------------------------------------

; --------------------------------------------------------------------
;	EPCS Operation Codes
; --------------------------------------------------------------------
EPCS_WRITE_ENABLE		:= 0b0000_0110
EPCS_WRITE_DISABLE		:= 0b0000_0100
EPCS_READ_STATUS		:= 0b0000_0101
EPCS_READ_BYTES			:= 0b0000_0011
EPCS_READ_SILICON_ID	:= 0b1010_1011			; require EPCS1/4/16/64
EPCS_FAST_READ			:= 0b0000_1011
EPCS_WRITE_STATUS		:= 0b0000_0001
EPCS_WRITE_BYTES		:= 0b0000_0010
EPCS_ERASE_BULK			:= 0b1100_0111
EPCS_ERASE_SECTOR		:= 0b1101_1000
EPCS_READ_DEVICE_ID		:= 0b1001_1111			; require EPCS128 or later

;----------------------------------------
; load 16KB from SerialROM(EPCS)
; de = adress of sector (512 byte)
; hl = adress of buffer
; b  = number of sectors (1~127)
		scope	srom_reader
srom_reader::
		push	de
		sla		e								; 
		rl		d								; de * 2
		xor		a, a							; dea = byte address, CY = 0
		ld		c, b
		sla		c								; c = {number of sectors} * 2  : number of half sectors
		ld		b, a							; b = 256

		push	bc								; save number of half sectors
		push	hl
		ld		hl, megasd_sd_register|(0<<12)	; /CS=0 (address bit12)
		ld		[hl], EPCS_READ_BYTES			; command byte
		ld		[hl], d							; byte address b23-b16
		ld		[hl], e							; byte address b15-b8
		ld		[hl], a							; byte address b7-b0
		ld		a, [hl]
		pop		de								; de = adress of buffer

read_all:
read_half_sector:
		ld		a, [hl]							; read 1byte
		ld		[de], a							; write 1byte to buffer
		inc		de
		djnz	read_half_sector
		dec		c
		jr		nz, read_all

		ld		a, [megasd_sd_register|(1<<12)]	; /CS=1 (address bit12)

		pop		hl								; H = number of half sectors
		pop		de								; adress of sector
		srl		l
		ld		h, 0
		add		hl, de
		ex		de, hl							; next sector (512 byte)
		xor		a, a							; Cy = 0
		ret
		endscope
