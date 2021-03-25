//
//  t800_alu16.v
//   Arithmetic logical unit for 16bit
//
//  Copyright (C) 2020 Takayuki Hara
//  All rights reserved.
//                               http://hraroom.s602.xrea.com/msx/ocm/index.html
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

module t800_alu16 (
	input	[ 7:0]	opecode,
	input	[15:0]	acc_q,
	input	[15:0]	operand_q,
	input			cy_q,
	input			prefix_cb,
	input			prefix_ed,
	output	[15:0]	alu16_acc_d,
	output			alu16_acc_d_en,
	output			alu16_sign_d,
	output			alu16_sign_d_en,
	output			alu16_zero_d,
	output			alu16_zero_d_en,
	output			alu16_yf_d,
	output			alu16_yf_d_en,
	output			alu16_half_cy_d,
	output			alu16_half_cy_d_en,
	output			alu16_xf_d,
	output			alu16_xf_d_en,
	output			alu16_pv_d,
	output			alu16_pv_d_en,
	output			alu16_negative_d,
	output			alu16_negative_d_en,
	output			alu16_cy_d,
	output			alu16_cy_d_en
);
	wire			w_cy_q;
	wire	[ 7:0]	w_acc_q;
	wire	[12:0]	w_add_l;
	wire	[ 4:0]	w_add_h;
	wire	[12:0]	w_sub_l;
	wire	[ 4:0]	w_sub_h;
	wire	[12:0]	w_result_l;
	wire	[ 4:0]	w_result_h;
	wire	[15:0]	w_result;
	wire			w_half_cy;
	wire			w_cy;
	wire			w_overflow;
	wire			w_prefix;
	wire	[ 1:0]	w_flag_d_en;
	wire			w_flag0_d_en;
	wire			w_flag1_d_en;

	assign w_result				= { w_result_h[3:0], w_result_l[11:0] };
	assign w_cy_q				= cy_q & opecode[6];
	assign w_acc_q				= (opecode[1:0] != 2'b11) ? acc_q: 8'd1;
	assign w_prefix				= ~(prefix_cb | prefix_ed);
	assign w_add_l				= { 1'b0, w_acc_q[11: 0] } + { 1'b0, operand_q[11: 0] } + { 12'd0, w_cy_q };
	assign w_sub_l				= { 1'b0, w_acc_q[11: 0] } - { 1'b0, operand_q[11: 0] } - { 12'd0, w_cy_q };
	assign w_add_h				= { 1'b0, w_acc_q[15:12] } + { 1'b0, operand_q[15:12] } + { 12'd0, w_half_cy };
	assign w_sub_h				= { 1'b0, w_acc_q[15:12] } - { 1'b0, operand_q[15:12] } - { 12'd0, w_half_cy };

	function [1:0] mux_flag_d_en;
		input	[7:0]	opecode;

		casex( opecode )
		8'b01xx1010, 8'b01xx0010:
			mux_flag_d_en = 2'b11;
		8'b00xx1001:
			mux_flag_d_en = 2'b01;
		default:
			mux_flag_d_en = 2'b00;
		endcase
	endfunction

	assign w_flag_d_en			= mux_flag_d_en( opecode );
	assign w_flag0_d_en			= w_prefix & w_flag_d[0];
	assign w_flag1_d_en			= w_prefix & w_flag_d[1];

	function [12:0] mux_result_l;
		input	[ 7:0]	opecode;
		input	[12:0]	w_add_l;
		input	[12:0]	w_sub_l;
	
		casex( opecode )
		8'b00xx1001, 8'b01xx1010, 8'b00xx0011:
			mux_result_l = w_add_l;
		8'b01xx0010, 8'b00xx1011:
			mux_result_l = w_sub_l;
		default:
			mux_result_l = 13'd0;
		endcase
	endfunction

	function [12:0] mux_result_h;
		input	[7:0]	opecode;
		input	[4:0]	w_add_h;
		input	[4:0]	w_sub_h;
	
		casex( opecode )
		8'b00xx1001, 8'b01xx1010, 8'b00xx0011:
			mux_result_h = w_add_h;
		8'b01xx0010, 8'b00xx1011:
			mux_result_h = w_sub_h;
		default:
			mux_result_h = 5'd0;
		endcase
	endfunction

	assign w_result_l			= mux_result_l( opecode, w_add_l, w_sub_l );
	assign w_result_h			= mux_result_h( opecode, w_add_h, w_sub_h );

	assign w_half_cy			= w_result_l[12];
	assign w_cy					= w_result_h[4];

	assign w_overflow			= w_acc_q[15] ^ operand_q[15] ^ w_cy;
	assign w_flag_d_en			= w_prefix & w_opdec[0];

	assign alu16_acc_d			= w_result;
	assign alu16_acc_d_en		= w_prefix & w_opdec[1];

	assign alu16_zero_d			= ( w_result == 16'd0 ) ? 1'b1: 1'b0;
	assign alu16_half_cy_d		= w_half_cy;
	assign alu16_cy_d			= w_cy;
	assign alu16_pv_d			= w_overflow;
	assign alu16_negative_d		= (opecode == 8'b01xx0010) ? 1'b1: 1'b0;
	assign alu16_sign_d			= w_result[15];
	assign alu16_yf_d			= w_result[13];
	assign alu16_xf_d			= w_result[11];

	assign alu16_yf_d_en		= w_flag0_d_en;
	assign alu16_half_cy_d_en	= w_flag0_d_en;
	assign alu16_xf_d_en		= w_flag0_d_en;
	assign alu16_negative_d_en	= w_flag0_d_en;
	assign alu16_cy_d_en		= w_flag0_d_en;

	assign alu16_sign_d_en		= w_flag1_d_en;
	assign alu16_zero_d_en		= w_flag1_d_en;
	assign alu16_pv_d_en		= w_flag1_d_en;
endmodule
