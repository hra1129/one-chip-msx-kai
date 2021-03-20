//
//  vdp_sprite_draw.v
//    Sprite module.
//
//  Copyright (C) 2004-2006 Kunihiko Ohnaka
//  All rights reserved.
//                                     http://www.ohnaka.jp/ese-vdp/
//
//  本ソフトウェアおよび本ソフトウェアに基づいて作成された派生物は、以下の条件を
//  満たす場合に限り、再頒布および使用が許可されます。
//
//  1.ソースコード形式で再頒布する場合、上記の著作権表示、本条件一覧、および下記
//    免責条項をそのままの形で保持すること。
//  2.バイナリ形式で再頒布する場合、頒布物に付属のドキュメント等の資料に、上記の
//    著作権表示、本条件一覧、および下記免責条項を含めること。
//  3.書面による事前の許可なしに、本ソフトウェアを販売、および商業的な製品や活動
//    に使用しないこと。
//
//  本ソフトウェアは、著作権者によって「現状のまま」提供されています。著作権者は、
//  特定目的への適合性の保証、商品性の保証、またそれに限定されない、いかなる明示
//  的もしくは暗黙な保証責任も負いません。著作権者は、事由のいかんを問わず、損害
//  発生の原因いかんを問わず、かつ責任の根拠が契約であるか厳格責任であるか（過失
//  その他の）不法行為であるかを問わず、仮にそのような損害が発生する可能性を知ら
//  されていたとしても、本ソフトウェアの使用によって発生した（代替品または代用サ
//  ービスの調達、使用の喪失、データの喪失、利益の喪失、業務の中断も含め、またそ
//  れに限定されない）直接損害、間接損害、偶発的な損害、特別損害、懲罰的損害、ま
//  たは結果損害について、一切責任を負わないものとします。
//
//  Note that above Japanese version license is the formal document.
//  The following translation is only for reference.
//
//  Redistribution and use of this software or any derivative works,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above
//     copyright notice, this list of conditions and the following
//     disclaimer in the documentation and/or other materials
//     provided with the distribution.
//  3. Redistributions may not be sold, nor may they be used in a
//     commercial product or activity without specific prior written
//     permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN if ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//---------------------------------------------------------------------------
// Memo
//   Japanese comment lines are starts with "JP:".
//   JP: 日本語のコメント行は JP:を頭に付ける事にする
//
//---------------------------------------------------------------------------
// Revision History
//
// 3rd,December,2020 modified by t.hara
//   - Converted to VerilogHDL from VHDL.
//   - Separated from vdp_sprite.
//
// 10th,December,2019 modified by t.hara
//   - modified delay of Sprite attribute table address.
//
// 29th,October,2006 modified by Kunihiko Ohnaka
//   - Insert the license text.
//   - Add the document part below.
//
// 26th,August,2006 modified by Kunihiko Ohnaka
//   - latch the base addresses every eight dot cycle
//     (DRAM RAS/CAS access emulation)
//
// 20th,August,2006 modified by Kunihiko Ohnaka
//   - Change the drawing algorithm.
//   - Add sprite collision checking function.
//   - Add sprite over-mapped checking function.
//   - Many bugs are fixed, and it works fine.
//   - (first release virsion)
//
// 17th,August,2004 created by Kunihiko Ohnaka
//   - Start new sprite module implementing.
//     * This module uses Block RAMs so that shrink the
//       circuit size.
//     * Separate sprite module from vdp.vhd.
//

