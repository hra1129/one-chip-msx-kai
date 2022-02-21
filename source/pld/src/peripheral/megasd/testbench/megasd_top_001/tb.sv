module tb;
	localparam		clk_base	= 1000000000/21480/2;

	reg				clk42m;
	reg				clk21m;
	reg				reset;
	reg				req;
	reg				wrt;
	reg		[15:0]	adr;
	reg		[ 7:0]	dbo;

	wire			ramreq;
	wire			ramreq_org;
	wire			ramwrt;
	wire			ramwrt_org;
	wire	[19:0]	ramadr;
	wire	[19:0]	ramadr_org;

	wire	[ 7:0]	mmcdbi;
	wire	[ 7:0]	mmcdbi_org;
	wire			mmcena;
	wire			mmcena_org;
	wire			mmcact;
	wire			mmcact_org;

	wire			mmc_ck;
	wire			mmc_ck_org;
	wire			mmc_cs;
	wire			mmc_cs_org;
	wire			mmc_di;
	wire			mmc_di_org;
	wire			mmc_do;

	wire			epc_ck;
	wire			epc_ck_org;
	wire			epc_cs;
	wire			epc_cs_org;
	wire			epc_oe;
	wire			epc_oe_org;
	wire			epc_di;
	wire			epc_di_org;
	wire			epc_do;

	string			s_test_name;
	int				i;

	reg				ff_mmc_ck;
	reg				ff_epc_ck;
	wire			w_mmc_ck_pe;
	wire			w_epc_ck_pe;
	wire			w_mmc_ck_ne;
	wire			w_epc_ck_ne;
	reg		[7:0]	ff_mmc_data;
	reg		[7:0]	ff_epc_data;
	wire			ff_mmc_do;
	wire			ff_epc_do;
	reg		[7:0]	ff_mmc_recv;
	reg		[7:0]	ff_epc_recv;
	reg		[7:0]	data;

	reg				ff_ramwrt;
	reg		[19:0]	ff_ramadr;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(clk_base/2) begin
		clk42m	<= ~clk42m;
	end

	always @( posedge clk42m ) begin
		clk21m	<= ~clk21m;
	end

	// -------------------------------------------------------------
	//	memory bank accesss
	// -------------------------------------------------------------
	always @( posedge clk21m ) begin
		if( ramreq ) begin
			ff_ramwrt <= ramwrt;
			ff_ramadr <= ramadr;
		end
	end

	// -------------------------------------------------------------
	//	data output on SD/EPCS simulator
	// -------------------------------------------------------------
	always @( posedge clk42m ) begin
		ff_mmc_ck <= mmc_ck;
		ff_epc_ck <= epc_ck;
	end

	assign w_mmc_ck_pe = ~ff_mmc_ck &  mmc_ck;
	assign w_epc_ck_pe = ~ff_epc_ck &  epc_ck;
	assign w_mmc_ck_ne =  ff_mmc_ck & ~mmc_ck;
	assign w_epc_ck_ne =  ff_epc_ck & ~epc_ck;

	always @( negedge mmc_ck ) begin
		ff_mmc_data	<= { ff_mmc_data[6:0], 1'b1 };
	end

	always @( posedge mmc_ck ) begin
		ff_mmc_recv <= { ff_mmc_recv[6:0], mmc_di };
	end

	always @( negedge epc_ck ) begin
		ff_epc_data <= { ff_epc_data[6:0], 1'b1 };
	end

	always @( posedge epc_ck ) begin
		ff_epc_recv <= { ff_epc_recv[6:0], epc_di };
	end

	assign ff_mmc_do = ff_mmc_data[7];
	assign ff_epc_do = ff_epc_data[7];

	assign mmc_do = ff_mmc_do;
	assign epc_do = ff_epc_do;

	// -------------------------------------------------------------
	//	dut
	// -------------------------------------------------------------
	megasd u_megasd (
		.clk21m			( clk21m			),
		.reset			( reset				),
		.req			( req				),
		.wrt			( wrt				),
		.adr			( adr				),
		.dbo			( dbo				),
		.ramreq			( ramreq			),
		.ramwrt			( ramwrt			),
		.ramadr			( ramadr			),
		.mmcdbi			( mmcdbi			),
		.mmcena			( mmcena			),
		.mmcact			( mmcact			),
		.mmc_ck			( mmc_ck			),
		.mmc_cs			( mmc_cs			),
		.mmc_di			( mmc_di			),
		.mmc_do			( mmc_do			),
		.epc_ck			( epc_ck			),
		.epc_cs			( epc_cs			),
		.epc_oe			( epc_oe			),
		.epc_di			( epc_di			),
		.epc_do			( epc_do			)
	);

	megasd_org u_megasd_org (
		.clk21m			( clk21m			),
		.reset			( reset				),
		.clkena			( 1'b0				),
		.req			( req				),
		.ack			( 					),
		.wrt			( wrt				),
		.adr			( adr				),
		.dbi			( 					),
		.dbo			( dbo				),
		.ramreq			( ramreq_org		),
		.ramwrt			( ramwrt_org		),
		.ramadr			( ramadr_org		),
		.ramdbi			( 8'd0				),
		.ramdbo			( 					),
		.mmcdbi			( mmcdbi_org		),
		.mmcena			( mmcena_org		),
		.mmcact			( mmcact_org		),
		.mmc_ck			( mmc_ck_org		),
		.mmc_cs			( mmc_cs_org		),
		.mmc_di			( mmc_di_org		),
		.mmc_do			( mmc_do			),
		.epc_ck			( epc_ck_org		),
		.epc_cs			( epc_cs_org		),
		.epc_oe			( epc_oe_org		),
		.epc_di			( epc_di_org		),
		.epc_do			( epc_do			)
	);

	// -------------------------------------------------------------
	//	functions
	// -------------------------------------------------------------
	task write_reg(
		input		[15:0]		address,
		input		[7:0]		data
	);
		@( posedge clk21m );

		adr <= address;
		dbo <= data;
		req <= 1'b1;
		wrt <= 1'b1;
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );

		adr <= 'd0;
		dbo <= 'd0;
		req <= 1'b0;
		wrt <= 1'b0;
		@( posedge clk21m );

		forever begin
			//if( mmcact == 1'b0 && mmcact_org == 1'b0 ) begin
			if( mmcact == 1'b0 ) begin
				break;
			end
			@( posedge clk21m );
		end
		@( posedge clk21m );
	endtask

	// -------------------------------------------------------------
	task read_reg(
		input		[15:0]		address,
		output		[7:0]		data
	);
		@( posedge clk21m );

		adr <= address;
		dbo <= 'd0;
		req <= 1'b1;
		wrt <= 1'b0;
		@( posedge clk21m );
		@( posedge clk21m );
		@( posedge clk21m );

		adr <= 'd0;
		dbo <= 'd0;
		req <= 1'b0;
		wrt <= 1'b0;
		@( posedge clk21m );

		forever begin
			//if( mmcact == 1'b0 && mmcact_org == 1'b0 ) begin
			if( mmcact == 1'b0 ) begin
				break;
			end
			@( posedge clk21m );
		end

		data <= mmcdbi;
		@( posedge clk21m );
	endtask

	// -------------------------------------------------------------
	initial begin
		clk42m = 0;
		clk21m = 0;
		reset = 1;
		req = 0;
		wrt = 0;
		adr = 0;
		dbo = 0;
		ff_mmc_data = 0;
		ff_epc_data = 0;
		s_test_name = "Prepare";

		repeat( 50 ) @( negedge clk21m );
		reset = 0;
		@( posedge clk21m );

		// ---------------------------------------------------------
		s_test_name = "Change BANK0 [001]";
		for( i = 255; i >= 0; i-- ) begin
			write_reg( 16'h6000, i );
		end

		// ---------------------------------------------------------
		s_test_name = "Change BANK0 [002]";
		write_reg( 16'h6001, 200 );
		write_reg( 16'h6002, 128 );
		write_reg( 16'h6432, 64 );
		write_reg( 16'h67FF, 96 );

		// ---------------------------------------------------------
		s_test_name = "Change BANK1 [001]";
		for( i = 255; i >= 0; i-- ) begin
			write_reg( 16'h6800, i );
		end

		// ---------------------------------------------------------
		s_test_name = "Change BANK1 [002]";
		write_reg( 16'h6801, 200 );
		write_reg( 16'h6802, 128 );
		write_reg( 16'h6C32, 64 );
		write_reg( 16'h6FFF, 96 );

		// ---------------------------------------------------------
		s_test_name = "Change BANK2 [001]";
		for( i = 255; i >= 0; i-- ) begin
			write_reg( 16'h7000, i );
		end

		// ---------------------------------------------------------
		s_test_name = "Change BANK2 [002]";
		write_reg( 16'h7001, 200 );
		write_reg( 16'h7002, 128 );
		write_reg( 16'h7432, 64 );
		write_reg( 16'h77FF, 96 );

		// ---------------------------------------------------------
		s_test_name = "Change BANK3 [001]";
		for( i = 255; i >= 0; i-- ) begin
			write_reg( 16'h7800, i );
		end

		// ---------------------------------------------------------
		s_test_name = "Change BANK3 [002]";
		write_reg( 16'h7801, 200 );
		write_reg( 16'h7802, 128 );
		write_reg( 16'h7C32, 64 );
		write_reg( 16'h7FFF, 96 );

		// ---------------------------------------------------------
		s_test_name = "Bank Access [001]";
		write_reg( 16'h6000, 0 | 128 );
		write_reg( 16'h6800, 1 | 128 );
		write_reg( 16'h7000, 2 | 128 );
		write_reg( 16'h7800, 3 | 128 );

		for( i = 0; i < 8192; i++ ) begin
			read_reg( 16'h4000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((0 << 13) + i) );

			read_reg( 16'h6000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((1 << 13) + i) );

			read_reg( 16'h8000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((2 << 13) + i) );

			read_reg( 16'hA000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((3 << 13) + i) );
		end

		for( i = 0; i < 8192; i++ ) begin
			write_reg( 16'h4000 + i, i & 255 );
			assert( ff_ramwrt == 1'b1 );
			assert( ff_ramadr == ((0 << 13) + i) );

			//	It is not possible to write to memory via Bank1.

			write_reg( 16'h8000 + i, i & 255 );
			assert( ff_ramwrt == 1'b1 );
			assert( ff_ramadr == ((2 << 13) + i) );

			write_reg( 16'hA000 + i, i & 255 );
			assert( ff_ramwrt == 1'b1 );
			assert( ff_ramadr == ((3 << 13) + i) );
		end

		// ---------------------------------------------------------
		s_test_name = "Bank Access [002]";
		write_reg( 16'h6000, 124 | 128 );
		write_reg( 16'h6800, 125 | 128 );
		write_reg( 16'h7000, 126 | 128 );
		write_reg( 16'h7800, 127 | 128 );

		for( i = 0; i < 8192; i++ ) begin
			read_reg( 16'h4000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((124 << 13) + i) );

			read_reg( 16'h6000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((125 << 13) + i) );

			read_reg( 16'h8000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((126 << 13) + i) );

			read_reg( 16'hA000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((127 << 13) + i) );
		end

		for( i = 0; i < 8192; i++ ) begin
			write_reg( 16'h4000 + i, i & 255 );
			assert( ff_ramwrt == 1'b1 );
			assert( ff_ramadr == ((124 << 13) + i) );

			//	It is not possible to write to memory via Bank1.

			write_reg( 16'h8000 + i, i & 255 );
			assert( ff_ramwrt == 1'b1 );
			assert( ff_ramadr == ((126 << 13) + i) );

			write_reg( 16'hA000 + i, i & 255 );
			assert( ff_ramwrt == 1'b1 );
			assert( ff_ramadr == ((127 << 13) + i) );
		end

		// ---------------------------------------------------------
		s_test_name = "Bank Access [003]";
		write_reg( 16'h6000, 60 );		//	Bank0 change to Bank#60 with write protected.
		write_reg( 16'h6800, 61 );		//	Bank1 change to Bank#61 with write protected.
		write_reg( 16'h7000, 62 );		//	Bank2 change to Bank#62 with write protected.
		write_reg( 16'h7800, 63 );		//	Bank3 change to Bank#63 with write protected.

		for( i = 0; i < 8192; i++ ) begin
			read_reg( 16'h4000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((60 << 13) + i) );

			read_reg( 16'h6000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((61 << 13) + i) );

			read_reg( 16'h8000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((62 << 13) + i) );

			read_reg( 16'hA000 + i, data );
			assert( ff_ramwrt == 1'b0 );
			assert( ff_ramadr == ((63 << 13) + i) );
		end

		ff_ramwrt = 0;
		ff_ramadr = 0;
		for( i = 0; i < 8192; i++ ) begin
			write_reg( 16'h4000 + i, i & 255 );
			assert( ff_ramwrt == 1'b0 );

			//	It is not possible to write to memory via Bank1.

			write_reg( 16'h8000 + i, i & 255 );
			assert( ff_ramwrt == 1'b0 );

			write_reg( 16'hA000 + i, i & 255 );
			assert( ff_ramwrt == 1'b0 );
		end

		// ---------------------------------------------------------
		s_test_name = "MMC Write [001]";
		write_reg( 16'h6000, 8'h40 );				//	Change to MMC/SD Bank
		write_reg( 16'h5800, 8'b10000000 );		//	Low speed mode and enable datas.
		write_reg( 16'h5800, 8'b00000000 );		//	High speed mode and enable datas.

		ff_mmc_recv = 0;
		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b11001100 );		//	Write data.
		assert( ff_mmc_recv == 8'b11001100 );

		write_reg( 16'h4000, 8'b11110000 );		//	Write data.
		assert( ff_mmc_recv == 8'b11110000 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b11001100 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b11001100 );

		write_reg( 16'h4000, 8'b11110000 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b11110000 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h5000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h5800, 8'b00000001 );		//	High speed mode and disable datas.

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );

		write_reg( 16'h5000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );

		write_reg( 16'h5800, 8'b00000000 );		//	High speed mode and enable datas.

		// ---------------------------------------------------------
		s_test_name = "MMC Read [001]";
		write_reg( 16'h6000, 8'h40 );				//	Change to MMC/SD Bank
		ff_mmc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b10101010 );

		ff_mmc_data = 8'b11001100;
		read_reg( 16'h4000, data );
		assert( data == 8'b11001100 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b11001100 );

		ff_mmc_data = 8'b11110000;
		read_reg( 16'h4000, data );
		assert( data == 8'b11110000 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b11110000 );

		ff_mmc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b10101010 );

		write_reg( 16'h5800, 8'b00000001 );		//	High speed mode and disable datas.

		// ---------------------------------------------------------
		s_test_name = "MMC Write [002]";
		write_reg( 16'h6000, 8'h40 );				//	Change to MMC/SD Bank
		write_reg( 16'h5800, 8'b10000000 );		//	Low speed mode and enable datas.

		ff_mmc_recv = 0;
		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b11001100 );		//	Write data.
		assert( ff_mmc_recv == 8'b11001100 );

		write_reg( 16'h4000, 8'b11110000 );		//	Write data.
		assert( ff_mmc_recv == 8'b11110000 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b11001100 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b11001100 );

		write_reg( 16'h4000, 8'b11110000 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b11110000 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_mmc_recv == 8'b10101010 );

		// ---------------------------------------------------------
		s_test_name = "MMC Read [002]";
		write_reg( 16'h6000, 8'h40 );				//	Change to MMC/SD Bank
		ff_mmc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b10101010 );

		ff_mmc_data = 8'b11001100;
		read_reg( 16'h4000, data );
		assert( data == 8'b11001100 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b11001100 );

		ff_mmc_data = 8'b11110000;
		read_reg( 16'h4000, data );
		assert( data == 8'b11110000 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b11110000 );

		ff_mmc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b10101010 );

		write_reg( 16'h5800, 8'b00000001 );		//	High speed mode and disable datas.

		// ---------------------------------------------------------
		s_test_name = "EPCS Write [001]";
		write_reg( 16'h6000, 8'h60 );				//	Change to EPCS Bank
		write_reg( 16'h5800, 8'b10000000 );		//	Low speed mode and enable datas.
		write_reg( 16'h5800, 8'b00000000 );		//	High speed mode and enable datas.

		ff_epc_recv = 0;
		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b11001100 );		//	Write data.
		assert( ff_epc_recv == 8'b11001100 );

		write_reg( 16'h4000, 8'b11110000 );		//	Write data.
		assert( ff_epc_recv == 8'b11110000 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b11001100 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b11001100 );

		write_reg( 16'h4000, 8'b11110000 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b11110000 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h5000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h5800, 8'b00000001 );		//	High speed mode and disable datas.

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );

		write_reg( 16'h5000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );

		write_reg( 16'h5800, 8'b00000000 );		//	High speed mode and enable datas.

		// ---------------------------------------------------------
		s_test_name = "EPCS Read [001]";
		write_reg( 16'h6000, 8'h60 );				//	Change to EPCS Bank
		ff_epc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b10101010 );

		ff_epc_data = 8'b11001100;
		read_reg( 16'h4000, data );
		assert( data == 8'b11001100 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b11001100 );

		ff_epc_data = 8'b11110000;
		read_reg( 16'h4000, data );
		assert( data == 8'b11110000 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b11110000 );

		ff_epc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b10101010 );

		write_reg( 16'h5800, 8'b00000001 );		//	High speed mode and disable datas.

		// ---------------------------------------------------------
		s_test_name = "EPCS Write [002]";
		write_reg( 16'h6000, 8'h60 );				//	Change to EPCS Bank
		write_reg( 16'h5800, 8'b10000000 );		//	Low speed mode and enable datas.

		ff_epc_recv = 0;
		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b11001100 );		//	Write data.
		assert( ff_epc_recv == 8'b11001100 );

		write_reg( 16'h4000, 8'b11110000 );		//	Write data.
		assert( ff_epc_recv == 8'b11110000 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b10101010 );

		write_reg( 16'h4000, 8'b11001100 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b11001100 );

		write_reg( 16'h4000, 8'b11110000 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b11110000 );

		write_reg( 16'h4000, 8'b10101010 );		//	Write data.
		repeat( 10 ) @( negedge clk21m );
		assert( ff_epc_recv == 8'b10101010 );

		// ---------------------------------------------------------
		s_test_name = "EPCS Read [002]";
		write_reg( 16'h6000, 8'h60 );				//	Change to EPCS Bank
		ff_epc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b10101010 );

		ff_epc_data = 8'b11001100;
		read_reg( 16'h4000, data );
		assert( data == 8'b11001100 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b11001100 );

		ff_epc_data = 8'b11110000;
		read_reg( 16'h4000, data );
		assert( data == 8'b11110000 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b11110000 );

		ff_epc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );
		read_reg( 16'h5800, data );
		assert( data == 8'b00000000 );
		read_reg( 16'h5C00, data );
		assert( data == 8'b10101010 );

		write_reg( 16'h5800, 8'b00000001 );		//	High speed mode and disable datas.

		// ---------------------------------------------------------
		s_test_name = "EPCS Read [002]";
		write_reg( 16'h6000, 8'h60 );				//	Change to EPCS Bank
		write_reg( 16'h5800, 8'b00000001 );		//	High speed mode and disable datas.

		ff_epc_data = 8'b10101010;
		read_reg( 16'h5000, data );
		assert( data == 8'b10101010 );

		ff_epc_data = 8'b10101010;
		read_reg( 16'h4000, data );
		assert( data == 8'b10101010 );

		ff_epc_data = 8'b11110000;
		read_reg( 16'h5000, data );
		assert( data == 8'b11110000 );

		ff_epc_data = 8'b11110000;
		read_reg( 16'h4000, data );
		assert( data == 8'b11110000 );
		write_reg( 16'h5800, 8'b00000001 );		//	High speed mode and disable datas.

		$finish;
	end
endmodule
