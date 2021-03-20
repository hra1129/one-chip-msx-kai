module tb;
	localparam		CLK_BASE	= 1000000000/21480;

	reg				clk21m;
	reg				reset;
	reg				req;
	wire			ack;
	reg				wrt;
	reg		[ 7:0]	adr;
	wire	[ 7:0]	dbi;
	reg		[ 7:0]	dbo;
	wire	[ 4:0]	eseram_memory_id;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(CLK_BASE/2) begin
		clk21m	<= ~clk21m;
	end

	// -------------------------------------------------------------
	//	DUT
	// -------------------------------------------------------------
	ocmkai_control_decice u_dut (
		.clk21m				( clk21m			),
		.reset				( reset				),
		.req				( req				),
		.ack				( ack				),
		.wrt				( wrt				),
		.adr				( adr				),
		.dbi				( dbi				),
		.dbo				( dbo				),
		.eseram_memory_id	( eseram_memory_id	)
	);

	// -------------------------------------------------------------
	//	sequence
	// -------------------------------------------------------------
	initial begin
		clk21m		= 0;
		reset		= 1;
		req			= 0;
		wrt			= 0;
		adr			= 0;
		dbo			= 0;
		@( posedge clk21m );

		reset		= 0;
		@( posedge clk21m );

		repeat( 100 ) @( posedge clk21m );

		req			= 1'b1;
		wrt			= 1'b1;
		adr			= 8'h40;
		dbo			= 8'd213;
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );

		req			= 1'b0;
		wrt			= 1'b0;
		adr			= 8'h0;
		dbo			= 8'd0;
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );

		req			= 1'b1;
		wrt			= 1'b1;
		adr			= 8'h41;
		dbo			= 8'd2;
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );

		req			= 1'b0;
		wrt			= 1'b0;
		adr			= 8'h0;
		dbo			= 8'd0;
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );

		req			= 1'b1;
		wrt			= 1'b1;
		adr			= 8'h42;
		dbo			= 8'd123;
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );

		req			= 1'b0;
		wrt			= 1'b0;
		adr			= 8'h0;
		dbo			= 8'd0;
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );

		$finish;
	end
endmodule
