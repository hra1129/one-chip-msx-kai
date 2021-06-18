//
// ocmkai_debugger.v
//	 1chipMSX-Kai Control Device
//	 Revision 1.00
//
// Copyright (c) 2021 Takayuki Hara.
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
//		04th/June/2021 by t.hara
//			1st release
//

module ocmkai_debugger (
	input			clk21m,
	input			reset,
	input			processor_mode,			//	1: Z80, 0: R800
	input	[15:0]	z80_pc,
	input	[15:0]	r800_pc,
	output	[ 6:0]	p_7seg_address_0,
	output	[ 6:0]	p_7seg_address_1,
	output	[ 6:0]	p_7seg_address_2,
	output	[ 6:0]	p_7seg_address_3
);
	reg		[15:0]	ff_pc;

	//	   _______   
	//	  <___0___>  
	//	| |       | |
	//	|5|       |1|
	//	| |_______| |
	//	  <___6___>  
	//	| |       | |
	//	|4|       |2|
	//	| |_______| |
	//	  <___3___>  
	//
	function [6:0] seven_segment_decoder(
		input	[3:0]	num
	);
		case( num )
			4'h0:		seven_segment_decoder = 7'b1000000;
			4'h1:		seven_segment_decoder = 7'b1111001;
			4'h2:		seven_segment_decoder = 7'b0100100;
			4'h3:		seven_segment_decoder = 7'b0110000;
			4'h4:		seven_segment_decoder = 7'b0011100;
			4'h5:		seven_segment_decoder = 7'b0010010;
			4'h6:		seven_segment_decoder = 7'b0000010;
			4'h7:		seven_segment_decoder = 7'b1111000;
			4'h8:		seven_segment_decoder = 7'b0000000;
			4'h9:		seven_segment_decoder = 7'b0010000;
			4'hA:		seven_segment_decoder = 7'b0001000;
			4'hB:		seven_segment_decoder = 7'b0000011;
			4'hC:		seven_segment_decoder = 7'b1000110;
			4'hD:		seven_segment_decoder = 7'b0100001;
			4'hE:		seven_segment_decoder = 7'b0000110;
			4'hF:		seven_segment_decoder = 7'b0001100;
			default:	seven_segment_decoder = 7'b1111111;
		endcase
	endfunction

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_pc <= 16'h0000;
		end
		else if( processor_mode ) begin
			ff_pc <= z80_pc;
		end
		else begin
			ff_pc <= r800_pc;
		end
	end

	assign p_7seg_address_0	= seven_segment_decoder( ff_pc[ 3: 0] );
	assign p_7seg_address_1	= seven_segment_decoder( ff_pc[ 7: 4] );
	assign p_7seg_address_2	= seven_segment_decoder( ff_pc[11: 8] );
	assign p_7seg_address_3	= seven_segment_decoder( ff_pc[15:12] );
endmodule
