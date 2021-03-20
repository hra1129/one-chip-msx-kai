// --------------------------------------------------------------------
//  BIOS Image Maker
// ====================================================================
//  2020/04/17  t.hara
// --------------------------------------------------------------------

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cctype>
#include <cstring>
#include <tuple>
#include <sstream>
#include <iomanip>

using namespace std;

// --------------------------------------------------------------------
class C_BIOS_IMAGE {
private:
	unsigned char				flag;
	vector< unsigned char >		command_blocks;
	vector< unsigned char >		rom_images;
	vector< string >			log;
	int							total_size;
	int							current_eseram_bank;

	tuple< int, int > get_outport( const vector< string > &a_commands ){
		int address, data = 0;

		address = stoi( a_commands[ 1 ], nullptr, 0 );
		if( a_commands.size() > 2 ){
			data = stoi( a_commands[ 2 ], nullptr, 0 );
		}
		return make_tuple( address, data );
	}

public:
	C_BIOS_IMAGE(){
		flag = 0;
		command_blocks.clear();
		rom_images.clear();
		log.clear();
		total_size = 0;
		current_eseram_bank = 128;
	}

	// --------------------------------------------------------------------
	//	a_commands[0] = "DISPLAY_MESSAGE"
	//	a_commands[1] = "ON" or "OFF"
	void set_display_message( vector< string > &a_commands ){
		if( a_commands[1] == "ON" ){
			flag = flag & ~1;
		}
		else{
			flag = flag | 1;
		}
	}

	// --------------------------------------------------------------------
	//	a_commands[0] = "MONITOR_TYPE"
	//	a_commands[1] = "NTSC" or "PAL"
	void set_pal_mode( vector< string > &a_commands ){
		if( a_commands[ 1 ] == "PAL" ){
			flag = flag | 2;
		}
		else{
			flag = flag & ~2;
		}
	}

	// --------------------------------------------------------------------
	//	a_commands[0] = "TERMINATE"
	//	a_commands[1] = total size
	//
	//	BIOS image file が total size に満たない場合は、FF を padding して
	//	ファイルサイズを指定のサイズまで増やす。
	//	total size の方が小さい場合は、padding は付けない。
	//
	void add_terminate( vector< string > &a_commands ){

		command_blocks.push_back( 0 );		//	Terminate Command
		total_size = stoi( a_commands[ 1 ], nullptr, 0 );

		stringstream ss;
		ss << "Terminate";
		if( total_size > 0 ){
			ss << " (Total size = " << total_size << "KB)";
		}
		log.push_back( ss.str() );
	}

	// --------------------------------------------------------------------
	//	a_command[0] = "ROM_IMAGE"
	//	a_command[1] = rom image file name
	//	a_command[2] = start ESERAM bank ID (option)
	//
	//	指定の ROM image file を、指定の ESERAMバンク以降に転送する設定。
	//	[2] を省略すると､前回の続きになるようにこのツールでID計算する。
	//
	void add_rom_image( vector< string > &a_commands ){
		ifstream rom_image( a_commands[ 1 ], ios::binary | ios::ate );
		if( !rom_image ){
			cerr << "[ERROR!] Cannot open " << a_commands[ 1 ] << endl;
			return;
		}
		unsigned int rom_image_size = (unsigned int) rom_image.tellg();
		rom_image.seekg( 0, fstream::beg );
		if( rom_image_size > ( 16384 * 256 ) ){
			cerr << "[ERROR!] Rom image file '" << a_commands[ 1 ] << "' is too big." << endl;
			return;
		}
		unsigned int blocks = (rom_image_size + 16383) / 16384;			//	中途半端なサイズの場合もあるので、端数は繰り上げ。足りない分は FF詰め。

		if( a_commands.size() > 2 ){
			current_eseram_bank = stoi( a_commands[ 2 ], nullptr, 0 );
		}
		char rom_buffer[ 16384 ];
		for( unsigned int i = 0; i < blocks; i++ ){
			memset( rom_buffer, 0xFF, sizeof( rom_buffer ) );
			rom_image.read( rom_buffer, sizeof( rom_buffer ) );
			for( int j = 0; j < sizeof( rom_buffer ); j++ ){
				rom_images.push_back( rom_buffer[ j ] );
			}
		}

		command_blocks.push_back( 1 );									//	Transfer BIOS image Command
		command_blocks.push_back( current_eseram_bank );				//	ESERAM Bank ID
		command_blocks.push_back( blocks );								//	Blocks

		stringstream ss;
		ss << "ROM image '" << a_commands[ 1 ] << "': " << rom_image_size << "bytes: " << blocks << "blocks: ESERAM Bank ID #" << current_eseram_bank << ".";
		log.push_back( ss.str() );
		current_eseram_bank = ((current_eseram_bank + (blocks * (16 / 8))) & 255) | 128;	//	ESERAM Bank size is 8KB. Block unit size is 16KB.
	}

