; --------------------------------------------------------------------
;	IPLROM4 for OCM booting from MMC/SD/SDHC card
;	without data compression
; ====================================================================
;	History
;	ver 3.0.0	caro
;	ver	4.0.0	t.hara
; --------------------------------------------------------------------

; --------------------------------------------------------------------
;	SD Card Command
; --------------------------------------------------------------------
SDCMD_GO_IDLE_STATE				:= 0
SDCMD_SEND_IO_COND				:= 1
SDCMD_SEND_IF_COND				:= 8
SDCMD_SEND_CSD					:= 9
SDCMD_SEND_CID					:= 10
SDCMD_SEND_STATUS				:= 13
SDCMD_SEND_BKICKLEN				:= 16
SDCMD_READ_SINGLE_BLK			:= 17
SDCMD_WRITE_BLOCK				:= 24
SDCMD_PROGRAM_CSD				:= 27
SDCMD_SET_WRITE_PROT			:= 28
SDCMD_CLR_WRITE_PROT			:= 29
SDCMD_SEND_WRITE_PROT			:= 30
SDCMD_TAG_SECT_START			:= 32
SDCMD_TAG_SECT_END				:= 33
SDCMD_UNTAG_SECTOR				:= 34
SDCMD_TAG_ERASE_G_SEL			:= 35
SDCMD_TAG_ERASE_G_END			:= 36
SDCMD_UNTAG_ERASE_GRP			:= 37
SDCMD_ERASE						:= 38
SDCMD_CRC_ON_OFF				:= 39
SDCMD_LOCK_UNLOCK				:= 42
SDCMD_APP_CMD					:= 55
SDCMD_READ_OCR					:= 58

SDACMD_SET_WR_BLOCK_ERASE_COUNT	:= 23
SDACMD_APP_SEND_OP_COND			:= 41

; --------------------------------------------------------------------
;	Master Boot Record Offset
; --------------------------------------------------------------------
mbr_boot_strap_loader			:= 0
mbr_1st_partition				:= 0x01BE
mbr_2nd_partition				:= 0x01CE
mbr_3rd_partition				:= 0x01DE
mbr_4th_partition				:= 0x01EE
mbr_boot_signature				:= 0x01FE

mbr_partition_boot_flag			:= 0		; 1byte
mbr_partition_chs_begin_sector	:= 1		; 3bytes
mbr_partition_type				:= 4		; 1byte
mbr_partition_chs_end_sector	:= 5		; 3bytes
mbr_partition_lba_begin_sector	:= 8		; 4bytes
mbr_partition_total_sectors		:= 12		; 4bytes

; --------------------------------------------------------------------
;	Partition Boot Record Offset
; --------------------------------------------------------------------
pbr_jump_instruction			:= 0x000	; 3bytes
pbr_oem_name					:= 0x003	; 8bytes
pbr_bios_parameter_block		:= 0x00B	; 25bytes
	pbr_bytes_per_sector		:= 0x00B	;   2bytes
	pbr_sectors_per_cluster		:= 0x00D	;   1byte
	pbr_reserved_sectors		:= 0x00E	;   2bytes
	pbr_num_of_fat				:= 0x010	;   1byte
	pbr_root_entries			:= 0x011	;   2bytes
	pbr_small_sector			:= 0x013	;   2bytes
	pbr_media_type				:= 0x015	;   1byte
	pbr_sectors_per_fat			:= 0x016	;   2bytes
	pbr_sectors_per_track		:= 0x018	;   2bytes
	pbr_number_of_heads			:= 0x01A	;   2bytes
pbr_extend_bios_parameter_block	:= 0x01C	; 26bytes
pbr_bootstrap_code				:= 0x03E	; 448bytes
pbr_signature					:= 0x1FE	; 2bytes

; --------------------------------------------------------------------
;	SD/SDHC/MMC command
;	input)
; --------------------------------------------------------------------
		scope	set_sd_command
set_acmd41::
		ld		hl, megasd_sd_register
		ld		a, [hl]
		ld		[hl], 0x40 + SDACMD_APP_SEND_OP_COND
		ld		[hl], 0x40
		ld		[hl], 0
		ld		[hl], 0
		ld		[hl], 0
		ld		[hl], 0x95
		jr		set_common

set_cmd8::
		ld		hl, megasd_sd_register
		ld		a, [hl]
		ld		[hl], 0x40 + SDCMD_SEND_IF_COND
		ld		[hl], 0
		ld		[hl], 0
		ld		[hl], 0x01
		ld		[hl], 0xAA
		ld		[hl], 0x87
		jr		set_common

set_cmd0::
		xor		a, a
		ld		c, a				;	parameter = 0
		ld		d, a
		ld		e, a

