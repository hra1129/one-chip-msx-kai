; ==============================================================================
;	IPL-ROM for OCM-Kai
;	load BIOS image
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
; ==============================================================================

MAIN_ROM1_BANK		:= 0x0080		;	Slot0-0 page 0		( 0000000h - 0003FFFh )	16KB
MAIN_ROM2_BANK		:= 0x0082		;	Slot0-0 page 1		( 0004000h - 0007FFFh )	16KB
RESERVED002_BANK	:= 0x0084		;	Slot0-0 page 2		( 0008000h - 000BFFFh )	16KB
RESERVED003_BANK	:= 0x0086		;	Slot0-0 page 3		( 000C000h - 000FFFFh )	16KB
RESERVED010_BANK	:= 0x0088		;	Slot0-1 page 0		( 0010000h - 0013FFFh )	16KB
RESERVED011_BANK	:= 0x008A		;	Slot0-1 page 1		( 0014000h - 0017FFFh )	16KB
RESERVED012_BANK	:= 0x008C		;	Slot0-1 page 2		( 0018000h - 001BFFFh )	16KB
RESERVED013_BANK	:= 0x008E		;	Slot0-1 page 3		( 001C000h - 001FFFFh )	16KB
RESERVED020_BANK	:= 0x0090		;	Slot0-2 page 0		( 0020000h - 0023FFFh )	16KB
MSX_MUSIC_BANK		:= 0x0092		;	Slot0-2 page 1		( 0024000h - 0027FFFh )	16KB
RESERVED022_BANK	:= 0x0094		;	Slot0-2 page 2		( 0028000h - 002BFFFh )	16KB
RESERVED023_BANK	:= 0x0096		;	Slot0-2 page 3		( 002C000h - 002FFFFh )	16KB
RESERVED030_BANK	:= 0x0098		;	Slot0-3 page 0		( 0030000h - 0033FFFh )	16KB
OPTION_ROM_BANK		:= 0x009A		;	Slot0-3 page 1		( 0034000h - 0037FFFh )	16KB
RESERVED032_BANK	:= 0x009C		;	Slot0-3 page 2		( 0038000h - 003BFFFh )	16KB
RESERVED033_BANK	:= 0x009E		;	Slot0-3 page 3		( 003C000h - 003FFFFh )	16KB
SUB_ROM_BANK		:= 0x00A0		;	Slot3-3 page 0		( 0040000h - 0043FFFh )	16KB
RESERVED311_BANK	:= 0x00A2		;	Slot3-3 page 1		( 0044000h - 0047FFFh )	16KB
RESERVED312_BANK	:= 0x00A4		;	Slot3-3 page 2		( 0048000h - 004BFFFh )	16KB
RESERVED313_BANK	:= 0x00A6		;	Slot3-3 page 3		( 004C000h - 004FFFFh )	16KB
NC000_BANK			:= 0x00A8		;	No Connect			( 0050000h - 00FFFFFh )	704KB
DOS_BANK			:= 0x0180		;	Slot3-2				( 0100000h - 01FFFFFh )	1MB
ESESCC1_0_BANK		:= 0x0280		;	Slot1				( 0200000h - 02FFFFFh )	1MB
ESESCC1_1_BANK		:= 0x0380		;	Slot1				( 0300000h - 03FFFFFh )	1MB
ESESCC2_0_BANK		:= 0x0480		;	Slot2				( 0400000h - 04FFFFFh )	1MB
ESESCC2_1_BANK		:= 0x0580		;	Slot2				( 0500000h - 05FFFFFh )	1MB
NC001_BANK			:= 0x0680		;	No Connect			( 0600000h - 06FFFFFh )	1MB
NC002_BANK			:= 0x0780		;	No Connect			( 0700000h - 07FFFFFh )	1MB
MAPPER_RAM0_BANK	:= 0x0880		;	Slot3-0				( 0800000h - 08FFFFFh )	1MB
MAPPER_RAM1_BANK	:= 0x0980		;	Slot3-0				( 0900000h - 09FFFFFh )	1MB
MAPPER_RAM2_BANK	:= 0x0A80		;	Slot3-0				( 0A00000h - 0AFFFFFh )	1MB
MAPPER_RAM3_BANK	:= 0x0B80		;	Slot3-0				( 0B00000h - 0BFFFFFh )	1MB
KANJI_ROM_BANK		:= 0x0C80		;	I/O					( 0C00000h - 0C3FFFFh )	256KB
NC003_BANK			:= 0x0CA0		;	No Connect			( 0C40000h - 0CFFFFFh )	768KB
NC004_BANK			:= 0x0D80		;	No Connect			( 0D00000h - 0DFFFFFh )	1MB
NC005_BANK			:= 0x0E80		;	No Connect			( 0E00000h - 0EFFFFFh )	1MB
NC006_BANK			:= 0x0F80		;	No Connect			( 0F00000h - 0FFFFFFh )	1MB

