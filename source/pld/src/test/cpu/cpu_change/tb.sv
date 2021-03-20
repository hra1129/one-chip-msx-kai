module tb;
	localparam		CLK_BASE	= 1000000000/21480;

	reg				clk;
	reg				cpuclk;
	reg		[1:0]	clkdiv3;

	reg				RESET_n;
	reg				WAIT_n ;
	reg				INT_n  ;
	reg				BUSRQ_n;
	wire			z80_M1_n   ;
	wire			z80_MREQ_n ;
	wire			z80_IORQ_n ;
	wire			z80_RD_n   ;
	wire			z80_WR_n   ;
	wire			z80_RFSH_n ;
	wire			z80_HALT_n ;
	wire			z80_BUSAK_n;
	wire	[15:0]	z80_A      ;
	wire	[ 7:0]	z80_D      ;

	wire			r800_M1_n   ;
	wire			r800_MREQ_n ;
	wire			r800_IORQ_n ;
	wire			r800_RD_n   ;
	wire			r800_WR_n   ;
	wire			r800_RFSH_n ;
	wire			r800_HALT_n ;
	wire			r800_BUSAK_n;
	wire	[15:0]	r800_A      ;
	wire	[ 7:0]	r800_D      ;

	reg		[ 7:0]	dbi;
	reg				wrt;
	reg				r800en;
	reg				ff_wait;

	wire			n_z80_write;
	wire			n_r800_write;
	wire			n_z80_wait;
	wire			n_r800_wait;
	wire			processor_mode;
	wire			rom_mode;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always begin
		#(CLK_BASE/2)
		clk	<= 1'b0;

		#(CLK_BASE/2)
		clk	<= 1'b1;
	end

	always @( negedge RESET_n or posedge clk ) begin
		if( !RESET_n ) begin
			cpuclk <= 1'b1;
		end
		else if( clkdiv3 == 2'b10 ) begin
			cpuclk <= ~cpuclk;
		end
	end

	always @( negedge RESET_n or posedge clk ) begin
		if( !RESET_n ) begin
			clkdiv3 <= 2'b10;
		end
		else begin
			if( clkdiv3 == 2'b00 ) begin
				clkdiv3 <= 2'b10;
			end
			else begin
				clkdiv3 <= clkdiv3 - 2'd1;
			end
		end
	end

	// -------------------------------------------------------------
	//	DUT
	// -------------------------------------------------------------
	T80a u_z80 (
		.RESET_n	( RESET_n			),
		.R800_mode	( 1'b0				),
		.CLK_n		( cpuclk			),
		.WAIT_n		( WAIT_n			),
		.INT_n		( INT_n				),
		.NMI_n		( 1'b1				),
		.BUSRQ_n	( n_z80_wait		),
		.M1_n		( z80_M1_n			),
		.MREQ_n		( z80_MREQ_n		),
		.IORQ_n		( z80_IORQ_n		),
		.RD_n		( z80_RD_n			),
		.WR_n		( z80_WR_n			),
		.RFSH_n		( z80_RFSH_n		),
		.HALT_n		( z80_HALT_n		),
		.BUSAK_n	( z80_BUSAK_n		),
		.A			( z80_A				),
		.D			( z80_D				),		//	try state
		.p_PC		( 					)
    );

	T80a u_r800 (
		.RESET_n	( RESET_n			),
		.R800_mode	( 1'b0				),
		.CLK_n		( cpuclk			),
		.WAIT_n		( WAIT_n			),
		.INT_n		( INT_n				),
		.NMI_n		( 1'b1				),
		.BUSRQ_n	( n_r800_wait		),
		.M1_n		( r800_M1_n			),
		.MREQ_n		( r800_MREQ_n		),
		.IORQ_n		( r800_IORQ_n		),
		.RD_n		( r800_RD_n			),
		.WR_n		( r800_WR_n			),
		.RFSH_n		( r800_RFSH_n		),
		.HALT_n		( r800_HALT_n		),
		.BUSAK_n	( r800_BUSAK_n		),
		.A			( r800_A			),
		.D			( r800_D			),		//	try state
		.p_PC		( 					)
    );

	wire			pSltMerq_n;
	wire			pSltIorq_n;
	wire			pSltRd_n;
	wire			pSltWr_n;
	wire	[15:0]	pSltAdr;
	wire	[ 7:0]	pSltDat;

	assign CpuM1_n		= ( processor_mode == 1'b1 ) ? z80_M1_n   : r800_M1_n;
	assign pSltMerq_n	= ( processor_mode == 1'b1 ) ? z80_MREQ_n : r800_MREQ_n;
	assign pSltIorq_n	= ( processor_mode == 1'b1 ) ? z80_IORQ_n : r800_IORQ_n;
	assign pSltRd_n		= ( processor_mode == 1'b1 ) ? z80_RD_n   : r800_RD_n;
	assign pSltWr_n		= ( processor_mode == 1'b1 ) ? z80_WR_n   : r800_WR_n;
	assign CpuRfsh_n	= ( processor_mode == 1'b1 ) ? z80_RFSH_n : r800_RFSH_n;
	assign pSltAdr		= ( processor_mode == 1'b1 ) ? z80_A      : r800_A;
	assign pSltDat		= ( processor_mode == 1'b1 ) ? z80_D      : r800_D;

	reg				iack;
	reg				iSltMerq_n;
	reg				iSltIorq_n;
	reg				xSltRd_n;
	reg				xSltWr_n;
	reg		[15:0]	iSltAdr;
	reg		[ 7:0]	iSltDat;
	reg		[ 7:0]	dlydbi;
	wire			ack;
	wire			req;
	reg				step_execute;
	reg				step_execute_en;

	always @( posedge clk ) begin
		// MSX slot signals
		iSltMerq_n		<= pSltMerq_n;
		iSltIorq_n		<= pSltIorq_n;
		xSltRd_n		<= pSltRd_n;
		xSltWr_n		<= pSltWr_n;
		iSltAdr			<= pSltAdr;
		iSltDat			<= pSltDat;
	end

	always @( negedge RESET_n or posedge clk ) begin
		if( !RESET_n ) begin
			wrt			<= 1'b0;
		end
		else begin
			if( !req ) begin
				wrt		<= ~pSltWr_n;
			end
		end
	end

	always @( negedge RESET_n or posedge clk ) begin
		if( !RESET_n ) begin
			iack <= 1'b0;
		end
		else begin
			if( iSltMerq_n && iSltIorq_n ) begin
				iack <= 1'b0;
			end
			else if( ack ) begin
				iack <= 1'b1;
			end
		end
	end

	wire	[15:0]	adr;
	wire	[ 7:0]	dbo;

	assign mem			=	iSltIorq_n;			// 1=memory area, 0=I/O area
	assign dbo			=	iSltDat;			// CPU data (CPU > device)
	assign adr			=	iSltAdr;			// CPU address (CPU > device)

	assign req			=	( (!iSltMerq_n || !iSltIorq_n) && (!xSltRd_n || !xSltWr_n) && !iack ) ? 1'b1: 1'b0;
	assign ack			=	req;

	//	I/O:E4-E7h	/ S1990
	assign s1990_req	=	( mem == 1'b0 && {adr[7:2], 2'd0} == 8'hE4 ) ? req : (mem & wrt);

	s1990 u_s1990 (
		.clk21m				( clk				),
		.reset				( ~RESET_n			),
		.mem				( mem				),
		.wrt				( wrt				),
		.req				( s1990_req			),
		.ack				( 					),		// open
		.adr				( adr				),
		.dbi				( 					),
		.dbo				( dbo				),
		.n_z80_m1			( z80_M1_n			),
		.n_r800_m1			( r800_M1_n			),
		.n_z80_ioreq		( z80_IORQ_n		),
		.n_r800_ioreq		( r800_IORQ_n		),
		.n_z80_busack		( z80_BUSAK_n		),
		.n_r800_busack		( r800_BUSAK_n		),
		.step_execute		( step_execute		),
		.step_execute_en	( step_execute_en	),
		.n_z80_write		( z80_WR_n			),
		.n_r800_write		( r800_WR_n			),
		.n_z80_wait			( n_z80_wait		),
		.n_r800_wait		( n_r800_wait		),
		.processor_mode		( processor_mode	),
		.rom_mode			( rom_mode			)
	);

	assign z80_D	= (processor_mode == 1'b1 && z80_RD_n  == 1'b0) ? dbi : 8'dz;
	assign r800_D	= (processor_mode == 1'b0 && r800_RD_n == 1'b0) ? dbi : 8'dz;

	always @( negedge RESET_n or posedge clk ) begin
		if( !RESET_n ) begin
			BUSRQ_n	<= 1'b1;
			ff_wait	<= 1'b0;
		end
		else begin
			if(      ~z80_IORQ_n && ~z80_WR_n ) begin
				if( ~ff_wait ) begin
					r800en	<= 1'b1;
					ff_wait	<= 1'b1;
				end
			end
			else if( ~r800_IORQ_n && ~r800_WR_n ) begin
				if( ~ff_wait ) begin
					r800en	<= 1'b0;
					ff_wait	<= 1'b1;
				end
			end
			else begin
				ff_wait	<= 1'b0;
			end
		end
	end

	initial begin
		r800en			<= 1'b0;
		clk				<= 1'b0;
		RESET_n			<= 1'b0;
		WAIT_n			<= 1'b1;
		INT_n			<= 1'b1;
		dbi				<= 8'd0;
		step_execute	<= 1'b0;
		step_execute_en	<= 1'b0;
		repeat( 10 ) @( posedge clk );

		RESET_n			<= 1'b1;
		repeat( 10 ) begin

			@( negedge pSltRd_n );

			//	LD A, 6
			dbi			<= 8'h3e;
			@( negedge pSltRd_n );

			dbi			<= 8'd6;
			@( negedge pSltRd_n );

			//	OUT (0E4h),A
			dbi			<= 8'hd3;
			@( negedge pSltRd_n );

			dbi			<= 8'he4;
			@( negedge pSltRd_n );

			//	LD A, 40h
			dbi			<= 8'h3e;
			@( negedge pSltRd_n );

			dbi			<= 8'h40;
			@( negedge pSltRd_n );

			//	OUT (0E5h),A
			dbi			<= 8'hd3;
			@( negedge pSltRd_n );

			dbi			<= 8'he5;
			@( negedge pSltRd_n );

			//	LD A, 60h
			dbi			<= 8'h3e;
			@( negedge pSltRd_n );

			dbi			<= 8'h40;
			@( negedge pSltRd_n );

			//	OUT (0E5h),A
			dbi			<= 8'hd3;
			@( negedge pSltRd_n );

			dbi			<= 8'he5;
			@( negedge pSltRd_n );
		end

		//	NOP
		repeat( 50 ) begin
			dbi			<= 8'h00;
			@( negedge pSltRd_n );
		end

		//	NOP
		dbi			<= 8'h00;
		step_execute_en	<= 1'b1;
		repeat( 50 ) @( posedge clk );

		step_execute	<= 1'b1;
		@( posedge clk );
		step_execute	<= 1'b0;
		@( posedge clk );

		step_execute_en	<= 1'b1;
		repeat( 50 ) @( posedge clk );

		//	LD A, 3eh
		dbi			<= 8'h3e;
		step_execute_en	<= 1'b1;
		repeat( 50 ) @( posedge clk );

		step_execute	<= 1'b1;
		@( posedge clk );
		step_execute	<= 1'b0;
		@( posedge clk );

		step_execute_en	<= 1'b1;
		repeat( 50 ) @( posedge clk );

		$finish;
	end
endmodule
