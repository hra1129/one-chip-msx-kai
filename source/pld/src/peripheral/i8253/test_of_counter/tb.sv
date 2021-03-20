module tb;
	localparam		clk_base	= 10;

	integer			test_item_index;

	reg				clk;
	reg				reset;

	reg				clk0_en;
	reg				clk0;
	reg				gate0;
	wire			out0;

	//	Counter
	reg		[ 7:0]	load_counter;
	wire	[15:0]	counter0;

	//	Control signals
	reg				wr_cw;
	reg				wr_lsb;
	reg				wr_msb;
	reg				wr_trigger;
	reg				mode0;
	reg				mode1;
	reg				mode2;
	reg				mode3;
	reg				mode4;
	reg				mode5;
	reg				bcd;

	reg		[1:0]	ff_clk0_div;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(clk_base/2) begin
		clk	<= ~clk;
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			ff_clk0_div	<= 1'd0;
		end
		else begin
			ff_clk0_div	<= ff_clk0_div + 2'd1;
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			clk0_en	<= 1'd0;
		end
		else if( ff_clk0_div == 2'b11 ) begin
			clk0_en	<= 1'b1;
		end
		else begin
			clk0_en	<= 1'd0;
		end
	end

	always @( posedge reset or posedge clk ) begin
		if( reset ) begin
			clk0	<= 1'd0;
		end
		else if( clk0_en ) begin
			clk0	<= ~clk0;
		end
		else begin
			//	hold
		end
	end

	// -------------------------------------------------------------
	//	dut
	// -------------------------------------------------------------
	i8253_counter u_counter (
		.clk				( clk				),
		.reset				( reset				),
		.clk0_en			( clk0_en			),
		.clk0				( clk0				),
		.gate0				( gate0				),
		.out0				( out0				),
		.load_counter		( load_counter		),
		.counter0			( counter0			),
		.wr_cw				( wr_cw				),
		.wr_lsb				( wr_lsb			),
		.wr_msb				( wr_msb			),
		.wr_trigger			( wr_trigger		),
		.mode0				( mode0				),
		.mode1				( mode1				),
		.mode2				( mode2				),
		.mode3				( mode3				),
		.mode4				( mode4				),
		.mode5				( mode5				),
		.bcd				( bcd				)
	);

	initial begin
		// --------------------------------------------------------------------
		//	Initial state
		test_item_index			= 100;

		clk						= 0;
		reset					= 1;

		clk0_en					= 0;
		clk0					= 0;
		gate0					= 0;
		load_counter			= 0;
		wr_cw					= 0;
		wr_lsb					= 0;
		wr_msb					= 0;
		wr_trigger				= 0;
		mode0					= 0;
		mode1					= 0;
		mode2					= 0;
		mode3					= 0;
		mode4					= 0;
		mode5					= 0;
		bcd						= 0;

		repeat( 10 ) @( negedge clk );
		reset					= 0;
		repeat( 10 ) @( posedge clk );
		assert( counter0 == 16'h0000 );
		assert( out0 == 1'b0 );

		// --------------------------------------------------------------------
		//	Mode0
		test_item_index			= 1000;

		wr_cw					= 1;
		mode0					= 1;
		gate0					= 1;
		load_counter			= 0;
		@( posedge clk0 );
		wr_cw					= 0;
		@( posedge clk0 );

		wr_lsb					= 1;
		load_counter			= 4;
		@( posedge clk0 );
		wr_lsb					= 0;
		load_counter			= 0;
		@( posedge clk0 );

		wr_msb					= 1;
		wr_trigger				= 1;
		@( posedge clk0 );
		wr_msb					= 0;
		wr_trigger				= 0;
		@( posedge clk0 );
		repeat( 13 ) @( posedge clk0 );

		// --------------------------------------------------------------------
		//	wr_cw	 Mode0 and control gate0 signal
		test_item_index			= 1000;

		mode0					= 1;
		gate0					= 1;

		wr_lsb					= 1;
		load_counter			= 4;
		wr_cw					= 1;
		@( posedge clk0 );
		wr_lsb					= 0;
		load_counter			= 0;
		wr_cw					= 0;
		@( posedge clk0 );

		wr_msb					= 1;
		wr_trigger				= 1;
		load_counter			= 0;
		@( posedge clk0 );
		wr_msb					= 0;
		wr_trigger				= 0;
		load_counter			= 0;
		@( posedge clk0 );
		assert( out0 == 1'b0 );
		repeat( 4 ) @( posedge clk0 );
		gate0					= 0;
		repeat( 4 ) @( posedge clk0 );
		gate0					= 1;

		repeat( 13 ) @( posedge clk0 );
		mode0					= 0;

		// --------------------------------------------------------------------
		//	wr_cw	 Mode1
		test_item_index			= 1100;

		mode1					= 1;
		gate0					= 0;
		wr_cw					= 0;

		wr_msb					= 1;
		load_counter			= 0;
		@( posedge clk0 );
		wr_msb					= 0;
		load_counter			= 0;
		@( posedge clk0 );
		wr_lsb					= 1;
		wr_trigger				= 1;
		load_counter			= 4;
		@( posedge clk0 );
		wr_lsb					= 0;
		wr_trigger				= 0;
		load_counter			= 0;
		@( posedge clk0 );

		repeat( 8 ) @( posedge clk0 );
		gate0					= 1;
		@( posedge clk0 );
		gate0					= 0;

		repeat( 50 ) @( posedge clk0 );

		// --------------------------------------------------------------------
		//	Mode1 with multiple wr_cw	
		test_item_index			= 1100;

		mode1					= 1;
		gate0					= 0;
		wr_cw					= 0;

		wr_msb					= 1;
		load_counter			= 0;
		@( posedge clk0 );
		wr_msb					= 0;
		load_counter			= 0;
		@( posedge clk0 );
		wr_lsb					= 1;
		wr_trigger				= 1;
		load_counter			= 4;
		@( posedge clk0 );
		wr_lsb					= 0;
		wr_trigger				= 0;
		load_counter			= 0;
		@( posedge clk0 );

		repeat( 8 ) @( posedge clk0 );
		gate0					= 1;

		@( posedge clk0 );
		gate0					= 0;

		repeat( 20 ) @( posedge clk0 );
		gate0					= 1;

		@( posedge clk0 );
		gate0					= 0;

		repeat( 70 ) @( posedge clk0 );
		mode1					= 0;

		// --------------------------------------------------------------------
		//	wr_cw	 Mode2
		test_item_index			= 1200;

		mode2					= 1;
		gate0					= 0;
		wr_cw					= 0;

		wr_msb					= 1;
		load_counter			= 0;
		@( posedge clk0 );
		wr_msb					= 0;
		load_counter			= 0;
		@( posedge clk0 );
		wr_lsb					= 1;
		wr_trigger				= 1;
		load_counter			= 4;
		wr_cw					= 1;
		@( posedge clk0 );
		wr_lsb					= 0;
		wr_trigger				= 0;
		load_counter			= 0;
		wr_cw					= 0;
		@( posedge clk0 );

		repeat( 8 ) @( posedge clk0 );
		gate0					= 1;

		repeat( 50 ) @( posedge clk0 );

		wr_msb					= 0;
		load_counter			= 0;
		@( posedge clk0 );
		wr_lsb					= 1;
		wr_trigger				= 1;
		load_counter			= 20;
		@( posedge clk0 );
		wr_lsb					= 0;
		wr_trigger				= 0;
		load_counter			= 0;
		@( posedge clk0 );

		repeat( 500 ) @( posedge clk0 );

		mode2					= 0;

		// --------------------------------------------------------------------
		//	wr_cw	 Mode3
		test_item_index			= 1300;

		mode3					= 1;
		gate0					= 1;
		wr_cw					= 0;

		wr_msb					= 1;
		load_counter			= 0;
		@( posedge clk0 );
		wr_msb					= 0;
		load_counter			= 0;
		@( posedge clk0 );
		wr_lsb					= 1;
		wr_trigger				= 1;
		load_counter			= 5;
		@( posedge clk0 );
		wr_lsb					= 0;
		wr_trigger				= 0;
		load_counter			= 0;
		@( posedge clk0 );

		repeat( 20 ) @( posedge clk0 );
		gate0					= 0;
		repeat( 3 ) @( posedge clk0 );
		gate0					= 1;

		repeat( 50 ) @( posedge clk0 );
		mode3					= 0;

		// --------------------------------------------------------------------
		//	wr_cw	 Mode4
		test_item_index			= 1400;

		mode4					= 1;
		gate0					= 1;
		wr_cw					= 1;
		@( posedge clk0 );
		wr_cw					= 0;
		@( posedge clk0 );

		wr_msb					= 1;
		load_counter			= 0;
		@( posedge clk0 );
		wr_msb					= 0;
		load_counter			= 0;
		@( posedge clk0 );
		wr_lsb					= 1;
		wr_trigger				= 1;
		load_counter			= 40;
		@( posedge clk0 );
		wr_lsb					= 0;
		wr_trigger				= 0;
		load_counter			= 0;
		@( posedge clk0 );

		repeat( 8 ) @( posedge clk0 );
		gate0					= 0;

		repeat( 8 ) @( posedge clk0 );
		gate0					= 1;

		repeat( 50 ) @( posedge clk0 );
		mode4					= 0;

		// --------------------------------------------------------------------
		//	wr_cw	 Mode5
		test_item_index			= 1500;

		mode5					= 1;
		gate0					= 0;
		wr_cw					= 0;

		wr_msb					= 1;
		load_counter			= 0;
		@( posedge clk0 );
		wr_msb					= 0;
		load_counter			= 0;
		@( posedge clk0 );
		wr_lsb					= 1;
		wr_trigger				= 1;
		load_counter			= 4;
		@( posedge clk0 );
		wr_lsb					= 0;
		wr_trigger				= 0;
		load_counter			= 0;
		@( posedge clk0 );

		repeat( 8 ) @( posedge clk0 );
		gate0					= 1;

		repeat( 50 ) @( posedge clk0 );
		mode5					= 0;

		$finish;
	end
endmodule
