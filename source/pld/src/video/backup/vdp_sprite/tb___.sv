module tb;
	localparam		CLK_BASE	= 1000000000/21480;

	reg					CLK21M;
	reg					RESET;
	reg			[ 1:0]	DOTSTATE;
	reg			[ 2:0]	EIGHTDOTSTATE;
	reg			[ 8:0]	DOTCOUNTERX;
	reg			[ 8:0]	DOTCOUNTERYP;
	reg					BWINDOW_Y;
	wire				PVDPS0SPCOLLISIONINCIDENCE;
	wire				PVDPS0SPOVERMAPPED;
	wire		[ 4:0]	PVDPS0SPOVERMAPPEDNUM;
	wire		[ 8:0]	PVDPS3S4SPCOLLISIONX;
	wire		[ 8:0]	PVDPS5S6SPCOLLISIONY;
	reg					PVDPS0RESETREQ;
	wire				PVDPS0RESETACK;
	reg					PVDPS5RESETREQ;
	wire				PVDPS5RESETACK;
	reg					REG_R1_SP_SIZE;
	reg					REG_R1_SP_ZOOM;
	reg			[ 9:0]	REG_R11R5_SP_ATR_ADDR;
	reg			[ 5:0]	REG_R6_SP_GEN_ADDR;
	reg					REG_R8_COL0_ON;
	reg					REG_R8_SP_OFF;
	reg			[ 7:0]	REG_R23_VSTART_LINE;
	reg			[ 2:0]	REG_R27_H_SCROLL;
	reg					SPMODE2;
	reg					VRAMINTERLEAVEMODE;
	wire				SPVRAMACCESSING;
	reg			[ 7:0]	PRAMDAT;
	wire		[16:0]	PRAMADR;
	wire				SPCOLOROUT;
	wire		[ 3:0]	SPCOLORCODE;

	reg			[ 7:0]	virtual_vram[longint unsigned];
	integer				vram_address;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(CLK_BASE/2) begin
		CLK21M	<= ~CLK21M;
	end

	// -------------------------------------------------------------
	//	DUT
	// -------------------------------------------------------------
	VDP_SPRITE u_dut (
		.CLK21M							( CLK21M						),
		.RESET							( RESET							),
		.DOTSTATE						( DOTSTATE						),
		.EIGHTDOTSTATE					( EIGHTDOTSTATE					),
		.DOTCOUNTERX					( DOTCOUNTERX					),
		.DOTCOUNTERYP					( DOTCOUNTERYP					),
		.BWINDOW_Y						( BWINDOW_Y						),
		.PVDPS0SPCOLLISIONINCIDENCE		( PVDPS0SPCOLLISIONINCIDENCE	),
		.PVDPS0SPOVERMAPPED				( PVDPS0SPOVERMAPPED			),
		.PVDPS0SPOVERMAPPEDNUM			( PVDPS0SPOVERMAPPEDNUM			),
		.PVDPS3S4SPCOLLISIONX			( PVDPS3S4SPCOLLISIONX			),
		.PVDPS5S6SPCOLLISIONY			( PVDPS5S6SPCOLLISIONY			),
		.PVDPS0RESETREQ					( PVDPS0RESETREQ				),
		.PVDPS0RESETACK					( PVDPS0RESETACK				),
		.PVDPS5RESETREQ					( PVDPS5RESETREQ				),
		.PVDPS5RESETACK					( PVDPS5RESETACK				),
		.REG_R1_SP_SIZE					( REG_R1_SP_SIZE				),
		.REG_R1_SP_ZOOM					( REG_R1_SP_ZOOM				),
		.REG_R11R5_SP_ATR_ADDR			( REG_R11R5_SP_ATR_ADDR			),
		.REG_R6_SP_GEN_ADDR				( REG_R6_SP_GEN_ADDR			),
		.REG_R8_COL0_ON					( REG_R8_COL0_ON				),
		.REG_R8_SP_OFF					( REG_R8_SP_OFF					),
		.REG_R23_VSTART_LINE			( REG_R23_VSTART_LINE			),
		.REG_R27_H_SCROLL				( REG_R27_H_SCROLL				),
		.SPMODE2						( SPMODE2						),
		.VRAMINTERLEAVEMODE				( VRAMINTERLEAVEMODE			),
		.SPVRAMACCESSING				( SPVRAMACCESSING				),
		.PRAMDAT						( PRAMDAT						),
		.PRAMADR						( PRAMADR						),
		.SPCOLOROUT						( SPCOLOROUT					),
		.SPCOLORCODE					( SPCOLORCODE					)
	);

	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			DOTSTATE	<= 2'b10;
		end
		else begin
			case( DOTSTATE )
			2'b00:		DOTSTATE <= 2'b01;
			2'b01:		DOTSTATE <= 2'b11;
			2'b11:		DOTSTATE <= 2'b10;
			2'b10:		DOTSTATE <= 2'b00;
			default:	DOTSTATE <= 2'b00;
			endcase
		end
	end

	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			EIGHTDOTSTATE	<= 3'd0;
		end
		else if( DOTSTATE == 2'b10 ) begin
			EIGHTDOTSTATE	<= DOTCOUNTERX[2:0];
		end
		else begin
			//	hold
		end
	end

	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			DOTCOUNTERX		<= -9'd8;
		end
		else if( DOTSTATE == 2'b11 ) begin
			if( DOTCOUNTERX == 9'd341 ) begin
				DOTCOUNTERX <= -9'd8;
			end
			else begin
				DOTCOUNTERX <= DOTCOUNTERX + 9'd1;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			DOTCOUNTERYP		<= -9'd8;
		end
		else if( DOTSTATE == 2'b10 && DOTCOUNTERX == 9'd341 ) begin
			if( DOTCOUNTERYP == 9'd264 ) begin
				DOTCOUNTERYP <= -9'd8;
			end
			else begin
				DOTCOUNTERYP <= DOTCOUNTERYP + 9'd1;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge CLK21M ) begin
		vram_address	<= PRAMADR;
		PRAMDAT			<= virtual_vram[ vram_address ];
	end

	initial begin
		CLK21M		= 0;
		RESET		= 1;

		BWINDOW_Y = 0;
		PVDPS0RESETREQ = 0;
		PVDPS5RESETREQ = 0;
		REG_R1_SP_SIZE = 1;
		REG_R1_SP_ZOOM = 0;
		REG_R11R5_SP_ATR_ADDR = 0;
		REG_R6_SP_GEN_ADDR = 0;
		REG_R8_COL0_ON = 0;
		REG_R8_SP_OFF = 0;
		REG_R23_VSTART_LINE = 0;
		REG_R27_H_SCROLL = 0;
		SPMODE2 = 1;
		VRAMINTERLEAVEMODE = 0;

		virtual_vram[ 17'h03800 ]	= 'hff;
		virtual_vram[ 17'h03801 ]	= 'hff;
		virtual_vram[ 17'h03802 ]	= 'hff;
		virtual_vram[ 17'h03803 ]	= 'hff;
		virtual_vram[ 17'h03804 ]	= 'hff;
		virtual_vram[ 17'h03805 ]	= 'hff;
		virtual_vram[ 17'h03806 ]	= 'hff;
		virtual_vram[ 17'h03807 ]	= 'hff;

		virtual_vram[ 17'h03808 ]	= 'hff;
		virtual_vram[ 17'h03809 ]	= 'hff;
		virtual_vram[ 17'h0380a ]	= 'hff;
		virtual_vram[ 17'h0380b ]	= 'hff;
		virtual_vram[ 17'h0380c ]	= 'hff;
		virtual_vram[ 17'h0380d ]	= 'hff;
		virtual_vram[ 17'h0380e ]	= 'hff;
		virtual_vram[ 17'h0380f ]	= 'hff;

		virtual_vram[ 17'h03810 ]	= 'hff;
		virtual_vram[ 17'h03811 ]	= 'hff;
		virtual_vram[ 17'h03812 ]	= 'hff;
		virtual_vram[ 17'h03813 ]	= 'hff;
		virtual_vram[ 17'h03814 ]	= 'hff;
		virtual_vram[ 17'h03815 ]	= 'hff;
		virtual_vram[ 17'h03816 ]	= 'hff;
		virtual_vram[ 17'h03817 ]	= 'hff;

		virtual_vram[ 17'h03818 ]	= 'hff;
		virtual_vram[ 17'h03819 ]	= 'hff;
		virtual_vram[ 17'h0381a ]	= 'hff;
		virtual_vram[ 17'h0381b ]	= 'hff;
		virtual_vram[ 17'h0381c ]	= 'hff;
		virtual_vram[ 17'h0381d ]	= 'hff;
		virtual_vram[ 17'h0381e ]	= 'hff;
		virtual_vram[ 17'h0381f ]	= 'hff;

		//	#0
		virtual_vram[ 17'h01e00 ]	= 100;
		virtual_vram[ 17'h01e01 ]	= 0;
		virtual_vram[ 17'h01e02 ]	= 0;
		//	#1
		virtual_vram[ 17'h01e04 ]	= 98;
		virtual_vram[ 17'h01e05 ]	= 16;
		virtual_vram[ 17'h01e06 ]	= 0;
		//	#2
		virtual_vram[ 17'h01e08 ]	= 96;
		virtual_vram[ 17'h01e09 ]	= 32;
		virtual_vram[ 17'h01e0A ]	= 0;
		//	#3
		virtual_vram[ 17'h01e0C ]	= 94;
		virtual_vram[ 17'h01e0D ]	= 48;
		virtual_vram[ 17'h01e0E ]	= 0;
		//	#4
		virtual_vram[ 17'h01e10 ]	= 92;
		virtual_vram[ 17'h01e11 ]	= 64;
		virtual_vram[ 17'h01e12 ]	= 0;
		//	#5
		virtual_vram[ 17'h01e14 ]	= 90;
		virtual_vram[ 17'h01e15 ]	= 80;
		virtual_vram[ 17'h01e16 ]	= 0;
		//	#6
		virtual_vram[ 17'h01e18 ]	= 88;
		virtual_vram[ 17'h01e19 ]	= 96;
		virtual_vram[ 17'h01e1A ]	= 0;
		//	#7
		virtual_vram[ 17'h01e1C ]	= 86;
		virtual_vram[ 17'h01e1D ]	= 112;
		virtual_vram[ 17'h01e1E ]	= 0;
		//	#8
		virtual_vram[ 17'h01e20 ]	= 84;
		virtual_vram[ 17'h01e21 ]	= 128;
		virtual_vram[ 17'h01e22 ]	= 0;
		//	#9
		virtual_vram[ 17'h01e24 ]	= 216;
		virtual_vram[ 17'h01e25 ]	= 144;
		virtual_vram[ 17'h01e26 ]	= 0;

		virtual_vram[ 17'h01c00 ]	= 12;
		virtual_vram[ 17'h01c01 ]	= 12;
		virtual_vram[ 17'h01c02 ]	= 12;
		virtual_vram[ 17'h01c03 ]	= 12;
		virtual_vram[ 17'h01c04 ]	= 12;
		virtual_vram[ 17'h01c05 ]	= 12;
		virtual_vram[ 17'h01c06 ]	= 12;
		virtual_vram[ 17'h01c07 ]	= 12;
		virtual_vram[ 17'h01c08 ]	= 0;
		virtual_vram[ 17'h01c09 ]	= 0;
		virtual_vram[ 17'h01c0a ]	= 0;
		virtual_vram[ 17'h01c0b ]	= 0;
		virtual_vram[ 17'h01c0c ]	= 0;
		virtual_vram[ 17'h01c0d ]	= 0;
		virtual_vram[ 17'h01c0e ]	= 0;
		virtual_vram[ 17'h01c0f ]	= 0;

		virtual_vram[ 17'h01c10 ]	= 13;
		virtual_vram[ 17'h01c11 ]	= 13;
		virtual_vram[ 17'h01c12 ]	= 13;
		virtual_vram[ 17'h01c13 ]	= 13;
		virtual_vram[ 17'h01c14 ]	= 13;
		virtual_vram[ 17'h01c15 ]	= 13;
		virtual_vram[ 17'h01c16 ]	= 13;
		virtual_vram[ 17'h01c17 ]	= 13;
		virtual_vram[ 17'h01c18 ]	= 0;
		virtual_vram[ 17'h01c19 ]	= 0;
		virtual_vram[ 17'h01c1a ]	= 0;
		virtual_vram[ 17'h01c1b ]	= 0;
		virtual_vram[ 17'h01c1c ]	= 0;
		virtual_vram[ 17'h01c1d ]	= 0;
		virtual_vram[ 17'h01c1e ]	= 0;
		virtual_vram[ 17'h01c1f ]	= 0;

		virtual_vram[ 17'h01c20 ]	= 14;
		virtual_vram[ 17'h01c21 ]	= 14;
		virtual_vram[ 17'h01c22 ]	= 14;
		virtual_vram[ 17'h01c23 ]	= 14;
		virtual_vram[ 17'h01c24 ]	= 14;
		virtual_vram[ 17'h01c25 ]	= 14;
		virtual_vram[ 17'h01c26 ]	= 14;
		virtual_vram[ 17'h01c27 ]	= 14;
		virtual_vram[ 17'h01c28 ]	= 14;
		virtual_vram[ 17'h01c29 ]	= 14;
		virtual_vram[ 17'h01c2a ]	= 14;
		virtual_vram[ 17'h01c2b ]	= 14;
		virtual_vram[ 17'h01c2c ]	= 14;
		virtual_vram[ 17'h01c2d ]	= 14;
		virtual_vram[ 17'h01c2e ]	= 14;
		virtual_vram[ 17'h01c2f ]	= 14;

		virtual_vram[ 17'h01c30 ]	= 15;
		virtual_vram[ 17'h01c31 ]	= 15;
		virtual_vram[ 17'h01c32 ]	= 15;
		virtual_vram[ 17'h01c33 ]	= 15;
		virtual_vram[ 17'h01c34 ]	= 15;
		virtual_vram[ 17'h01c35 ]	= 15;
		virtual_vram[ 17'h01c36 ]	= 15;
		virtual_vram[ 17'h01c37 ]	= 15;
		virtual_vram[ 17'h01c38 ]	= 15;
		virtual_vram[ 17'h01c39 ]	= 15;
		virtual_vram[ 17'h01c3a ]	= 15;
		virtual_vram[ 17'h01c3b ]	= 15;
		virtual_vram[ 17'h01c3c ]	= 15;
		virtual_vram[ 17'h01c3d ]	= 15;
		virtual_vram[ 17'h01c3e ]	= 15;
		virtual_vram[ 17'h01c3f ]	= 15;

		virtual_vram[ 17'h01c40 ]	= 2;
		virtual_vram[ 17'h01c41 ]	= 2;
		virtual_vram[ 17'h01c42 ]	= 2;
		virtual_vram[ 17'h01c43 ]	= 2;
		virtual_vram[ 17'h01c44 ]	= 2;
		virtual_vram[ 17'h01c45 ]	= 2;
		virtual_vram[ 17'h01c46 ]	= 2;
		virtual_vram[ 17'h01c47 ]	= 2;
		virtual_vram[ 17'h01c48 ]	= 2;
		virtual_vram[ 17'h01c49 ]	= 2;
		virtual_vram[ 17'h01c4a ]	= 2;
		virtual_vram[ 17'h01c4b ]	= 2;
		virtual_vram[ 17'h01c4c ]	= 2;
		virtual_vram[ 17'h01c4d ]	= 2;
		virtual_vram[ 17'h01c4e ]	= 2;
		virtual_vram[ 17'h01c4f ]	= 2;

		virtual_vram[ 17'h01c50 ]	= 3;
		virtual_vram[ 17'h01c51 ]	= 3;
		virtual_vram[ 17'h01c52 ]	= 3;
		virtual_vram[ 17'h01c53 ]	= 3;
		virtual_vram[ 17'h01c54 ]	= 3;
		virtual_vram[ 17'h01c55 ]	= 3;
		virtual_vram[ 17'h01c56 ]	= 3;
		virtual_vram[ 17'h01c57 ]	= 3;
		virtual_vram[ 17'h01c58 ]	= 3;
		virtual_vram[ 17'h01c59 ]	= 3;
		virtual_vram[ 17'h01c5a ]	= 3;
		virtual_vram[ 17'h01c5b ]	= 3;
		virtual_vram[ 17'h01c5c ]	= 3;
		virtual_vram[ 17'h01c5d ]	= 3;
		virtual_vram[ 17'h01c5e ]	= 3;
		virtual_vram[ 17'h01c5f ]	= 3;

		virtual_vram[ 17'h01c60 ]	= 4;
		virtual_vram[ 17'h01c61 ]	= 4;
		virtual_vram[ 17'h01c62 ]	= 4;
		virtual_vram[ 17'h01c63 ]	= 4;
		virtual_vram[ 17'h01c64 ]	= 4;
		virtual_vram[ 17'h01c65 ]	= 4;
		virtual_vram[ 17'h01c66 ]	= 4;
		virtual_vram[ 17'h01c67 ]	= 4;
		virtual_vram[ 17'h01c68 ]	= 4;
		virtual_vram[ 17'h01c69 ]	= 4;
		virtual_vram[ 17'h01c6a ]	= 4;
		virtual_vram[ 17'h01c6b ]	= 4;
		virtual_vram[ 17'h01c6c ]	= 4;
		virtual_vram[ 17'h01c6d ]	= 4;
		virtual_vram[ 17'h01c6e ]	= 4;
		virtual_vram[ 17'h01c6f ]	= 4;

		virtual_vram[ 17'h01c70 ]	= 5;
		virtual_vram[ 17'h01c71 ]	= 5;
		virtual_vram[ 17'h01c72 ]	= 5;
		virtual_vram[ 17'h01c73 ]	= 5;
		virtual_vram[ 17'h01c74 ]	= 5;
		virtual_vram[ 17'h01c75 ]	= 5;
		virtual_vram[ 17'h01c76 ]	= 5;
		virtual_vram[ 17'h01c77 ]	= 5;
		virtual_vram[ 17'h01c78 ]	= 5;
		virtual_vram[ 17'h01c79 ]	= 5;
		virtual_vram[ 17'h01c7a ]	= 5;
		virtual_vram[ 17'h01c7b ]	= 5;
		virtual_vram[ 17'h01c7c ]	= 5;
		virtual_vram[ 17'h01c7d ]	= 5;
		virtual_vram[ 17'h01c7e ]	= 5;
		virtual_vram[ 17'h01c7f ]	= 5;

		virtual_vram[ 17'h01c80 ]	= 6;
		virtual_vram[ 17'h01c81 ]	= 6;
		virtual_vram[ 17'h01c82 ]	= 6;
		virtual_vram[ 17'h01c83 ]	= 6;
		virtual_vram[ 17'h01c84 ]	= 6;
		virtual_vram[ 17'h01c85 ]	= 6;
		virtual_vram[ 17'h01c86 ]	= 6;
		virtual_vram[ 17'h01c87 ]	= 6;
		virtual_vram[ 17'h01c88 ]	= 6;
		virtual_vram[ 17'h01c89 ]	= 6;
		virtual_vram[ 17'h01c8a ]	= 6;
		virtual_vram[ 17'h01c8b ]	= 6;
		virtual_vram[ 17'h01c8c ]	= 6;
		virtual_vram[ 17'h01c8d ]	= 6;
		virtual_vram[ 17'h01c8e ]	= 6;
		virtual_vram[ 17'h01c8f ]	= 6;

		virtual_vram[ 17'h01c90 ]	= 7;
		virtual_vram[ 17'h01c91 ]	= 7;
		virtual_vram[ 17'h01c92 ]	= 7;
		virtual_vram[ 17'h01c93 ]	= 7;
		virtual_vram[ 17'h01c94 ]	= 7;
		virtual_vram[ 17'h01c95 ]	= 7;
		virtual_vram[ 17'h01c96 ]	= 7;
		virtual_vram[ 17'h01c97 ]	= 7;
		virtual_vram[ 17'h01c98 ]	= 7;
		virtual_vram[ 17'h01c99 ]	= 7;
		virtual_vram[ 17'h01c9a ]	= 7;
		virtual_vram[ 17'h01c9b ]	= 7;
		virtual_vram[ 17'h01c9c ]	= 7;
		virtual_vram[ 17'h01c9d ]	= 7;
		virtual_vram[ 17'h01c9e ]	= 7;
		virtual_vram[ 17'h01c9f ]	= 7;

		repeat( 50 ) @( negedge CLK21M );
		RESET		= 0;
		repeat( 10 ) @( posedge CLK21M );

		repeat( 300000 ) begin
			BWINDOW_Y = (DOTCOUNTERYP >= 9'd0 && DOTCOUNTERYP <= 191 ) ? 1'b1 : 1'b0;
			REG_R1_SP_SIZE = 1'b1;
			REG_R1_SP_ZOOM = 1'b0;
			REG_R11R5_SP_ATR_ADDR = 'h01e00 >> 7;
			REG_R6_SP_GEN_ADDR = 'h03800 >> 11;
			REG_R8_COL0_ON = 1'b0;
			REG_R8_SP_OFF = 1'b0;
			REG_R23_VSTART_LINE = 8'd0;
			REG_R27_H_SCROLL = 3'd0;
			SPMODE2 = 1'b1;
			VRAMINTERLEAVEMODE = 1'b0;
			@( posedge CLK21M );
		end
		$finish;
	end
endmodule
