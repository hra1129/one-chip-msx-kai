--
-- VoiceRom.vhd
--
-- Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
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
-------------------------------------------------------------------------------
-- History
-- 2020/09/02 modified by t.hara
--   (1) Changed the notation of ROM to hexadecimal numbers.
--   (2) Copy the ROM data from YM2413Burczynski.cc in OpenMSX 16.0.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.VM2413.ALL;

entity VoiceRom is
  port (
    clk    : in std_logic;
    addr : in VOICE_ID_TYPE;
    data  : out VOICE_TYPE
  );
end VoiceRom;

architecture RTL of VoiceRom is

  type VOICE_ARRAY_TYPE is array (VOICE_ID_TYPE'range) of VOICE_VECTOR_TYPE;
  constant voices : VOICE_ARRAY_TYPE := (
-- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
--  X"00" & X"00" & X"0" & X"00" & X"00", -- @0(M) user instrument
--  X"00" & X"00" & X"0" & X"00" & X"00", -- @0(C) user instrument
--
--  X"61" & X"1E" & X"7" & X"F0" & X"00", -- @1(M) violin
--  X"61" & X"00" & X"8" & X"7F" & X"17", -- @1(C) violin
--
--  X"13" & X"17" & X"E" & X"FF" & X"23", -- @2(M) guitar
--  X"41" & X"00" & X"0" & X"FF" & X"13", -- @2(C) guitar
--
--  X"23" & X"9A" & X"4" & X"A3" & X"F0", -- @3(M) piano
--  X"01" & X"00" & X"0" & X"F4" & X"23", -- @3(C) piano
--
--  X"11" & X"0E" & X"7" & X"FA" & X"70", -- @4(M) flute
--  X"61" & X"00" & X"0" & X"64" & X"17", -- @4(C) flute
--
--  X"22" & X"1E" & X"6" & X"F0" & X"00", -- @5(M) clarinet
--  X"21" & X"00" & X"0" & X"76" & X"28", -- @5(C) clarinet
--
--  X"21" & X"16" & X"5" & X"F0" & X"00", -- @6(M) oboe
--  X"22" & X"00" & X"0" & X"71" & X"18", -- @6(C) oboe
--
--  X"21" & X"1D" & X"7" & X"82" & X"10", -- @7(M) trumpet
--  X"61" & X"00" & X"0" & X"80" & X"07", -- @7(C) trumpet
--
--  X"23" & X"2D" & X"6" & X"90" & X"00", -- @8(M) organ
--  X"21" & X"00" & X"8" & X"90" & X"07", -- @8(C) organ
--
--  X"21" & X"1B" & X"6" & X"64" & X"10", -- @9(M) horn
--  X"21" & X"00" & X"0" & X"65" & X"17", -- @9(C) horn
--
--  X"21" & X"0B" & X"A" & X"85" & X"70", -- @10(M) synthesizer
--  X"21" & X"00" & X"8" & X"A0" & X"07", -- @10(C) synthesizer
--
--  X"23" & X"83" & X"0" & X"FF" & X"10", -- @11(M) harpsichord
--  X"01" & X"00" & X"8" & X"B0" & X"04", -- @11(C) harpsichord
--
--  X"97" & X"20" & X"7" & X"FF" & X"22", -- @12(M) vibraphone
--  X"C1" & X"00" & X"0" & X"FF" & X"12", -- @12(C) vibraphone
--
--  X"61" & X"0C" & X"5" & X"D2" & X"40", -- @13(M) synthesizer bass
--  X"00" & X"00" & X"0" & X"F6" & X"43", -- @13(C) synthesizer bass
--
--  X"01" & X"56" & X"3" & X"F4" & X"03", -- @14(M) acoustic bass
--  X"01" & X"00" & X"0" & X"F0" & X"02", -- @14(C) acoustic bass
--
--  X"21" & X"89" & X"3" & X"F1" & X"F0", -- @15(M) electric guitar
--  X"41" & X"00" & X"0" & X"F4" & X"23", -- @15(C) electric guitar
--
--  X"07" & X"16" & X"0" & X"DF" & X"FF", -- BD(M) 
--  X"21" & X"00" & X"0" & X"F8" & X"F8", -- BD(C) 
--
--  X"31" & X"00" & X"0" & X"F7" & X"F7", -- HH 
--  X"32" & X"00" & X"0" & X"F7" & X"F7", -- SD 
--
--  X"25" & X"00" & X"0" & X"F8" & X"F8", -- TOM 
--  X"01" & X"00" & X"0" & X"DC" & X"55"  -- CYM 

-- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
  X"00" & X"00" & X"0" & X"00" & X"00", -- @0(M) user instrument
  X"00" & X"00" & X"0" & X"00" & X"00", -- @0(C) user instrument

  X"61" & X"1E" & X"7" & X"F0" & X"00", -- @1(M) violin
  X"61" & X"00" & X"8" & X"7F" & X"17", -- @1(C) violin

  X"13" & X"16" & X"E" & X"FD" & X"23", -- @2(M) guitar
  X"41" & X"00" & X"0" & X"F4" & X"13", -- @2(C) guitar

  X"03" & X"9A" & X"4" & X"F3" & X"13", -- @3(M) piano
  X"01" & X"00" & X"0" & X"F3" & X"F3", -- @3(C) piano

  X"11" & X"0E" & X"7" & X"FA" & X"70", -- @4(M) flute
  X"61" & X"00" & X"0" & X"64" & X"17", -- @4(C) flute

  X"22" & X"1E" & X"6" & X"F0" & X"00", -- @5(M) clarinet
  X"21" & X"00" & X"0" & X"76" & X"28", -- @5(C) clarinet

  X"21" & X"16" & X"5" & X"F0" & X"00", -- @6(M) oboe
  X"22" & X"00" & X"0" & X"71" & X"18", -- @6(C) oboe

  X"21" & X"1D" & X"7" & X"82" & X"17", -- @7(M) trumpet
  X"61" & X"00" & X"0" & X"80" & X"17", -- @7(C) trumpet

  X"23" & X"2D" & X"6" & X"90" & X"00", -- @8(M) organ
  X"21" & X"00" & X"8" & X"90" & X"07", -- @8(C) organ

  X"21" & X"1B" & X"6" & X"64" & X"10", -- @9(M) horn
  X"21" & X"00" & X"0" & X"65" & X"17", -- @9(C) horn

  X"21" & X"0B" & X"A" & X"85" & X"70", -- @10(M) synthesizer
  X"21" & X"00" & X"8" & X"A0" & X"07", -- @10(C) synthesizer

  X"23" & X"83" & X"0" & X"FF" & X"10", -- @11(M) harpsichord
  X"01" & X"00" & X"8" & X"B4" & X"F4", -- @11(C) harpsichord

  X"97" & X"20" & X"7" & X"FF" & X"22", -- @12(M) vibraphone
  X"C1" & X"00" & X"0" & X"F4" & X"22", -- @12(C) vibraphone

  X"61" & X"0C" & X"5" & X"C2" & X"40", -- @13(M) synthesizer bass
  X"00" & X"00" & X"0" & X"F6" & X"44", -- @13(C) synthesizer bass

  X"01" & X"56" & X"3" & X"94" & X"03", -- @14(M) acoustic bass
  X"01" & X"00" & X"0" & X"C2" & X"12", -- @14(C) acoustic bass

  X"21" & X"89" & X"3" & X"F1" & X"F0", -- @15(M) electric guitar
  X"01" & X"00" & X"0" & X"E4" & X"23", -- @15(C) electric guitar

  X"01" & X"16" & X"0" & X"FD" & X"2F", -- BD(M) 
  X"01" & X"00" & X"0" & X"F8" & X"6D", -- BD(C) 

  X"01" & X"00" & X"0" & X"D8" & X"F9", -- HH 
  X"01" & X"00" & X"0" & X"D8" & X"F8", -- SD 

  X"05" & X"00" & X"0" & X"F8" & X"49", -- TOM 
  X"01" & X"00" & X"0" & X"BA" & X"55"  -- CYM 
);

begin

  process (clk)

  begin

    if clk'event and clk = '1' then
      data <= CONV_VOICE(voices(addr));
    end if;

  end process;

end RTL;