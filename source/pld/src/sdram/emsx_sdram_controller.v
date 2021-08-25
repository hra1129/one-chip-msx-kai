//
// emsx_sdram_controller.v
//
// Copyright (c) 2020-2021 Takayuki Hara
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
// ----------------------------------------------------------------------------
//	2020.May.4th by t.hara
//	-- Separated from emsx_top.
//	-- Redesigned to handle 32MB of space.
//
//	2021.August.25th by t.hara
//	-- The initialization process for some memories is now limited to only 
//	   when the power is turned on.
//	-- Fixed to clear the MainROM area as well.
//
module emsx_sdram_controller (
	input				reset,
	input				sync_reset,			//	synchronous reset
	input				mem_clk,			//	85.92MHz
	input				clk21m,				//	21.48MHz
	input				iSltRfsh_n,
	input	[ 7:0]		vram_slot_ids,
	output				sdram_ready,

	input				mem_vdp_dh_clk,		//	10.74MHz: VideoDHClk 
	input				mem_vdp_dl_clk,		//	 5.37MHz: VideoDLClk 
	input	[24:0]		mem_vdp_address,
	input				mem_vdp_write,		//	not WeVdp_n 
	input	[ 7:0]		mem_vdp_write_data,
	output	[15:0]		mem_vdp_read_data,

	input				mem_req,
	output				mem_ack,
	input	[24:0]		mem_cpu_address,
	input				mem_cpu_write,
	input	[ 7:0]		mem_cpu_write_data,
	output	[ 7:0]		mem_cpu_read_data,

	// SDRAM ports
	output				pMemCke,			// SD-RAM Clock enable
	output				pMemCs_n,			// SD-RAM Chip select
	output				pMemRas_n,			// SD-RAM Row/RAS
	output				pMemCas_n,			// SD-RAM /CAS
	output				pMemWe_n,			// SD-RAM /WE
	output				pMemUdq,			// SD-RAM UDQM
	output				pMemLdq,			// SD-RAM LDQM
	output				pMemBa1,			// SD-RAM Bank select address 1
	output				pMemBa0,			// SD-RAM Bank select address 0
	output	[12:0]		pMemAdr,			// SD-RAM Address
	inout	[15:0]		pMemDat				// SD-RAM Data
);
	localparam	[3:0]	c_sdr_command_mode_register_set		= 4'b0000;
	localparam	[3:0]	c_sdr_command_refresh				= 4'b0001;
	localparam	[3:0]	c_sdr_command_precharge_all			= 4'b0010;
	localparam	[3:0]	c_sdr_command_activate				= 4'b0011;
	localparam	[3:0]	c_sdr_command_write					= 4'b0100;
	localparam	[3:0]	c_sdr_command_read					= 4'b0101;
	localparam	[3:0]	c_sdr_command_burst_stop			= 4'b0110;
	localparam	[3:0]	c_sdr_command_no_operation			= 4'b0111;
	localparam	[3:0]	c_sdr_command_deselect				= 4'b1111;

	localparam	[4:0]	c_main_state_begin_first_wait		= 5'd0;
	localparam	[4:0]	c_main_state_first_wait				= 5'd1;
	localparam	[4:0]	c_main_state_send_precharge_all		= 5'd2;
	localparam	[4:0]	c_main_state_wait_precharge_all		= 5'd3;
	localparam	[4:0]	c_main_state_send_refresh_all1		= 5'd4;
	localparam	[4:0]	c_main_state_wait_refresh_all1		= 5'd5;
	localparam	[4:0]	c_main_state_send_refresh_all2		= 5'd6;
	localparam	[4:0]	c_main_state_wait_refresh_all2		= 5'd7;
	localparam	[4:0]	c_main_state_send_mode_register_set	= 5'd8;
	localparam	[4:0]	c_main_state_wait_mode_register_set	= 5'd9;
	localparam	[4:0]	c_main_state_clear_eseram			= 5'd10;
	localparam	[4:0]	c_main_state_wait_clear_eseram		= 5'd11;
	localparam	[4:0]	c_main_state_clear_esescc1			= 5'd12;
	localparam	[4:0]	c_main_state_wait_clear_esescc1		= 5'd13;
	localparam	[4:0]	c_main_state_clear_esescc2			= 5'd14;
	localparam	[4:0]	c_main_state_wait_clear_esescc2		= 5'd15;
	localparam	[4:0]	c_main_state_clear_mainrom			= 5'd16;
	localparam	[4:0]	c_main_state_wait_clear_mainrom		= 5'd17;
	localparam	[4:0]	c_main_state_ready					= 5'd18;

	localparam	[2:0]	c_sub_state_activate				= 3'd0;
	localparam	[2:0]	c_sub_state_nop1					= 3'd1;
	localparam	[2:0]	c_sub_state_nop2					= 3'd2;
	localparam	[2:0]	c_sub_state_read_or_write			= 3'd3;
	localparam	[2:0]	c_sub_state_nop3					= 3'd4;
	localparam	[2:0]	c_sub_state_nop4					= 3'd5;
	localparam	[2:0]	c_sub_state_data_fetch				= 3'd6;
	localparam	[2:0]	c_sub_state_end_of_sub_state		= 3'd7;

	reg		[ 4:0]	ff_main_state				= c_main_state_begin_first_wait;
	reg		[15:0]	ff_main_timer;
	wire			w_end_of_main_timer;
	wire			w_start_of_sub_state;
	wire			w_end_of_sub_state;

	reg				ff_sub_state_drive			= 1'b0;
	reg		[ 2:0]	ff_sub_state;
	reg				ff_do_refresh;
	wire			w_vdp_phase;

	reg		[ 3:0]	ff_sdram_command			= 4'b0000;
	reg		[14:0]	ff_sdr_address				= 15'd0;
	reg		[15:0]	ff_sdr_data					= 16'd0;
	reg				ff_sdr_upper_dq_mask		= 1'b1;
	reg				ff_sdr_lower_dq_mask		= 1'b1;
	reg		[15:0]	ff_mem_vdp_read_data;
	reg		[ 7:0]	ff_mem_cpu_read_data;
	reg		[ 7:0]	ff_vram_page				= 8'd0;
	reg				ff_mem_ack;
	reg				ff_skip_clear				= 1'b0;

	// --------------------------------------------------------------------
	//	Main State
	// --------------------------------------------------------------------
	always @( posedge mem_clk ) begin
		if( sync_reset ) begin
			ff_main_state	<= c_main_state_begin_first_wait;
		end
		else begin
			case( ff_main_state )
			c_main_state_begin_first_wait:
				ff_main_state	<= c_main_state_first_wait;
			c_main_state_send_precharge_all:
				ff_main_state	<= c_main_state_wait_precharge_all;
			c_main_state_send_refresh_all1:
				ff_main_state	<= c_main_state_wait_refresh_all1;
			c_main_state_send_refresh_all2:
				ff_main_state	<= c_main_state_wait_refresh_all2;
			c_main_state_send_mode_register_set:
				ff_main_state	<= c_main_state_wait_mode_register_set;
			c_main_state_clear_eseram:
				ff_main_state	<= c_main_state_wait_clear_eseram;
			c_main_state_clear_esescc1:
				ff_main_state	<= c_main_state_wait_clear_esescc1;
			c_main_state_clear_esescc2:
				ff_main_state	<= c_main_state_wait_clear_esescc2;
			c_main_state_clear_mainrom:
				ff_main_state	<= c_main_state_wait_clear_mainrom;
			c_main_state_ready:
				begin
					ff_main_state	<= c_main_state_ready;
					ff_skip_clear	<= 1'b1;
				end
			default:
				if( (!ff_sub_state_drive && w_end_of_main_timer) || (ff_sub_state == c_sub_state_end_of_sub_state && !mem_vdp_dh_clk) ) begin
					if( ff_skip_clear && (ff_main_state == c_main_state_wait_mode_register_set) ) begin
						ff_main_state	<= c_main_state_ready;
					end
					else begin
						ff_main_state	<= ff_main_state + 5'd1;
					end
				end
				else begin
					//	hold
				end
			endcase
		end
	end

	assign sdram_ready	= (ff_main_state == c_main_state_ready) ? 1'b1 : 1'b0;

	// --------------------------------------------------------------------
	//	Sub State
	// --------------------------------------------------------------------
	always @( posedge mem_clk ) begin
		if( sync_reset ) begin
			ff_sub_state_drive	<= 1'b0;
		end
		else if( (ff_main_state == c_main_state_wait_mode_register_set) && w_end_of_main_timer ) begin
			ff_sub_state_drive	<= 1'b1;
		end
		else begin
			//	hold
		end
	end

	always @( posedge mem_clk ) begin
		if( sync_reset ) begin
			ff_sub_state	<= c_sub_state_activate;
		end
		else if( ff_sub_state_drive ) begin
			case( ff_sub_state )
			c_sub_state_activate:
				if( w_start_of_sub_state ) begin
					ff_sub_state <= c_sub_state_nop1;
				end
			c_sub_state_end_of_sub_state:
				if( w_end_of_sub_state ) begin
					ff_sub_state <= c_sub_state_activate;
				end
			default:
				ff_sub_state <= ff_sub_state + 3'd1;
			endcase
		end
		else begin
			//	hold
		end
	end

	assign w_start_of_sub_state	=  mem_vdp_dh_clk || (ff_main_state != c_main_state_ready);
	assign w_end_of_sub_state	= !mem_vdp_dh_clk || (ff_main_state != c_main_state_ready);

	always @( posedge mem_clk ) begin
		if( sync_reset ) begin
			ff_do_refresh	<= 1'b0;
		end
		else if( ff_sub_state_drive ) begin
			if( ff_sub_state == c_sub_state_end_of_sub_state ) begin
				if( iSltRfsh_n == 1'b0 && mem_vdp_dl_clk == 1'b1 ) begin
					ff_do_refresh	<= 1'b1;
				end
				else begin
					ff_do_refresh	<= 1'b0;
				end
			end
			else begin
				//	hold
			end
		end
		else begin
			ff_do_refresh	<= 1'b0;
		end
	end

	// --------------------------------------------------------------------
	//	Main Timer
	// --------------------------------------------------------------------
	always @( posedge mem_clk ) begin
		case( ff_main_state )
		c_main_state_begin_first_wait:
			ff_main_timer	<= 16'd42960;		//	500usec
		c_main_state_send_precharge_all:
			ff_main_timer	<= 16'd5;
		c_main_state_send_refresh_all1:
			ff_main_timer	<= 16'd15;
		c_main_state_send_refresh_all2:
			ff_main_timer	<= 16'd15;
		c_main_state_send_mode_register_set:
			ff_main_timer	<= 16'd2;
		default:
			//	ff_main_timer is decrement counter.
			if( !w_end_of_main_timer ) begin
				ff_main_timer	<= ff_main_timer - 16'd1;
			end
			else begin
				//	hold
			end
		endcase
	end

	assign w_end_of_main_timer	= (ff_main_timer == 16'd0) ? 1'b1 : 1'b0;

	// --------------------------------------------------------------------
	//	SDRAM Command Signal
	// --------------------------------------------------------------------
	assign w_vdp_phase	= mem_vdp_dl_clk;

	always @( posedge mem_clk ) begin
		case( ff_main_state )
		c_main_state_send_precharge_all:
			begin
				ff_sdram_command		<= c_sdr_command_precharge_all;
				ff_sdr_upper_dq_mask	<= 1'b1;
				ff_sdr_lower_dq_mask	<= 1'b1;
			end
		c_main_state_send_refresh_all1, c_main_state_send_refresh_all2:
			begin
				ff_sdram_command <= c_sdr_command_refresh;
				ff_sdr_upper_dq_mask	<= 1'b0;
				ff_sdr_lower_dq_mask	<= 1'b0;
			end
		c_main_state_send_mode_register_set:
			begin
				ff_sdram_command <= c_sdr_command_mode_register_set;
				ff_sdr_upper_dq_mask	<= 1'b1;
				ff_sdr_lower_dq_mask	<= 1'b1;
			end
		default:
			if( ff_sub_state_drive ) begin
				case( ff_sub_state )
				c_sub_state_activate:
					if( ff_do_refresh ) begin
						ff_sdram_command		<= c_sdr_command_refresh;
						ff_sdr_upper_dq_mask	<= 1'b0;
						ff_sdr_lower_dq_mask	<= 1'b0;
					end
					else begin
						ff_sdram_command		<= c_sdr_command_activate;
						ff_sdr_upper_dq_mask	<= 1'b1;
						ff_sdr_lower_dq_mask	<= 1'b1;
					end
				c_sub_state_read_or_write:
					if( ff_do_refresh ) begin
						ff_sdram_command		<= c_sdr_command_no_operation;
						ff_sdr_upper_dq_mask	<= 1'b1;
						ff_sdr_lower_dq_mask	<= 1'b1;
					end
					else begin
						if( ff_main_state > c_main_state_wait_mode_register_set && ff_main_state != c_main_state_ready ) begin
							ff_sdram_command		<= c_sdr_command_write;
							ff_sdr_upper_dq_mask	<= ~mem_cpu_address[0];
							ff_sdr_lower_dq_mask	<=  mem_cpu_address[0];
						end
						else if( w_vdp_phase ) begin
							if( mem_vdp_write ) begin
								ff_sdram_command		<= c_sdr_command_write;
								ff_sdr_upper_dq_mask	<= ~mem_vdp_address[16];
								ff_sdr_lower_dq_mask	<=  mem_vdp_address[16];
							end
							else begin
								ff_sdram_command		<= c_sdr_command_read;
								ff_sdr_upper_dq_mask	<= 1'b0;
								ff_sdr_lower_dq_mask	<= 1'b0;
							end
						end
						else begin
							if( mem_cpu_write && mem_req ) begin
								ff_sdram_command		<= c_sdr_command_write;
								ff_sdr_upper_dq_mask	<= ~mem_cpu_address[0];
								ff_sdr_lower_dq_mask	<=  mem_cpu_address[0];
							end
							else begin
								ff_sdram_command		<= c_sdr_command_read;
								ff_sdr_upper_dq_mask	<= 1'b0;
								ff_sdr_lower_dq_mask	<= 1'b0;
							end
						end
					end
				default:
					begin
						ff_sdram_command		<= c_sdr_command_no_operation;
						ff_sdr_upper_dq_mask	<= 1'b1;
						ff_sdr_lower_dq_mask	<= 1'b1;
					end
				endcase
			end
			else begin
				ff_sdram_command		<= c_sdr_command_no_operation;
				ff_sdr_upper_dq_mask	<= 1'b1;
				ff_sdr_lower_dq_mask	<= 1'b1;
			end
		endcase
	end

	always @( posedge mem_clk ) begin
		if( !ff_sub_state_drive ) begin
			ff_sdr_address <= { 2'b00,		//	Bank
				3'b000,						//	Reserved
				1'b1,						//	0: Burst Write, 1: Single Write
				2'b00,						//	Operation mode
				3'b010,						//	CAS Latency 010: 2cyc, 011: 3cyc, others: Reserved
				1'b0,						//	0: Sequential Access, 1: Interleave Access
				3'b000 };					//	Burst length 000: 1, 001: 2, 010: 4, 011: 8, 111: full page (Sequential Access only), others: Reserved
		end
		else begin
			case( ff_sub_state )
			c_sub_state_activate:
				if( ff_main_state == c_main_state_ready ) begin
					if( w_vdp_phase ) begin
						ff_sdr_address <= { mem_vdp_address[24:23], mem_vdp_address[12:0] };		// vdp read/write
					end
					else begin
						ff_sdr_address <= { mem_cpu_address[24:23], mem_cpu_address[13:1] };		// cpu read/write
					end
				end
				else begin
					ff_sdr_address[14:13]	<= 2'd0;
					ff_sdr_address[12: 0]	<= 13'd0;												// Initialize phase
				end
			c_sub_state_read_or_write:
				begin
					ff_sdr_address[12:9] <= 4'b0010;													// A10 = 1 => enable auto precharge
					if( ff_main_state == c_main_state_ready ) begin
						if( w_vdp_phase ) begin
							if( mem_vdp_address[15] == 1'b0 ) begin
								ff_sdr_address[14:13]	<= mem_vdp_address[24:23];
								ff_sdr_address[ 8: 0]	<= { mem_vdp_address[22:20], ff_vram_page[3:0], mem_vdp_address[14:13] };
							end
							else begin
								ff_sdr_address[14:13]	<= mem_vdp_address[24:23];
								ff_sdr_address[ 8: 0]	<= { mem_vdp_address[22:20], ff_vram_page[7:4], mem_vdp_address[14:13] };
							end
						end
						else begin
							ff_sdr_address[14:13]	<= mem_cpu_address[24:23];
							ff_sdr_address[ 8: 0]	<= mem_cpu_address[22:14];
						end
					end
					else begin
						ff_sdr_address[14:13]	<= 2'd0;
						case( ff_main_state )
						c_main_state_wait_clear_esescc2:		//	ESE-SCC2 400000h
							ff_sdr_address[12: 0]	<= 13'b000_0100_0000_00;
						c_main_state_wait_clear_esescc1:		//	ESE-SCC1 500000h
							ff_sdr_address[12: 0]	<= 13'b000_0101_0000_00;
						c_main_state_wait_clear_eseram:			//	ESE-RAM  600000h
							ff_sdr_address[12: 0]	<= 13'b000_0110_0000_00;
						default:
							ff_sdr_address[12: 0]	<= 13'd0;
						endcase
					end
				end
			default:
				begin
					//	hold
				end
			endcase
		end
	end

	always @( posedge mem_clk ) begin
		if( ff_sub_state_drive && ff_sub_state == c_sub_state_read_or_write ) begin
			if( ff_main_state == c_main_state_ready ) begin
				if( w_vdp_phase ) begin
					ff_sdr_data <= { mem_vdp_write_data, mem_vdp_write_data };
				end
				else begin
					ff_sdr_data <= { mem_cpu_write_data, mem_cpu_write_data };
				end
			end
			else begin
				ff_sdr_data <= 16'd0;
			end
		end
		else begin
			ff_sdr_data <= 16'dz;
		end
	end

	always @( posedge mem_clk ) begin
		if( ff_sub_state_drive && ff_sub_state == c_sub_state_data_fetch ) begin
			if( !w_vdp_phase ) begin
				if( mem_cpu_address[0] == 1'b0 ) begin
					ff_mem_cpu_read_data <= pMemDat[ 7:0];
				end
				else begin
					ff_mem_cpu_read_data <= pMemDat[15:8];
				end
			end
		end
	end

	always @( posedge mem_clk ) begin
		if( ff_sub_state_drive && ff_sub_state == c_sub_state_data_fetch ) begin
			if( w_vdp_phase ) begin
				ff_mem_vdp_read_data <= pMemDat;
			end
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_mem_ack <= 1'b0;
		end
		else if( mem_req == 1'b0 ) begin
			ff_mem_ack <= 1'b0;
		end
		else if( mem_vdp_dl_clk == 1'b0 && mem_vdp_dh_clk == 1'b1 ) begin
			ff_mem_ack <= 1'b1;
		end
	end

	always @( posedge clk21m ) begin
		if( mem_vdp_dl_clk == 1'b0 ) begin
			ff_vram_page <= vram_slot_ids;
		end
	end

	assign pMemCke				= 1'b1;
	assign pMemCs_n				= ff_sdram_command[3];
	assign pMemRas_n			= ff_sdram_command[2];
	assign pMemCas_n			= ff_sdram_command[1];
	assign pMemWe_n				= ff_sdram_command[0];

	assign pMemUdq				= ff_sdr_upper_dq_mask;
	assign pMemLdq				= ff_sdr_lower_dq_mask;
	assign pMemBa1				= ff_sdr_address[14];
	assign pMemBa0				= ff_sdr_address[13];

	assign pMemAdr				= ff_sdr_address[12:0];
	assign pMemDat				= ff_sdr_data;

	assign mem_cpu_read_data	= ff_mem_cpu_read_data;
	assign mem_vdp_read_data	= ff_mem_vdp_read_data;

	assign mem_ack				= ff_mem_ack;
endmodule
