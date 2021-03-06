-- 
-- rtc.vhd
--   Real time clock (RP-5C01)
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rtc_original is
  port(
    clk21m  : in std_logic;
    reset   : in std_logic;
    clkena  : in std_logic;
    req     : in std_logic;
    ack     : out std_logic;
    wrt     : in std_logic;
    adr     : in std_logic_vector(15 downto 0);
    dbi     : out std_logic_vector(7 downto 0);
    dbo     : in std_logic_vector(7 downto 0)
 );
end rtc_original;

architecture rtl of rtc_original is

  component ram is
    port (
      adr   : in  std_logic_vector(7 downto 0);
      clk   : in  std_logic;
      we    : in  std_logic;
      dbo   : in  std_logic_vector(7 downto 0);
      dbi   : out std_logic_vector(7 downto 0)
    );
  end component;

  -- RTC signals
  signal ireq        : std_logic;
  signal MemWe       : std_logic;
  signal MemAdr      : std_logic_vector(7 downto 0);
  signal oMemDat     : std_logic_vector(7 downto 0);
  signal PreScaler   : std_logic_vector(23 downto 0) := x"000000";
  signal RtcRegPtr   : std_logic_vector(3 downto 0) := "0000";
  signal RegMode     : std_logic_vector(3 downto 0) := "1000";
  signal RegTest     : std_logic_vector(3 downto 0) := "0000";
  signal RegRest     : std_logic_vector(3 downto 0) := "0000";

  signal RegSec      : std_logic_vector(7 downto 0) := "00000000";
  signal RegMin      : std_logic_vector(7 downto 0) := "00000000";
  signal RegHou      : std_logic_vector(7 downto 0) := "00000000";
  signal RegWee      : std_logic_vector(7 downto 0) := "00000000";
  signal RegDay      : std_logic_vector(7 downto 0) := "00000000";
  signal RegMon      : std_logic_vector(7 downto 0) := "00000000";
  signal RegYea      : std_logic_vector(7 downto 0) := "00000000";
  signal RegMinA     : std_logic_vector(7 downto 0) := "00000000";
  signal RegHouA     : std_logic_vector(7 downto 0) := "00000000";
  signal RegWeeA     : std_logic_vector(7 downto 0) := "00000000";
  signal RegDayA     : std_logic_vector(7 downto 0) := "00000000";
  signal Reg1224     : std_logic_vector(7 downto 0) := "00000000";
  signal RegLeap     : std_logic_vector(7 downto 0) := "00000000";

