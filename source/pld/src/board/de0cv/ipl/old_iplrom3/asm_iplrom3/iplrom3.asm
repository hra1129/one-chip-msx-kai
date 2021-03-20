;************************************************
; IPLROM3 for OCM booting from MMC/SD/SDHC-card	*
; 0xwitout data compression						*
; from caro 2008..2019							*
; EPCS64 start adr 0x780000						*
;************************************************
epcs64		=	1								; 1 - EPCS64 else EPCS4
buffer		=	0xC000							; for data
prog		=	0xFC00							; for programm
SDBIOS_LEN	= 	32								; SDBIOS 0xlengt: 32=512 kB, 24=384 kB
;===============================================
;start:
		ld		bc,end_p-st_prog				; len prg
		ld		de,prog							; addr prg
		ld		hl,end_beg						;
		ldir									; copy to RAM
		jp		prog							; start programm

end_beg:
		org		prog
st_prog:
; -----
		ld		a, 0xD4
		out		[0x40], a						; I/O $40 = 212
		ld		a, 0x40							; enable SD/MMC
		ld		[0x6000], a
		ld		bc, 0x100						; b = 1 (1 sector)
		ld		d, c							; cde = 0
		ld		e, c
		ld		hl, buffer						; buffer for sector
		call	rd_card							; read from SD/MMC
		jr		c, rd_EPCS						; error
; read OK
		call	test_MBR						; 0xSearc partition
		jr		c, rd_EPCS						;  CY=1 no partition
; yes partition (cde = sector N)
		push	de
		push	bc
		ld		b, 1							; 1 sector
		ld		hl, buffer						; buffer for DAT
		call	rd_card							;  read PBR
		call	src_FAT							; 0xsearc "FAT"
		pop		bc
		pop		de
		jr		nz,rd_EPCS						; Z=0 - no "FAT"
; yes "FAT"
yes_FAT:
; cde = adress PBR
		call	test_BIOS						; test BIOS on SD
		jr		c, rd_EPCS						;  not BIOS on SD
; read BIOS from SD/MMC/SDHC
		call	prm_SD							; Print message SD
		jr		rd_SD							;  read from SD
;--------------------------------------
; read BIOS from EPCS
rd_EPCS:
		call	prm_EPCS						; Print message EPCS
		ld		hl,ld_EPCS						; for EPCS
		ld		[ p_read + 1 ], hl
;
		ld		a,0x60							; EPCS ON
		ld		[0x6000], a
		ld		de, 0x3C00						; EPCS64 start adr = (0x800000 - 0x080000) / 0x200 <512k
rd_SD:
		call	ld_BIOS							; load BIOS
		jr		c,err_ld						;  error load
;=======================================
; START SYSTEM
		ld		a, 0x80							; enable
		ld		[0x7000], a						;  ermbank
		ld		hl, [0x8000]					;  2 first byte
		xor		a, a							; CY=0
		ld		de, 0x4241						; ="AB" ?
		sbc		hl, de
		jr		z, st_bios						;  start BIOS
; error BIOS
err_ld:
		call	prm_error						; print message ERROR
		jr		$								; cikl
st_bios:
		xor		a, a
		ld		[0x6000], a
		inc		a
		ld		[0x6800], a
		ld		[0x7000], a
		ld		[0x7800], a
		ld		a, 0x0C0
		out		[0x0A8], a						; PPI port a
; test BASIC.ROM
		ld		a, [0x0000]						;  first byte
		cp		a, 0xF3							; = DI ?
		jr		nz,err_ld						;  error
		rst		0								; start MSX BASIC
;=================================
; load BIOS from SD or EPCS4
; c,d,e = sector (512 byte) address in SD or EPCS
ld_BIOS:
		call	prm_step						; print message :>>>
		ld		b, 16+8+4						; 16+8+4 page (28*16 Kb)
		ld		a, 0x80							; bit 7 = 1 enable ermmem
;/---- load 24 page (384 kb) or 32 page (512 kb)
		ld		b,9								; DISKBIOS+MAIN(1)
		call	load_blocks						; load (b) blocks (16 kbyte)
		ret		c								;  error
		call	set_f4_device					; set F4 normal or inverted
		ld		b,SDBIOS_LEN-9					;  MAIN(2)+XBAS+MUS+SUB+KNJ 0xlengt
		call	load_blocks
		ret		c
