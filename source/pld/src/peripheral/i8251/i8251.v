//
// i8251.v
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

module i8251 (
	input			reset,
	input			clk21m,

	//	BUS interface
	input			cs_n,
	input			rd_n,
	input			wr_n,
	input			a,
	input	[ 7:0]	d,
	output	[ 7:0]	q,

	//	Transmitter
	input			txc_n,
	output			txd,
	output			txrdy,

	//	Receiver
	input			rxc_n,
	input			rxd,
	output			rxrdy,
	input			cts_n,
	output			rts_n,
	input			dsr_n,
	output			dtr_n
);
	wire			gtxc;
	wire			gtxc_en;
	wire			w_txc_rise_edge;

	wire			grxc;
	wire			grxc_en;
	wire			w_rxc_rise_edge;

	reg		[ 1:0]	ff_state;
	localparam		state_mode			= 2'd0;
	localparam		state_sync_char1	= 2'd1;
	localparam		state_sync_char2	= 2'd2;
	localparam		state_command		= 2'd3;

	reg				ff_txc_rd;
	reg				ff_txc_wr;
	reg				ff_txc_a;
	reg		[ 7:0]	ff_txc_d;

	reg				ff_rxc_rd;
	reg				ff_rxc_wr;
	reg				ff_rxc_a;
	reg		[ 7:0]	ff_rxc_d;

	reg		[ 1:0]	ff_stop_bits;
	reg				ff_even_parity;
	reg				ff_parity_en;
	reg		[ 1:0]	ff_char_len;
	reg		[ 1:0]	ff_baud_rate;

	reg				ff_enter_hunt;
	reg				ff_ireset;
	reg				ff_req_send;
	reg				ff_ereset;
	reg				ff_send_break;
	reg				ff_rts_n;
	reg				ff_sbrk;
	reg				ff_rx_en;
	reg				ff_dtr_n;
	reg				ff_tx_en;

	reg		[ 7:0]	ff_sync_char1;
	reg		[ 7:0]	ff_sync_char2;

	wire			w_txd;
	wire			w_txrdy;

	wire	[ 7:0]	w_receive_data;
	wire			w_rxrdy;

	wire	[ 7:0]	w_status;
	wire			w_scs;
	wire			w_esd;

	assign w_txc_rise_edge	= ~gtxc & gtxc_en;
	assign w_rxc_rise_edge	= ~grxc & grxc_en;

	assign dtr_n			= ff_dtr_n;
	assign rts_n			= ff_rts_n;
	assign q				= ( cs_n == 1'b1 ) ? 8'hff:
							  ( a == 1'b0 )    ? w_receive_data: w_status;

	assign w_status			= { ~dsr_n, 4'd0, (ff_tx_en & w_txrdy), w_rxrdy, w_txrdy };
	assign w_scs			= ff_stop_bits[1];
	assign w_esd			= ff_stop_bits[0];

	// --------------------------------------------------------------------
	//	latch
	// --------------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_txc_rd	<= 1'd0;
			ff_txc_wr	<= 1'b0;
			ff_txc_a	<= 1'd0;
			ff_txc_d	<= 8'd0;
		end
		else if( !cs_n ) begin
			ff_txc_rd	<= ~rd_n;
			ff_txc_wr	<= ~wr_n;
			ff_txc_a	<= a;
			ff_txc_d	<= d;
		end
		else if( gtxc_en && w_txc_rise_edge ) begin
			ff_txc_rd	<= 1'd0;
			ff_txc_wr	<= 1'b0;
			ff_txc_a	<= 1'd0;
			ff_txc_d	<= 8'd0;
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_rxc_rd	<= 1'd0;
			ff_rxc_wr	<= 1'b0;
			ff_rxc_a	<= 1'd0;
			ff_rxc_d	<= 8'd0;
		end
		else if( !cs_n ) begin
			ff_rxc_rd	<= ~rd_n;
			ff_rxc_wr	<= ~wr_n;
			ff_rxc_a	<= a;
			ff_rxc_d	<= d;
		end
		else if( grxc_en && w_rxc_rise_edge ) begin
			ff_rxc_rd	<= 1'd0;
			ff_rxc_wr	<= 1'b0;
			ff_rxc_a	<= 1'd0;
			ff_rxc_d	<= 8'd0;
		end
		else begin
			//	hold
		end
	end

	// --------------------------------------------------------------------
	//	register access
	// --------------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_stop_bits	<= 2'd0;
			ff_even_parity	<= 1'd0;
			ff_parity_en	<= 1'd0;
			ff_char_len		<= 2'd0;
			ff_baud_rate	<= 2'd0;
		end
		else if( ff_ireset ) begin
			ff_stop_bits	<= 2'd0;
			ff_even_parity	<= 1'd0;
			ff_parity_en	<= 1'd0;
			ff_char_len		<= 2'd0;
			ff_baud_rate	<= 2'd0;
		end
		else if( ~wr_n && a ) begin
			if( ff_state == state_mode ) begin
				ff_stop_bits	<= d[7:6];
				ff_even_parity	<= d[5];
				ff_parity_en	<= d[4];
				ff_char_len		<= d[3:2];
				ff_baud_rate	<= d[1:0];
			end
			else begin
				//	hold
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_rts_n		<= 1'b1;
			ff_sbrk			<= 1'b0;
			ff_rx_en		<= 1'b0;
			ff_dtr_n		<= 1'b1;
			ff_tx_en		<= 1'b0;
		end
		else if( ff_ireset ) begin
			ff_rts_n		<= 1'b1;
			ff_sbrk			<= 1'b0;
			ff_rx_en		<= 1'b0;
			ff_dtr_n		<= 1'b1;
			ff_tx_en		<= 1'b0;
		end
		else if( ~wr_n && a ) begin
			if( ff_state == state_command ) begin
				ff_rts_n		<=~d[5];
				ff_sbrk			<= d[3];
				ff_rx_en		<= d[2];
				ff_dtr_n		<=~d[1];
				ff_tx_en		<= d[0];
			end
			else begin
				//	hold
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_enter_hunt	<= 1'b0;
			ff_ireset		<= 1'b0;
			ff_req_send		<= 1'b0;
			ff_ereset		<= 1'b0;
			ff_send_break	<= 1'b0;
		end
		else if( ~wr_n && a ) begin
			if( ff_state == state_command ) begin
				ff_enter_hunt	<= d[7];
				ff_ireset		<= d[6];
				ff_req_send		<= d[5];
				ff_ereset		<= d[4];
				ff_send_break	<= d[3];
			end
			else begin
				ff_enter_hunt	<= 1'b0;
				ff_ireset		<= 1'b0;
				ff_req_send		<= 1'b0;
				ff_ereset		<= 1'b0;
				ff_send_break	<= 1'b0;
			end
		end
		else begin
			ff_enter_hunt	<= 1'b0;
			ff_ireset		<= 1'b0;
			ff_req_send		<= 1'b0;
			ff_ereset		<= 1'b0;
			ff_send_break	<= 1'b0;
		end
	end

	// --------------------------------------------------------------------
	//	state
	// --------------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_state		<= state_mode;
		end
		else if( ff_ireset ) begin
			ff_state		<= state_mode;
		end
		else if( ~wr_n && a ) begin
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
				if( w_scs == 1'b0 ) begin
					ff_state		<= state_sync_char2;
				end
				else begin
					ff_state		<= state_command;
				end
			end
			else if( ff_state == state_sync_char2 ) begin
				ff_state		<= state_command;
			end
		end
	end

	// --------------------------------------------------------------------
	//	synchronous characters for async mode
	// --------------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_sync_char1	<= 8'd0;
		end
		else if( ff_ireset ) begin
			ff_sync_char1	<= 8'd0;
		end
		else if( ~wr_n && a ) begin
			if( ff_state == state_sync_char1 ) begin
				ff_sync_char1	<= 8'd0;
			end
			else begin
				//	hold
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_sync_char2	<= 8'd0;
		end
		else if( ff_ireset ) begin
			ff_sync_char2	<= 8'd0;
		end
		else if( ~wr_n && a ) begin
			if( ff_state == state_sync_char2 ) begin
				ff_sync_char2	<= 8'd0;
			end
			else begin
				//	hold
			end
		end
	end

	// --------------------------------------------------------------------
	//	clock
	// --------------------------------------------------------------------
	i8251_clk_en u_txc (
		.reset				( reset				),
		.clk21m				( clk21m			),
		.clk				( ~txc_n			),
		.gclk_en			( gtxc_en			),
		.gclk				( gtxc				)
	);

	i8251_clk_en u_rxc (
		.reset				( reset				),
		.clk21m				( clk21m			),
		.clk				( ~rxc_n			),
		.gclk_en			( grxc_en			),
		.gclk				( grxc				)
	);

	// --------------------------------------------------------------------
	//	transmitter
	// --------------------------------------------------------------------
	i8251_transmitter u_transmitter (
		.reset				( reset				),
		.clk21m				( clk21m			),
		.clk_en				( gtxc_en			),
		.clk				( gtxc				),
		.wr					( ff_txc_wr			),
		.a					( ff_txc_a			),
		.d					( ff_txc_d			),
		.ireset				( ff_ireset			),
		.stop_bits			( ff_stop_bits		),
		.even_parity		( ff_even_parity	),
		.parity_en			( ff_parity_en		),
		.char_len			( ff_char_len		),
		.baud_rate			( ff_baud_rate		),
		.txd				( w_txd				),
		.txrdy				( w_txrdy			)
	);

	assign txd		= ~ff_sbrk & (~ff_tx_en | w_txd);
	assign txrdy	=  ff_tx_en & ~cts_n & w_txrdy;

	// --------------------------------------------------------------------
	//	receiver
	// --------------------------------------------------------------------
	i8251_receiver u_receiver (
		.reset				( reset				),
		.clk21m				( clk21m			),
		.clk_en				( grxc_en			),
		.clk				( grxc				),
		.wr					( ff_txc_wr			),
		.a					( ff_txc_a			),
		.d					( ff_txc_d			),
		.ireset				( ff_ireset			),
		.stop_bits			( ff_stop_bits		),
		.even_parity		( ff_even_parity	),
		.parity_en			( ff_parity_en		),
		.char_len			( ff_char_len		),
		.baud_rate			( ff_baud_rate		),
		.rxd				( rxd				),
		.rxrdy				( w_rxrdy			),
		.receive_data		( w_receive_data	)
	);

	assign rxrdy	= ff_tx_en & w_rxrdy;

endmodule
