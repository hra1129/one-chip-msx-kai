; ==============================================================================
;	IPL-ROM v4.00 for OCM-PLD v3.4/OCM-Kai or later
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
; ====================================================================
;	History
;	ver 3.0.0	caro
;		Added text font and message.
;	ver	4.0.0	t.hara
;		Support for new BIOS Image format.
;	ver	4.0.1	t.hara	May/13rd/2020
;		Support for MemoryID.
;	ver	4.0.2	t.hara	August/5th/2020
;		Added initialization of PrimarySlotRegister(A8h).
;	ver	4.0.3	t.hara	August/5th/2020
;		BugFix
;	ver	4.0.4	t.hara	August/10th/2020
;		Modified register access for OCM-Kai control device
;	ver	4.1.0	t.hara	September/15th/2021
;		Supported DualBIOS.
;		Support to search the BIOS file in FAT file system.
; --------------------------------------------------------------------

; --------------------------------------------------------------------
;	Configuration
; --------------------------------------------------------------------
epcs_bios1_start_address				:= 0x200000 >> 9
epcs_bios2_start_address				:= 0x500000 >> 9

; --------------------------------------------------------------------
;	MegaSD Information
; --------------------------------------------------------------------
megasd_sd_register						:= 0x4000			; Command register for read/write access of SD/SDHC/MMC/EPCS Controller (4000h-57FFh)
megasd_mode_register					:= 0x5800			; Mode register for write access of SD/SDHC/MMC/EPCS Controller (5800h-5FFFh)
megasd_status_register					:= 0x5800			; status register for read access of SD/SDHC/MMC/EPCS Controller (5800h-5BFFh)
megasd_last_data_register				:= 0x5C00			; last data register for read access of SD/SDHC/MMC/EPCS Controller (5C00h-5FFFh)

eseram8k_bank0							:= 0x6000			; 4000h~5FFFh bank selector
eseram8k_bank1							:= 0x6800			; 6000h~7FFFh bank selector
eseram8k_bank2							:= 0x7000			; 8000h~9FFFh bank selector
eseram8k_bank3							:= 0x7800			; A000h~BFFFh bank selector

; --------------------------------------------------------------------
;	I/O
; --------------------------------------------------------------------
primary_slot_register					:= 0xA8

; --------------------------------------------------------------------
;	Expanded I/O
; --------------------------------------------------------------------
exp_io_vendor_id_port					:= 0x40				; Vendor ID register for Expanded I/O
exp_io_1chipmsx_id						:= 212				; KdL's switch device ID
exp_io_ocmkai_ctrl_id					:= 213				; 1chipMSX Kai control device ID

exp_io_ocmkai_ctrl_register_sel			:= 0x41
exp_io_ocmkai_ctrl_data					:= 0x42

exp_io_ocmkai_ctrl_reg_major_ver		:= 0
exp_io_ocmkai_ctrl_reg_minor_ver		:= 1
exp_io_ocmkai_ctrl_reg_memory_id		:= 2

; --------------------------------------------------------------------
;	Work area
; --------------------------------------------------------------------
buffer									:= 0xC000			; read buffer
fat_buffer								:= 0xC200			; read buffer for FAT entry
dram_code_address						:= 0xF000			; program code address on DRAM

; --------------------------------------------------------------------
;	First sector map in BIOS image (offset address)
; --------------------------------------------------------------------
bios_image_signature					:= 0				; 4bytes, "OCMB"
bios_image_flag							:= 4				; 1byte
	bios_image_flag_message_enable_bit	:= 0b0000_0001		; 0: disable, 1: enable
	bios_image_flag_pal_bit				:= 0b0000_0010		; 0: NTSC, 1: pal
	bios_image_flag_reserve_2			:= 0b0000_0100
	bios_image_flag_reserve_3			:= 0b0000_1000
	bios_image_flag_reserve_4			:= 0b0001_0000
	bios_image_flag_reserve_5			:= 0b0010_0000
	bios_image_flag_reserve_6			:= 0b0100_0000
	bios_image_flag_reserve_7			:= 0b1000_0000
bios_image_command_blocks				:= 5

; --------------------------------------------------------------------
;	main program
; --------------------------------------------------------------------
		org			0x0000