;\----
		ld		a, ' ' - 0x20
		out		[DATP], a
		ld		a, 'O' - 0x20
		out		[DATP], a
		ld		a, 'K' - 0x20
		out		[DATP], a
		ret										; OK
;======================================
load_blocks:
		ld		[0x7000], a						; ermbank2(8 kb)
		inc		a
		ld		[0x7800], a						; ermbank3(8 kb)
		inc		a
		push	af
		push	bc
; load page 16 kb
		ld		b, 0x20							; 32 sectors
		ld		hl, 0x8000						; buffer
p_read:
		call	rd_card							; read and load
		pop		bc
		pop		hl
		ret		c								; error
		ld		a,'>' - 0x20					;  Print '>'
		out		[DATP], a
		ld		a, h							;
		djnz	load_blocks						;
		ret
;----------------------------------------
; F4 device
set_f4_device:
		ex		af, af'							; '
		ld		a, [0x8000 + 0x002D]			; MSX-ID adr = $002D of MAIN-ROM
		sub		a, 0x03							; MSX-ID = 3 is MSXtR
		out		[0x4F], a						; $0X = normal, $FX = inverted
		out		[0xF4], a						; force MSX logo = on
		ex		af, af'							; '
		ret
;----------------------------------------
; load 16 kbyte from EPCS
; de = adress of sector (512 byte)
; hl = adress of buffer
ld_EPCS:
		push	de
		sla		e								; 
		rl		d								; de*2 adress byte
		xor		a, a							; CY=0
		ld		c, 64							; c=64
		ld		b, a							; b=256
		push	hl
		ld		hl, 0x4000						; /CS=0
		ld		[hl], 0x03						;  RD byte CMD
		ld		[hl], d
		ld		[hl], e
		ld		[hl], a							; =0
		ld		a, [hl]
		pop		de								; de=adress of buffer
;/-----
cikl_3:
		ld		a, [hl]							;
		ld		[de], a
		inc		de
		djnz	cikl_3							; 256 cikl
;\-----
		dec		c
		jr		nz, cikl_3						; 64 cikl
;\\---- 64*256 = 16 kbyte
		ld		a, [0x5000]						; /CS=1
;
		pop		de								; adress of sector
		ld		hl,32							; 32*512 = 16kbyte
		add		hl, de
		ex		de, hl							; next sector (512 byte)
		ret		
;=============================================
prm_step:
; 7*40=280
		ld		a, ( 7 * 40 ) % 256				; col=0, str=7
		out		[CMDP], a
		ld		a, 0x40 + 0x08 + ( 7 * 40 ) / 256
		out		[CMDP], a
		ld		a, ':' - 0x20
		out		[DATP], a
		ret
prm_error:
		push	bc
		push	hl
		ld		hl,t_ERR
; 8*40=320
		ld		a, ( 8 * 40 ) % 256				; col=0, str=8
		ld		C,CMDP							; 0x99
		out		[c],a
		ld		a,0x40 + 0x08 + ( 8 * 40 ) / 256
		jr		prm_2
prm_EPCS:
		push	bc
		push	hl
		ld		hl,t_EPCS
		jr		prm_
prm_SD:
		push	bc
		push	hl
		ld		HL,t_SD							;Send message to display
prm_:
; 6*40=240
		ld		a,6*40							;col=0, str=6
		ld		C,CMDP							;0x99
		out		[c],a
		ld		a,0x40 + 0x08
prm_2:
		out		[c],a							;Adress VRAM = 0x0800
		call	print
		pop		hl
		pop		bc
		ret
;---------------------------------------------
t_SD:
		ds		"Load from SD-card"
		db		0
t_EPCS:
		ds		"Load from EPCS64 "
		db		0
t_ERR:
		ds		"Error BIOS"
		db		0

;=============================================
set41CMD:
		ld		hl,0x4000
		ld		a,[hl]
		ld		[hl], 0x40+41					;CMD41
		ld		[hl], 0x40
		ld		[hl], 0
		ld		[hl], 0
		ld		[hl], 0
		ld		[hl], 0x95						;CRC
		jr		set_							;
