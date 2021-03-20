//
// clock_generator.v
//	 Clock Generator
//	 Revision 1.00
//
// Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//	  this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//	  notice, this list of conditions and the following disclaimer in the
//	  documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//	  product or activity without specific prior written permission.
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
// -----------------------------------------------------------------------------
//	History
//	May/20th/2020 ver1.00 first release by t.hara
//		Separated from emsx_top.
//

module clock_generator (
	input			reset,
	input			clk21m,
	output			cpuclk,
	output			trueClk,
	output			pCpuClk,
	output			clkena,
	output	[1:0]	clkdiv,
	input			clksel,
	input			clksel5m_n,
	input			extclk3m
);
	reg		[1:0]	ff_clkdiv3		= 2'b10;
	reg				ff_cpuclk		= 1'b1;
	reg				ff_clkena		= 1'b0;
	reg		[1:0]	ff_clkdiv		= 2'b10;

	// Prescaler : 21.48MHz / 6
	always @( posedge clk21m ) begin
		if( ff_clkdiv3 == 2'b00 ) begin
			ff_clkdiv3 <= 2'b10;
		end
		else begin
			ff_clkdiv3 <= { 1'b0, ff_clkdiv3[1] };
		end
	end

	// ff_cpuclk : 3.58MHz = 21.48MHz / 6
	always @( posedge clk21m ) begin
		if( ff_clkdiv3 == 2'b10 ) begin
			ff_cpuclk <= ~ff_cpuclk;
		end
		else begin
			// hold
		end
	end

	// Clock enabler : 3.58MHz = 21.48MHz / 6
	always @( posedge clk21m ) begin
		if( ff_clkdiv3 == 2'b00 ) begin
			ff_clkena <= ff_cpuclk;
		end
		else begin
			ff_clkena <= 1'b0;
		end
	end

	// Prescaler : 21.48MHz / 4
	always @( posedge clk21m ) begin
		ff_clkdiv	<= ff_clkdiv - 2'b01;
	end

	assign cpuclk	= ff_cpuclk;
	assign clkena	= ff_clkena;
	assign clkdiv	= ff_clkdiv;

	// cpu clock assignment
	assign trueClk = //( !SdPaus                         ) ? 1'b1			:	// dismissed
					( clksel && !reset                   ) ? ff_clkdiv[0]	:	// 10.74MHz
					( !clksel5m_n && !reset              ) ? ff_clkdiv[1]	:	//	5.37MHz
					ff_cpuclk;													//	3.58MHz

	// slots clock assignment
	assign pCpuClk = //( !SdPaus                         ) ? 1'b1			:	// dismissed
					( clksel && !extclk3m && !reset      ) ? ff_clkdiv[0]	:	// 10.74MHz
					( !clksel5m_n && !extclk3m && !reset ) ? ff_clkdiv[1]	:	//	5.37MHz
					ff_cpuclk;													//	3.58MHz
endmodule
