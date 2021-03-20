//
//	vdp_interrupt.v
//	 Interrupt controller of ESE-VDP.
//
//	Copyright (C) 2000-2006 Kunihiko Ohnaka
//	All rights reserved.
//									   http://www.ohnaka.jp/ese-vdp/
//
//	本ソフトウェアおよび本ソフトウェアに基づいて作成された派生物は、以下の条件を
//	満たす場合に限り、再頒布および使用が許可されます。
//
//	1.ソースコード形式で再頒布する場合、上記の著作権表示、本条件一覧、および下記
//	  免責条項をそのままの形で保持すること。
//	2.バイナリ形式で再頒布する場合、頒布物に付属のドキュメント等の資料に、上記の
//	  著作権表示、本条件一覧、および下記免責条項を含めること。
//	3.書面による事前の許可なしに、本ソフトウェアを販売、および商業的な製品や活動
//	  に使用しないこと。
//
//	本ソフトウェアは、著作権者によって「現状のまま」提供されています。著作権者は、
//	特定目的への適合性の保証、商品性の保証、またそれに限定されない、いかなる明示
//	的もしくは暗黙な保証責任も負いません。著作権者は、事由のいかんを問わず、損害
//	発生の原因いかんを問わず、かつ責任の根拠が契約であるか厳格責任であるか（過失
//	その他の）不法行為であるかを問わず、仮にそのような損害が発生する可能性を知ら
//	されていたとしても、本ソフトウェアの使用によって発生した（代替品または代用サ
//	ービスの調達、使用の喪失、データの喪失、利益の喪失、業務の中断も含め、またそ
//	れに限定されない）直接損害、間接損害、偶発的な損害、特別損害、懲罰的損害、ま
//	たは結果損害について、一切責任を負わないものとします。
//
//	Note that above Japanese version license is the formal document.
//	The following translation is only for reference.
//
//	Redistribution and use of this software or any derivative works,
//	are permitted provided that the following conditions are met:
//
//	1. Redistributions of source code must retain the above copyright
//	   notice, this list of conditions and the following disclaimer.
//	2. Redistributions in binary form must reproduce the above
//	   copyright notice, this list of conditions and the following
//	   disclaimer in the documentation and/or other materials
//	   provided with the distribution.
//	3. Redistributions may not be sold, nor may they be used in a
//	   commercial product or activity without specific prior written
//	   permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//	COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//	POSSIBILITY OF SUCH DAMAGE.
//
// ----------------------------------------------------------------------------
//	Update history
//	3rd.Dec.2019 by t.hara
//		Converted to VerilogHDL.
//

module VDP_INTERRUPT (
	input			RESET,
	input			CLK21M,

	input	[ 8:0]	H_CNT,
	input	[ 7:0]	Y_CNT,
	input			ACTIVE_LINE,
	input			V_BLANKING_START,
	input			CLR_VSYNC_INT,
	input			CLR_HSYNC_INT,
	output			REQ_VSYNC_INT_N,
	output			REQ_HSYNC_INT_N,
	input	[ 7:0]	REG_R19_HSYNC_INT_LINE
);
	reg				ff_vsync_int_n;
	reg				ff_hsync_int_n;
	wire			w_vsync_intr_timing;

	assign REQ_VSYNC_INT_N		= ff_vsync_int_n;
	assign REQ_HSYNC_INT_N		= ff_hsync_int_n;

	//---------------------------------------------------------------------------
	// vsync interrupt request
	//---------------------------------------------------------------------------
	assign w_vsync_intr_timing	= ( H_CNT == 9'd8 ) ? 1'b1 : 1'b0;

	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			ff_vsync_int_n <= 1'b1;
		end
		else begin
			if( CLR_VSYNC_INT ) begin
				// v-blanking interrupt clear
				ff_vsync_int_n <= 1'b1;
			end
			else if( w_vsync_intr_timing && V_BLANKING_START ) begin
				// v-blanking interrupt request
				ff_vsync_int_n <= 1'b0;
			end
		end
	end

	//---------------------------------------------------------------------------
	//	w_hsync interrupt request
	//---------------------------------------------------------------------------
	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			ff_hsync_int_n <= 1'b1;
		end
		else begin
			if( CLR_HSYNC_INT || (w_vsync_intr_timing && V_BLANKING_START) ) begin
				// h-blanking interrupt clear
				ff_hsync_int_n <= 1'b1;
			end
			else if( ACTIVE_LINE && (Y_CNT == REG_R19_HSYNC_INT_LINE) ) begin
				// h-blanking interrupt request
				ff_hsync_int_n <= 1'b0;
			end
		end
	end
endmodule
