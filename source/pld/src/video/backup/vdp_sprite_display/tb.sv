module tb;
	localparam		CLK_BASE	= 1000000000/21480;
	localparam		LINE_END	= 9'd341;

	reg				reset;
	reg				clk21m;
	reg		[ 1:0]	dot_state;
	reg		[ 8:0]	dot_counter_x;
	wire			sp_color_out;
	wire	[ 3:0]	sp_color_code;
	wire			sp_display_en;
	wire	[ 6:0]	line_buffer_display_adr;
	wire			line_buffer_display_we;
	reg		[ 7:0]	line_buffer_xeven_q;
	reg		[ 7:0]	line_buffer_xodd_q;
	reg		[ 2:0]	reg_r27_h_scroll;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(CLK_BASE/2) begin
		clk21m	<= ~clk21m;
	end

	// -------------------------------------------------------------
	//	DUT
	// -------------------------------------------------------------
	vdp_sprite_display u_dut (
		.reset						( reset						),
		.clk21m						( clk21m					),
		.dot_state					( dot_state					),
		.dot_counter_x				( dot_counter_x				),
		.sp_color_out				( sp_color_out				),
		.sp_color_code				( sp_color_code				),
		.sp_display_en				( sp_display_en				),
		.line_buffer_display_adr	( line_buffer_display_adr	),
		.line_buffer_display_we		( line_buffer_display_we	),
		.line_buffer_xeven_q		( line_buffer_xeven_q		),
		.line_buffer_xodd_q			( line_buffer_xodd_q		),
		.reg_r27_h_scroll			( reg_r27_h_scroll			)
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

	initial begin
		clk21m				= 0;
		reset				= 1;
		line_buffer_xeven_q	= 1;
		line_buffer_xodd_q	= 2;
		reg_r27_h_scroll	= 0;

		repeat( 50 ) @( negedge clk21m );
		reset				= 0;

		repeat( 100000 ) begin
			line_buffer_xeven_q	<= { 4'b0, line_buffer_display_adr[2:0], 1'b0 };
			line_buffer_xodd_q	<= { 4'b0, line_buffer_display_adr[2:0], 1'b1 };
			@( posedge clk21m );
		end
		$finish;
	end
endmodule
