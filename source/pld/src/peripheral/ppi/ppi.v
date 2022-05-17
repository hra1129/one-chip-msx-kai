//
// ppi.v
//	 1chipMSX PPI
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
//	May/27th/2020 Created by t.hara
//		Separate from emsx_top hierarchy.
//
//	August/4th/2020 Modified by t.hara
//		Move ff_ldbios_n to ocm_bus_selector
//

module ppi (
	input			reset,
	input			clk21m,
	input			clkena,
	input			req,
	input			exp_slot_req,
	input			wrt,
	input	[15:0]	adr,
	input	[ 7:0]	dbo,
	output	[ 7:0]	dbi,
	input			slot0_expanded,
	inout			pPs2Clk,
	inout			pPs2Dat,
	output	[ 1:0]	PriSltNum,
	output	[ 1:0]	ExpSltNum0,
	output	[ 1:0]	ExpSltNum3,
	output	[ 7:0]	ExpDbi,
	output			RemOut,
	output			CmtOut,
	input			CmtScro,
	output			KeyClick,
	input			Kmap,
	input			Kana,
	output			Paus,
	output			Scro,
	output			Reso,
	output	[ 7:0]	Fkeys,
	input			autofire
//	output	[15:0]	debug_sig
);
	reg		[ 7:0]	ff_ppi_port_a;
	reg		[ 7:0]	ff_ppi_port_c;
	reg		[ 7:0]	ff_ExpSlot0;
	reg		[ 7:0]	ff_ExpSlot3;
	wire	[ 7:0]	w_key_x;
	wire	[ 7:0]	w_key_x_af;
	wire			w_caps;

	// Space key autofire
	assign w_key_x_af = ( ff_ppi_port_c[ 3: 0 ] != 4'd8 ) ? w_key_x: 
						{ w_key_x[7:1], (w_key_x[0] | autofire) };

	always @( posedge reset or posedge clk21m ) begin
		if( reset == 1'b1 )begin
			ff_ppi_port_a	<= 8'hFF;					// primary slot : page 0 => boot-rom, page 1/2 => ese-mmc, page 3 => mapper
			ff_ppi_port_c	<= 8'h00;
		end
		else begin
			// I/O port access on A8-ABh ... PPI(8255) access
			if( req == 1'b1 )begin
				if( wrt == 1'b1 && adr[1:0] == 2'b00 )begin
					ff_ppi_port_a	<= dbo;
				end
				else if( wrt == 1'b1 && adr[1:0] == 2'b10 )begin
					ff_ppi_port_c	<= dbo;
				end
				else if( wrt == 1'b1 && adr[1:0] == 2'b11 && dbo[7] == 1'b0 )begin
					case( dbo[3:1] )
					3'b000:		ff_ppi_port_c[0] <= dbo[0];		// key_matrix Y[0]
					3'b001:		ff_ppi_port_c[1] <= dbo[0];		// key_matrix Y(1)
					3'b010:		ff_ppi_port_c[2] <= dbo[0];		// key_matrix Y(2)
					3'b011:		ff_ppi_port_c[3] <= dbo[0];		// key_matrix Y(3)
					3'b100:		ff_ppi_port_c[4] <= dbo[0];		// cassete motor on (0==On,1==Off)
					3'b101:		ff_ppi_port_c[5] <= dbo[0];		// cassete audio out
					3'b110:		ff_ppi_port_c[6] <= dbo[0];		// CAPS lamp (0==On,1==Off)
					default:	ff_ppi_port_c[7] <= dbo[0];		// 1bit sound port
					endcase
				end
			end
		end
	end

	// slot #0
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_ExpSlot0 <= 8'd0;
		end
		else begin
			// Memory mapped I/O port access on FFFFh ... expansion slot register (master mode)
			if( exp_slot_req && wrt && adr == 16'hFFFF ) begin
				if( ff_ppi_port_a[7:6] == 2'b00 ) begin
					if( slot0_expanded == 1'b1 ) begin
						ff_ExpSlot0 <= dbo;
					end
					else begin
						ff_ExpSlot0 <= 8'd0;
					end
				end
			end
		end
	end

	// slot #3
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			// primary slot : page 3 => mapper, page 2 => megasd, page 3 => megasd, page 0 => ipl-rom / xbasic
			ff_ExpSlot3 <= 8'b00_10_10_11;
		end
		else begin
			// Memory mapped I/O port access on FFFFh ... expansion slot register (master mode)
			if( exp_slot_req && wrt && adr == 16'hFFFF ) begin
				if( ff_ppi_port_a[7:6] == 2'b11 ) begin
					ff_ExpSlot3 <= dbo;
				end
			end
		end
	end

	function [1:0] func_slot_select(
		input	[1:0]	page_num,
		input	[7:0]	slot_select
	);
		case( page_num )
		2'b00:		func_slot_select = slot_select[1:0];
		2'b01:		func_slot_select = slot_select[3:2];
		2'b10:		func_slot_select = slot_select[5:4];
		default:	func_slot_select = slot_select[7:6];
		endcase
	endfunction

	assign w_caps		= ff_ppi_port_c[6];

	// primary slot number (master mode)
	assign PriSltNum	= func_slot_select( adr[15:14], ff_ppi_port_a );

	// expansion slot number : slot 0 (master mode)
	assign ExpSltNum0	= func_slot_select( adr[15:14], ff_ExpSlot0 );

	// expansion slot number : slot 3 (master mode)
	assign ExpSltNum3	= func_slot_select( adr[15:14], ff_ExpSlot3 );

	// expansion slot register read
	assign ExpDbi		= (ff_ppi_port_a[7:6] == 2'b00) ? ~ff_ExpSlot0:
						  (ff_ppi_port_a[7:6] == 2'b11) ? ~ff_ExpSlot3: 8'hFF;

	// I/O port access on A8-ABh ... PPI(8255) register read
	assign dbi			=	( adr[1:0] == 2'b00 ) ? ff_ppi_port_a: 
							( adr[1:0] == 2'b01 ) ? w_key_x_af   : 
							( adr[1:0] == 2'b10 ) ? ff_ppi_port_c: 8'hFF;

	assign RemOut		= ff_ppi_port_c[4];
	assign CmtOut		= ff_ppi_port_c[5];
	assign KeyClick		= ff_ppi_port_c[7];

	eseps2 #(
		.numlk_is_kana	( 1'b0			),
		.numlk_initial	( 1'b0			)
	) u_keyboard_controller (
		.clk21m			( clk21m		),
		.reset			( reset			),
		.clkena			( clkena		),
		.Kmap			( Kmap			),
		.Caps			( w_caps		),
		.Kana			( Kana			),
		.Paus			( Paus			),
		.Scro			( Scro			),
		.Reso			( Reso			),
		.Fkeys			( Fkeys			),
		.pPs2Clk		( pPs2Clk		),
		.pPs2Dat		( pPs2Dat		),
		.PpiPortC		( ff_ppi_port_c	),
		.pKeyX			( w_key_x		),
		.CmtScro		( CmtScro		)
//		.debug_sig		( debug_sig		)
	);
endmodule
