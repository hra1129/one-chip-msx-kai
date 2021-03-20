// --------------------------------------------------------------------
//  extract BIOS image file from original emsx_top.hex
// ====================================================================
//  2020/04/20  t.hara
// --------------------------------------------------------------------
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cctype>
#include <cstring>

using namespace std;

// --------------------------------------------------------------------
static int get_1column( string &s_line ){
	int c;

	if( s_line.length() == 0 ){
		return 0;
	}
	c = s_line[ 0 ] & 255;
	s_line = s_line.substr( 1 );
	if( isdigit( c ) ){
		return (int)( c - '0' );
	}
	return (int)( toupper( c ) - 'A' ) + 10;
}

// --------------------------------------------------------------------
static int get_1byte( string &s_line ){
	int d;
	d = get_1column( s_line ) << 4;
	d |= get_1column( s_line );
	return d;
}

// --------------------------------------------------------------------
static bool get_intel_hex_line( ifstream &hex_file, int &data_length, int &offset_address, int &record_type, vector< unsigned char > &data ){
	string s_line;
	int d;

	if( hex_file.eof() ){
		return false;					//	End of file.
	}
	getline( hex_file, s_line );
	if( s_line.length() == 0 || s_line[ 0 ] != ':' ){
		return true;					//	This is blank line or comment line.
	}
	data.clear();

	s_line = s_line.substr( 1 );		//	Cut record mark ':'.
	data_length = get_1byte( s_line );
	offset_address = get_1byte( s_line ) << 8;
	offset_address |= get_1byte( s_line );
	record_type = get_1byte( s_line );
	for( int i = 0; i < data_length; i++ ){
		d = get_1byte( s_line );
		data.push_back( d );
	}
	return true;
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ){
	vector< unsigned char > data;
	ifstream emsx_top( "emsx_top.hex" );
	int data_length, offset_address, record_type;
	int line_no = 0;
	static char s_bank[ 16384 ];
	int remain_length, write_position;
	vector< const char * > file_name_list = {
		"ocm_megasdhc_0.rom",
		"ocm_megasdhc_1.rom",
		"ocm_megasdhc_2.rom",
		"ocm_megasdhc_3.rom",
		"ocm_msx2_main_0.rom",
		"ocm_msx2_main_1.rom",
		"ocm_msx2_ext.rom",
		"ocm_msx2_opll.rom",
		"ocm_msx2_kanji_0.rom",
		"ocm_msx2_kanji_1.rom",
		"ocm_msx2_kanji_2.rom",
		"ocm_msx2_kanji_3.rom",
		"ocm_msx2_kanji_4.rom",
		"ocm_msx2_kanji_5.rom",
		"ocm_msx2_kanji_6.rom",
		"ocm_msx2_kanji_7.rom",
	};
	const char *p_dummy_name = "ocm_dummy.rom";
	int file_name_index = 0;

	if( !emsx_top ){
		cerr << "[ERROR!] 'emsx_top.hex' is not found." << endl;
		return 1;
	}

	remain_length = sizeof( s_bank );
	write_position = 0;
	while( file_name_list.size() > (unsigned)file_name_index ){
		if( !get_intel_hex_line( emsx_top, data_length, offset_address, record_type, data ) ){
			break;		//	End of file.
		}
		line_no++;
		if( record_type != 0x00 ){
			continue;	//	emsx_top.hex専用なのでアドレスはインクリメント前提で無視。セグメントレコード指定も無視。
		}

		if( data.size() > (unsigned)remain_length ){
			//	emsx_top専用なので、中途半端なサイズには対応しない。
			cerr << "[ERROR!] Invalid data length." << endl;
			return 1;
		}
		memcpy( s_bank + write_position, &data[ 0 ], data.size() );
		write_position += data.size();
		remain_length -= data.size();
		if( remain_length == 0 ){
			ofstream rom_image( file_name_list[ file_name_index ], ios::binary );
			if( !rom_image ){
				cerr << "[ERROR!] Cannot create '" << file_name_list[ file_name_index ] << "'." << endl;
				return 1;
			}
			cout << "Create '" << file_name_list[ file_name_index ] << "'." << endl;
			rom_image.write( s_bank, sizeof( s_bank ) );
			rom_image.close();
			file_name_index++;

			remain_length = sizeof( s_bank );
			write_position = 0;
		}
	}

	memset( s_bank, 0xFF, sizeof(s_bank) );
	ofstream rom_image( p_dummy_name, ios::binary );
	if( !rom_image ){
		cerr << "[ERROR!] Cannot create '" << p_dummy_name << "'." << endl;
		return 1;
	}
	cout << "Create '" << p_dummy_name << "'." << endl;
	rom_image.write( s_bank, sizeof( s_bank ) );
	rom_image.close();
	return 0;
}