--
--  vdp_ssg.vhd
--   Synchronous Signal Generator of ESE-VDP.
--
--  Copyright (C) 2000-2006 Kunihiko Ohnaka
--  All rights reserved.
--                                     http://www.ohnaka.jp/ese-vdp/
--
--  本ソフトウェアおよび本ソフトウェアに基づいて作成された派生物は、以下の条件を
--  満たす場合に限り、再頒布および使用が許可されます。
--
--  1.ソースコード形式で再頒布する場合、上記の著作権表示、本条件一覧、および下記
--    免責条項をそのままの形で保持すること。
--  2.バイナリ形式で再頒布する場合、頒布物に付属のドキュメント等の資料に、上記の
--    著作権表示、本条件一覧、および下記免責条項を含めること。
--  3.書面による事前の許可なしに、本ソフトウェアを販売、および商業的な製品や活動
--    に使用しないこと。
--
--  本ソフトウェアは、著作権者によって「現状のまま」提供されています。著作権者は、
--  特定目的への適合性の保証、商品性の保証、またそれに限定されない、いかなる明示
--  的もしくは暗黙な保証責任も負いません。著作権者は、事由のいかんを問わず、損害
--  発生の原因いかんを問わず、かつ責任の根拠が契約であるか厳格責任であるか（過失
--  その他の）不法行為であるかを問わず、仮にそのような損害が発生する可能性を知ら
--  されていたとしても、本ソフトウェアの使用によって発生した（代替品または代用サ
--  ービスの調達、使用の喪失、データの喪失、利益の喪失、業務の中断も含め、またそ
--  れに限定されない）直接損害、間接損害、偶発的な損害、特別損害、懲罰的損害、ま
--  たは結果損害について、一切責任を負わないものとします。
--
--  Note that above Japanese version license is the formal document.
--  The following translation is only for reference.
--
--  Redistribution and use of this software or any derivative works,
--  are permitted provided that the following conditions are met:
--
--  1. Redistributions of source code must retain the above copyright
--     notice, this list of conditions and the following disclaimer.
--  2. Redistributions in binary form must reproduce the above
--     copyright notice, this list of conditions and the following
--     disclaimer in the documentation and/or other materials
--     provided with the distribution.
--  3. Redistributions may not be sold, nor may they be used in a
--     commercial product or activity without specific prior written
--     permission.
--
--  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
--  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
--  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
--  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
--  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
--  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
--  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
--  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
--  POSSIBILITY OF SUCH DAMAGE.
--
-------------------------------------------------------------------------------
--  30th,March,2008
--  JP: VDP.VHD から分離 by t.hara
--
--  5th,June,2021
--  JP: V_BLANKING_END 出力ポートを追加 by t.hara
--
--  27th,June,2021
--  JP: 全面的に中身を作り直し by t.hara
--

LIBRARY IEEE;
	USE IEEE.STD_LOGIC_1164.ALL;
	USE IEEE.STD_LOGIC_UNSIGNED.ALL;
	USE IEEE.STD_LOGIC_ARITH.ALL;
	USE WORK.VDP_PACKAGE.ALL;

