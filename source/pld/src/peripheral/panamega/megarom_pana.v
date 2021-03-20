//
// megarom_pana.v
//	 MegaROM (Panasonic type)
//	 Revision 1.03
//
// Copyright (c) 2020 Takayuki Hara
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
// History
//   Revision 1.00 July/23th/2020 by t.hara
//      First release
//
//   Revision 1.01 August/5th/2020 by t.hara
//      Added linear ROM mode
//
//   Revision 1.02 August/10th/2020 by t.hara
//      Modified register address for bank 5 and 6
//
//   Revision 1.03 Feburary/22th/2021 by t.hara
//      Add internal ROM/RAM connection
//

module megarom_pana (
	input			clk21m,
	input			reset,
	input			clkena,
	input			req,
	output			ack,
	input			wrt,
	input	[15:0]	adr,
	output	[ 7:0]	dbi,
	input	[ 7:0]	dbo,

	input			is_linear_rom,

	output			ramreq,
	output			ramwrt,
	output	[24:0]	ramadr,
	input	[ 7:0]	ramdbi,
	output	[ 7:0]	ramdbo
);
	reg				ff_ack;
	reg				ff_read_rom_bank_en;
	reg				ff_read_mode;
	reg				ff_upper_bit_access_en;
	reg		[ 8:0]	ff_rom_bank0;
	reg		[ 8:0]	ff_rom_bank1;
	reg		[ 8:0]	ff_rom_bank2;
	reg		[ 8:0]	ff_rom_bank3;
	reg		[ 8:0]	ff_rom_bank4;
	reg		[ 8:0]	ff_rom_bank5;
	reg		[ 8:0]	ff_rom_bank6;
	reg		[ 8:0]	ff_rom_bank7;
	wire	[ 8:0]	w_current_bank;
	wire	[11:0]	w_bank_remap;

	//--------------------------------------------------------------
	// ROM bank register access
	//--------------------------------------------------------------
	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_ack	<= 1'b0;
		end
		else begin
			ff_ack	<= req;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_rom_bank0[8:0]		<= 9'd0;
			ff_rom_bank1[8:0]		<= 9'd0;
			ff_rom_bank2[8:0]		<= 9'd0;
			ff_rom_bank3[8:0]		<= 9'd0;
			ff_rom_bank4[8:0]		<= 9'd0;
			ff_rom_bank5[8:0]		<= 9'd0;
			ff_rom_bank6[8:0]		<= 9'd0;
			ff_rom_bank7[8:0]		<= 9'd0;
			ff_read_rom_bank_en		<= 1'b0;
			ff_read_mode			<= 1'b0	;
			ff_upper_bit_access_en	<= 1'b0;
		end
		else if( !is_linear_rom ) begin
			if( req && wrt && adr[15:13] == 3'd3 ) begin
				//	Memory Mapped I/O Port Address on 6000-7FFFh ... Bank Register Write
				case( adr[12:10] )							//	Bank Register Address
				3'b000:		ff_rom_bank0[7:0]	<= dbo;		//	6000h-63FFh
				3'b001:		ff_rom_bank1[7:0]	<= dbo;		//	6400h-67FFh
				3'b010:		ff_rom_bank2[7:0]	<= dbo;		//	6800h-6BFFh
				3'b011:		ff_rom_bank3[7:0]	<= dbo;		//	6C00h-6FFFh
				3'b100:		ff_rom_bank4[7:0]	<= dbo;		//	7000h-73FFh
				3'b101:		ff_rom_bank6[7:0]	<= dbo;		//	7800h-7BFFh
				3'b110:		ff_rom_bank5[7:0]	<= dbo;		//	7400h-77FFh
				default:									//	7C00h-7FFFh
					begin
						if( adr[11:4] == 8'hFF ) begin		//	7FF0h-7FFFh
							if( adr[3:0] == 4'h8 && ff_upper_bit_access_en ) begin	//	7FF8h
								ff_rom_bank0[8]	<= dbo[0];
								ff_rom_bank1[8]	<= dbo[1];
								ff_rom_bank2[8]	<= dbo[2];
								ff_rom_bank3[8]	<= dbo[3];
								ff_rom_bank4[8]	<= dbo[4];
								ff_rom_bank5[8]	<= dbo[5];
								ff_rom_bank6[8]	<= dbo[6];
								ff_rom_bank7[8]	<= dbo[7];
							end
							else if( adr[3:0] == 4'h9 ) begin
								ff_read_rom_bank_en		<= dbo[2];
								ff_read_mode			<= dbo[3];
								ff_upper_bit_access_en	<= dbo[4];
							end
						end
						else begin
							ff_rom_bank7[7:0]	<= dbo;		//	7C00h-7FEFh
						end
					end
				endcase
			end
		end
		else begin
			//	hold
		end
	end

	assign ack		=	ff_ack;
	assign dbi		=	( is_linear_rom                             ) ? ramdbi :
						( adr == 16'h7FF0 && ff_read_rom_bank_en    ) ? ff_rom_bank0[7:0] :
						( adr == 16'h7FF1 && ff_read_rom_bank_en    ) ? ff_rom_bank1[7:0] :
						( adr == 16'h7FF2 && ff_read_rom_bank_en    ) ? ff_rom_bank2[7:0] :
						( adr == 16'h7FF3 && ff_read_rom_bank_en    ) ? ff_rom_bank3[7:0] :
						( adr == 16'h7FF4 && ff_read_rom_bank_en    ) ? ff_rom_bank4[7:0] :
						( adr == 16'h7FF5 && ff_read_rom_bank_en    ) ? ff_rom_bank5[7:0] :
						( adr == 16'h7FF6 && ff_read_rom_bank_en    ) ? ff_rom_bank6[7:0] :
						( adr == 16'h7FF7 && ff_read_rom_bank_en    ) ? ff_rom_bank7[7:0] :
						( adr == 16'h7FF8 && ff_upper_bit_access_en ) ? {ff_rom_bank7[8], ff_rom_bank6[8], ff_rom_bank5[8], ff_rom_bank4[8], ff_rom_bank3[8], ff_rom_bank2[8], ff_rom_bank1[8], ff_rom_bank0[8] } :
						( adr == 16'h7FF9 && ff_read_mode           ) ? { 3'd0, ff_upper_bit_access_en, ff_read_mode, ff_read_rom_bank_en, 2'd0 } :
						ramdbi;

	assign ramreq	=	( is_linear_rom      ) ? req :
						( wrt == 1'b0        ) ? req :
						( adr[15:13] == 3'd3 ) ? 1'b0 :			//	bank register read/write
						req;

	assign w_current_bank	=	( adr[15:13] == 3'd0 ) ? ff_rom_bank0 :
								( adr[15:13] == 3'd1 ) ? ff_rom_bank1 :
								( adr[15:13] == 3'd2 ) ? ff_rom_bank2 :
								( adr[15:13] == 3'd3 ) ? ff_rom_bank3 :
								( adr[15:13] == 3'd4 ) ? ff_rom_bank4 :
								( adr[15:13] == 3'd5 ) ? ff_rom_bank5 :
								( adr[15:13] == 3'd6 ) ? ff_rom_bank6 : 
														 ff_rom_bank7;

	assign w_bank_remap		=	( is_linear_rom                        ) ? { 9'd1_0000_0000,   adr[15:13] } :				//	Bank#         : SDRAM Address : Size : Description
								( w_current_bank[8:5] == 4'b0_000      ) ? { 7'b1_0000_00,     w_current_bank[4:0] } :		//	Bank#000h-01Fh: 1000000h      : 256KB: Built-in software
								( w_current_bank[8:3] == 6'b0_0010_0   ) ? { 9'b1_0000_0100,   w_current_bank[2:0] } :		//	Bank#020h-027h: 1040000h      :  64KB: Built-in software
								( w_current_bank[8:2] == 7'b0_0010_10  ) ? {10'b0_0000_0000_0, w_current_bank[1:0] } :		//	Bank#028h-02Bh: 0000000h      :  32KB: Main-ROM
								( w_current_bank[8:2] == 7'b0_0010_11  ) ? {10'b1_0000_0101_0, w_current_bank[1:0] } :		//	Bank#02Ch-02Fh: 1050000h      :  32KB: Built-in software
								( w_current_bank[8:3] == 6'b0_0011_0   ) ? { 9'b0_0001_0000,   w_current_bank[2:0] } :		//	Bank#030h-037h: 0100000h      :  64KB: DiskBIOS
								( w_current_bank[8:1] == 8'b0_0011_100 ) ? {11'b0_0000_0100_00,w_current_bank[  0] } :		//	Bank#038h-039h: 0040000h      :  16KB: SUB-ROM
								( w_current_bank[8:1] == 8'b0_0011_101 ) ? {11'b0_0000_0100_01,w_current_bank[  0] } :		//	Bank#03Ah-03Bh: 0044000h      :  16KB: KanjiDriver1
								( w_current_bank[8:1] == 8'b0_0011_110 ) ? {11'b0_0000_0100_10,w_current_bank[  0] } :		//	Bank#03Ch-03Dh: 0048000h      :  16KB: KanjiDriver2
								( w_current_bank[8:1] == 8'b0_0011_111 ) ? {11'b0_0000_0010_01,w_current_bank[  0] } :		//	Bank#03Eh-03Fh: 0024000h      :  16KB: MSX-MUSIC
								( w_current_bank[8:6] == 3'b0_01       ) ? { 6'b1_0000_1      ,w_current_bank[5:0] } :		//	Bank#040h-07Fh: 1080000h      : 512KB: MSX-JE DicROM
								( w_current_bank[8:5] == 4'b0_100      ) ? { 7'b1_0001_00     ,w_current_bank[4:0] } :		//	Bank#080h-09Fh: 1100000h      : 256KB: MSX-JE DicRAM
								( w_current_bank[8:5] == 4'b0_101      ) ? { 7'b1_0001_01     ,w_current_bank[4:0] } :		//	Bank#0A0h-0BFh: 1140000h      : 256KB: ROM disk
								( w_current_bank[8:6] == 3'b0_11       ) ? { 6'b1_0001_1      ,w_current_bank[5:0] } :		//	Bank#0C0h-0FFh: 1180000h      : 512KB: ROM disk?
								( w_current_bank[8:7] == 2'b1_0        ) ? { 5'b1_0010        ,w_current_bank[6:0] } :		//	Bank#100h-17Fh: 1200000h      :1024KB: ROM disk
								                                           { 5'b0_1000        ,w_current_bank[6:0] };		//	Bank#180h-1FFh: 0800000h      :1024KB: MapperRAM

	assign ramwrt	=	( is_linear_rom                   ) ? 1'b0 :	//	Linear ROM is not writable.
						( adr[15:13] == 3'd3              ) ? 1'b0 :	//	bank register read/write
						( w_current_bank[8:7] == 2'b1_1   ) ? wrt :		//	MapperRAM
						( w_current_bank[8:5] == 3'b0_100 ) ? wrt :		//	SRAM/DRAM bank
						1'b0;											//	Read only for others bank

	assign ramadr	=	{ w_bank_remap, adr[12:0] };

	assign ramdbo	=	dbo;
endmodule
