//
// ocm_bus_selector.v
//	 1chipMSX BUS Selector
//	 Revision 1.00
//
// Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//	  this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//	  notice, this list of conditions and the following disclaimer in the
//	  documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//	  product or activity without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ----------------------------------------------------------------------------
//	History
//	June/16th/2021 Added OPL3 by t.hara
//
//	July/12th/2020 Added Panasonic MegaROM by t.hara
//
//	May/23th/2020 Created by t.hara
//		(1) Separate from emsx_top hierarchy.
//		(2) Support for new memory maps.
//		(3) Convert to Verilog.
//
//	Feb/22th/2021 t.hara
//		Added rom_mode port.
//		When rom_mode=0, some segments of MemoryMapper will be write-protected.
//
module ocm_bus_selector (
	input			reset,
	input			clk21m,
	input			trueClk,
	input			ff_clksel,
	input			ff_clksel5m_n,
	input			CpuM1_n,
	output			wait_n_s,
	input	[ 3:0]	CustomSpeed,
	output			req,
	output			mem,
	output			wrt,
	output	[15:0]	adr,
	output	[ 7:0]	dbo,
	output	[ 7:0]	dbi,
	input	[ 4:0]	eseram_memory_id,
	input	[20:0]	Scc1Adr,
	input	[20:0]	Scc2Adr,
	input	[21:0]	MapAdr,
	input	[17:0]	KanAdr,
	input	[19:0]	ErmAdr,
	input	[24:0]	PanaAdr,
	input			pSltIorq_n,
	input			pSltRd_n,
	input			pSltWr_n,
	input	[15:0]	pSltAdr,
	input	[ 7:0]	pSltDat,
	input			pSltRfsh_n,
	input			pSltMerq_n,
	input			pSltWait_n,
	input	[ 1:0]	PriSltNum,
	input	[ 1:0]	ExpSltNum0,
	input	[ 1:0]	ExpSltNum3,
	input	[ 7:0]	io40_n,
	input			okaictrl_en,
	input			JIS2_ena,
	input			MmcEna,
	input			MmcAct,
	input			portF4_mode,
	input			FullRAM,
	output			BusDir,
	output			iSltRfsh_n,
	output			iSltMerq_n,
	output			iSltIorq_n,
	output	[24:0]	CpuAdr,
	input	[ 7:0]	ExpDbi,
	input	[ 7:0]	RomDbi,
	input	[ 7:0]	MmcDbi,
	input	[ 7:0]	VdpDbi,
	input	[ 7:0]	PsgDbi,
	input	[ 7:0]	PpiDbi,
	input	[ 7:0]	KanDbi,
	input	[ 7:0]	PanaDbi,
	input	[ 7:0]	MapDbi,
	input	[ 7:0]	RtcDbi,
	input	[ 7:0]	s1990_dbi,
	input	[ 7:0]	tr_pcm_dbi,
	input	[ 7:0]	tr_midi_dbi,
	input	[ 7:0]	swio_dbi,
	input	[ 7:0]	okaictrl_dbi,
	input	[ 7:0]	system_flags_dbi,
	input	[ 7:0]	Scc1Dbi,
	input	[ 7:0]	Scc2Dbi,
	input	[ 7:0]	RamDbi,
	input	[ 7:0]	Opl3Dbi,
	input			RamAck,
	input			Scc1Ack,
	input			Scc2Ack,
	input			PanaAck,
	input			OpllAck,
	output			ldbios_n,
	input			iSlt1_linear,
	input			iSlt2_linear,
	input			MmcMode,
	input			Slot0Mode,
	input	[ 1:0]	Slot1Mode,
	input	[ 1:0]	Slot2Mode,
	input			rom_mode,					//	0: DRAM mode, 1: ROM mode
	input			opl3_enabled,
	output			mem_slot0_0,
	output			mem_slot0_1,
	output			mem_slot0_2,
	output			mem_slot0_3,
	output			mem_slot1_scc,
	output			mem_slot1_linear,
	output			mem_slot2_scc,
	output			mem_slot2_linear,
	output			mem_mapper,
	output			mem_slot3_1,
	output			mem_eseram,
	output			mem_panamega,
	input			Scc1Ram,
	input			Scc2Ram,
	input			ErmRam,
	input			PanaRam,
	input			MapRam,
	input			KanRom,
	output			RamReq,
	output			OpllReq,
	output			VdpReq,
	output			PsgReq,
	output			PpiReq,
	output			KanReq,
	output			MapReq,
	output			Scc1Req,
	output			Scc2Req,
	output			ErmReq,
	output			PanaReq,
	output			RtcReq,
	output			s1990_req,
	output			exp_io_req,
	output			system_flags_req,
	output			tr_pcm_req,
	output			tr_midi_req,
	output			opl3_req,
	input			req_reset_primary_slot,
	output			ack_reset_primary_slot
);
	reg				ff_ldbios_n		= 1'b0;
	reg				ff_iSltRfsh_n;
	reg				ff_iSltMerq_n;
	reg				ff_iSltIorq_n;
	reg				ff_xSltRd_n;
	reg				ff_xSltWr_n;
	reg		[15:0]	ff_iSltAdr;
	reg		[ 7:0]	ff_iSltDat;
	reg				ff_wrt;
	wire			w_ack;
	reg				ff_ack;
	wire			w_req;
	wire			w_mem;
	wire	[ 3:0]	w_page_dec;
	wire	[ 3:0]	w_prislt_dec;
	wire	[ 3:0]	w_expslt0_dec;
	wire	[ 3:0]	w_expslt3_dec;
	reg				ff_ExpDec;
	reg		[ 7:0]	ff_dlydbi;
	wire			w_mem_slot0_0;
	wire			w_mem_slot0_1;
	wire			w_mem_slot0_2;
	wire			w_mem_slot0_3;
	wire			w_mem_slot1_scc;
	wire			w_mem_slot1_linear;
	wire			w_mem_slot2_scc;
	wire			w_mem_slot2_linear;
	wire			w_mem_mapper_protected_segment;
	wire			w_mem_mapper;
	wire			w_mem_slot3_1;
	wire			w_mem_eseram;
	wire			w_mem_panamega;
	wire			w_mem_iplrom;
	wire			w_mem_kanjirom;
	wire			w_RamReq;
	wire			w_RomReq;
	wire			w_OpllReq;
	wire			w_ErmReq;
	wire			w_PanaReq;
	reg				ff_mem_slot1_scc;
	reg				ff_mem_slot2_scc;
	reg				ff_mem_panamega;
	reg				ff_slot_mem;
	wire	[ 3:0]	w_wait_count;
	wire	[ 3:0]	w_wait_count00;
	wire	[ 3:0]	w_wait_count01;
	wire	[ 3:0]	w_wait_count02;
	wire	[ 3:0]	w_wait_count03;
	wire	[ 3:0]	w_wait_count04;
	wire	[ 3:0]	w_wait_count05;
	reg		[ 3:0]	ff_wait_count;
	reg				iCpuM1_n;
	reg				jSltMerq_n;
	reg				jSltIorq_n;
	reg				ff_wait_n_s;
	wire			w_ack_reset_primary_slot;
	wire			w_ram_bios_enable;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_iSltRfsh_n	<= 1'b1;
			ff_iSltMerq_n	<= 1'b1;
			ff_iSltIorq_n	<= 1'b1;
			ff_xSltRd_n		<= 1'b1;
			ff_xSltWr_n		<= 1'b1;
			ff_iSltAdr		<= 16'hFFFF;
			ff_iSltDat		<= 8'hFF;
		end
		else begin
			ff_iSltRfsh_n	<= pSltRfsh_n;
			ff_iSltMerq_n	<= pSltMerq_n;
			ff_iSltIorq_n	<= pSltIorq_n;
			ff_xSltRd_n		<= pSltRd_n;
			ff_xSltWr_n		<= pSltWr_n;
			ff_iSltAdr		<= pSltAdr;
			ff_iSltDat		<= pSltDat;
		end
	end

	assign iSltRfsh_n	= ff_iSltRfsh_n;
	assign iSltMerq_n	= ff_iSltMerq_n;
	assign iSltIorq_n	= ff_iSltIorq_n;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_wrt	<= 1'b0;
		end
		else begin
			ff_wrt	<= ~pSltWr_n;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_ack <= 1'b0;
		end
		else if( ff_iSltMerq_n && ff_iSltIorq_n ) begin
			ff_ack <= 1'b0;
		end
		else if( w_ack ) begin
			ff_ack <= 1'b1;
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_ExpDec <= 1'b0;
		end
		else begin
			if( ff_iSltAdr == 16'hFFFF ) begin
				ff_ExpDec <= 1'b1;
			end
			else begin
				ff_ExpDec <= 1'b0;
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_dlydbi <= 8'd0;
		end
		else begin
			if( w_mem && ff_ExpDec ) begin
				ff_dlydbi <= ExpDbi;
			end
			else if( w_mem && w_mem_iplrom ) begin														// IPL-ROM
				ff_dlydbi <= RomDbi;
			end
			else if( w_mem && w_mem_eseram && MmcEna                                       ) begin		// MegaSD
				ff_dlydbi <= MmcDbi;
			end
//			else if( !w_mem && { ff_iSltAdr[ 7:4 ], 4'd0 } == 8'h40 && io40_n != 8'hFF     ) begin		// Switched I/O ports
			else if( !w_mem && { ff_iSltAdr[ 7:4 ], 4'd0 } == 8'h40                        ) begin		// Switched I/O ports, OCM-Kai Control Device	// Modified by t.hara in May/11th/2020
				ff_dlydbi <= swio_dbi & okaictrl_dbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:2 ], 2'd0 } == 8'h98                        ) begin		// VDP (V9938/V9958)
				ff_dlydbi <= VdpDbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:2 ], 2'd0 } == 8'hA0                        ) begin		// PSG (AY-3-8910)
				ff_dlydbi <= PsgDbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:1 ], 1'd0 } == 8'hA4                        ) begin		// turboR PCM device		// 2019/11/29 t.hara added
				ff_dlydbi <= tr_pcm_dbi;                                                          									// 2019/11/29 t.hara added
			end
			else if( !w_mem &&   ff_iSltAdr[ 7:0 ]         == 8'hA7 && portF4_mode == 1'b1 ) begin		// Pause R800 (read only)
				ff_dlydbi <= 8'h00;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:2 ], 2'd0 } == 8'hA8                        ) begin		// PPI (8255)
				ff_dlydbi <= PpiDbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:1 ], 1'd0 } == 8'hB4                        ) begin		// RTC (RP-5C01)
				ff_dlydbi <= RtcDbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:1 ], 1'd0 } == 8'hD8                        ) begin		// Kanji-data (JIS1 only)
				ff_dlydbi <= KanDbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:2 ], 2'd0 } == 8'hD8 && JIS2_ena == 1'b1    ) begin		// Kanji-data (JIS1+JIS2)
				ff_dlydbi <= KanDbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:2 ], 2'd0 } == 8'hE4                        ) begin		// System timer (S1990)
				ff_dlydbi <= s1990_dbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:3 ], 3'd0 } == 8'hE8                        ) begin		// MSX-MIDI ports			// 2020/02/12 t.hara added
				ff_dlydbi <= tr_midi_dbi;
			end
			else if( !w_mem && (ff_iSltAdr[ 7:0 ] == 8'hF4 || ff_iSltAdr[ 7:0 ] == 8'hA7)  ) begin		// Port F4, A7
				ff_dlydbi <= system_flags_dbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:2 ], 2'd0 } == 8'hFC && !FullRAM            ) begin		// Memory-mapper 2048 kB
				ff_dlydbi <= { 1'b1, MapDbi[6:0] };
			end
			else if( !w_mem && { ff_iSltAdr[ 7:2 ], 2'd0 } == 8'hFC                        ) begin		// Memory-mapper 4096 kB
				ff_dlydbi <= MapDbi;
			end
			else if( !w_mem && { ff_iSltAdr[ 7:3 ], 3'd0 } == 8'hC0 && opl3_enabled        ) begin		// OPL3
				ff_dlydbi <= Opl3Dbi;
			end
//			else if( !w_mem && { ff_iSltAdr[ 7:1 ], 1'd0 } == 8'h7C                        ) begin		// OPL3
//				ff_dlydbi <= Opl3Dbi;
//			end
			else begin
				ff_dlydbi <= 8'hFF;
			end
		end
	end

	assign w_page_dec	=	( ff_iSltAdr[15:14] == 2'd0 ) ? 4'b0001 :
							( ff_iSltAdr[15:14] == 2'd1 ) ? 4'b0010 :
							( ff_iSltAdr[15:14] == 2'd2 ) ? 4'b0100 :
							( ff_iSltAdr[15:14] == 2'd3 ) ? 4'b1000 : 4'dx;

	assign w_prislt_dec	=	( PriSltNum         == 2'd0 ) ? 4'b0001 :
							( PriSltNum         == 2'd1 ) ? 4'b0010 :
							( PriSltNum         == 2'd2 ) ? 4'b0100 :
							( PriSltNum         == 2'd3 ) ? 4'b1000 : 2'dx;

	assign w_expslt0_dec=	( ExpSltNum0        == 2'd0 ) ? 4'b0001 :
							( ExpSltNum0        == 2'd1 ) ? 4'b0010 :
							( ExpSltNum0        == 2'd2 ) ? 4'b0100 :
							( ExpSltNum0        == 2'd3 ) ? 4'b1000 : 2'dx;

	assign w_expslt3_dec=	( ExpSltNum3        == 2'd0 ) ? 4'b0001 :
							( ExpSltNum3        == 2'd1 ) ? 4'b0010 :
							( ExpSltNum3        == 2'd2 ) ? 4'b0100 :
							( ExpSltNum3        == 2'd3 ) ? 4'b1000 : 2'dx;

	assign w_req		=	( (!ff_iSltMerq_n || !ff_iSltIorq_n) && (!ff_xSltRd_n || !ff_xSltWr_n) && !ff_ack ) ? 1'b1 : 1'b0;

	assign w_ack		=	( w_RamReq == 1'b1        ) ? RamAck	:		// ErmAck, MapAck, KanAck
							( w_mem_slot1_scc == 1'b1 ) ? Scc1Ack	:		// Scc1Ack
							( w_mem_slot2_scc == 1'b1 ) ? Scc2Ack	:		// Scc2Ack
							( w_mem_panamega == 1'b1  ) ? PanaAck	:		// PanaAck
							( w_OpllReq == 1'b1       ) ? OpllAck	:		// OpllAck
							w_req;											// PsgAck, PpiAck, VdpAck, RtcAck, ...

	assign w_mem		= ff_iSltIorq_n;

	assign req			= w_req;
	assign wrt			= ff_wrt;
	assign mem			= w_mem;
	assign dbo			= ff_iSltDat;
	assign adr			= ff_iSltAdr;

	assign BusDir					=
			( {pSltAdr[7:4], 4'd0} == 8'h40 && (io40_n != 8'hFF || okaictrl_en == 1'b1)	) ? 1'b1 :		// I/O:40-4Fh / Switched I/O ports
			( {pSltAdr[7:2], 2'd0} == 8'h98												) ? 1'b1 :		// I/O:98-9Bh / VDP (TMS9918/V9938/V9958)

			// commented out to enable the PSG signal to the external slot (the joystick should respond)
			( {pSltAdr[7:2], 2'd0} == 8'hA0												) ? 1'b1 :		// I/O:A0-A3h / PSG (AY-3-8910)

			( {pSltAdr[7:1], 1'd0} == 8'hA4												) ? 1'b1 :		// I/O:A4-A5h / turboR PCM device
			(  pSltAdr[7:0]        == 8'hA7												) ? 1'b1 :		// I/O:A7h	  / Pause R800 (read only)
			( {pSltAdr[7:2], 2'd0} == 8'hA8												) ? 1'b1 :		// I/O:A8-ABh / PPI (8255)
			( {pSltAdr[7:1], 1'd0} == 8'hB4												) ? 1'b1 :		// I/O:B4-B5h / RTC (RP-5C01)
			( {pSltAdr[7:1], 1'd0} == 8'hD8												) ? 1'b1 :		// I/O:D8-DBh / Kanji-data (JIS1+JIS2)
			( {pSltAdr[7:1], 1'd0} == 8'hDA && JIS2_ena									) ? 1'b1 :		// I/O:D8-D9h / Kanji-data (JIS1 only)
			( {pSltAdr[7:2], 2'd0} == 8'hE4												) ? 1'b1 :		// I/O:E4-E7h / S1990
			( {pSltAdr[7:2], 2'd0} == 8'hE8												) ? 1'b1 :		// I/O:E8-EFh / MSX-MIDI device
			(  pSltAdr[7:0]        == 8'hF4												) ? 1'b1 :		// I/O:F4h	  / Port F4 device
			( {pSltAdr[7:2], 2'd0} == 8'hFC												) ? 1'b1 :		// I/O:FC-FFh / Memory-mapper
																						    1'b0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset )begin
			ff_mem_slot1_scc <= 1'b0;
		end
		else if( w_mem_slot1_scc )begin
			ff_mem_slot1_scc <= 1'b1;
		end
		else begin
			ff_mem_slot1_scc <= 1'b0;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset )begin
			ff_mem_slot2_scc <= 1'b0;
		end
		else if( w_mem_slot2_scc )begin
			ff_mem_slot2_scc <= 1'b1;
		end
		else begin
			ff_mem_slot2_scc <= 1'b0;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset )begin
			ff_mem_panamega <= 1'b0;
		end
		else if( w_mem_panamega )begin
			ff_mem_panamega <= 1'b1;
		end
		else begin
			ff_mem_panamega <= 1'b0;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset )begin
			ff_slot_mem <= 1'b0;
		end
		else begin
			if( w_mem_eseram )begin
				if( MmcEna && (ff_iSltAdr[15:13] == 3'b010) )begin
					ff_slot_mem <= 1'b0;
				end
				else if( MmcMode || !ff_ldbios_n )begin						// enable SD/MMC drive
					ff_slot_mem <= 1'b1;
				end
				else begin													// disable SD/MMC drive
					ff_slot_mem <= 1'b0;
				end
			end
			else if( w_mem_mapper || w_mem_slot1_linear || w_mem_slot2_linear ||
					 w_mem_slot0_0 || w_mem_slot0_1 || w_mem_slot0_2 || w_mem_slot0_3 || 
					 w_mem_slot3_1 )begin
					ff_slot_mem <= 1'b1;
			end
			else begin
					ff_slot_mem <= 1'b0;
			end
		end
	end

	assign dbi	=	( ff_mem_slot1_scc ) ? Scc1Dbi	:
					( ff_mem_slot2_scc ) ? Scc2Dbi	:
					( ff_mem_panamega  ) ? PanaDbi	:
					( ff_slot_mem      ) ? RamDbi	: ff_dlydbi;

	//--------------------------------------------------------------
	// Z80 CPU wait control
	//--------------------------------------------------------------
	assign w_wait_count00	= ( ff_ldbios_n == 1'b0                      ) ? 'b0010              : CustomSpeed;
	assign w_wait_count01	= ( ff_clksel == 1'b1                        ) ? w_wait_count00      : 'b0001;
	assign w_wait_count02	= ( ff_wait_count != 'b0000                  ) ? (ff_wait_count - 1) : ff_wait_count;
	assign w_wait_count03	= ( ff_clksel5m_n == 1'b0                    ) ? 'b0110              : ff_wait_count;
	assign w_wait_count04	= ( ff_clksel == 1'b1                        ) ? 'b0011              : w_wait_count03;
	assign w_wait_count05	= ( pSltIorq_n == 1'b0 && jSltIorq_n == 1'b1 ) ? w_wait_count04      : w_wait_count02;
	assign w_wait_count		= ( pSltMerq_n == 1'b0 && jSltMerq_n == 1'b1 ) ? w_wait_count01      : w_wait_count05;

	always @( posedge reset or posedge trueClk ) begin
		if( reset == 1'b1 )begin
			iCpuM1_n		<= 1'b1;
			jSltIorq_n		<= 1'b1;
			jSltMerq_n		<= 1'b1;
			ff_wait_count	<= 4'd0;
			ff_wait_n_s		<= 1'b1;												// WAIT_n fix by Victor Trucco
		end
		else begin
			ff_wait_count	<= w_wait_count;

			if( (CpuM1_n == 1'b0 && iCpuM1_n == 1'b1) || pSltWait_n == 1'b0 )begin
				ff_wait_n_s <= 1'b0;
			end
			else if( w_wait_count != 4'd0 )begin
				ff_wait_n_s <= 1'b0;
			end
			else if( (ff_clksel == 1'b1 || ff_clksel5m_n == 1'b0) && OpllReq == 1'b1 && OpllAck == 1'b0 )begin
				ff_wait_n_s <= 1'b0;
			end
			else if( w_ErmReq == 1'b1 && ff_iSltAdr[15:13] == 3'b010 && MmcAct == 1'b1 )begin
				ff_wait_n_s <= 1'b0;
			end
			else begin
//				ff_wait_n_s <= ~SdPaus;									// dismissed
				ff_wait_n_s <= 1'b1;
			end

			iCpuM1_n	<= CpuM1_n;
			jSltIorq_n	<= pSltIorq_n;
			jSltMerq_n	<= pSltMerq_n;
		end
	end

	assign wait_n_s = ff_wait_n_s;

	//--------------------------------------------------------------
	// IPL-ROM enabler
	//--------------------------------------------------------------
	always @( /* posedge reset or */ posedge clk21m ) begin
		if( reset == 1'b1 ) begin
			ff_ldbios_n <= 1'b0;				// OCM-BIOS is waiting to be loaded by IPL-ROM
		end
		else begin
			if( w_ack_reset_primary_slot ) begin
				ff_ldbios_n <= 1'b1;			// OCM-BIOS has been loaded by IPL-ROM
			end
			else begin
				//	hold
			end
		end
	end

	assign w_ack_reset_primary_slot	= (ff_iSltAdr == 16'h0000) ? ~ff_iSltMerq_n & ~ff_xSltRd_n & req_reset_primary_slot : 1'b0;
	assign ack_reset_primary_slot	= w_ack_reset_primary_slot;

	//--------------------------------------------------------------
	// External memory access
	//--------------------------------------------------------------
	// Slot map / SD-RAM memory map
	//
	//	Slot0-0 page 0: MainROM		( 0000000h - 0003FFFh )	16KB
	//	Slot0-0 page 1: MainROM		( 0004000h - 0007FFFh )	16KB
	//	Slot0-0 page 2				( 0008000h - 000BFFFh )	16KB
	//	Slot0-0 page 3				( 000C000h - 000FFFFh )	16KB
	//	Slot0-1 page 0				( 0010000h - 0013FFFh )	16KB
	//	Slot0-1 page 1				( 0014000h - 0017FFFh )	16KB
	//	Slot0-1 page 2				( 0018000h - 001BFFFh )	16KB
	//	Slot0-1 page 3				( 001C000h - 001FFFFh )	16KB
	//	Slot0-2 page 0				( 0020000h - 0023FFFh )	16KB
	//	Slot0-2 page 1: MSX-MUSIC	( 0024000h - 0027FFFh )	16KB
	//	Slot0-2 page 2				( 0028000h - 002BFFFh )	16KB
	//	Slot0-2 page 3				( 002C000h - 002FFFFh )	16KB
	//	Slot0-3 page 0				( 0030000h - 0033FFFh )	16KB
	//	Slot0-3 page 1: OpeningROM	( 0034000h - 0037FFFh )	16KB
	//	Slot0-3 page 2				( 0038000h - 003BFFFh )	16KB
	//	Slot0-3 page 3				( 003C000h - 003FFFFh )	16KB
	//	Slot3-1 page 0: SubROM		( 0040000h - 0043FFFh )	16KB
	//	Slot3-1 page 1: KanjiDriver	( 0044000h - 0047FFFh )	16KB
	//	Slot3-1 page 2: KanjiDriver	( 0048000h - 004BFFFh )	16KB
	//	Slot3-1 page 3				( 004C000h - 004FFFFh )	16KB
	//	        No connect			( 0050000h - 00FFFFFh )	704KB
	//	Slot3-2 MegaSDHC/Nextor		( 0100000h - 01FFFFFh )	1MB
	//	Slot1   ESE-SCC1(1st)		( 0200000h - 03FFFFFh )	2MB
	//	Slot2   ESE-SCC2(1st)		( 0400000h - 05FFFFFh )	2MB
	//	        No connect			( 0600000h - 07FFFFFh )	2MB
	//	Slot3-0 MapperRAM			( 0800000h - 0BFFFFFh )	4MB
	//	        KanjiROM			( 0C00000h - 0C3FFFFh )	256KB
	//	        No connect			( 0C40000h - 0CFFFFFh )	768KB
	//	        No connect			( 0D00000h - 0FFFFFFh )	3MB
	//	Slot3-3 PanaMegaROM			( 1000000h - 13FFFFFh )	4MB
	//	        No connect			( 1400000h - 1EFFFFFh )	11MB
	//	        VRAM				( 1F00000h - 1FFFFFFh )	1MB
	//
	//	R800-DRAM mode                  : 2MB Mapper : 4MB Mapper
	//	    MainROM on MemoryMapper     :   09F0000h :   0BF0000h
	//	    SubROM on MemoryMapper      :   09F8000h :   0BF8000h
	//	    KanjiDriver on MemoryMapper :   09FC000h :   0BFC000h

	assign w_ram_bios_enable	= ~rom_mode & (w_mem_slot0_0 | w_mem_slot3_1) & ~ff_iSltAdr[15];

	assign CpuAdr[24:20] =	( w_mem_eseram  				) ?   eseram_memory_id			:	// xxxxxxx => 32768 kB ESE-RAM
							( w_mem_slot1_linear 			) ?   5'h02						:	// 02xxxxx =>    64 kB Linear over ESE-SCC1
							( w_mem_slot1_scc 				) ? { 4'b0_001, Scc1Adr[20] }	:	// 02xxxxx =>  2048 kB ESE-SCC1
							( w_mem_slot2_linear 			) ?   5'h04						:	// 04xxxxx =>    64 kB Linear over ESE-SCC2
							( w_mem_slot2_scc 				) ? { 4'b0_010, Scc2Adr[20] }	:	// 04xxxxx =>  2048 kB ESE-SCC2
							( w_mem_mapper && FullRAM		) ? { 3'b0_10, MapAdr[21:20] }	:	// 08xxxxx =>  4096 kB Mapped RAM
							( w_mem_mapper  				) ? { 4'b0_100, MapAdr[20] }	:	// 08xxxxx =>  2048 kB Mapped RAM
							( w_mem_kanjirom 				) ?   5'h0C						:	// 0Cxxxxx =>   256 kB Kanji-data (JIS1+JIS2)
							( w_mem_panamega 				) ? PanaAdr[24:20]				:	// xxxxxxx =>  4096 kB PanaMegaROM
							( w_ram_bios_enable && ~FullRAM	) ? 5'b0_1001					:	// 09xxxxx =>  4096 kB Mapped RAM
							( w_ram_bios_enable &&  FullRAM	) ? 5'b0_1011					:	// 0Bxxxxx =>  2048 kB Mapped RAM
							5'h00;																// 00xxxxx =>          others (slot0-x, slot3-1)

	assign CpuAdr[19:0] =	( w_ram_bios_enable && w_mem_slot0_0	) ? { 5'b11110, ff_iSltAdr[14:0] }	:	// xxF0000h-xxF7FFFh (  32 kB)  Mapped RAM Seg#FCh-FDh
							( w_ram_bios_enable && w_mem_slot3_1	) ? { 5'b11111, ff_iSltAdr[14:0] }	:	// xxF8000h-xxFFFFFh (  32 kB)  Mapped RAM Seg#FEh-FFh
							( w_mem_slot0_0							) ? { 4'b0000, ff_iSltAdr }			:	// 0000000h-000FFFFh (  64 kB)  Internal Slot0-0
							( w_mem_slot0_1							) ? { 4'b0001, ff_iSltAdr }			:	// 0010000h-001FFFFh (  64 kB)  Internal Slot0-1
							( w_mem_slot0_2							) ? { 4'b0010, ff_iSltAdr }			:	// 0020000h-002FFFFh (  64 kB)  Internal Slot0-2
							( w_mem_slot0_3							) ? { 4'b0011, ff_iSltAdr }			:	// 0030000h-003FFFFh (  64 kB)  Internal Slot0-3
							( w_mem_slot3_1							) ? { 4'b0100, ff_iSltAdr }			:	// 0040000h-004FFFFh (  64 kB)  Internal Slot3-1
							( w_mem_eseram							) ?   ErmAdr						:	// 0100000h-01FFFFFh (1024 kB)  Internal Slot3-2
							( w_mem_slot1_linear					) ? { 4'b0000, ff_iSltAdr }			:	// 0200000h-020FFFFh (  64 kB)  Internal Slot1 Linear
							( w_mem_slot1_scc						) ?   Scc1Adr[19:0]					:	// 0200000h-03FFFFFh (2048 kB)  Internal Slot1
							( w_mem_slot2_linear					) ? { 4'b0000, ff_iSltAdr }			:	// 0400000h-040FFFFh (  64 kB)  Internal Slot2 Linear
							( w_mem_slot2_scc						) ?   Scc2Adr[19:0]					:	// 0400000h-05FFFFFh (2048 kB)  Internal Slot2
							( w_mem_mapper							) ?   MapAdr[19:0]					:	// 0800000h-0BFFFFFh (4096 kB)  Internal Slot3-0
							( w_mem_kanjirom						) ? { 2'b00, KanAdr[17:0] }			:	// 0C00000h-0C3FFFFh ( 256 kB)  Kanji-data (JIS1+JIS2)
							( w_mem_panamega						) ?   PanaAdr[19:0]					:	// 1000000h-13FFFFFh (  16 kB)  Internal Slot3-3
							20'd0;

	// -------------------------------------------------------------
	assign w_mem_mapper_protected_segment	=	( rom_mode == 1'b1 || wrt == 1'b0 ) ? 1'b0 :
												( MapAdr[20:16] == 5'b11111  && FullRAM == 1'b0 ) ? 1'b1 :
												( MapAdr[21:16] == 6'b111111 ) ? 1'b1 : 1'b0;

	//--------------------------------------------------------------
	//	Address Decode for CPU
	//--------------------------------------------------------------
	// Slot0-X
	assign w_mem_slot0_0		=	( ff_iSltAdr != 16'hFFFF && (w_prislt_dec[0] && (w_expslt0_dec[0] || ~Slot0Mode)     ) == 1'b1					) ? w_mem :	// 0-0 (0000-FFFEh)	   64 kB  MSX2P	  .ROM / MSXTR	 .ROM
								1'b0;
	assign w_mem_slot0_1		=	( ff_iSltAdr != 16'hFFFF && (w_prislt_dec[0] && w_expslt0_dec[1] && Slot0Mode        ) == 1'b1					) ? w_mem :	// 0-1 (0000-FFFEh)	   64 kB  Free
								1'b0;
	assign w_mem_slot0_2		=	( ff_iSltAdr != 16'hFFFF && (w_prislt_dec[0] && w_expslt0_dec[2] && Slot0Mode        ) == 1'b1					) ? w_mem :	// 0-2 (0000-FFFEh)	   64 kB  MSX2PMUS.ROM / MSXTRMUS.ROM
								1'b0;
	assign w_mem_slot0_3		=	( ff_iSltAdr != 16'hFFFF && (w_prislt_dec[0] && w_expslt0_dec[3] && Slot0Mode        ) == 1'b1					) ? w_mem :	// 0-3 (0000-FFFEh)	   64 kB  FREE16KB.ROM / MSXTROPT.ROM
								1'b0;
	// Slot1
	assign w_mem_slot1_scc		=	( (w_prislt_dec[1] && (w_page_dec[1] || w_page_dec[2]) && (~iSlt1_linear)) == 1'b1 && Slot1Mode != 2'b00		) ? w_mem :	// 1   (4000-BFFFh)	 2048 kB  ESE-SCC1
								1'b0;
	assign w_mem_slot1_linear	=	( (w_prislt_dec[1] && iSlt1_linear) == 1'b1 && Slot1Mode != 2'b00												) ? w_mem :	// 1   (0000-FFFFh)	   64 kB  Linear over ESE-SCC1
								1'b0;
	// Slot2
	assign w_mem_slot2_scc		=	( (w_prislt_dec[2] && (w_page_dec[1] || w_page_dec[2]) && (~iSlt2_linear)) == 1'b1 && Slot2Mode != 2'b00		) ? w_mem :	// 2   (4000-BFFFh)	 2048 kB  ESE-SCC2
								1'b0;
	assign w_mem_slot2_linear	=	( (w_prislt_dec[2] && iSlt2_linear) == 1'b1 && Slot2Mode != 2'b00												) ? w_mem :	// 2   (0000-FFFFh)	   64 kB  Linear over ESE-SCC2
								1'b0;
	// Slot3-X
	assign w_mem_mapper			=	( ff_iSltAdr != 16'hFFFF && (w_prislt_dec[3] && w_expslt3_dec[0]) == 1'b1 && !w_mem_mapper_protected_segment	) ? w_mem :	// 3-0 (0000-FFFEh)	 4096 kB  Internal Mapper
								1'b0;
	assign w_mem_slot3_1		=	( ff_iSltAdr != 16'hFFFF && (w_prislt_dec[3] && w_expslt3_dec[1]) == 1'b1										) ? w_mem :	// 3-1 (0000-FFFEh)	   64 kB  (MSX2PEXT.ROM || MSXTREXT.ROM) + MSXKANJI.ROM
								1'b0;
	assign w_mem_eseram			=	(                           (w_prislt_dec[3] && w_expslt3_dec[2] && (w_page_dec[1] || w_page_dec[2])) == 1'b1	) ? w_mem :	// 3-2 (4000-BFFFh)	  128 kB  (MEGASDHC.ROM + FILL64KB.ROM) || NEXT||16.ROM
								1'b0;
	assign w_mem_panamega		=	(                           (w_prislt_dec[3] && w_expslt3_dec[3] && ~w_page_dec[3] && ( ff_ldbios_n)) == 1'b1	) ? w_mem :	// 3-3 (4000-7FFFh)	 4096 kB  XBASIC2 .ROM / XBASIC21.ROM || FS-A1GT MSX-View/RomDisk/A1 Cockpit ROM
								1'b0;
	assign w_mem_iplrom			=	(                           (w_prislt_dec[3] && w_expslt3_dec[3] &&  w_page_dec[0] && (~ff_ldbios_n)) == 1'b1	) ? w_mem :	// 3-3 (0000-3FFFh)	    2 kB  IPL-ROM (pre-boot state)
								1'b0;
	assign w_mem_kanjirom		=	( { ff_iSltAdr[7:2], 2'd0 } == 8'hD8 ) ? ~w_mem:
								1'b0;

	assign w_RomReq				=	( (w_mem_slot0_0 | w_mem_slot0_1 | w_mem_slot0_2 | w_mem_slot0_3 | 
									   w_mem_slot3_1 | w_mem_panamega | 
									   w_mem_slot1_linear | w_mem_slot2_linear) == 1'b1) ? req : 1'b0;

	assign w_RamReq				= Scc1Ram | Scc2Ram | ErmRam | PanaRam | MapRam | w_RomReq | KanRom;
	assign RamReq				= w_RamReq;

	// access request to component
	assign w_OpllReq 			=	( !ff_iSltIorq_n && { ff_iSltAdr[7:1], 1'd0 } == 8'h7C && Slot0Mode == 1'b1      ) ? req : 1'b0;					// I/O:7C-7Dh	/ OPLL (YM2413)
	assign OpllReq				=	w_OpllReq;
	assign VdpReq				=	( !ff_iSltIorq_n && { ff_iSltAdr[7:2], 2'd0 } == 8'h98                           ) ? req : 1'b0;					// I/O:98-9Bh	/ VDP (V9938/V9958)
	assign PsgReq				=	( !ff_iSltIorq_n && { ff_iSltAdr[7:2], 2'd0 } == 8'hA0                           ) ? req : 1'b0;					// I/O:A0-A3h	/ PSG (AY-3-8910)
	assign PpiReq				=	( !ff_iSltIorq_n && { ff_iSltAdr[7:2], 2'd0 } == 8'hA8                           ) ? req : 1'b0;					// I/O:A8-ABh	/ PPI (8255)
	assign KanReq				=	( !ff_iSltIorq_n && { ff_iSltAdr[7:2], 2'd0 } == 8'hD8                           ) ? req : 1'b0;					// I/O:D8-DBh	/ Kanji-data
	assign MapReq				=	( !ff_iSltIorq_n && { ff_iSltAdr[7:2], 2'd0 } == 8'hFC                           ) ? req :							// I/O:FC-FFh	/ Memory-mapper
									( w_mem_mapper                                                                   ) ? req : 1'b0;					// MEM:			/ Memory-mapper
	assign Scc1Req 				=	( w_mem_slot1_scc                                                                ) ? req : 1'b0;					// MEM:			/ ESE-SCC1
	assign Scc2Req 				=	( w_mem_slot2_scc                                                                ) ? req : 1'b0;					// MEM:			/ ESE-SCC2
	assign w_ErmReq				=	( w_mem_eseram                                                                   ) ? req : 1'b0;					// MEM:			/ ESE-RAM, MegaSD
	assign w_PanaReq			=	( w_mem_panamega                                                                 ) ? req : 1'b0;					// MEM:			/ Panasonic MegaROM
	assign RtcReq				=	( !ff_iSltIorq_n && { ff_iSltAdr[7:1], 1'd0 } == 8'hB4                           ) ? req : 1'b0;					// I/O:B4-B5h	/ RTC (RP-5C01)
	assign s1990_req			=	( !ff_iSltIorq_n && { ff_iSltAdr[7:2], 2'd0 } == 8'hE4                           ) ? req : (w_mem && ff_wrt);		// I/O:E4-E7h	/ S1990
	assign exp_io_req			=	( !ff_iSltIorq_n && { ff_iSltAdr[7:4], 4'd0 } == 8'h40                           ) ? req : 1'b0;					// I/O:40-4Fh	/ Switched I/O ports, OCM-Kai Control Device  // Modified by t.hara in May/11th/2020
	assign system_flags_req		=	( !ff_iSltIorq_n && ( ff_iSltAdr[7:0] == 8'hF4 || ff_iSltAdr[7:0] == 8'hA7 )     ) ? req : 1'b0;					// I/O:F4h, A7h	/ Port F4 device, A7 device
	assign tr_pcm_req			=	( !ff_iSltIorq_n && { ff_iSltAdr[7:1], 1'd0 } == 8'hA4                           ) ? req : 1'b0;					// I/O:A4h-A5h	/ turboR PCM device		// 2019/11/29 t.hara added
	assign tr_midi_req			=	( !ff_iSltIorq_n && { ff_iSltAdr[7:3], 3'd0 } == 8'hE8                           ) ? req : 1'b0;					// I/O:E8h-EFh	/ MSX-MIDI

	assign mem_slot0_0			= w_mem_slot0_0;
	assign mem_slot0_1			= w_mem_slot0_1;
	assign mem_slot0_2			= w_mem_slot0_2;
	assign mem_slot0_3			= w_mem_slot0_3;
	assign mem_slot1_scc		= w_mem_slot1_scc;
	assign mem_slot1_linear		= w_mem_slot1_linear;
	assign mem_slot2_scc		= w_mem_slot2_scc;
	assign mem_slot2_linear		= w_mem_slot2_linear;
	assign mem_mapper			= w_mem_mapper;
	assign mem_slot3_1			= w_mem_slot3_1;
	assign mem_eseram			= w_mem_eseram;
	assign mem_panamega			= w_mem_panamega;
	assign ErmReq				= w_ErmReq;
	assign PanaReq				= w_PanaReq;
	assign ldbios_n				= ff_ldbios_n;
endmodule
