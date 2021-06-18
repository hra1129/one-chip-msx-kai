--
-- emsx_top_de0cv.vhd
--   ESE MSX-SYSTEM3 / MSX clone on a Cyclone FPGA (ALTERA)
--   Revision 1.00
--
-- Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
-- All rights reserved.
--
-- Redistribution and use of this source code or any derivative works, are
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial
--    product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
--------------------------------------------------------------------------------------
-- OCM-PLD Pack v3.6.2 by KdL (2018.07.27) / MSX2+ Stable Release / MSXtR Experimental
-- Special thanks to t.hara, caro, mygodess & all MRC users (http://www.msx.org)
--------------------------------------------------------------------------------------
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use work.vdp_package.all;

entity emsx_top_de0cv is
    port(

        -- Clock, Reset ports
        CLOCK_50        : in    std_logic;                          -- FPGA Clock ... 50.00MHz
        pCpuClk         : out   std_logic;                          -- CPU Clock ... 3.58MHz (up to 10.74MHz/21.48MHz)

        RESET_N         : in    std_logic;

        -- MSX cartridge slot ports
        pSltRst_n       : out   std_logic;
        pSltSltsl_n     : inout std_logic;
        pSltSlts2_n     : inout std_logic;
        pSltIorq_n      : inout std_logic;
        pSltRd_n        : inout std_logic;
        pSltWr_n        : inout std_logic;
        pSltAdr         : inout std_logic_vector( 15 downto 0 );
        pSltDat         : inout std_logic_vector(  7 downto 0 );
        pSltBdir_n      : out   std_logic;                          -- Bus direction (not used in   master mode)

        pSltCs1_n       : inout std_logic;
        pSltCs2_n       : inout std_logic;
        pSltCs12_n      : inout std_logic;
        pSltRfsh_n      : inout std_logic;
        pSltWait_n      : inout std_logic;
        pSltInt_n       : in    std_logic;
        pSltM1_n        : inout std_logic;
        pSltMerq_n      : inout std_logic;

        pSltRsv5        : out   std_logic;                          -- Reserved
        pSltRsv16       : out   std_logic;                          -- Reserved (w/ external pull-up)
        pSltSw1         : inout std_logic;                          -- Reserved (w/ external pull-up)
        pSltSw2         : inout std_logic;                          -- Reserved

        -- SD-RAM ports
        pMemClk         : out   std_logic;                          -- SD-RAM Clock
        pMemCke         : out   std_logic;                          -- SD-RAM Clock enable
        pMemCs_n        : out   std_logic;                          -- SD-RAM Chip select
        pMemRas_n       : out   std_logic;                          -- SD-RAM Row/RAS
        pMemCas_n       : out   std_logic;                          -- SD-RAM /CAS
        pMemWe_n        : out   std_logic;                          -- SD-RAM /WE
        pMemUdq         : out   std_logic;                          -- SD-RAM UDQM
        pMemLdq         : out   std_logic;                          -- SD-RAM LDQM
        pMemBa1         : out   std_logic;                          -- SD-RAM Bank select address 1
        pMemBa0         : out   std_logic;                          -- SD-RAM Bank select address 0
        pMemAdr         : out   std_logic_vector( 12 downto 0 );    -- SD-RAM Address
        pMemDat         : inout std_logic_vector( 15 downto 0 );    -- SD-RAM Data

        -- PS/2 keyboard ports
        pPs2Clk         : inout std_logic;
        pPs2Dat         : inout std_logic;

        -- PS/2 mouse ports
        pPs2mClk        : inout std_logic;
        pPs2mDat        : inout std_logic;

        -- Joystick ports (Port_A, Port_B)
        pJoyA           : inout std_logic_vector(  5 downto 0);
        pStrA           : out   std_logic;
        pJoyB           : inout std_logic_vector(  5 downto 0);
        pStrB           : out   std_logic;

        -- SD/MMC slot ports
        pSd_Ck          : out   std_logic;                          -- pin 5
        pSd_Cm          : out   std_logic;                          -- pin 2
        pSd_Dt          : inout std_logic_vector(  3 downto 0);     -- pin 1(D3), 9(D2), 8(D1), 7(D0)

        -- MIDI ports                                               -- Added by t.hara at 12th/Feb./2020
        pMidiTxD        : out   std_logic;
        pMidiRxD        : in    std_logic;

        -- DIP switch, Lamp ports
        pSW             : in    std_logic_vector(  3 downto 0);     -- 0=press, 1=unpress
        pDip            : in    std_logic_vector(  9 downto 0);     -- 0=On, 1=Off (default on shipment)
        pLed            : out   std_logic_vector(  9 downto 0);     -- 0=Off, 1=On (green)

        p7SegLed0       : out   std_logic_vector(  6 downto 0);
        p7SegLed1       : out   std_logic_vector(  6 downto 0);
        p7SegLed2       : out   std_logic_vector(  6 downto 0);
        p7SegLed3       : out   std_logic_vector(  6 downto 0);
        p7SegLed4       : out   std_logic_vector(  6 downto 0);
        p7SegLed5       : out   std_logic_vector(  6 downto 0);

        -- Video, Audio/CMT ports
        pDac_VR         : inout std_logic_vector(  3 downto 0);     -- RGB_Red / Svideo_C
        pDac_VG         : inout std_logic_vector(  3 downto 0);     -- RGB_Grn / Svideo_Y
        pDac_VB         : inout std_logic_vector(  3 downto 0);     -- RGB_Blu / CompositeVideo

        pDac_S          : out   std_logic;                          -- Sound
        pREM_out        : out   std_logic;                          -- REM output; 1 - Tape On
        pCMT_out        : out   std_logic;                          -- CMT output
        pCMT_in         : in    std_logic;                          -- CMT input

        pVideoHS_n      : out   std_logic;                          -- Csync(RGB15K), HSync(VGA31K)
        pVideoVS_n      : out   std_logic                           -- Audio(RGB15K), VSync(VGA31K)
    );
end emsx_top_de0cv;

architecture RTL of emsx_top_de0cv is

    -- Clock generator ( Altera specific component )
    component pll_de0cv
        port(
            refclk   : in    std_logic := '0';   -- 50.00MHz input to PLL    (external I/O pin, from crystal oscillator)
            rst      : in    std_logic := '0';   -- reset
            outclk_0 : out   std_logic;          -- 21.48MHz output from PLL (internal LEs, for VDP, internal-bus, etc.)
            outclk_1 : out   std_logic;          -- 85.92MHz output from PLL (internal LEs, for SD-RAM)
            outclk_2 : out   std_logic           -- 85.92MHz output from PLL (external I/O pin, for SD-RAM)
        );
    end component;

    -- ASMI (Altera specific component)
    component cyclonev_asmiblock 
        port(
            dclk     : in std_logic;
            sce      : in std_logic;
            oe       : in std_logic;
            data0out : in std_logic;
            data1out : in std_logic;
            data2out : in std_logic;
            data3out : in std_logic;
            data0oe  : in std_logic;
            data1oe  : in std_logic;
            data2oe  : in std_logic;
            data3oe  : in std_logic;
            data0in  : out std_logic;
            data1in  : out std_logic;
            data2in  : out std_logic;
            data3in  : out std_logic
    );
    end component;

    -- CORE
    component emsx_top
        port(
            -- Clock, Reset ports
            clk21m          : in    std_logic;                          -- VDP Clock ... 21.48MHz
            memclk          : in    std_logic;                          -- Reserved (for multi FPGAs)
            pCpuClk         : out   std_logic;                          -- CPU Clock ... 3.58MHz (up to 10.74MHz/21.48MHz)
            pW10hz          : out   std_logic;

            -- MSX cartridge slot ports
            xSltRst_n       : out   std_logic;
            pSltRst_n       : in    std_logic;                          -- pCpuRst_n returns here
            pSltSltsl_n     : inout std_logic;
            pSltSlts2_n     : inout std_logic;
            pSltIorq_n      : inout std_logic;
            pSltRd_n        : inout std_logic;
            pSltWr_n        : inout std_logic;
            pSltAdr         : inout std_logic_vector( 15 downto 0 );
            pSltDat         : inout std_logic_vector(  7 downto 0 );
            pSltBdir_n      : out   std_logic;                          -- Bus direction (not used in   master mode)

            pSltCs1_n       : inout std_logic;
            pSltCs2_n       : inout std_logic;
            pSltCs12_n      : inout std_logic;
            pSltRfsh_n      : inout std_logic;
            pSltWait_n      : inout std_logic;
            pSltInt_n       : in    std_logic;
            pSltM1_n        : inout std_logic;
            pSltMerq_n      : inout std_logic;

            pSltRsv5        : out   std_logic;                          -- Reserved
            pSltRsv16       : out   std_logic;                          -- Reserved (w/ external pull-up)
            pSltSw1         : inout std_logic;                          -- Reserved (w/ external pull-up)
            pSltSw2         : inout std_logic;                          -- Reserved

            -- SD-RAM ports
            pMemCke         : out   std_logic;                          -- SD-RAM Clock enable
            pMemCs_n        : out   std_logic;                          -- SD-RAM Chip select
            pMemRas_n       : out   std_logic;                          -- SD-RAM Row/RAS
            pMemCas_n       : out   std_logic;                          -- SD-RAM /CAS
            pMemWe_n        : out   std_logic;                          -- SD-RAM /WE
            pMemUdq         : out   std_logic;                          -- SD-RAM UDQM
            pMemLdq         : out   std_logic;                          -- SD-RAM LDQM
            pMemBa1         : out   std_logic;                          -- SD-RAM Bank select address 1
            pMemBa0         : out   std_logic;                          -- SD-RAM Bank select address 0
            pMemAdr         : out   std_logic_vector( 12 downto 0 );    -- SD-RAM Address
            pMemDat         : inout std_logic_vector( 15 downto 0 );    -- SD-RAM Data

            -- PS/2 keyboard ports
            pPs2Clk         : inout std_logic;
            pPs2Dat         : inout std_logic;

            -- Joystick ports (Port_A, Port_B)
            pJoyA           : inout std_logic_vector(  5 downto 0);
            pStrA           : out   std_logic;
            pJoyB           : inout std_logic_vector(  5 downto 0);
            pStrB           : out   std_logic;

            -- SD/MMC slot ports
            pSd_Ck          : out   std_logic;                          -- pin 5
            pSd_Cm          : out   std_logic;                          -- pin 2
            pSd_Dt          : inout std_logic_vector(  3 downto 0);     -- pin 1(D3), 9(D2), 8(D1), 7(D0)

            -- MIDI ports                                               -- Added by t.hara at 12th/Feb./2020
            pMidiTxD        : out   std_logic;
            pMidiRxD        : in    std_logic;

            -- DIP switch, Lamp ports
            pDip            : in    std_logic_vector(  9 downto 0);     -- 0=On, 1=Off (default on shipment)
            pLed            : out   std_logic_vector(  8 downto 0);     -- 0=Off, 1=On (green)
            pLedPwr         : out   std_logic;                          -- 0=Off, 1=On (red)

            p_toggle_sexec_sw          : in  std_logic;
            p_reserved_sw              : in  std_logic;
            p_toggle_sw                : in  std_logic;
            p_7seg_cpu_type            : out std_logic_vector( 6 downto 0 );
            p_7seg_address_0           : out std_logic_vector( 6 downto 0 );
            p_7seg_address_1           : out std_logic_vector( 6 downto 0 );
            p_7seg_address_2           : out std_logic_vector( 6 downto 0 );
            p_7seg_address_3           : out std_logic_vector( 6 downto 0 );
            p_7seg_debug               : out std_logic_vector( 6 downto 0 );

            -- Video, Audio/CMT ports
            pDac_VR         : inout std_logic_vector(  5 downto 0);     -- RGB_Red / Svideo_C
            pDac_VG         : inout std_logic_vector(  5 downto 0);     -- RGB_Grn / Svideo_Y
            pDac_VB         : inout std_logic_vector(  5 downto 0);     -- RGB_Blu / CompositeVideo

            pVideoHS_n      : out   std_logic;                          -- Csync(RGB15K), HSync(VGA31K)
            pVideoVS_n      : out   std_logic;                          -- Audio(RGB15K), VSync(VGA31K)

            pVideoClk       : out   std_logic;                          -- (Reserved)
            pVideoDat       : out   std_logic;                          -- (Reserved)

            pRemOut         : out   std_logic;
            pCmtOut         : out   std_logic;
            pCmtIn          : in    std_logic;
            pCmtEn          : out   std_logic;

            pDacOut         : out   std_logic;
            pDacLMute       : out   std_logic;
            pDacRInverse    : out   std_logic;

            -- EPCS ports
            EPC_CK          : out   std_logic;
            EPC_CS          : out   std_logic;
            EPC_OE          : out   std_logic;
            EPC_DI          : out   std_logic;
            EPC_DO          : in    std_logic;

			-- DE0CV, SM-X, Multicore 2 and SX-2 ports
			clk21m_out		: out	std_logic;
			clk_hdmi		: out	std_logic;
			esp_rx_o		: out	std_logic;
			esp_tx_i		: in	std_logic;
			pcm_o			: out	std_logic_vector( 15 downto 0 );
			blank_o			: out	std_logic;
			ear_i			: in	std_logic;
			mic_o			: out	std_logic;
			midi_o			: out	std_logic;
			midi_active_o	: out	std_logic;
			vga_status		: out	std_logic;
			vga_scanlines	: inout	std_logic_vector( 1 downto 0 );
			btn_scan		: out	std_logic
        );
    end component;

    -- Clock, Reset signals

    signal        pRESET_N     : std_logic;
    signal        iRESET_N     : std_logic_vector(  2 downto 0 ) := (others => '0');
 
    -- Clock signals
    signal        clk21m       : std_logic;
    signal        memclk       : std_logic;
    signal        w_10hz       : std_logic;

    -- EPCS signals
    signal        EPC_CK       : std_logic;
    signal        EPC_CS       : std_logic;
    signal        EPC_OE       : std_logic;
    signal        EPC_DI       : std_logic;
    signal        EPC_DO       : std_logic;

    -- Video signals
    signal        pDac_VR6     : std_logic_vector(  5 downto 0 );
    signal        pDac_VG6     : std_logic_vector(  5 downto 0 );
    signal        pDac_VB6     : std_logic_vector(  5 downto 0 );


begin

    pRESET_N <= RESET_N and pSW(0);

    process( pRESET_N, clk21m )
    begin
        if( pRESET_N = '0' )then
            iRESET_N <= (others => '0');
        elsif( clk21m'event and clk21m = '1' )then
            if( w_10hz = '1' )then
                iRESET_N <= iRESET_N(1 downto 0) & "1";
            end if;
        end if;
    end process;

    pDac_VR   <= pDac_VR6( 5 downto 2);
    pDac_VG   <= pDac_VG6( 5 downto 2);
    pDac_VB   <= pDac_VB6( 5 downto 2);

    U90 : pll_de0cv
        port map(
            refclk   => CLOCK_50,               -- 50.00MHz external
            outclk_0 => clk21m,                 -- 21.48MHz internal
            outclk_1 => memclk,                 -- 85.92MHz = 21.48MHz x 4
            outclk_2 => pMemClk                 -- 85.92MHz external
        );

    U91 : cyclonev_asmiblock
        port map(EPC_CK, EPC_CS, EPC_OE, EPC_DI, 'Z', 'Z', 'Z', not EPC_OE, '0', '0', '0', open, EPC_DO, open, open);

    U92 : emsx_top
        port map(
            clk21m,
            memclk,
            pCpuClk,
            w_10hz,

            pSltRst_n,
            iRESET_N(2),
            pSltSltsl_n,
            pSltSlts2_n,
            pSltIorq_n,
            pSltRd_n,
            pSltWr_n,
            pSltAdr,
            pSltDat,
            pSltBdir_n,

            pSltCs1_n,
            pSltCs2_n,
            pSltCs12_n,
            pSltRfsh_n,
            pSltWait_n,
            pSltInt_n,
            pSltM1_n,
            pSltMerq_n,

            pSltRsv5,
            pSltRsv16,
            pSltSw1,
            pSltSw2,

            pMemCke,
            pMemCs_n,
            pMemRas_n,
            pMemCas_n,
            pMemWe_n,
            pMemUdq,
            pMemLdq,
            pMemBa1,
            pMemBa0,
            pMemAdr,
            pMemDat,

            pPs2Clk,
            pPs2Dat,

            pJoyA,
            pStrA,
            pJoyB,
            pStrB,

            pSd_Ck,
            pSd_Cm,
            pSd_Dt,

            pMidiTxD,
            pMidiRxD,

            pDip,
            pLed(8 downto 0),
            pLed(9),

            pSW(2),             -- p_toggle_sexec_sw
            pSW(3),             -- p_step_sexec_sw  
            pSW(1),             -- p_toggle_sw
            p7SegLed4,          -- p_7seg_cpu_type  
            p7SegLed0,          -- p_7seg_address_0 
            p7SegLed1,          -- p_7seg_address_1 
            p7SegLed2,          -- p_7seg_address_2 
            p7SegLed3,          -- p_7seg_address_3 
            p7SegLed5,          -- p_7seg_address_5 

            pDac_VR6,
            pDac_VG6,
            pDac_VB6,

            pVideoHS_n,
            pVideoVS_n,

            open,
            open,

            pREM_out,
            pCMT_out,
            pCMT_in,
            open,

            pDac_S,
            open,
            open,

            EPC_CK,
            EPC_CS,
            EPC_OE,
            EPC_DI,
            EPC_DO,

			open,		--	clk21m_out		
			open,		--	clk_hdmi		
			open,		--	esp_rx_o		
			'0',		--	esp_tx_i		
			open,		--	pcm_o			
			open,		--	blank_o			
			'0',		--	ear_i			
			open,		--	mic_o			
			open,		--	midi_o			
			open,		--	midi_active_o	
			open,		--	vga_status		
			open,		--	vga_scanlines	
			open		--	btn_scan		
        );

end RTL;
