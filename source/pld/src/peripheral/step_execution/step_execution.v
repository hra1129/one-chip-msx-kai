//
// step_execution.v
//	 1chipMSX step execution device
//	 Revision 1.00
//
// Copyright (c) 2020 Takayuki Hara
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
//	July/28th/2020 first release by t.hara
//

module step_execution (
	input			reset,
	input			clk21m,

	input	[15:0]	z80_address,
	input	[15:0]	r800_address,
	input			cpu_is_r800,

	input			activate_step_execution,	//	pulse

	output			step_execute,
	output			step_execute_en,

	input			p_toggle_sexec_sw,			//	0: pressed, 1: unpressed
	input			p_step_sexec_sw,			//	0: pressed, 1: unpressed

	output	[6:0]	p_7seg_cpu_type,
	output	[6:0]	p_7seg_address_0,
	output	[6:0]	p_7seg_address_1,
	output	[6:0]	p_7seg_address_2,
	output	[6:0]	p_7seg_address_3
);
	//        		        	     6543210
	localparam		c_7seg_z	= 7'b0100100;
	localparam		c_7seg_r	= 7'b0101111;
	localparam		c_7seg_0	= 7'b1000000;
	localparam		c_7seg_1	= 7'b1111001;
	localparam		c_7seg_2	= 7'b0100100;
	localparam		c_7seg_3	= 7'b0110000;
	localparam		c_7seg_4	= 7'b0011001;
	localparam		c_7seg_5	= 7'b0010010;
	localparam		c_7seg_6	= 7'b0000010;
	localparam		c_7seg_7	= 7'b1111000;
	localparam		c_7seg_8	= 7'b0000000;
	localparam		c_7seg_9	= 7'b0010000;
	localparam		c_7seg_a	= 7'b0001000;
	localparam		c_7seg_b	= 7'b0000011;
	localparam		c_7seg_c	= 7'b1000110;
	localparam		c_7seg_d	= 7'b0100001;
	localparam		c_7seg_e	= 7'b0000110;
	localparam		c_7seg_f	= 7'b0001110;

	reg		[20:0]	ff_counter;
	reg				ff_last_toggle_sexec_sw;
	reg				ff_last_step_sexec_sw;
	reg				ff_d1_toggle_sexec_sw;
	reg				ff_d1_step_sexec_sw;
	reg				ff_se_enable;
	wire			w_toggle;
	wire			w_step;
	wire			w_7seg_en;
	wire	[15:0]	w_address;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_counter <= 21'd0;
		end
		else begin
			ff_counter <= ff_counter + 21'd1;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_last_toggle_sexec_sw	<= 1'b0;
			ff_last_step_sexec_sw	<= 1'b0;
			ff_d1_toggle_sexec_sw	<= 1'b0;
			ff_d1_step_sexec_sw		<= 1'b0;
		end
		else begin
			ff_last_toggle_sexec_sw	<= ~p_toggle_sexec_sw;
			ff_last_step_sexec_sw	<= ~p_step_sexec_sw;
			ff_d1_toggle_sexec_sw	<= ff_last_toggle_sexec_sw;
			ff_d1_step_sexec_sw		<= ff_last_step_sexec_sw;
		end
	end

	assign w_toggle		= ff_last_toggle_sexec_sw & ~ff_d1_toggle_sexec_sw;
	assign w_step		= ff_last_step_sexec_sw   & ~ff_d1_step_sexec_sw;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_se_enable <= 1'b0;
		end
		else begin
			if( w_toggle ) begin
				ff_se_enable <= ~ff_se_enable;
			end
			else if( activate_step_execution ) begin
				ff_se_enable <= 1'b1;
			end
			else begin
				//	hold
			end
		end
	end

	assign w_7seg_en	= ff_se_enable;

	function [6:0] set_7seg_pattern(
		input	[3:0]	d
	);
		case( d )
		4'd0:
			set_7seg_pattern	= c_7seg_0;
		4'd1:
			set_7seg_pattern	= c_7seg_1;
		4'd2:
			set_7seg_pattern	= c_7seg_2;
		4'd3:
			set_7seg_pattern	= c_7seg_3;
		4'd4:
			set_7seg_pattern	= c_7seg_4;
		4'd5:
			set_7seg_pattern	= c_7seg_5;
		4'd6:
			set_7seg_pattern	= c_7seg_6;
		4'd7:
			set_7seg_pattern	= c_7seg_7;
		4'd8:
			set_7seg_pattern	= c_7seg_8;
		4'd9:
			set_7seg_pattern	= c_7seg_9;
		4'd10:
			set_7seg_pattern	= c_7seg_a;
		4'd11:
			set_7seg_pattern	= c_7seg_b;
		4'd12:
			set_7seg_pattern	= c_7seg_c;
		4'd13:
			set_7seg_pattern	= c_7seg_d;
		4'd14:
			set_7seg_pattern	= c_7seg_e;
		default:
			set_7seg_pattern	= c_7seg_f;
		endcase
	endfunction

	assign w_address			= ( cpu_is_r800 ) ? r800_address : z80_address;

	assign p_7seg_cpu_type		= ( cpu_is_r800 ) ? c_7seg_r : c_7seg_z;
	assign p_7seg_address_0		= ( w_7seg_en   ) ? set_7seg_pattern( w_address[ 3: 0] ) : 7'b1111111;
	assign p_7seg_address_1		= ( w_7seg_en   ) ? set_7seg_pattern( w_address[ 7: 4] ) : 7'b1111111;
	assign p_7seg_address_2		= ( w_7seg_en   ) ? set_7seg_pattern( w_address[11: 8] ) : 7'b1111111;
	assign p_7seg_address_3		= ( w_7seg_en   ) ? set_7seg_pattern( w_address[15:12] ) : 7'b1111111;

	assign step_execute			= w_step;
	assign step_execute_en		= ff_se_enable;
endmodule
