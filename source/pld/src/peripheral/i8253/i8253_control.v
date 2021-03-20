//
// i8253_control.v
//   Timer Device
//   Revision 1.00
//
// Copyright (c) 2020 Takayuki Hara
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
// ----------------------------------------------------------------------------
//	Update history
//	14th, February, 2020
//		First release by t.hara
//

module i8253_control #(
	parameter		p_id = 2'd0
) (
	input			reset,
	input			clk21m,

	input			clk_en,
	input			clk,

	//	BUS interface
	input			cs,
	input			rd,
	input			wr,
	input	[ 1:0]	a,
	input	[ 7:0]	d,
	output	[ 7:0]	q,

	input	[15:0]	counter,
	output			wr_cw,
	output			wr_lsb,
	output			wr_msb,
	output			wr_trigger,
	output	[ 7:0]	wr_d,
	output			mode0,
	output			mode1,
	output			mode2,
	output			mode3,
	output			mode4,
	output			mode5,
	output			bcd
);
	wire			w_clk_rise_edge;
	wire	[1:0]	w_sc;
	wire	[1:0]	w_rw;
	wire	[2:0]	w_m;
	wire			w_bcd;
	wire			w_wr_cw;
	wire			w_wr_lsb;
	wire			w_wr_msb;
	wire			w_wr_trigger;
	wire	[7:0]	w_wr_d;
	reg		[1:0]	ff_rw;
	reg		[2:0]	ff_m;
	reg				ff_bcd;
	reg				ff_sel_msb_wr;
	reg				ff_sel_msb_rd;
	reg				ff_pre_wr_cw;
	reg				ff_pre_wr_lsb;
	reg				ff_pre_wr_msb;
	reg				ff_pre_wr_trigger;
	reg		[ 7:0]	ff_pre_wr_d;
	reg				ff_wr_cw;
	reg				ff_wr_lsb;
	reg				ff_wr_msb;
	reg				ff_wr_trigger;
	reg		[ 7:0]	ff_wr_d;
	reg		[15:0]	ff_counter;

	assign w_clk_rise_edge	= ~clk;

	assign w_wr_cw			=(( a == 2'b11) && (w_sc == p_id)) ? 1'b1: 1'b0;
	assign w_wr_lsb			=(( a == p_id ) ? ~ff_sel_msb_wr: 1'b0) | ((a == 2'b11 && w_rw == 2'b10) ? 1'b1: 1'b0);
	assign w_wr_msb			=(( a == p_id ) ?  ff_sel_msb_wr: 1'b0) | ((a == 2'b11 && w_rw == 2'b01) ? 1'b1: 1'b0);
	assign w_wr_trigger		= ( a == p_id && ( (ff_rw == 2'b11 && ff_sel_msb_wr) || (ff_rw == 2'b01) || (ff_rw == 2'b10) )) ? 1'b1: 1'b0;
	assign w_wr_d			= ( a == 2'b11) ?  8'd0: d;

	assign w_sc				= d[7:6];
	assign w_rw				= d[5:4];
	assign w_m				= d[3:1];
	assign w_bcd			= d[0];

	assign q				= ((a == p_id ) && rd &&  ff_sel_msb_rd && cs ) ? ff_counter[15:8]:
							  ((a == p_id ) && rd && ~ff_sel_msb_rd && cs ) ? ff_counter[ 7:0]:
							  ((a == 2'b11) && rd && (w_sc == p_id) && cs ) ? { p_id, ff_rw, ff_m, ff_bcd }:
							  8'hFF;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_rw		<= 2'd0;
		end
		else if( cs && (a == 2'b11) && wr && (w_sc == p_id) ) begin
			ff_rw		<= w_rw;
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_m		<= 3'd0;
			ff_bcd		<= 1'd0;
		end
		else if( cs && (a == 2'b11) && wr && (w_sc == p_id) ) begin
			if( w_rw != 2'b00 ) begin
				ff_m		<= w_m;
				ff_bcd		<= w_bcd;
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_sel_msb_wr	<= 1'b0;
		end
		else if( cs && (a == 2'b11) && wr && (w_sc == p_id) ) begin
			ff_sel_msb_wr	<= (w_rw == 2'b10) ? 1'b1: 1'b0;
		end
		else if( cs && (a == p_id) && wr ) begin
			if( ff_rw == 2'b11 ) begin
				ff_sel_msb_wr	<= ~ff_sel_msb_wr;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_sel_msb_rd	<= 1'b0;
		end
		else if( cs && (a == 2'b11) && rd && (w_sc == p_id) ) begin
			ff_sel_msb_rd	<= (w_rw == 2'b10) ? 1'b1: 1'b0;
		end
		else if( cs && (a == p_id) && rd ) begin
			if( ff_rw == 2'b11 ) begin
				ff_sel_msb_rd	<= ~ff_sel_msb_rd;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge clk21m ) begin
		if( reset ) begin
			ff_counter	<= 16'd0;
		end
		if( cs && clk_en && w_clk_rise_edge ) begin
			if( (a == 2'b11) && wr && (w_sc == p_id) && (w_rw == 2'b00) ) begin
				ff_counter	<= counter;
			end
			else begin
				//	hold
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_pre_wr_cw		<= 1'b0;
			ff_pre_wr_lsb		<= 1'b0;
			ff_pre_wr_msb		<= 1'b0;
			ff_pre_wr_trigger	<= 1'b0;
			ff_pre_wr_d			<= 8'd0;
		end
		else if( clk_en && w_clk_rise_edge ) begin
			ff_pre_wr_cw		<= 1'b0;
			ff_pre_wr_lsb		<= 1'b0;
			ff_pre_wr_msb		<= 1'b0;
			ff_pre_wr_trigger	<= 1'b0;
			ff_pre_wr_d			<= 8'd0;
		end
		else if( cs && wr ) begin
			ff_pre_wr_cw		<= w_wr_cw;
			ff_pre_wr_lsb		<= w_wr_lsb;
			ff_pre_wr_msb		<= w_wr_msb;
			ff_pre_wr_trigger	<= w_wr_trigger;
			ff_pre_wr_d			<= w_wr_d;
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_wr_cw		<= 1'b0;
			ff_wr_lsb		<= 1'b0;
			ff_wr_msb		<= 1'b0;
			ff_wr_trigger	<= 1'b0;
			ff_wr_d			<= 8'd0;
		end
		else if( clk_en && w_clk_rise_edge ) begin
			if( cs && wr ) begin
				ff_wr_cw		<= w_wr_cw;
				ff_wr_lsb		<= w_wr_lsb;
				ff_wr_msb		<= w_wr_msb;
				ff_wr_trigger	<= w_wr_trigger;
				ff_wr_d			<= w_wr_d;
			end
			else begin
				ff_wr_cw		<= ff_pre_wr_cw;
				ff_wr_lsb		<= ff_pre_wr_lsb;
				ff_wr_msb		<= ff_pre_wr_msb;
				ff_wr_trigger	<= ff_pre_wr_trigger;
				ff_wr_d			<= ff_pre_wr_d;
			end
		end
		else begin
			//	hold
		end
	end

	assign wr_cw		= ff_wr_cw;
	assign wr_lsb		= ff_wr_lsb;
	assign wr_msb		= ff_wr_msb;
	assign wr_trigger	= ff_wr_trigger;
	assign wr_d			= ff_wr_d;

	assign bcd			= ff_bcd;
	assign mode0		= (ff_m      == 3'd0) ? 1'b1 : 1'b0;
	assign mode1		= (ff_m      == 3'd1) ? 1'b1 : 1'b0;
	assign mode2		= (ff_m[1:0] == 2'd2) ? 1'b1 : 1'b0;
	assign mode3		= (ff_m[1:0] == 2'd3) ? 1'b1 : 1'b0;
	assign mode4		= (ff_m      == 3'd4) ? 1'b1 : 1'b0;
	assign mode5		= (ff_m      == 3'd5) ? 1'b1 : 1'b0;
endmodule