entity VDP_SSG is
	port(
		RESET					: in	std_logic;
		CLK21M					: in	std_logic;

		H_CNT					: out	std_logic_vector( 10 downto 0 );
		V_CNT					: out	std_logic_vector( 10 downto 0 );
		DOTSTATE				: out	std_logic_vector(  1 downto 0 );
		EIGHTDOTSTATE			: out	std_logic_vector(  2 downto 0 );
		PREDOTCOUNTER_X			: out	std_logic_vector(  8 downto 0 );
		PREDOTCOUNTER_Y			: out	std_logic_vector(  8 downto 0 );
		PREDOTCOUNTER_YP		: out	std_logic_vector(  8 downto 0 );
		PREWINDOW_Y				: out	std_logic;
		PREWINDOW_Y_SP			: out	std_logic;
		FIELD					: out	std_logic;
		WINDOW_X				: out	std_logic;
		PVIDEODHCLK				: out	std_logic;
		PVIDEODLCLK				: out	std_logic;
		IVIDEOVS_N				: out	std_logic;

		HD						: out	std_logic;
		VD						: out	std_logic;
		HSYNC					: out	std_logic;
--		ENAHSYNC				: out	std_logic;
		SYNC_AT_NEXT_LINE		: out	std_logic;
		H_BLANK_START			: out	std_logic;
		H_BLANK_END				: out	std_logic;
		V_BLANKING_START		: out	std_logic;
		V_BLANKING_END			: out	std_logic;
		VSYNC_INTR_TIMING		: out	std_logic;

		TEXT_MODE				: in	std_logic;
		REG_R9_PAL_MODE			: in	std_logic;
		REG_R9_INTERLACE_MODE	: in	std_logic;
		REG_R9_Y_DOTS			: in	std_logic;
		REG_R18_ADJ				: in	std_logic_vector(  7 downto 0 );
		REG_R19_HSYNC_INT_LINE	: in	std_logic_vector(  7 downto 0 );
		REG_R23_VSTART_LINE		: in	std_logic_vector(  7 downto 0 );
		REG_R25_MSK				: in	std_logic;
		REG_R27_H_SCROLL		: in	std_logic_vector(  2 downto 0 );
		REG_R25_YJK				: in	std_logic;
		CENTERYJK_R25_N			: in	std_logic
	);
end VDP_SSG;

architecture rtl of VDP_SSG is

	-- flip flop
	signal ff_h_cnt					: std_logic_vector( 10 downto 0 );
	signal ff_dotstate				: std_logic_vector(  1 downto 0 );
	signal ff_video_dh_clk			: std_logic;
	signal ff_video_dl_clk			: std_logic;
	signal ff_left_border			: std_logic_vector( 10 downto 0 );
	signal ff_right_border			: std_logic_vector( 10 downto 0 );
	signal ff_h_blank				: std_logic;

	signal ff_v_cnt_in_field		: std_logic_vector(	 9 downto 0 );
	signal ff_v_cnt_in_frame		: std_logic_vector( 10 downto 0 );
	signal ff_v_blank				: std_logic;

	signal ff_field					: std_logic;

	signal ff_pal_mode				: std_logic;
	signal ff_interlace_mode		: std_logic;

	-- wire
	signal w_sync_at_line			: std_logic;

	signal w_h_cnt_half				: std_logic;
	signal w_h_cnt_end				: std_logic;
	signal w_h_blank_start			: std_logic;
	signal w_h_blank_end			: std_logic;
	signal w_horizontal_adjust		: std_logic_vector( 10 downto 0 );

	signal w_v_blank_start			: std_logic;
	signal w_v_blank_end			: std_logic;
	signal w_vertical_adjust		: std_logic_vector(  8 downto 0 );

	signal w_field_end_cnt			: std_logic_vector(	 9 downto 0 );
	signal w_field_end				: std_logic;
	signal w_display_mode			: std_logic_vector(  1 downto 0 );
	signal w_line_mode				: std_logic_vector(  1 downto 0 );
	signal w_v_sync_intr_start_line	: std_logic_vector(	 8 downto 0 );
	signal w_v_sync_intr_end_line	: std_logic_vector(	 8 downto 0 );
	signal w_predotcounterypstart	: std_logic_vector(	 8 downto 0 );

	signal ff_eightdotstate		: std_logic_vector(  2 downto 0 );
	signal ff_pre_x_cnt			: std_logic_vector(  8 downto 0 );
	signal ff_x_cnt				: std_logic_vector(  8 downto 0 );
	signal ff_pre_y_cnt			: std_logic_vector(  8 downto 0 );
	signal ff_monitor_line		: std_logic_vector(  8 downto 0 );
	signal ff_pre_x_cnt_start1	: std_logic_vector(  5 downto 0 );
	signal ff_right_mask		: std_logic_vector(  8 downto 0 );
	signal ff_window_x			: std_logic;

	-- wire
	signal w_pre_x_cnt_start0		: std_logic_vector(  4 downto 0 );
	signal w_pre_x_cnt_start2		: std_logic_vector(  8 downto 0 );
	signal w_hsync					: std_logic;
	signal w_left_mask				: std_logic_vector(  8 downto 0 );
	signal w_predotcounter_yp_v		: std_logic_vector(	 8 downto 0 );
	signal ff_prewindow_y			: std_logic;
	signal ff_field_end				: std_logic;
