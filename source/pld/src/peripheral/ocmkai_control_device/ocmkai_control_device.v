//
// ocmkai_control_device.v
//	 1chipMSX-Kai Control Device
//	 Revision 1.02
//
// Copyright (c) 2020 Takayuki Hara.
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
//	May/11th/2020 ver1.00 first release by t.hara
//		Impremented major_version, minor_version and eseram_memory_id
//
//	July/28th/2020 ver1.01 added 'activate_step_execution' by t.hara
//
//  August/5th/2020 ver1.02 added 'panamega_is_linear' by t.hara
//
//	Feburary/25th/2021 ver1.03 removed 'step_execution' by t.hara
//

module ocmkai_control_decice (
	input			clk21m,
	input			reset,
	input			req,
	output			ack,
	input			wrt,
	input	[ 7:0]	adr,
	output	[ 7:0]	dbi,
	input	[ 7:0]	dbo,

	output			connected,
	output	[ 4:0]	eseram_memory_id,
	output			req_reset_primary_slot,
	input			ack_reset_primary_slot,
	output			panamega_is_linear
);
	localparam	[ 7:0]	c_major_version		= 8'd1;
	localparam	[ 7:0]	c_minor_version		= 8'd0;

	reg					ff_is_connected;
	reg			[ 7:0]	ff_register_select;
	reg			[ 7:0]	ff_dbi;
	reg					ff_ack;
	wire		[ 7:0]	w_dbi;
	wire				w_data_wrt;

	reg			[ 4:0]	ff_eseram_memory_id;				//	02h: ESE-RAM upper address
	reg					ff_req_reset_primary_slot;			//	03h: Request reset primary slot at read 0000h in memory
	reg					ff_panamega_is_linear;				//	04h: Select PanasonicMegaROM mode

	// --------------------------------------------------------------
	//	Connection
	// --------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_is_connected		<= 1'b0;
		end
		else if( req && wrt && adr == 8'h40 ) begin
			if( dbo == 8'd213 ) begin
				ff_is_connected		<= 1'b1;
			end
			else begin
				ff_is_connected		<= 1'b0;
			end
		end
		else begin
			//	hold
		end
	end

	assign connected	= ff_is_connected;

	// --------------------------------------------------------------
	//	Register Select
	// --------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_register_select	<= 8'd0;
		end
		else if( ff_is_connected ) begin
			if( req && wrt && adr == 8'h41 ) begin
				ff_register_select	<= dbo;
			end
			else begin
				//	hold
			end
		end
		else begin
			//	hold
		end
	end

	// --------------------------------------------------------------
	//	Write Data Registers
	// --------------------------------------------------------------
	assign w_data_wrt	= (ff_is_connected && req && wrt && adr == 8'h42) ? 1'b1 : 1'b0;

	//	ESE-RAM Upper Address
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_eseram_memory_id	<= 5'd0;
		end
		else if( w_data_wrt && ff_register_select == 8'h02 ) begin
			ff_eseram_memory_id	<= dbo[4:0];
		end
	end

	assign eseram_memory_id			= ff_eseram_memory_id;

	//	Request reset primary slot
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_req_reset_primary_slot	<= 1'b0;
		end
		else if( w_data_wrt && ff_register_select == 8'h03 ) begin
			ff_req_reset_primary_slot	<= 1'b1;
		end
		else if( ack_reset_primary_slot ) begin
			ff_req_reset_primary_slot	<= 1'b0;
		end
	end

	assign req_reset_primary_slot	= ff_req_reset_primary_slot;

	//	Select PanasonicMegaROM Mode
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_panamega_is_linear	<= 1'b1;
		end
		else if( w_data_wrt && ff_register_select == 8'h04 ) begin
			ff_panamega_is_linear	<= dbo[0];
		end
	end

	assign panamega_is_linear	= ff_panamega_is_linear;

	// --------------------------------------------------------------
	//	Read Data Registers
	// --------------------------------------------------------------
	assign w_dbi	=
		( ff_register_select == 8'h00 ) ? c_major_version :
		( ff_register_select == 8'h01 ) ? c_minor_version :
		( ff_register_select == 8'h02 ) ? { 3'd0, ff_eseram_memory_id } : 
		( ff_register_select == 8'h04 ) ? { 7'd0, ff_panamega_is_linear } : 8'hFF;

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_dbi	<= 8'hFF;
		end
		else if( ff_is_connected ) begin
			if( req && !wrt ) begin
				case( adr )
				8'h40:		ff_dbi	<= ~8'd213;
				8'h41:		ff_dbi	<= ff_register_select;
				8'h42:		ff_dbi	<= w_dbi;
				default:	ff_dbi	<= 8'hFF;
				endcase
			end
			else begin
				//	hold
			end
		end
		else begin
			ff_dbi	<= 8'hFF;
		end
	end

	always @( posedge clk21m ) begin
		ff_ack	<= req;
	end

	assign dbi		= ff_dbi;
	assign ack		= ff_ack;
endmodule
