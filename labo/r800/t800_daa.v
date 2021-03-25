//
//  t800_daa.v
//   DAA unit
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

module t800_daa (
	input	[7:0]	opecode,
	input	[7:0]	acc_q,
	input			cy_q,
	input			half_cy_q,
	input			negative_q,
	input			prefix_cb,
	input			prefix_ed,
	output	[7:0]	daa_acc_d,
	output			daa_acc_d_en,
	output			daa_sign_d,
	output			daa_sign_d_en,
	output			daa_zero_d,
	output			daa_zero_d_en,
	output			daa_yf_d,
	output			daa_yf_d_en,
	output			daa_half_cy_d,
	output			daa_half_cy_d_en,
	output			daa_xf_d,
	output			daa_xf_d_en,
	output			daa_pv_d,
	output			daa_pv_d_en,
	output			daa_cy_d,
	output			daa_cy_d_en
);
	wire			w_flag_d_en;
	wire	[3:0]	w_acc_l;
	wire	[7:4]	w_acc_h;
	wire	[3:0]	w_acc_l_cond;
	wire	[3:0]	w_acc_h_cond;
	wire			w_acc_l_cond2;
	wire	[5:0]	w_acc_cond;
	wire	[3:0]	w_acc_half_cond;
	wire	[7:0]	w_result;
	wire			w_cy;
	wire			w_half_cy;
	wire	[7:0]	w_decimal_adjust;
	wire	[7:0]	w_add;
	wire	[7:0]	w_sub;

	assign w_acc_l				= acc_q[3:0];
	assign w_acc_h				= acc_q[7:4];

	function [1:0] mux_cond;
		input	[3:0]	w_acc;

		casex( w_acc )
		4'b0xxx:
			mux_cond = 2'b11;
		4'b1000:
			mux_cond = 2'b11;
		4'b1001:
			mux_cond = 2'b10;
		default:
			mux_cond = 2'b00;
		endcase
	endfunction

	function mux_cond2;
		input	[3:0]	w_acc;

		casex( w_acc )
		4'b00xx:
			mux_cond2 = 1'b0;
		4'b010x:
			mux_cond2 = 1'b0;
		default:
			mux_cond2 = 1'b1;
		endcase
	endfunction

	function [7:0] mux_decimal_adjust;
		input	[5:0]	w_acc_cond;

		casex( w_acc_cond )
		6'b00_00_00:
			mux_decimal_adjust = 8'h00;
		6'b01_00_00:
			mux_decimal_adjust = 8'h06;
		6'b0x_x0_1x:
			mux_decimal_adjust = 8'h06;
		6'b00_1x_00:
			mux_decimal_adjust = 8'h60;
		6'b10_xx_00:
			mux_decimal_adjust = 8'h60;
		default:
			mux_decimal_adjust = 8'h66;
		endcase
	endfunction

	function mux_cy;
		input	[5:0]	w_acc_cond;

		casex( w_acc_cond )
		6'b0x_00_00:
			mux_cy = 1'b0;
		6'b0x_x0_1x:
			mux_cy = 1'b0;
		6'b0x_x1_1x:
			mux_cy = 1'b1;
		6'b0x_1x_00:
			mux_cy = 1'b1;
		default:
			mux_cy = 1'b1;
		endcase
	endfunction

	function mux_half_cy;
		input	[3:0]	w_acc_half_cond;

		casex( w_acc_half_cond )
		4'b0x_x0:
			mux_cy = 1'b0;
		4'b0x_x1:
			mux_cy = 1'b1;
		4'b10_xx:
			mux_cy = 1'b0;
		4'b11_0x:
			mux_cy = 1'b0;
		default:
			mux_cy = 1'b1;
		endcase
	endfunction

	assign w_acc_l_cond			= mux_cond( w_acc_l );
	assign w_acc_h_cond			= mux_cond( w_acc_h );
	assign w_acc_l_cond2		= mux_cond2( w_acc_l );
	assign w_acc_cond			= { cy_q, half_cy_q, w_acc_h_cond, w_acc_l_cond };
	assign w_acc_half_cond		= { negative_q, half_cy_q, w_acc_l_cond2, w_acc_l_cond[1] }

	assign w_decimal_adjust		= mux_decimal_adjust( w_acc_cond );
	assign w_cy					= mux_cy( w_acc_cond );
	assign w_half_cy			= mux_half_cy( w_acc_half_ond );

	assign w_add				= acc_q + w_decimal_adjust;
	assign w_sub				= acc_q - w_decimal_adjust;
	assign w_result				= negative_q ? w_sub: w_add;

	assign w_flag_d_en			= (opecode == 8'h27 && ~(prefix_cb | prefix_ed)) ? 1'b1: 1'b0;

	assign daa_acc_d_en			= w_flag_d_en;
	assign daa_sign_d_en		= w_flag_d_en;
	assign daa_zero_d_en		= w_flag_d_en;
	assign daa_yf_d_en			= w_flag_d_en;
	assign daa_half_cy_d_en		= w_flag_d_en;
	assign daa_xf_d_en			= w_flag_d_en;
	assign daa_pv_d_en			= w_flag_d_en;
	assign daa_cy_d_en			= w_flag_d_en;

	assign daa_acc_d			= w_flag_d_en ? w_result: 8'd0;
	assign daa_sign_d			= w_flag_d_en & w_result[7];
	assign daa_zero_d			= (w_result == 8'd0) ? w_flag_d_en: 1'b0;
	assign daa_yf_d				= w_flag_d_en & w_result[5];
	assign daa_half_cy_d		= w_flag_d_en & w_half_cy;
	assign daa_xf_d				= w_flag_d_en & w_result[3];
	assign daa_pv_d				= w_flag_d_en & ~(w_result[7] ^ w_result[6] ^ w_result[5] ^ w_result[4] ^ w_result[3] ^ w_result[2] ^ w_result[1] ^ w_result[0]);
	assign daa_cy_d				= w_flag_d_en & w_cy;
endmodule
