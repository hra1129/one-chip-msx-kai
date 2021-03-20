module tb;
	localparam		CLK_BASE	= 1000000000/85920;

	reg					reset;
	reg					sync_reset;
	reg					mem_clk;
	reg					clk21m;
	reg					iSltRfsh_n;
	reg		[ 7:0]		vram_slot_ids;
	wire				sdram_ready;

	wire				mem_vdp_dh_clk;
	wire				mem_vdp_dl_clk;
	reg		[24:0]		mem_vdp_address;
	reg					mem_vdp_write;
	reg		[ 7:0]		mem_vdp_write_data;
	wire	[15:0]		mem_vdp_read_data;

	reg					mem_req;
	wire				mem_ack;
	reg		[24:0]		mem_cpu_address;
	reg					mem_cpu_write;
	reg		[ 7:0]		mem_cpu_write_data;
	wire	[ 7:0]		mem_cpu_read_data;

	wire				pMemCke;
	wire				pMemCs_n;
	wire				pMemRas_n;
	wire				pMemCas_n;
	wire				pMemWe_n;
	wire				pMemUdq;
	wire				pMemLdq;
	wire				pMemBa1;
	wire				pMemBa0;
	wire	[12:0]		pMemAdr;
	wire	[15:0]		pMemDat;

	reg		[ 1:0]		ff_mem_seq				= 2'b0;
	reg		[15:0]		ff_free_run_counter		= 16'd0;
	reg					ff_holdrst_ena			= 1'b0;
	reg		[ 3:0]		ff_hardrst_cnt			= 4'd0;
	wire				w_10hz;
	wire				pSltRst_n;
	reg		[ 3:0]		ff_vdp_clk;
	reg		[ 1:0]		ff_clk_div				= 2'b0;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(CLK_BASE/2) begin
		mem_clk	<= ~mem_clk;
	end

	always @( posedge mem_clk ) begin
		ff_clk_div	<= ff_clk_div + 2'd1;
	end

	assign clk21m	= ff_clk_div[1];

	// -------------------------------------------------------------
	//	DUT
	// -------------------------------------------------------------
	emsx_sdram_controller u_dut (
		.reset					( reset					),
		.sync_reset				( sync_reset			),
		.mem_clk				( mem_clk				),
		.clk21m					( clk21m				),
		.iSltRfsh_n				( iSltRfsh_n			),
		.vram_slot_ids			( vram_slot_ids			),
		.sdram_ready			( sdram_ready			),
		.mem_vdp_dh_clk			( mem_vdp_dh_clk		),
		.mem_vdp_dl_clk			( mem_vdp_dl_clk		),
		.mem_vdp_address		( mem_vdp_address		),
		.mem_vdp_write			( mem_vdp_write			),
		.mem_vdp_write_data		( mem_vdp_write_data	),
		.mem_vdp_read_data		( mem_vdp_read_data		),
		.mem_req				( mem_req				),
		.mem_ack				( mem_ack				),
		.mem_cpu_address		( mem_cpu_address		),
		.mem_cpu_write			( mem_cpu_write			),
		.mem_cpu_write_data		( mem_cpu_write_data	),
		.mem_cpu_read_data		( mem_cpu_read_data		),
		.pMemCke				( pMemCke				),
		.pMemCs_n				( pMemCs_n				),
		.pMemRas_n				( pMemRas_n				),
		.pMemCas_n				( pMemCas_n				),
		.pMemWe_n				( pMemWe_n				),
		.pMemUdq				( pMemUdq				),
		.pMemLdq				( pMemLdq				),
		.pMemBa1				( pMemBa1				),
		.pMemBa0				( pMemBa0				),
		.pMemAdr				( pMemAdr				),
		.pMemDat				( pMemDat				)
	);

	// -------------------------------------------------------------
	//	other circuit
	// -------------------------------------------------------------
	always @( posedge mem_clk ) begin
		ff_mem_seq	<= { ff_mem_seq[0], ~ff_mem_seq[1] };
	end

	always @( posedge mem_clk ) begin
		if( ff_mem_seq == 2'b00 ) begin
			ff_free_run_counter <= ff_free_run_counter + 1;
		end
	end

	always @( posedge mem_clk ) begin
		if( ff_mem_seq == 2'b00 ) begin
			if( pSltRst_n != 1'b0 ) begin
				ff_holdrst_ena <= 1'b0;
				if( ff_hardrst_cnt != 4'b0011 || ff_hardrst_cnt != 4'b0010 ) begin
					ff_hardrst_cnt <= 4'b0000;
				end
			end
			else begin
				if( ff_holdrst_ena == 1'b0 ) begin
					ff_hardrst_cnt <= 4'b1110;				// 1500ms hold reset
					ff_holdrst_ena <= 1'b1;
				end
				else if( w_10hz == 1'b1 && ff_hardrst_cnt != 4'b0001 ) begin
					ff_hardrst_cnt <= ff_hardrst_cnt - 4'd1;
				end
			end
		end
	end

	assign pSltRst_n	= 1'b1;
	assign w_10hz		= 1'b0;

	assign reset		= ( pSltRst_n == 1'b0 && ff_hardrst_cnt != 4'b0001 ) ? 1'b1:
						  ( ff_hardrst_cnt == 4'b0011 || ff_hardrst_cnt == 4'b0010 || !sdram_ready ) ? 1'b1:
						  1'b0;

	always @( posedge mem_clk ) begin
		if( reset ) begin
			ff_vdp_clk	<= 3'd0;
		end
		else begin
			ff_vdp_clk	<= ff_vdp_clk + 1;
		end
	end
	assign mem_vdp_dh_clk	= ff_vdp_clk[2];
	assign mem_vdp_dl_clk	= ~(ff_vdp_clk[3] ^ ff_vdp_clk[2]);

	// -------------------------------------------------------------
	//	sequence
	// -------------------------------------------------------------
	initial begin
		sync_reset				= 0;
		mem_clk					= 0;
		iSltRfsh_n				= 1;
		vram_slot_ids			= 0;
		mem_vdp_address			= 25'b0_0000_0000_0000_0000_0000_1111;
		mem_vdp_write			= 0;
		mem_vdp_write_data		= 0;
		mem_req					= 0;
		mem_cpu_address			= 25'b0_0000_0000_0000_0000_0000_0000;
		mem_cpu_write			= 0;
		mem_cpu_write_data		= 0;

		sync_reset				= 1;
		@( posedge mem_clk );

		sync_reset				= 0;
		@( posedge mem_clk );

		repeat( 3000000 ) @( posedge mem_clk );

		mem_req					= 1;
		mem_cpu_address			= 25'b0_0000_0000_0000_0000_1111_1111;
		mem_cpu_write			= 1;
		mem_cpu_write_data		= 8'hAA;
		repeat( 5000 ) @( posedge mem_clk );

		iSltRfsh_n				= 0;
		repeat( 16 ) @( posedge mem_clk );

		iSltRfsh_n				= 1;
		repeat( 100 ) @( posedge mem_clk );

		$finish;
	end
endmodule