PANA_MEGA0_BANK		:= 0x1080		;	Slot3-3				( 1000000h - 104FFFFh )	320KB
PANA_MEGA1_BANK		:= 0x10A8		;	Slot3-3				( 1050000h - 1057FFFh )	32KB
NC007_BANK			:= 0x10AC		;	No Connect			( 1058000h - 107FFFFh )	160KB
PANA_MEGA2_BANK		:= 0x10C0		;	Slot3-3 MSX-JE DIC	( 1080000h - 10FFFFFh )	512KB

LINEAR_ROM_BANK		:= 0x1080		;	Slot3-3				( 1000000h - 100FFFFh )	64KB
NC008_BANK			:= 0x1088		;	No Connect			( 1010000h - 10FFFFFh )	960KB

PANA_MEGA3_BANK		:= 0x1180		;	Slot3-3 SRAM		( 1100000h - 113FFFFh )	256KB
PANA_MEGA4_BANK		:= 0x11A0		;	Slot3-3 ROM Disk	( 1140000h - 117FFFFh )	256KB
PANA_MEGA5_BANK		:= 0x11C0		;	Slot3-3 N/A			( 1180000h - 11FFFFFh )	512KB

PANA_MEGA6_BANK		:= 0x1280		;	Slot3-3 ROM Disk	( 1240000h - 127FFFFh )	512KB
PANA_MEGA7_BANK		:= 0x12C0		;	Slot3-3 N/A			( 1280000h - 12FFFFFh )	512KB

NC010_BANK			:= 0x1380		;	No Connect			( 1300000h - 13FFFFFh )	1MB
NC011_BANK			:= 0x1480		;	No Connect			( 1400000h - 14FFFFFh )	1MB
NC012_BANK			:= 0x1580		;	No Connect			( 1500000h - 15FFFFFh )	1MB
NC013_BANK			:= 0x1680		;	No Connect			( 1600000h - 16FFFFFh )	1MB
NC014_BANK			:= 0x1780		;	No Connect			( 1700000h - 17FFFFFh )	1MB
NC015_BANK			:= 0x1880		;	No Connect			( 1800000h - 18FFFFFh )	1MB
NC016_BANK			:= 0x1980		;	No Connect			( 1900000h - 19FFFFFh )	1MB
NC017_BANK			:= 0x1A80		;	No Connect			( 1A00000h - 1AFFFFFh )	1MB
NC018_BANK			:= 0x1B80		;	No Connect			( 1B00000h - 1BFFFFFh )	1MB
NC019_BANK			:= 0x1C80		;	No Connect			( 1C00000h - 1CFFFFFh )	1MB
NC020_BANK			:= 0x1D80		;	No Connect			( 1D00000h - 1DFFFFFh )	1MB
NC021_BANK			:= 0x1E80		;	No Connect			( 1E00000h - 1EFFFFFh )	1MB
VRAM_BANK			:= 0x1F80		;	No Connect			( 1F00000h - 1FFFFFFh )	1MB

; ------------------------------------------------------------------------------
;	load_bios
;	input:
;		cde ... target sector number
;	output:
;		none
;	break:
;		all
;	comment:
;		Load the BIOS image, and if it loads successfully, boot the image.
; ------------------------------------------------------------------------------
			scope	load_bios
load_bios::
			; Activate "OCM-Kai control device" and initialize MemoryID to 0.
			ld		a, exp_io_ocmkai_ctrl_id
			out		[ exp_io_vendor_id_port ], a

			; Start to load BIOS
			ld		a, 0xD4
			ld		[bios_updating], a

			push	hl								; [001] "Boot from xxxx"
			call	read_first_sector
			pop		hl								; [001] "Boot from xxxx"
			ret		c								;	error

			push	hl								; [001] "Boot from xxxx"
			ld		[current_sector_low ], de
			ld		[current_sector_high], bc

			; Evaluate BIOS image flag -------------------------------------------------------
			ld		a, [buffer + bios_image_flag]
			rrca									;	Cy = message enable bit
			ld		b, a
			ld		a, 0xC9							;	code 'RET'
			jr		c, message_disable
			xor		a, a							;	code 'NOP'
