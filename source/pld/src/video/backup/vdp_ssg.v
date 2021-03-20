//
//  vdp_ssg.vhd
//   Synchronous Signal Generator of ESE-VDP.
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
//  22th,April,2020 by.thara
//  Modified bit-width for w_v_cnt_body
//  Modified ff_pre_y_cnt
//
//  08th,December,2019 by.thara
//  Added output V_CNT_IN_FIELD
//
//  30th,March,2008
//  JP: VDP.VHD から分離 by t.hara
//

module vdp_ssg (
		input			reset,
		input			clk21m,

		output	[10:0]	h_cnt,
		output	[10:0]	v_cnt,
		output	[ 9:0]	v_cnt_in_field,
		output	[ 1:0]	dotstate,
		output	[ 2:0]	eightdotstate,
		output	[ 8:0]	predotcounter_x,
		output	[ 8:0]	predotcounter_y,
		output	[ 8:0]	predotcounter_yp,
		output			pre_window_y,
		output			pre_window_y_sp,
		output			field,
		output			window_x,
		output			pvideodhclk,
		output			pvideodlclk,
		output			ivideovs_n,

		output			hd,
		output			vd,
		output			hsync,
		output			enahsync,
		output			v_blanking_start,
		output			register_hold,

		output			bwindow_x,
		output			bwindow_y,
		output			bwindow,

		input	[ 6:0]	offset_y,
		input			vdp_r9_pal_mode,
		input			reg_r9_interlace_mode,
		input			reg_r9_y_dots,
		input	[ 7:0]	reg_r18_adj,
		input	[ 7:0]	reg_r19_hsync_int_line,
		input	[ 7:0]	reg_r23_vstart_line,
		input			reg_r25_msk,
		input	[ 2:0]	reg_r27_h_scroll,
		input			reg_r25_yjk,
		input			centeryjk_r25_n
	);

	localparam		clocks_per_line				= 1368;		// 342*4
	localparam		offset_x					= 7'd49;
	localparam		led_tv_x_ntsc				= (-3);
	localparam		led_tv_y_ntsc				= 7'd1;
	localparam		led_tv_x_pal				= (-2);
	localparam		led_tv_y_pal				= 7'd3;
	localparam		v_blanking_start_192_ntsc	= 9'd240 + 9'd5;
	localparam		v_blanking_start_212_ntsc	= 9'd250 + 9'd5;
	localparam		v_blanking_start_192_pal	= 9'd263 + 9'd5;
	localparam		v_blanking_start_212_pal	= 9'd273 + 9'd5;

	reg		[ 1:0]	ff_dotstate;
	reg		[ 2:0]	ff_eightdotstate;
	reg		[ 8:0]	ff_pre_x_cnt;
	reg		[ 8:0]	ff_x_cnt;
	reg		[ 8:0]	ff_pre_y_cnt;
	reg		[ 8:0]	ff_monitor_line;
	reg		[ 1:0]	ff_video_dh_clk;
	reg		[ 1:0]	ff_video_dl_clk;
	reg		[ 5:0]	ff_pre_x_cnt_start1;
	reg		[ 8:0]	ff_right_mask;
	reg		[ 1:0]	ff_window_x;
	reg				ff_ivideovs_n;
	reg				ff_pre_window_y;
	reg				ff_pre_window_y_sp;
	reg				ff_enahsync;
	reg				ff_bwindow_x;
	reg				ff_bwindow_y;
	reg				ff_bwindow;
	reg				ff_h_blank;		//	xxx

	wire	[10:0]	w_h_cnt;
	wire	[10:0]	w_v_cnt_in_frame;
	wire	[ 9:0]	w_v_cnt_in_field;
	wire			w_field;
	wire			w_h_blank;
	wire			w_v_blank;
	wire	[ 4:0]	w_pre_x_cnt_start0;
	wire	[ 8:0]	w_pre_x_cnt_start2;
	wire			w_hsync;
	wire	[ 8:0]	w_left_mask;
	wire	[ 8:0]	w_y_adj;
	wire	[ 1:0]	w_line_mode;
	wire			w_v_blanking_start;
	wire			w_v_blanking_end;
	wire	[ 8:0]	w_pre_dot_counter_yp_v;
	wire	[ 8:0]	w_pre_dot_counter_yp_start;
	wire	[ 8:0]	w_v_sync_intr_start_line;
	wire	[ 6:0]	w_led_tv_x;
	wire	[ 6:0]	w_adjust_x;
	wire	[ 6:0]	w_h_cnt_body;
	wire	[ 6:0]	w_led_tv_y;
	wire	[ 6:0]	w_adjust_y;
	wire	[ 9:0]	w_v_cnt_body;

	////////////////////////////////////////////////////////////////////////////
	//	port assignment
	////////////////////////////////////////////////////////////////////////////
	assign h_cnt				= w_h_cnt;
	assign v_cnt				= w_v_cnt_in_frame;
	assign v_cnt_in_field		= w_v_cnt_in_field;
	assign dotstate				= ff_dotstate;
	assign eightdotstate		= ff_eightdotstate;
	assign field				= w_field;
	assign window_x				= ff_window_x;
	assign pvideodhclk			= ff_video_dh_clk;
	assign pvideodlclk			= ff_video_dl_clk;
	assign predotcounter_x		= ff_pre_x_cnt;
	assign predotcounter_y		= ff_pre_y_cnt;
	assign predotcounter_yp		= ff_monitor_line;

	assign hd					= ff_h_blank;
	assign vd					= w_v_blank;

	assign hsync				= ( w_h_cnt[1:0] == 2'b10 && ff_pre_x_cnt == 9'd8 ) ? 1'b1 : 1'b0;
	assign register_hold		= ( w_h_cnt[1:0] == 2'b10 && ff_pre_x_cnt == 9'd264 ) ? 1'b1 : 1'b0;
	assign v_blanking_start		= w_v_blanking_start;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_h_blank <= 1'b0;
		end
		else if( w_h_cnt[1:0] == 2'b10 && ff_pre_x_cnt == 9'd8 ) begin
			ff_h_blank <= 1'b0;
		end
		else if( w_h_cnt[1:0] == 2'b10 && ff_pre_x_cnt == 9'd264 ) begin
			ff_h_blank <= 1'b1;
		end
		else begin
			//	hold
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//	sub components
	////////////////////////////////////////////////////////////////////////////
	vdp_hvcounter u_hvcounter (
		.reset				( reset					),
		.clk21m				( clk21m				),
		.h_cnt				( w_h_cnt				),
		.v_cnt_in_field		( w_v_cnt_in_field		),
		.v_cnt_in_frame		( w_v_cnt_in_frame		),
		.field				( w_field				),
		.h_blank			( w_h_blank				),
		.v_blank			( w_v_blank				),
		.pal_mode			( vdp_r9_pal_mode		),
		.interlace_mode		( reg_r9_interlace_mode	),
		.y212_mode			( reg_r9_y_dots			),
		.offset_y			( offset_y				)
	);

	////////////////////////////////////////////////////////////////////////////
	//	dot state
	////////////////////////////////////////////////////////////////////////////
	always @( posedge reset or posedge clk21m )
	begin
		if( reset ) begin
			ff_dotstate		<= 2'b00;
			ff_video_dh_clk <= 1'b0;
			ff_video_dl_clk <= 1'b0;
		end
		else if( w_h_cnt == (clocks_per_line-1) ) begin
			ff_dotstate		<= 2'b00;
			ff_video_dh_clk <= 1'b1;
			ff_video_dl_clk <= 1'b1;
		end
		else begin
			case( ff_dotstate )
			2'b00:
				begin
					ff_dotstate		<= 2'b01;
					ff_video_dh_clk <= 1'b0;
					ff_video_dl_clk <= 1'b1;
				end
			2'b01:
				begin
					ff_dotstate		<= 2'b11;
					ff_video_dh_clk <= 1'b1;
					ff_video_dl_clk <= 1'b0;
				end
			2'b11:
				begin
					ff_dotstate		<= 2'b10;
					ff_video_dh_clk <= 1'b0;
					ff_video_dl_clk <= 1'b0;
				end
			2'b10:
				begin
					ff_dotstate		<= 2'b00;
					ff_video_dh_clk <= 1'b1;
					ff_video_dl_clk <= 1'b1;
				end
			endcase
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//	8dot state
	////////////////////////////////////////////////////////////////////////////
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_eightdotstate <= 3'd0;
		end
		else if( w_h_cnt[1:0] == 2'b11 ) begin
			if( ff_pre_x_cnt == 0 ) begin
				ff_eightdotstate <= 3'd0;
			end
			else begin
				ff_eightdotstate <= ff_eightdotstate + 3'd1;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//	generate dotcounter
	////////////////////////////////////////////////////////////////////////////

	assign w_pre_x_cnt_start0	= { reg_r18_adj[3], reg_r18_adj[3:0] + 5'b11000 };					//	(-8...7) - 8 = (-16...-1)

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_pre_x_cnt_start1 <= 6'd0;
		end
		else begin
			ff_pre_x_cnt_start1 <= { w_pre_x_cnt_start0[4], w_pre_x_cnt_start0 } - { 3'd0, reg_r27_h_scroll };	// (-23...-1)
		end
	end

	assign w_pre_x_cnt_start2[8:6] = { 3 {ff_pre_x_cnt_start1[5]} };
	assign w_pre_x_cnt_start2[5:0] = ff_pre_x_cnt_start1;

	assign w_led_tv_x	= ( vdp_r9_pal_mode                ) ? (offset_x + led_tv_x_pal) : (offset_x + led_tv_x_ntsc);
	assign w_adjust_x	= ( reg_r25_yjk && centeryjk_r25_n ) ? 7'd4 : 7'd0;
	assign w_h_cnt_body	= w_led_tv_x - {(reg_r25_msk & ~centeryjk_r25_n), 2'b00} + w_adjust_x;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_pre_x_cnt <= 9'd0;
		end
 		else if( w_h_cnt == {2'b00, w_h_cnt_body, 2'b10} ) begin
			ff_pre_x_cnt <= w_pre_x_cnt_start2;
		end
		else if( w_h_cnt[1:0] == 2'b10 ) begin
			ff_pre_x_cnt <= ff_pre_x_cnt + 9'd1;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_x_cnt <= 9'd0;
		end
		else if( w_h_cnt == {2'b00, w_h_cnt_body, 2'b10} ) begin
			// hold
		end
		else if( w_h_cnt[1:0] == 2'b10 ) begin
			if( ff_pre_x_cnt == 9'b111111111 ) begin
				// jp: ff_pre_x_cnt が -1から0にカウントアップする時にff_x_cntを-8にする
				ff_x_cnt <= 9'b111111000;		// -8
			end
			else begin
				ff_x_cnt <= ff_x_cnt + 9'd1;
			end
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// generate v-sync pulse
	////////////////////////////////////////////////////////////////////////////
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_ivideovs_n <= 1'b1;
		end
		else if( w_v_cnt_in_field == 6 ) begin
			// sstate = sstate_b
			ff_ivideovs_n <= 1'b0;
		end
		else if( w_v_cnt_in_field == 12 ) begin
			// sstate = sstate_a
			ff_ivideovs_n <= 1'b1;
		end
	end
	assign ivideovs_n	= ff_ivideovs_n;

	////////////////////////////////////////////////////////////////////////////
	//	display window
	////////////////////////////////////////////////////////////////////////////

	// left mask (r25 msk)
	// h_scroll = 0 --> 8
	// h_scroll = 1 --> 7
	// h_scroll = 2 --> 6
	// h_scroll = 3 --> 5
	// h_scroll = 4 --> 4
	// h_scroll = 5 --> 3
	// h_scroll = 6 --> 2
	// h_scroll = 7 --> 1
	assign w_left_mask	=	( reg_r25_msk == 1'b0 ) ? 9'd0 : { 5'd0, { 1'b0, ~reg_r27_h_scroll } + 1 };

	always @( posedge clk21m ) begin
		// main window
		if( w_h_cnt[1:0] == 2'b01 && ff_x_cnt == w_left_mask ) begin
			// when dotcounter_x = 0
			ff_right_mask <= 9'b100000000 - { 6'd0, reg_r27_h_scroll };
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_window_x <= 1'b0;
		end
		else if( w_h_cnt[1:0] == 2'b01 && ff_x_cnt == w_left_mask )  begin
			// when dotcounter_x = 0
			ff_window_x <= 1'b1;
		end
		else if( w_h_cnt[1:0] == 2'b01 && ff_x_cnt == ff_right_mask )  begin
			// when dotcounter_x = 256
			ff_window_x <= 1'b0;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// y
	////////////////////////////////////////////////////////////////////////////
	assign w_hsync	=	( w_h_cnt[1:0] == 2'b10 && ff_pre_x_cnt == 9'b111111111 ) ? 1'b1 : 1'b0;
	assign w_y_adj	=	{ reg_r18_adj[7], reg_r18_adj[7], reg_r18_adj[7], reg_r18_adj[7], reg_r18_adj[7], reg_r18_adj[7:4] };

	function [8:0] sel_pre_dot_counter_yp_start;
		input			reg_r9_y_dots;
		input			vdp_r9_pal_mode;
		
		case( { reg_r9_y_dots, vdp_r9_pal_mode } )
		2'b00:
			sel_pre_dot_counter_yp_start = 9'b111100110;					// top border lines = -26
		2'b10:
			sel_pre_dot_counter_yp_start = 9'b111110000;					// top border lines = -16
		2'b01:
			sel_pre_dot_counter_yp_start = 9'b111001011;					// top border lines = -53
		default:
			sel_pre_dot_counter_yp_start = 9'b111010101;					// top border lines = -43
		endcase
	endfunction

	assign w_pre_dot_counter_yp_start	= sel_pre_dot_counter_yp_start( reg_r9_y_dots, vdp_r9_pal_mode );
	assign w_pre_dot_counter_yp_v		= (ff_monitor_line == 9'd255) ? ff_monitor_line : (ff_monitor_line + 9'd1);

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_monitor_line		<= 9'd0;
			ff_pre_window_y		<= 1'b0;
			ff_pre_window_y_sp	<= 1'b0;
			ff_enahsync			<= 1'b0;
		end
		else if( w_hsync ) begin
			// jp: prewindow_xが 1になるタイミングと同じタイミングでy座標の計算
			if(	 w_v_blanking_end ) begin
				ff_monitor_line <= w_pre_dot_counter_yp_start + w_y_adj;
				ff_pre_window_y_sp	<= 1'b1;
			end
			else begin
				if( w_pre_dot_counter_yp_v == 9'd0 )  begin
					ff_enahsync		<= 1'b1;
					ff_pre_window_y	<= 1'b1;
				end
				else if( (reg_r9_y_dots == 1'b0 && w_pre_dot_counter_yp_v == 9'd192) ||
						 (reg_r9_y_dots == 1'b1 && w_pre_dot_counter_yp_v == 9'd212) ) begin
					ff_pre_window_y		<= 1'b0;
					ff_pre_window_y_sp		<= 1'b0;
				end
				else if( (reg_r9_y_dots == 1'b0 && vdp_r9_pal_mode == 1'b0 && w_pre_dot_counter_yp_v == 9'd235) ||
						 (reg_r9_y_dots == 1'b1 && vdp_r9_pal_mode == 1'b0 && w_pre_dot_counter_yp_v == 9'd245) ||
						 (reg_r9_y_dots == 1'b0 && vdp_r9_pal_mode == 1'b1 && w_pre_dot_counter_yp_v == 9'd259) ||
						 (reg_r9_y_dots == 1'b1 && vdp_r9_pal_mode == 1'b1 && w_pre_dot_counter_yp_v == 9'd269) ) begin
					ff_enahsync		<= 1'b0;
				end
				ff_monitor_line <= w_pre_dot_counter_yp_v;
			end
		end
	end

	always @( posedge clk21m ) begin
		ff_pre_y_cnt <= ff_monitor_line + { 1'b0, reg_r23_vstart_line };
	end

	assign pre_window_y		= ff_pre_window_y;
	assign pre_window_y_sp	= ff_pre_window_y_sp;
	assign enahsync			= ff_enahsync;

	////////////////////////////////////////////////////////////////////////////
	// vsync interrupt request
	////////////////////////////////////////////////////////////////////////////
	assign w_line_mode		=	reg_r9_y_dots & vdp_r9_pal_mode;

	function [8:0] sel_v_sync_intr_start_line;
		input	[1:0]	w_line_mode;
		
		case( w_line_mode )
			2'b00:		sel_v_sync_intr_start_line = v_blanking_start_192_ntsc;
			2'b10:		sel_v_sync_intr_start_line = v_blanking_start_212_ntsc;
			2'b01:		sel_v_sync_intr_start_line = v_blanking_start_192_pal;
			default:	sel_v_sync_intr_start_line = v_blanking_start_212_pal;
		endcase
	endfunction

	assign w_v_sync_intr_start_line	= sel_v_sync_intr_start_line( w_line_mode ) + w_led_tv_y;
	assign w_led_tv_y				= ( vdp_r9_pal_mode ) ? led_tv_y_pal : led_tv_y_ntsc;
	assign w_adjust_y				= offset_y + w_led_tv_y;
	assign w_v_cnt_body				= { 2'b00, w_adjust_y, (w_field & reg_r9_interlace_mode) };
	assign w_v_blanking_end			=	( w_v_cnt_in_field == w_v_cnt_body ) ? 1'b1 : 1'b0;
	assign w_v_blanking_start		=	( w_v_cnt_in_field == { w_v_sync_intr_start_line, (w_field & reg_r9_interlace_mode) } ) ? 1'b1 : 1'b0;

	////////////////////////////////////////////////////////////////////////////
	// bwindow
	////////////////////////////////////////////////////////////////////////////
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_bwindow_x <= 1'b0;
		end
		else if( h_cnt == 200 )  begin
			ff_bwindow_x <= 1'b1;
		end
		else if( h_cnt == clocks_per_line-1-1 ) begin
			ff_bwindow_x <= 1'b0;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_bwindow_y <= 1'b0;
		end
		else if( !reg_r9_interlace_mode ) begin
			// non-interlace
			// 3+3+16 = 19
			if(  (v_cnt == 20*2) ||
				((v_cnt == 524+20*2) && (vdp_r9_pal_mode == 1'b0)) ||
				((v_cnt == 626+20*2) && (vdp_r9_pal_mode == 1'b1)) )  begin
				ff_bwindow_y <= 1'b1;
			end
			else if( ((v_cnt == 524) && (vdp_r9_pal_mode == 1'b0)) ||
					 ((v_cnt == 626) && (vdp_r9_pal_mode == 1'b1)) ||
					  (v_cnt == 0) ) begin
				ff_bwindow_y <= 1'b0;
			end
		end
		else begin
			// interlace
			if( (v_cnt == 20*2) ||
				// +1 should be needed.
				// because odd field's start is delayed half line.
				// so the start position of display time should be
				// delayed more half line.
				((v_cnt === 525+20*2 + 1) && (vdp_r9_pal_mode == 1'b0)) ||
				((v_cnt === 625+20*2 + 1) && (vdp_r9_pal_mode == 1'b1)) )  begin
				ff_bwindow_y <= 1'b1;
			end
			else if(	((v_cnt == 525) && (vdp_r9_pal_mode == 1'b0)) ||
						((v_cnt == 625) && (vdp_r9_pal_mode == 1'b1)) ||
						 (v_cnt == 0) ) begin
				ff_bwindow_y <= 1'b0;
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_bwindow <= 1'b0;
		end
		else begin
			ff_bwindow <= ff_bwindow_x & ff_bwindow_y;
		end
	end

	assign bwindow_x	= ff_bwindow_x;
	assign bwindow_y	= ff_bwindow_y;
	assign bwindow		= ff_bwindow;
endmodule