module vdp_sprite_draw (
	input			clk21m,
	input			reset,

	input	[ 1:0]	dot_state,
	input	[ 2:0]	eight_dot_state,
	input			sp_draw_state,
	input			sp_en,

	input	[ 8:0]	dot_counter_x,
	input	[ 8:0]	current_y,
	input	[ 9:0]	attribute_table_address,
	input	[ 5:0]	pattern_gentbl_address,

	input			vdp_s0_reset_timing,
	input			vdp_s5_reset_timing,

	output	[ 2:0]	current_render_sp,
	input	[ 4:0]	render_sp,
	input	[ 3:0]	render_sp_num,

	output	[ 6:0]	draw_xeven_adr,
	output	[ 6:0]	draw_xodd_adr,
	output			draw_xeven_write,
	output			draw_xodd_write,
	output	[ 7:0]	draw_xeven_pixel,
	output	[ 7:0]	draw_xodd_pixel,

	input	[ 7:0]	line_buffer_xeven_q,
	input	[ 7:0]	line_buffer_xodd_q,

	output			vdp_s0_sp_collision_incidence,
	output	[ 8:0]	vdp_s3_s4_sp_collision_x,
	output	[ 8:0]	vdp_s5_s6_sp_collision_y,

	input			reg_r1_sp_size,
	input			reg_r1_sp_zoom,
	input			reg_r8_col0_on,
	input			sp_mode2,

	input	[ 7:0]	vram_q,
	output	[16:0]	vram_a
);
	wire	[16:0]	w_render_read_address;

	reg		[ 2:0]	ff_current_render_sp;
	wire	[16:2]	w_attribute_address;
	wire	[16:0]	w_y_address;
	wire	[16:0]	w_x_address;
	wire	[16:0]	w_pattern_num_address;
	wire	[16:0]	w_pattern_l_address;
	wire	[16:0]	w_pattern_r_address;
	wire	[16:0]	w_color_address;
	wire	[ 7:0]	w_y_pos;
	reg		[ 3:0]	ff_render_y;
	reg		[ 7:0]	ff_render_x;
	reg		[ 7:0]	ff_render_pattern_l;
	reg		[ 7:0]	ff_render_pattern_r;
	reg		[ 7:0]	ff_render_pattern_num;
	reg		[ 3:0]	ff_render_color;
	reg				ff_render_ic;
	reg				ff_render_cc;
	reg				ff_render_ec;

	reg		[ 2:0]	ff_draw_sp_num;
	reg		[ 4:0]	ff_draw_state;
	wire			w_draw_enable_8x8_normal;
	wire			w_draw_enable_8x8_zoom;
	wire			w_draw_enable_16x16_normal;
	wire			w_draw_enable_16x16_zoom;
	wire			w_draw_enable;
	wire			w_draw_write;
	wire	[ 7:0]	w_draw_x0_pixel;
	wire	[ 7:0]	w_draw_x1_pixel;
	reg		[ 8:0]	ff_draw_x0;
	reg		[ 8:0]	ff_draw_x1;
	reg		[15:0]	ff_draw_pattern;
	reg		[ 3:0]	ff_draw_color;
	reg				ff_draw_ic;
	reg				ff_draw_cc;
	reg				ff_sp_enable;
	wire			w_sp_final;
	reg				ff_sp_final;
	wire			w_draw_pattern_x0;
	wire			w_draw_pattern_x1;
	wire	[ 7:0]	w_line_buffer_x0_q;
	wire	[ 7:0]	w_line_buffer_x1_q;
	wire			w_draw_x0_last_active;
	wire	[ 2:0]	w_draw_x0_last_sp_num;
	wire	[ 3:0]	w_draw_x0_last_color;
	wire			w_draw_x1_last_active;
	wire	[ 2:0]	w_draw_x1_last_sp_num;
	wire	[ 3:0]	w_draw_x1_last_color;
	wire			w_draw_opacity;

	reg				ff_vdp_s0_sp_collision_incidence;
	reg				ff_vdp_s3456_sp_collision_xy_hold;
	reg		[ 8:0]	ff_vdp_s3_s4_sp_collision_x;
	reg		[ 8:0]	ff_vdp_s5_s6_sp_collision_y;
	wire	[ 3:0]	w_next_render_sp;

	// --------------------------------------------------------------------
	//	render sprite
	// --------------------------------------------------------------------
	assign w_attribute_address		= { attribute_table_address, render_sp };
	assign w_y_address				= { w_attribute_address, 2'b00 };
	assign w_x_address				= { w_attribute_address, 2'b01 };
	assign w_pattern_num_address	= { w_attribute_address, 2'b10 };
	assign w_pattern_l_address		= ( !reg_r1_sp_size ) ? 
			{ pattern_gentbl_address, ff_render_pattern_num[7:0], ff_render_y[2:0] } :				// 8x8 mode
			{ pattern_gentbl_address, ff_render_pattern_num[7:2], 1'b0, ff_render_y };				// 16x16 mode
	assign w_pattern_r_address		= ( !reg_r1_sp_size ) ? 
			{ pattern_gentbl_address, ff_render_pattern_num[7:0], ff_render_y[2:0] } :				// 8x8 mode
			{ pattern_gentbl_address, ff_render_pattern_num[7:2], 1'b1, ff_render_y };				// 16x16 mode
	assign w_color_address			= ( !sp_mode2 ) ? 
			{ w_attribute_address, 2'b11 } :														// Sprite mode 1 (TMS9918 compatible)
			{ attribute_table_address[9:3], ~attribute_table_address[2], render_sp, ff_render_y };	// Sprite mode 2 (V9938/9958)

	assign w_next_render_sp			= { 1'b0, ff_current_render_sp } + 4'd1;

	always @( posedge clk21m ) begin
		if( (dot_counter_x == 9'd256) && (dot_state == 2'b10) ) begin
			ff_current_render_sp <= 3'd0;
		end
		else if( sp_draw_state && (dot_state == 2'b11) && (eight_dot_state == 3'd6) ) begin
			if( (w_next_render_sp != render_sp_num) && (render_sp_num != 4'd0) ) begin
				ff_current_render_sp <= w_next_render_sp[2:0];
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
			ff_sp_enable	<= 1'b0;
		end
		else if( (dot_state == 2'b11) && (eight_dot_state == 3'd6) ) begin
			if( (render_sp_num == 4'd0) || ff_sp_final ) begin
				ff_sp_enable	<= 1'b0;
			end
			else begin
				ff_sp_enable	<= sp_draw_state & sp_en;
			end
		end
		else begin
			//	hold
		end
	end

	assign w_sp_final	= (w_next_render_sp == render_sp_num) ? 1'b1 : 1'b0;
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_sp_final		<= 1'b0;
		end
		else if( (dot_state == 2'b11) && (dot_counter_x == 9'd256) ) begin
			ff_sp_final		<= 1'b0;
		end
		else if( (dot_state == 2'b11) && (dot_counter_x == 9'd262) ) begin
			ff_sp_final		<= w_sp_final;
		end
		else if( (dot_state == 2'b11) && (eight_dot_state == 3'd6) ) begin
			if( w_sp_final ) begin
				ff_sp_final		<= 1'b1;
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	function [16:0] sel_render_read_address;
		input	[ 2:0]	eight_dot_state;
		input	[16:0]	w_y_address;
		input	[16:0]	w_x_address;
		input	[16:0]	w_pattern_num_address;
		input	[16:0]	w_pattern_l_address;
		input	[16:0]	w_pattern_r_address;
		input	[16:0]	w_color_address;

		case( eight_dot_state )
		3'd0:		sel_render_read_address = w_y_address;
		3'd1:		sel_render_read_address = w_x_address;
		3'd2:		sel_render_read_address = w_pattern_num_address;
		3'd3:		sel_render_read_address = w_pattern_l_address;
		3'd4:		sel_render_read_address = w_pattern_r_address;
		3'd5:		sel_render_read_address = w_color_address;
		default:	sel_render_read_address = 17'd0;
		endcase
	endfunction

	assign w_render_read_address	= sel_render_read_address( 
		eight_dot_state, 
		w_y_address, 
		w_x_address, 
		w_pattern_num_address, 
		w_pattern_l_address, 
		w_pattern_r_address, 
		w_color_address );
	assign w_y_pos					= current_y - vram_q;

	always @( posedge clk21m ) begin
		if( sp_draw_state && (dot_state == 2'b01) ) begin
			case( eight_dot_state )
			3'd1: begin
				ff_render_y <= ( !reg_r1_sp_zoom ) ? w_y_pos[3:0] : w_y_pos[4:1];
			end
			3'd2: begin
				ff_render_x <= vram_q;
			end
			3'd3: begin
				ff_render_pattern_num <= vram_q;
			end
			3'd4: begin
				ff_render_pattern_l <= vram_q;
			end
			3'd5: begin
				ff_render_pattern_r <= vram_q;
			end
			3'd6: begin
				ff_render_color <= vram_q[3:0];
				ff_render_ic <= vram_q[5] & sp_mode2;
				ff_render_cc <= vram_q[6] & sp_mode2;
				ff_render_ec <= vram_q[7];
			end
			endcase
		end
		else begin
			//	hold
		end
	end

	always @( posedge clk21m ) begin
		if( ff_sp_enable ) begin
			if( (dot_state == 2'b11) && (eight_dot_state == 3'd6) ) begin
				ff_draw_state			<= 5'd0;
			end
			else begin
				ff_draw_state			<= ff_draw_state + 5'd1;
			end
		end
		else begin
			ff_draw_state			<= 5'd0;
		end
	end

	assign w_draw_enable_8x8_normal		= (ff_draw_state[4:3] == 2'b0) ? 1'b1 : 1'b0;
	assign w_draw_enable_8x8_zoom		= (ff_draw_state[4]   == 1'b0) ? 1'b1 : 1'b0;
	assign w_draw_enable_16x16_normal	= (ff_draw_state[4]   == 1'b0) ? 1'b1 : 1'b0;
	assign w_draw_enable_16x16_zoom		= 1'b1;
	assign w_draw_enable				= ( !reg_r1_sp_size && !reg_r1_sp_zoom ) ?	w_draw_enable_8x8_normal	:
										  (  reg_r1_sp_size && !reg_r1_sp_zoom ) ?	w_draw_enable_8x8_zoom		:
										  ( !reg_r1_sp_size &&  reg_r1_sp_zoom ) ?	w_draw_enable_16x16_normal	:
																					w_draw_enable_16x16_zoom;
	assign w_draw_write					=  ff_draw_state[0] & w_draw_enable & ff_sp_enable;

	assign w_draw_pattern_x0			= ff_draw_pattern[15];
	assign w_draw_pattern_x1			= (reg_r1_sp_zoom) ? ff_draw_pattern[15] : ff_draw_pattern[14];

	assign w_line_buffer_x0_q			= (ff_draw_x0[0] == 1'b0) ? line_buffer_xeven_q : line_buffer_xodd_q;
	assign w_line_buffer_x1_q			= (ff_draw_x1[0] == 1'b0) ? line_buffer_xeven_q : line_buffer_xodd_q;
	assign w_draw_x0_last_active		= w_line_buffer_x0_q[7];
	assign w_draw_x0_last_sp_num		= w_line_buffer_x0_q[6:4];
	assign w_draw_x0_last_color			= w_line_buffer_x0_q[3:0];
	assign w_draw_x1_last_active		= w_line_buffer_x1_q[7];
	assign w_draw_x1_last_sp_num		= w_line_buffer_x1_q[6:4];
	assign w_draw_x1_last_color			= w_line_buffer_x1_q[3:0];

	function [7:0] makeup_draw_pixel;
		input			w_draw_opacity;
		input			w_draw_pattern;
		input	[2:0]	ff_draw_sp_num;
		input	[3:0]	ff_draw_color;
		input			ff_draw_cc;
		input			w_draw_last_active;
		input	[2:0]	w_draw_last_sp_num;
		input	[3:0]	w_draw_last_color;

		if( !w_draw_last_active ) begin
			if( w_draw_opacity && w_draw_pattern ) begin
				makeup_draw_pixel = { 1'b1, ff_draw_sp_num, ff_draw_color };
			end
			else begin
				makeup_draw_pixel = 8'd0;
			end
		end
		else begin
			if( (!ff_draw_cc) || (ff_draw_sp_num != (w_draw_last_sp_num + 3'd1) ) ) begin
				makeup_draw_pixel = { 1'b1, w_draw_last_sp_num, w_draw_last_color };
			end
			else if( w_draw_opacity && w_draw_pattern ) begin
				makeup_draw_pixel = { 1'b1, ff_draw_sp_num, (ff_draw_color | w_draw_last_color) };
			end
			else begin
				makeup_draw_pixel = { 1'b1, ff_draw_sp_num, w_draw_last_color };
			end
		end
	endfunction

	assign w_draw_opacity		= reg_r8_col0_on | ( (ff_draw_color != 4'd0) ? 1'b1 : 1'b0 );
	assign w_draw_x0_pixel		= makeup_draw_pixel( w_draw_opacity, w_draw_pattern_x0, ff_draw_sp_num, ff_draw_color, ff_draw_cc, w_draw_x0_last_active, w_draw_x0_last_sp_num, w_draw_x0_last_color );
	assign w_draw_x1_pixel		= makeup_draw_pixel( w_draw_opacity, w_draw_pattern_x1, ff_draw_sp_num, ff_draw_color, ff_draw_cc, w_draw_x1_last_active, w_draw_x1_last_sp_num, w_draw_x1_last_color );

	assign draw_xeven_adr		= (ff_draw_x0[0] == 1'b0) ? ff_draw_x0[7:1] : ff_draw_x1[7:1];
	assign draw_xodd_adr		= (ff_draw_x0[0] == 1'b1) ? ff_draw_x0[7:1] : ff_draw_x1[7:1];

	assign draw_xeven_write		= w_draw_write & ( (ff_draw_x0[0] == 1'b0) ? ~ff_draw_x0[8] : ~ff_draw_x1[8] );
	assign draw_xodd_write		= w_draw_write & ( (ff_draw_x0[0] == 1'b1) ? ~ff_draw_x0[8] : ~ff_draw_x1[8] );

	assign draw_xeven_pixel		= (ff_draw_x0[0] == 1'b0) ? w_draw_x0_pixel : w_draw_x1_pixel;
	assign draw_xodd_pixel		= (ff_draw_x0[0] == 1'b1) ? w_draw_x0_pixel : w_draw_x1_pixel;

	always @( posedge clk21m ) begin
		if( (dot_state == 2'b11) && (eight_dot_state == 3'd6) ) begin
			if( sp_draw_state || ff_sp_enable ) begin
				ff_draw_sp_num			<= ff_current_render_sp;
				ff_draw_color			<= ff_render_color;
				ff_draw_ic				<= sp_mode2 & ff_render_ic;
				ff_draw_cc				<= sp_mode2 & ff_render_cc;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge clk21m ) begin
		if( sp_draw_state || ff_sp_enable ) begin
			if( (dot_state == 2'b11) && (eight_dot_state == 3'd6) ) begin
				ff_draw_pattern			<= { ff_render_pattern_l, ff_render_pattern_r };
			end
			else if( w_draw_write ) begin
				if( reg_r1_sp_zoom ) begin
					ff_draw_pattern			<= { ff_draw_pattern[14:0], 1'b0 };		// shift left 1 dot
				end
				else begin
					ff_draw_pattern			<= { ff_draw_pattern[13:0], 2'b0 };		// shift left 2 dots
				end
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge clk21m ) begin
		if( sp_draw_state || ff_sp_enable ) begin
			if( (dot_state == 2'b11) && (eight_dot_state == 3'd6) ) begin
				ff_draw_x0				<= ( !ff_render_ec ) ? { 1'b0, ff_render_x }        : { 1'b0, ff_render_x } - 9'd32;
				ff_draw_x1				<= ( !ff_render_ec ) ? { 1'b0, ff_render_x } + 9'd1 : { 1'b0, ff_render_x } - 9'd31;
			end
			else if( w_draw_write ) begin
				ff_draw_x0				<= ff_draw_x0 + 9'd2;
				ff_draw_x1				<= ff_draw_x1 + 9'd2;
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
			ff_vdp_s0_sp_collision_incidence <= 1'b0;
		end
		else if( vdp_s0_reset_timing ) begin
			ff_vdp_s0_sp_collision_incidence <= 1'b0;
		end
		else if( ff_sp_enable && w_draw_opacity && w_draw_write && !ff_draw_ic && w_draw_opacity ) begin
			if(      !ff_draw_cc || (ff_draw_cc && ( ff_draw_sp_num != w_draw_x0_last_sp_num + 3'b1 ) ) ) begin
				if( w_draw_x0_last_active && w_draw_pattern_x0 ) begin
					ff_vdp_s0_sp_collision_incidence <= 1'b1;
				end
			end
			else if( !ff_draw_cc || (ff_draw_cc && ( ff_draw_sp_num != w_draw_x1_last_sp_num + 3'b1 ) ) ) begin
				if( w_draw_x1_last_active && w_draw_pattern_x1 ) begin
					ff_vdp_s0_sp_collision_incidence <= 1'b1;
				end
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_vdp_s3456_sp_collision_xy_hold	<= 1'b0;
			ff_vdp_s3_s4_sp_collision_x			<= 9'd0;
			ff_vdp_s5_s6_sp_collision_y			<= 9'd0;
		end
		else if( vdp_s5_reset_timing ) begin
			ff_vdp_s3456_sp_collision_xy_hold	<= 1'b0;
			ff_vdp_s3_s4_sp_collision_x			<= 9'd0;
			ff_vdp_s5_s6_sp_collision_y			<= 9'd0;
		end
		else if( !ff_vdp_s3456_sp_collision_xy_hold && ff_sp_enable && w_draw_opacity && w_draw_write && !ff_draw_ic && w_draw_opacity ) begin
			if(      !ff_draw_cc || (ff_draw_cc && ( ff_draw_sp_num != w_draw_x0_last_sp_num + 3'b1 ) ) ) begin
				if( w_draw_x0_last_active && w_draw_pattern_x0 && !ff_draw_x0[8] ) begin
					ff_vdp_s3456_sp_collision_xy_hold	<= 1'b1;
					ff_vdp_s3_s4_sp_collision_x			<= ff_draw_x0 + 9'd12;
					ff_vdp_s5_s6_sp_collision_y			<= current_y + 9'd7;
				end
			end
			else if( !ff_draw_cc || (ff_draw_cc && ( ff_draw_sp_num != w_draw_x1_last_sp_num + 3'b1 ) ) ) begin
				if( w_draw_x1_last_active && w_draw_pattern_x1 && !ff_draw_x1[8] ) begin
					ff_vdp_s3456_sp_collision_xy_hold	<= 1'b1;
					ff_vdp_s3_s4_sp_collision_x			<= ff_draw_x1 + 9'd12;
					ff_vdp_s5_s6_sp_collision_y			<= current_y + 9'd7;
				end
			end
		end
	end

	assign vdp_s0_sp_collision_incidence	= ff_vdp_s0_sp_collision_incidence;
	assign vdp_s3_s4_sp_collision_x			= ff_vdp_s3_s4_sp_collision_x;
	assign vdp_s5_s6_sp_collision_y			= ff_vdp_s5_s6_sp_collision_y;

	assign current_render_sp				= ff_current_render_sp;

	assign vram_a							= w_render_read_address;
endmodule