begin

  ----------------------------------------------------------------
  -- RTC register read
  ----------------------------------------------------------------
  dbi <= "1111" & RegMode when RtcRegPtr = "1101" and adr(0) = '1' else
         "1111" & RegTest when RtcRegPtr = "1110" and adr(0) = '1' else
         "1111" & RegRest when RtcRegPtr = "1111" and adr(0) = '1' else

         "1111" & RegSec(3 downto 0) when RegMode(1 downto 0) & RtcRegPtr = "000000" and adr(0) = '1' else
         "1111" & RegSec(7 downto 4) when RegMode(1 downto 0) & RtcRegPtr = "000001" and adr(0) = '1' else
         "1111" & RegMin(3 downto 0) when RegMode(1 downto 0) & RtcRegPtr = "000010" and adr(0) = '1' else
         "1111" & RegMin(7 downto 4) when RegMode(1 downto 0) & RtcRegPtr = "000011" and adr(0) = '1' else
         "1111" & RegHou(3 downto 0) when RegMode(1 downto 0) & RtcRegPtr = "000100" and adr(0) = '1' else
         "1111" & RegHou(7 downto 4) when RegMode(1 downto 0) & RtcRegPtr = "000101" and adr(0) = '1' else
         "1111" & RegWee(3 downto 0) when RegMode(1 downto 0) & RtcRegPtr = "000110" and adr(0) = '1' else
         "1111" & RegDay(3 downto 0) when RegMode(1 downto 0) & RtcRegPtr = "000111" and adr(0) = '1' else
         "1111" & RegDay(7 downto 4) when RegMode(1 downto 0) & RtcRegPtr = "001000" and adr(0) = '1' else
         "1111" & RegMon(3 downto 0) when RegMode(1 downto 0) & RtcRegPtr = "001001" and adr(0) = '1' else
         "1111" & RegMon(7 downto 4) when RegMode(1 downto 0) & RtcRegPtr = "001010" and adr(0) = '1' else
         "1111" & RegYea(3 downto 0) when RegMode(1 downto 0) & RtcRegPtr = "001011" and adr(0) = '1' else
         "1111" & RegYea(7 downto 4) when RegMode(1 downto 0) & RtcRegPtr = "001100" and adr(0) = '1' else
         "1111" & RegLeap(3 downto 0) when RegMode(1 downto 0) & RtcRegPtr = "011011" and adr(0) = '1' else

         oMemDat          when                        adr(0) = '1' else
         (others => '1');

  ----------------------------------------------------------------
  -- RTC register write
  ----------------------------------------------------------------
  process(clk21m, reset)

  begin

    if (reset = '1') then

      ireq      <= '0';
      RtcRegPtr <= (others => '0');
      RegMode   <= (others => '0');
      RegTest   <= (others => '0');
      RegRest   <= (others => '0');

      RegSec(7)           <= '0';
      RegMin(7)           <= '0';
      RegHou(7 downto 6)  <= (others => '0');
      RegWee(3)           <= '0';
      RegDay(7 downto 6)  <= (others => '0');
      RegMon(7 downto 5)  <= (others => '0');
      RegLeap(7 downto 2) <= (others => '0');

    elsif (clk21m'event and clk21m = '1') then

      ireq <= req;

      if (req = '1' and wrt = '1' and adr(0) = '0') then
        -- register pointer
        RtcRegPtr <= dbo(3 downto 0);
      elsif (req = '1' and wrt = '1' and adr(0) = '1') then
        -- Rtc registers
        if (RegMode(1 downto 0) = "00") then
          case RtcRegPtr is
            when "0000" => RegSec(3 downto 0) <= dbo(3 downto 0);
            when "0001" => RegSec(6 downto 4) <= dbo(2 downto 0);
            when "0010" => RegMin(3 downto 0) <= dbo(3 downto 0);
            when "0011" => RegMin(6 downto 4) <= dbo(2 downto 0);
            when "0100" => RegHou(3 downto 0) <= dbo(3 downto 0);
            when "0101" => RegHou(5 downto 4) <= dbo(1 downto 0);
            when "0110" => RegWee(2 downto 0) <= dbo(2 downto 0);
            when "0111" => RegDay(3 downto 0) <= dbo(3 downto 0);
            when "1000" => RegDay(5 downto 4) <= dbo(1 downto 0);
            when "1001" => RegMon(3 downto 0) <= dbo(3 downto 0);
            when "1010" => RegMon(4         ) <= dbo(0         );
            when "1011" => RegYea(3 downto 0) <= dbo(3 downto 0);
            when "1100" => RegYea(7 downto 4) <= dbo(3 downto 0);
            when others => null;
          end case;
        end if;

        if (RegMode(1 downto 0) = "01") then
          case RtcRegPtr is
            when "0010" => RegMinA(3 downto 0) <= dbo(3 downto 0);
            when "0011" => RegMinA(6 downto 4) <= dbo(2 downto 0);
            when "0100" => RegHouA(3 downto 0) <= dbo(3 downto 0);
            when "0101" => RegHouA(5 downto 4) <= dbo(1 downto 0);
            when "0110" => RegWeeA(2 downto 0) <= dbo(2 downto 0);
            when "0111" => RegDayA(3 downto 0) <= dbo(3 downto 0);
            when "1000" => RegDayA(5 downto 4) <= dbo(1 downto 0);
            when "1010" => Reg1224(0         ) <= dbo(0         );
            when "1011" => RegLeap(1 downto 0) <= dbo(1 downto 0);
            when others => null;
          end case;
        end if;

        case RtcRegPtr is
          when "1101" => RegMode <= dbo(3 downto 0);
          when "1110" => RegTest <= dbo(3 downto 0);
          when "1111" => RegRest <= dbo(3 downto 0);
          when others => null;
        end case;

      elsif (clkena = '1') then

        if (PreScaler /= X"000000") then
          PreScaler <= PreScaler - 1;
        else
          PreScaler <= X"369E99"; --(3.579545MHz)
--          PreScaler <= X"000009"; --(10Hz)
          if (RegSec(3 downto 0) /= "1001") then
            RegSec(3 downto 0) <= RegSec(3 downto 0) + 1;
          else
            RegSec(3 downto 0) <= (others => '0');
            if (RegSec(6 downto 4) /= "101") then
              RegSec(6 downto 4) <= RegSec(6 downto 4) + 1;
            else
              RegSec(6 downto 4) <= (others => '0');
              if (RegMin(3 downto 0) /= "1001") then
                RegMin(3 downto 0) <= RegMin(3 downto 0) + 1;
              else
                RegMin(3 downto 0) <= (others => '0');
                if (RegMin(6 downto 4) /= "101") then
                  RegMin(6 downto 4) <= RegMin(6 downto 4) + 1;
                else
                  RegMin(6 downto 4) <= (others => '0');
                  if (RegHou(3 downto 0) = "1001") then
                    RegHou(3 downto 0) <= "0000";
                    RegHou(5 downto 4) <= RegHou(5 downto 4) + 1;
                  elsif ((Reg1224(0) & RegHou(4 downto 0) /= "010001") and
                         (Reg1224(0) & RegHou(5 downto 0) /= "1100011")) then
                    RegHou(3 downto 0) <= RegHou(3 downto 0) + 1;
                  else
                    RegHou(4 downto 0) <= (others => '0');
                    RegHou(5) <= not RegHou(5);

                    if (RegWee(2 downto 0) /= "110") then
                      RegWee(2 downto 0) <= RegWee(2 downto 0) + 1;
                    else
                      RegWee(2 downto 0) <= (others => '0');
                    end if;

                    if ((RegMon & RegDay & RegLeap = X"022801") or
                        (RegMon & RegDay & RegLeap = X"022802") or
                        (RegMon & RegDay & RegLeap = X"022803") or
                        (RegMon & RegDay & RegLeap = X"022900") or
                        (RegMon & RegDay = X"0430") or
                        (RegMon & RegDay = X"0630") or
                        (RegMon & RegDay = X"0930") or
                        (RegMon & RegDay = X"1130") or
                        (         RegDay = X"31")) then
                      RegDay(5 downto 0) <= "000001";

                      if (RegMon(3 downto 0) = "1001") then
                        RegMon(4 downto 0) <= "10000";
                      elsif (RegMon(4 downto 0) /= "10010" ) then
                        RegMon(3 downto 0) <= RegMon(3 downto 0) + 1;
                      else
                        RegMon(4 downto 0) <= "00001";
                        RegLeap(1 downto 0) <= RegLeap(1 downto 0) + 1;
                        if (RegYea(3 downto 0) /= "1001") then
                          RegYea(3 downto 0) <= RegYea(3 downto 0) + 1;
                        else
                          RegYea(3 downto 0) <= "0000";
                          if (RegYea(7 downto 4) /= "1001") then
                            RegYea(7 downto 4) <= RegYea(7 downto 4) + 1;
                          else
                            RegYea(7 downto 4) <= "0000";
                          end if;
                        end if;
                      end if;

                    elsif (RegDay(3 downto 0) /= "1001") then
                      RegDay(3 downto 0) <= RegDay(3 downto 0) + 1;
                    else
                      RegDay(3 downto 0) <= (others => '0');
                      RegDay(5 downto 4) <= RegDay(5 downto 4) + 1;
                    end if;
                  end if;
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;

    end if;

  end process;

  ----------------------------------------------------------------
  -- Connect components
  ----------------------------------------------------------------

  -- I/O port access on B5h ... RTC register access
  MemAdr <= "00" & RegMode(1 downto 0) & RtcRegPtr;
  MemWe  <= wrt when req = '1' and ireq = '0' and adr(0) = '1' else '0';
  ack    <= ireq;
  Mem : ram port map(MemAdr, clk21m, MemWe, dbo, oMemDat);

end rtl;
