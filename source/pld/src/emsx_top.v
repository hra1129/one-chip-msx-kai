//
// emsx_top.vhd
//	 ESE MSX-SYSTEM3 / MSX clone on a Cyclone FPGA (ALTERA)
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
//-----------------------------------------------------------------------------------------------------
// OCM-PLD Pack v3.9 by KdL (2021.06.11) / MSX2+ Stable Release for SM-X and SX-2 / MSXtR Experimental
// Special thanks to t.hara, caro, mygodess & all MRC users (http://www.msx.org)
//-----------------------------------------------------------------------------------------------------
// Setup for XTAL 50.00000MHz
//-----------------------------------------------------------------------------------------------------
// History
//     June/27th/2020
//       Converted to VerilogHDL by t.hara
//
//     July/31th/2020
//       Added step execution by t.hara
//
//     Feburary/25th/2021
//       Removed step execution by t.hara
//

module emsx_top(
		// Clock, Reset ports
		input			clk21m,								// VDP Clock ... 21.48MHz
		input			memclk,
		output			pCpuClk,							// CPU Clock ... 3.58MHz (up to 10.74MHz/21.48MHz)
		output			pW10hz,

		// MSX cartridge slot ports
		output			xSltRst_n,
		input			pSltRst_n,
		inout			pSltSltsl_n,
		inout			pSltSlts2_n,
		inout			pSltIorq_n,
		inout			pSltRd_n,
		inout			pSltWr_n,
		inout	[15:0]	pSltAdr,
		inout	[7:0]	pSltDat,
		output			pSltBdir_n,							// Bus direction (not used in master mode)

		inout			pSltCs1_n,
		inout			pSltCs2_n,
		inout			pSltCs12_n,
		inout			pSltRfsh_n,
		inout			pSltWait_n,
		input			pSltInt_n,
		inout			pSltM1_n,
		inout			pSltMerq_n,

		output			pSltRsv5,							// Reserved
		output			pSltRsv16,							// Reserved (w/ external pull-up)
		inout			pSltSw1,							// Reserved (w/ external pull-up)
		inout			pSltSw2,							// Reserved

		// SD-RAM ports
		output			pMemCke,							// SD-RAM Clock enable
		output			pMemCs_n,							// SD-RAM Chip select
		output			pMemRas_n,							// SD-RAM Row/RAS
		output			pMemCas_n,							// SD-RAM /CAS
		output			pMemWe_n,							// SD-RAM /WE
		output			pMemUdq,							// SD-RAM UDQM
		output			pMemLdq,							// SD-RAM LDQM
		output			pMemBa1,							// SD-RAM Bank select address 1
		output			pMemBa0,							// SD-RAM Bank select address 0
		output	[12:0]	pMemAdr,							// SD-RAM Address
		inout	[15:0]	pMemDat,							// SD-RAM Data

		// PS/2 keyboard ports
		inout			pPs2Clk,
		inout			pPs2Dat,

		// Joystick ports (Port_A, Port_B)
		input	[5:0]	pJoyA_in,
		output	[1:0]	pJoyA_out,
		output			pStrA,
		input	[5:0]	pJoyB_in,
		output	[1:0]	pJoyB_out,
		output			pStrB,

		// SD/MMC slot ports
		output			pSd_Ck,								// pin 5
		output			pSd_Cm,								// pin 2
		inout	[3:0]	pSd_Dt,								// pin 1(D3), 9(D2), 8(D1), 7(D0)

		// MIDI ports                                       // Added by t.hara at 12th/Feb./2020
		output			pMidiTxD,
		input			pMidiRxD,

		// DIP switch, Lamp ports
		input	[9:0]	pDip,								// 0=On, 1=Off (default on shipment)
		output	[8:0]	pLed,								// 0=Off, 1=On (green)
		output			pLedPwr,							// 0=Off, 1=On (red)

		input			p_toggle_sexec_sw,					// toggle switch for Step Execution (0=pressed, 1=unpressed)
		input			p_reserved_sw,						// reserved switch for Step Execution (0=pressed, 1=unpressed)
		input			p_toggle_sw,						// toggle switch
		output	[6:0]	p_7seg_cpu_type,					// CPU type indicator (Z=Z80, r=R800)
		output	[6:0]	p_7seg_address_0,					// PC[ 3: 0] register indicator
		output	[6:0]	p_7seg_address_1,					// PC[ 7: 4] register indicator
		output	[6:0]	p_7seg_address_2,					// PC[11: 8] register indicator
		output	[6:0]	p_7seg_address_3,					// PC[15:12] register indicator
		output	[6:0]	p_7seg_debug,						// debug indicator

		// Video, Audio/CMT ports
		inout	[5:0]	pDac_VR,							// RGB_Red / Svideo_C
		inout	[5:0]	pDac_VG,							// RGB_Grn / Svideo_Y
		inout	[5:0]	pDac_VB,							// RGB_Blu / CompositeVideo

		output			pVideoHS_n,							// Csync(RGB15K), HSync(VGA31K)
		output			pVideoVS_n,							// Audio(RGB15K), VSync(VGA31K)

		output			pVideoClk,							// (Reserved)
		output			pVideoDat,							// (Reserved)

		output			pRemOut,
		output			pCmtOut,
		input			pCmtIn,
		output			pCmtEn,

		output			pDacOut,
		output			pDacLMute,
		output			pDacRInverse,

		// EPCS ports
		output			EPC_CK,
		output			EPC_CS,
		output			EPC_OE,
		output			EPC_DI,
		input			EPC_DO,

		// DE0CV, SM-X, Multicore 2 and SX-2 ports
		output			clk21m_out,
		output			clk_hdmi,
		output			esp_rx_o,
		input			esp_tx_i,
		output	[15:0]	pcm_o,
		output			blank_o,
		input			ear_i,
		output			mic_o,
		output			midi_o,
		output			midi_active_o,
		output			vga_status,
		inout	[1:0]	vga_scanlines,
		output			btn_scan
	);

	localparam		DEBUG_MODE		= 0;			// 1 = enabled, 0 = disabled
	localparam		c_7seg_z	= 7'b0100100;		// 7seg 'Z' : CPU indicator of Z80.
	localparam		c_7seg_r	= 7'b0101111;		// 7seg 'r' : CPU indicator of R800.

	// Switched I/O ports
	wire	[7:0]	swio_dbi;
	wire	[7:0]	io40_n;
	wire	[7:0]	io41_id212_n;										// here to reduce LEs
	wire	[7:0]	io42_id212;
	wire	[7:0]	io43_id212;
	wire			RstKeyLock;
	wire	[7:0]	io44_id212;
	wire	[7:0]	GreenLeds;
	wire	[3:0]	CustomSpeed;
	wire			tMegaSD;
	wire			tPanaRedir;											// here to reduce LEs
	wire			VdpSpeedMode;
	wire			V9938_n;
	wire			Mapper_req;											// here to reduce LEs
	wire			Mapper_ack;
	wire			MegaSD_req;											// here to reduce LEs
	wire			MegaSD_ack;
	wire			io41_id008_n;
	wire			swioKmap;
	reg				ff_CmtScro;
	wire			swioCmt;
	wire			LightsMode;
	wire			Red_sta;
	wire			LastRst_sta;										// here to reduce LEs
	wire			RstReq_sta;											// here to reduce LEs
	wire			Blink_ena;
	wire			pseudoStereo;
	wire			extclk3m;
	wire			right_inverse;
	wire	[7:0]	vram_slot_ids;
	wire	[7:0]	vram_page;
	wire			DefKmap;											// here to reduce LEs
	reg		[9:0]	ff_dip_req = 10'b0010000011;						// overwrites any startup errors with the most common settings
	wire	[7:0]	ff_dip_ack;											// here to reduce LEs
	wire	[2:0]	LevCtrl;
	wire			GreenLvEna;
	wire			swioRESET_n;
	wire			warmRESET;
	wire			WarmMSXlogo;										// here to reduce LEs
	wire			ZemmixNeo;
	wire			JIS2_ena;
	wire			portF4_mode;
	wire	[2:0]	RatioMode;
	wire			centerYJK_R25_n;
	wire			legacy_sel;
	wire			iSlt1_linear;
	wire			iSlt2_linear;
	wire			Slot0_req;											// here to reduce LEs
	wire			Slot0Mode;

	// OCM-Kai Control Device		Added by t.hara in May/11th/2020
	wire	[7:0]	okaictrl_dbi;
	wire			okaictrl_en;
	wire	[4:0]	eseram_memory_id;
	wire			req_reset_primary_slot;
	wire			ack_reset_primary_slot;

	// Expanded I/O Device			Added by t.hara in May/11th/2020
	wire			exp_io_req;

	// S1990
	wire			s1990_req;
	wire	[7:0]	s1990_dbi;
	wire			n_z80_wait;
	wire			n_r800_wait;
	wire			processor_mode;

	wire			z80_M1_n;
	wire			z80_MREQ_n;
	wire			z80_IORQ;
	wire			z80_NoRead;
	wire			z80_write;
	wire			z80_RFSH_n;
	wire			z80_HALT_n;
	wire			z80_BUSAK_n;
	wire	[15:0]	z80_A;
	wire	[15:0]	z80_pc;

	wire			r800_M1_n;
	wire			r800_MREQ_n;
	wire			r800_IORQ;
	wire			r800_NoRead;
	wire			r800_write;
	wire			r800_RFSH_n;
	wire			r800_HALT_n;
	wire			r800_BUSAK_n;
	wire	[15:0]	r800_A;
	wire	[15:0]	r800_pc;

	// Operation mode
	wire			w_key_mode;										// Kana key board layout: 1=JIS layout
	reg				ff_Kmap;											// 1'b0: Japanese-106	1'b1: Non-Japanese (English-101, French, ..)
	reg		[1:0]	ff_DisplayMode = 2'b10;
	reg				ff_Slot1Mode;
	reg		[1:0]	ff_Slot2Mode;
	wire			FullRAM;										// 1'b0: 2048 kB RAM		1'b1: 4096 kB RAM
	wire			MmcMode;										// 1'b0: disable SD/MMC	1'b1: enable SD/MMC

	// Clock, Reset control signals
	wire			cpuclk;
	wire			clkena;
	wire	[1:0]	clkdiv;
	reg				ff_clksel;
	reg				ff_clksel5m_n;
	reg				ff_hybridclk_n;
	reg		[2:0]	ff_hybstartcnt;
	reg		[2:0]	ff_hybtoutcnt;
	wire			reset;
	wire			power_on_reset;
	wire			w_sig10mhz;											// Added by t.hara in May/22th/2020
	wire			w_sig5mhz;											// Added by t.hara in May/22th/2020
	reg		[4:0]	ff_LogoRstCnt	= 5'b11111;
	reg		[1:0]	ff_logo_timeout	= 2'b00;
	wire			trueClk;

	// MSX cartridge slot control signals
	wire			BusDir;
	wire			iSltRfsh_n;
	wire			iSltMerq_n;
	wire			CpuM1_n;
	wire			CpuRfsh_n;
	wire			wait_n_s;

	// Internal bus signals (common)
	wire			req;
	wire			mem;
	wire			wrt;
	wire	[15:0]	adr;
	wire	[7:0]	dbi;
	wire	[7:0]	dbo;

	// Primary, Expansion slot signals
	wire	[7:0]	ExpDbi;
	wire			exp_slot_req;
	wire	[1:0]	PriSltNum;
	wire	[1:0]	ExpSltNum0;
	wire	[1:0]	ExpSltNum3;

	// Slot decode signals
	wire			w_mem_slot0_0;
	wire			w_mem_slot0_1;
	wire			w_mem_slot0_2;
	wire			w_mem_slot0_3;
	wire			w_mem_mapper;
	wire			w_mem_slot1_scc;
	wire			w_mem_slot2_scc;
	wire			w_mem_eseram;
	wire			w_mem_slot1_linear;
	wire			w_mem_slot2_linear;
	wire			w_mem_slot3_1;
	wire			w_mem_panamega;

	// IPL-ROM signals
	wire	[7:0]	RomDbi;
	wire			w_ldbios_n;

	// ESE-RAM signals
	wire			ErmReq;
	wire			ErmRam;
	wire			ErmWrt;
	wire	[19:0]	ErmAdr;

	// SD/MMC signals
	wire			MmcEna;
	wire			MmcAct;
	wire	[7:0]	MmcDbi;

	// Panasonic MegaROM signals
	wire			PanaReq;
	wire			PanaAck;
	wire	[7:0]	PanaDbi;
	wire			PanaRam;
	wire			PanaWrt;
	wire	[24:0]	PanaAdr;
	wire			PanaMegaIsLinear;

	// Mapper RAM signals
	wire			MapReq;
	wire	[7:0]	MapDbi;
	wire			MapRam;
	wire			MapWrt;
	wire	[21:0]	MapAdr;

	// Z80 mode / R800 ROM mode = 1, R800 DRAM mode = 0
	wire			w_rom_mode;

	// PPI(8255) and PS/2 Keyboard signals
	wire			PpiReq;
	wire	[7:0]	PpiDbi;
	wire			Paus;
	wire			Scro;
	wire			Reso;
	reg				Reso_v;
	wire			Kana;
	wire	[7:0]	FKeys;

	// CMT signals
	wire			CmtIn;

	// 1bit sound port signal
	wire			KeyClick;

	// RTC signals
	wire			RtcReq;
	wire	[7:0]	RtcDbi;

	// Kanji signals
	wire			KanReq;
	wire	[7:0]	KanDbi;
	wire			KanRom;
	wire	[17:0]	KanAdr;

	// VDP signals
	reg		[5:0]	ff_pDac_VR;
	reg		[5:0]	ff_pDac_VG;
	reg		[5:0]	ff_pDac_VB;
	reg				ff_pVideoHS_n;
	reg				ff_pVideoVS_n;
	wire			VdpReq;
	wire	[7:0]	VdpDbi;
	wire			VideoSC;
	wire			VideoDLClk;
	wire			VideoDHClk;
	wire			WeVdp_n;
	wire	[16:0]	VdpAdr;
	wire	[7:0]	VrmDbo;
	wire	[15:0]	VrmDbi;
	wire			pVdpInt_n;
	wire			ntsc_pal_type;
	wire			forced_v_mode;
	reg				ff_legacy_vga;

	// Video signals
	wire	[5:0]	VideoR;								// RGB Red
	wire	[5:0]	VideoG;								// RGB Green
	wire	[5:0]	VideoB;								// RGB Blue
	wire			VideoHS_n;							// Horizontal Sync
	wire			VideoVS_n;							// Vertical Sync
	wire			VideoCS_n;							// Composite Sync
	wire	[5:0]	videoY;								// S-Video Y
	wire	[5:0]	videoC;								// S-Video C
	wire	[5:0]	videoV;								// CompositeVideo

	// PSG signals
	wire			PsgReq;
	wire	[7:0]	PsgDbi;
	wire	[7:0]	PsgAmp;

	// SCC signals
	wire			Scc1Req;
	wire			Scc1Ack;
	wire	[7:0]	Scc1Dbi;
	wire			Scc1Ram;
	wire			Scc1Wrt;
	wire	[20:0]	Scc1Adr;
	wire	[14:0]	Scc1AmpL;

	wire			Scc2Req;
	wire			Scc2Ack;
	wire	[7:0]	Scc2Dbi;
	wire			Scc2Ram;
	wire			Scc2Wrt;
	wire	[20:0]	Scc2Adr;
	wire	[14:0]	Scc2AmpL;

	wire	[1:0]	Scc1Type;

	// Opll signals
	wire			OpllReq;
	wire			OpllAck;
	wire	[9:0]	OpllAmp;
	reg				OpllEnaWait;

	// Sound signals
	localparam				DAC_msbi = 13;
	wire	[DAC_msbi:0]	DACin;
	wire					DACout;

	wire	[2:0]			OpllVol;
	wire	[2:0]			SccVol;
	wire	[2:0]			PsgVol;
	wire	[2:0]			MstrVol;

	// External memory signals
	wire			RamReq;
	wire			RamAck;
	wire	[7:0]	RamDbi;
	wire	[17:0]	ClrAdr;
	wire	[24:0]	CpuAdr;				// Extended by t.hara in 19/May/2020

	// SD-RAM control signals
	wire			sync_reset;										// Added by t.hara in 10th/May/2020
	wire			sdram_ready;									// Added by t.hara in 10th/May/2020

	// Clock divider
	wire			PausFlash;
	wire	[1:0]	ff_mem_seq;

	// Operation mode
	wire	[20:0]	freerun_count;				// free run counter
	wire	[6:0]	GreenLv;					// green level
	reg		[1:0]	ff_rst_seq;

	// RTC lfsr counter
	reg		[21:0]	ff_10hz_cnt;
	wire			w_10hz;

	// Sound output, Toggle keys
	wire	[7:0]	vFKeys;
	reg				ff_Scro;
	reg				ff_Reso;

	// DRAM arbiter
	wire			w_wrt_req;

	// SD-RAM controller
	wire	[2:0]	ff_sdr_seq;

	// System flags
	wire			system_flags_req;
	wire	[7:0]	system_flags_dbi;							// Bit7: 1=hard reset, 0=soft reset

	// turboR PCM device										// 2019/11/29 t.hara added
	wire			tr_pcm_req;									// 2019/11/29 t.hara added
	wire	[7:0]	tr_pcm_dbi;									// 2019/11/29 t.hara added
	wire	[7:0]	tr_pcm_wave_in;								// 2019/11/29 t.hara added
	wire	[7:0]	tr_pcm_wave_out;							// 2019/11/29 t.hara added

	// OPL3 signals
	wire	[7:0]	opl3_dout_s;
	wire	[15:0]	opl3_sound_s;
	wire			opl3_req;
	wire			opl3_ce;
	wire	[2:0]	Opl3Vol;
	reg				opl3_enabled;

	// MSX-MIDI ports											// 2020/02/12 t.hara added
	wire			tr_midi_req;
	wire	[7:0]	tr_midi_dbi;
	wire			tr_midi_intr;

	// Autofire,  Added by t.hara, 2021/Aug/6th
	wire			af_on_off_toggle;
	wire			af_increment;
	wire			af_decrement;
	wire			af_mask;
	wire	[3:0]	af_speed;
	wire	[5:0]	w_pJoyA_in;
	wire	[5:0]	w_pJoyB_in;
	wire	[7:0]	w_PpiPortB;

	// Sound output filter
	wire	[DAC_msbi:0]	lpf1_wave;
	wire	[DAC_msbi:0]	lpf5_wave;

	// Interrupt
	wire			w_pSltInt_n;

	wire			w_led_internal_firmware;

	reg		[1:0]	DEBUG_ENA;

	assign RstKeyLock	= io43_id212[5];
	assign GreenLeds	= io44_id212;

	assign FullRAM		= Mapper_ack;
	assign MmcMode		= MegaSD_ack;

	//--------------------------------------------------------------
	// Clock generator (21.48MHz > 3.58MHz)
	// pCpuClk should be independent from reset
	//--------------------------------------------------------------
	clock_generator u_clock_generator (
		.reset			( reset				),
		.power_on_reset	( power_on_reset	),
		.clk21m			( clk21m			),
		.cpuclk			( cpuclk			),
		.trueClk		( trueClk			),
		.pCpuClk		( pCpuClk			),
		.clkena			( clkena			),
		.clkdiv			( clkdiv			),
		.clksel			( ff_clksel			),
		.clksel5m_n		( ff_clksel5m_n		),
		.extclk3m		( extclk3m			)
	);

	assign clk21m_out = clk21m;
	assign vga_status = ff_DisplayMode[1];

	// hybrid clock timeout counter
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_hybstartcnt <= 3'd0;
		end
		else begin
			if( freerun_count[16:0] == 17'd0 ) begin
				if( MmcEna == 1'b0 ) begin
					ff_hybstartcnt <= 3'b111;
				end
				else if( ff_hybstartcnt != 3'b000 ) begin
					ff_hybstartcnt <= ff_hybstartcnt - 3'd1;
				end
			end
		end
	end

	// hybrid clock timeout counter
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_hybtoutcnt <= 3'd0;
		end
		else begin
			if( ff_hybstartcnt == 3'b000 || ff_hybtoutcnt != 3'b000 ) begin
				if( MmcEna == 1'b1 ) begin
					ff_hybtoutcnt <= 3'b111;
				end
				else if( freerun_count[17:0] == 18'd0 ) begin
					ff_hybtoutcnt <= ff_hybtoutcnt - 3'd1;
				end
			end
		end
	end

	// hybrid clock enabler
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_hybridclk_n <= 1'b1;
		end
		else begin
			if( ff_hybtoutcnt == 3'b000 ) begin
				ff_hybridclk_n <= 1'b1;
			end
			else begin
				ff_hybridclk_n <= ~tMegaSD;
			end
		end
	end

	// logo speed limiter
	always @( posedge clk21m ) begin
		if( w_ldbios_n == 1'b0 ) begin
			if( LastRst_sta == portF4_mode ) begin
				ff_LogoRstCnt <= 5'b11111;
				ff_logo_timeout <= 2'b00;
			end
		end
		else if( w_10hz == 1'b1 && ff_LogoRstCnt != 5'b00000 ) begin
			ff_LogoRstCnt <= ff_LogoRstCnt - 5'd1;
			if( ff_LogoRstCnt == 5'b10010 ) begin
				ff_logo_timeout <= 2'b01;
			end
		end
		else if( ff_LogoRstCnt == 5'b00000 ) begin
			ff_logo_timeout <= 2'b10;
		end
	end

	// virtual DIP-SW assignment (1/2)
	always @( negedge clk21m ) begin
		if( cpuclk == 1'b0 && clkdiv == 2'b00 && wait_n_s == 1'b0 ) begin
			if( w_ldbios_n == 1'b0 || ff_logo_timeout == 2'b00 ) begin						// ultra-fast bootstrap
				ff_clksel5m_n	<=	1'b1;
				ff_clksel		<=	1'b1;
			end
			else if( ff_logo_timeout == 2'b10 ) begin
				if( io42_id212[0] == 1'b0 ) begin
					ff_clksel5m_n	<=	io41_id008_n	& ff_hybridclk_n;
					ff_clksel		<=	io42_id212[0]	& ff_hybridclk_n;
				end
				else begin
					ff_clksel5m_n	<=	io41_id008_n;
					ff_clksel		<=	io42_id212[0];
				end
			end
			else begin
				ff_clksel5m_n	<=	1'b1;
				ff_clksel		<=	1'b0;
			end
		end
	end

	// virtual DIP-SW assignment (2/2)
	always @( posedge clk21m ) begin
		ff_Kmap				<=	swioKmap;			// keyboard layout assignment
		ff_CmtScro			<=	swioCmt;
		ff_DisplayMode[1]	<=	io42_id212[1];
		ff_DisplayMode[0]	<=	io42_id212[2];
		ff_Slot1Mode		<=	io42_id212[3];
		ff_Slot2Mode[1]		<=	io42_id212[4];
		ff_Slot2Mode[0]		<=	io42_id212[5];
		opl3_enabled		<=	swioCmt;
	end

	//--------------------------------------------------------------
	// Reset control
	//--------------------------------------------------------------

	reset_controller u_reset_controller (
		.memclk				( memclk			),
		.clk21m				( clk21m			),
		.pulse10hz			( w_10hz			),
		.RstKeyLock			( RstKeyLock		),
		.pSltRst_n			( pSltRst_n			),
		.sdram_ready		( sdram_ready		),
		.swioRESET_n		( swioRESET_n		),
		.reset				( reset				),
		.xSltRst_n			( xSltRst_n			),
		.sync_reset			( sync_reset		),
		.sig10mhz			( w_sig10mhz		),
		.sig5mhz			( w_sig5mhz			),
		.power_on_reset		( power_on_reset	)
	);

	//--------------------------------------------------------------
	// Operation mode
	//--------------------------------------------------------------

	// FreeRun Counter
	freerun_counter u_freerun_counter (
		.reset				( reset				),
		.clk21m				( clk21m			),
		.freerun_count		( freerun_count		)
	);

	assign w_10hz		=	( ff_10hz_cnt == 22'd0 ) ? 1'b1 : 1'b0;

	assign pW10hz		=	w_10hz;

	always @( posedge clk21m ) begin
		if( w_10hz == 1'b1 ) begin
			ff_10hz_cnt <= 22'd2147726;
		end
		else begin
			ff_10hz_cnt <= ff_10hz_cnt - 22'd1;
		end
	end

	// flash counter
	indicator u_indicator (
		.reset				( reset				),
		.clk21m				( clk21m			),
		.Paus				( Paus				),
		.ff_clksel5m_n		( ff_clksel5m_n		),
		.w_10hz				( w_10hz			),
		.GreenLvEna			( GreenLvEna		),
		.ZemmixNeo			( ZemmixNeo			),
		.PausFlash			( PausFlash			),
		.freerun_count		( freerun_count		),
		.debug_mode			( 2'b00				),
		.break_point		( 8'b00000000		),
		.GreenLeds			( GreenLeds			),
		.Blink_ena			( Blink_ena			),
		.MmcEna				( MmcEna			),
		.MmcMode			( MmcMode			),
		.LightsMode			( LightsMode		),
		.LevCtrl			( LevCtrl			),
		.io42_id212			( io42_id212		),
		.DisplayMode		( ff_DisplayMode	),
		.Slot1Mode			( ff_Slot1Mode		),
		.Slot2Mode			( ff_Slot2Mode		),
		.FullRAM			( FullRAM			),
		.Red_sta			( Red_sta			),
		.w_sig5mhz			( w_sig5mhz			),
		.w_sig10mhz			( w_sig10mhz		),
		.pSltRst_n			( pSltRst_n			),
		.RstKeyLock			( RstKeyLock		),
		.pLed				( pLed[7:0]			),
		.pLedPwr			( pLedPwr			)
	);

	// reset enable wait counter
	//
	//	ff_rst_seq(0)	X___X~~~X~~~X___X___X ...
	//	ff_rst_seq(1)	X___X___X~~~X~~~X___X ...
	//
	always @( posedge reset or posedge clk21m ) begin
		if( reset == 1'b1 ) begin
			ff_rst_seq <= 2'b00;
		end
		else begin
			if( w_10hz == 1'b1 ) begin
				ff_rst_seq <= { ff_rst_seq[0], (~ff_rst_seq[1]) };
			end
			else begin
				//	hold
			end
		end
	end

	// DIP-SW latch
	always @( posedge clk21m ) begin
		ff_dip_req <= ~pDip;						// convert negative logic to positive logic, and latch
	end

	// Kana keyboard layout: 1=JIS layout
	assign w_key_mode	=	1'b1;

	//--------------------------------------------------------------
	// MSX cartridge slot control
	//--------------------------------------------------------------
	assign pSltCs1_n	=	( pSltAdr[15:14] == 2'b01 ) ? pSltRd_n : 1'b1;
	assign pSltCs2_n	=	( pSltAdr[15:14] == 2'b10 ) ? pSltRd_n : 1'b1;
	assign pSltCs12_n	=	( pSltAdr[15:14] == 2'b01 ) ? pSltRd_n :
							( pSltAdr[15:14] == 2'b10 ) ? pSltRd_n : 1'b1;
	assign pSltM1_n		=	CpuM1_n;
	assign pSltRfsh_n	=	CpuRfsh_n;

	assign w_pSltInt_n	=	pSltInt_n & pVdpInt_n & tr_midi_intr;

	assign pSltSltsl_n	=	( Scc1Type != 2'b00 ) ? 1'b1 :
							( pSltMerq_n == 1'b0 && CpuRfsh_n == 1'b1 && PriSltNum == 2'b01 ) ? 1'b0 :
							1'b1;

	assign pSltSlts2_n	=	( ff_Slot2Mode != 2'b00 ) ? 1'b1 :
							( pSltMerq_n == 1'b0 && CpuRfsh_n == 1'b1 && PriSltNum == 2'b10 ) ? 1'b0 :
							1'b1;

	assign pSltBdir_n	=	1'bz;

	assign pSltDat		=	( pSltRd_n == 1'b1 ) ? 8'dz :
							( pSltIorq_n == 1'b0 && BusDir    == 1'b1  ) ? dbi :
							( pSltMerq_n == 1'b0 && PriSltNum == 2'b00 ) ? dbi :
							( pSltMerq_n == 1'b0 && PriSltNum == 2'b11 ) ? dbi :
							( pSltMerq_n == 1'b0 && PriSltNum == 2'b01 && Scc1Type  != 2'b00 ) ? dbi :
							( pSltMerq_n == 1'b0 && PriSltNum == 2'b10 && ff_Slot2Mode != 2'b00 ) ? dbi :
							8'dz;

	assign pSltRsv5		= 1'bz;
	assign pSltRsv16	= ( ~reset ) & power_on_reset;			// can perform RESET_n lock on Cyclone I machine slot pins by applying a hardware patch
	assign pSltSw1		= 1'bz;
	assign pSltSw2		= 1'bz;

	//--------------------------------------------------------------
	// PPI(8255) / primary-slot, keyboard, 1bit sound port
	//--------------------------------------------------------------
	wire	[15:0]		w_debug_sig;

	ppi u_ppi (
		.reset					( reset					),
		.clk21m					( clk21m				),
		.clkena					( clkena				),
		.req					( PpiReq				),
		.exp_slot_req			( exp_slot_req			),
		.wrt					( wrt					),
		.adr					( adr					),
		.dbo					( dbo					),
		.dbi					( PpiDbi				),
		.slot0_expanded			( Slot0Mode				),
		.pPs2Clk				( pPs2Clk				),
		.pPs2Dat				( pPs2Dat				),
		.PriSltNum				( PriSltNum				),
		.ExpSltNum0				( ExpSltNum0			),
		.ExpSltNum3				( ExpSltNum3			),
		.ExpDbi					( ExpDbi				),
		.RemOut					( pRemOut				),
		.CmtOut					( pCmtOut				),
		.CmtScro				( ff_CmtScro			),
		.KeyClick				( KeyClick				),
		.Kmap					( ff_Kmap				),
		.Kana					( Kana					),
		.Paus					( Paus					),
		.Scro					( Scro					),
		.Reso					( Reso					),
		.Fkeys					( FKeys					),
		.autofire				( af_mask				)
//		.debug_sig				( w_debug_sig			)
	);

	assign exp_slot_req		= req & ~iSltMerq_n;

	ocm_bus_selector u_ocm_bus_selector (
		.reset					( reset					),
		.clk21m					( clk21m				),
		.trueClk				( trueClk				),
		.ff_clksel				( ff_clksel				),
		.ff_clksel5m_n			( ff_clksel5m_n			),
		.CpuM1_n				( CpuM1_n				),
		.wait_n_s				( wait_n_s				),
		.CustomSpeed			( CustomSpeed			),
		.req					( req					),
		.mem					( mem					),
		.wrt					( wrt					),
		.adr					( adr					),
		.dbo					( dbo					),
		.dbi					( dbi					),
		.eseram_memory_id		( eseram_memory_id		),
		.Scc1Adr				( Scc1Adr				),
		.Scc2Adr				( Scc2Adr				),
		.MapAdr					( MapAdr				),
		.KanAdr					( KanAdr				),
		.ErmAdr					( ErmAdr				),
		.PanaAdr				( PanaAdr				),
		.pSltIorq_n				( pSltIorq_n			),
		.pSltRd_n				( pSltRd_n				),
		.pSltWr_n				( pSltWr_n				),
		.pSltAdr				( pSltAdr				),
		.pSltDat				( pSltDat				),
		.pSltRfsh_n				( pSltRfsh_n			),
		.pSltMerq_n				( pSltMerq_n			),
		.pSltWait_n				( pSltWait_n			),
		.PriSltNum				( PriSltNum				),
		.ExpSltNum0				( ExpSltNum0			),
		.ExpSltNum3				( ExpSltNum3			),
		.io40_n					( io40_n				),
		.okaictrl_en			( okaictrl_en			),
		.JIS2_ena				( JIS2_ena				),
		.MmcEna					( MmcEna				),
		.MmcAct					( MmcAct				),
		.portF4_mode			( portF4_mode			),
		.FullRAM				( FullRAM				),
		.BusDir					( BusDir				),
		.iSltRfsh_n				( iSltRfsh_n			),
		.iSltMerq_n				( iSltMerq_n			),
		.CpuAdr					( CpuAdr				),
		.ExpDbi					( ExpDbi				),
		.RomDbi					( RomDbi				),
		.MmcDbi					( MmcDbi				),
		.VdpDbi					( VdpDbi				),
		.PsgDbi					( PsgDbi				),
		.PpiDbi					( PpiDbi				),
		.KanDbi					( KanDbi				),
		.PanaDbi				( PanaDbi				),
		.MapDbi					( MapDbi				),
		.RtcDbi					( RtcDbi				),
		.s1990_dbi				( s1990_dbi				),
		.tr_pcm_dbi				( tr_pcm_dbi			),
		.tr_midi_dbi			( tr_midi_dbi			),
		.swio_dbi				( swio_dbi				),
		.okaictrl_dbi			( okaictrl_dbi			),
		.system_flags_dbi		( system_flags_dbi		),
		.Scc1Dbi				( Scc1Dbi				),
		.Scc2Dbi				( Scc2Dbi				),
		.RamDbi					( RamDbi				),
		.Opl3Dbi				( opl3_dout_s			),
		.RamAck					( RamAck				),
		.Scc1Ack				( Scc1Ack				),
		.Scc2Ack				( Scc2Ack				),
		.PanaAck				( PanaAck				),
		.OpllAck				( OpllAck				),
		.ldbios_n				( w_ldbios_n			),
		.iSlt1_linear			( iSlt1_linear			),
		.iSlt2_linear			( iSlt2_linear			),
		.MmcMode				( MmcMode				),
		.Slot0Mode				( Slot0Mode				),
		.Slot1Mode				( Scc1Type				),
		.Slot2Mode				( ff_Slot2Mode			),
		.rom_mode				( w_rom_mode			),
		.opl3_enabled			( opl3_enabled			),
		.mem_slot0_0			( w_mem_slot0_0			),
		.mem_slot0_1			( w_mem_slot0_1			),
		.mem_slot0_2			( w_mem_slot0_2			),
		.mem_slot0_3			( w_mem_slot0_3			),
		.mem_slot1_scc			( w_mem_slot1_scc		),
		.mem_slot1_linear		( w_mem_slot1_linear	),
		.mem_slot2_scc			( w_mem_slot2_scc		),
		.mem_slot2_linear		( w_mem_slot2_linear	),
		.mem_mapper				( w_mem_mapper			),
		.mem_slot3_1			( w_mem_slot3_1			),
		.mem_eseram				( w_mem_eseram			),
		.mem_panamega			( w_mem_panamega		),
		.Scc1Ram				( Scc1Ram				),
		.Scc2Ram				( Scc2Ram				),
		.ErmRam					( ErmRam				),
		.PanaRam				( PanaRam				),
		.MapRam					( MapRam				),
		.KanRom					( KanRom				),
		.RamReq					( RamReq				),
		.OpllReq				( OpllReq				),
		.VdpReq					( VdpReq				),
		.PsgReq					( PsgReq				),
		.PpiReq					( PpiReq				),
		.KanReq					( KanReq				),
		.MapReq					( MapReq				),
		.Scc1Req				( Scc1Req				),
		.Scc2Req				( Scc2Req				),
		.ErmReq					( ErmReq				),
		.PanaReq				( PanaReq				),
		.RtcReq					( RtcReq				),
		.s1990_req				( s1990_req				),
		.exp_io_req				( exp_io_req			),
		.system_flags_req		( system_flags_req		),
		.tr_pcm_req				( tr_pcm_req			),
		.tr_midi_req			( tr_midi_req			),
		.opl3_req				( opl3_req				),
		.req_reset_primary_slot	( req_reset_primary_slot),
		.ack_reset_primary_slot	( ack_reset_primary_slot)
	);

	//--------------------------------------------------------------
	// Video output
	//--------------------------------------------------------------
//	assign V9938_n		= 1'b0;			// 1'b0 is V9938 MSX2 VDP
	assign V9938_n		= 1'b1;			// 1'b1 is V9958 MSX2+/tR VDP

	assign pDac_VR		= ff_pDac_VR;
	assign pDac_VG		= ff_pDac_VG;
	assign pDac_VB		= ff_pDac_VB;
	assign pVideoHS_n	= ff_pVideoHS_n;
	assign pVideoVS_n	= ff_pVideoVS_n;

	always @( posedge clk21m ) begin
		case( ff_DisplayMode )
		2'b00:														// TV 15KHz
			begin
				ff_pDac_VR		<= videoC;							// Luminance of S-Video Out
				ff_pDac_VG		<= videoY;							// Chrominance of S-Video Out
				ff_pDac_VB		<= videoV;							// Composite Video Out
				Reso_v			<= 1'b0;							// Hsync:15kHz
				ff_pVideoHS_n	<= 1'bz;							// CSync Disabled
				ff_pVideoVS_n	<= DACout;							// Audio Out (Mono)
//				ff_legacy_vga	<= 1'b0;							// behaves like vAllow_n		(for V9938 MSX2 VDP)
			end
		2'b01:														// RGB 15kHz
			begin
				ff_pDac_VR		<= VideoR;
				ff_pDac_VG		<= VideoG;
				ff_pDac_VB		<= VideoB;
				Reso_v			<= 1'b0;							// Hsync:15kHz
				ff_pVideoHS_n	<= VideoCS_n;						// CSync Enabled
				ff_pVideoVS_n	<= DACout;							// Audio Out (Mono)
//				ff_legacy_vga	<= 1'b0;							// behaves like vAllow_n		(for V9938 MSX2 VDP)
			end
		default:
			begin													// VGA / VGA+ 31kHz
				ff_pDac_VR		<= VideoR;
				ff_pDac_VG		<= VideoG;
				ff_pDac_VB		<= VideoB;
				Reso_v			<= 1'b1;							// Hsync:31kHz
				ff_pVideoHS_n	<= VideoHS_n;
				ff_pVideoVS_n	<= VideoVS_n;
//				ff_legacy_vga	<= ~ff_DisplayMode[0];				// behaves like vAllow_n		(for V9938 MSX2 VDP)
				if( !legacy_sel ) begin								// Assignment of Legacy Output	(for V9958 MSX2+/tR VDP)
					ff_legacy_vga	<= ~ff_DisplayMode[0];			// to VGA
				end
				else begin
					ff_legacy_vga	<= ff_DisplayMode[0];			// to VGA+
				end
			end
		endcase
	end

	// PRNSCR key
	always @( posedge clk21m ) begin
		ff_Reso <= Reso;
	end

	assign pVideoClk	= 1'bz;
	assign pVideoDat	= 1'bz;

	//--------------------------------------------------------------
	// Sound output
	//--------------------------------------------------------------
	sound_mixer #(
		.c_DAC_msbi			( DAC_msbi			),
		.c_opllamp_range	( 10				)
	) u_sound_mixer (
		.clk21m				( clk21m			),
		.Fkeys				( FKeys				),
		.vFkeys				( vFKeys			),
		.PsgAmp				( PsgAmp			),
		.OpllAmp			( OpllAmp			),
		.Scc1Amp			( Scc1AmpL			),
		.Scc2Amp			( Scc2AmpL			),
		.Opl3Amp			( opl3_sound_s		),
		.tr_pcm_wave_out	( tr_pcm_wave_out	),
		.OpllVol			( OpllVol			),
		.SccVol				( SccVol			),
		.PsgVol				( PsgVol			),
		.Opl3Vol			( Opl3Vol			),
		.MstrVol			( MstrVol			),
		.KeyClick			( KeyClick			),
		.DACin				( DACin				)
	);

	assign Opl3Vol		= ~{ 3 {opl3_enabled} } | MstrVol;

	assign pDacOut		= DACout;
	assign pDacLMute	= ( pseudoStereo == 1'b1 && ff_CmtScro == 1'b0 ) ? 1'b1 : 1'b0;
	assign pDacRInverse	= right_inverse;

	// Cassette Magnetic Tape (CMT) interface
	assign CmtIn		= pCmtIn;
	assign pCmtEn		= ( ff_CmtScro == 1'b1 && portF4_mode == 1'b0 ) ? 1'b1 : 1'b0;

	// SCRLK key
	always @( posedge clk21m ) 	begin
		ff_Scro		<= Scro;
	end

	//--------------------------------------------------------------
	// SD-RAM access
	//--------------------------------------------------------------
	emsx_sdram_controller u_sdram_control (
		.reset					( reset						),
		.sync_reset				( sync_reset				),
		.mem_clk				( memclk					),
		.clk21m					( clk21m					),
		.iSltRfsh_n				( iSltRfsh_n				),
		.vram_slot_ids			( vram_slot_ids				),
		.sdram_ready			( sdram_ready				),
		.mem_vdp_dh_clk			( VideoDHClk				),
		.mem_vdp_dl_clk			( VideoDLClk				),
		.mem_vdp_address		( { 8'b11111000, VdpAdr }	),		// bit19-17 must be set "000"
		.mem_vdp_write			( ~WeVdp_n					),
		.mem_vdp_write_data		( VrmDbo					),
		.mem_vdp_read_data		( VrmDbi					),
		.mem_req				( RamReq					),
		.mem_ack				( RamAck					),
		.mem_cpu_address		( CpuAdr					),
		.mem_cpu_write			( w_wrt_req					),
		.mem_cpu_write_data		( dbo						),
		.mem_cpu_read_data		( RamDbi					),
		.pMemCke				( pMemCke					),
		.pMemCs_n				( pMemCs_n					),
		.pMemRas_n				( pMemRas_n					),
		.pMemCas_n				( pMemCas_n					),
		.pMemWe_n				( pMemWe_n					),
		.pMemUdq				( pMemUdq					),
		.pMemLdq				( pMemLdq					),
		.pMemBa1				( pMemBa1					),
		.pMemBa0				( pMemBa0					),
		.pMemAdr				( pMemAdr					),
		.pMemDat				( pMemDat					)
	);

	assign w_wrt_req	=	( Scc1Wrt & w_mem_slot1_scc ) |
							( Scc2Wrt & w_mem_slot2_scc ) |
							( ErmWrt  & w_mem_eseram    ) |
							( MapWrt  & w_mem_mapper    ) |
							( PanaWrt & w_mem_panamega  );

	//--------------------------------------------------------------
	// Connect components
	//--------------------------------------------------------------
	assign CpuM1_n		= ( processor_mode ) ? z80_M1_n   : r800_M1_n;
	assign pSltMerq_n	= ( processor_mode ) ? z80_MREQ_n : r800_MREQ_n;
	assign pSltIorq_n	= ( processor_mode ) ? z80_IORQ   : r800_IORQ;
	assign pSltRd_n		= ( processor_mode ) ? z80_NoRead : r800_NoRead;
	assign pSltWr_n		= ( processor_mode ) ? z80_write  : r800_write;
	assign CpuRfsh_n	= ( processor_mode ) ? z80_RFSH_n : r800_RFSH_n;
	assign pSltAdr		= ( processor_mode ) ? z80_A      : r800_A;
	assign pLed[8]		= ~processor_mode;

	t80a u_z80 (
		.RESET_n		( (pSltRst_n | RstKeyLock) & swioRESET_n ),
		.R800_mode		( portF4_mode				),
		.CLK_n			( trueClk					),
		.WAIT_n			( wait_n_s					),
		.INT_n			( w_pSltInt_n				),
		.NMI_n			( 1'b1						),
		.BUSRQ_n		( n_z80_wait				),
		.M1_n			( z80_M1_n					),
		.MREQ_n			( z80_MREQ_n				),
		.IORQ_n			( z80_IORQ					),
		.RD_n			( z80_NoRead				),
		.WR_n			( z80_write					),
		.RFSH_n			( z80_RFSH_n				),
		.HALT_n			( 							),
		.BUSAK_n		( z80_BUSAK_n				),
		.A				( z80_A						),
		.D				( pSltDat					),
		.p_PC			( z80_pc					)
	);

	t800a u_r800 (
		.RESET_n		( (pSltRst_n | RstKeyLock) & swioRESET_n ),
		.R800_mode		( 1'b1						),
		.CLK_n			( trueClk					),
		.WAIT_n			( wait_n_s					),
		.INT_n			( w_pSltInt_n				),
		.NMI_n			( 1'b1						),
		.BUSRQ_n		( n_r800_wait				),
		.M1_n			( r800_M1_n					),
		.MREQ_n			( r800_MREQ_n				),
		.IORQ_n			( r800_IORQ					),
		.RD_n			( r800_NoRead				),
		.WR_n			( r800_write				),
		.RFSH_n			( r800_RFSH_n				),
		.HALT_n			( 							),
		.BUSAK_n		( r800_BUSAK_n				),
		.A				( r800_A					),
		.D				( pSltDat					),
		.p_PC			( r800_pc					)
	);

	iplrom u_iplrom (
		.clk				( clk21m				), 
		.adr				( adr					),
		.dbi				( RomDbi				)
	);

	wire	[7:0]		megasd_debug;
	megasd u_megasd (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.req				( ErmReq				),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbo				( dbo					),
		.ramreq				( ErmRam				),
		.ramwrt				( ErmWrt				),
		.ramadr				( ErmAdr				),
		.mmcdbi				( MmcDbi				),
		.mmcena				( MmcEna				),
		.mmcact				( MmcAct				),
		.mmc_ck				( pSd_Ck				),
		.mmc_cs				( pSd_Dt[3]				),
		.mmc_di				( pSd_Cm				),
		.mmc_do				( pSd_Dt[0]				),
		.epc_ck				( EPC_CK				),
		.epc_cs				( EPC_CS				),
		.epc_oe				( EPC_OE				),
		.epc_di				( EPC_DI				),
		.epc_do				( EPC_DO				),
		.debug				( megasd_debug			)
	);

	assign pSd_Dt[2:0]	= 3'bzzz;

	megarom_pana u_megarom_pana (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.clkena				( clkena				),
		.req				( PanaReq				),
		.ack				( PanaAck				),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbi				( PanaDbi				),
		.dbo				( dbo					),
		.is_linear_rom		( PanaMegaIsLinear		),
		.ramreq				( PanaRam				),
		.ramwrt				( PanaWrt				),
		.ramadr				( PanaAdr				),
		.ramdbi				( RamDbi				),
		.ramdbo				( 						)
	);

//	megaram u_megaram_for_slot3_3 (
//		.clk21m				( clk21m				),
//		.reset				( reset					),
//		.clkena				( clkena				),
//		.req				( PanaReq				),
//		.ack				( PanaAck				),
//		.wrt				( wrt					),
//		.adr				( adr					),
//		.dbi				( PanaDbi				),
//		.dbo				( dbo					),
//		.ramreq				( PanaRam				),
//		.ramwrt				( PanaWrt				),
//		.ramadr				( PanaAdr[20:0]			),
//		.ramdbi				( RamDbi				),
//		.ramdbo				( 						),
//		.mapsel				( 2'b10					),
//		.wavl				( 						),
//		.wavr				( 						)
//	);
//	assign PanaAdr[21] = 1'b0;

	mapper u_mapper_ram_for_slot3_0 (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.clkena				( clkena				),
		.req				( MapReq				),
		.ack				( 						),
		.mem				( mem					),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbi				( MapDbi				),
		.dbo				( dbo					),
		.ramreq				( MapRam				),
		.ramwrt				( MapWrt				),
		.ramadr				( MapAdr				),
		.ramdbi				( RamDbi				),
		.ramdbo				( 						)
	);

	rtc u_real_time_clock (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.clkena				( clkena				),
		.req				( RtcReq				),
		.ack				( 						),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbi				( RtcDbi				),
		.dbo				( dbo					)
	);

	kanji u_kanji_rom (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.clkena				( clkena				),
		.req				( KanReq				),
		.ack				( 						),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbi				( KanDbi				),
		.dbo				( dbo					),
		.ramreq				( KanRom				),
		.ramadr				( KanAdr				),
		.ramdbi				( RamDbi				),
		.ramdbo				( 						)
	);

//	vdp u_v9958 (
//		.clk21m				( clk21m							),
//		.reset				( reset								),
//		.req				( VdpReq							),
//		.ack				( 									),
//		.wrt				( wrt								),
//		.adr				( adr								),
//		.dbi				( VdpDbi							),
//		.dbo				( dbo								),
//		.int_n				( pVdpInt_n							),
//		.pRamOe_n			( 									),
//		.pRamWe_n			( WeVdp_n							),
//		.pRamAdr			( VdpAdr							),
//		.pRamDbi			( VrmDbi							),
//		.pRamDbo			( VrmDbo							),
//		.VdpSpeedMode		( VdpSpeedMode | ~ff_hybridclk_n	),	// for V9958 MSX2+/tR VDP
//		.RatioMode			( RatioMode							),	// for V9958 MSX2+/tR VDP
//		.centerYJK_R25_n 	( centerYJK_R25_n					),	// for V9958 MSX2+/tR VDP
//		.pVideo_H_CNT		( 									),	// DEBUG by t.hara
//		.pVideo_V_CNT		( 									),	// DEBUG by t.hara
//		.pVideoR			( VideoR							),
//		.pVideoG			( VideoG							),
//		.pVideoB			( VideoB							),
//		.pVideoHS_n			( VideoHS_n							),
//		.pVideoVS_n			( VideoVS_n							),
//		.pVideoCS_n			( VideoCS_n							),
//		.pVideoDHClk		( VideoDHClk						),
//		.pVideoDLClk		( VideoDLClk						),
////		.pVideoSC			( 									),
////		.pVideoSYNC			( 									),
//		.DispReso			( Reso_v							),
//		.ntsc_pal_type		( ntsc_pal_type						),
//		.forced_v_mode		( forced_v_mode						),
//		.legacy_vga			( ff_legacy_vga						)
//	);

	//	VDP instance for OCM-PLD 3.8.1 version
	VDP u_v9958 (
		.CLK21M				( clk21m							),
		.RESET				( reset								),
		.REQ				( VdpReq							),
		.ACK				( 									),
		.WRT				( wrt								),
		.ADR				( adr								),
		.DBI				( VdpDbi							),
		.DBO				( dbo								),
		.INT_N				( pVdpInt_n							),
		.PRAMOE_N			( 									),
		.PRAMWE_N			( WeVdp_n							),
		.PRAMADR			( VdpAdr							),
		.PRAMDBI			( VrmDbi							),
		.PRAMDBO			( VrmDbo							),
		.VDPSPEEDMODE		( VdpSpeedMode | ~ff_hybridclk_n	),	// for V9958 MSX2+/tR VDP
		.RATIOMODE			( RatioMode							),	// for V9958 MSX2+/tR VDP
		.CENTERYJK_R25_N 	( centerYJK_R25_n					),	// for V9958 MSX2+/tR VDP
		.PVIDEOR			( VideoR							),
		.PVIDEOG			( VideoG							),
		.PVIDEOB			( VideoB							),
		.PVIDEOHS_N			( VideoHS_n							),
		.PVIDEOVS_N			( VideoVS_n							),
		.PVIDEOCS_N			( VideoCS_n							),
		.PVIDEODHCLK		( VideoDHClk						),
		.PVIDEODLCLK		( VideoDLClk						),
		.BLANK_o			( blank_o							),
		.DISPRESO			( Reso_v							),
		.NTSC_PAL_TYPE		( ntsc_pal_type						),
		.FORCED_V_MODE		( forced_v_mode						),
		.LEGACY_VGA			( ff_legacy_vga						)
	);

	vencode u_video_encoder (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.videoR				( VideoR				),
		.videoG				( VideoG				),
		.videoB				( VideoB				),
		.videoHS_n			( VideoHS_n				),
		.videoVS_n			( VideoVS_n				),
		.videoY				( videoY				),
		.videoC				( videoC				),
		.videoV				( videoV				)
	);

	psg u_psg (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.clkena				( clkena				),
		.req				( PsgReq				),
		.ack				( 						),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbi				( PsgDbi				),
		.dbo				( dbo					),
		.joya_in			( w_pJoyA_in			),
		.joya_out			( pJoyA_out				),
		.stra				( pStrA					),
		.joyb_in			( w_pJoyB_in			),
		.joyb_out			( pJoyB_out				),
		.strb				( pStrB					),
		.kana				( Kana					),
		.cmtin				( CmtIn					),
		.keymode			( w_key_mode			),
		.wave				( PsgAmp				)
	);

	megaram u_megaram_for_slot1 (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.clkena				( clkena				),
		.req				( Scc1Req				),
		.ack				( Scc1Ack				),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbi				( Scc1Dbi				),
		.dbo				( dbo					),
		.ramreq				( Scc1Ram				),
		.ramwrt				( Scc1Wrt				),
		.ramadr				( Scc1Adr				),
		.ramdbi				( RamDbi				),
		.ramdbo				( 						),
		.mapsel				( Scc1Type				),
		.wavl				( Scc1AmpL				),
		.wavr				( 						)
	);

	assign Scc1Type		= { ff_Slot1Mode, 1'b0 };

	megaram u_megaram_for_slot2 (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.clkena				( clkena				),
		.req				( Scc2Req				),
		.ack				( Scc2Ack				),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbi				( Scc2Dbi				),
		.dbo				( dbo					),
		.ramreq				( Scc2Ram				),
		.ramwrt				( Scc2Wrt				),
		.ramadr				( Scc2Adr				),
		.ramdbi				( RamDbi				),
		.ramdbo				( 						),
		.mapsel				( ff_Slot2Mode			),
		.wavl				( Scc2AmpL				),
		.wavr				( 						)
	);

	eseopll u_eseopll (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.clkena				( clkena				),
		.enawait			( OpllEnaWait			),
		.req				( OpllReq				),
		.ack				( OpllAck				),
		.wrt				( wrt					),
		.adr				( adr					),
		.dbo				( dbo					),
		.wav				( OpllAmp				)
	);

	// OPLL wait enabler
	always @( posedge clk21m ) begin
		OpllEnaWait <= ~(ff_clksel ^ ff_clksel5m_n);
	end

	interpo #(
		.msbi				( DAC_msbi			)
	) u_interpo (
		.clk21m				( clk21m			),
		.reset				( reset				),
		.clkena				( clkena			),
		.idata				( DACin				),
		.odata				( lpf1_wave			)
	);

	lpf2 #(
		.msbi				( DAC_msbi			)
	) u_lpf2 (
		.clk21m				( clk21m			),
		.reset				( reset				),
		.clkena				( clkena			),
		.idata				( lpf1_wave			),
		.odata				( lpf5_wave			)
	);

	esepwm #(
		.msbi				( DAC_msbi			)
	) u_esepwm (
		.clk				( clk21m			), 
		.reset				( reset				), 
		.DACin				( lpf5_wave			), 
		.DACout				( DACout			)
	);

	// HDMI sound output
	assign pcm_o = { 2'b00, lpf5_wave };

	tr_pcm u_tr_pcm (		// 2019/11/29 t.hara added
		.clk21m				( clk21m				),
		.reset				( reset					),
		.req				( tr_pcm_req			),
		.ack				( 						),
		.wrt				( wrt					),
		.adr				( adr[0]				),
		.dbi				( tr_pcm_dbi			),
		.dbo				( dbo					),
		.wave_in			( tr_pcm_wave_in		),
		.wave_out			( tr_pcm_wave_out		)
	);

	assign tr_pcm_wave_in	= 8'd0;

	wifi u_wifi (
		.clk_i				( clk21m				),
		.wait_o				( esp_wait_s			),
		.reset_i			( xSltRst_n				),			 // swioRESET_n was purposely excluded here
		.iorq_i				( pSltIorq_n			),
		.wrt_i				( pSltWr_n				),
		.rd_i				( pSltRd_n				),
		.tx_i				( esp_tx_i				),
		.rx_o				( esp_rx_o				),
		.adr_i				( adr					),
		.db_i				( dbo					),
		.db_o				( esp_dout_s			)
	);

	tr_midi #(
		.c_base_clk			( 2147727			)	// clk21m is 21.47727MHz
	) u_tr_midi (
		.clk21m				( clk21m			),
		.reset				( reset				),
		.req				( tr_midi_req		),
		.ack				( 					),
		.wrt				( wrt				),
		.adr				( adr[2:0]			),
		.dbi				( tr_midi_dbi		),
		.dbo				( dbo				),
		.pMidiTxD			( pMidiTxD			),
		.pMidiRxD			( pMidiRxD			),
		.pMidiIntr			( tr_midi_intr		)
	);

//	opl3 #(
//		.OPLCLK				( 86000000			)	//	opl_clk in Hz
//	) u_opl3 (
//		.clk				( clk21m			),
//		.clk_opl			( memclk			),	//	86MHz
//		.rst_n				( ~reset			),
//		.irq_n				(					),
//		.addr				( adr[1:0]			),	// OPL and OPL2 uses adr(0) only
//		.dout				( opl3_dout_s		),
//		.din				( dbo				),
//		.we					( opl3_ce			),
//		.sample_l			( opl3_sound_s		),
//		.sample_r			(					)
//	);
//	assign opl3_ce	= opl3_req & ~pSltWr_n;
	assign opl3_sound_s = 'd0;
	assign opl3_dout_s = 'd0;

	s1990 u_s1990 (
		.clk21m					( clk21m					),
		.reset					( reset						),
		.mem					( mem						),
		.wrt					( wrt						),
		.req					( s1990_req					),
		.ack					( 							),
		.adr					( adr						),
		.dbi					( s1990_dbi					),
		.dbo					( dbo						),
		.n_z80_m1				( z80_M1_n					),
		.n_r800_m1				( r800_M1_n					),
		.n_z80_ioreq			( z80_IORQ					),
		.n_r800_ioreq			( r800_IORQ					),
		.n_z80_busack			( z80_BUSAK_n				),
		.n_r800_busack			( r800_BUSAK_n				),
		.n_z80_write			( z80_write					),
		.n_r800_write			( r800_write				),
		.n_z80_wait				( n_z80_wait				),
		.n_r800_wait			( n_r800_wait				),
		.processor_mode			( processor_mode			),
		.rom_mode				( w_rom_mode				),
		.sw_internal_firmware	( ff_dip_req[9]				),
		.led_internal_firmware	( w_led_internal_firmware	)
	);

	// Added by t.hara, 2021/Aug/6th
	autofire u_autofire (
		.clk21m				( clk21m				),
		.reset				( reset					),
		.count_en			( freerun_count[18]		),
		.af_on_off_toggle	( af_on_off_toggle		),
		.af_increment		( af_increment			),
		.af_decrement		( af_decrement			),
		.af_mask			( af_mask				),
		.af_speed			( af_speed				)
	);

	// | b7	 | b6	| b5   | b4	  | b3	| b2  | b1	| b0  |
	// | SHI | CTRL | PgUp | PgDn | F9	| F10 | F11 | F12 |
	assign af_on_off_toggle	=   vFKeys[7]  & vFKeys[6] & ( (vFKeys[5] ^ FKeys[5]) | (vFKeys[4] ^ FKeys[4]) );
	assign af_increment		= (~vFKeys[7]) & vFKeys[6] & (vFKeys[5] ^ FKeys[5]);
	assign af_decrement		= (~vFKeys[7]) & vFKeys[6] & (vFKeys[4] ^ FKeys[4]);

	// Joypad autofire
	assign w_pJoyA_in = { pJoyA_in[5], (pJoyA_in[4] | af_mask), pJoyA_in[3:0] };
	assign w_pJoyB_in = { pJoyB_in[5], (pJoyB_in[4] | af_mask), pJoyB_in[3:0] };

	system_flags u_system_flags (
		.clk21m				( clk21m			),
		.reset				( reset				),
		.req				( system_flags_req	),
		.wrt				( wrt				),
		.ack				( 					),
		.adr				( adr[0]			),
		.dbi				( system_flags_dbi	),
		.dbo				( dbo				),
		.is_turbo_r			( 1'b1				),		//	( portF4_mode		)
		.pause_sw			( 1'b0				),
		.pause_led			( 					),
		.r800_led			( 					),
		.z80_pause_mask		( 					)
	);

	switched_io_ports u_switched_io_ports (
		.clk21m				( clk21m			),
		.reset				( reset				),
		.req				( exp_io_req		),	// Modified by t.hara in May/11th/2020
		.ack				( 					),
		.wrt				( wrt				),
		.adr				( adr				),
		.dbi				( swio_dbi			),
		.dbo				( dbo				),

		.io40_n				( io40_n			),
		.io41_id212_n		( io41_id212_n		),	// here to reduce LEs
		.io42_id212			( io42_id212		),
		.io43_id212			( io43_id212		),
		.io44_id212			( io44_id212		),
		.OpllVol			( OpllVol			),
		.SccVol				( SccVol			),
		.PsgVol				( PsgVol			),
		.MstrVol			( MstrVol			),
		.CustomSpeed		( CustomSpeed		),
		.tMegaSD			( tMegaSD			),
		.tPanaRedir			( tPanaRedir		),	// here to reduce LEs
		.VdpSpeedMode		( VdpSpeedMode		),
		.V9938_n			( V9938_n			),
		.Mapper_req			( Mapper_req		),	// here to reduce LEs
		.Mapper_ack			( Mapper_ack		),
		.MegaSD_req			( MegaSD_req		),	// here to reduce LEs
		.MegaSD_ack			( MegaSD_ack		),
		.io41_id008_n		( io41_id008_n		),
		.swioKmap			( swioKmap			),
		.CmtScro			( ff_CmtScro		),
		.swioCmt			( swioCmt			),
		.LightsMode			( LightsMode		),
		.Red_sta			( Red_sta			),
		.LastRst_sta		( LastRst_sta		),
		.RstReq_sta			( RstReq_sta		),	// here to reduce LEs
		.Blink_ena			( Blink_ena			),
		.pseudoStereo		( pseudoStereo		),
		.extclk3m			( extclk3m			),
		.ntsc_pal_type		( ntsc_pal_type		),
		.forced_v_mode		( forced_v_mode		),
		.right_inverse		( right_inverse		),
		.vram_slot_ids		( vram_slot_ids		),
		.DefKmap			( DefKmap			),	// here to reduce LEs

		.ff_dip_req			( ff_dip_req[7:0]	),
		.ff_dip_ack			( ff_dip_ack		),	// here to reduce LEs

//		.SdPaus				( SdPaus			),	-- dismissed
		.Scro				( Scro				),
		.ff_Scro			( ff_Scro			),
		.Reso				( Reso				),
		.ff_Reso			( ff_Reso			),
		.FKeys				( FKeys				),
		.vFKeys				( vFKeys			),
		.LevCtrl			( LevCtrl			),
		.GreenLvEna			( GreenLvEna		),

		.swioRESET_n		( swioRESET_n		),
		.warmRESET			( warmRESET			),
		.WarmMSXlogo		( WarmMSXlogo		),	// here to reduce LEs

		.JIS2_ena			( JIS2_ena			),
		.portF4_mode		( portF4_mode		),
		.ff_ldbios_n		( w_ldbios_n		),

		.RatioMode			( RatioMode			),
		.centerYJK_R25_n	( centerYJK_R25_n	),
		.legacy_sel			( legacy_sel		),
		.iSlt1_linear		( iSlt1_linear		),
		.iSlt2_linear		( iSlt2_linear		),
		.Slot0_req			( Slot0_req			),	// here to reduce LEs
		.Slot0Mode			( Slot0Mode			),
		.vga_scanlines		(					),
		.btn_scan			(					)
	);

	// OCM-Kai Control Device		Added by t.hara in May/11th/2020
	ocmkai_control_decice u_ocmkai_control_device (
		.clk21m						( clk21m					),
		.reset						( reset						),
		.req						( exp_io_req				),
		.ack						( 							),
		.wrt						( wrt						),
		.adr						( adr[7:0]					),
		.dbi						( okaictrl_dbi				),
		.dbo						( dbo						),
		.connected					( okaictrl_en				),
		.eseram_memory_id			( eseram_memory_id			),
		.req_reset_primary_slot		( req_reset_primary_slot	),
		.ack_reset_primary_slot		( ack_reset_primary_slot	),
		.panamega_is_linear			( PanaMegaIsLinear			)
	);

//	ocmkai_debugger u_ocmkai_debugger (
//		.clk21m						( clk21m					),
//		.reset						( reset						),
//		.processor_mode				( processor_mode			),
//		.z80_pc						( z80_pc					),
//		.r800_pc					( r800_pc					),
//		.p_7seg_address_0			( p_7seg_address_0			),
//		.p_7seg_address_1			( p_7seg_address_1			),
//		.p_7seg_address_2			( p_7seg_address_2			),
//		.p_7seg_address_3			( p_7seg_address_3			)
//	);

	ocmkai_debugger u_ocmkai_debugger (
		.clk21m						( clk21m					),
		.reset						( reset						),
		.processor_mode				( 1'b0						),		//	R800
		.z80_pc						( 16'd0						),
		.r800_pc					( { { 3'd0, vFKeys[6] }, { 2'd0, vFKeys[5], vFKeys[4] }, { 3'd0, af_mask }, af_speed }	),
		//.r800_pc					( w_debug_sig				),
		.p_7seg_address_0			( p_7seg_address_0			),
		.p_7seg_address_1			( p_7seg_address_1			),
		.p_7seg_address_2			( p_7seg_address_2			),
		.p_7seg_address_3			( p_7seg_address_3			)
	);

	assign p_7seg_cpu_type	= ( ~processor_mode ) ? c_7seg_r : c_7seg_z;
	assign p_7seg_debug		= { ~w_led_internal_firmware, 3'b111, opl3_enabled, req_reset_primary_slot, w_ldbios_n };

    // debug enabler 'SHIFT+PAUSE'
	always @( posedge clk21m ) begin
		if( FKeys[7] == 1'b1 && Paus == 1'b0 ) begin
			DEBUG_ENA	<= 2'd2;
		end
		else if( FKeys[7] == 1'b0 && Paus == 1'b0 ) begin
			DEBUG_ENA	<= 2'd0;
		end
		else if( DEBUG_ENA == 2 && DEBUG_MODE == 1 ) begin
			DEBUG_ENA	<= 2'd1;
		end
	end
endmodule
