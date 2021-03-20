//
//  vdp_sprite.v
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
// 16th,December,2019 modified by t.hara
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

module VDP_SPRITE (
	// VDP CLOCK ... 21.477MHZ
	input			CLK21M,
	input			RESET,

	input	[ 1:0]	DOTSTATE,
	input	[ 2:0]	EIGHTDOTSTATE,

	input	[ 8:0]	DOTCOUNTERX,
	input	[ 8:0]	DOTCOUNTERYP,
	input			BWINDOW_Y,

	// VDP STATUS REGISTERS OF SPRITE
	output			PVDPS0SPCOLLISIONINCIDENCE,
	output			PVDPS0SPOVERMAPPED,
	output	[ 4:0]	PVDPS0SPOVERMAPPEDNUM,
	output	[ 8:0]	PVDPS3S4SPCOLLISIONX,
	output	[ 8:0]	PVDPS5S6SPCOLLISIONY,
	input			PVDPS0RESETREQ,
	output			PVDPS0RESETACK,
	input			PVDPS5RESETREQ,
	output			PVDPS5RESETACK,
	// VDP REGISTERS
	input			REG_R1_SP_SIZE,
	input			REG_R1_SP_ZOOM,
	input	[ 9:0]	REG_R11R5_SP_ATR_ADDR,
	input	[ 5:0]	REG_R6_SP_GEN_ADDR,
	input			REG_R8_COL0_ON,
	input			REG_R8_SP_OFF,
	input	[ 7:0]	REG_R23_VSTART_LINE,
	input	[ 2:0]	REG_R27_H_SCROLL,
	input			SPMODE2,
	input			VRAMINTERLEAVEMODE,

	output			SPVRAMACCESSING,

	input	[ 7:0]	PRAMDAT,
	output	[16:0]	PRAMADR,

	output			SPCOLOROUT,				//	0: Transparent, 1: Active pixcel
	output	[ 3:0]	SPCOLORCODE				//	Active pixel color
);
	wire	[16:0]	w_y_test_vram_address;

	localparam		sp_state_idle	= 2'd0;
	localparam		sp_state_y_test	= 2'd1;
	localparam		sp_state_draw	= 2'd2;
	reg		[ 1:0]	ff_sp_state;
	wire			w_sp_y_test_state;
	wire			w_sp_draw_state;

	wire	[ 8:0]	w_current_y;
	wire			w_sp_en;
	reg				ff_sp_en;
	reg				ff_vram_access_enable;
	wire			w_line_top;
	wire			w_hblank_top;
	wire			w_draw_end;

	reg		[16:0]	ff_vram_address;
	wire	[16:0]	w_render_read_address;

	reg		[9:0]	ff_attribute_table_address;
	reg				ff_vdp_s0_reset_ack;
	reg				ff_vdp_s5_reset_ack;
	wire			w_vdp_s0_reset_timing;
	wire			w_vdp_s5_reset_timing;

	wire	[ 2:0]	w_current_render_sp;
	wire	[ 4:0]	w_render_sp;
	wire	[ 3:0]	w_render_sp_num;
	reg		[ 5:0]	ff_pattern_gentbl_address;
	reg		[ 7:0]	ff_r23_vstart_line;

	wire	[ 6:0]	w_draw_xeven_adr;
	wire	[ 6:0]	w_draw_xodd_adr;
	wire			w_draw_xeven_write;
	wire			w_draw_xodd_write;
	wire	[ 7:0]	w_draw_xeven_pixel;
	wire	[ 7:0]	w_draw_xodd_pixel;

	wire	[ 6:0]	w_display_adr;
	wire			w_display_we;
	wire			w_display_en;

	wire	[6:0]	w_line_buffer_xeven_adr;
	wire			w_line_buffer_xeven_we;
	wire	[7:0]	w_line_buffer_xeven_d;
	wire	[7:0]	w_line_buffer_xeven_q;

	wire	[6:0]	w_line_buffer_xodd_adr;
	wire			w_line_buffer_xodd_we;
	wire	[7:0]	w_line_buffer_xodd_d;
	wire	[7:0]	w_line_buffer_xodd_q;

	// --------------------------------------------------------------------
	//	machine state
	// --------------------------------------------------------------------
	assign w_line_top		= ((DOTSTATE == 2'b10) && (DOTCOUNTERX == 9'b1_1111_1111 )) ? 1'b1 : 1'b0;
	assign w_hblank_top		= ((DOTSTATE == 2'b10) && (DOTCOUNTERX == 9'd256)         ) ? 1'b1 : 1'b0;
	assign w_draw_end		= ((DOTSTATE == 2'b10) && (DOTCOUNTERX ==(9'd256 + 9'd64))) ? 1'b1 : 1'b0;

	assign w_sp_en			= (~REG_R8_SP_OFF) & BWINDOW_Y;

	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			ff_sp_state				<= sp_state_idle;
			ff_vram_access_enable	<= 1'b0;
		end
		else if( w_line_top ) begin
			ff_sp_state				<= sp_state_y_test;
			ff_vram_access_enable	<= w_sp_en;
		end
		else if( w_hblank_top ) begin
			ff_sp_state				<= sp_state_draw;
			ff_vram_access_enable	<= ff_sp_en;
		end
		else if( w_draw_end ) begin
			ff_sp_state				<= sp_state_idle;
			ff_vram_access_enable	<= 1'b0;
		end
		else begin
			//	hold
		end
	end

	assign w_sp_y_test_state	= (ff_sp_state == sp_state_y_test) ? 1'b1: 1'b0;
	assign w_sp_draw_state		= (ff_sp_state == sp_state_draw)   ? 1'b1: 1'b0;

	always @( posedge CLK21M ) begin
		if( (DOTSTATE == 2'b01) && (DOTCOUNTERX == 9'd0) ) begin
			ff_sp_en	<= w_sp_en;
		end
		else begin
			//	hold
		end
	end

	assign w_current_y	= DOTCOUNTERYP + { 1'b0, ff_r23_vstart_line };

	// --------------------------------------------------------------------
	//	VRAM Access
	// --------------------------------------------------------------------
	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			ff_vram_address <= 17'd0;
		end
		else if( (ff_sp_state == sp_state_y_test) && (DOTSTATE == 2'b11) && (EIGHTDOTSTATE == 3'd5) ) begin
			ff_vram_address <= w_y_test_vram_address;
		end
		else if( (ff_sp_state == sp_state_draw) && (DOTSTATE == 2'b11) ) begin
			ff_vram_address <= w_render_read_address;
		end
	end

	assign SPVRAMACCESSING	= ff_vram_access_enable;
	assign PRAMADR			= VRAMINTERLEAVEMODE ? { ff_vram_address[0], ff_vram_address[16:1] } : ff_vram_address;

	// --------------------------------------------------------------------
	//	Register latch
	// --------------------------------------------------------------------
	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			ff_vdp_s0_reset_ack <= 1'b0;
			ff_vdp_s5_reset_ack <= 1'b0;
		end
		else begin
			ff_vdp_s0_reset_ack <= PVDPS0RESETREQ;
			ff_vdp_s5_reset_ack <= PVDPS5RESETREQ;
		end
	end

	assign w_vdp_s0_reset_timing	= (PVDPS0RESETREQ != ff_vdp_s0_reset_ack) ? 1'b1 : 1'b0;
	assign w_vdp_s5_reset_timing	= (PVDPS5RESETREQ != ff_vdp_s5_reset_ack) ? 1'b1 : 1'b0;
	assign PVDPS0RESETACK			= ff_vdp_s0_reset_ack;
	assign PVDPS5RESETACK			= ff_vdp_s5_reset_ack;

	always @( posedge CLK21M ) begin
		if( (DOTSTATE == 2'b01) && (DOTCOUNTERX == 9'd0) ) begin
			if( !SPMODE2 ) begin
				ff_attribute_table_address <=   REG_R11R5_SP_ATR_ADDR[ 9:0];
			end
			else begin
				ff_attribute_table_address <= { REG_R11R5_SP_ATR_ADDR[ 9:2], 2'b00 };
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge CLK21M ) begin
		if( (DOTSTATE == 2'b01) && (DOTCOUNTERX == 9'd0) ) begin
			ff_pattern_gentbl_address	<= REG_R6_SP_GEN_ADDR;
			ff_r23_vstart_line			<= REG_R23_VSTART_LINE;
		end
		else begin
			//	hold
		end
	end

	// --------------------------------------------------------------------
	//	Y test
	// --------------------------------------------------------------------
	vdp_sprite_y_test u_sprite_y_test (
		.clk21m							( CLK21M						),
		.reset							( RESET							),
		.dot_state						( DOTSTATE						),
		.eight_dot_state				( EIGHTDOTSTATE					),
		.sp_y_test_state				( w_sp_y_test_state				),
		.dot_counter_x					( DOTCOUNTERX					),
		.current_y						( w_current_y					),
		.vdp_s0_reset_timing			( w_vdp_s0_reset_timing			),
		.vdp_s0_sp_overmapped			( PVDPS0SPOVERMAPPED			),
		.vdp_s0_sp_overmapped_num		( PVDPS0SPOVERMAPPEDNUM			),
		.reg_r1_sp_size					( REG_R1_SP_SIZE				),
		.reg_r1_sp_zoom					( REG_R1_SP_ZOOM				),
		.sp_mode2						( SPMODE2						),
		.attribute_table_address		( ff_attribute_table_address	),
		.current_render_sp				( w_current_render_sp			),
		.render_sp						( w_render_sp					),
		.render_sp_num					( w_render_sp_num				),
		.vram_q							( PRAMDAT						),
		.vram_a							( w_y_test_vram_address			)
	);

	// --------------------------------------------------------------------
	//	render sprite
	// --------------------------------------------------------------------
	vdp_sprite_draw u_sprite_draw (
		.clk21m							( CLK21M						),
		.reset							( RESET							),
		.dot_state						( DOTSTATE						),
		.eight_dot_state				( EIGHTDOTSTATE					),
		.sp_draw_state					( w_sp_draw_state				),
		.sp_en							( ff_sp_en						),
		.dot_counter_x					( DOTCOUNTERX					),
		.current_y						( w_current_y					),
		.attribute_table_address		( ff_attribute_table_address	),
		.pattern_gentbl_address			( ff_pattern_gentbl_address		),
		.vdp_s0_reset_timing			( w_vdp_s0_reset_timing			),
		.vdp_s5_reset_timing			( w_vdp_s5_reset_timing			),
		.current_render_sp				( w_current_render_sp			),
		.render_sp						( w_render_sp					),
		.render_sp_num					( w_render_sp_num				),
		.draw_xeven_adr					( w_draw_xeven_adr				),
		.draw_xodd_adr					( w_draw_xodd_adr				),
		.draw_xeven_write				( w_draw_xeven_write			),
		.draw_xodd_write				( w_draw_xodd_write				),
		.draw_xeven_pixel				( w_draw_xeven_pixel			),
		.draw_xodd_pixel				( w_draw_xodd_pixel				),
		.line_buffer_xeven_q			( w_line_buffer_xeven_q			),
		.line_buffer_xodd_q				( w_line_buffer_xodd_q			),
		.vdp_s0_sp_collision_incidence	( PVDPS0SPCOLLISIONINCIDENCE	),
		.vdp_s3_s4_sp_collision_x		( PVDPS3S4SPCOLLISIONX			),
		.vdp_s5_s6_sp_collision_y		( PVDPS5S6SPCOLLISIONY			),
		.reg_r1_sp_size					( REG_R1_SP_SIZE				),
		.reg_r1_sp_zoom					( REG_R1_SP_ZOOM				),
		.reg_r8_col0_on					( REG_R8_COL0_ON				),
		.sp_mode2						( SPMODE2						),
		.vram_q							( PRAMDAT						),
		.vram_a							( w_render_read_address			)
	);

	// --------------------------------------------------------------------
	//	display
	// --------------------------------------------------------------------
	vdp_sprite_display u_sprite_display (
		.reset							( RESET							),
		.clk21m							( CLK21M						),
		.dot_state						( DOTSTATE						),
		.dot_counter_x					( DOTCOUNTERX					),
		.sp_color_out					( SPCOLOROUT					),
		.sp_color_code					( SPCOLORCODE					),
		.sp_display_en					( w_display_en					),
		.line_buffer_display_adr		( w_display_adr					),
		.line_buffer_display_we			( w_display_we					),
		.line_buffer_xeven_q			( w_line_buffer_xeven_q			),
		.line_buffer_xodd_q				( w_line_buffer_xodd_q			),
		.reg_r27_h_scroll				( REG_R27_H_SCROLL				)
	);

	// --------------------------------------------------------------------
	//	line buffer
	//
	//	data bits
	//		[7] ..... 1: sprite is found. 0: sprite is not found.
	//		[6:4] ... last sprite number
	//		[3:0] ... pixel color
	// --------------------------------------------------------------------

	//                           	                    display       : draw
	assign w_line_buffer_xeven_adr	= w_display_en ? w_display_adr : w_draw_xeven_adr;
	assign w_line_buffer_xodd_adr	= w_display_en ? w_display_adr : w_draw_xodd_adr;

	assign w_line_buffer_xeven_d	= w_display_en ? 8'd0          : w_draw_xeven_pixel;
	assign w_line_buffer_xodd_d		= w_display_en ? 8'd0          : w_draw_xodd_pixel;

	assign w_line_buffer_xeven_we	= w_display_en ? w_display_we  : w_draw_xeven_write;
	assign w_line_buffer_xodd_we	= w_display_en ? w_display_we  : w_draw_xodd_write;

	vdp_sprite_line_buffer u_line_buffer_xeven (
		.clk21m		( CLK21M					),
		.adr		( w_line_buffer_xeven_adr	),
		.we			( w_line_buffer_xeven_we	),
		.d			( w_line_buffer_xeven_d		),
		.q			( w_line_buffer_xeven_q		)
	);

	vdp_sprite_line_buffer u_line_buffer_xodd (
		.clk21m		( CLK21M					),
		.adr		( w_line_buffer_xodd_adr	),
		.we			( w_line_buffer_xodd_we		),
		.d			( w_line_buffer_xodd_d		),
		.q			( w_line_buffer_xodd_q		)
	);

endmodule
