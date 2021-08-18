; --------------------------------------------------------------------
;	IPLROM4 for OCM booting from MMC/SD/SDHC card
;	without data compression
; ====================================================================
;	History
;	ver 3.0.0	caro
;	ver	4.0.0	t.hara
;		Support for new BIOS Image format.
;	ver	4.0.1	t.hara	May/13th/2020
;		Support for MemoryID.
;	ver	4.0.2	t.hara	August/5th/2020
;		Added initialization of PrimarySlotRegister(A8h).
;	ver	4.0.3	t.hara	August/5th/2020
;		BugFix
;	ver	4.0.4	t.hara	August/10th/2020
;		Modified register access for OCM-Kai control device
; --------------------------------------------------------------------

; --------------------------------------------------------------------
;	Configuration
; --------------------------------------------------------------------
srom_bios_image_address					:= 0x780000 >> 9	; EPCS64 0x780000

; --------------------------------------------------------------------
;	Work area
; --------------------------------------------------------------------
buffer									:= 0xC000			; read buffer
dram_code_address						:= 0xF000			; program code address on DRAM

; --------------------------------------------------------------------
;	I/O
; --------------------------------------------------------------------
primary_slot_register					:= 0xA8

; --------------------------------------------------------------------
;	MegaSD Information
; --------------------------------------------------------------------
megasd_sd_register						:= 0x4000			; Register of SD/SDHC/MMC/EPCS Controller (4000h-57FFh)
eseram8k_bank0							:= 0x6000			; 4000h~5FFFh bank selector
eseram8k_bank1							:= 0x6800			; 6000h~7FFFh bank selector
eseram8k_bank2							:= 0x7000			; 8000h~9FFFh bank selector
eseram8k_bank3							:= 0x7800			; A000h~BFFFh bank selector

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
		org		0x0000
entry_point:
		;	Initialize Stack Pointer
		di
		ld		sp, 0xFFFF

		;	Copy IPLROM to DRAM
		ld		bc, end_code - start_code
		ld		de, dram_code_address
		ld		hl, rom_code_address
		ldir
		jp		start_code
rom_code_address::

		org		dram_code_address
start_code::
		; Activate "OCM-Kai control device" and initialize MemoryID to 0.
		ld		a, exp_io_ocmkai_ctrl_id
		out		[ exp_io_vendor_id_port ], a

		; Initialize Primary Slot Register
		ld		a, 0xFC							; Page0 is slot0. Page1, Page2 and Page3 is slot3
		out		[ primary_slot_register ], a

		; Request reset primary slot at read 0000h
		ld		a, 3
		out		[exp_io_ocmkai_ctrl_register_sel], a
		out		[exp_io_ocmkai_ctrl_data], a

		; Skip check of alreay loaded BIOS, when press [ESC] key.
		ld		a, 0xF7
		out		[0xAA], a
		in		a, [0xA9]
		and		a, 4
		jr		z, skip_check

		; Check already loaded BIOS.
		ld		a, exp_io_ocmkai_ctrl_reg_memory_id
		out		[exp_io_ocmkai_ctrl_register_sel], a
		ld		a, 1
		out		[exp_io_ocmkai_ctrl_data], a

		ld		a, 0x80							;	Check DOS-ROM
		ld		[ eseram8k_bank2 ], a
		ld		hl, 0x8000
		ld		a, [hl]
		cp		a, 'A'
		jr		nz, no_loaded
		inc		hl
		ld		a, [hl]
		cp		a, 'B'
		jr		nz, no_loaded

		ld		a, exp_io_ocmkai_ctrl_reg_memory_id
		out		[exp_io_ocmkai_ctrl_register_sel], a
		xor		a, a
		out		[exp_io_ocmkai_ctrl_data], a

		ld		a, 0x80							;	Check MAIN-ROM
		ld		[ eseram8k_bank2 ], a
		ld		hl, 0x8000
		ld		a, [hl]
		cp		a, 0xF3
		jr		nz, no_loaded
		inc		hl
		ld		a, [hl]
		cp		a, 0xC3
		jp		z, start_system

no_loaded:

skip_check:
		ld		a, 0x40							;	Enable SD/MMC (Disable EPCS)
		ld		[ eseram8k_bank0 ], a

		call	vdp_initialize

		ld		hl, 0x0000						;	Pattern Name Table
		call	vdp_set_vram_address

		call	try_sd_card
		call	try_srom

bios_read_error::
		ld		hl, 0 + 6 * 40					;	LOCATE 0,6
		call	vdp_set_vram_address
		xor		a, a
		ld		[putc], a						;	replace code to 'nop'. (Force puts error message.)
		ld		hl, message_bios_read_error
		call	puts
end_loop::
		jr		end_loop

; --------------------------------------------------------------------
;	try sd card
; --------------------------------------------------------------------
		scope	try_common