;=============================================
set8CMD:
		ld		hl,0x4000
		ld		a,[hl]
		ld		[hl], 0x40+8					;CMD8
		ld		[hl], 0
		ld		[hl], 0
		ld		[hl], 0x01
		ld		[hl], 0x0AA
		ld		[hl], 0x87						;CRC
		jr		set_
;==========================================
; (b) -> CMD
set0cmd:
		ld		c,0								;parametr = 0
		ld		de,0							;
;=============================================
; for SD/MMC
set_cmd:		
		ld		hl, 0x4000						;
type_c	=		$+1
		ld		a, 0							;card type
		cp		a, [hl]							;
		ld		[hl], b							;CMD
		bit		1,a
		jr		z,set_sd						;bit1 = 1 (SDHC)
; for SDHC
		ld		[hl], 0
		ld		[hl], c
		ld		[hl], d
		ld		[hl], e
		jr		set_crc
; for SD/MMC
set_sd: 
		sla		e								;number of sector
		rl		d								; -> number of byte
		rl		c								; cde*2
		ld		[hl], c
		ld		[hl], d
		ld		[hl], e
		ld		[hl], 0
set_crc:
		ld		[hl], 0x95						;CS=0x95
set_:
		ld		a, [hl]
		ld		b, 16
;/-----
cikl_4:
		ld		a, [hl]
		cp		a, 0x0FF
		ccf		
		ret		nc								;no ERROR
		djnz	cikl_4
;\-----
		scf										;ERROR
		ret		
;=================================
; SD Init
init_sd:
		ld		b, 10							;
init_c:
		ld		a, [0x5000]						; /CS=1 (bit12)
		djnz	init_c
;\-----
		ld		b, 0x40+0						; CMD=0 GO_IDLE_STATE
		call	set0cmd
		ret		c								; error
		and		a, 0x0F7							;
		cp		a, 0x01							;bit0 - in idle state ?
		scf										;CY=1
		ret		nz								; error
; bit 0=1 (in idle state)
;--------------------------------
		call	set8CMD							; CMD8
		cp		a, 0x01
		jr		nz, mmc_						; Not SD-card
		ld		a,[hl]
		ld		a,[hl]
		ld		a,[hl]
		and		a, 0x0F
		cp		a, 0x01							;
		scf										;CY=1
		ret		nz								; error
		ld		a,[hl]
		cp		a, 0x0AA
		scf										;CY=1
		ret		nz								; error
;--------------------------------
cikl_i:
		ld		b, 0x40+55						; CMD=55 APP_CMD
		call	set0cmd
		ret		c								; error
		and		a, 4							;bit 2=1 - illegal command
		jr		z, com_OK						;command OK
; command for MMC-card
mmc_:
		xor		a, a							; type_c = 0 (MM-card)
		ld		[type_c],a						; Card type 0-MM, 1 - SD
		ld		b, 0x40+1						; CMD=1 SEND_OP_COND
		call	set0cmd
		jr		corr
; command for SD-card
com_OK:
		ld		a,1								; type_c = 1 (SD-card)
		ld		[type_c],a
		call	set41CMD						; ACMD=41 APP_SEND_OP_COND
corr:
		ret		c								; error
		cp		a, 0x01							; in_idle_state=1 ?
		jr		z, cikl_i						; yes, repeat
;\-------------------------------
; in_idle_state = 0
		or		a, a							; CY=0
		jr		z,init0ok						;		Ok
		scf										; CY=1
		ret										;		error
init0ok:
		ld		a,[type_c]
		or		a, a							; if MMC
		ret		z								;		return
; select SD or SDHC
		ld		b,0x40+58						; CMD58 READ_OCR
		call	set0cmd
		ret		c								; error
		ld		a,[hl]							; read CCS (bit 6)
		cp		a,[hl]
		cp		a,[hl]
		cp		a,[hl]
		bit		6,a								; CCS=1 ?
		ret		z								; SD-card	CCS=0
		ld		a,2								; SDHC-card CCS=1
		ld		[type_c],a
		ret
