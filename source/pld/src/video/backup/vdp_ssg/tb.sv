module tb;
	localparam		clk_base	= 1000000000/21480;
	localparam		line_end	= 9'd341;

	reg				reset;
	reg				clk21m;
	wire	[10:0]	h_cnt;
	wire	[10:0]	v_cnt;
	wire	[ 9:0]	v_cnt_in_field;
	wire	[ 1:0]	dotstate;
	wire	[ 2:0]	eightdotstate;
	wire	[ 8:0]	predotcounter_x;
	wire	[ 8:0]	predotcounter_y;
	wire	[ 8:0]	predotcounter_yp;
	wire			pre_window_y;
	wire			pre_window_y_sp;
	wire			field;
	wire			window_x;
	wire			pvideodhclk;
	wire			pvideodlclk;
	wire			ivideovs_n;
	wire			hd;
	wire			vd;
	wire			hsync;
	wire			enahsync;
	wire			v_blanking_start;
	reg		[ 6:0]	offset_y;
	reg				vdp_r9_pal_mode;
	reg				reg_r9_interlace_mode;
	reg				reg_r9_y_dots;
	reg		[ 7:0]	reg_r18_adj;
	reg		[ 7:0]	reg_r19_hsync_int_line;
	reg		[ 7:0]	reg_r23_vstart_line;
	reg				reg_r25_msk;
	reg		[ 2:0]	reg_r27_h_scroll;
	reg				reg_r25_yjk;
	reg				centeryjk_r25_n;

	wire	[10:0]	old_h_cnt;
	wire	[10:0]	old_v_cnt;
	wire	[ 9:0]	old_v_cnt_in_field;
	wire	[ 1:0]	old_dotstate;
	wire	[ 2:0]	old_eightdotstate;
	wire	[ 8:0]	old_predotcounter_x;
	wire	[ 8:0]	old_predotcounter_y;
	wire	[ 8:0]	old_predotcounter_yp;
	wire			old_pre_window_y;
	wire			old_pre_window_y_sp;
	wire			old_field;
	wire			old_window_x;
	wire			old_pvideodhclk;
	wire			old_pvideodlclk;
	wire			old_ivideovs_n;
	wire			old_hd;
	wire			old_vd;
	wire			old_hsync;
	wire			old_enahsync;
	wire			old_v_blanking_start;

	// -------------------------------------------------------------
	//	clock generator
	// -------------------------------------------------------------
	always #(clk_base/2) begin
		clk21m	<= ~clk21m;
	end

	// -------------------------------------------------------------
	//	dut
	// -------------------------------------------------------------
	vdp_ssg u_dut (
		.reset					( reset						),
		.clk21m					( clk21m					),
		.h_cnt					( h_cnt						),
		.v_cnt					( v_cnt						),
		.v_cnt_in_field			( v_cnt_in_field			),
		.dotstate				( dotstate					),
		.eightdotstate			( eightdotstate				),
		.predotcounter_x		( predotcounter_x			),
		.predotcounter_y		( predotcounter_y			),
		.predotcounter_yp		( predotcounter_yp			),
		.pre_window_y			( pre_window_y				),
		.pre_window_y_sp		( pre_window_y_sp			),
		.field					( field						),
		.window_x				( window_x					),
		.pvideodhclk			( pvideodhclk				),
		.pvideodlclk			( pvideodlclk				),
		.ivideovs_n				( ivideovs_n				),
		.hd						( hd						),
		.vd						( vd						),
		.hsync					( hsync						),
		.enahsync				( enahsync					),
		.v_blanking_start		( v_blanking_start			),
		.offset_y				( offset_y					),
		.vdp_r9_pal_mode		( vdp_r9_pal_mode			),
		.reg_r9_interlace_mode	( reg_r9_interlace_mode		),
		.reg_r9_y_dots			( reg_r9_y_dots				),
		.reg_r18_adj			( reg_r18_adj				),
		.reg_r19_hsync_int_line	( reg_r19_hsync_int_line	),
		.reg_r23_vstart_line	( reg_r23_vstart_line		),
		.reg_r25_msk			( reg_r25_msk				),
		.reg_r27_h_scroll		( reg_r27_h_scroll			),
		.reg_r25_yjk			( reg_r25_yjk				),
		.centeryjk_r25_n		( centeryjk_r25_n			)
	);

	VDP_SSG_OLD u_old (
		.RESET					( reset						),
		.CLK21M					( clk21m					),
		.H_CNT					( old_h_cnt						),
		.V_CNT					( old_v_cnt						),
		.V_CNT_IN_FIELD			( old_v_cnt_in_field			),
		.DOTSTATE				( old_dotstate					),
		.EIGHTDOTSTATE			( old_eightdotstate				),
		.PREDOTCOUNTER_X		( old_predotcounter_x			),
		.PREDOTCOUNTER_Y		( old_predotcounter_y			),
		.PREDOTCOUNTER_YP		( old_predotcounter_yp			),
		.PREWINDOW_Y			( old_pre_window_y				),
		.PREWINDOW_Y_SP			( old_pre_window_y_sp			),
		.FIELD					( old_field						),
		.WINDOW_X				( old_window_x					),
		.PVIDEODHCLK			( old_pvideodhclk				),
		.PVIDEODLCLK			( old_pvideodlclk				),
		.IVIDEOVS_N				( old_ivideovs_n				),
		.HD						( old_hd						),
		.VD						( old_vd						),
		.HSYNC					( old_hsync						),
		.ENAHSYNC				( old_enahsync					),
		.V_BLANKING_START		( old_v_blanking_start			),
		.OFFSET_Y				( offset_y					),
		.VDPR9PALMODE			( vdp_r9_pal_mode			),
		.REG_R9_INTERLACE_MODE	( reg_r9_interlace_mode		),
		.REG_R9_Y_DOTS			( reg_r9_y_dots				),
		.REG_R18_ADJ			( reg_r18_adj				),
		.REG_R19_HSYNC_INT_LINE	( reg_r19_hsync_int_line	),
		.REG_R23_VSTART_LINE	( reg_r23_vstart_line		),
		.REG_R25_MSK			( reg_r25_msk				),
		.REG_R27_H_SCROLL		( reg_r27_h_scroll			),
		.REG_R25_YJK			( reg_r25_yjk				),
		.CENTERYJK_R25_N		( centeryjk_r25_n			)
	);

	initial begin
		clk21m						= 0;
		reset						= 1;
		vdp_r9_pal_mode				= 0;
		reg_r9_interlace_mode		= 0;
		reg_r9_y_dots				= 0;
		reg_r18_adj					= 0;
		reg_r19_hsync_int_line		= 0;
		reg_r23_vstart_line			= 50;
		reg_r25_msk					= 0;
		reg_r27_h_scroll			= 0;
		reg_r25_yjk					= 0;
		centeryjk_r25_n				= 0;
		offset_y					= 19;

		repeat( 50 ) @( negedge clk21m );
		reset						= 0;
		@( posedge clk21m );

		repeat( 500000 ) @( negedge clk21m );
		$finish;
	end
endmodule