begin
	-----------------------------------------------------------------------------
	--	port assignment
	-----------------------------------------------------------------------------
	H_CNT				<= ff_h_cnt;
	DOTSTATE			<= ff_dotstate;
	PVIDEODHCLK			<= ff_video_dh_clk;
	PVIDEODLCLK			<= ff_video_dl_clk;
	H_BLANK_START		<= w_h_blank_start;
	H_BLANK_END			<= w_h_blank_end;
	VSYNC_INTR_TIMING	<= w_h_blank_end;
	HD					<= ff_h_blank;

	V_CNT				<= ff_v_cnt_in_frame;
	V_BLANKING_START	<= w_v_blank_start;
	V_BLANKING_END		<= w_v_blank_end;
	VD					<= ff_v_blank;

	PREWINDOW_Y			<= ff_prewindow_y;
	FIELD				<= ff_field;

	EIGHTDOTSTATE		<= ff_eightdotstate;
	WINDOW_X			<= ff_window_x;
	PREDOTCOUNTER_X		<= ff_pre_x_cnt;
	PREDOTCOUNTER_Y		<= ff_pre_y_cnt;
	PREDOTCOUNTER_YP	<= ff_monitor_line;
	HSYNC				<= '1' when( ff_h_cnt(1 downto 0) = "10" and ff_pre_x_cnt = "111111111" )else '0';
	SYNC_AT_NEXT_LINE	<= w_h_cnt_end;

	-----------------------------------------------------------------------------
	--	base timing signal
	-----------------------------------------------------------------------------
	process( RESET, CLK21M ) begin
		if( RESET = '1' ) then
			ff_h_cnt <= (others => '0');
		elsif( CLK21M'event and CLK21M = '1' ) then
			if( w_h_cnt_end = '1' ) then
				ff_h_cnt <= ( others => '0' );
			else
				ff_h_cnt <= ff_h_cnt + 1;
			end if;
		end if;
	end process;

	w_h_cnt_half	<=	'1' when( ff_h_cnt = ((CLOCKS_PER_LINE / 2)-1) ) else '0';
	w_h_cnt_end		<=	'1' when( ff_h_cnt = ( CLOCKS_PER_LINE     -1) ) else '0';
	w_h_blank_start	<=	'1' when( ff_h_cnt = ff_right_border           ) else '0';
	w_h_blank_end	<=	'1' when( ff_h_cnt = ff_left_border            ) else '0';
	w_sync_at_line	<=	w_h_blank_end;

	-----------------------------------------------------------------------------
	--	dot state
	-----------------------------------------------------------------------------
	process( RESET, CLK21M ) begin
		if( RESET = '1' )then
			ff_dotstate		<= "00";
			ff_video_dh_clk <= '0';
			ff_video_dl_clk <= '0';
		elsif( CLK21M'event and CLK21M = '1' )then
			if( w_h_cnt_end = '1' )then
				ff_dotstate		<= "00";
				ff_video_dh_clk <= '1';
				ff_video_dl_clk <= '1';
			else
				case ff_dotstate is
				when "00" =>
					ff_dotstate		<= "01";
					ff_video_dh_clk <= '0';
					ff_video_dl_clk <= '1';
				when "01" =>
					ff_dotstate		<= "11";
					ff_video_dh_clk <= '1';
					ff_video_dl_clk <= '0';
				when "11" =>
					ff_dotstate		<= "10";
					ff_video_dh_clk <= '0';
					ff_video_dl_clk <= '0';
				when "10" =>
					ff_dotstate		<= "00";
					ff_video_dh_clk <= '1';
					ff_video_dl_clk <= '1';
				when others =>
					null;
				end case;
			end if;
		end if;
	end process;

	-----------------------------------------------------------------------------
	--	HD
	-----------------------------------------------------------------------------
	--   144 + ((reg_r18_adj(3 downto 0) xor 7) - 7 + reg_r25_yjk) * 4
	-- = (reg_r25_yjk ? 132 : 116) + (reg_r18_adj(3 downto 0) xor 7) * 4
	w_horizontal_adjust	<= "00000" & reg_r18_adj(3) & (not reg_r18_adj( 2 downto 0 )) & "00";

	process( RESET, CLK21M ) begin
		if( RESET = '1' )then
			ff_left_border	<= w_horizontal_adjust;
		elsif( CLK21M'event and CLK21M = '1' )then
			if( w_sync_at_line = '1' ) then
				if( reg_r25_yjk = '1' ) then
					ff_left_border	<= conv_std_logic_vector( 132, 11 ) + w_horizontal_adjust;
				else
					ff_left_border	<= conv_std_logic_vector( 116, 11 ) + w_horizontal_adjust;
				end if;
			end if;
		end if;
	end process;

	process( RESET, CLK21M )
	begin
		if( RESET = '1' )then
			ff_right_border	<= conv_std_logic_vector( 230 + 1024, 11 );
		elsif( CLK21M'event and CLK21M = '1' )then
			if( w_sync_at_line = '1' ) then
				if( text_mode = '1' ) then
					if( reg_r25_yjk = '1' ) then
						ff_right_border	<= conv_std_logic_vector( 246 + 996, 11 ) + w_horizontal_adjust;
					else
						ff_right_border	<= conv_std_logic_vector( 230 + 996, 11 ) + w_horizontal_adjust;
					end if;
				else
					if( reg_r25_yjk = '1' ) then
						ff_right_border	<= conv_std_logic_vector( 246 + 1024, 11 ) + w_horizontal_adjust;
					else
						ff_right_border	<= conv_std_logic_vector( 230 + 1024, 11 ) + w_horizontal_adjust;
					end if;
				end if;
			end if;
		end if;
	end process;

	process( RESET, CLK21M ) begin
		if( RESET = '1' ) then
			ff_h_blank <= '0';
		elsif( CLK21M'event and CLK21M = '1' )then
			if( w_h_blank_start = '1' )then
				ff_h_blank <= '1';
			elsif( w_h_blank_end = '1' )then
				ff_h_blank <= '0';
			end if;
		end if;
	end process;

	--------------------------------------------------------------------------
	--	FIELD ID
	--------------------------------------------------------------------------
	process( RESET, CLK21M )
	begin
		if( RESET = '1' )then
			ff_field <= '0';
		elsif( CLK21M'event and CLK21M = '1' )then
			-- generate ff_field signal
			if( (w_h_cnt_half or w_h_cnt_end) = '1' )then
				if( w_field_end = '1' )then
					ff_field <= not ff_field;
				end if;
			end if;
		end if;
	end process;

	w_display_mode	<=	ff_interlace_mode & ff_pal_mode;

	with( w_display_mode )select w_field_end_cnt <=
		conv_std_logic_vector( FIELD_END_NON_INTERLACE_NTSC	, 10 )	when "00",
		conv_std_logic_vector( FIELD_END_NON_INTERLACE_PAL	, 10 )	when "01",
		conv_std_logic_vector( FIELD_END_INTERLACE_NTSC		, 10 )	when "10",
		conv_std_logic_vector( FIELD_END_INTERLACE_PAL		, 10 )	when "11",
		(others=>'X')						when others;

	w_field_end <=	'1' when( ff_v_cnt_in_field = w_field_end_cnt )else '0';

	process( RESET, CLK21M ) begin
		if( RESET = '1' ) then
			ff_v_cnt_in_field	<= (others => '0');
		elsif( CLK21M'event and CLK21M = '1' ) then
			if( (w_h_cnt_half or w_h_cnt_end) = '1' ) then
				if( w_field_end = '1' ) then
					ff_v_cnt_in_field <= (others => '0');
				else
					ff_v_cnt_in_field <= ff_v_cnt_in_field + 1;
				end if;
			end if;
		end if;
	end process;

	--------------------------------------------------------------------------
	--	V SYNCHRONIZE MODE CHANGE
	--------------------------------------------------------------------------
	process( RESET, CLK21M ) begin
		if( RESET = '1' )then
			ff_pal_mode			<= '0';
			ff_interlace_mode	<= '0';
		elsif( CLK21M'event and CLK21M = '1' )then
			if( ((w_h_cnt_half or w_h_cnt_end) and w_field_end and ff_field) = '1' )then
				ff_pal_mode			<= REG_R9_PAL_MODE;
				ff_interlace_mode	<= REG_R9_INTERLACE_MODE;
			end if;
		end if;
	end process;

	-----------------------------------------------------------------------------
	-- V BLANKING
	-----------------------------------------------------------------------------
	w_vertical_adjust	<= "00000" & reg_r18_adj(7) & (not reg_r18_adj( 6 downto 4 ));

	w_line_mode <= REG_R9_Y_DOTS & ff_pal_mode;

	with w_line_mode select w_v_sync_intr_start_line <=
		conv_std_logic_vector( v_blanking_start_192_ntsc, 9 )	when "00",
		conv_std_logic_vector( v_blanking_start_212_ntsc, 9 )	when "10",
		conv_std_logic_vector( v_blanking_start_192_pal, 9 )	when "01",
		conv_std_logic_vector( v_blanking_start_212_pal, 9 )	when "11",
		(others => 'X')											when others;

	with w_line_mode select w_v_sync_intr_end_line <=
		conv_std_logic_vector( v_blanking_end_192_ntsc, 9 )		when "00",
		conv_std_logic_vector( v_blanking_end_212_ntsc, 9 )		when "10",
		conv_std_logic_vector( v_blanking_end_192_pal, 9 )		when "01",
		conv_std_logic_vector( v_blanking_end_212_pal, 9 )		when "11",
		(others => 'X')											when others;

	w_v_blank_start	<=	'1' when( ff_v_cnt_in_field = ((w_v_sync_intr_start_line + w_vertical_adjust) & (ff_field and ff_interlace_mode)) ) else '0';
	w_v_blank_end	<=	'1' when( ff_v_cnt_in_field = ((w_v_sync_intr_end_line   + w_vertical_adjust) & (ff_field and ff_interlace_mode)) ) else '0';

	process( reset, clk21m )
	begin
		if( reset = '1' )then
			ff_v_blank <= '0';
		elsif( clk21m'event and clk21m = '1' )then
			if( w_sync_at_line = '1' )then
				if( w_v_blank_end = '1' )then
					ff_v_blank <= '0';
				elsif( w_v_blank_start = '1' )then
					ff_v_blank <= '1';
				end if;
			end if;
		end if;
	end process;

	--------------------------------------------------------------------------
	--	VERTICAL COUNTER IN FRAME
	--------------------------------------------------------------------------
	process( RESET, CLK21M ) begin
		if( RESET = '1' )then
			ff_v_cnt_in_frame	<= (others => '0');
		elsif( CLK21M'event and CLK21M = '1' )then
			if( (w_h_cnt_half or w_h_cnt_end) = '1' )then
				if( w_field_end = '1' and ff_field = '1' )then
					ff_v_cnt_in_frame	<= (others => '0');
				else
					ff_v_cnt_in_frame	<= ff_v_cnt_in_frame + 1;
				end if;
			end if;
		end if;
	end process;

	-----------------------------------------------------------------------------
	--	8dot state
	-----------------------------------------------------------------------------
	process( reset, clk21m )
	begin
		if( reset = '1' )then
			ff_eightdotstate <= "000";
		elsif( clk21m'event and clk21m = '1' )then
			if( ff_h_cnt(1 downto 0) = "11" )then
				if( ff_pre_x_cnt = 0 )then
					ff_eightdotstate <= "000";
				else
					ff_eightdotstate <= ff_eightdotstate + 1;
				end if;
			end if;
		end if;
	end process;

	-----------------------------------------------------------------------------
	--	generate dotcounter
	-----------------------------------------------------------------------------
	-- w_pre_x_cnt_start0	<=	reg_r18_adj(3) & reg_r18_adj(3 downto 0) + "11000";					--	(-8...7) - 8 = (-16...-1)
	w_pre_x_cnt_start0	<=	"1" & (not reg_r18_adj(3)) & reg_r18_adj(2 downto 0);					--	(-8...7) - 8 = (-16...-1)

	-- 1000		=> 0000		=>	10000
	-- 1001		=> 0001		=>	10001
	-- 1010		=> 0010		=>	10010
	-- 1011		=> 0011		=>	10011
	-- 1100		=> 0100		=>	10100
	-- 1101		=> 0101		=>	10101
	-- 1110		=> 0110		=>	10110
	-- 1111		=> 0111		=>	10111
	-- 0000		=> 1000		=>	11000
	-- 0001		=> 1001		=>	11001
	-- 0010		=> 1010		=>	11010
	-- 0011		=> 1011		=>	11011
	-- 0100		=> 1100		=>	11100
	-- 0101		=> 1101		=>	11101
	-- 0110		=> 1110		=>	11110
	-- 0111		=> 1111		=>	11111

	process( reset, clk21m )
	begin
		if( reset = '1' )then
			ff_pre_x_cnt_start1 <= (others => '0');
		elsif( clk21m'event and clk21m = '1' )then
			ff_pre_x_cnt_start1 <= (w_pre_x_cnt_start0(4) & w_pre_x_cnt_start0) - ("000" & reg_r27_h_scroll);	-- (-23...-1)
		end if;
	end process;

	w_pre_x_cnt_start2( 8 downto 6 ) <= (others => ff_pre_x_cnt_start1(5));
	w_pre_x_cnt_start2( 5 downto 0 ) <= ff_pre_x_cnt_start1;

	process( reset, clk21m )
	begin
		if( reset = '1' )then
			ff_pre_x_cnt <= (others =>'0');
		elsif( clk21m'event and clk21m = '1' )then
			if( (ff_h_cnt = ("00" & (offset_x + led_tv_x_ntsc - ((reg_r25_msk and (not centeryjk_r25_n)) & "00") + 4) & "10") and reg_r25_yjk  = '1' and centeryjk_r25_n = '1'  and reg_r9_pal_mode = '0') or
				(ff_h_cnt = ("00" & (offset_x + led_tv_x_ntsc - ((reg_r25_msk and (not centeryjk_r25_n)) & "00")    ) & "10") and (reg_r25_yjk = '0' or centeryjk_r25_n  = '0') and reg_r9_pal_mode = '0') or
				(ff_h_cnt = ("00" & (offset_x + led_tv_x_pal  - ((reg_r25_msk and (not centeryjk_r25_n)) & "00") + 4) & "10") and reg_r25_yjk  = '1' and centeryjk_r25_n = '1'  and reg_r9_pal_mode = '1') or
				(ff_h_cnt = ("00" & (offset_x + led_tv_x_pal  - ((reg_r25_msk and (not centeryjk_r25_n)) & "00")    ) & "10") and (reg_r25_yjk = '0' or centeryjk_r25_n  = '0') and reg_r9_pal_mode = '1') )then
				ff_pre_x_cnt <= w_pre_x_cnt_start2;
			elsif( ff_h_cnt(1 downto 0) = "10" )then
				ff_pre_x_cnt <= ff_pre_x_cnt + 1;
			end if;
		end if;
	end process;

	process( reset, clk21m )
	begin
		if( reset = '1' )then
			ff_x_cnt <= (others =>'0');
		elsif( clk21m'event and clk21m = '1' )then
			if( (ff_h_cnt = ("00" & (offset_x + led_tv_x_ntsc - ((reg_r25_msk and (not centeryjk_r25_n)) & "00") + 4) & "10") and reg_r25_yjk  = '1' and centeryjk_r25_n = '1'  and reg_r9_pal_mode = '0') or
				(ff_h_cnt = ("00" & (offset_x + led_tv_x_ntsc - ((reg_r25_msk and (not centeryjk_r25_n)) & "00")    ) & "10") and (reg_r25_yjk = '0' or centeryjk_r25_n  = '0') and reg_r9_pal_mode = '0') or
				(ff_h_cnt = ("00" & (offset_x + led_tv_x_pal  - ((reg_r25_msk and (not centeryjk_r25_n)) & "00") + 4) & "10") and reg_r25_yjk  = '1' and centeryjk_r25_n = '1'  and reg_r9_pal_mode = '1') or
				(ff_h_cnt = ("00" & (offset_x + led_tv_x_pal  - ((reg_r25_msk and (not centeryjk_r25_n)) & "00")    ) & "10") and (reg_r25_yjk = '0' or centeryjk_r25_n  = '0') and reg_r9_pal_mode = '1') )then
				-- hold
			elsif( ff_h_cnt(1 downto 0) = "10") then
				if( ff_pre_x_cnt = "111111111" )then
					-- jp: ff_pre_x_cnt が -1から0にカウントアップする時にff_x_cntを-8にする
					ff_x_cnt <= conv_std_logic_vector( -8, 9 );
				else
					ff_x_cnt <= ff_x_cnt + 1;
				end if;
			end if;
		end if;
	end process;

	-----------------------------------------------------------------------------
	-- generate v-sync pulse
	-----------------------------------------------------------------------------
	process( reset, clk21m )
	begin
		if( reset = '1' )then
			ivideovs_n <= '1';
		elsif( clk21m'event and clk21m = '1' )then
			if( ff_v_cnt_in_field = 6 )then
				-- sstate = sstate_b
				ivideovs_n <= '0';
			elsif( ff_v_cnt_in_field = 12 )then
				-- sstate = sstate_a
				ivideovs_n <= '1';
			end if;
		end if;
	end process;

	-----------------------------------------------------------------------------
	--	display window
	-----------------------------------------------------------------------------

	-- left mask (r25 msk)
	-- h_scroll = 0 --> 8
	-- h_scroll = 1 --> 7
	-- h_scroll = 2 --> 6
	-- h_scroll = 3 --> 5
	-- h_scroll = 4 --> 4
	-- h_scroll = 5 --> 3
	-- h_scroll = 6 --> 2
	-- h_scroll = 7 --> 1
	w_left_mask		<=	(others => '0') when( reg_r25_msk = '0' )else
						"00000" & ("0" & (not reg_r27_h_scroll) + 1);

	process( clk21m )
	begin
		if( clk21m'event and clk21m = '1' )then
			-- main window
			if( ff_h_cnt( 1 downto 0) = "01" and ff_x_cnt = w_left_mask )then
				-- when dotcounter_x = 0
				ff_right_mask <= "100000000" - ("000000" & reg_r27_h_scroll);
			end if;
		end if;
	end process;

	process( reset, clk21m )
	begin
		if( reset = '1' )then
			ff_window_x <= '0';
		elsif( clk21m'event and clk21m = '1' )then
			-- main window
			if( ff_h_cnt( 1 downto 0) = "01" and ff_x_cnt = w_left_mask ) then
				-- when dotcounter_x = 0
				ff_window_x <= '1';
			elsif( ff_h_cnt( 1 downto 0) = "01" and ff_x_cnt = ff_right_mask ) then
				-- when dotcounter_x = 256
				ff_window_x <= '0';
			end if;
		end if;
	end process;

	-----------------------------------------------------------------------------
	-- y
	-----------------------------------------------------------------------------
	w_hsync <=	'1'		when( ff_h_cnt(1 downto 0) = "10" and ff_pre_x_cnt = "111111111" )else
				'0';

	process( CLK21M, RESET ) begin
		if (RESET = '1') then
			ff_pre_y_cnt		<= (others =>'0');
		elsif( CLK21M'event and CLK21M = '1' )then
			ff_pre_y_cnt( 7 downto 0 )	<= ff_monitor_line( 7 downto 0 ) + reg_r23_vstart_line;
			ff_pre_y_cnt( 8 )			<= ff_monitor_line( 8 );
		end if;
	end process;

	with( w_line_mode ) select w_predotcounterypstart <=
		conv_std_logic_vector( monitor_line_192_ntsc, 9 )	when "00",
		conv_std_logic_vector( monitor_line_212_ntsc, 9 )	when "10",
		conv_std_logic_vector( monitor_line_192_pal, 9 )	when "01",
		conv_std_logic_vector( monitor_line_212_pal, 9 )	when "11",
		(others => 'X')										when others;

	w_predotcounter_yp_v <= ff_monitor_line + 1;

	process( CLK21M, RESET ) begin
		if (RESET = '1') then
			ff_field_end <= '0';
		elsif( CLK21M'event and CLK21M = '1' )then
			if( (w_h_cnt_half or w_h_cnt_end) = '1' )then
				ff_field_end <= ff_field_end or w_field_end;
			elsif( w_hsync = '1' )then
				ff_field_end <= '0';
			end if;
		end if;
	end process;

	process( CLK21M, RESET ) begin
		if (RESET = '1') then
			ff_monitor_line		<= (others =>'0');
		elsif( CLK21M'event and CLK21M = '1' )then
			if( w_hsync = '1' )then
				if( ff_field_end = '1' )then
					ff_monitor_line <= w_predotcounterypstart - w_vertical_adjust;
				elsif( ff_prewindow_y = '0' and ff_monitor_line = 0 )then
					-- hold
				else
					ff_monitor_line <= ff_monitor_line + 1;
				end if;
			end if;
		end if;
	end process;

	process( CLK21M, RESET ) begin
		if (RESET = '1') then
			ff_prewindow_y			<= '0';
		elsif( CLK21M'event and CLK21M = '1' )then
			if( w_hsync = '1' )then
				-- jp: prewindow_xが 1になるタイミングと同じタイミングでy座標の計算
				if( ff_monitor_line = 0 ) then
					ff_prewindow_y		<= '1';
				elsif( (reg_r9_y_dots = '0' and ff_monitor_line = 191) or
					   (reg_r9_y_dots = '1' and ff_monitor_line = 211) )then
					ff_prewindow_y		<= '0';
				end if;
			end if;
		end if;
	end process;

	process( CLK21M, RESET ) begin
		if (RESET = '1') then
			prewindow_y_sp		<= '0';			-- 2021/june/20th added by t.hara
		elsif( CLK21M'event and CLK21M = '1' )then
			if( w_hsync = '1' )then
				-- jp: prewindow_xが 1になるタイミングと同じタイミングでy座標の計算
				if(	 w_v_blank_end = '1' )then
					prewindow_y_sp	<= '1';
				else
					if( ff_monitor_line = 0 ) then
						-- hold
					elsif( (reg_r9_y_dots = '0' and ff_monitor_line = 191) or
						   (reg_r9_y_dots = '1' and ff_monitor_line = 211) )then
						prewindow_y_sp	<= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

--	process( CLK21M, RESET ) begin
--		if (RESET = '1') then
--			enahsync			<= '0';			-- 2021/june/20th added by t.hara
--		elsif( CLK21M'event and CLK21M = '1' )then
--			if( w_hsync = '1' )then
--				-- jp: prewindow_xが 1になるタイミングと同じタイミングでy座標の計算
--				if(	 w_v_blank_end = '1' )then
--					-- hold
--				else
--					if( ff_monitor_line = 0 ) then
--						enahsync		<= '1';
--					elsif( (reg_r9_y_dots = '0' and reg_r9_pal_mode = '0' and ff_monitor_line = 234) or
--						   (reg_r9_y_dots = '1' and reg_r9_pal_mode = '0' and ff_monitor_line = 244) or
--						   (reg_r9_y_dots = '0' and reg_r9_pal_mode = '1' and ff_monitor_line = 258) or
--						   (reg_r9_y_dots = '1' and reg_r9_pal_mode = '1' and ff_monitor_line = 268) )then
--						enahsync		<= '0';
--					end if;
--				end if;
--			end if;
--		end if;
--	end process;
end rtl;