	// --------------------------------------------------------------------
	//	a_command[0] = "CHANGE_ESERAM_MEMORY"
	//	a_command[1] = ESERAM memory ID
	//
	//	ESERAM全体を SDRAM のどこに割り当てるか変更する
	//
	void add_change_eseram_memory( vector< string > &a_commands ){
		unsigned char memory_id = 0;

		memory_id = stoi( a_commands[ 1 ], nullptr, 0 ) & 255;
		command_blocks.push_back( 2 );				//	Change ESE-RAM memory ID
		command_blocks.push_back( memory_id );		//	address

		stringstream ss;
		ss << "Change ESE-RAM memory ID to " << (unsigned int)memory_id;
		log.push_back( ss.str() );
	}

	// --------------------------------------------------------------------
	//	a_command[0] = "OUTPORT"
	//	a_command[1] = Port Address (0-255)
	//	a_command[2] = Write Data (0-255)
	//
	//	指定のI/Oポートに指定の値を書き込む
	//
	void add_outport( vector< string > &a_commands ){
		tuple< int, int > outport_image;
		outport_image = get_outport( a_commands );

		command_blocks.push_back( 3 );		//	Write I/O Port Command
		command_blocks.push_back( get<0>( outport_image ) & 255 );		//	address
		command_blocks.push_back( get<1>( outport_image ) & 255 );		//	data

		stringstream ss;
		ss << "OUTPORT 0x" << hex << ( get<0>( outport_image ) & 255 ) << ", 0x" << hex << ( get<1>( outport_image ) & 255 );
		log.push_back( ss.str() );
	}

	// --------------------------------------------------------------------
	//	a_command[0] = "MESSAGE"
	//	a_command[1] = char (0-255)
	//	a_command[2] = char (0-255)
	//		:
	//		:
	//
	//	0 で終わる文字列を表示する
	//
	void add_message( vector< string > &a_commands ){
		string s_line;

		if( a_commands.size() > 1 ){
			s_line = a_commands[ 1 ];
		}
		else{
			s_line = "";
		}

		command_blocks.push_back( 4 );			//	Message Command

		for( const char c : s_line ){
			command_blocks.push_back( c );		//	Message
		}
		command_blocks.push_back( 0 );			//	Message

		stringstream ss;
		ss << "MESSAGE \"" << a_commands[1] << "\"";
		log.push_back( ss.str() );
	}

	// --------------------------------------------------------------------
	//	a_command[0] = "FILL_DUMMY"
	//	a_command[1] = number of fill blocks
	//	a_command[2] = start ESERAM bank ID (option)
	//
	//	指定の ROM image file を、指定の ESERAMバンク以降に転送する設定。
	//	[2] を省略すると､前回の続きになるようにこのツールでID計算する。
	//
	void add_fill_dummy( vector< string > &a_commands ){
		unsigned int blocks = stoi( a_commands[ 1 ], nullptr, 0 );

		if( a_commands.size() > 2 ){
			current_eseram_bank = stoi( a_commands[ 2 ], nullptr, 0 );
		}

		command_blocks.push_back( 5 );									//	Transfer BIOS image Command
		command_blocks.push_back( current_eseram_bank );				//	ESERAM Bank ID
		command_blocks.push_back( blocks );								//	Blocks

		stringstream ss;
		ss << "Fill dummy " << blocks << "blocks: ESERAM Bank ID #" << current_eseram_bank << ".";
		log.push_back( ss.str() );
		current_eseram_bank = ( ( current_eseram_bank + ( blocks * ( 16 / 8 ) ) ) & 255 ) | 128;	//	ESERAM Bank size is 8KB. Block unit size is 16KB.
	}

	// --------------------------------------------------------------------
	void write( ofstream &file ){
		char s_buffer[ 512 ];

		if( ( command_blocks.size() + 5 ) > 512 ){
			cerr << "[ERROR!] Command block size is over." << endl;
			return;
		}
		memset( s_buffer, 0x00, sizeof( s_buffer ) );
		memcpy( s_buffer, "OCMB", 4 );
		s_buffer[ 4 ] = flag;
		if( command_blocks.size() ){
			memcpy( s_buffer + 5, &command_blocks[ 0 ], command_blocks.size() );
		}
		file.write( s_buffer, sizeof( s_buffer ) );
		if( rom_images.size() ){
			file.write( (char *)&rom_images[ 0 ], rom_images.size() );
		}
		
		int remain_padding = total_size * 1024 - ( sizeof( s_buffer ) + rom_images.size() );
		if( remain_padding > 0 ){
			memset( s_buffer, 0xFF, sizeof( s_buffer ) );
			while( remain_padding > 0 ){
				if( remain_padding > 512 ){
					file.write( s_buffer, 512 );
					remain_padding -= 512;
				}
				else{
					file.write( s_buffer, remain_padding );
					remain_padding = 0;
				}
			}
		}

		if( (flag & 1) == 0 ){
			cout << "Display mode: ON" << endl;
		}
		else{
			cout << "Display mode: OFF" << endl;
		}
		if( ( flag & 2 ) == 0 ){
			cout << "Monitor mode: NTSC" << endl;
		}
		else{
			cout << "Monitor mode: PAL" << endl;
		}
		for( string s_line: log ){
			cout << s_line << endl;
		}
	}
};

