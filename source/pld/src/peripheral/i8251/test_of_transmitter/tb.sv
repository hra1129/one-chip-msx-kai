module tb;
	localparam		clk_base	= 10;

	integer			test_item_index;

	reg				reset;
	reg				clk21m;

	reg				clk_en;
	reg				clk;

	//	BUS interface
	reg				wr;
	reg				a;
	reg		[ 7:0]	d;

	//	Mode
	reg				ireset;
	reg		[ 1:0]	stop_bits;
	reg				even_parity;
	reg				parity_en;
	reg		[ 1:0]	char_len;
	reg		[ 1:0]	baud_rate;

	//	Transmitter
	wire			txd;
	wire			txrdy;

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
	i8251_transmitter u_dut (
		.reset			( reset			),
		.clk21m			( clk21m		),
		.clk_en			( clk_en		),
		.clk			( clk			),
		.wr				( wr			),
		.a				( a				),
		.d				( d				),
		.ireset			( ireset		),
		.stop_bits		( stop_bits		),
		.even_parity	( even_parity	),
		.parity_en		( parity_en		),
		.char_len		( char_len		),
		.baud_rate		( baud_rate		),
		.txd			( txd			),
		.txrdy			( txrdy			)
	);

	initial begin
		// --------------------------------------------------------------------
		//	Initial state
		test_item_index			= 0;

		reset					= 1;
		clk21m					= 0;
		wr						= 0;
		a						= 0;
		d						= 0;
		ireset					= 0;
		stop_bits				= 1;
		even_parity				= 0;
		parity_en				= 0;
		char_len				= 3;
		baud_rate				= 2;

		repeat( 10 ) @( negedge clk21m );
		reset					= 0;
		repeat( 10 ) @( posedge clk21m );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 100;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 0;	//	parity   : disable
		char_len				= 3;	//	char len : 8bit
		baud_rate				= 2;	//	baud rate: x1/16

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 101;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 0;	//	parity   : disable
		char_len				= 3;	//	char len : 8bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 102;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 0;	//	parity   : disable
		char_len				= 3;	//	char len : 8bit
		baud_rate				= 3;	//	baud rate: x1/64

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 103;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 2;	//	stop bit : 1.5bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 0;	//	parity   : disable
		char_len				= 3;	//	char len : 8bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 104;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 3;	//	stop bit : 2bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 0;	//	parity   : disable
		char_len				= 3;	//	char len : 8bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 105;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 1;	//	parity   : enable
		char_len				= 3;	//	char len : 8bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 106;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 1;	//	parity   : even
		parity_en				= 1;	//	parity   : enable
		char_len				= 3;	//	char len : 8bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 107;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : even
		parity_en				= 0;	//	parity   : disable
		char_len				= 0;	//	char len : 5bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 108;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : even
		parity_en				= 0;	//	parity   : disable
		char_len				= 1;	//	char len : 6bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 109;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : even
		parity_en				= 0;	//	parity   : disable
		char_len				= 2;	//	char len : 7bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 110;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 1;	//	parity   : enable
		char_len				= 0;	//	char len : 5bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 111;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 1;	//	parity   : enable
		char_len				= 1;	//	char len : 6bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		// --------------------------------------------------------------------
		//	
		test_item_index			= 112;
		@( posedge clk21m );
		@( posedge clk );

		stop_bits				= 1;	//	stop bit : 1bit
		even_parity				= 0;	//	parity   : odd
		parity_en				= 1;	//	parity   : enable
		char_len				= 2;	//	char len : 7bit
		baud_rate				= 1;	//	baud rate: x1

		wr						= 1;
		d						= 8'haa;
		@( posedge clk );

		wr						= 0;
		d						= 0;
		@( posedge clk );

		@( posedge txrdy );
		repeat( 20 ) @( posedge clk );

		$finish;
	end
endmodule
