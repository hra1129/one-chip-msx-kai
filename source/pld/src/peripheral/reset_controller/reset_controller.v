//
// ocmkai_control_device.v
//	 1chipMSX-Kai Control Device
//	 Revision 1.00
//
// Copyright (c) 2020 Takayuki Hara.
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
// -----------------------------------------------------------------------------
//	History
//	May/21th/2020 ver1.00 first release by t.hara
//		Separated from emsx_top.
//
//	Aug/27th/2021 ver1.01 by t.hara
//		Added power_on_reset signal
//
module reset_controller (
	input			memclk,
	input			clk21m,
	input			pulse10hz,
	input			RstKeyLock,
	input			pSltRst_n,
	input			sdram_ready,
	input			swioRESET_n,
	output			reset,
	output			xSltRst_n,
	output			sync_reset,
	output			sig10mhz,
	output			sig5mhz,
	output			power_on_reset
);
	reg		[ 1:0]	ff_mem_seq			= 2'b00;
	reg		[19:0]	FreeCounter			= 20'd0;
	reg				HoldRst_ena			= 1'b0;
	reg		[ 3:0]	HardRst_cnt			= 4'd0;
	reg				ff_sync_reset		= 1'b1;
	reg				ff_power_on_reset	= 1'b0;

	always @( posedge memclk ) begin
		if( FreeCounter[19:15] == 5'b11001 ) begin		//	about 38ms
			ff_power_on_reset <= 1'b1;
		end
	end
	assign power_on_reset = ff_power_on_reset;

	//	00 --> 01 --> 11 --> 10 --> 00
	always @( posedge memclk ) begin
		ff_mem_seq <= { ff_mem_seq[0], ~ff_mem_seq[1] };
	end

	always @( posedge clk21m ) begin
		FreeCounter <= FreeCounter + 20'd1;
	end

	// hard reset timer
	always @( posedge clk21m ) begin
		if( RstKeyLock == 1'b0 ) begin
			if( pSltRst_n != 1'b0 ) begin
				HoldRst_ena <= 1'b0;
				if( HardRst_cnt != 4'b0011 || HardRst_cnt != 4'b0010 ) begin
					HardRst_cnt <= 4'b0000;
				end
			end
			else begin
				if( HoldRst_ena == 1'b0 ) begin
					HardRst_cnt <= 4'b1110;				// 1500ms hold reset
					HoldRst_ena <= 1'b1;
				end
				else if( pulse10hz == 1'b1 && HardRst_cnt != 4'b0001 ) begin
					HardRst_cnt <= HardRst_cnt - 4'd1;
				end
			end
		end
	end

	always @( posedge memclk ) begin
		if( HardRst_cnt == 4'b0011 ) begin				// 200ms from "0001"
			if( pulse10hz == 1'b1 && sdram_ready == 1'b1 ) begin
				ff_sync_reset <= 1'b1;
			end
			else begin
				ff_sync_reset <= 1'b0;
			end
		end
		else begin
			ff_sync_reset <= 1'b0;
		end
	end

	assign reset		= ( pSltRst_n == 1'b0 && RstKeyLock == 1'b0 && HardRst_cnt != 4'b0001 ) ? 1'b1 :
						  ( swioRESET_n == 1'b0 || HardRst_cnt == 4'b0011 || HardRst_cnt == 4'b0010 || sdram_ready == 1'b0 ) ? 1'b1 :		// Modifyed by t.hara in 10th/May/2020
						  1'b0;
	assign xSltRst_n	= ~reset & ff_power_on_reset;
	assign sync_reset	= ff_sync_reset;
	assign sig10mhz		= FreeCounter[0];
	assign sig5mhz		= FreeCounter[1];
endmodule
