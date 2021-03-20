//
// debuffer.v
//   debuffer device
//   Revision 1.00
//
// Copyright (c) 2019 Takayuki Hara.
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
//	07th,December,2019 First release by t.hara
//

module debugger (
	input			clk21m,
	input			reset,
	input			visible,
	input	[10:0]	h_cnt_vdp,
	input	[ 9:0]	v_cnt_vdp,
	input	[ 5:0]	video_r_vdp,
	input	[ 5:0]	video_g_vdp,
	input	[ 5:0]	video_b_vdp,
	input			videohs_n_vdp,
	input			videovs_n_vdp,
	input			videocs_n_vdp,
	input			videodhclk_vdp,
	input			videodlclk_vdp,
	output	[ 5:0]	video_r_out,
	output	[ 5:0]	video_g_out,
	output	[ 5:0]	video_b_out,
	output			videohs_n_out,
	output			videovs_n_out,
	output			videocs_n_out,
	output			videodhclk_out,
	output			videodlclk_out
);
	reg		[ 5:0]	ff_video_r_out;
	reg		[ 5:0]	ff_video_g_out;
	reg		[ 5:0]	ff_video_b_out;
	reg				ff_videohs_n_out;
	reg				ff_videovs_n_out;
	reg				ff_videocs_n_out;
	reg				ff_videodhclk_out;
	reg				ff_videodlclk_out;



endmodule