;==========================================
; reinit SD-card
reinit:
		call	init_sd
		pop		bc
		pop		de
		pop		hl
		ret		c								;error
;***********************************************
; load (b) sectors from MMC/SD/SDHC
; c,d,e = sector number
;***********************************************
rd_card:
		push	hl
		push	de
		push	bc
		ld		b, 0x51							;CMD17 - READ_SINGLE_BLOCK
		call	set_cmd
		jr		c, reinit						;error
;
		pop		bc
		pop		de
		pop		hl
		or		a, a
		scf		
		ret		nz								;error
;
		push	de
		push	bc
		ex		de, hl
		ld		bc, 0x200						;512 byte
		ld		hl, 0x4000
;/------
cikl_5:
		ld		a, [hl]
		cp		a, 0x0FE
		jr		nz, cikl_5
;\------
		ldir									;read sector
		ex		de, hl
		ld		a, [de]
		pop		bc
		ld		a, [de]
		pop		de
		inc		de								;sector+1
		ld		a, d
		or		a, e
		jr		nz, pass_2
;
		inc		c
pass_2:
		djnz	rd_card							;next sector
;
		ret		
;=================================
; 0xsearc "FAT"
src_FAT:
		ld		hl, buffer						;buffer
		ld		bc, 0x80
;/-----
cikl_6:
		ld		a,'F'
		cpir	
		jr		z, pass_3
		ret										;Z=0, no FAT
;-------
pass_3:
		push	hl
		ld		d, [hl]
		inc		hl
		ld		e, [hl]
		ld		hl,'A'*256+'T'					;"AT"
		or		a, a
		sbc		hl, de
		pop		hl
		jr		nz, cikl_6
;\------ yes marker "FAT"
		ret										;Z=1 yes FAT
;=================================
; test MBR - 0xsearc partition
test_MBR:
		ld		b, 4							;number partition
		ld		ix, buffer+0x1be				;offset in sector
;/-----
cikl_7:
		ld		e, [ix+8]						;
		ld		d, [ix+9]						;
		ld		c, [ix+10]						;cde - start sector
		ld		a, c
		or		a, d
		or		a, e							;cde /= 0 OK
		ret		nz								;Yes partition (CY=0)
; next partition
		ld		de, 16
		add		ix, de
		djnz	cikl_7
;\----- no partition
		scf										;CY=1 error
		ret		
;=========================================
; test BIOS on MMC/SD/SDHC
test_BIOS:
		ld		ix, buffer						;PBR sector
;
		ld		l, [ix+0x0E]					;number of reserved
		ld		h, [ix+0x0F]					;sectors
		ld		a, c
		add		hl, de
		adc		a, 0
		ld		c, a
;---
		ld		e, [ix+0x11]					;number of root
		ld		d, [ix+0x12]					;directory entries
		ld		a, e
		and		a, 0x0F
		ld		b, 4
cikl_1:
		srl		d
		rr		e
		djnz	cikl_1
;
		or		a, a
		jr		z, pass_1
;
		inc		de
pass_1:
		push	de
		ld		b, [ix+0x10]					; number of FAT
;
		ld		e, [ix+0x16]					; number of sectors
		ld		d, [ix+0x17]					; per FAT
		ld		a, c
cikl_2:
		add		hl, de
		adc		a, 0
		djnz	cikl_2
;\------
		pop		de
		add		hl, de
		ex		de, hl
		ld		c, a
;
		push	de
		push	bc
		ld		b, 1
		ld		hl, buffer						;buffer
		call	rd_card							; read MMC/SD/SDHC
		ret		c								;  error
;
		ld		hl, [buffer]					;2 first byte
		ld		de,'B'*256+'A'					;'AB' marker disk BIOS
		or		a, a
		sbc		hl, de							;compare
		pop		bc
		pop		de
		ret		z								;yes marker
		scf										;CY=1, error
		ret
;--------------------------------------
print:
		xor		a, a							;Print a string in [HL] up to <0x20
c_prn:
		ld		a,[hl]
		inc		HL
		sub		a, 0x20
		ret		c								;exit if < 0x20
		out		[DATP],a
		jr		c_prn
;-------------------------------
end_p:
; iplrom3.asm
