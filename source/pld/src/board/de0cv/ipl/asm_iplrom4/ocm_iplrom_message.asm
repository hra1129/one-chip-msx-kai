; ==============================================================================
;	IPL-ROM for OCM-PLD v3.9 or later
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
;	ver 3.0.0	caro
;	-- Added text font and message.
;
;	ver	4.0.0	t.hara
;	-- Changed the file format of BIOS image.
;
;	ver	4.0.7	t.hara
;	-- Fixed to skip BIOS loading when there is already a loaded BIOS.
;	-- Added a function to force BIOS loading when booting with the ESC key pressed, 
;	   even if the BIOS has already been loaded.
;
;	ver	4.1.0	t.hara in 2021/Aug/23rd
;	-- Support to search file name 'OCMKBIOS.DAT' in FAT file system.
;	-- Support DualEPBIOS.
; ==============================================================================

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
message_initial_text1::
		ds		"Initial Program Loader for OneChipMSX."
		db		0
message_initial_text2::
		ds		"Revision 4.1.3"
		db		0
message_initial_text3::
		ds		"OCM-Kai Build date Aug.16th.2022 "
		db		0

message_sd_boot::
		ds		"Boot from SD Card"
		db		0

message_srom_boot1::
		ds		"Boot from EPBIOS1"
		db		0

message_srom_boot2::
		ds		"Boot from EPBIOS2"
		db		0

message_bios_read_error::
		ds		"[ERROR!] Cannot read BIOS image."
		db		0
