//
// s1990.v
//   S1990 device
//   Revision 1.01
//
// Copyright (c) 2007 Takayuki Hara.
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
//	23th,Feburary,2021 Modified by t.hara
//	 - Modified internal firmware ON/OFF SW (R#5 bit6).
//
//	13th,August,2020 Modified by t.hara
//	 - Modified internal firmware ON/OFF SW (R#5 bit6).
//
//	01st,March,2020 Modified by t.hara
//	 - Added "Clear System Timer Function at write E6h."
//
//	05th,December,2019 Modified by t.hara
//	 - Modified read value.
//	 - Modified initial value of processor_mode and rom_mode.
//
//	04th,December,2019 Modified by t.hara
//	 - Converted to VerilogHDL from VHDL
//	 - File name changed to s1990.v from systemtimer.vhd
//	 - Entity name changed to s1990 from system_timer
//
//	xx,xx,2007 First release (System Timer) by t.hara
//	 - System Timer for MSXturboR (3.911usec increment freerun counter)
//

module s1990 (
	input			clk21m,
	input			reset,
	input			mem,
	input			wrt,
	input			req,
	output			ack,
	input	[15:0]	adr,
	output	[ 7:0]	dbi,
	input	[ 7:0]	dbo,
	input			n_z80_m1,
	input			n_r800_m1,
	input			n_z80_ioreq,
	input			n_r800_ioreq,
	input			n_z80_write,
	input			n_r800_write,
	input			n_z80_busack,
	input			n_r800_busack,
	input			step_execute,
	input			step_execute_en,
	output			n_z80_wait,
	output			n_r800_wait,
	output			processor_mode,
	output			rom_mode,
	input			sw_internal_firmware,	//	Internal firmware ON/OFF Dip SW     0: on, 1: off
	output			led_internal_firmware	//	Internal firmware indicator         0: disable, 1: enable
);
	reg		[ 3:0]	ff_register_index;
	reg				ff_switch;				//	Internal firmware ON/OFF SW     0:right(OFF), 1:left(ON)
	reg		[ 1:0]	ff_cpu_change_state;	//	cpu change state                00: R800, 01: Z80, 10: R800->Z80 changing, 11: Z80->R800 changing
	reg				ff_rom_mode;			//	ROM mode                        0:DRAM, 1:ROM
	reg		[ 6:0]	ff_div_counter;
	reg		[15:0]	ff_freerun_counter;
	reg				ff_ack;
	reg				ff_timing;
	reg				ff_r800_en;
	reg				ff_cpu_pause;
	reg				ff_step_execute;
	wire			w_3_911usec;
	wire			w_counter_reset;
	wire	[ 7:0]	w_register_read;
	wire			w_sw_latch_timing;
	localparam		c_div_start_pt		= 7'b1010011;

	//--------------------------------------------------------------
	//	out assignment
	//--------------------------------------------------------------
	assign n_z80_wait		=  ff_cpu_change_state[0] & ~ff_cpu_change_state[1] & ~ff_cpu_pause;
	assign n_r800_wait		= ~ff_cpu_change_state[0] & ~ff_cpu_change_state[1] & ~ff_cpu_pause;
	assign processor_mode	= ff_cpu_change_state[0];
	assign rom_mode			= ff_rom_mode;


	assign ack = ff_ack;
	assign dbi = (adr[1:0] == 2'b00) ? { 4'd0, ff_register_index } :						// E4h  Register index
				 (adr[1:0] == 2'b01) ? w_register_read :									// E5h  Register value
				 (adr[1:0] == 2'b10) ? ff_freerun_counter[7:0] : 							// E6h  System Timer (LSB)
				                       ff_freerun_counter[15:8];							// E7h  System Timer (MSB)

	function [7:0] register_read(
		input	[ 3:0]	register_index,
		input			switch,
		input			processor_mode,
		input			rom_mode
	);
		case( register_index )
		4'd5:		register_read = { 1'b0, switch, 6'd0 };
		4'd6:		register_read = { 1'b0, rom_mode, processor_mode, 5'd0 };
		4'd13:		register_read = 8'h03;
		4'd14:		register_read = 8'h2F;
		4'd15:		register_read = 8'h8B;
		default:	register_read = 8'hFF;
		endcase
	endfunction

	assign w_register_read = register_read( 
		ff_register_index, 
		ff_switch, 
		ff_cpu_change_state[0], 
		ff_rom_mode 
	);

	//--------------------------------------------------------------
	//	reset freerun counter
	//--------------------------------------------------------------
	assign w_counter_reset	= ( adr[7:0] == 8'hE6 ) ? ((!mem) & req & wrt) : 1'b0;

	//--------------------------------------------------------------
	//	3.911usec generator
	//--------------------------------------------------------------
	assign w_3_911usec = ( ff_div_counter == 7'b0000000 ) ? 1'b1 : 1'b0;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_div_counter <= 7'd0;
		end
		else begin
			if( w_counter_reset ) begin
				ff_div_counter <= 7'd0;
			end
			else if( w_3_911usec ) begin
				ff_div_counter <= c_div_start_pt;
			end
			else begin
				ff_div_counter <= ff_div_counter - 7'd1;
			end
		end
	end

	//--------------------------------------------------------------
	//	freerun counter
	//--------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_freerun_counter <= 16'd0;
		end
		else begin
			if( w_counter_reset ) begin
				ff_freerun_counter <= 16'd0;
			end
			else if( w_3_911usec ) begin
				ff_freerun_counter <= ff_freerun_counter + 16'd1;
			end
			else begin
				// hold
			end
		end
	end

	//--------------------------------------------------------------
	//	register write
	//--------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_register_index <= 4'd0;
		end
		else begin
			if( req && !mem && wrt && adr[1:0] == 2'b00 ) begin
				ff_register_index <= dbo[3:0];
			end
			else begin
				//	hold
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_rom_mode			<= 1'b1;
		end
		else begin
			if( req && !mem && wrt && adr[1:0] == 2'b01 ) begin
				case( ff_register_index )
				4'd6:
					ff_rom_mode				<= dbo[6];
				default:
					begin
						//	hold
					end
				endcase
			end
			else begin
				//	hold
			end
		end
	end

	//--------------------------------------------------------------
	//	internal firmware SW
	//--------------------------------------------------------------
	assign w_sw_latch_timing = (ff_freerun_counter == 16'd12784) ? w_3_911usec : 1'b0;		// about 50msec interval

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_switch			<= 1'b0;
		end
		else begin
			if( w_sw_latch_timing ) begin
				ff_switch <= ~sw_internal_firmware;
			end
		end
	end

	assign led_internal_firmware = ff_switch;

	//--------------------------------------------------------------
	//	change CPU state
	//		00: R800
	//		01: Z80
	//		10: Z80 --> R800 changing
	//		11: R800--> Z80 changing
	//--------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_cpu_change_state	<= 2'b01;
		end
		else begin
			if( ff_cpu_change_state[1] == 1'b1 ) begin
				if( ff_cpu_change_state[0] == 1'b1 ) begin
					if( n_r800_busack == 1'b0 ) begin
						ff_cpu_change_state[1] <= 1'b0;
					end
				end
				else begin
					if( n_z80_busack == 1'b0 ) begin
						ff_cpu_change_state[1] <= 1'b0;
					end
				end
			end
			else if( req && !mem && wrt && adr[1:0] == 2'b01 ) begin
				if( ff_register_index == 4'd6 ) begin
					ff_cpu_change_state[0]	<= dbo[5];
					ff_cpu_change_state[1]	<= dbo[5] ^ ff_cpu_change_state[0];
				end
			end
			else begin
				//	hold
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_r800_en	<= 1'b0;
			ff_timing	<= 1'b0;
		end
		else begin
			if(      ~n_z80_ioreq && ~n_z80_write ) begin
				if( ~ff_timing && ff_cpu_change_state[0] ) begin
					ff_r800_en	<= 1'b1;
					ff_timing	<= 1'b1;
				end
			end
			else if( ~n_r800_ioreq && ~n_r800_write ) begin
				if( ~ff_timing && ~ff_cpu_change_state[0] ) begin
					ff_r800_en	<= 1'b0;
					ff_timing	<= 1'b1;
				end
			end
			else begin
				ff_timing	<= 1'b0;
			end
		end
	end

	//--------------------------------------------------------------
	//	Step execution (for debug)
	//--------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_step_execute <= 1'b0;
		end
		else if( step_execute_en ) begin
			if( !ff_step_execute ) begin
				ff_step_execute <= step_execute;
			end
			else if( !n_z80_m1 || !n_r800_m1 ) begin
				ff_step_execute <= 1'b0;
			end
		end
		else begin
			ff_step_execute <= 1'b0;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_cpu_pause <= 1'b0;
		end
		else if( step_execute_en ) begin
			ff_cpu_pause <= ~ff_step_execute;
		end
		else begin
			ff_cpu_pause <= 1'b0;
		end
	end

	//--------------------------------------------------------------
	//	ack
	//--------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_ack <= 1'b0;
		end
		else begin
			ff_ack <= req;
		end
	end
endmodule
