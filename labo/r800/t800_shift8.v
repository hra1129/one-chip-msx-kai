//
//  t800_shift8.v
//   Shifter unit for 8bit
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

module t800_shift8 (
	input	[7:0]	opecode,
	input	[7:0]	operand_q,
	input			cy_q,
	input			prefix_cb,
	input			prefix_ed,
	output	[7:0]	shift8_result_d,
	output			shift8_result_d_en,
	output			shift8_sign_d,
	output			shift8_sign_d_en,
	output			shift8_zero_d,
	output			shift8_zero_d_en,
	output			shift8_yf_d,
	output			shift8_yf_d_en,
	output			shift8_half_cy_d,
	output			shift8_half_cy_d_en,
	output			shift8_xf_d,
	output			shift8_xf_d_en,
	output			shift8_pv_d,
	output			shift8_pv_d_en,
	output			shift8_negative_d,
	output			shift8_negative_d_en,
	output			shift8_cy_d,
	output			shift8_cy_d_en
);
	wire			w_prefix;
	wire	[9:0]	w_result;

	assign w_prefix				= prefix_cb & ~prefix_ed;

	function [9:0] mux;
		input	[7:0]	opecode;
		input	[8:0]	operand;

		casex( opecode )
		8'b00000xxx:
			mux = { 1'b1, operand[7:0], operand[7] };
		8'b00001xxx:
			mux = { 1'b1, operand[0], operand[0], operand[7:1] };
		8'b00010xxx:
			mux = { 1'b1, operand[7:0], operand[8] };
		8'b00011xxx:
			mux = { 1'b1, operand[0], operand[8], operand[7:1] };
		8'b00100xxx:
			mux = { 1'b1, operand[7:0], 1'b0 };
		8'b00110xxx:
			mux = { 1'b1, operand[7:0], 1'b1 };
		8'b00101xxx:
			mux = { 1'b1, operand[0], operand[7], operand[7:1] };
		8'b00111xxx:
			mux = { 1'b1, operand[0], 1'b0, operand[7:1] };
		default:
			mux = 10'd0;
		endcase
	endfunction

	assign w_result				= mux( opecode, operand_q );

	assign shift8_result_d		= w_result[7:0];
	assign shift8_result_d_en	= w_prefix & w_result[9];
	assign shift8_negative_d	= 1'b0;
	assign shift8_negative_d_en	= w_prefix & w_result[9];
	assign shift8_half_cy_d		= 1'b0;
	assign shift8_half_cy_d_en	= w_prefix & w_result[9];
	assign shift8_cy_d			= w_result[8];
	assign shift8_cy_d_en		= w_prefix & w_result[9];
	assign shift8_zero_d		= (w_result[7:0] == 8'd0) ? 1'b1: 1'b0;
	assign shift8_zero_d_en		= w_prefix & w_result[9];
	assign shift8_sign_d		= w_prefix & w_result[9] & w_result[7];
	assign shift8_sign_d_en		= w_prefix & w_result[9];
	assign shift8_yf_d			= w_prefix & w_result[9] & w_result[5];
	assign shift8_yf_d_en		= w_prefix & w_result[9];
	assign shift8_xf_d			= w_prefix & w_result[9] & w_result[3];
	assign shift8_xf_d_en		= w_prefix & w_result[9];
	assign shift8_pv_d			= w_prefix & w_result[9] & ~(w_result[7] ^ w_result[6] ^ w_result[5] ^ w_result[4] ^ w_result[3] ^ w_result[2] ^ w_result[1] ^ w_result[0]);
	assign shift8_pv_d_en		= w_prefix & w_result[9];
endmodule
