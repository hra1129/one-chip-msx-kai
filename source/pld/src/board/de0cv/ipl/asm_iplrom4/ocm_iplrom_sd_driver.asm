; ==============================================================================
;	IPL-ROM for OCM-PLD v3.4 or later
;	SD-Card Driver
; ------------------------------------------------------------------------------
; Copyright (c) 2021 Takayuki Hara
; All rights reserved.
;
; Redistribution and use of this source code or any derivative works, are
; permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
;	 this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;	 notice, this list of conditions and the following disclaimer in the
;	 documentation and/or other materials provided with the distribution.
; 3. Redistributions may not be sold, nor may they be used in a commercial
;	 product or activity without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
; TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
; PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
; OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
; ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; ------------------------------------------------------------------------------
; History:
;   2021/Aug/20th  t.hara  Overall revision.
; ==============================================================================

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

card_type						:= 0xFFCF	; 1byte: 2: MMC/SDHC, 3: SDHC

; --------------------------------------------------------------------
;	SD/SDHC/MMC command
;	input)
; --------------------------------------------------------------------
		scope	set_sd_command
set_sd_command::
		ld		a, [card_type]		;	Card type : 2=MMC/SD, 3=SDHC
		sub		a, 2
		jr		z, set_sd_mmc
		dec		a
		jr		z, set_sdhc
		scf
		ret

		;	for SDHC
set_sdhc:
		ld		a, [hl]
		ld		[hl], b				;	set command code
		ld		[hl], 0
		ld		[hl], c
		ld		[hl], d
		ld		[hl], e
		jr		set_src95

		;	for SD/MMC
set_sd_mmc:
		sla		e					;	convert 'number of sector' to 'number of byte'
		rl		d					;	cde = cde * 2
		rl		c
set_cmd2::
		ld		a, [hl]
		ld		[hl], b				;	set command code
		ld		[hl], c
		ld		[hl], d
		ld		[hl], e
		ld		[hl], 0
set_src95:
		ld		[hl], 0x95			;	CRC
		jr		set_common

set_cmd8::
		ld		a, [hl]
		ld		[hl], 0x40 + SDCMD_SEND_IF_COND
		ld		[hl], 0
		ld		[hl], 0
		ld		[hl], 0x01
		ld		[hl], 0xAA
		ld		[hl], 0x87

set_common:
		ld		a, [hl]
		ld		b, 16				;	16 cycles
wait_command_accept:
		ld		a, [hl]
		cp		a, 0x0FF
		ccf
		ret		nc					;	no error
		djnz	wait_command_accept	;	no flag change
		ret							;	Cy = 1
		endscope

; --------------------------------------------------------------------
;	Preinitialize
;	input)
; --------------------------------------------------------------------
		scope	sd_preinitialize
sd_preinitialize::
		ld		a, 0x40
		ld		[eseram8k_bank0], a						; BANK 40h
		ld		a, [megasd_sd_register | (1 << 12)]		;	/CS = 1 (bit12)
		ret
		endscope

; --------------------------------------------------------------------
;	Initialize SD card
;	input)
; --------------------------------------------------------------------
		scope	sd_initialize
sd_initialize::
		call	sd_initialize_sub
		ret		c
		ret		nz
		ld		hl, card_type
		ld		[hl], e
		xor		a, a
		ret

sd_initialize_sub:
		;	"/CS=1, DI=1" is input for a period of 74 clocks or more.
		ld		hl, megasd_sd_register
		ld		b, 10
wait_cs:
		ld		a, [megasd_sd_register | (1 << 12)]		;	/CS = 1 (bit12)
		djnz	wait_cs

		ld		d, b				;	CDE = 0
		ld		e, b
		ld		bc, ((0x40 + SDCMD_GO_IDLE_STATE) << 8) | 0x00
		call	set_cmd2			;	save CDE
		ret		c					;	error

		and		a, 0x0F3
		cp		a, 0x01				;	bit0 - in idle state?
		ret		nz					;	error (SD is not idle state when bit0 is zero.)

		; SD is idle state.
		call	set_cmd8			;	save CDE
		ret		c					;	error
		cp		a, 1
		jr		nz, detect_mmc		;	Not SD Card

		; case of SD Card
		ld		a, [hl]
		nop
		ld		a, [hl]
		nop
		ld		a, [hl]
		and		a, 0x0F
		cp		a, 1
		ret		nz					;	error

		ld		a, [hl]
		cp		a, 0xAA
		ret		nz

repeat_app_cmd:
		ld		b, (0x40 + SDCMD_APP_CMD)		;	CDE = 0
		call	set_cmd2			;	save CDE
		ret		c					;	error
		cp		a, 1
		ret		nz					;	error

		ld		bc, ((0x40 + SDACMD_APP_SEND_OP_COND) << 8) | 0x40
		call	set_cmd2			;	save CDE
		ret		c					;	error
		and		a, 1
		jr		nz, repeat_app_cmd

		ld		b, (0x40 + SDCMD_READ_OCR)
		call	set_cmd2
		ret		c					;	error

		ld		a, [hl]
		cp		a, [hl]
		cp		a, [hl]
		cp		a, [hl]
		bit		6, a
		ld		e, 2				;	SD = 2
		jr		z, not_sdhc
		inc		e					;	SDHC = 3
not_sdhc:
		xor		a, a
		ret

detect_mmc:
		ld		b, (0x40 + SDCMD_APP_CMD)	;	CDE = 0
		call	set_cmd2			; save CDE
		ret		c
		bit		2, a
		jr		nz, skip2
		cp		a, 1
		ret		nz

		ld		b, 0x40 + SDACMD_APP_SEND_OP_COND
		call	set_cmd2			;	save CDE
		ret		c					;	error
		bit		2, a
		jr		nz, skip2
		and		a, 1				;	Cy = 0, a = 0 or 1
		jr		nz, detect_mmc		;	if a == 1 goto detect_mmc
		ld		e, 2				;	MMC = 2
		ret

skip2:
		ld		b, 0x40 + SDCMD_SEND_IO_COND
		call	set_cmd2			;	save CDE
		ret		c					;	error
		cp		a, 1
		jr		z, detect_mmc
		xor		a, a				;	Cy = 0
		ret							;	Unknown card: e = 0
		endscope

; --------------------------------------------------------------------
;	Read sectors from MMC/SD/SDHC card
;	input)
;		B   = number of sectors
;		HL  = read buffer
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
		ld		hl, megasd_sd_register
		call	set_sd_command
		jr		c, retry_init

		pop		bc
		pop		de
		pop		hl
		or		a, a
		scf
		ret		nz					;	error

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

		ret
		endscope

; --------------------------------------------------------------------
;	test MBR (Search partition)
; --------------------------------------------------------------------
		scope	search_active_partition_on_mbr
search_active_partition_on_mbr::
		ld		b, 4															; number of partition entry
		ld		hl, buffer + mbr_1st_partition + mbr_partition_lba_begin_sector	; offset in sector
test_partition_loop:
		ld		e, [hl]
		inc		hl
		ld		d, [hl]
		inc		hl
		ld		c, [hl]
		ld		a, c
		or		a, d
		or		a, e
		ret		nz					; if CDE != 0 then found partition

		; failed, and test next partition.
		ld		de, 16 - 2
		add		hl, de
		djnz	test_partition_loop

		; Not found a partition.
		scf							; CY = 1, error
		ret
		endscope
