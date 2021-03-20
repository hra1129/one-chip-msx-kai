//
//  t800_alu4.v
//   Arithmetic logical unit for 4bit
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

module t800_alu4 (
	input	[ 7:0]	opecode,
	input	[ 3:0]	acc_q,
	input	[ 3:0]	operand_q,
	input			cy_q,
	output	[ 3:0]	result_d,
	output			cy_d
);
	wire	[ 4:0]	w_add;
	wire	[ 4:0]	w_sub;
	wire	[ 3:0]	w_and;
	wire	[ 3:0]	w_xor;
	wire	[ 3:0]	w_or;
	wire	[ 4:0]	w_result;

	assign w_add	= { 1'b0, acc_q } + { 1'b0, operand_q } + { 4'd0, cy_q };
	assign w_sub	= { 1'b0, acc_q } - { 1'b0, operand_q } - { 4'd0, cy_q };
	assign w_and	= acc_q & operand_q;
	assign w_xor	= acc_q ^ operand_q;
	assign w_or		= acc_q | operand_q;

	function [ 4:0] mux;
		input	[7:0]	opecode;
		input	[4:0]	w_add;
		input	[4:0]	w_sub;
		input	[3:0]	w_and;
		input	[3:0]	w_xor;
		input	[3:0]	w_or;

		casex( opecode )
		8'b1x00xxxx, 8'b00xxx100:
			mux = w_add;
		8'b1x01xxxx, 8'b1x111xxx, 8'b00xxx101:
			mux = w_sub;
		8'b1x100xxx:
			mux = { 1'b0, w_and };
		8'b1x101xxx:
			mux = { 1'b0, w_xor };
		8'b1x110xxx:
			mux = { 1'b0, w_or };
		default:
			mux = 5'd0;
		endcase
	endfunction

	assign w_result	= mux( opecode, w_add, w_sub, w_and, w_xor, w_or );

	assign result_d	= w_result[3:0];
	assign cy_d		= w_result[4];
endmodule
