//
// i8251_transmitter.v
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
//	18th, February, 2020
//		First release by t.hara
//

module i8251_transmitter (
	input			reset,
	input			clk21m,

	input			clk_en,
	input			clk,

	//	BUS interface
	input			wr,
	input			a,
	input	[ 7:0]	d,

	//	Mode
	input			ireset,
	input	[ 1:0]	stop_bits,
	input			even_parity,
	input			parity_en,
	input	[ 1:0]	char_len,
	input	[ 1:0]	baud_rate,

	//	Transmitter
	output			txd,
	output			txrdy
);
	wire			w_clk_rise_edge;

	reg		[ 1:0]	ff_state;
	localparam		state_mode			= 2'd0;
	localparam		state_sync_char1	= 2'd1;
	localparam		state_sync_char2	= 2'd2;
	localparam		state_command		= 2'd3;

	reg		[ 2:0]	ff_tx_state;
	reg				ff_txd;
	reg				ff_txrdy;
	localparam		tx_state_idle		= 3'd0;
	localparam		tx_state_start_bit	= 3'd1;
	localparam		tx_state_data_bit	= 3'd2;
	localparam		tx_state_parity_bit	= 3'd3;
	localparam		tx_state_stop_bit	= 3'd4;

	reg		[ 7:0]	ff_tx_baud_counter;
	reg		[ 2:0]	ff_tx_remain_bit;
	reg		[ 7:0]	ff_tx_data;
	reg				ff_tx_parity;
	wire	[ 7:0]	w_counter_max;
	wire	[ 2:0]	w_remain_bit;
	wire	[ 7:0]	w_stop_bits_1;
	wire	[ 7:0]	w_stop_bits_1p5;
	wire	[ 7:0]	w_stop_bits_2;
	wire	[ 7:0]	w_stop_bits;

	assign w_clk_rise_edge	= clk_en & ~clk;
	assign txd				= ff_txd;
	assign txrdy			= ff_txrdy;

	// --------------------------------------------------------------------
	//	state
	// --------------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_state		<= state_mode;
		end
		else if( ireset ) begin
			ff_state		<= state_mode;
		end
		else if( clk_en && w_clk_rise_edge && wr && a ) begin
			if( ff_state == state_mode ) begin
				if( d[1:0] == 2'b00 ) begin
					//	sync mode
					ff_state		<= state_sync_char1;
				end
				else begin
					ff_state		<= state_command;
				end
			end
			else if( ff_state == state_sync_char1 ) begin
				ff_state		<= state_sync_char2;
			end
			else if( ff_state == state_sync_char2 ) begin
				ff_state		<= state_command;
			end
		end
	end

	// --------------------------------------------------------------------
	//	counters
	// --------------------------------------------------------------------
	assign w_counter_max	= (baud_rate == 2'b01) ? 8'd1:
							  (baud_rate == 2'b10) ? 8'd31:
							  (baud_rate == 2'b11) ? 8'd127: 8'd0;

	assign w_remain_bit		= (char_len  == 2'b00) ? 3'd4:
							  (char_len  == 2'b01) ? 3'd5:
							  (char_len  == 2'b10) ? 3'd6: 3'd7;

	assign w_stop_bits_1	= (baud_rate == 2'b01) ? 8'd1:
							  (baud_rate == 2'b10) ? 8'd31:
							  (baud_rate == 2'b11) ? 8'd127: 8'd0;
	assign w_stop_bits_1p5	= (baud_rate == 2'b01) ? 8'd2:
							  (baud_rate == 2'b10) ? 8'd47:
							  (baud_rate == 2'b11) ? 8'd191: 8'd0;
	assign w_stop_bits_2	= (baud_rate == 2'b01) ? 8'd3:
							  (baud_rate == 2'b10) ? 8'd63:
							  (baud_rate == 2'b11) ? 8'd255: 8'd0;
	assign w_stop_bits		= (stop_bits == 2'b01) ? w_stop_bits_1:
							  (stop_bits == 2'b10) ? w_stop_bits_1p5:
							  (stop_bits == 2'b11) ? w_stop_bits_2: 8'd0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_tx_state		<= tx_state_idle;
		end
		else if( ireset ) begin
			ff_tx_state		<= tx_state_idle;
		end
		else if( ff_tx_state == tx_state_idle ) begin
			if( clk_en && w_clk_rise_edge && wr && ~a ) begin
				ff_tx_state		<= tx_state_start_bit;
			end
			else begin
				//	hold
			end
		end
		else if( ff_tx_state == tx_state_start_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_tx_state		<= tx_state_data_bit;
			end
			else begin
				//	hold
			end
		end
		else if( ff_tx_state == tx_state_data_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) && (ff_tx_remain_bit == 3'd0) ) begin
				if( parity_en ) begin
					ff_tx_state		<= tx_state_parity_bit;
				end
				else begin
					ff_tx_state		<= tx_state_stop_bit;
				end
			end
			else begin
				//	hold
			end
		end
		else if( ff_tx_state == tx_state_parity_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_tx_state		<= tx_state_stop_bit;
			end
			else begin
				//	hold
			end
		end
		else begin	//	tx_state_stop_bit
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_tx_state		<= tx_state_idle;
			end
			else begin
				//	hold
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_txrdy		<= 1'd1;
		end
		else if( ireset ) begin
			ff_txrdy		<= 1'd1;
		end
		else if( ff_tx_state == tx_state_idle ) begin
			if( clk_en && w_clk_rise_edge && wr && ~a ) begin
				//	start bits
				ff_txrdy		<= 1'd0;
			end
		end
		else if( ff_tx_state == tx_state_stop_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_txrdy		<= 1'd1;
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_tx_baud_counter		<= 8'd0;
		end
		else if( ireset ) begin
			ff_tx_baud_counter		<= 8'd0;
		end
		else if( ff_tx_state == tx_state_idle ) begin
			if( clk_en && w_clk_rise_edge && wr && ~a ) begin
				//	start bits
				ff_tx_baud_counter		<= w_counter_max;
			end
		end
		else if( ff_tx_state == tx_state_start_bit ) begin
			if( clk_en ) begin
				if( ff_tx_baud_counter == 8'd0 ) begin
					ff_tx_baud_counter		<= w_counter_max;
				end
				else begin
					ff_tx_baud_counter	<= ff_tx_baud_counter - 8'd1;
				end
			end
			else begin
				//	hold
			end
		end
		else if( ff_tx_state == tx_state_data_bit ) begin
			if( clk_en ) begin
				if( ff_tx_baud_counter == 8'd0 ) begin
					if( ~parity_en && (ff_tx_remain_bit == 3'd0) ) begin
						ff_tx_baud_counter		<= w_stop_bits;
					end
					else begin
						ff_tx_baud_counter		<= w_counter_max;
					end
				end
				else begin
					ff_tx_baud_counter	<= ff_tx_baud_counter - 8'd1;
				end
			end
			else begin
				//	hold
			end
		end
		else if( ff_tx_state == tx_state_parity_bit ) begin
			if( clk_en ) begin
				if( ff_tx_baud_counter == 8'd0 ) begin
					ff_tx_baud_counter		<= w_stop_bits;
				end
				else begin
					ff_tx_baud_counter	<= ff_tx_baud_counter - 8'd1;
				end
			end
			else begin
				//	hold
			end
		end
		else begin	//	tx_state_stop_bit
			if( clk_en ) begin
				if( ff_tx_baud_counter == 8'd0 ) begin
					ff_tx_baud_counter		<= w_counter_max;
				end
				else begin
					ff_tx_baud_counter	<= ff_tx_baud_counter - 8'd1;
				end
			end
			else begin
				//	hold
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_tx_data		<= 8'd0;
		end
		else if( ireset ) begin
			ff_tx_data		<= 8'd0;
		end
		else if( ff_tx_state == tx_state_idle ) begin
			if( clk_en && w_clk_rise_edge && wr && ~a ) begin
				ff_tx_data		<= d;
			end
		end
		else if( ff_tx_state == tx_state_start_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_tx_data		<= { 1'b0, ff_tx_data[7:1] };
			end
			else begin
				//	hold
			end
		end
		else if( ff_tx_state == tx_state_data_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_tx_data		<= { 1'b0, ff_tx_data[7:1] };
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_txd		<= 1'd1;
		end
		else if( ireset ) begin
			ff_txd		<= 1'd1;
		end
		else if( ff_tx_state == tx_state_idle ) begin
			if( clk_en && w_clk_rise_edge && wr && ~a ) begin
				ff_txd		<= 1'd0;
			end
		end
		else if( ff_tx_state == tx_state_start_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_txd		<= ff_tx_data[0];
			end
		end
		else if( ff_tx_state == tx_state_data_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				if( ff_tx_remain_bit == 8'd0 ) begin
					ff_txd		<= ( parity_en ) ? ff_tx_parity : 1'b1;
				end
				else begin
					ff_txd		<= ff_tx_data[0];
				end
			end
			else begin
				//	hold
			end
		end
		else if( ff_tx_state == tx_state_stop_bit ) begin
			ff_txd		<= 1'd1;
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_tx_parity		<= 1'd0;
		end
		else if( ireset ) begin
			ff_tx_parity		<= 1'd0;
		end
		else if( ff_tx_state == tx_state_start_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_tx_parity	<= ~even_parity;
			end
		end
		else if( ff_tx_state == tx_state_data_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				if( ff_tx_remain_bit == 8'd0 ) begin
					ff_tx_parity	<= 1'b0;
				end
				else begin
					ff_tx_parity	<= ff_tx_parity ^ ff_tx_data[0];
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


	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_tx_remain_bit	<= 3'd0;
		end
		else if( ireset ) begin
			ff_tx_remain_bit	<= 3'd0;
		end
		else if( ff_tx_state == tx_state_start_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_tx_remain_bit	<= w_remain_bit;
			end
			else begin
				//	hold
			end
		end
		else if( ff_tx_state == tx_state_data_bit ) begin
			if( clk_en && (ff_tx_baud_counter == 8'd0) ) begin
				ff_tx_remain_bit	<= ff_tx_remain_bit - 3'd1;
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end
endmodule