entry_point:
		;	Initialize Stack Pointer
		di
		ld			sp, 0xFFFF

		;	Copy IPLROM to DRAM
		ld			bc, end_of_code - start_of_code
		ld			de, dram_code_address
		ld			hl, rom_code_address
		ldir
		jp			start_of_code
rom_code_address::

		org			dram_code_address
start_of_code::
		call		vdp_initialize
		ld			hl, 0x0000						;	Pattern Name Table
		call		vdp_set_vram_address

		; Activate "OCM-Kai control device" and initialize MemoryID to 0.
		ld			a, exp_io_ocmkai_ctrl_id
		out			[ exp_io_vendor_id_port ], a

		ld			a, exp_io_ocmkai_ctrl_reg_memory_id
		out			[exp_io_ocmkai_ctrl_register_sel], a
		xor			a, a
		out			[exp_io_ocmkai_ctrl_data], a

		; check power on reset
		ld			a, 0x40
		ld			[eseram8k_bank0], a				; BANK 40h

		ld			a, [megasd_status_register]
		rrca										; Is the activation this time PowerOnReset?
		jr			nc, not_power_on_reset
		ld			[bios_updating], a				; Clear bios_updating flag.
not_power_on_reset:

		call		sd_initialize

		; Skip check of alreay loaded BIOS, when press [ESC] key.
		ld			a, 0xF7
		out			[0xAA], a
		in			a, [0xA9]
		and			a, 4
		jr			z, skip_check

		; Check already loaded BIOS.
check_already_loaded::
		ld			a, [bios_updating]
		cp			a, 0xD4							; If it's a quick reset, boot EPBIOS.
		jr			z, force_bios_load_from_sdcard

		; -- Check MAIN-ROM
		xor			a, a							;	LD A, MAIN_ROM1_BANK >> 8
		out			[exp_io_ocmkai_ctrl_data], a
		ld			a, MAIN_ROM1_BANK & 0xFF
		ld			[ eseram8k_bank2 ], a
		ld			hl, 0x8000
		ld			a, [hl]
		cp			a, 0xF3
		jr			nz, no_loaded
		inc			hl
		ld			a, [hl]
		cp			a, 0xC3
		jp			z, start_system
no_loaded:
skip_check:

force_bios_load_from_sdcard::
		call		load_from_sdcard
force_bios_load_from_epbios::
		call		load_from_epcs

bios_read_error::
		ld			hl, 0 + 6 * 40					;	LOCATE 0,6
		call		vdp_set_vram_address
		xor			a, a
		ld			[putc], a						;	replace code to 'nop'. (Force puts error message.)
		ld			hl, message_bios_read_error
		call		puts
		halt

; --------------------------------------------------------------------
msg_enter::
		ds			"[Enter]"
		db			0
msg_sd_preinit::
		ds			"[SdPre]"
		db			0
msg_end_of_init::
		ds			"[EOINIT]"
		db			0

; --------------------------------------------------------------------
;	subroutines
; --------------------------------------------------------------------
		include "ocm_iplrom_load_epcs.asm"
		include "ocm_iplrom_load_bios.asm"
		include "ocm_iplrom_fat_driver.asm"
		include "ocm_iplrom_serial_rom.asm"
		include "ocm_iplrom_sd_driver.asm"
		include "ocm_iplrom_message.asm"
		include "ocm_iplrom_vdp_driver.asm"
end_of_code:
	remain_fat_sectors	:= $							; 2bytes
	root_entries		:= $ + 2						; 3bytes
	data_area			:= $ + 5						; 3bytes
	current_sector_low	:= $ + 8						; 2bytes
	current_sector_high	:= $ + 10						; 2bytes
	bios_updating		:= $ + 12						; 1byte: 0xD4: Updating now, the others: Not loaded

		if ( (end_of_code - start_of_code) + (rom_code_address - entry_point) ) > 4096
			error "The size is too BIG. (" + ( (end_of_code - start_of_code) + (rom_code_address - entry_point) ) + "byte)"
		else
			message "Size is not a problem. (" + ( (end_of_code - start_of_code) + (rom_code_address - entry_point) ) + "byte)"
		endif
