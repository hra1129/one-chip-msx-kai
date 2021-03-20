//
// debuffer_font.v
//   debuffer device
//   Revision 1.00
//
// Copyright (c) 2019 Takayuki Hara.
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//    product or activity without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ----------------------------------------------------------------------------
//	Update history
//	07th,December,2019 First release by t.hara
//

module debugger_font (
	input			clk21m,
	input	[ 5:0]	char_code,
	input	[ 2:0]	column_no,
	input	[ 2:0]	line_no,
	output			pixel
);
	reg		[7:0]	mem_array[0:7][0:37] = '{
		'{	//	code 0: space
			8'b00000000,
			8'b00000000,
			8'b00000000,
			8'b00000000,
			8'b00000000,
			8'b00000000,
			8'b00000000,
			8'b00000000
		},
		'{	//	code 1: colon
			8'b00000000,
			8'b00010000,
			8'b00010000,
			8'b00000000,
			8'b00000000,
			8'b00010000,
			8'b00010000,
			8'b00000000
		},
		'{	//	code 2: '0'
			8'b01111100,
			8'b11000010,
			8'b10100010,
			8'b10010010,
			8'b10001010,
			8'b10000110,
			8'b01111100,
			8'b00000000
		},
		'{	//	code 3: '1'
			8'b00010000,
			8'b00110000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b01111100,
			8'b00000000
		},
		'{	//	code 4: '2'
			8'b01111100,
			8'b10000010,
			8'b00000100,
			8'b00011000,
			8'b01100000,
			8'b10000000,
			8'b11111110,
			8'b00000000
		},
		'{	//	code 5: '3'
			8'b01111100,
			8'b10000010,
			8'b00000010,
			8'b00111100,
			8'b00000010,
			8'b10000010,
			8'b01111100,
			8'b00000000
		},
		'{	//	code 6: '4'
			8'b00011000,
			8'b00101000,
			8'b01001000,
			8'b10001000,
			8'b11111110,
			8'b00001000,
			8'b00001000,
			8'b00000000
		},
		'{	//	code 7: '5'
			8'b11111110,
			8'b10000000,
			8'b10000000,
			8'b11111100,
			8'b00000010,
			8'b00000010,
			8'b11111100,
			8'b00000000
		},
		'{	//	code 8: '6'
			8'b00111100,
			8'b01000000,
			8'b10000000,
			8'b11111100,
			8'b10000010,
			8'b10000010,
			8'b01111100,
			8'b00000000
		},
		'{	//	code 9: '7'
			8'b11111110,
			8'b10000010,
			8'b00000100,
			8'b00001000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00000000
		},
		'{	//	code 10: '8'
			8'b01111100,
			8'b10000010,
			8'b10000010,
			8'b01111100,
			8'b10000010,
			8'b10000010,
			8'b01111100,
			8'b00000000
		},
		'{	//	code 11: '9'
			8'b01111100,
			8'b10000010,
			8'b10000010,
			8'b01111110,
			8'b00000010,
			8'b00000100,
			8'b01111000,
			8'b00000000
		},
		'{	//	code 12: 'A'
			8'b00111000,
			8'b01000100,
			8'b10000010,
			8'b10000010,
			8'b11111110,
			8'b10000010,
			8'b10000010,
			8'b00000000
		},
		'{	//	code 13: 'B'
			8'b11111100,
			8'b10000010,
			8'b10000010,
			8'b11111100,
			8'b10000010,
			8'b10000010,
			8'b11111100,
			8'b00000000
		},
		'{	//	code 14: 'C'
			8'b00111000,
			8'b01000100,
			8'b10000000,
			8'b10000000,
			8'b10000000,
			8'b01000100,
			8'b00111000,
			8'b00000000
		},
		'{	//	code 15: 'D'
			8'b11111000,
			8'b10000100,
			8'b10000010,
			8'b10000010,
			8'b10000010,
			8'b10000100,
			8'b11111000,
			8'b00000000
		},
		'{	//	code 16: 'E'
			8'b11111110,
			8'b10000000,
			8'b10000000,
			8'b11111100,
			8'b10000000,
			8'b10000000,
			8'b11111110,
			8'b00000000
		},
		'{	//	code 17: 'F'
			8'b11111110,
			8'b10000000,
			8'b10000000,
			8'b11111100,
			8'b10000000,
			8'b10000000,
			8'b10000000,
			8'b00000000
		},
		'{	//	code 18: 'G'
			8'b00111000,
			8'b01000100,
			8'b10000000,
			8'b10011110,
			8'b10000010,
			8'b01000100,
			8'b00111000,
			8'b00000000
		},
		'{	//	code 19: 'H'
			8'b10000010,
			8'b10000010,
			8'b10000010,
			8'b11111110,
			8'b10000010,
			8'b10000010,
			8'b10000010,
			8'b00000000
		},
		'{	//	code 20: 'I'
			8'b00111000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00111000,
			8'b00000000
		},
		'{	//	code 21: 'J'
			8'b00000010,
			8'b00000010,
			8'b00000010,
			8'b00000010,
			8'b10000010,
			8'b10000010,
			8'b01111100,
			8'b00000000
		},
		'{	//	code 22: 'K'
			8'b10000110,
			8'b10011000,
			8'b10100000,
			8'b11010000,
			8'b10001000,
			8'b10000100,
			8'b10000010,
			8'b00000000
		},
		'{	//	code 23: 'L'
			8'b10000000,
			8'b10000000,
			8'b10000000,
			8'b10000000,
			8'b10000000,
			8'b10000000,
			8'b11111110,
			8'b00000000
		},
		'{	//	code 24: 'M'
			8'b10000010,
			8'b11000110,
			8'b10101010,
			8'b10010010,
			8'b10000010,
			8'b10000010,
			8'b10000010,
			8'b00000000
		},
		'{	//	code 25: 'N'
			8'b10000010,
			8'b11000010,
			8'b10100010,
			8'b10010010,
			8'b10001010,
			8'b10000110,
			8'b10000010,
			8'b00000000
		},
		'{	//	code 26: 'O'
			8'b00111000,
			8'b01000100,
			8'b10000010,
			8'b10000010,
			8'b10000010,
			8'b01000100,
			8'b00111000,
			8'b00000000
		},
		'{	//	code 27: 'P'
			8'b11111100,
			8'b10000010,
			8'b10000010,
			8'b11111100,
			8'b10000000,
			8'b10000000,
			8'b10000000,
			8'b00000000
		},
		'{	//	code 28: 'Q'
			8'b00111000,
			8'b01000100,
			8'b10000010,
			8'b10000010,
			8'b10111010,
			8'b01000100,
			8'b00111010,
			8'b00000000
		},
		'{	//	code 29: 'R'
			8'b11111100,
			8'b10000010,
			8'b10000010,
			8'b11111100,
			8'b10001000,
			8'b10000100,
			8'b10000010,
			8'b00000000
		},
		'{	//	code 30: 'S'
			8'b01111100,
			8'b10000010,
			8'b10000000,
			8'b01111100,
			8'b00000010,
			8'b10000010,
			8'b01111100,
			8'b00000000
		},
		'{	//	code 31: 'T'
			8'b11111110,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00000000
		},
		'{	//	code 32: 'U'
			8'b10000010,
			8'b10000010,
			8'b10000010,
			8'b10000010,
			8'b10000010,
			8'b01000100,
			8'b00111000,
			8'b00000000
		},
		'{	//	code 33: 'V'
			8'b10000010,
			8'b10000010,
			8'b01000100,
			8'b01000100,
			8'b00101000,
			8'b00101000,
			8'b00010000,
			8'b00000000
		},
		'{	//	code 34: 'W'
			8'b10000010,
			8'b10010010,
			8'b10010010,
			8'b10010010,
			8'b10010010,
			8'b10010010,
			8'b01101100,
			8'b00000000
		},
		'{	//	code 35: 'X'
			8'b10000010,
			8'b01000100,
			8'b00101000,
			8'b00010000,
			8'b00101000,
			8'b01000100,
			8'b10000010,
			8'b00000000
		},
		'{	//	code 36: 'Y'
			8'b10000010,
			8'b01000100,
			8'b00101000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00010000,
			8'b00000000
		},
		'{	//	code 37: 'Z'
			8'b11111110,
			8'b00000100,
			8'b00001000,
			8'b00010000,
			8'b00100000,
			8'b01000000,
			8'b11111110,
			8'b00000000
		},
	};


endmodule