message_disable:
			ld		[putc], a

			ld		a, b
			rrca									;	Cy = pal bit
			ld		a, 2							;	PAL
			jr		c, pal_mode
			xor		a, a							;	NTSC
pal_mode:
			out		[vdp_port1], a
			ld		a, 0x89							;	VDP R#9
			out		[vdp_port1], a

			; Puts boot message --------------------------------------------------------------
			ld		hl, 0 + 0 * 40
			call	vdp_set_vram_address
			ld		hl, message_initial_text1
			call	puts
			ld		hl, 0 + 1 * 40
			call	vdp_set_vram_address
			ld		hl, message_initial_text2
			call	puts
			ld		hl, 0 + 2 * 40
			call	vdp_set_vram_address
			ld		hl, message_initial_text3
			call	puts
			ld		hl, 0 + 5 * 40					;	LOCATE 0,5
			call	vdp_set_vram_address
			pop		hl								; [001] "Boot from xxxx"
			call	puts
			ld		hl, 0 + 7 * 40					;	LOCATE 0,7
			call	vdp_set_vram_address

			; Command execution --------------------------------------------------------------
			ld		hl, buffer + bios_image_command_blocks
command_execution:
			ld		a, [hl]							;	Get command code
			inc		hl
			or		a, a							;	Is it Terminate Command? , and CY=0
			jp		z, start_system
			dec		a
			jr		z, transfer_bios_image
			dec		a
			jr		z, change_eseram_memory
			dec		a
			jr		z, write_io
			dec		a
			jr		z, print_message
			dec		a
			jr		z, fill_dummy_code
			jp		bios_read_error

			; COMMAND1: Transfer BIOS image --------------------------------------------------
transfer_bios_image:
			ld		a, [hl]							; Get ESERAM bank ID
			inc		hl
			ld		b, [hl]							; Get number of blocks
			inc		hl
			push	hl								; [001] save header index
load_rom_image:
			; set ESE-RAM bank registers
			ld		[eseram8k_bank2], a				; ESE-RAM Bank2 (8KB)
			inc		a
			ld		[eseram8k_bank3], a				; ESE-RAM Bank3 (8KB)
			inc		a
			ld		c, a
			push	bc								; [002] save remain blocks and ESE-RAM Bank index
			; load page 16 kb
			ld		de, [current_sector_low]
			ld		bc, [current_sector_high]

			ld		b, 16384 / 512
			ld		hl, 0x8000						; buffer

			call	read_sector
			ld		[current_sector_low ], de
			ld		[current_sector_high], bc

			pop		bc								; [002] load remain blocks and ESE-RAM Bank index
			jr		c, exit							; error
			ld		a, '>'							; Display progress bar
			call	putc
			ld		a, c							; A = ESE-RAM Bank index
			djnz	load_rom_image					;
exit:
			pop		hl								; [001] load header index
			jr		command_execution

			; COMMAND2: Change ESERAM memory -------------------------------------------------
change_eseram_memory:
			ld		a, exp_io_ocmkai_ctrl_id
			out		[ exp_io_vendor_id_port ], a
			ld		a, exp_io_ocmkai_ctrl_reg_memory_id
			out		[exp_io_ocmkai_ctrl_register_sel], a
			ld		a, [hl]							; Get ESERAM memoryID
			out		[exp_io_ocmkai_ctrl_data], a	; Set the MemoryID
			inc		hl
			jr		command_execution

			; COMMAND3: Write I/O Port -------------------------------------------------------
write_io:
			ld		c, [hl]							;	Get I/O Address
			inc		hl
			ld		a, [hl]							;	Get I/O Data
			inc		hl
			out		[c], a
			jr		command_execution

			; COMMAND4: Message --------------------------------------------------------------
print_message:
			push	hl								; [001] header index
			ld		hl, 0 + 6*40
			call	vdp_set_vram_address
			pop		hl								; [001] header index
			call	puts
			push	hl								; [001] header index
			ld		hl, 0 + 7*40
			call	vdp_set_vram_address
			pop		hl								; [001] header index
			jr		command_execution

			; COMMAND5: Fill dummy code ------------------------------------------------------
fill_dummy_code:
			ld		a, [hl]							; Get ESERAM bank ID
			inc		hl
			ld		b, [hl]							; Get number of blocks
			inc		hl
			push	hl								; [001] header index
