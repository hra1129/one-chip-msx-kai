//
//  vdp_hvcounter.vhd
//   horizontal and vertical counter of ESE-VDP.
//
//  Copyright (C) 2000-2006 Kunihiko Ohnaka
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
//  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//-----------------------------------------------------------------------------
//  History
//  Jan/21th/2020
//      -- Added updated history.
//      -- Converted to VerilogHDL from VHDL by t.hara
//
//  April/22th/2020
//      -- Added bit-width to localparam
//

module vdp_hvcounter (
		input			reset,
		input			clk21m,

		output	[10:0]	h_cnt,
		output	[ 9:0]	v_cnt_in_field,
		output	[10:0]	v_cnt_in_frame,
		output			field,
		output			h_blank,
		output			v_blank,

		input			pal_mode,
		input			interlace_mode,
		input			y212_mode,
		input	[ 6:0]	offset_y
	);

	// flip flop
	reg		[10:0]	ff_h_cnt;
	reg		[ 9:0]	ff_v_cnt_in_field;
	reg				ff_field;
	reg		[10:0]	ff_v_cnt_in_frame;
	reg				ff_h_blank;
	reg				ff_v_blank;
	reg				ff_pal_mode;
	reg				ff_interlace_mode;

	// wire
	wire			w_h_cnt_half;
	wire			w_h_cnt_end;
	wire	[ 9:0]	w_field_end_cnt;
	wire			w_field_end;
	wire	[ 1:0]	w_display_mode;
	wire	[ 1:0]	w_line_mode;
	wire			w_h_blank_start;
	wire			w_h_blank_end;
	wire			w_v_blanking_start;
	wire			w_v_blanking_end;
	wire	[ 8:0]	w_v_sync_intr_start_line;

	localparam		clocks_per_line = 1368;
	localparam		led_tv_x_ntsc = (-3);
	localparam		led_tv_y_ntsc = 1;
	localparam		led_tv_x_pal = (-2);
	localparam		led_tv_y_pal = 3;
	localparam		h_blank_start = 256;
	localparam		left_border = h_blank_start + 342;
	localparam		v_blanking_start_192_ntsc = 9'd240;
	localparam		v_blanking_start_212_ntsc = 9'd250;
	localparam		v_blanking_start_192_pal = 9'd263;
	localparam		v_blanking_start_212_pal = 9'd273;

	assign h_cnt				= ff_h_cnt;
	assign v_cnt_in_field		= ff_v_cnt_in_field;
	assign field				= ff_field;
	assign v_cnt_in_frame		= ff_v_cnt_in_frame;
	assign h_blank				= ff_h_blank;
	assign v_blank				= ff_v_blank;

	//////////////////////////////////////////////////////////////////////////
	//	v synchronize mode change
	//////////////////////////////////////////////////////////////////////////
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_pal_mode			<= 1'b0;
			ff_interlace_mode	<= 1'b0;
		end
		else if( (w_h_cnt_half || w_h_cnt_end) && w_field_end && ff_field ) begin
			ff_pal_mode			<= pal_mode;
			ff_interlace_mode	<= interlace_mode;
		end
	end

	//////////////////////////////////////////////////////////////////////////
	//	horizontal counter
	//////////////////////////////////////////////////////////////////////////
	assign w_h_cnt_half		=	( ff_h_cnt == ((clocks_per_line/2) - 1) ) ? 1'b1 : 1'b0;
	assign w_h_cnt_end		=	( ff_h_cnt == ( clocks_per_line    - 1) ) ? 1'b1 : 1'b0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_h_cnt <= 11'd0;
		end
		else if( w_h_cnt_end ) begin
			ff_h_cnt <= 11'd0;
		end
		else begin
			ff_h_cnt <= ff_h_cnt + 11'd1;
		end
	end

	//////////////////////////////////////////////////////////////////////////
	//	vertical counter
	//////////////////////////////////////////////////////////////////////////
	assign w_display_mode	=	ff_interlace_mode & ff_pal_mode;

	
	function [9:0] sel_field_end_cnt;
		input	[1:0]	w_display_mode;

		case( w_display_mode )
			2'b00:		sel_field_end_cnt = 10'd523;
			2'b10:		sel_field_end_cnt = 10'd524;
			2'b01:		sel_field_end_cnt = 10'd625;
			2'b11:		sel_field_end_cnt = 10'd624;
			default:	sel_field_end_cnt = 10'dx;
		endcase
	endfunction

	assign w_field_end_cnt	= sel_field_end_cnt( w_display_mode );
	assign w_field_end		= ( ff_v_cnt_in_field == w_field_end_cnt ) ? 1'b1 : 1'b0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_v_cnt_in_field	<= 10'd0;
		end
		else if( w_h_cnt_half || w_h_cnt_end ) begin
			if( w_field_end ) begin
				ff_v_cnt_in_field <= 10'd0;
			end
			else begin
				ff_v_cnt_in_field <= ff_v_cnt_in_field + 10'd1;
			end
		end
	end

	//////////////////////////////////////////////////////////////////////////
	//	field id
	//////////////////////////////////////////////////////////////////////////
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_field <= 1'b0;
		end
		else if( w_h_cnt_half || w_h_cnt_end ) begin
			if( w_field_end ) begin
				ff_field <= ~ff_field;
			end
		end
	end

	//////////////////////////////////////////////////////////////////////////
	//	vertical counter in frame
	//////////////////////////////////////////////////////////////////////////
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_v_cnt_in_frame	<= 11'd0;
		end
		else if( w_h_cnt_half || w_h_cnt_end ) begin
			if( w_field_end && ff_field ) begin
				ff_v_cnt_in_frame	<= 11'd0;
			end
			else begin
				ff_v_cnt_in_frame	<= ff_v_cnt_in_frame + 11'd1;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////-
	// h blanking
	////////////////////////////////////////////////////////////////////////////-
	assign w_h_blank_start		= ( ff_h_cnt == h_blank_start ) ? 1'b1 : 1'b0;
	assign w_h_blank_end		= ( ff_h_cnt == left_border   ) ? 1'b1 : 1'b0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_h_blank <= 1'b0;
		end
		else if( w_h_blank_start ) begin
			ff_h_blank <= 1'b1;
		end
		else if( w_h_blank_end ) begin
			ff_h_blank <= 1'b0;
		end
	end

	////////////////////////////////////////////////////////////////////////////-
	// v blanking
	////////////////////////////////////////////////////////////////////////////-
	assign w_line_mode = y212_mode & ff_pal_mode;

	function [8:0] sel_v_sync_intr_start_line;
		input	[1:0]	w_line_mode;

		case( w_line_mode )
			2'b00:		sel_v_sync_intr_start_line = v_blanking_start_192_ntsc;
			2'b10:		sel_v_sync_intr_start_line = v_blanking_start_212_ntsc;
			2'b01:		sel_v_sync_intr_start_line = v_blanking_start_192_pal;
			2'b11:		sel_v_sync_intr_start_line = v_blanking_start_212_pal;
			default:	sel_v_sync_intr_start_line = 9'dx;
		endcase
	endfunction
	assign w_v_sync_intr_start_line	= sel_v_sync_intr_start_line( w_line_mode );

	assign w_v_blanking_end		=	( (ff_v_cnt_in_field == { 2'b00, (offset_y + led_tv_y_ntsc + 8), (ff_field & ff_interlace_mode)} && !ff_pal_mode) ||
									  (ff_v_cnt_in_field == { 2'b00, (offset_y + led_tv_y_pal  + 8), (ff_field & ff_interlace_mode)} &&  ff_pal_mode) ) ? 1'b1 : 1'b0;
	assign w_v_blanking_start	=	( (ff_v_cnt_in_field == {(w_v_sync_intr_start_line + led_tv_y_ntsc), (ff_field & ff_interlace_mode)} && !ff_pal_mode) ||
									  (ff_v_cnt_in_field == {(w_v_sync_intr_start_line + led_tv_y_pal ), (ff_field & ff_interlace_mode)} &&  ff_pal_mode) ) ? 1'b1 : 1'b0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_v_blank <= 1'b0;
		end
		else if( w_h_blank_end ) begin
			if( w_v_blanking_end ) begin
				ff_v_blank <= 1'b0;
			end
			else if( w_v_blanking_start ) begin
				ff_v_blank <= 1'b1;
			end
		end
	end
endmodule
