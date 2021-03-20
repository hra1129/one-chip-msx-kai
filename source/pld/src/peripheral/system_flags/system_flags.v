//
// system_flags.v
//	 System Flags for MSXturboR
//	 Revision 1.00
//
// Copyright (c) 2019 Takayuki Hara.
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

module system_flags (
	input			clk21m,
	input			reset,
	input			req,
	input			wrt,
	output			ack,
	input			adr,				//	0: F4h, 1: A7h
	output	[ 7:0]	dbi,
	input	[ 7:0]	dbo,
	input			is_turbo_r,			//	0: MSX2/2+, 1: MSXturboR
	input			pause_sw,			//	0: off, 1: on
	output			pause_led,			//	0: on, 1: off
	output			r800_led,			//	0: on, 1: off
	output			z80_pause_mask
);
	reg		[ 7:0]	ff_status;			//	bit7: 0: hardware reset, 1: software reset (without MSX logo)
										//	bit5: 0: Z80, 1: R800
	reg				ff_pause_led;
	reg				ff_z80_pause_mask;
	reg				ff_r800_led;

	//--------------------------------------------------------------
	//	out assignment
	//--------------------------------------------------------------
	assign dbi	=	( is_turbo_r ) ? ( ( adr == 1'b0 ) ? ff_status : { 7'b0, pause_sw } ):
					                 ( ( adr == 1'b0 ) ?~ff_status : 8'hFF );
	assign ack	=	req;

	//--------------------------------------------------------------
	//	simply memory cell
	//--------------------------------------------------------------

	//	port F4h
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_status			<= 8'd0;
		end
		else if( req && wrt && !adr ) begin
			ff_status			<= dbo;
		end
	end

	//	port A7h
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_pause_led		<= 1'b0;
			ff_z80_pause_mask	<= 1'b0;
			ff_r800_led			<= 1'b0;
		end
		else if( req && wrt && adr ) begin
			ff_pause_led		<= dbo[0];
			ff_z80_pause_mask	<= dbo[1];
			ff_r800_led			<= dbo[7];
		end
	end

	assign pause_led		= ~ff_pause_led;
	assign r800_led			= ~ff_r800_led;
	assign z80_pause_mask	= ff_z80_pause_mask;
endmodule
