//
// sound_mixer.v
//
// ESE MSX-SYSTEM3 / MSX clone on a Cyclone FPGA (ALTERA)
// Revision 1.00
//
// Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//    product or activity without specific prior written permission.
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
// //--------------------------------------------------------------------------
//	Update history
//	03rd, June, 2020
//		Modified by t.hara
//		Separate from emsx_top hierarchy.
//

module sound_mixer #(
	parameter				c_DAC_msbi		= 13,
	parameter				c_opllamp_range	= 10
) (
	input					clk21m,
	input	[ 7:0]			Fkeys,
	output	[ 7:0]			vFkeys,
	input	[ 7:0]			PsgAmp,
	input	[ 9:0]			OpllAmp,
	input	[14:0]			Scc1Amp,
	input	[14:0]			Scc2Amp,
	input	[15:0]			Opl3Amp,
	input	[ 7:0]			tr_pcm_wave_out,
	input	[ 2:0]			OpllVol,
	input	[ 2:0]			SccVol,
	input	[ 2:0]			PsgVol,
	input	[ 2:0]			Opl3Vol,
	input	[ 2:0]			MstrVol,
	input					KeyClick,
	output	[c_DAC_msbi:0]	DACin
);
	reg		[ 7:0]	vFKeys;
	localparam h_ramp			= -1;						// h_ramp selector -4 to 0 <= lv1-3, lv2-4, lv3-5, lv4-6 (in use), lv5-7
	localparam m_ramp			=  2;						// m_ramp selector -1 to 3 <= lv1-3, lv2-4, lv3-5, lv4-6 (in use), lv5-7
	localparam l_ramp			=  6;						// l_ramp <= level 1-7 (steps 3, 4, 5, 6, 7, 8, 9)
	localparam h_thrd			= 12;						// h_ramp threshold (steps 13, 14, 15)
	localparam m_thrd			=  9;						// m_ramp threshold (steps 10, 11, 12)
	localparam x_thrd			=  1;						// extra threshold (PsgVol goes up one level when x_thrd = 1)

	localparam c_DACin_high		= c_DAC_msbi;
	localparam c_prepsg_high	= 8;
	localparam c_opllamp_high	= c_opllamp_range - 1;
	localparam c_opll_offset	= { 1'b1, { (c_DACin_high + 2) { 1'b0 } } };
	localparam c_opll_zero		= { 1'b1, { (c_opllamp_high  ) { 1'b0 } } };

	reg		[ 7:0]						ff_vFkeys;

	reg		[ c_prepsg_high: 0]			ff_prepsg;
	reg		[ 15: 0]					ff_prescc;

	wire	[ c_prepsg_high: 0]			chPsg;
	reg		[  3: 0]					c_Psg;		// combine PsgVol and MstrVol
	reg		[  3: 0]					c_Scc;		// combine SccVol and MstrVol
	reg		[  3: 0]					c_Opll;		// combine OpllVol and MstrVol

	wire	[ c_DACin_high - 2 : 0]		w_psg;
	reg		[ c_DACin_high + 2 : 0]		ff_psg;
	reg		[ c_DACin_high + 2 : 0]		ff_scc;
	reg		[ c_DACin_high + 2 : 0]		ff_opl3;
	wire	[ 18: 0]					w_scc;
	reg		[  2: 0]					m_SccVol;
	wire	[ c_DACin_high + 2 : 0]		chOpll;
	reg		[ c_DACin_high + 2 : 0]		ff_opll;
	reg		[ c_DACin_high + 2 : 0]		ff_psg_offset;
	reg		[ c_DACin_high + 2 : 0]		ff_scc_offset;
	wire	[  2: 0]					tr_pcm_vol;
	reg		[ c_DACin_high + 2 : 0]		ff_tr_pcm;
	reg		[ c_DACin_high + 2 : 0]		ff_pre_dacin;
	wire	[ c_opllamp_high   : 0]		w_opll_amplitude;
	reg		[ c_DACin_high     : 0]		ff_DACin;

	// | b7	 | b6	| b5   | b4	  | b3	| b2  | b1	| b0  |
	// | SHI | --	| PgUp | PgDn | F9	| F10 | F11 | F12 |
	always @( posedge clk21m ) begin
		ff_vFkeys	<=	Fkeys;
	end
	assign vFkeys	= ff_vFkeys;

	// mixer (pipe lined)
	scc_mix_mul u_mul (
		.a		( ff_prescc		),			// 16bits signed
		.b		( m_SccVol		),			//	3bits unsigned
		.c		( w_scc			)			// 19bits signed
	);

	assign chPsg	=	( c_Psg > h_thrd            ) ? ff_prepsg :
						( c_Psg > (m_thrd - x_thrd) ) ? { 1'b0,  ff_prepsg[ c_prepsg_high : 1 ] } :
														{ 2'b00, ff_prepsg[ c_prepsg_high : 2 ] };

	assign w_psg	=	( c_Psg > h_thrd            ) ? ((chPsg * (PsgVol - MstrVol + h_ramp + x_thrd)) + chPsg[ c_prepsg_high - 4 : 0 ]) :
						( c_Psg > (m_thrd - x_thrd) ) ? ((chPsg * (PsgVol - MstrVol + m_ramp + x_thrd)) + chPsg[ c_prepsg_high - 4 : 0 ]) :
													    ((chPsg * (PsgVol - MstrVol + l_ramp + x_thrd)) + chPsg[ c_prepsg_high - 4 : 0 ]);

	assign w_opll_amplitude	=	( OpllAmp < c_opll_zero ) ? (c_opll_zero - OpllAmp) : (OpllAmp - c_opll_zero);
	assign chOpll			=	( c_Opll > h_thrd ) ? {       (w_opll_amplitude * (OpllVol - MstrVol + h_ramp)), 3'b000} :
								( c_Opll > m_thrd ) ? {1'b0 , (w_opll_amplitude * (OpllVol - MstrVol + m_ramp)), 2'b00 } :
													  {2'b00, (w_opll_amplitude * (OpllVol - MstrVol + l_ramp)), 1'b0  };

	assign tr_pcm_vol	= MstrVol;

	always @( posedge clk21m ) begin
		// amplitude ramp of the PSG (full range)
		ff_prepsg	<= { 1'b0, PsgAmp } + { KeyClick, 5'b00000 };
		c_Psg		<= { 1'b1, PsgVol } - { 1'b0, MstrVol };
//		if( PsgVol == 3'b000 || MstrVol == 3'b111 || SdPaus == 1'b1 )begin				// dismissed
		if( PsgVol == 3'b000 || MstrVol == 3'b111 )begin
			ff_psg		<= 'd0;
		end
		else begin
			ff_psg	<= { 2'b00, w_psg, 2'b00 };
		end

		// amplitude ramp of the SCC-I (full range)
		ff_prescc	<= { Scc1Amp[14], Scc1Amp } + { Scc2Amp[14], Scc2Amp };
		c_Scc		<= { 1'b1, SccVol } - { 1'b0, MstrVol };
//		if( SccVol == 3'b000 || MstrVol == 3'b111 || SdPaus == 1'b1 ) begin				// dismissed
		if( SccVol == 3'b000 || MstrVol == 3'b111 ) begin
			m_SccVol	<= 3'b000;
			ff_scc		<= { (c_DACin_high + 3) { w_scc[18] } };
		end
		else if( c_Scc > h_thrd )begin
			m_SccVol	<= SccVol - MstrVol + h_ramp;
			ff_scc		<= { w_scc[18], w_scc[18: 4] };
		end
		else if( c_Scc > m_thrd )begin
			m_SccVol	<= SccVol - MstrVol + m_ramp;
			ff_scc		<= { w_scc[18], w_scc[18], w_scc[18: 5] };
		end
		else begin
			m_SccVol	<= SccVol - MstrVol + l_ramp;
			ff_scc		<= { w_scc[18], w_scc[18], w_scc[18], w_scc[18: 6] };
		end

		// amplitude ramp of the OPLL (full range)
		c_Opll		<= { 1'b1, OpllVol} - {1'b0, MstrVol};
//		if( OpllVol == 3'b000 || MstrVol == 3'b111 || SdPaus == 1'b1 ) begin			// dismissed
		if( OpllVol == 3'b000 || MstrVol == 3'b111 )begin
			ff_opll <= c_opll_offset;
		end
		else if( OpllAmp < c_opll_zero ) begin
			ff_opll <= c_opll_offset - (chOpll - chOpll[c_DACin_high + 2: 3]);
		end
		else begin
			ff_opll <= c_opll_offset + (chOpll - chOpll[c_DACin_high + 2: 3]);
		end

		// amplitude ramp of the OPL3 (mixer level equivalences: off, 4, 7 and 10 out of 13)
		case( Opl3Vol )
		3'b000, 3'b001:
			begin
				ff_tr_pcm[               11 :  0] <= Opl3Amp[15:4];
				ff_tr_pcm[ c_DACin_high + 2 : 12] <= { (c_DACin_high + 2 - 11 + 1) { Opl3Amp[15] } };
			end
		3'b010, 3'b011, 3'b100:
			begin
				ff_tr_pcm[               10 :  0] <= Opl3Amp[15:5];
				ff_tr_pcm[ c_DACin_high + 2 : 11] <= { (c_DACin_high + 2 - 10 + 1) { Opl3Amp[15] } };
			end
		3'b101, 3'b110:
			begin
				ff_tr_pcm[                9 :  0] <= Opl3Amp[15:6];
				ff_tr_pcm[ c_DACin_high + 2 : 10] <= { (c_DACin_high + 2 -  9 + 1) { Opl3Amp[15] } };
			end
		default:
			begin
				ff_opl3							  <= { (c_DACin_high + 2 -  0 + 1) { Opl3Amp[15] } };
			end
		endcase

		// amplitude ramp of the turboR PCM (mixer level equivalences: off, 1, 5 and 10 out of 13)
		case( tr_pcm_vol )
		3'b000, 3'b001:
			begin
				ff_tr_pcm[               10 :  0] <= { tr_pcm_wave_out,      3'b000 };
				ff_tr_pcm[ c_DACin_high + 2 : 11] <= { (c_DACin_high + 2 - 11 + 1) { tr_pcm_wave_out[7] } };
			end
		3'b010, 3'b011, 3'b100:
			begin
				ff_tr_pcm[                9 :  0] <= { tr_pcm_wave_out[7:1], 3'b000 };
				ff_tr_pcm[ c_DACin_high + 2 : 10] <= { (c_DACin_high + 2 - 10 + 1) { tr_pcm_wave_out[7] } };
			end
		3'b101, 3'b110:
			begin
				ff_tr_pcm[                8 :  0] <= { tr_pcm_wave_out[7: 2], 3'b000 };
				ff_tr_pcm[ c_DACin_high + 2 :  9] <= { (c_DACin_high + 2 -  9 + 1) { tr_pcm_wave_out[7] } };
			end
		default:
			begin
				ff_tr_pcm						  <= { (c_DACin_high + 2 -  0 + 1) { tr_pcm_wave_out[7] } };
			end
		endcase
	end

	always @( posedge clk21m ) begin
		// ff_pre_dacin assignment
		ff_pre_dacin <= (~ff_psg) + ff_scc + ff_opll + ff_tr_pcm + ff_opl3;

		// amplitude limiter
		case( ff_pre_dacin[ c_DACin_high + 2 : c_DACin_high ] )
		3'b100:
			ff_DACin <= { ff_pre_dacin[c_DACin_high + 2], ff_pre_dacin[c_DACin_high + 2 - 3: 0] };
		3'b011:
			ff_DACin <= { ff_pre_dacin[c_DACin_high + 2], ff_pre_dacin[c_DACin_high + 2 - 3: 0] };
		default:
			ff_DACin <= { (c_DACin_high + 1) { ff_pre_dacin[c_DACin_high + 2] } };
		endcase
	end

	assign DACin			= ff_DACin;
endmodule
