module tb;
	localparam		clk_base	= (1s /21477270);

	integer			test_item_index;

	reg				clk21m;
	reg				reset;
	reg				req;
	wire			ack;
	reg				wrt;
	reg		[ 7:0]	adr;
	wire	[ 7:0]	dbi;
	reg		[ 7:0]	dbo;
	wire			pMidiTxD;
	reg				pMidiRxD;
	wire			pMidiIntr;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(clk_base/2) begin
		clk21m	<= ~clk21m;
	end

	// -------------------------------------------------------------
	//	dut
	// -------------------------------------------------------------
	tr_midi u_tr_midi (
		.clk21m				( clk21m			),
		.reset				( reset				),
		.req				( req				),
		.ack				( ack				),
		.wrt				( wrt				),
		.adr				( adr[2:0]			),
		.dbi				( dbi				),
		.dbo				( dbo				),
		.pMidiTxD			( pMidiTxD			),
		.pMidiRxD			( pMidiRxD			),
		.pMidiIntr			( pMidiIntr			)
	);

	initial begin
		// --------------------------------------------------------------------
		//	Initial state
		test_item_index			= 0;

		clk21m					= 0;
		reset					= 1;
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		pMidiRxD				= 1;
		repeat( 100 ) @( negedge clk21m );

		reset					= 0;
		repeat( 100 ) @( posedge clk21m );

		// ----------------------------------------
		//	8253
		req						= 1;
		wrt						= 1;
		adr						= 8'hEF;
		dbo						= 8'b00010110;	//	counter0(00), LSB only(01), mode3(011), binary(0)
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hEC;
		dbo						= 8'd8;			//	counter0 = 8
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hEF;
		dbo						= 8'b10110100;	//	counter2(10), LSB/MSB(11), mode2(010), binary(0)
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hEE;
		dbo						= 8'h20;		//	counter2_LSB = 0x20
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hEE;
		dbo						= 8'h4E;		//	counter2_MSB = 0x4E --> counter2 = 20000
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		// ----------------------------------------
		//	8251
		req						= 1;
		wrt						= 1;
		adr						= 8'hE9;
		dbo						= 8'd0;			//	i8251 reset
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 27 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hE9;
		dbo						= 8'd0;			//	i8251 reset
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 27 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hE9;
		dbo						= 8'd0;			//	i8251 reset
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 27 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hE9;
		dbo						= 8'h40;		//	i8251 reset
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 27 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hE9;
		dbo						= 8'b01001110;	//	i8251: 4eh
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hE9;
		dbo						= 8'b00100011;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 27 ) @( posedge clk21m );

		// ----------------------------------------
		//	send MIDI note on
		req						= 1;
		wrt						= 1;
		adr						= 8'hE8;
		dbo						= 8'h90;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 8000 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hE8;
		dbo						= 8'd60;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 8000 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hE8;
		dbo						= 8'd100;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 5 ) begin
			repeat( 2000 ) @( posedge clk21m );
			req						= 1;
			wrt						= 0;
			adr						= 8'hE9;
			dbo						= 0;
			@( posedge clk21m );
			req						= 0;
			wrt						= 0;
			adr						= 0;
			dbo						= 0;
			@( posedge clk21m );
		end

		// ----------------------------------------
		//	8253 counter read
		req						= 1;
		wrt						= 0;
		adr						= 8'hEC;
		dbo						= 0;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 0;
		adr						= 8'hEC;
		dbo						= 0;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 0;
		adr						= 8'hEC;
		dbo						= 0;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 0;
		adr						= 8'hEC;
		dbo						= 0;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 0;
		adr						= 8'hEC;
		dbo						= 0;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 0;
		dbo						= 0;
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hEA;
		dbo						= 0;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 8'hEA;
		dbo						= 0;
		@( posedge clk21m );

		@( negedge pMidiIntr );
		repeat( 6 * 11 ) @( posedge clk21m );

		req						= 1;
		wrt						= 1;
		adr						= 8'hEA;
		dbo						= 0;
		@( posedge clk21m );
		req						= 0;
		wrt						= 0;
		adr						= 8'hEA;
		dbo						= 0;
		@( posedge clk21m );

		@( negedge pMidiIntr );
		repeat( 6 * 11 ) @( posedge clk21m );

		repeat( 2000 ) @( posedge clk21m );
		$finish;
	end
endmodule
