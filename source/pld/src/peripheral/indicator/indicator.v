//
// indicator.v
//	 1chipMSX Indicator
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
//	June/24th/2020 Created by t.hara
//		Separate from emsx_top hierarchy.
//		

module indicator (
	input			reset,
	input			clk21m,
	input			Paus,
	input			ff_clksel5m_n,
	input			w_10hz,
	input			GreenLvEna,
	input			ZemmixNeo,
	output			PausFlash,
	input	[20:0]	freerun_count,
	input	[1:0]	debug_mode,
	input	[7:0]	break_point,
	input	[7:0]	GreenLeds,
	input			Blink_ena,
	input			MmcEna,
	input			MmcMode,
	input			LightsMode,
	input	[2:0]	LevCtrl,
	input	[7:0]	io42_id212,
	input	[1:0]	DisplayMode,
	input			Slot1Mode,
	input	[1:0]	Slot2Mode,
	input			FullRAM,
	input			Red_sta,
	input			w_sig5mhz,
	input			w_sig10mhz,
	input			pSltRst_n,
	input			RstKeyLock,
	output	[7:0]	pLed,
	output			pLedPwr
);
	reg		[3:0]	flash_cnt;		// flash counter
	reg		[3:0]	GreenLv_cnt;	// green level counter
	reg		[6:0]	GreenLv;		// green level
	reg				FadedRed;
	reg				FadedGreen;
	reg				ff_pLedPwr;
	wire			MmcEnaLed;

	always @( posedge clk21m ) begin
		if( !Paus ) begin
			if( ff_clksel5m_n ) begin
				flash_cnt <= 4'b0000;
			end
			else begin
				flash_cnt <= 4'b0100;
			end
		end
		else if( w_10hz ) begin
			if( flash_cnt == 4'b0000 ) begin
				flash_cnt <= 4'b1011;				// 1200ms
			end
			else begin
				flash_cnt <= flash_cnt - 4'd1;
			end
		end
	end

	// Pause Flash (800ms On + 400ms Off = 1200ms per cycle)
	assign PausFlash	=	( flash_cnt[3:2] == 2'b00 ) ? 1'b0 : 1'b1;

	// Blink assignment
	assign MmcEnaLed	=	( Blink_ena && MmcEna      ) ? ((freerun_count[20] | (~freerun_count[19])) & FadedGreen) :
							(!Blink_ena && !LightsMode ) ? ( MmcMode & FadedGreen ) :
							(               LightsMode ) ? ( GreenLeds[7] & FadedGreen ) : 1'b0;

	// green level counter
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			GreenLv_cnt <= 4'b0000;
		end
		else begin
			if( GreenLvEna ) begin
				GreenLv_cnt <= 4'b1111;
			end
			else if( w_10hz && GreenLv_cnt != 4'b0000 ) begin
				GreenLv_cnt <= GreenLv_cnt - 4'd1;			// 1600ms
			end
		end
	end

	// green level assignment
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			GreenLv <= 7'd0;
		end
		else begin
			case( LevCtrl )
			3'b111:		GreenLv <=	7'b1111111;
			3'b110:		GreenLv <=	7'b0111111;
			3'b101:		GreenLv <=	7'b0011111;
			3'b100:		GreenLv <=	7'b0001111;
			3'b011:		GreenLv <=	7'b0000111;
			3'b010:		GreenLv <=	7'b0000011;
			3'b001:		GreenLv <=	7'b0000001;
			default:	GreenLv <=	7'b0000000;
			endcase
		end
	end

	// LEDs luminance
	always @( posedge clk21m ) begin
		if( !ZemmixNeo ) begin
			FadedGreen	<=	freerun_count[12];
			FadedRed	<=	freerun_count[0];
		end
		else begin
			FadedGreen	<=	1'b1;
			FadedRed	<=	1'b1;
		end
	end

	// power LED
	always @( posedge reset or posedge clk21m )
	begin
		if( reset ) begin
			ff_pLedPwr <= 1'b0;	//clk21m | ZemmixNeo;					// lights test holding the hard reset
		end
		else begin
//			if( SdPaus ) begin								// dismissed
//				if( PausFlash && !ZemmixNeo ) begin
//					ff_pLedPwr <= FadedRed;					// Pause		is Flash + Faded Red
//				end
//				else begin
//					ff_pLedPwr <= 1'b0;
//				end
//			end
			// Lights On/Off toggle
			if( Red_sta && GreenLv_cnt == 4'b0000 && !Paus ) begin
				if( ZemmixNeo ) begin
					ff_pLedPwr <= 1'b1;						// On
				end
				else begin
					ff_pLedPwr <= FadedRed;					// 5.37MHz On	is Faded Red only
				end
			end
			else begin
//				ff_pLedPwr <= logo_timeout[0];					// test for the logo speed limiter
				ff_pLedPwr <= 1'b0;							// Off / Blink
			end
		end
	end

	assign pLedPwr	= ff_pLedPwr;

	// LEDs assignment
	assign pLed	=	//	( ZemmixNeo && SdPaus ) ? {					// Pause Flash for Zemmix Neo				// dismissed
					//		{ 3'd0, (PausFlash & FadedGreen), 4'd0 } :

					( Paus && debug_mode != 2'd1 ) ? 				// Lights On/Off toggle
						8'd0 :

					( Paus && ZemmixNeo ) ? {						// DEBUG MODE for Zemmix Neo
						break_point[7], break_point[6], break_point[5], break_point[4], 
						break_point[3], break_point[2], break_point[1], break_point[0] } :

					( Paus ) ? {									// DEBUG MODE for 1chipMSX
						(break_point[0] & FadedGreen), (break_point[1] & FadedGreen),
						(break_point[2] & FadedGreen), (break_point[3] & FadedGreen),
						(break_point[4] & FadedGreen), (break_point[5] & FadedGreen),
						(break_point[6] & FadedGreen), (break_point[7] & FadedGreen) } :

					( LightsMode && ZemmixNeo ) ? {					// LightsMode + Blink for Zemmix Neo
						GreenLeds[0], GreenLeds[1], GreenLeds[2], GreenLeds[3], 
						GreenLeds[4], GreenLeds[5], GreenLeds[6], MmcEnaLed } :

					( LightsMode ) ? {								// Blink + LightsMode for 1chipMSX
						MmcEnaLed					, (GreenLeds[6] & FadedGreen) ,
						(GreenLeds[5] & FadedGreen)	, (GreenLeds[4] & FadedGreen) ,
						(GreenLeds[3] & FadedGreen)	, (GreenLeds[2] & FadedGreen) ,
						(GreenLeds[1] & FadedGreen)	, (GreenLeds[0] & FadedGreen) } :

					( GreenLv_cnt != 4'b0000 && ZemmixNeo ) ? {		// Volume + High-Speed Level + Blink for Zemmix Neo
						GreenLv[0], GreenLv[1], GreenLv[2], GreenLv[3],
						GreenLv[4], GreenLv[5], GreenLv[6], MmcEnaLed } :

					( GreenLv_cnt != 4'b0000 ) ? {					// Blink + Volume + High-Speed Level for 1chipMSX
						MmcEnaLed					, (GreenLv[6] & w_sig5mhz)	, 
						(GreenLv[5] & w_sig5mhz)	, (GreenLv[4] & w_sig5mhz)	, 
						(GreenLv[3] & w_sig5mhz)	, (GreenLv[2] & w_sig5mhz)	, 
						(GreenLv[1] & w_sig5mhz)	, (GreenLv[0] & w_sig5mhz) } :

					( !pSltRst_n && !RstKeyLock ) ? {				// lights test holding the hard reset
						8 { w_sig10mhz } } :

					( ZemmixNeo ) ? {								// Virtual DIP-SW (Auto) + Blink for Zemmix Neo
						io42_id212[0]	, DisplayMode[1]	, DisplayMode[0]	, Slot1Mode			, 
						Slot2Mode[1]	, Slot2Mode[0]		, FullRAM			, MmcEnaLed } :

					// Blink + Virtual DIP-SW (Auto) for 1chipMSX
					{	MmcEnaLed						, (FullRAM			&& FadedGreen) ,
						(Slot2Mode[0]	&&  FadedGreen)	, (Slot2Mode[1]		&& FadedGreen) ,
						(Slot1Mode		&&  FadedGreen)	, (DisplayMode[0]	&& FadedGreen) ,
						(DisplayMode[1]	&&  FadedGreen)	, (io42_id212[0]	&& FadedGreen) };
endmodule
