//
// i8253.v
//   Timer Device
//   Revision 1.00
//
// Copyright (c) 2020 Takayuki Hara
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//    product or activity without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ----------------------------------------------------------------------------
//	Update history
//	16th, February, 2020
//		First release by t.hara
//

module i8253 (
	input			reset,
	input			clk21m,

	//	BUS interface
	input			cs_n,
	output			rd_n,
	input			wr_n,
	input	[ 1:0]	a,
	input	[ 7:0]	d,
	output	[ 7:0]	q,

	//	Timer0
	input			clk0,
	input			gate0,
	output			out0,

	//	Timer1
	input			clk1,
	input			gate1,
	output			out1,

	//	Timer2
	input			clk2,
	input			gate2,
	output			out2
);
	wire			gclk0_en;
	wire			gclk0;
	wire			gclk1_en;
	wire			gclk1;
	wire			gclk2_en;
	wire			gclk2;

	wire	[ 7:0]	w_q0;
	wire	[15:0]	w_counter0;
	wire			w_wr_cw0;
	wire			w_wr_lsb0;
	wire			w_wr_msb0;
	wire			w_wr_trigger0;
	wire	[ 7:0]	w_wr_d0;
	wire			w_c0_bcd;
	wire			w_c0_mode0;
	wire			w_c0_mode1;
	wire			w_c0_mode2;
	wire			w_c0_mode3;
	wire			w_c0_mode4;
	wire			w_c0_mode5;

	wire	[ 7:0]	w_q1;
	wire	[15:0]	w_counter1;
	wire			w_wr_cw1;
	wire			w_wr_lsb1;
	wire			w_wr_msb1;
	wire			w_wr_trigger1;
	wire	[ 7:0]	w_wr_d1;
	wire			w_c1_bcd;
	wire			w_c1_mode0;
	wire			w_c1_mode1;
	wire			w_c1_mode2;
	wire			w_c1_mode3;
	wire			w_c1_mode4;
	wire			w_c1_mode5;

	wire	[ 7:0]	w_q2;
	wire	[15:0]	w_counter2;
	wire			w_wr_cw2;
	wire			w_wr_lsb2;
	wire			w_wr_msb2;
	wire			w_wr_trigger2;
	wire	[ 7:0]	w_wr_d2;
	wire			w_c2_bcd;
	wire			w_c2_mode0;
	wire			w_c2_mode1;
	wire			w_c2_mode2;
	wire			w_c2_mode3;
	wire			w_c2_mode4;
	wire			w_c2_mode5;
	wire			w_rd;

	assign q	= w_q0 & w_q1 & w_q2;
	assign rd_n	= ~w_rd;

	// --------------------------------------------------------------------
	//	Counter0
	// --------------------------------------------------------------------
	i8253_clk_en u_clk0_en (
		.reset			( reset			),
		.clk21m			( clk21m		),
		.clk			( clk0			),
		.gclk_en		( gclk0_en		),
		.gclk			( gclk0			)
	);

	i8253_control #(
		.p_id			( 2'd0			)
	) u_control0 (
		.reset			( reset			),
		.clk21m			( clk21m		),
		.clk_en			( gclk0_en		),
		.clk			( gclk0			),
		.cs				( ~cs_n			),
		.rd				( w_rd			),
		.wr				( ~wr_n			),
		.a				( a				),
		.d				( d				),
		.q				( w_q0			),
		.counter		( w_counter0	),
		.wr_cw			( w_wr_cw0		),
		.wr_lsb			( w_wr_lsb0		),
		.wr_msb			( w_wr_msb0		),
		.wr_trigger		( w_wr_trigger0	),
		.wr_d			( w_wr_d0		),
		.mode0			( w_c0_mode0	),
		.mode1			( w_c0_mode1	),
		.mode2			( w_c0_mode2	),
		.mode3			( w_c0_mode3	),
		.mode4			( w_c0_mode4	),
		.mode5			( w_c0_mode5	),
		.bcd			( w_c0_bcd		)
	);

	i8253_counter u_counter0 (
		.clk			( clk21m		),
		.reset			( reset			),
		.clk0_en		( gclk0_en		),
		.clk0			( gclk0			),
		.gate0			( gate0			),
		.out0			( out0			),
		.load_counter	( w_wr_d0		),
		.counter0		( w_counter0	),
		.wr_cw			( w_wr_cw0		),
		.wr_lsb			( w_wr_lsb0		),
		.wr_msb			( w_wr_msb0		),
		.wr_trigger		( w_wr_trigger0	),
		.mode0			( w_c0_mode0	),
		.mode1			( w_c0_mode1	),
		.mode2			( w_c0_mode2	),
		.mode3			( w_c0_mode3	),
		.mode4			( w_c0_mode4	),
		.mode5			( w_c0_mode5	),
		.bcd			( w_c0_bcd		)
	);

	// --------------------------------------------------------------------
	//	Counter1
	// --------------------------------------------------------------------
	i8253_clk_en u_clk1_en (
		.reset			( reset			),
		.clk21m			( clk21m		),
		.clk			( clk1			),
		.gclk_en		( gclk1_en		),
		.gclk			( gclk1			)
	);

	i8253_control #(
		.p_id			( 2'd1			)
	) u_control1 (
		.reset			( reset			),
		.clk21m			( clk21m		),
		.clk_en			( gclk0_en		),
		.clk			( gclk0			),
		.cs				( ~cs_n			),
		.rd				( ~rd_n			),
		.wr				( ~wr_n			),
		.a				( a				),
		.d				( d				),
		.q				( w_q1			),
		.counter		( w_counter1	),
		.wr_cw			( w_wr_cw1		),
		.wr_lsb			( w_wr_lsb1		),
		.wr_msb			( w_wr_msb1		),
		.wr_trigger		( w_wr_trigger1	),
		.wr_d			( w_wr_d1		),
		.mode0			( w_c1_mode0	),
		.mode1			( w_c1_mode1	),
		.mode2			( w_c1_mode2	),
		.mode3			( w_c1_mode3	),
		.mode4			( w_c1_mode4	),
		.mode5			( w_c1_mode5	),
		.bcd			( w_c1_bcd		)
	);

	i8253_counter u_counter1 (
		.clk			( clk21m		),
		.reset			( reset			),
		.clk0_en		( gclk1_en		),
		.clk0			( gclk1			),
		.gate0			( gate1			),
		.out0			( out1			),
		.load_counter	( w_wr_d1		),
		.counter0		( w_counter1	),
		.wr_cw			( w_wr_cw1		),
		.wr_lsb			( w_wr_lsb1		),
		.wr_msb			( w_wr_msb1		),
		.wr_trigger		( w_wr_trigger1	),
		.mode0			( w_c1_mode0	),
		.mode1			( w_c1_mode1	),
		.mode2			( w_c1_mode2	),
		.mode3			( w_c1_mode3	),
		.mode4			( w_c1_mode4	),
		.mode5			( w_c1_mode5	),
		.bcd			( w_c1_bcd		)
	);

	// --------------------------------------------------------------------
	//	Counter2
	// --------------------------------------------------------------------
	i8253_clk_en u_clk2_en (
		.reset			( reset			),
		.clk21m			( clk21m		),
		.clk			( clk2			),
		.gclk_en		( gclk2_en		),
		.gclk			( gclk2			)
	);

	i8253_control #(
		.p_id			( 2'd2			)
	) u_control2 (
		.reset			( reset			),
		.clk21m			( clk21m		),
		.clk_en			( gclk2_en		),
		.clk			( gclk2			),
		.cs				( ~cs_n			),
		.rd				( ~rd_n			),
		.wr				( ~wr_n			),
		.a				( a				),
		.d				( d				),
		.q				( w_q2			),
		.counter		( w_counter2	),
		.wr_cw			( w_wr_cw2		),
		.wr_lsb			( w_wr_lsb2		),
		.wr_msb			( w_wr_msb2		),
		.wr_trigger		( w_wr_trigger2	),
		.wr_d			( w_wr_d2		),
		.mode0			( w_c2_mode0	),
		.mode1			( w_c2_mode1	),
		.mode2			( w_c2_mode2	),
		.mode3			( w_c2_mode3	),
		.mode4			( w_c2_mode4	),
		.mode5			( w_c2_mode5	),
		.bcd			( w_c2_bcd		)
	);

	i8253_counter u_counter2 (
		.clk			( clk21m		),
		.reset			( reset			),
		.clk0_en		( gclk2_en		),
		.clk0			( gclk2			),
		.gate0			( gate2			),
		.out0			( out2			),
		.load_counter	( w_wr_d2		),
		.counter0		( w_counter2	),
		.wr_cw			( w_wr_cw2		),
		.wr_lsb			( w_wr_lsb2		),
		.wr_msb			( w_wr_msb2		),
		.wr_trigger		( w_wr_trigger2	),
		.mode0			( w_c2_mode0	),
		.mode1			( w_c2_mode1	),
		.mode2			( w_c2_mode2	),
		.mode3			( w_c2_mode3	),
		.mode4			( w_c2_mode4	),
		.mode5			( w_c2_mode5	),
		.bcd			( w_c2_bcd		)
	);
endmodule