set_sd_command::
		ld		hl, megasd_sd_register
card_type	:=	$ + 1
		ld		a, 0				;	Card type : 0=MMC, 1=SD, 2=SDHC
		cp		a, [hl]
		ld		[hl], b				;	set command code
		bit		1, a
		jr		z, set_sd_mmc

		;	for SDHC
		ld		[hl], 0
		ld		[hl], c
		ld		[hl], d
		ld		[hl], e
		jr		set_crc

		;	for SD/MMC
set_sd_mmc:
		sla		e					;	convert 'number of sector' to 'number of byte'
		rl		d					;	cde = cde * 2
		rl		c
		ld		[hl], c
		ld		[hl], d
		ld		[hl], e
		ld		[hl], 0

set_crc:
		ld		[hl], 0x95			;	CS = 0x95

set_common:
		ld		a, [hl]
		ld		b, 32
wait_command_accept:
		ld		a, [hl]
		cp		a, 0x0FF
		ccf
		ret		nc					;	no error
		djnz	wait_command_accept
		scf							;	error
		ret
		endscope

; --------------------------------------------------------------------
;	Initialize SD card
;	input)
; --------------------------------------------------------------------
		scope	sd_initialize
sd_initialize::
		ld		b, 10
wait_cs:
		ld		a, [0x5000]			;	/CS = 1 (bit12)
		djnz	wait_cs

		ld		b, 0x40 + SDCMD_GO_IDLE_STATE
		call	set_cmd0
		ret		c					;	error

		and		a, 0x0F7
		cp		a, 0x01				;	bit0 - in idle state?
		scf							;	CY = 1
		ret		nz					;	error (SD is not idle state when bit0 is zero.)

		; SD is idle state.
		call	set_cmd8
		cp		a, 1
		jr		nz, detect_mmc		;	Not SD Card

		; case of SD Card
		ld		a, [hl]
		ld		a, [hl]
		ld		a, [hl]
		and		a, 0x0F
		cp		a, 1
		scf							;	CY = 1
		ret		nz					;	error

		ld		a, [hl]
		cp		a, 0xAA
		scf							;	CY = 1
		ret		nz

repeat_app_cmd:
		ld		b, 0x40 + SDCMD_APP_CMD
		call	set_cmd0
		ret		c					;	error
		and		a, 4				;	bit2 = 1 - illegal command
		jr		z, command_ok

detect_mmc:
		xor		a, a				;	card_type = 0 (MMC)
		ld		[card_type], a

		ld		b, 0x40 + SDCMD_SEND_IO_COND
		call	set_cmd0
		jr		skip1

command_ok:
		ld		a, 1				;	card_type = 1 (SD Card)
		ld		[card_type], a

		call	set_acmd41			;	SDACMD_APP_SEND_OP_COND

skip1:
		ret		c					;	error

		cp		a, 0x01				;	bit0 - in idle state?
		jr		z, repeat_app_cmd	;	Yes, idle state. repeat app_cmd

		; in_idle_state = 0
		or		a, a				;	CY = 0
		jr		z, initialize_ok

		scf
		ret							;	error
initialize_ok:
		ld		a, [card_type]
		or		a, a				;	Is card_type MMC?
		ret		z					;	Yes, return.

		; case of SD Card
		ld		b,0x40 + SDCMD_READ_OCR
		call	set_cmd0
		ret		c					;	error
		ld		a, [hl]				;	read CCS (bit 6)
		cp		a, [hl]
		cp		a, [hl]
		cp		a, [hl]
		bit		6, a				;	CCS = 1 ?
		ret		z					;	This is SD Card. (CCS = 0)
		ld		a, 2				;	card_type = 2 (SDHC card)
		ld		[card_type], a
		ret
		endscope

; --------------------------------------------------------------------
;	Read sectors from MMC/SD/SDHC card
;	input)
;		B   = number of sectors
;		CDE = sector number
; --------------------------------------------------------------------
		scope	sd_read_sector
retry_init:
		call	sd_initialize
		pop		bc
		pop		de
		pop		hl
		ret		c					;	initialize error

sd_read_sector::
		push	hl
		push	de
		push	bc

		ld		b, 0x40 + SDCMD_READ_SINGLE_BLK
		call	set_sd_command
		jr		c, retry_init

		pop		bc
		pop		de
		pop		hl
		or		a, a
		scf
		ret		nz					;	error	ÅöÇ±Ç±Ç≈î≤ÇØÇƒÇµÇ‹Ç§ 

		push	de
		push	bc
		ex		de, hl
		ld		bc, 0x200			;	512bytes
		ld		hl, megasd_sd_register