fill_blocks:
			; set ESE-RAM bank registers
			ld		[eseram8k_bank2], a				; ESE-RAM Bank2 (8KB)
			inc		a
			ld		[eseram8k_bank3], a				; ESE-RAM Bank3 (8KB)
			inc		a
			ld		c, a
			push	bc								; [002] save remain blocks and ESE-RAM Bank index
			ld		bc, 16384 - 1
			ld		hl, 0x8000
			ld		de, 0x8001
			ld		[hl], c
			ldir
			pop		bc								; [002] load remain blocks and ESE-RAM Bank index
			ld		a, '*'							; Display progress bar
			call	putc
			ld		a, c							; A = ESE-RAM Bank index
			djnz	fill_blocks						;
			jr		exit

			; COMMAND0: Start System ---------------------------------------------------------
start_system::
			; Initialize MegaSDHC MemoryID
			ld		a, exp_io_ocmkai_ctrl_id
			out		[ exp_io_vendor_id_port ], a
			ld		a, exp_io_ocmkai_ctrl_reg_memory_id
			out		[exp_io_ocmkai_ctrl_register_sel], a

			; change bank2 (0x8000..0x9FFF) to MAIN-ROM
			ld		a, MAIN_ROM1_BANK >> 8
			out		[exp_io_ocmkai_ctrl_data], a
			ld		a, MAIN_ROM1_BANK & 0xFF
			ld		[eseram8k_bank2], a

			ld		a, '#'							; Display progress bar
			call	putc

			ld		a, [ 0x8000 ]					;  first byte in MAIN-ROM
			cp		a, 0xF3							; = DI ?
			jp		nz, bios_read_error				;  error

			ld		a, [ 0x8000 + 0x002D ]
			or		a, a
			call	nz, set_msx2_palette

			ld		a, DOS_BANK >> 8				; Default MemoryID for MegaSDHC
			out		[exp_io_ocmkai_ctrl_data], a

			; Initialize MegaSDHC bank registers
			xor		a, a
			ld		[ eseram8k_bank0 ], a
			inc		a
			ld		[ eseram8k_bank1 ], a
			ld		[ eseram8k_bank2 ], a
			ld		[ eseram8k_bank3 ], a
			ld		a, 0xC0
			out		[ primary_slot_register ], a

			; Finished load BIOS image
			ld		[bios_updating], a

			; -- Request reset primary slot at read 0000h and change to customized clock
			ld		a, 3
			out		[exp_io_ocmkai_ctrl_register_sel], a
			out		[exp_io_ocmkai_ctrl_data], a

			; Activate 1chipMSX device
			ld		a, exp_io_1chipmsx_id
			out		[ exp_io_vendor_id_port ], a	; I/O address 0x40 is 1chipMSX device in expanded I/O.

			rst		0x00							; start MSX BASIC
			endscope

; --------------------------------------------------------------------
;	Read the first sector and evaluate the content
;	input)
;		CDE ... First sector in BIOS image.
;	output)
;		CDE ... Next sector in BIOS image.
;		Cy .... 0: This is BIOS image, 1: This is not BIOS image
;	break)
;		af, bc, de, hl
; --------------------------------------------------------------------
			scope	read_first_sector
read_first_sector::
			; read first 512byte of BIOS image. Sector #cde
			ld		b, 1					; read 1 sector
			ld		hl, buffer
			call	read_sector
			ret		c

			push	bc						; [001] save next sector index (upper)
			push	de						; [002] save next sector index (lower)

			ld		hl, buffer + bios_image_signature
			ld		de, bios_image_signature_reference
			ld		b, 4

check_signature_loop:
			ld		a, [de]
			cp		a, [hl]
			jr		nz, no_match			; Success --> Zf=1, Cy=0: Error --> Zf=0
			inc		de
			inc		hl
			djnz	check_signature_loop
match:
			pop		de						; [002] load next sector index (lower)
			pop		bc						; [001] load next sector index (upper)
			ret
no_match:
			scf								; Cy = 1 : error
			jr		match

bios_image_signature_reference:
			ds		"OCMB"
			endscope

; --------------------------------------------------------------------
;	Read sector hook
;	input)
;		B ..... Number of sectors
;		CDE ... Sector index
;	output)
;		Cy .... 0: SUCCESS, 1: ERROR
;	break)
;		af, bc, de, hl
; --------------------------------------------------------------------
			scope		read_sector
read_sector::
read_sector_cbr		:= $ + 1
			jp			sd_read_sector
			endscope
