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
		REG_R1_SP_SIZE = 0;
		REG_R1_SP_ZOOM = 0;
		REG_R11R5_SP_ATR_ADDR = 0;
		REG_R6_SP_GEN_ADDR = 0;
		REG_R8_COL0_ON = 0;
		REG_R8_SP_OFF = 0;
		REG_R23_VSTART_LINE = 0;
		REG_R27_H_SCROLL = 0;
		SPMODE2 = 0;
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

		virtual_vram[ 17'h01b00 ]	= 0;
		virtual_vram[ 17'h01b01 ]	= 0;
		virtual_vram[ 17'h01b02 ]	= 0;
		virtual_vram[ 17'h01b03 ]	= 12;

		virtual_vram[ 17'h01b04 ]	= 0;
		virtual_vram[ 17'h01b05 ]	= 32;
		virtual_vram[ 17'h01b06 ]	= 0;
		virtual_vram[ 17'h01b07 ]	= 13;

		virtual_vram[ 17'h01b08 ]	= 0;
		virtual_vram[ 17'h01b09 ]	= 64;
		virtual_vram[ 17'h01b0A ]	= 0;
		virtual_vram[ 17'h01b0B ]	= 12;

		virtual_vram[ 17'h01b0C ]	= 0;
		virtual_vram[ 17'h01b0D ]	= 96;
		virtual_vram[ 17'h01b0E ]	= 0;
		virtual_vram[ 17'h01b0F ]	= 13;

		virtual_vram[ 17'h01b10 ]	= 0;
		virtual_vram[ 17'h01b11 ]	= 128;
		virtual_vram[ 17'h01b12 ]	= 0;
		virtual_vram[ 17'h01b13 ]	= 12;

		virtual_vram[ 17'h01b14 ]	= 0;
		virtual_vram[ 17'h01b15 ]	= 160;
		virtual_vram[ 17'h01b16 ]	= 0;
		virtual_vram[ 17'h01b17 ]	= 13;

		virtual_vram[ 17'h01b18 ]	= 0;
		virtual_vram[ 17'h01b19 ]	= 192;
		virtual_vram[ 17'h01b1A ]	= 0;
		virtual_vram[ 17'h01b1B ]	= 12;

		virtual_vram[ 17'h01b1C ]	= 0;
		virtual_vram[ 17'h01b1D ]	= 224;
		virtual_vram[ 17'h01b1E ]	= 0;
		virtual_vram[ 17'h01b1F ]	= 13;

		virtual_vram[ 17'h01b20 ]	= 208;
		virtual_vram[ 17'h01b21 ]	= 0;
		virtual_vram[ 17'h01b22 ]	= 0;
		virtual_vram[ 17'h01b23 ]	= 2;

		repeat( 50 ) @( negedge CLK21M );
		RESET		= 0;
		repeat( 10 ) @( posedge CLK21M );

		repeat( 100000 ) begin
			BWINDOW_Y = (DOTCOUNTERYP >= 9'd0 && DOTCOUNTERYP <= 191 ) ? 1'b1 : 1'b0;
			REG_R1_SP_SIZE = 1'b1;
			REG_R1_SP_ZOOM = 1'b1;
			REG_R11R5_SP_ATR_ADDR = 'h1b00 >> 7;
			REG_R6_SP_GEN_ADDR = 'h3800 >> 11;
			REG_R8_COL0_ON = 1'b0;
			REG_R8_SP_OFF = 1'b0;
			REG_R23_VSTART_LINE = 8'd0;
			REG_R27_H_SCROLL = 3'd0;
			SPMODE2 = 1'b0;
			VRAMINTERLEAVEMODE = 1'b0;
			@( posedge CLK21M );
		end
		$finish;
	end
endmodule
