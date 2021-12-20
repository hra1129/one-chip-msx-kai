module tb;
	localparam		clk_base	= 1000000000/21480;

	// VDP CLOCK ... 21.477MHZ
	reg				CLK21M;				// IN	STD_LOGIC;
	reg				RESET;				// IN	STD_LOGIC;
	reg				REQ;				// IN	STD_LOGIC;
	wire			ACK;				// OUT	STD_LOGIC;
	reg				WRT;				// IN	STD_LOGIC;
	reg		[15:0]	ADR;				// IN	STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	wire	[7:0]	DBI;				// OUT	STD_LOGIC_VECTOR(  7 DOWNTO 0 );
	reg		[7:0]	DBO;				// IN	STD_LOGIC_VECTOR(  7 DOWNTO 0 );

	wire			INT_N;				// OUT	STD_LOGIC;

	wire			PRAMOE_N;			// OUT	STD_LOGIC;
	wire			PRAMWE_N;			// OUT	STD_LOGIC;
	wire	[16:0]	PRAMADR;			// OUT	STD_LOGIC_VECTOR( 16 DOWNTO 0 );
	reg		[15:0]	PRAMDBI;			// IN	STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	wire	[7:0]	PRAMDBO;			// OUT	STD_LOGIC_VECTOR(  7 DOWNTO 0 );

	reg				VDPSPEEDMODE;		// IN	STD_LOGIC;
	reg		[2:0]	RATIOMODE;			// IN	STD_LOGIC_VECTOR(  2 DOWNTO 0 );
	reg				CENTERYJK_R25_N;	// IN	STD_LOGIC;

	// VIDEO OUTPUT
	wire	[5:0]	PVIDEOR;			// OUT	STD_LOGIC_VECTOR(  5 DOWNTO 0 );
	wire	[5:0]	PVIDEOG;			// OUT	STD_LOGIC_VECTOR(  5 DOWNTO 0 );
	wire	[5:0]	PVIDEOB;			// OUT	STD_LOGIC_VECTOR(  5 DOWNTO 0 );

	wire			PVIDEOHS_N;			// OUT	STD_LOGIC;
	wire			PVIDEOVS_N;			// OUT	STD_LOGIC;
	wire			PVIDEOCS_N;			// OUT	STD_LOGIC;

	wire			PVIDEODHCLK;		// OUT	STD_LOGIC;
	wire			PVIDEODLCLK;		// OUT	STD_LOGIC;

	wire			BLANK_O;			// OUT	STD_LOGIC;

	// DISPLAY RESOLUTION (0=15KHZ, 1=31KHZ)
	reg				DISPRESO;			// IN	STD_LOGIC;

	reg				NTSC_PAL_TYPE;		// IN	STD_LOGIC;
	reg				FORCED_V_MODE;		// IN	STD_LOGIC;
	reg				LEGACY_VGA;			// IN	STD_LOGIC

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(clk_base/2) begin
		CLK21M	<= ~CLK21M;
	end

	// -------------------------------------------------------------
	//	dut
	// -------------------------------------------------------------
	VDP u_vdp (
		.CLK21M				( CLK21M			),
		.RESET				( RESET				),
		.REQ				( REQ				),
		.ACK				( ACK				),
		.WRT				( WRT				),
		.ADR				( ADR				),
		.DBI				( DBI				),
		.DBO				( DBO				),
		.INT_N				( INT_N				),
		.PRAMOE_N			( PRAMOE_N			),
		.PRAMWE_N			( PRAMWE_N			),
		.PRAMADR			( PRAMADR			),
		.PRAMDBI			( PRAMDBI			),
		.PRAMDBO			( PRAMDBO			),
		.VDPSPEEDMODE		( VDPSPEEDMODE		),
		.RATIOMODE			( RATIOMODE			),
		.CENTERYJK_R25_N	( CENTERYJK_R25_N	),
		.PVIDEOR			( PVIDEOR			),
		.PVIDEOG			( PVIDEOG			),
		.PVIDEOB			( PVIDEOB			),
		.PVIDEOHS_N			( PVIDEOHS_N		),
		.PVIDEOVS_N			( PVIDEOVS_N		),
		.PVIDEOCS_N			( PVIDEOCS_N		),
		.PVIDEODHCLK		( PVIDEODHCLK		),
		.PVIDEODLCLK		( PVIDEODLCLK		),
		.BLANK_O			( BLANK_O			),
		.DISPRESO			( DISPRESO			),
		.NTSC_PAL_TYPE		( NTSC_PAL_TYPE		),
		.FORCED_V_MODE		( FORCED_V_MODE		),
		.LEGACY_VGA			( LEGACY_VGA		)
	);

	initial begin
		CLK21M = 0;
		RESET = 1;
		REQ = 0;
		WRT = 0;
		ADR = 0;
		DBO = 0;
		PRAMDBI = 0;
		VDPSPEEDMODE = 0;
		RATIOMODE = 0;
		CENTERYJK_R25_N = 0;
		DISPRESO = 0;
		NTSC_PAL_TYPE = 0;
		FORCED_V_MODE = 0;
		LEGACY_VGA = 0;

		repeat( 50 ) @( negedge CLK21M );
		RESET = 0;
		@( posedge CLK21M );

		repeat( 500000 ) @( negedge CLK21M );
		$finish;
	end
endmodule