read_wait:
		ld		a, [hl]
		cp		a, 0x0FE
		jr		nz, read_wait

		ldir						;	read sector
		ex		de, hl
		ld		a, [de]
		pop		bc
		ld		a, [de]
		pop		de
		inc		de
		ld		a, d
		or		a, e
		jr		nz, skip

		inc		c
skip:
		djnz	sd_read_sector		;	next sector
		or		a, a				;	Cy = 0
		ret
		endscope

; --------------------------------------------------------------------
;	Search "FAT"
; --------------------------------------------------------------------
		scope	search_fat
search_fat::
		ld		hl, buffer
		ld		bc, 0x80

search_loop:
		ld		a, 'F'
		cpir
		jr		z, found_f
		ret							;	no FAT (Z = 0)

found_f:
		push	hl
		ld		d, [hl]
		inc		hl
		ld		e, [hl]
		ld		hl, 'A' * 256 + 'T'
		or		a, a
		sbc		hl, de
		pop		hl
		jr		nz, search_loop
		ret							; FAT (Z = 1)
		endscope

; --------------------------------------------------------------------
;	test MBR (Search partition)
; --------------------------------------------------------------------
		scope	search_active_partition_on_mbr
search_active_partition_on_mbr::
		ld		b, 4							; number of partition entry
		ld		ix, buffer + mbr_1st_partition	; offset in sector
test_partition_loop:
		ld		e, [ix + mbr_partition_lba_begin_sector + 0]
		ld		d, [ix + mbr_partition_lba_begin_sector + 1]
		ld		c, [ix + mbr_partition_lba_begin_sector + 2]
		ld		a, c
		or		a, d
		or		a, e
		ret		nz					; if CDE != 0 then found partition

		; failed, and test next partition.
		ld		de, 16
		add		ix, de
		djnz	test_partition_loop

		; Not found a partition.
		scf							; CY = 1, error
		ret
		endscope

; --------------------------------------------------------------------
;	Process to find the first sector of the BIOS image file.
;	input)
;		none
;	output)
;		CDE ... First sector number in BIOS image
;		Cy .... 0: Failed, 1: Success
;	break)
;		af, bc, de, hl
; --------------------------------------------------------------------
		scope	sd_first_process
sd_first_process::
		;	Read Sector#0 (MBR)
		ld		bc, 0x100			;	B = 1 (1 sector)
		ld		d, c				;	CDE = 0x000000 (Sector #0)
		ld		e, c
		ld		hl, buffer
		call	sd_read_sector
		ret		c					;	go to srom_read when SD card read is error.

		call	search_active_partition_on_mbr
		ret		c					;	go to srom_read when partition is not found.

		push	de
		push	bc
		ld		b, 1
		ld		hl, buffer
		call	sd_read_sector
		call	search_fat
		pop		bc
		pop		de
		scf
		ret		nz					;	go to srom_read ehen SD card is not FAT16 file system.

sd_card_is_fat:
		call	calculate_first_sector_in_bios_image
		ret		c					;	first file on SD card is not BIOS image.
		xor		a, a				;	Success (CY = 0)
		ret
		endscope

; --------------------------------------------------------------------
;	Calculate first sector in BIOS image.
;	input)
;		none
;	output)
;		CDE ... First sector number in BIOS image
;		Cy .... 0: Failed, 1: Success
;	break)
;		af, bc, de, hl, ix
; --------------------------------------------------------------------
		scope	calculate_first_sector_in_bios_image
calculate_first_sector_in_bios_image::
		ld		ix, buffer			; PBR sector

		; HL = reserved sectors
		ld		l, [ix + pbr_reserved_sectors + 0]
		ld		h, [ix + pbr_reserved_sectors + 1]

		ld		a, c
		add		hl, de
		adc		a, 0
		ld		c, a

		; DE = root entries
		ld		e, [ix + pbr_root_entries + 0]
		ld		d, [ix + pbr_root_entries + 1]
		ld		a, e
		and		a, 0x0F
		ld		b, 4
loop1:
		srl		d
		rr		e
		djnz	loop1

		or		a, a
		jr		z, skip1
		inc		de
skip1:
		; calculate first sector address of BIOS image.
		push	de
		; Seek out the next sector of the FAT.
		ld		b, [ix + pbr_num_of_fat]
		ld		e, [ix + pbr_sectors_per_fat + 0]
		ld		d, [ix + pbr_sectors_per_fat + 1]
		ld		a, c
loop2:
		add		hl, de
		adc		a, 0
		djnz	loop2
		pop		de
		add		hl, de
		ex		de, hl
		ld		c, a
		ret
		endscope
