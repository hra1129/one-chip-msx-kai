//
// mapper.v
// Memory mapper
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
// ============================================================================
//	Feb./21th/2021 t.hara
//		Transcode to Verilog from VHDL
// ============================================================================

module mapper(
		input			clk21m,
		input			reset,
		input			clkena,
		input			req,
		output			ack,
		input			mem,
		input			wrt,
		input	[15:0]	adr,
		output	[ 7:0]	dbi,
		input	[ 7:0]	dbo,

		output			ramreq,
		output			ramwrt,
		output	[21:0]	ramadr,
		input	[ 7:0]	ramdbi,
		output	[ 7:0]	ramdbo
	);
	reg		[7:0]	ff_mapper_bank0;
	reg		[7:0]	ff_mapper_bank1;
	reg		[7:0]	ff_mapper_bank2;
	reg		[7:0]	ff_mapper_bank3;

	//--------------------------------------------------------------
	// Mapper bank register access
	//--------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_mapper_bank0	 <= 8'h03;
			ff_mapper_bank1	 <= 8'h02;
			ff_mapper_bank2	 <= 8'h01;
			ff_mapper_bank3	 <= 8'h00;
		end
		else begin
			// I/O port access on FC-FFh ... Mapper bank register write
			if( (req & ~mem & wrt) == 1'b1 ) begin
				case( adr[1:0] )
					2'b00:		ff_mapper_bank0 <= dbo;
					2'b01:		ff_mapper_bank1 <= dbo;
					2'b10:		ff_mapper_bank2 <= dbo;
					default:	ff_mapper_bank3 <= dbo;
				endcase
			end
		end
	end

	assign ack    = req & ~mem;
	assign ramreq = req & mem;
	assign ramwrt = wrt;

	assign ramadr = (adr[15:14] == 2'b00) ? { ff_mapper_bank0, adr[13:0] } :
					(adr[15:14] == 2'b01) ? { ff_mapper_bank1, adr[13:0] } :
					(adr[15:14] == 2'b10) ? { ff_mapper_bank2, adr[13:0] } : { ff_mapper_bank3, adr[13:0] };

	assign ramdbo = dbo;
	assign dbi    = (mem == 1'b1      ) ? ramdbi :
					(adr[1:0] == 2'b00) ? ff_mapper_bank0 :
					(adr[1:0] == 2'b01) ? ff_mapper_bank1 :
					(adr[1:0] == 2'b10) ? ff_mapper_bank2 : ff_mapper_bank3;
endmodule
