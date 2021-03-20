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

	wire				REF_PVDPS0SPCOLLISIONINCIDENCE;
	wire				REF_PVDPS0SPOVERMAPPED;
	wire		[ 4:0]	REF_PVDPS0SPOVERMAPPEDNUM;
	wire		[ 8:0]	REF_PVDPS3S4SPCOLLISIONX;
	wire		[ 8:0]	REF_PVDPS5S6SPCOLLISIONY;
	wire				REF_PVDPS0RESETACK;
	wire				REF_PVDPS5RESETACK;
	wire				REF_SPVRAMACCESSING;
	wire				REF_SPCOLOROUT;
	wire		[ 3:0]	REF_SPCOLORCODE;
	wire		[16:0]	REF_PRAMADR;

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

	VDP_SPRITE_OLD u_ref (
		.CLK21M							( CLK21M							),
		.RESET							( RESET								),
		.DOTSTATE						( DOTSTATE							),
		.EIGHTDOTSTATE					( EIGHTDOTSTATE						),
		.DOTCOUNTERX					( DOTCOUNTERX						),
		.DOTCOUNTERYP					( DOTCOUNTERYP						),
		.BWINDOW_Y						( BWINDOW_Y							),
		.PVDPS0SPCOLLISIONINCIDENCE		( REF_PVDPS0SPCOLLISIONINCIDENCE	),
		.PVDPS0SPOVERMAPPED				( REF_PVDPS0SPOVERMAPPED			),
		.PVDPS0SPOVERMAPPEDNUM			( REF_PVDPS0SPOVERMAPPEDNUM			),
		.PVDPS3S4SPCOLLISIONX			( REF_PVDPS3S4SPCOLLISIONX			),
		.PVDPS5S6SPCOLLISIONY			( REF_PVDPS5S6SPCOLLISIONY			),
		.PVDPS0RESETREQ					( PVDPS0RESETREQ					),
		.PVDPS0RESETACK					( REF_PVDPS0RESETACK				),
		.PVDPS5RESETREQ					( PVDPS5RESETREQ					),
		.PVDPS5RESETACK					( REF_PVDPS5RESETACK				),
		.REG_R1_SP_SIZE					( REG_R1_SP_SIZE					),
		.REG_R1_SP_ZOOM					( REG_R1_SP_ZOOM					),
		.REG_R11R5_SP_ATR_ADDR			( REG_R11R5_SP_ATR_ADDR				),
		.REG_R6_SP_GEN_ADDR				( REG_R6_SP_GEN_ADDR				),
		.REG_R8_COL0_ON					( REG_R8_COL0_ON					),
		.REG_R8_SP_OFF					( REG_R8_SP_OFF						),
		.REG_R23_VSTART_LINE			( REG_R23_VSTART_LINE				),
		.REG_R27_H_SCROLL				( REG_R27_H_SCROLL					),
		.SPMODE2						( SPMODE2							),
		.VRAMINTERLEAVEMODE				( VRAMINTERLEAVEMODE				),
		.SPVRAMACCESSING				( REF_SPVRAMACCESSING				),
		.PRAMDAT						( PRAMDAT							),
		.PRAMADR						( REF_PRAMADR						),
		.SPCOLOROUT						( REF_SPCOLOROUT					),
		.SPCOLORCODE					( REF_SPCOLORCODE					)
	);

	always @( posedge RESET or posedge CLK21M ) begin
		if( RESET ) begin
			DOTSTATE	<= 2'b00;
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
			EIGHTDOTSTATE	<= 3'd7;
		end
		else if( DOTSTATE == 2'b10 ) begin
			EIGHTDOTSTATE	<= EIGHTDOTSTATE + 3'd1;
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
			DOTCOUNTERYP		<= 9'd0;
		end
		else if( DOTSTATE == 2'b10 && DOTCOUNTERX == 9'd341 ) begin
			if( DOTCOUNTERYP == 9'd264 ) begin
				DOTCOUNTERYP <= 9'd0;
			end
			else begin
				DOTCOUNTERYP <= DOTCOUNTERYP + 9'd1;
			end
		end
		else begin
			//	hold
		end
	end

	always @( negedge CLK21M ) begin
		if( !RESET ) begin
			assert( PVDPS0SPCOLLISIONINCIDENCE	=== REF_PVDPS0SPCOLLISIONINCIDENCE	);
			assert( PVDPS0SPOVERMAPPED			=== REF_PVDPS0SPOVERMAPPED			);
			assert( PVDPS0SPOVERMAPPEDNUM		=== REF_PVDPS0SPOVERMAPPEDNUM		);
			assert( PVDPS3S4SPCOLLISIONX		=== REF_PVDPS3S4SPCOLLISIONX		);
			assert( PVDPS5S6SPCOLLISIONY		=== REF_PVDPS5S6SPCOLLISIONY		);
			assert( PVDPS0RESETACK				=== REF_PVDPS0RESETACK				);
			assert( PVDPS5RESETACK				=== REF_PVDPS5RESETACK				);
			assert( SPVRAMACCESSING				=== REF_SPVRAMACCESSING				);
			assert( SPCOLOROUT					=== REF_SPCOLOROUT					);
			assert( SPCOLORCODE					=== REF_SPCOLORCODE					);
			assert( PRAMADR						=== REF_PRAMADR						);
		end
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

		repeat( 50 ) @( negedge CLK21M );
		RESET		= 0;
		repeat( 10 ) @( posedge CLK21M );

		repeat( 5000 ) begin
			BWINDOW_Y = 1;
			PVDPS0RESETREQ = $random;
			PVDPS5RESETREQ = $random;
			PRAMDAT = $random;
			REG_R1_SP_SIZE = $random;
			REG_R1_SP_ZOOM = $random;
			REG_R11R5_SP_ATR_ADDR = $random;
			REG_R6_SP_GEN_ADDR = $random;
			REG_R8_COL0_ON = $random;
			REG_R8_SP_OFF = $random;
			REG_R23_VSTART_LINE = $random;
			REG_R27_H_SCROLL = $random;
			SPMODE2 = $random;
			VRAMINTERLEAVEMODE = $random;
			@( posedge CLK21M );
		end
		$finish;
	end
endmodule
