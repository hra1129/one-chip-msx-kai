//
//  vdp_doublebuf.v
//    Double Buffered Line Memory.
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
// Memo
//   Japanese comment lines are starts with "JP:".
//   JP: 日本語のコメント行は JP:を頭に付ける事にする
//
//-----------------------------------------------------------------------------
// Document
//
// JP: ダブルバッファリング機能付きラインバッファモジュール。
// JP: vdp_vga.v によるアップスキャンコンバートに使用します。
//
// Line buffer module with double buffering function. 
// Used for upscan conversion by vdp_vga.v.
//
// JP: x_position_w に X座標を入れ，weを 1にすると書き込みバッファに
// JP: 書き込まれる．また，x_position_r に X座標を入れると，読み込み
// JP: バッファから読み出した色コードが qから出力される。
// JP: odd_line信号によって，読み込みバッファと書き込みバッファが
// JP: 切り替わる。
//
// Put the X coordinate in x_position_w and set we to 1 to write to the write buffer. 
// When the X coordinate is put in x_position_r, the color code read from the read buffer is output from q.
// The read buffer and the write buffer are switched by the odd_line signal.
//
//-----------------------------------------------------------------------------
// History
//
// 2020/Jan/20th
//    Converted to VerilogHDL from VHDL by t.hara
//

module vdp_doublebuf (
	input			clk,
	input	[ 9:0]	x_position_w,
	input	[ 9:0]	x_position_r,
	input			odd_line,
	input			we,
	input	[ 5:0]	r_in,
	input	[ 5:0]	g_in,
	input	[ 5:0]	b_in,
	output	[ 5:0]	r_out,
	output	[ 5:0]	g_out,
	output	[ 5:0]	b_out
);

	wire			we_e;
	wire			we_o;
	wire	[ 9:0]	addr_e;
	wire	[ 9:0]	addr_o;
	wire	[ 5:0]	outr_e;
	wire	[ 5:0]	outg_e;
	wire	[ 5:0]	outb_e;
	wire	[ 5:0]	outr_o;
	wire	[ 5:0]	outg_o;
	wire	[ 5:0]	outb_o;

	// even line
	vdp_linebuf u_buf_r_even (
		.address	( addr_e	),
		.inclock	( clk		),
		.we			( we_e		),
		.data		( r_in		),
		.q			( outr_e	)
	);

	vdp_linebuf u_buf_g_even (
		.address	( addr_e	),
		.inclock	( clk		),
		.we			( we_e		),
		.data		( g_in		),
		.q			( outg_e	)
	);

	vdp_linebuf u_buf_b_even (
		.address	( addr_e	),
		.inclock	( clk		),
		.we			( we_e		),
		.data		( b_in		),
		.q			( outb_e	)
	);
	// odd line
	vdp_linebuf u_buf_r_odd (
		.address	( addr_o	),
		.inclock	( clk		),
		.we			( we_o		),
		.data		( r_in		),
		.q			( outr_o	)
	);

	vdp_linebuf u_buf_g_odd (
		.address	( addr_o	),
		.inclock	( clk		),
		.we			( we_o		),
		.data		( g_in		),
		.q			( outg_o	)
	);

	vdp_linebuf u_buf_b_odd (
		.address	( addr_o	),
		.inclock	( clk		),
		.we			( we_o		),
		.data		( b_in		),
		.q			( outb_o	)
	);

	assign we_e			= ( odd_line == 1'b0 )? we : 1'b0;
	assign we_o			= ( odd_line == 1'b1 )? we : 1'b0;

	assign addr_e		= ( odd_line == 1'b0 )? x_position_w : x_position_r;
	assign addr_o		= ( odd_line == 1'b1 )? x_position_w : x_position_r;

	assign r_out		= ( odd_line == 1'b1 )? outr_e : outr_o;
	assign g_out		= ( odd_line == 1'b1 )? outg_e : outg_o;
	assign b_out		= ( odd_line == 1'b1 )? outb_e : outb_o;
endmodule
