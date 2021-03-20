--
--   iplrom3de0cv.vhd
--   Initial Program Loader for Cyclone & EPCS (Altera)
--   Revision 3.00
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
-- IPL-ROM Revision 3.00 for 384 kB unpacked
-- EPCS64 start adr 780000h
--

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity iplrom is
    port (
        clk     : in  std_logic;
        adr     : in  std_logic_vector ( 15 downto 0 );
        dbi     : out std_logic_vector (  7 downto 0 )
    );
end iplrom;

architecture rtl of iplrom is
    type rom_type is array ( 0 to 2047 ) of std_logic_vector (  7 downto 0 );
    constant ipl_data : rom_type := (
        X"F3",X"C3",X"A4",X"00",X"20",X"49",X"6E",X"69",X"74",X"69",X"61",X"6C",X"20",X"50",X"72",X"6F",
        X"67",X"72",X"61",X"6D",X"20",X"4C",X"6F",X"61",X"64",X"65",X"72",X"20",X"66",X"6F",X"72",X"20",
        X"4F",X"6E",X"65",X"43",X"68",X"69",X"70",X"4D",X"53",X"58",X"2E",X"20",X"4C",X"6F",X"61",X"64",
        X"20",X"52",X"4F",X"4D",X"73",X"20",X"66",X"72",X"6F",X"6D",X"20",X"4D",X"4D",X"43",X"2F",X"53",
        X"44",X"2F",X"53",X"44",X"48",X"43",X"2D",X"63",X"61",X"72",X"64",X"20",X"6F",X"72",X"20",X"45",
        X"50",X"43",X"53",X"2E",X"52",X"65",X"76",X"69",X"73",X"69",X"6F",X"6E",X"20",X"33",X"2E",X"30",
        X"30",X"20",X"77",X"69",X"74",X"68",X"6F",X"75",X"74",X"20",X"64",X"61",X"74",X"61",X"20",X"63",
        X"6F",X"6D",X"70",X"72",X"65",X"73",X"73",X"69",X"6F",X"6E",X"2E",X"20",X"56",X"65",X"72",X"73",
        X"2E",X"20",X"66",X"6F",X"72",X"20",X"4F",X"43",X"4D",X"2D",X"4B",X"61",X"69",X"20",X"42",X"75",
        X"69",X"6C",X"64",X"20",X"64",X"61",X"74",X"65",X"20",X"32",X"30",X"32",X"30",X"2E",X"30",X"31",
        X"2E",X"32",X"36",X"00",X"31",X"FF",X"FF",X"21",X"EA",X"00",X"01",X"99",X"0E",X"ED",X"B3",X"01",
        X"9A",X"20",X"ED",X"B3",X"AF",X"D3",X"99",X"3E",X"40",X"D3",X"99",X"21",X"18",X"01",X"01",X"00",
        X"03",X"7E",X"D3",X"98",X"23",X"0B",X"78",X"B1",X"20",X"F7",X"01",X"00",X"3D",X"AF",X"D3",X"98",
        X"0B",X"78",X"B1",X"20",X"F8",X"AF",X"D3",X"99",X"3E",X"48",X"D3",X"99",X"21",X"04",X"00",X"7E",
        X"D6",X"20",X"DA",X"18",X"04",X"D3",X"98",X"23",X"18",X"F5",X"00",X"80",X"50",X"81",X"02",X"82",
        X"00",X"84",X"F4",X"87",X"00",X"89",X"00",X"90",X"00",X"00",X"00",X"00",X"11",X"06",X"33",X"07",
        X"17",X"01",X"27",X"03",X"51",X"01",X"27",X"06",X"71",X"01",X"73",X"03",X"61",X"06",X"64",X"06",
        X"11",X"04",X"65",X"02",X"55",X"05",X"77",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
        X"00",X"20",X"20",X"20",X"20",X"00",X"20",X"00",X"00",X"48",X"48",X"00",X"00",X"00",X"00",X"00",
        X"00",X"00",X"50",X"F8",X"50",X"F8",X"50",X"00",X"00",X"20",X"F8",X"A0",X"F8",X"28",X"F8",X"20",
        X"00",X"00",X"C8",X"D0",X"20",X"58",X"98",X"00",X"00",X"40",X"A0",X"40",X"A8",X"90",X"68",X"00",
        X"00",X"20",X"40",X"00",X"00",X"00",X"00",X"00",X"00",X"08",X"10",X"10",X"10",X"10",X"08",X"00",
        X"00",X"40",X"20",X"20",X"20",X"20",X"40",X"00",X"00",X"00",X"50",X"20",X"F8",X"20",X"50",X"00",
        X"00",X"00",X"20",X"20",X"F8",X"20",X"20",X"00",X"00",X"00",X"00",X"00",X"00",X"20",X"20",X"40",
        X"00",X"00",X"00",X"00",X"F8",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"60",X"60",X"00",
        X"00",X"00",X"08",X"10",X"20",X"40",X"80",X"00",X"00",X"70",X"98",X"A8",X"A8",X"C8",X"70",X"00",
        X"00",X"20",X"60",X"20",X"20",X"20",X"F8",X"00",X"00",X"70",X"88",X"08",X"70",X"80",X"F8",X"00",
        X"00",X"70",X"88",X"30",X"08",X"88",X"70",X"00",X"00",X"10",X"30",X"50",X"90",X"F8",X"10",X"00",
        X"00",X"F8",X"80",X"F0",X"08",X"88",X"70",X"00",X"00",X"70",X"80",X"F0",X"88",X"88",X"70",X"00",
        X"00",X"F8",X"08",X"10",X"20",X"20",X"20",X"00",X"00",X"70",X"88",X"70",X"88",X"88",X"70",X"00",
        X"00",X"70",X"88",X"88",X"78",X"08",X"70",X"00",X"00",X"00",X"20",X"00",X"00",X"20",X"00",X"00",
        X"00",X"00",X"20",X"00",X"00",X"20",X"20",X"40",X"00",X"00",X"10",X"20",X"40",X"20",X"10",X"00",
        X"00",X"00",X"00",X"78",X"00",X"78",X"00",X"00",X"00",X"00",X"20",X"10",X"08",X"10",X"20",X"00",
        X"00",X"70",X"88",X"10",X"20",X"00",X"20",X"00",X"00",X"70",X"A8",X"A8",X"B0",X"80",X"78",X"00",
        X"00",X"78",X"88",X"88",X"F8",X"88",X"88",X"00",X"00",X"F0",X"88",X"F0",X"88",X"88",X"F0",X"00",
        X"00",X"70",X"88",X"80",X"80",X"88",X"70",X"00",X"00",X"E0",X"90",X"88",X"88",X"88",X"F0",X"00",
        X"00",X"F8",X"80",X"F0",X"80",X"80",X"F8",X"00",X"00",X"F8",X"80",X"F0",X"80",X"80",X"80",X"00",
        X"00",X"70",X"88",X"80",X"B8",X"88",X"70",X"00",X"00",X"88",X"88",X"F8",X"88",X"88",X"88",X"00",
        X"00",X"F8",X"20",X"20",X"20",X"20",X"F8",X"00",X"00",X"08",X"08",X"08",X"88",X"88",X"70",X"00",
        X"00",X"90",X"A0",X"C0",X"A0",X"90",X"88",X"00",X"00",X"80",X"80",X"80",X"80",X"80",X"F8",X"00",
        X"00",X"88",X"D8",X"A8",X"A8",X"88",X"88",X"00",X"00",X"88",X"88",X"C8",X"A8",X"98",X"88",X"00",
        X"00",X"70",X"88",X"88",X"88",X"88",X"70",X"00",X"00",X"F0",X"88",X"88",X"F0",X"80",X"80",X"00",
        X"00",X"70",X"88",X"88",X"88",X"A8",X"70",X"10",X"00",X"F0",X"88",X"88",X"F0",X"90",X"88",X"00",
        X"00",X"70",X"80",X"70",X"08",X"88",X"70",X"00",X"00",X"F8",X"20",X"20",X"20",X"20",X"20",X"00",
        X"00",X"88",X"88",X"88",X"88",X"88",X"70",X"00",X"00",X"88",X"88",X"88",X"88",X"50",X"20",X"00",
        X"00",X"88",X"88",X"88",X"A8",X"A8",X"50",X"00",X"00",X"88",X"50",X"20",X"20",X"50",X"88",X"00",
        X"00",X"88",X"88",X"50",X"20",X"20",X"20",X"00",X"00",X"F8",X"90",X"20",X"40",X"88",X"F8",X"00",
        X"00",X"70",X"40",X"40",X"40",X"40",X"70",X"00",X"00",X"00",X"80",X"40",X"20",X"10",X"08",X"00",
        X"00",X"70",X"10",X"10",X"10",X"10",X"70",X"00",X"00",X"20",X"50",X"88",X"00",X"00",X"00",X"00",
        X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FC",X"00",X"40",X"40",X"20",X"00",X"00",X"00",X"00",
        X"00",X"00",X"70",X"08",X"78",X"88",X"78",X"00",X"00",X"80",X"80",X"F0",X"88",X"88",X"F0",X"00",
        X"00",X"00",X"70",X"88",X"80",X"80",X"78",X"00",X"00",X"08",X"08",X"78",X"88",X"88",X"78",X"00",
        X"00",X"00",X"70",X"88",X"F0",X"80",X"78",X"00",X"00",X"18",X"20",X"30",X"20",X"20",X"20",X"00",
        X"00",X"00",X"78",X"88",X"88",X"78",X"08",X"70",X"00",X"80",X"80",X"F0",X"88",X"88",X"88",X"00",
        X"00",X"20",X"00",X"60",X"20",X"20",X"70",X"00",X"00",X"08",X"00",X"08",X"08",X"08",X"48",X"30",
        X"00",X"40",X"50",X"60",X"60",X"50",X"48",X"00",X"00",X"20",X"20",X"20",X"20",X"20",X"18",X"00",
        X"00",X"00",X"D0",X"A8",X"A8",X"A8",X"A8",X"00",X"00",X"00",X"F0",X"88",X"88",X"88",X"88",X"00",
        X"00",X"00",X"70",X"88",X"88",X"88",X"70",X"00",X"00",X"00",X"F0",X"88",X"88",X"F0",X"80",X"80",
        X"00",X"00",X"70",X"90",X"90",X"70",X"10",X"18",X"00",X"00",X"38",X"40",X"40",X"40",X"40",X"00",
        X"00",X"00",X"70",X"80",X"70",X"08",X"F0",X"00",X"00",X"20",X"70",X"20",X"20",X"20",X"18",X"00",
        X"00",X"00",X"88",X"88",X"88",X"88",X"70",X"00",X"00",X"00",X"88",X"88",X"50",X"50",X"20",X"00",
        X"00",X"00",X"88",X"A8",X"A8",X"A8",X"50",X"00",X"00",X"00",X"88",X"50",X"20",X"50",X"88",X"00",
        X"00",X"00",X"88",X"88",X"88",X"78",X"08",X"70",X"00",X"00",X"F8",X"10",X"20",X"40",X"F8",X"00",
        X"00",X"38",X"20",X"C0",X"20",X"20",X"38",X"00",X"00",X"20",X"20",X"20",X"20",X"20",X"20",X"00",
        X"00",X"E0",X"20",X"18",X"20",X"20",X"E0",X"00",X"00",X"28",X"50",X"00",X"00",X"00",X"00",X"00",
        X"30",X"48",X"B4",X"C4",X"C4",X"B4",X"48",X"30",X"01",X"D6",X"02",X"11",X"00",X"FC",X"21",X"26",
        X"04",X"ED",X"B0",X"C3",X"00",X"FC",X"3E",X"D4",X"D3",X"40",X"3E",X"40",X"32",X"00",X"60",X"01",
        X"00",X"01",X"51",X"59",X"21",X"00",X"C0",X"CD",X"16",X"FE",X"38",X"20",X"CD",X"5F",X"FE",X"38",
        X"1B",X"D5",X"C5",X"06",X"01",X"21",X"00",X"C0",X"CD",X"16",X"FE",X"CD",X"44",X"FE",X"C1",X"D1",
        X"20",X"0A",X"CD",X"7B",X"FE",X"38",X"05",X"CD",X"10",X"FD",X"18",X"11",X"CD",X"09",X"FD",X"21",
        X"C7",X"FC",X"22",X"AE",X"FC",X"3E",X"60",X"32",X"00",X"60",X"11",X"00",X"3C",X"CD",X"7B",X"FC",
        X"38",X"10",X"3E",X"80",X"32",X"00",X"70",X"2A",X"00",X"80",X"AF",X"11",X"41",X"42",X"ED",X"52",
        X"28",X"05",X"CD",X"FA",X"FC",X"18",X"FE",X"AF",X"32",X"00",X"60",X"3C",X"32",X"00",X"68",X"32",
        X"00",X"70",X"32",X"00",X"78",X"3E",X"C0",X"D3",X"A8",X"3A",X"00",X"00",X"FE",X"F3",X"20",X"E2",
        X"C7",X"CD",X"ED",X"FC",X"06",X"1C",X"3E",X"80",X"06",X"09",X"CD",X"9E",X"FC",X"D8",X"CD",X"BB",
        X"FC",X"06",X"17",X"CD",X"9E",X"FC",X"D8",X"3E",X"00",X"D3",X"98",X"3E",X"2F",X"D3",X"98",X"3E",
        X"2B",X"D3",X"98",X"C9",X"32",X"00",X"70",X"3C",X"32",X"00",X"78",X"3C",X"F5",X"C5",X"06",X"20",
        X"21",X"00",X"80",X"CD",X"16",X"FE",X"C1",X"E1",X"D8",X"3E",X"1E",X"D3",X"98",X"7C",X"10",X"E4",
        X"C9",X"08",X"3A",X"2D",X"80",X"D6",X"03",X"D3",X"4F",X"D3",X"F4",X"08",X"C9",X"D5",X"CB",X"23",
        X"CB",X"12",X"AF",X"0E",X"40",X"47",X"E5",X"21",X"00",X"40",X"36",X"03",X"72",X"73",X"77",X"7E",
        X"D1",X"7E",X"12",X"13",X"10",X"FB",X"0D",X"20",X"F8",X"3A",X"00",X"50",X"D1",X"21",X"20",X"00",
        X"19",X"EB",X"C9",X"3E",X"18",X"D3",X"99",X"3E",X"49",X"D3",X"99",X"3E",X"1A",X"D3",X"98",X"C9",
        X"C5",X"E5",X"21",X"49",X"FD",X"3E",X"40",X"0E",X"99",X"ED",X"79",X"3E",X"49",X"18",X"14",X"C5",
        X"E5",X"21",X"37",X"FD",X"18",X"05",X"C5",X"E5",X"21",X"25",X"FD",X"3E",X"F0",X"0E",X"99",X"ED",
        X"79",X"3E",X"48",X"ED",X"79",X"CD",X"CC",X"FE",X"E1",X"C1",X"C9",X"4C",X"6F",X"61",X"64",X"20",
        X"66",X"72",X"6F",X"6D",X"20",X"53",X"44",X"2D",X"63",X"61",X"72",X"64",X"00",X"4C",X"6F",X"61",
        X"64",X"20",X"66",X"72",X"6F",X"6D",X"20",X"45",X"50",X"43",X"53",X"36",X"34",X"20",X"00",X"45",
        X"72",X"72",X"6F",X"72",X"20",X"42",X"49",X"4F",X"53",X"00",X"21",X"00",X"40",X"7E",X"36",X"69",
        X"36",X"40",X"36",X"00",X"36",X"00",X"36",X"00",X"36",X"95",X"18",X"36",X"21",X"00",X"40",X"7E",
        X"36",X"48",X"36",X"00",X"36",X"00",X"36",X"01",X"36",X"AA",X"36",X"87",X"18",X"24",X"0E",X"00",
        X"11",X"00",X"00",X"21",X"00",X"40",X"3E",X"00",X"BE",X"70",X"CB",X"4F",X"28",X"07",X"36",X"00",
        X"71",X"72",X"73",X"18",X"0B",X"CB",X"23",X"CB",X"12",X"CB",X"11",X"71",X"72",X"73",X"36",X"00",
        X"36",X"95",X"7E",X"06",X"10",X"7E",X"FE",X"FF",X"3F",X"D0",X"10",X"F9",X"37",X"C9",X"06",X"0A",
        X"3A",X"00",X"50",X"10",X"FB",X"06",X"40",X"CD",X"78",X"FD",X"D8",X"E6",X"F7",X"FE",X"01",X"37",
        X"C0",X"CD",X"66",X"FD",X"FE",X"01",X"20",X"18",X"7E",X"7E",X"7E",X"E6",X"0F",X"FE",X"01",X"37",
        X"C0",X"7E",X"FE",X"AA",X"37",X"C0",X"06",X"77",X"CD",X"78",X"FD",X"D8",X"E6",X"04",X"28",X"0B",
        X"AF",X"32",X"81",X"FD",X"06",X"41",X"CD",X"78",X"FD",X"18",X"08",X"3E",X"01",X"32",X"81",X"FD",
        X"CD",X"54",X"FD",X"D8",X"FE",X"01",X"28",X"DE",X"B7",X"28",X"02",X"37",X"C9",X"3A",X"81",X"FD",
        X"B7",X"C8",X"06",X"7A",X"CD",X"78",X"FD",X"D8",X"7E",X"BE",X"BE",X"BE",X"CB",X"77",X"C8",X"3E",
        X"02",X"32",X"81",X"FD",X"C9",X"CD",X"A8",X"FD",X"C1",X"D1",X"E1",X"D8",X"E5",X"D5",X"C5",X"06",
        X"51",X"CD",X"7D",X"FD",X"38",X"EF",X"C1",X"D1",X"E1",X"B7",X"37",X"C0",X"D5",X"C5",X"EB",X"01",
        X"00",X"02",X"21",X"00",X"40",X"7E",X"FE",X"FE",X"20",X"FB",X"ED",X"B0",X"EB",X"1A",X"C1",X"1A",
        X"D1",X"13",X"7A",X"B3",X"20",X"01",X"0C",X"10",X"D3",X"C9",X"21",X"00",X"C0",X"01",X"80",X"00",
        X"3E",X"46",X"ED",X"B1",X"28",X"01",X"C9",X"E5",X"56",X"23",X"5E",X"21",X"54",X"41",X"B7",X"ED",
        X"52",X"E1",X"20",X"EC",X"C9",X"06",X"04",X"DD",X"21",X"BE",X"C1",X"DD",X"5E",X"08",X"DD",X"56",
        X"09",X"DD",X"4E",X"0A",X"79",X"B2",X"B3",X"C0",X"11",X"10",X"00",X"DD",X"19",X"10",X"EC",X"37",
        X"C9",X"DD",X"21",X"00",X"C0",X"DD",X"6E",X"0E",X"DD",X"66",X"0F",X"79",X"19",X"CE",X"00",X"4F",
        X"DD",X"5E",X"11",X"DD",X"56",X"12",X"7B",X"E6",X"0F",X"06",X"04",X"CB",X"3A",X"CB",X"1B",X"10",
        X"FA",X"B7",X"28",X"01",X"13",X"D5",X"DD",X"46",X"10",X"DD",X"5E",X"16",X"DD",X"56",X"17",X"79",
        X"19",X"CE",X"00",X"10",X"FB",X"D1",X"19",X"EB",X"4F",X"D5",X"C5",X"06",X"01",X"21",X"00",X"C0",
        X"CD",X"16",X"FE",X"D8",X"2A",X"00",X"C0",X"11",X"41",X"42",X"B7",X"ED",X"52",X"C1",X"D1",X"C8",
        X"37",X"C9",X"AF",X"7E",X"23",X"D6",X"20",X"D8",X"D3",X"98",X"18",X"F7",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF"
    );

begin

    process( clk )
    begin
        if( clk'event and clk = '1' )then
            dbi <= ipl_data( conv_integer( adr(  10 downto 0 )));    -- conv_integer is limited to 2048 bytes
        end if;
    end process;

end rtl;