try_srom::
		ld		hl, srom_reader
		ld		[ read_sector_hook ], hl

		ld		a, 0x60							;	Enable EPCS (Disable SD/MMC)
		ld		[ eseram8k_bank0 ], a

		ld		de, srom_bios_image_address		;	EPCS64 start address
		ld		hl, message_srom_boot
		jr		try_common

try_sd_card::
		call	sd_first_process				;	Initialize SD Card and search first sector number(CDE) in BIOS image.
		ret		c								;	error
		ld		hl, message_sd_boot

try_common:
		push	hl

		call	read_first_sector
		ret		c								;	error

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
		ld		hl, message_initial_text
		call	puts
		ld		hl, 0 + 5 * 40					;	LOCATE 0,5
		call	vdp_set_vram_address
		pop		hl								;	HL = "Boot from xxx"
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
		push	hl								; save header index
load_blocks:
		; set ESE-RAM bank registers
		ld		[eseram8k_bank2], a				; ESE-RAM Bank2 (8KB)
		inc		a
		ld		[eseram8k_bank3], a				; ESE-RAM Bank3 (8KB)
		inc		a
		ld		c, a
		push	bc								; save remain blocks and ESE-RAM Bank index
; load page 16 kb
		ld		de, [current_sector_low]
		ld		bc, [current_sector_high]

		ld		b, 16384 / 512
		ld		hl, 0x8000						; buffer

		call	read_sector
		ld		[current_sector_low ], de
		ld		[current_sector_high], bc

		pop		bc								; load remain blocks and ESE-RAM Bank index
		jr		c, exit							; error
		ld		a, '>'							; Display progress bar
		call	putc
		ld		a, c							; A = ESE-RAM Bank index
		djnz	load_blocks						;
exit:
		pop		hl								; load header index
		jr		command_execution

		; COMMAND2: Change ESERAM memory -------------------------------------------------
change_eseram_memory:
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
		push	hl
		ld		hl, 0 + 6*40
		call	vdp_set_vram_address
		pop		hl
		call	puts
		push	hl
		ld		hl, 0 + 7*40
		call	vdp_set_vram_address
		pop		hl
		jr		command_execution

		; COMMAND5: Fill dummy code ------------------------------------------------------
fill_dummy_code:
		ld		a, [hl]							; Get ESERAM bank ID
		inc		hl
		ld		b, [hl]							; Get number of blocks
		inc		hl
		push	hl								; save header index
fill_blocks:
		; set ESE-RAM bank registers
		ld		[eseram8k_bank2], a				; ESE-RAM Bank2 (8KB)
		inc		a
		ld		[eseram8k_bank3], a				; ESE-RAM Bank3 (8KB)
		inc		a
		ld		c, a
		push	bc								; save remain blocks and ESE-RAM Bank index
		ld		bc, 16384 - 1
		ld		hl, 0x8000
		ld		de, 0x8001
		ld		[hl], c
		ldir
		pop		bc								; load remain blocks and ESE-RAM Bank index
		ld		a, '>'							; Display progress bar
		call	putc
		ld		a, c							; A = ESE-RAM Bank index
		djnz	fill_blocks						;
		jr		exit

		; COMMAND0: Start System ---------------------------------------------------------
start_system::
		; Initialize MegaSDHC MemoryID
		ld		a, exp_io_ocmkai_ctrl_reg_memory_id
		out		[exp_io_ocmkai_ctrl_register_sel], a
		ld		a, 1							; Default MemoryID for MegaSDHC is 0x01
		out		[exp_io_ocmkai_ctrl_data], a

		; Initialize MegaSDHC bank registers
		xor		a, a
		ld		[ eseram8k_bank0 ], a
		inc		a
		ld		[ eseram8k_bank1 ], a
		ld		[ eseram8k_bank2 ], a
		ld		[ eseram8k_bank3 ], a

		ld		a, 0xF0
		out		[ primary_slot_register ], a

		ld		a, [ 0x0000 ]					;  first byte
		cp		a, 0xF3							; = DI ?
		jp		nz, bios_read_error				;  error

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

		push	bc						; save next sector index
		push	de
		jr		c, no_match				; error


		ld		hl, buffer + bios_image_signature
		ld		de, bios_image_signature_reference
		ld		b, 4

check_signature_loop:
		ld		a, [de]
		cp		a, [hl]
		jr		nz, no_match
		inc		de
		inc		hl
		djnz	check_signature_loop
		jr		match					; Cy = 0 : success
no_match:
		scf								; Cy = 1 : error
match:
		pop		de						; load next sector index
		pop		bc
		ret

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
read_sector_hook	:= $ + 1
		jp			sd_read_sector
		endscope

; --------------------------------------------------------------------
;	subroutines
; --------------------------------------------------------------------
		include "ocm_iplrom_vdp_driver.asm"
		include "ocm_iplrom_sd_driver.asm"
		include "ocm_iplrom_srom_driver.asm"
		include "ocm_iplrom_message.asm"

; --------------------------------------------------------------------
;	work area
; --------------------------------------------------------------------
current_sector_low:
		dw		0
current_sector_high:
		dw		0
end_code::
