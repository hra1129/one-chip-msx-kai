//
// tr_midi.v
//	 MSX-MIDI for MSXturboR (FS-A1GT)
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

module tr_midi #(
	parameter		c_base_clk		= 22'd2147727	//	21.47727[MHz]
) (
	input			clk21m,
	input			reset,
	input			req,
	output			ack,
	input			wrt,
	input	[ 2:0]	adr,
	output	[ 7:0]	dbi,
	input	[ 7:0]	dbo,
	output			pMidiTxD,
	input			pMidiRxD,
	output			pMidiIntr
);
	parameter		c_target_clk_x2	=  22'd800000;	//	 4.00000[MHz] * 2

	reg		[21:0]	ff_clk_generator;				//	22[bit] > log2( c_base_clk + c_target_clk_x2 )
	wire	[21:0]	w_clk_generator;
	wire			w_clk_en;
	reg				ff_clk4m;
	wire			w_timer0_out;
	wire			w_timer2_out;
	reg				ff_timer2_out;
	reg				ff_timer_intr;
	wire			w_dsr_n;
	wire			w_dtr_n;
	wire			w_rxrdy;

	wire			i8251_cs_n;
	wire			i8251_rd_n;
	wire			i8251_wr_n;
	wire	[ 7:0]	i8251_q;

	wire			other_cs_n;
	wire			other_rd_n;
	wire			other_wr_n;
	wire	[ 7:0]	other_q;

	wire			i8253_cs_n;
	wire			i8253_rd_n;
	wire			i8253_wr_n;
	wire	[ 7:0]	i8253_q;

	reg		[ 7:0]	ff_dbi;

	//--------------------------------------------------------------
	//	out assignment
	//--------------------------------------------------------------
	assign dbi		=	ff_dbi;
	assign ack		=	req;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_dbi	<= 8'd255;
		end
		else if( req && !wrt ) begin
			ff_dbi	<= i8251_q & i8253_q & other_q;
		end
		else begin
			//	hold
		end
	end

	//--------------------------------------------------------------
	//	clock generator (Generate 4MHz from 21.47727MHz)
	//--------------------------------------------------------------
	assign w_clk_generator	= ff_clk_generator + c_target_clk_x2;
	assign w_clk_en			= (w_clk_generator >= c_base_clk) ? 1'b1: 1'b0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_clk_generator	<= 22'd0;
		end
		else begin
			if( w_clk_en ) begin
				ff_clk_generator	<= w_clk_generator - c_base_clk;
			end
			else begin
				ff_clk_generator	<= w_clk_generator;
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_clk4m	<= 1'b0;
		end
		else begin
			if( w_clk_en ) begin
				ff_clk4m	<= ~ff_clk4m;
			end
			else begin
				//	hold
			end
		end
	end

	//--------------------------------------------------------------
	//	other circuit ( EAh, EBh )
	//	                1110_1010 - 1110_1011
	//--------------------------------------------------------------
	assign other_cs_n	= ( adr[2:1] == 2'b01 ) ? ~req          : 1'b1;
	assign other_rd_n	= ( adr[2:1] == 2'b01 ) ? ~(req & ~wrt) : 1'b1;
	assign other_wr_n	= ( adr[2:1] == 2'b01 ) ? ~(req &  wrt) : 1'b1;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_timer2_out	<= 1'b1;
		end
		else begin
			ff_timer2_out	<= w_timer2_out;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_timer_intr	<= 1'b1;
		end
		else begin
			if( ~w_timer2_out && ff_timer2_out ) begin
				ff_timer_intr	<= 1'b0;
			end
			else if( !other_cs_n && !other_wr_n ) begin
				ff_timer_intr	<= 1'b1;
			end
			else begin
				//	hold
			end
		end
	end

	assign other_q		= 8'hff;
	assign w_dsr_n		= ff_timer_intr | w_dtr_n;
	assign pMidiIntr	= w_dsr_n;

	//--------------------------------------------------------------
	//	i8251 clone ( E8h, E9h )
	//	              1110_1000 - 1110_1001
	//--------------------------------------------------------------
	assign i8251_cs_n	= ( adr[2:1] == 2'b00 ) ? ~req          : 1'b1;
	assign i8251_rd_n	= ( adr[2:1] == 2'b00 ) ? ~(req & ~wrt) : 1'b1;
	assign i8251_wr_n	= ( adr[2:1] == 2'b00 ) ? ~(req &  wrt) : 1'b1;

	i8251 u_8251 (
		.reset				( reset				),
		.clk21m				( clk21m			),
		.cs_n				( i8251_cs_n		),
		.rd_n				( i8251_rd_n		),
		.wr_n				( i8251_wr_n		),
		.a					( adr[0]			),
		.d					( dbo				),
		.q					( i8251_q			),
		.txc_n				( w_timer0_out		),
		.txd				( pMidiTxD			),
		.txrdy				( w_txrdy			),
		.rxc_n				( w_timer0_out		),
		.rxd				( pMidiRxD			),
		.rxrdy				( w_rxrdy			),
		.cts_n				( 1'b0				),
		.dsr_n				( w_dsr_n			),
		.dtr_n				( w_dtr_n			)
	);

	//--------------------------------------------------------------
	//	i8253 clone ( ECh - EFh )
	//	              1110_1100 - 1110_1111
	//--------------------------------------------------------------
	assign i8253_cs_n	= ( adr[2] == 1'b1 ) ? ~req          : 1'b1;
	assign i8253_rd_n	= ( adr[2] == 1'b1 ) ? ~(req & ~wrt) : 1'b1;
	assign i8253_wr_n	= ( adr[2] == 1'b1 ) ? ~(req &  wrt) : 1'b1;

	i8253 u_8253 (
		.reset				( reset				),
		.clk21m				( clk21m			),
		.cs_n				( i8253_cs_n		),
		.rd_n				( i8253_rd_n		),
		.wr_n				( i8253_wr_n		),
		.a					( adr[1:0]			),
		.d					( dbo				),
		.q					( i8253_q			),
		.clk0				( ff_clk4m			),
		.gate0				( 1'b1				),
		.out0				( w_timer0_out		),
		.clk1				( w_timer2_out		),
		.gate1				( 1'b1				),
		.out1				( 					),	//	open
		.clk2				( ff_clk4m			),
		.gate2				( 1'b1				),
		.out2				( w_timer2_out		)
	);
endmodule
