//
//  t800_neg.v
//   NEG/CPL/CCF/SCF unit
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

module t800_neg (
	input	[7:0]	opecode,
	input	[7:0]	acc_q,
	input			cy_q,
	input			prefix_cb,
	input			prefix_ed,
	output	[7:0]	neg_result_d,
	output			neg_result_d_en,
	output			neg_sign_d,
	output			neg_sign_d_en,
	output			neg_zero_d,
	output			neg_zero_d_en,
	output			neg_yf_d,
	output			neg_yf_d_en,
	output			neg_half_cy_d,
	output			neg_half_cy_d_en,
	output			neg_xf_d,
	output			neg_xf_d_en,
	output			neg_pv_d,
	output			neg_pv_d_en,
	output			neg_negative_d,
	output			neg_negative_d_en,
	output			neg_cy_d,
	output			neg_cy_d_en
);
	wire	[8:0]	w_opecode;
	wire	[3:0]	w_opdec;
	wire			w_flag_d_en;
	wire	[7:0]	w_cpl_result;
	wire	[4:0]	w_neg_l;
	wire	[4:0]	w_neg_h;
	wire			w_neg_half_cy;
	wire			w_neg_cy;
	wire	[7:0]	w_result;

	assign w_opecode			= { prefix_cb, opecode };

	function [3:0] mux;
		input	[8:0]	opecode;
		input			prefix_ed;

		case( opecode )
		9'h2f:
			mux	= 4'b0001;
		9'h44:
			mux	= { 2'b00, prefix_ed, 1'b0 };
		9'h3f:
			mux	= 4'b0100;
		9'h37:
			mux	= 4'b1000;
		default:
			mux	= 4'b0000;
		endcase
	endfunction

	assign w_opdec				= mux( w_opecode, prefix_ed );
	assign w_flag_d_en			= (w_opdec != 4'b0000) ? 1'b1: 1'b0;

	assign w_cpl_result			= ~acc_q;

	assign w_neg_l				= 5'd0 - { 1'b0, acc_q[3:0] };
	assign w_neg_half_cy		= w_neg_l[4];
	assign w_neg_h				= { 5 { w_neg_l[4] } } - { 1'b0, acc_q[7:4] };
	assign w_neg_cy				= w_neg_h[4];

	assign w_result				= (w_opdec[0] ? w_cpl_result : 8'd0) | (w_opdec[1] ? { w_neg_h[3:0], w_neg_l[3:0] } : 8'd0);

	assign neg_result_d			= w_result;
	assign neg_result_d_en		= w_opdec[0] | w_opdec[1];

	assign neg_sign_d_en		= w_opdec[1];
	assign neg_zero_d_en		= w_opdec[1];
	assign neg_pv_d_en			= w_opdec[1];
	assign neg_yf_d_en			= w_flag_d_en;
	assign neg_xf_d_en			= w_flag_d_en;
	assign neg_half_cy_d_en		= w_flag_d_en;
	assign neg_negative_d_en	= w_flag_d_en;

	assign neg_sign_d			= w_opdec[1]  & w_result[7];
	assign neg_yf_d				= w_flag_d_en & w_result[5];
	assign neg_xf_d				= w_flag_d_en & w_result[3];

	assign neg_zero_d			= (w_result[7:0] == 8'd0) ? w_opdec[1]: 1'b0;

	assign neg_half_cy_d		= w_opdec[0] | (w_opdec[1] & w_neg_half_cy) | (w_opdec[2] & cy_q);

	assign neg_cy_d				= (w_opdec[1] & w_neg_cy) | (w_opdec[2] & ~cy_q) | w_opdec[3];
	assign neg_cy_d_en			= w_opdec[1] | w_opdec[2] | w_opdec[3];

	assign neg_pv_d				= w_opdec[1] & (acc_q[7] ^ w_neg_cy);

	assign neg_negative_d		= w_opdec[0] | w_opdec[1];
endmodule