// --------------------------------------------------------------------
static void usage( const char *p_name ){
	cout << "Usage> " << p_name << " <config.txt> <bios_image.bin>" << endl;
}

// --------------------------------------------------------------------
static void skip_white_space( string &s_line ){
	while( isspace( s_line[ 0 ] & 255 ) ){
		s_line = s_line.substr( 1 );
	}
}

// --------------------------------------------------------------------
static string get_word( string &s_line ){
	string s_word;

	skip_white_space( s_line );
	if( ( s_line.length() > 0 ) && ( s_line[ 0 ] == '"' ) ){
		//	文字列の場合。※面倒なのでSJISには対応してません。2byte目が " と同じコードの文字が含まれてると途中で切れます。
		s_line = s_line.substr( 1 );
		while( ( s_line.length() > 0 ) && (s_line[0] != '"') ){
			s_word = s_word + s_line[ 0 ];
			s_line = s_line.substr( 1 );
		}
		if( ( s_line.length() > 0 ) && ( s_line[ 0 ] == '"' ) ){
			s_line = s_line.substr( 1 );
		}
	}
	else{
		//	コマンド名、数値の場合。
		while( ( s_line.length() > 0 ) && ( isalpha( s_line[ 0 ] & 255 ) || isdigit( s_line[ 0 ] & 255 ) || ( s_line[ 0 ] == '_' ) ) ){
			s_word = s_word + (char)toupper( s_line[ 0 ] & 255 );
			s_line = s_line.substr( 1 );
		}
	}
	return s_word;
}

// --------------------------------------------------------------------
static bool parse_line( string s_line, vector< string > &a_commands, int line_no ){
	string s_command;
	string s_parameter;

	a_commands.clear();
	if( s_line.length() == 0 ){
		return true;				//	空行
	}
	s_command = get_word( s_line );
	if( s_command == "" ){
		if( s_line.length() > 0 && s_line[ 0 ] == ';' ){
			return true;			//	コメント行
		}
		cerr << "[ERROR!] Cannot find command string." << endl;
		return false;				//	error
	}
	skip_white_space( s_line );
	if( s_line.length() == 0 || s_line[ 0 ] != '=' ){
		cerr << "[ERROR!] Cannot find '='." << endl;
		return false;				//	error
	}

	a_commands.push_back( s_command );

	for(;;){
		s_line = s_line.substr( 1 );
		s_parameter = get_word( s_line );
		a_commands.push_back( s_parameter );
		skip_white_space( s_line );
		if( s_line.length() == 0 || s_line[ 0 ] != ',' ){
			break;
		}
	}
	return true;
}

// --------------------------------------------------------------------
static int bios_image_maker( const char *p_input_name, const char *p_output_name ){
	C_BIOS_IMAGE bios_image;
	string s_line;
	ifstream input_file( p_input_name );
	vector< string > a_commands;
	int line_no = 0;

	if( !input_file ){
		cerr << "[ERROR!] Cannot open " << p_input_name << endl;
		return 1;
	}
	for(;;){
		getline( input_file, s_line );
		line_no++;
		if( input_file.eof() ){
			break;
		}
		if( !parse_line( s_line, a_commands, line_no ) ){
			break;		//	error
		}
		if( a_commands.size() == 0 ){
			continue;	//	空行、コメント行
		}
		if( a_commands[ 0 ] == "DISPLAY_MESSAGE" ){
			bios_image.set_display_message( a_commands );
		}
		else if( a_commands[ 0 ] == "MONITOR_TYPE" ) {
			bios_image.set_pal_mode( a_commands );
		}
		else if( a_commands[ 0 ] == "TERMINATE" ){
			bios_image.add_terminate( a_commands );
		}
		else if( a_commands[ 0 ] == "ROM_IMAGE" ){
			bios_image.add_rom_image( a_commands );
		}
		else if( a_commands[ 0 ] == "CHANGE_ESERAM_MEMORY" ){
			bios_image.add_change_eseram_memory( a_commands );
		}
		else if( a_commands[ 0 ] == "OUTPORT" ){
			bios_image.add_outport( a_commands );
		}
		else if( a_commands[ 0 ] == "MESSAGE" ){
			bios_image.add_message( a_commands );
		}
		else if( a_commands[ 0 ] == "FILL_DUMMY" ){
			bios_image.add_fill_dummy( a_commands );
		}
	}
	ofstream output_file( p_output_name, ios::binary );
	if( !output_file ){
		cerr << "[ERROR!] Cannot create the file '" << p_output_name << "'." << endl;
		return 1;
	}
	bios_image.write( output_file );
	return 0;
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ) {
	cout << "OCM BIOS Image Maker for OCM IPL-ROM ver.4" << endl;
	cout << "=========================================================" << endl;
	cout << "(C)2020 t.hara" << endl;

	if( argc < 3 ){
		usage( argv[ 0 ] );
		return 1;
	}
	return bios_image_maker( argv[ 1 ], argv[ 2 ] );
}
