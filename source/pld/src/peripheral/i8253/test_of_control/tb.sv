module tb;
	localparam		clk_base	= 10;

	integer			test_item_index;

	reg				reset;
	reg				clk21m;

	reg				clk;
	reg				clk_en;

	//	BUS interface
	reg				cs;
	reg				rd;
	reg				wr;
	reg		[ 1:0]	a;
	reg		[ 7:0]	d;
	wire	[ 7:0]	q;

	reg		[15:0]	counter;
	wire			wr_cw;
	wire			wr_lsb;
	wire			wr_msb;
	wire			wr_trigger;
	wire	[ 7:0]	wr_d;
	wire			mode0;
	wire			mode1;
	wire			mode2;
	wire			mode3;
	wire			mode4;
	wire			mode5;
	wire			bcd;
	reg		[1:0]	ff_clk_div;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(clk_base/2) begin
		clk21m	<= ~clk21m;
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			ff_clk_div	<= 1'd0;
		end
		else begin
			ff_clk_div	<= ff_clk_div + 2'd1;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			clk_en	<= 1'd0;
		end
		else if( ff_clk_div == 2'b11 ) begin
			clk_en	<= 1'b1;
		end
		else begin
			clk_en	<= 1'd0;
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			clk	<= 1'd0;
		end
		else if( clk_en ) begin
			clk	<= ~clk;
		end
		else begin
			//	hold
		end
	end

	// -------------------------------------------------------------
	//	dut
	// -------------------------------------------------------------
	i8253_control u_dut (
		.reset		( reset			),
		.clk21m		( clk21m		),
		.clk		( clk			),
		.clk_en		( clk_en		),
		.cs			( cs			),
		.rd			( rd			),
		.wr			( wr			),
		.a			( a				),
		.d			( d				),
		.q			( q				),
		.counter	( counter		),
		.wr_cw		( wr_cw			),
		.wr_lsb		( wr_lsb		),
		.wr_msb		( wr_msb		),
		.wr_trigger	( wr_trigger	),
		.wr_d		( wr_d			),
		.mode0		( mode0			),
		.mode1		( mode1			),
		.mode2		( mode2			),
		.mode3		( mode3			),
		.mode4		( mode4			),
		.mode5		( mode5			),
		.bcd		( bcd			)
	);

	initial begin
		// --------------------------------------------------------------------
		//	Initial state
		test_item_index			= 0;

		reset					= 1;
		clk21m					= 0;
		cs						= 0;
		rd						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		counter					= 0;

		repeat( 10 ) @( negedge clk21m );
		reset					= 0;
		repeat( 10 ) @( posedge clk21m );

		// --------------------------------------------------------------------
		//	write control word
		test_item_index			= 100;
		@( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b11;
		d						= 8'b00_11_000_0;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		@( posedge clk21m );
		repeat( 11 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b11;
		d						= 8'b00_11_000_0;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		@( posedge clk21m );
		repeat( 11 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b11;
		d						= 8'b00_11_000_0;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		@( posedge clk21m );
		repeat( 11 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b11;
		d						= 8'b00_11_000_0;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		@( posedge clk21m );
		repeat( 11 ) @( posedge clk21m );

		// --------------------------------------------------------------------
		//	RW = 01 : Read/Write least significant byte only.
		test_item_index			= 101;
		@( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b11;
		d						= 8'b00_01_000_0;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b00;
		d						= 8'd123;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b00;
		d						= 8'd123;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		// --------------------------------------------------------------------
		//	RW = 10 : Read/Write most significant byte only.
		test_item_index			= 102;
		@( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b11;
		d						= 8'b00_10_000_0;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b00;
		d						= 8'd123;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b00;
		d						= 8'd123;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		// --------------------------------------------------------------------
		//	RW = 11 : Read/Write least significant byte first, then most significant byte.
		test_item_index			= 103;
		@( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b11;
		d						= 8'b00_11_000_0;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b00;
		d						= 8'd123;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		cs						= 1;
		wr						= 1;
		a						= 2'b00;
		d						= 8'd234;
		@( posedge clk21m );

		cs						= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		repeat( 8 ) @( posedge clk21m );

		$finish;
	end
endmodule
