module tb;
	localparam		CLK_BASE	= 1000000000/21480;
	localparam		LINE_END	= 9'd341;

	reg				clk21m;
	reg				reset;

	reg		[ 1:0]	dot_state;
	reg		[ 2:0]	eight_dot_state;
	reg				sp_draw_state;

	reg		[ 8:0]	dot_counter_x;
	reg		[ 8:0]	current_y;
	reg		[ 9:0]	attribute_table_address;
	reg		[ 5:0]	pattern_gentbl_address;

	reg				vdp_s0_reset_timing;
	reg				vdp_s5_reset_timing;

	wire	[ 2:0]	current_render_sp;
	reg		[ 4:0]	render_sp;
	reg		[ 3:0]	render_sp_num;

	wire	[ 6:0]	draw_xeven_adr;
	wire	[ 6:0]	draw_xodd_adr;
	wire			draw_xeven_write;
	wire			draw_xodd_write;
	wire	[ 7:0]	draw_xeven_pixel;
	wire	[ 7:0]	draw_xodd_pixel;

	reg		[ 7:0]	line_buffer_xeven_q;
	reg		[ 7:0]	line_buffer_xodd_q;

	wire			vdp_s0_sp_collision_incidence;
	wire	[ 8:0]	vdp_s3_s4_sp_collision_x;
	wire	[ 8:0]	vdp_s5_s6_sp_collision_y;

	reg				reg_r1_sp_size;
	reg				reg_r1_sp_zoom;
	reg				reg_r8_col0_on;
	reg				sp_mode2;

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
	vdp_sprite_draw u_dut (
		.clk21m								( clk21m							),
		.reset								( reset								),
		.dot_state							( dot_state							),
		.eight_dot_state					( eight_dot_state					),
		.sp_draw_state						( sp_draw_state						),
		.dot_counter_x						( dot_counter_x						),
		.current_y							( current_y							),
		.attribute_table_address			( attribute_table_address			),
		.pattern_gentbl_address				( pattern_gentbl_address			),
		.vdp_s0_reset_timing				( vdp_s0_reset_timing				),
		.vdp_s5_reset_timing				( vdp_s5_reset_timing				),
		.current_render_sp					( current_render_sp					),
		.render_sp							( render_sp							),
		.render_sp_num						( render_sp_num						),
		.draw_xeven_adr						( draw_xeven_adr					),
		.draw_xodd_adr						( draw_xodd_adr						),
		.draw_xeven_write					( draw_xeven_write					),
		.draw_xodd_write					( draw_xodd_write					),
		.draw_xeven_pixel					( draw_xeven_pixel					),
		.draw_xodd_pixel					( draw_xodd_pixel					),
		.line_buffer_xeven_q				( line_buffer_xeven_q				),
		.line_buffer_xodd_q					( line_buffer_xodd_q				),
		.vdp_s0_sp_collision_incidence		( vdp_s0_sp_collision_incidence		),
		.vdp_s3_s4_sp_collision_x			( vdp_s3_s4_sp_collision_x			),
		.vdp_s5_s6_sp_collision_y			( vdp_s5_s6_sp_collision_y			),
		.reg_r1_sp_size						( reg_r1_sp_size					),
		.reg_r1_sp_zoom						( reg_r1_sp_zoom					),
		.reg_r8_col0_on						( reg_r8_col0_on					),
		.sp_mode2							( sp_mode2							),
		.vram_q								( vram_q							),
		.vram_a								( vram_a							)
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
			dot_counter_x		<= -9'd8;
		end
		else if( dot_state == 2'b11 ) begin
			if( dot_counter_x == LINE_END ) begin
				dot_counter_x <= -9'd8;
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
		clk21m						= 0;
		reset						= 1;
		sp_draw_state				= 0;
		dot_counter_x				= 0;
		current_y					= 0;
		attribute_table_address		= 0;
		pattern_gentbl_address		= 0;
		vdp_s0_reset_timing			= 0;
		vdp_s5_reset_timing			= 0;
		render_sp					= 0;
		render_sp_num				= 0;
		line_buffer_xeven_q			= 0;
		line_buffer_xodd_q			= 0;
		reg_r1_sp_size				= 0;
		reg_r1_sp_zoom				= 0;
		reg_r8_col0_on				= 0;
		sp_mode2					= 0;
		vram_q						= 0;

		repeat( 50 ) @( negedge clk21m );
		reset						= 0;
		@( posedge clk21m );

		sp_draw_state				= 1;
		sp_mode2					= 1;
		@( posedge clk21m );

		reg_r1_sp_size				= 0;
		reg_r1_sp_zoom				= 0;
		render_sp					= 0;
		render_sp_num				= 8;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 7;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 6;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 5;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 4;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 3;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 2;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 1;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 0;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		reg_r1_sp_size				= 1;
		reg_r1_sp_zoom				= 0;
		render_sp					= 0;
		render_sp_num				= 8;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 7;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 6;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 5;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 4;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 3;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 2;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 1;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 0;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		reg_r1_sp_size				= 1;
		reg_r1_sp_zoom				= 1;
		render_sp					= 0;
		render_sp_num				= 8;
		current_y					= 15;
		vram_q						= 31;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 7;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 6;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 5;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 4;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 3;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 2;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 1;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		render_sp					= 0;
		render_sp_num				= 0;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) @( negedge clk21m );

		sp_mode2					= 0;
		reg_r1_sp_size				= 1;
		reg_r1_sp_zoom				= 1;
		render_sp					= 0;
		render_sp_num				= 8;
		current_y					= 15;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end

		render_sp					= 0;
		render_sp_num				= 7;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end

		render_sp					= 0;
		render_sp_num				= 6;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end

		render_sp					= 0;
		render_sp_num				= 5;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end

		render_sp					= 0;
		render_sp_num				= 4;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end

		render_sp					= 0;
		render_sp_num				= 3;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end

		render_sp					= 0;
		render_sp_num				= 2;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end

		render_sp					= 0;
		render_sp_num				= 1;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end

		render_sp					= 0;
		render_sp_num				= 0;
		@( dot_counter_x == 9'd256 );
		@( posedge clk21m );

		repeat( 5000 ) begin
			vram_q					= $urandom;
			@( negedge clk21m );
		end
		$finish;
	end
endmodule
