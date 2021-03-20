//
//  vdp_sprite_display.v
//    Sprite module.
//
//  Copyright (C) 2019 Takayuki Hara
//  All rights reserved.
//                                     http://hraroom.s602.xrea.com/ocm/index.html
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
// Revision History
//
// 30th,December,2019 Created by t.hara
//   - 1st version.
//

module vdp_sprite_display (
	input			reset,
	input			clk21m,

	input	[ 1:0]	dot_state,
	input	[ 8:0]	dot_counter_x,
	output			sp_color_out,				//	0: Transparent, 1: Active pixcel
	output	[ 3:0]	sp_color_code,				//	Active pixel color
	output			sp_display_en,
	output	[ 6:0]	line_buffer_display_adr,
	output			line_buffer_display_we,
	input	[ 7:0]	line_buffer_xeven_q,
	input	[ 7:0]	line_buffer_xodd_q,
	input	[ 2:0]	reg_r27_h_scroll
);
	reg		[ 7:0]	ff_sp_display_x;
	reg				ff_sp_display_x0_d;
	reg				ff_sp_display_en;
	reg				ff_sp_found;
	reg		[ 3:0]	ff_sp_color_code;
	reg				ff_sp_found_d [0:7];
	reg		[ 3:0]	ff_sp_color_code_d [0:7];
	wire	[ 4:0]	w_display_buffer_x0;
	wire	[ 4:0]	w_display_buffer_x1;
	wire	[ 4:0]	w_display_buffer;

	assign w_display_buffer_x0	= { line_buffer_xeven_q[7], line_buffer_xeven_q[3:0] };
	assign w_display_buffer_x1	= { line_buffer_xodd_q[7] , line_buffer_xodd_q[3:0]  };
	assign w_display_buffer		= ( ff_sp_display_x0_d == 1'b0 ) ? w_display_buffer_x0 : w_display_buffer_x1;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_sp_display_x	<= 8'b0;
		end
		else if( dot_state == 2'b10 ) begin
			if( dot_counter_x == 9'd0 ) begin
				ff_sp_display_x		<= { 5'd0, reg_r27_h_scroll };
			end
			else begin
				ff_sp_display_x		<= ff_sp_display_x + 8'd1;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge clk21m ) begin
		ff_sp_display_x0_d	<= ff_sp_display_x[0];
	end

	assign line_buffer_display_adr	= ff_sp_display_x[7:1];
	assign line_buffer_display_we	= (dot_state == 2'b10) ? ff_sp_display_x[0] : 1'b0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_sp_display_en	<= 1'b0;
		end
		else if( dot_state == 2'b10 ) begin
			if( dot_counter_x == 9'd0 ) begin
				ff_sp_display_en	<= 1'b1;
			end
			else if( ff_sp_display_x == 8'd255 ) begin
				ff_sp_display_en	<= 1'b0;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge clk21m ) begin
		if( dot_state == 2'b01 ) begin
			if( ff_sp_display_en ) begin
				ff_sp_found			<= w_display_buffer[4];
				ff_sp_color_code	<= w_display_buffer[3:0];
			end
			else begin
				ff_sp_found			<= 1'b0;
				ff_sp_color_code	<= 4'd0;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge clk21m ) begin
		if( dot_state == 2'b01 ) begin
			ff_sp_found_d[0]		<= ff_sp_found;
			ff_sp_found_d[1]		<= ff_sp_found_d[0];
			ff_sp_found_d[2]		<= ff_sp_found_d[1];
			ff_sp_found_d[3]		<= ff_sp_found_d[2];
			ff_sp_found_d[4]		<= ff_sp_found_d[3];
			ff_sp_found_d[5]		<= ff_sp_found_d[4];
			ff_sp_found_d[6]		<= ff_sp_found_d[5];
			ff_sp_found_d[7]		<= ff_sp_found_d[6];
			ff_sp_color_code_d[0]	<= ff_sp_color_code;
			ff_sp_color_code_d[1]	<= ff_sp_color_code_d[0];
			ff_sp_color_code_d[2]	<= ff_sp_color_code_d[1];
			ff_sp_color_code_d[3]	<= ff_sp_color_code_d[2];
			ff_sp_color_code_d[4]	<= ff_sp_color_code_d[3];
			ff_sp_color_code_d[5]	<= ff_sp_color_code_d[4];
			ff_sp_color_code_d[6]	<= ff_sp_color_code_d[5];
			ff_sp_color_code_d[7]	<= ff_sp_color_code_d[6];
		end
	end

	assign sp_display_en	= ff_sp_display_en;
	assign sp_color_out		= ff_sp_found_d[7];
	assign sp_color_code	= ff_sp_color_code_d[7];
endmodule
