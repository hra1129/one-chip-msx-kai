module tb;
	localparam		CLK_BASE	= 1000000000/21480;
	localparam		LINE_END	= 9'd99;	//	9'd341

	reg				clk21m;
	reg				reset;
	reg		[ 1:0]	dot_state;
	reg		[ 2:0]	eight_dot_state;
	reg				sp_y_test_state;
	reg		[ 8:0]	dot_counter_x;
	reg		[ 8:0]	current_y;
	reg				vdp_s0_reset_timing;
	wire			vdp_s0_sp_overmapped;
	wire	[ 4:0]	vdp_s0_sp_overmapped_num;
	reg				reg_r1_sp_size;
	reg				reg_r1_sp_zoom;
	reg				sp_mode2;
	reg		[ 9:0]	attribute_table_address;
	reg		[ 2:0]	current_render_sp;
	wire	[ 4:0]	render_sp;
	wire	[ 3:0]	render_sp_num;
	reg		[ 7:0]	vram_q;
	wire	[16:0]	vram_a;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(CLK_BASE/2) begin
		clk21m	<= ~clk21m;
	end

	// -------------------------------------------------------------
	//	DUT
	// -------------------------------------------------------------
	vdp_sprite_y_test u_dut (
		.clk21m							( clk21m						),
		.reset							( reset							),
		.dot_state						( dot_state						),
		.eight_dot_state				( eight_dot_state				),
		.sp_y_test_state				( sp_y_test_state				),
		.dot_counter_x					( dot_counter_x					),
		.current_y						( current_y						),
		.vdp_s0_reset_timing			( vdp_s0_reset_timing			),
		.vdp_s0_sp_overmapped			( vdp_s0_sp_overmapped			),
		.vdp_s0_sp_overmapped_num		( vdp_s0_sp_overmapped_num		),
		.reg_r1_sp_size					( reg_r1_sp_size				),
		.reg_r1_sp_zoom					( reg_r1_sp_zoom				),
		.sp_mode2						( sp_mode2						),
		.attribute_table_address		( attribute_table_address		),
		.current_render_sp				( current_render_sp				),
		.render_sp						( render_sp						),
		.render_sp_num					( render_sp_num					),
		.vram_q							( vram_q						),
		.vram_a							( vram_a						)
	);

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			dot_state	<= 2'b00;
		end
		else begin
			case( dot_state )
			2'b00:		dot_state <= 2'b01;
			2'b01:		dot_state <= 2'b11;
			2'b11:		dot_state <= 2'b10;
			2'b10:		dot_state <= 2'b00;
			default:	dot_state <= 2'b00;
			endcase
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			dot_counter_x		<= -9'd1;
		end
		else if( dot_state == 2'b11 ) begin
			if( dot_counter_x == LINE_END ) begin
				dot_counter_x <= -9'd1;
			end
			else begin
				dot_counter_x <= dot_counter_x + 9'd1;
			end
		end
		else begin
			//	hold
		end
	end

	always @( posedge reset or posedge clk21m ) begin
		if( reset ) begin
			eight_dot_state		<= 3'd0;
		end
		else if( dot_state == 2'b10 ) begin
			eight_dot_state		<= dot_counter_x[2:0];
		end
		else begin
			//	hold
		end
	end

	initial begin
		clk21m					= 0;
		reset					= 1;
		sp_y_test_state			= 0;
		current_y				= 0;
		vdp_s0_reset_timing		= 0;
		reg_r1_sp_size			= 0;
		reg_r1_sp_zoom			= 0;
		sp_mode2				= 0;
		attribute_table_address	= 0;
		current_render_sp		= 0;
		vram_q					= 0;

		repeat( 50 ) @( negedge clk21m );
		reset				= 0;
		@( posedge clk21m );

		sp_y_test_state		= 1;
		sp_mode2			= 1;
		@( posedge clk21m );

		repeat( 1000 ) @( posedge clk21m );

		@( dot_counter_x == 9'b111111111 );
		@( posedge clk21m );

		sp_mode2				= 0;
		vram_q					= 208;
		current_y				= 210;
		repeat( 1000 ) @( posedge clk21m );

		vdp_s0_reset_timing		<= 1;
		@( posedge clk21m );
		vdp_s0_reset_timing		<= 0;
		@( posedge clk21m );

		@( dot_counter_x == 9'b111111111 );
		@( posedge clk21m );

		sp_mode2				= 1;
		vram_q					= 216;
		current_y				= 220;
		repeat( 1000 ) @( posedge clk21m );

		vdp_s0_reset_timing		<= 1;
		@( posedge clk21m );
		vdp_s0_reset_timing		<= 0;
		@( posedge clk21m );

		@( dot_counter_x == 9'b111111111 );
		@( posedge clk21m );

		sp_mode2				= 0;
		vram_q					= 208;
		current_y				= 211;
		repeat( 1000 ) @( posedge clk21m );

		vdp_s0_reset_timing		<= 1;
		@( posedge clk21m );
		vdp_s0_reset_timing		<= 0;
		@( posedge clk21m );

		@( dot_counter_x == 9'b111111111 );
		@( posedge clk21m );

		sp_mode2				= 1;
		vram_q					= 216;
		current_y				= 221;
		repeat( 1000 ) @( posedge clk21m );

		$finish;
	end
endmodule
