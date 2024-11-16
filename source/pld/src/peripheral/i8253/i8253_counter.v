//
// i8253_counter.v
//   Timer Device
//   Revision 1.00
//
// Copyright (c) 2020 Takayuki Hara
// All rights reserved.
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
//-----------------------------------------------------------------------------
//	Update history
//	5th, January, 2020
//		First release by t.hara
//

module i8253_counter (
	input			clk,
	input			reset,

	input			clk0_en,
	input			clk0,
	input			gate0,
	output			out0,

	//	Counter
	input	[ 7:0]	load_counter,
	output	[15:0]	counter0,

	//	Control signals
	input			wr_cw,
	input			wr_lsb,
	input			wr_msb,
	input			wr_trigger,
	input			mode0,
	input			mode1,
	input			mode2,
	input			mode3,
	input			mode4,
	input			mode5,
	input			bcd
);
	wire			w_clk0_rise_edge;
	wire			w_clk0_fall_edge;
	wire			w_out_init_value;
	reg				ff_count_en;
	wire			w_count_start;
	wire			w_count_1;
	wire			w_count_2;
	wire			w_count_end;
	wire	[15:0]	w_counter;
	wire			w_count_hold;
	wire	[ 4:0]	w_counter0_dec;
	wire	[ 4:0]	w_counter1_dec;
	wire	[ 4:0]	w_counter2_dec;
	wire	[ 4:0]	w_counter3_dec;
	wire	[ 3:0]	w_max_digit;
	reg		[ 3:0]	ff_counter0_latch;
	reg		[ 3:0]	ff_counter1_latch;
	reg		[ 3:0]	ff_counter2_latch;
	reg		[ 3:0]	ff_counter3_latch;
	reg				ff_count_load;
	reg		[ 3:0]	ff_counter0;
	reg		[ 3:0]	ff_counter1;
	reg		[ 3:0]	ff_counter2;
	reg		[ 3:0]	ff_counter3;
	reg				ff_out0;
	reg				ff_gate0;
	wire			w_out_rise;
	wire			w_out_fall;
	wire			w_out_invert;

	assign w_clk0_rise_edge	= ~clk0;
	assign w_clk0_fall_edge	= clk0;
	assign w_counter		= { ff_counter3, ff_counter2, ff_counter1, ff_counter0 };
	assign w_max_digit		= ( bcd ) ? 4'd9: 4'd15;

	assign w_out_init_value	= ( mode0 ) ? 1'b0 : 1'b1;

	assign w_counter0_dec	= { 1'b0, ff_counter0 } - ((mode3) ? 5'd2: 5'd1);
	assign w_counter1_dec	= { 1'b0, ff_counter1 } - 5'd1;
	assign w_counter2_dec	= { 1'b0, ff_counter2 } - 5'd1;
	assign w_counter3_dec	= { 1'b0, ff_counter3 } - 5'd1;

	assign w_count_hold		= ( mode0 || mode2 || mode3 || mode4 ) ? ~gate0: 1'b0;

	assign w_count_start	= ( mode0 || mode4 ) ? wr_trigger:
							  ( mode1 || mode5 ) ? (gate0 & ~ff_gate0):
							  ( mode2 || mode3 ) ? (wr_trigger | w_count_end): 1'b0;
	assign w_count_1		= ( w_counter == 16'd1 ) ? 1'b1: 1'b0;
	assign w_count_2		= ( w_counter == 16'd2 ) ? 1'b1: 1'b0;
	assign w_count_end		= w_count_1 | (mode3 & w_count_2);

	assign w_out_rise		= ( (mode4 | mode5) & ~ff_out0    ) | ( mode2 & w_count_end );
	assign w_out_fall		= ( (mode4 | mode5) & w_count_end );
	assign w_out_invert		= (  mode3          & w_count_end );

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_count_en	<= 1'd0;
		end
		else if( clk0_en && w_clk0_rise_edge ) begin
			if( w_count_start ) begin
				ff_count_en	<= 1'd1;
			end
			else if( wr_cw || wr_msb || wr_lsb ) begin
				ff_count_en	<= 1'd0;
			end
		end
		else if( clk0_en && w_clk0_fall_edge ) begin
			if( w_count_start ) begin
				//	hold
			end
			else if( (mode2 || mode3) && w_count_end ) begin
				ff_count_en	<= 1'd0;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_count_load	<= 1'b0;
		end
		else if( clk0_en && w_clk0_rise_edge ) begin
			if( w_count_start || (mode1 && gate0 && ~ff_gate0) ) begin
				ff_count_load	<= 1'b1;
			end
			else begin
				ff_count_load	<= 1'b0;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_counter0_latch	<= 4'd0;
			ff_counter1_latch	<= 4'd0;
		end
		else if( wr_lsb ) begin
			ff_counter0_latch	<= load_counter[3:0];
			ff_counter1_latch	<= load_counter[7:4];
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_counter2_latch	<= 4'd0;
			ff_counter3_latch	<= 4'd0;
		end
		else if( wr_msb ) begin
			ff_counter2_latch	<= load_counter[3:0];
			ff_counter3_latch	<= load_counter[7:4];
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_counter0	<= 4'd0;
		end
		else if( clk0_en && w_clk0_fall_edge ) begin
			if( ff_count_load ) begin
				if( mode3 ) begin
					ff_counter0	<= { ff_counter0_latch[3:1], ff_counter0_latch[0] ^ ff_counter0[0] };
				end
				else begin
					ff_counter0	<= ff_counter0_latch;
				end
			end
			else if( ff_count_en && !w_count_hold ) begin
				if( w_counter0_dec[4] ) begin
					ff_counter0	<= w_max_digit;
				end
				else begin
					ff_counter0	<= w_counter0_dec[3:0];
				end
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_counter1	<= 4'd0;
		end
		else if( clk0_en && w_clk0_fall_edge ) begin
			if( ff_count_load ) begin
				ff_counter1	<= ff_counter1_latch;
			end
			else if( ff_count_en && !w_count_hold && w_counter0_dec[4] ) begin
				if( w_counter1_dec[4] ) begin
					ff_counter1	<= w_max_digit;
				end
				else begin
					ff_counter1	<= w_counter1_dec[3:0];
				end
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_counter2	<= 4'd0;
		end
		else if( clk0_en && w_clk0_fall_edge ) begin
			if( ff_count_load ) begin
				ff_counter2	<= ff_counter2_latch;
			end
			else if( ff_count_en && !w_count_hold && w_counter0_dec[4] && w_counter1_dec[4] ) begin
				if( w_counter2_dec[4] ) begin
					ff_counter2	<= w_max_digit;
				end
				else begin
					ff_counter2	<= w_counter2_dec[3:0];
				end
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_counter3	<= 4'd0;
		end
		else if( clk0_en && w_clk0_fall_edge ) begin
			if( ff_count_load ) begin
				ff_counter3	<= ff_counter3_latch;
			end
			else if( ff_count_en && !w_count_hold && w_counter0_dec[4] && w_counter1_dec[4] && w_counter2_dec[4] ) begin
				if( w_counter3_dec[4] ) begin
					ff_counter3	<= w_max_digit;
				end
				else begin
					ff_counter3	<= w_counter3_dec[3:0];
				end
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_out0	<= 1'b0;
		end
		else if( clk0_en && w_clk0_rise_edge ) begin
			if( wr_cw ) begin
				ff_out0 <= w_out_init_value;
			end
		end
		else if( clk0_en && w_clk0_fall_edge ) begin
			if( w_out_rise ) begin
				ff_out0	<= 1'b1;
			end
			else if( w_out_invert ) begin
				ff_out0	<= ~ff_out0;
			end
			else if( ~mode5 && w_count_start ) begin
				ff_out0	<= 1'b0;
			end
			else if( w_out_fall ) begin
				ff_out0	<= 1'b0;
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_gate0	<= 1'b0;
		end
		else if( clk0_en && w_clk0_rise_edge ) begin
			ff_gate0	<= gate0;
		end
	end

	assign out0		= ff_out0 & ( ( mode2 ) ? ~w_count_end : 1'b1 );
	assign counter0	= ( mode3 ) ? { w_counter[15:1], 1'b0 }: w_counter;
endmodule
