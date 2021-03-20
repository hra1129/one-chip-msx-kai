// --------------------------------------------------------------------
//	ROM Disk Creator
// ====================================================================
//	2020/07/01	t.hara
// --------------------------------------------------------------------

#include <cstdio>
#include <vector>
#include <string>
#include <cstring>
#include <cctype>
#include <ctime>
#include <algorithm>
#include <sys/stat.h>
#include "boot_sector.h"

using namespace std;

static tm now_time_tm;

// --------------------------------------------------------------------
class c_rom_disk_image{
private:
	vector<uint8_t>		image;
	const unsigned int	cluster_size = BPB_SecPerClus * BPB_BytePerSec;
	unsigned int current_cluster;
	unsigned int fat_size;

public:
	// --------------------------------------------------------------------
	unsigned int size( void ) const {
		return image.size();
	}

	// --------------------------------------------------------------------
	unsigned int get_fat_size( void ) const{
		return fat_size;
	}

	// --------------------------------------------------------------------
	uint8_t *data( void ){
		return image.data();
	}

	// --------------------------------------------------------------------
	c_rom_disk_image(){
		image.resize( BPB_TotSec16 * BPB_BytePerSec );
		memcpy( image.data(), boot_sector_image, BPB_BytePerSec );
		image[ BPB_BytePerSec + 0 ] = 0xFF;
		image[ BPB_BytePerSec + 1 ] = 0xFF;
		image[ BPB_BytePerSec + 2 ] = 0xFF;
		current_cluster = 2;
		fat_size = BPB_FATSz16 / 2;		//	“ä‚Ì / 2BŠ®‘S‚É‚Â‚¶‚Â‚Ü‡‚í‚¹B
		if( fat_size > ( (BPB_TotSec16 - 2) * 12 / ( BPB_BytePerSec * BPB_SecPerClus * 8) ) ){
			fat_size = (BPB_TotSec16 - 2) * 12 / ( BPB_BytePerSec * BPB_SecPerClus * 8 );
		}
	}

	// --------------------------------------------------------------------
	unsigned int get_current_cluster( void ) const{
		return current_cluster;
	}

	// --------------------------------------------------------------------
	void set_current_cluster( unsigned int cluster ) {
		current_cluster = cluster;
	}

	// --------------------------------------------------------------------
	unsigned int convert_bytes_to_clusters( unsigned int bytes ){
		return( ( bytes + cluster_size - 1 ) / cluster_size );
	}

	// --------------------------------------------------------------------
	void write_cluster( const vector<uint8_t> &file_image, unsigned int &offset_address, unsigned int cluster_id, uint8_t padding ){
		unsigned int i;
		unsigned int base_offset = ( ( ( BPB_RootEntCnt * 32 + ( BPB_BytePerSec - 1 ) ) / BPB_BytePerSec ) + fat_size ) * BPB_BytePerSec;
		cluster_id -= 2;
		for( i = 0; i < ( BPB_SecPerClus * BPB_BytePerSec ); i++ ){
			if( ( offset_address + i ) < file_image.size() ){
				image[ base_offset + cluster_id * BPB_SecPerClus * BPB_BytePerSec + i ] = file_image[ offset_address + i ];
			}
			else{
				image[ base_offset + cluster_id * BPB_SecPerClus * BPB_BytePerSec + i ] = padding;
			}
		}
		offset_address += BPB_SecPerClus * BPB_BytePerSec;
	}

	// --------------------------------------------------------------------
	void update_next_cluster( unsigned int cluster_id, unsigned int next_cluster_id ){
		unsigned int address;

		address = ( cluster_id * 12 ) / 8 + BPB_BytePerSec;
		if( (cluster_id & 1) == 0 ) {
			image[ address + 0 ] = next_cluster_id & 255;
			image[ address + 1 ] = ( image[ address + 1 ] & 0xF0 ) | ( ( next_cluster_id >> 8 ) & 0x0F );
		}
		else{
			image[ address + 0 ] = ( image[ address + 0 ] & 0x0F ) | ( ( next_cluster_id << 4 ) & 0xF0 );
			image[ address + 1 ] = ( next_cluster_id >> 4 ) & 255;
		}
	}

	// --------------------------------------------------------------------
	void write_file_image_with_position( const vector<uint8_t> &file_image, unsigned int offset, uint8_t padding = 0xFF ){
		unsigned int i;

		for( i = 0; i < file_image.size(); i++ ){
			image[ offset++ ] = file_image[ i ];
		}
		i = i % BPB_BytePerSec;
		if( i ){
			for( ; i < BPB_BytePerSec; i++ ){
				image[ offset++ ] = padding;
			}
		}
	}

	// --------------------------------------------------------------------
	unsigned int write_file_image( const vector<uint8_t> &file_image, unsigned int cluster, uint8_t padding = 0xFF ){
		unsigned int i;
		unsigned int max_cluster = BPB_TotSec16 / BPB_SecPerClus;
		bool is_final_cluster;
		if( ( fat_size * BPB_BytePerSec * BPB_SecPerClus * 8 / 12 ) < max_cluster ){
			max_cluster = fat_size * BPB_BytePerSec * BPB_SecPerClus * 8 / 12;
		}
		i = 0;
		while( cluster < max_cluster ){
			is_final_cluster = ( ( file_image.size() - i ) < ( BPB_BytePerSec * BPB_SecPerClus ) );
			write_cluster( file_image, i, cluster, padding );
			if( is_final_cluster ){
				update_next_cluster( cluster, 0xFFF );
			}
			else{
				update_next_cluster( cluster, cluster + 1 );
			}
			cluster++;
			if( i >= file_image.size() ){
				break;
			}
		}
		return cluster;
	}

	// --------------------------------------------------------------------
	void save( FILE *p_file ){
		fwrite( image.data(), image.size(), 1, p_file );
	}
};

// --------------------------------------------------------------------
enum class c_entry_type: uint16_t {
	ENTRY_TYPE_VOLUME_LABEL = 0x28,
	ENTRY_TYPE_FILE = 0x00,
	ENTRY_TYPE_DIRECTORY = 0x10,
	ENTRY_TYPE_ROOT_DIRECTORY = 0xFF,
	ENTRY_TYPE_THIS_DIRECTORY = ENTRY_TYPE_DIRECTORY | 0x0100,
	ENTRY_TYPE_PARENT_DIRECTORY = ENTRY_TYPE_DIRECTORY | 0x0200,
};

// --------------------------------------------------------------------
class c_file_entry {
private:
	string					s_name;
	c_entry_type			entry_type;
	unsigned int			file_size;
	unsigned int			cluster;
public:
	tm						atime;
	tm						ctime;
	tm						mtime;

	// --------------------------------------------------------------------
	c_file_entry(){
		s_name = "";
		entry_type = c_entry_type::ENTRY_TYPE_FILE;
		file_size = 0;
		cluster = 0;
	}

	// --------------------------------------------------------------------
	void set_current_time( void ) const{
		memcpy( (void *)&atime, &now_time_tm, sizeof( tm ) );
		memcpy( (void *)&ctime, &now_time_tm, sizeof( tm ) );
		memcpy( (void *)&mtime, &now_time_tm, sizeof( tm ) );
	}

	// --------------------------------------------------------------------
	unsigned int get_cluster( void ) const{
		return cluster;
	}

	// --------------------------------------------------------------------
	void set_cluster( unsigned int c ){
		cluster = c;
	}

	// --------------------------------------------------------------------
	unsigned int get_file_size( void ) const{
		return file_size;
	}

	// --------------------------------------------------------------------
	void set_file_size( unsigned int s ){
		file_size = s;
	}

	// --------------------------------------------------------------------
	bool check_name( const string &s_name ){
		const char *p = s_name.c_str();
		int len = 0, ext_len = 0;

		for( ;; ){
			if( *p == '\0' ){
				break;
			}
			if( strchr( "\\/:*?<>|", *p ) != NULL ){
				return false;
			}
			if( *p == '.' ){
				p++;
				break;
			}
			len++;
			p++;
		}
		for( ;; ){
			if( *p == '\0' ){
				break;
			}
			if( strchr( "\\/:*?<>|.", *p ) != NULL ){
				return false;
			}
			ext_len++;
			p++;
		}
		if( len == 0 || len > 8 || ext_len > 3 ){
			return false;
		}
		return true;
	}

	bool set_name( const string &s_name ){
		if( !check_name( s_name ) ){
			return false;
		}
		this->s_name = s_name;
		return true;
	}

	const string &get_name( void ) const {
		return s_name;
	}

	void set_entry_type( c_entry_type type_id ){
		this->entry_type = type_id;
	}

	c_entry_type get_entry_type( void ) const {
		return entry_type;
	}

	// --------------------------------------------------------------------
	void makeup_name( vector<uint8_t> &directory_entry ){
		unsigned int i, j;
		const char s_this_directory[] = ".          ";
		const char s_parent_directory[] = "..         ";

		if( entry_type == c_entry_type::ENTRY_TYPE_THIS_DIRECTORY ){
			memcpy( directory_entry.data(), s_this_directory, 8 + 3 );
			return;
		}
		if( entry_type == c_entry_type::ENTRY_TYPE_PARENT_DIRECTORY ){
			memcpy( directory_entry.data(), s_parent_directory, 8 + 3 );
			return;
		}
		for( i = 0; i < 8; i++ ){
			if( s_name.size() <= i || s_name[ i ] == '.' ){
				break;
			}
			directory_entry[ i ] = s_name[ i ];
		}
		for( j = i; j < 8; j++ ){
			directory_entry[ j ] = ' ';
		}
		if( s_name[ i ] == '.' ){
			i++;
		}
		for( j = 8; j < 11; j++ ){
			if( s_name.size() <= i ){
				for( ; j < 11; j++ ){
					directory_entry[ j ] = ' ';
				}
				break;
			}
			directory_entry[ j ] = s_name[ i ];
			i++;
		}
		if( directory_entry[ 0 ] == 0xE5 ){
			directory_entry[ 0 ] = 0x05;
		}
	}

	// --------------------------------------------------------------------
	vector<uint8_t> get_directory_entry( void ){
		vector<uint8_t> image;
		image.resize( 32 );
		uint16_t cd, ct, ud, ut;

		ct = ( ( ctime.tm_sec >> 1 ) % 30 ) | ( ctime.tm_min << 5 ) | ( ctime.tm_hour << 11 );
		cd = ( ( ctime.tm_mday & 31 ) | (( ctime.tm_mon + 1 ) << 5) | (( ctime.tm_year + 1900 - 1980 ) << 9) );
		ut = ( ( mtime.tm_sec >> 1 ) % 30 ) | ( mtime.tm_min << 5 ) | ( mtime.tm_hour << 11 );
		ud = ( ( mtime.tm_mday & 31 ) | (( mtime.tm_mon + 1 ) << 5) | (( mtime.tm_year + 1900 - 1980 ) << 9) );

		makeup_name( image );
		image[ 11 ] = (uint8_t)get_entry_type();
		image[ 12 ] = 0;		//	not support.
		image[ 13 ] = 0;		//	not support.	
		image[ 14 ] = ct & 255;	//	create time
		image[ 15 ] = ct >> 8;
		image[ 16 ] = cd & 255;	//	create data
		image[ 17 ] = cd >> 8;
		image[ 18 ] = 0;		//	last open data
		image[ 19 ] = 0;
		image[ 20 ] = 0;		//	always 0
		image[ 21 ] = 0;		//	always 0
		image[ 22 ] = ut & 255;	//	update time
		image[ 23 ] = ut >> 8;
		image[ 24 ] = ud & 255;	//	update date
		image[ 25 ] = ud >> 8;
		image[ 26 ] = cluster & 255;
		image[ 27 ] = ( cluster >> 8 ) & 255;
		image[ 28 ] = file_size & 255;
		image[ 29 ] = ( file_size >> 8 ) & 255;
		image[ 30 ] = ( file_size >> 16 ) & 255;
		image[ 31 ] = ( file_size >> 24 ) & 255;
		return image;
	}

	// --------------------------------------------------------------------
	virtual void write_image( c_rom_disk_image &image, unsigned int cluster ) = 0;
};

// --------------------------------------------------------------------
class c_volume_label: public c_file_entry{
private:
	string		s_volume_label;
public:

	// --------------------------------------------------------------------
	bool set_volume_label( const string &s_name ){
		if( !check_name( s_name ) ){
			return false;
		}
		s_volume_label = s_name;
		return true;
	}

	// --------------------------------------------------------------------
	const string &get_volume_label( void ) const{
		return s_volume_label;
	}

	// --------------------------------------------------------------------
	void write_image( c_rom_disk_image &image, unsigned int cluster ){
	}
};

// --------------------------------------------------------------------
class c_file: public c_file_entry{
public:
	vector<uint8_t>			file_image;

	// --------------------------------------------------------------------
	bool get_file_image( const string &s_source ){
		FILE *p_file;
		struct stat file_state;

		memset( &file_state, 0, sizeof( file_state ) );
		p_file = fopen( s_source.c_str(), "rb" );
		if( p_file == NULL ){
			return false;
		}
		stat( s_source.c_str(), &file_state );
		set_file_size( (unsigned int) file_state.st_size );
		memcpy( &atime, localtime( &(file_state.st_atime) ), sizeof( tm ) );
		memcpy( &ctime, localtime( &(file_state.st_ctime) ), sizeof( tm ) );
		memcpy( &mtime, localtime( &(file_state.st_mtime) ), sizeof( tm ) );
		file_image.resize( get_file_size() );
		fread( file_image.data(), get_file_size(), 1, p_file );
		fclose( p_file );
		return true;
	}

	// --------------------------------------------------------------------
	void write_image( c_rom_disk_image &image, unsigned int cluster ){
		set_cluster( image.get_current_cluster() );
		image.set_current_cluster( image.write_file_image( file_image, get_cluster() ) );
	}
};

// --------------------------------------------------------------------
class c_directory: public c_file_entry{
public:
	vector<uint8_t>			file_image;
	vector<c_file_entry*>	entry;
	bool					has_volume_label;

	// --------------------------------------------------------------------
	c_directory(){
		entry.clear();
		set_file_size( 0 );
		has_volume_label = false;
	}

	// --------------------------------------------------------------------
	string get_directory_name( const string &s_file_path, string &s_name ){
		const char *p = s_file_path.c_str();
		string p_path = "";

		s_name = "";
		while( *p != '\0' ){
			if( *p == '/' || *p == '\\' ){
				p++;
				s_name = p;
				return p_path;
			}
			p_path = p_path + *p;
			p++;
		}
		p_path = "";
		return p_path;
	}

	// --------------------------------------------------------------------
	c_file_entry *search_target_name( const string &s_target_name ){

		for( auto &entry_item : entry ){
			if( entry_item->get_name() == s_target_name ){
				return entry_item;
			}
		}
		return nullptr;
	}

	// --------------------------------------------------------------------
	void set_volume_label( const string &s_name, int line_no ){
		if( get_entry_type() != c_entry_type::ENTRY_TYPE_ROOT_DIRECTORY ){
			fprintf( stderr, "ERROR: Line(%d): This is not root directory.", line_no );
			return;
		}
		if( has_volume_label ){
			fprintf( stderr, "ERROR: Line(%d): Multiple volume labels are specified..", line_no );
			return;
		}
		c_volume_label *p_label = new c_volume_label;
		if( !p_label->set_volume_label( s_name ) ){
			fprintf( stderr, "ERROR: Line(%d): Invalid volume label '%s'.", line_no, s_name.c_str() );
			return;
		}
		p_label->set_entry_type( c_entry_type::ENTRY_TYPE_VOLUME_LABEL );
		p_label->set_name( s_name );
		entry.push_back( p_label );
		has_volume_label = true;
		printf( "  LABEL: '%s'\n", s_name.c_str() );
	}

	// --------------------------------------------------------------------
	void append_parent_directory( void ){
		c_directory *p_this_directory, *p_parent_directory;
		p_this_directory = new c_directory;
		p_parent_directory = new c_directory;
		p_this_directory->set_entry_type( c_entry_type::ENTRY_TYPE_THIS_DIRECTORY );
		p_parent_directory->set_entry_type( c_entry_type::ENTRY_TYPE_PARENT_DIRECTORY );
		p_this_directory->set_current_time();
		p_parent_directory->set_current_time();
		entry.push_back( p_this_directory );
		entry.push_back( p_parent_directory );
	}
	// --------------------------------------------------------------------
	void append( const string &s_source, const string &s_destination, int line_no ){
		string s_path, s_name;
		s_path = get_directory_name( s_destination, s_name );
		if( s_path == "" ){
			// s_destination is file name.
			c_file *p_target_file;
			if( search_target_name( s_destination ) != nullptr ){
				fprintf( stderr, "ERROR: Line(%d): There are multiple files '%s'.\n", line_no, s_destination.c_str() );
				return;
			}
			p_target_file = new c_file;
			if( !p_target_file->set_name( s_destination ) ){
				fprintf( stderr, "ERROR: Line(%d): Invalid file name '%s'.\n", line_no, s_destination.c_str() );
				return;
			}
			p_target_file->set_entry_type( c_entry_type::ENTRY_TYPE_FILE );
			entry.push_back( p_target_file );
			p_target_file->get_file_image( s_source );
			printf( "  ADD: %s (%dbytes)\n", s_destination.c_str(), p_target_file->get_file_size() );
			return;
		}
		// s_destination has directory name.
		c_file_entry *p_entry = search_target_name( s_path );
		if( p_entry == nullptr ){
			c_directory *p_target_directory;
			p_target_directory = new c_directory;
			if( !p_target_directory->set_name( s_path ) ){
				fprintf( stderr, "ERROR: Line(%d): Invalid directory name '%s'.\n", line_no, s_path.c_str() );
				return;
			}
			p_target_directory->set_entry_type( c_entry_type::ENTRY_TYPE_DIRECTORY );
			p_target_directory->set_current_time();
			p_target_directory->append_parent_directory();
			entry.push_back( p_target_directory );
			printf( "  MKDIR: %s\n", s_path.c_str() );
		}
		p_entry = search_target_name( s_path );
		if( p_entry->get_entry_type() != c_entry_type::ENTRY_TYPE_DIRECTORY ) {
			fprintf( stderr, "ERROR: Line(%d): Illegal path specification.\n", line_no );
			return;
		}
		c_directory *p_directory = reinterpret_cast<c_directory *>( p_entry );
		p_directory->append( s_source, s_name, line_no );
	}

	// --------------------------------------------------------------------
	void write_image( c_rom_disk_image &image, unsigned int parent_cluster ){
		int i, current_entry;

		file_image.resize( entry.size() * 32 );
		current_entry = 0;
		if( get_entry_type() == c_entry_type::ENTRY_TYPE_ROOT_DIRECTORY ){
			set_cluster( 0 );
		}
		else{
			set_cluster( image.get_current_cluster() );
			image.set_current_cluster( image.get_current_cluster() + ( file_image.size() + ( BPB_BytePerSec * BPB_SecPerClus - 1 ) ) / ( BPB_BytePerSec * BPB_SecPerClus ) );
		}
		for( auto &p_file_entry : entry ){
			if( p_file_entry->get_entry_type() == c_entry_type::ENTRY_TYPE_THIS_DIRECTORY ){
				p_file_entry->set_cluster( get_cluster() );
			}
			else if( p_file_entry->get_entry_type() == c_entry_type::ENTRY_TYPE_PARENT_DIRECTORY ){
				p_file_entry->set_cluster( parent_cluster );
			}
			else{
				p_file_entry->write_image( image, get_cluster() );
			}
			vector<uint8_t> directory_entry = p_file_entry->get_directory_entry();
			for( i = 0; i < 32; i++ ){
				file_image[ current_entry++ ] = directory_entry[ i ];
			}
		}
		if( get_entry_type() != c_entry_type::ENTRY_TYPE_ROOT_DIRECTORY ){
			image.write_file_image( file_image, get_cluster(), 0x00 );
		}
		else{
			image.write_file_image_with_position( file_image, (BPB_RsvdSecCnt + image.get_fat_size() * BPB_NumFATs) * BPB_BytePerSec, 0x00 );
		}
	}
};

// --------------------------------------------------------------------
vector<string> split_string( const char *p_string ){
	vector<string> result;
	string s_word;
	int i = 0;

	while( isspace( p_string[ i ] ) ) {
		i++;
	}
	while( p_string[ i ] != '\0' ) {
		s_word = "";
		while( !isspace( p_string[ i ] ) && p_string[ i ] != '\0' ){
			s_word = s_word + p_string[ i ];
			i++;
		}
		while( isspace( p_string[ i ] ) ){
			i++;
		}
		result.push_back( s_word );
	}
	return result;
}

// --------------------------------------------------------------------
void rom_disk_creator( const char *p_image_txt_name, const char *p_output_name ){
	FILE *p_image_txt, *p_output;
	char s_buffer[ 2048 ];
	vector<string> line;
	string s_command;
	c_directory root_directory;
	c_rom_disk_image image;
	int line_no;
	time_t now_time;

	now_time = time( NULL );
	memcpy( &now_time_tm, localtime( &now_time ), sizeof( tm ) );

	p_image_txt = fopen( p_image_txt_name, "r" );
	if( p_image_txt == NULL ){
		fprintf( stderr, "ERROR: Cannot open the '%s'.\n", p_image_txt_name );
		return;
	}

	root_directory.set_current_time();
	root_directory.set_entry_type( c_entry_type::ENTRY_TYPE_ROOT_DIRECTORY );
	line_no = 0;
	for( ;; ){
		fgets( s_buffer, sizeof( s_buffer ), p_image_txt );
		if( feof( p_image_txt ) ){
			break;
		}
		line_no++;
		line = split_string( s_buffer );
		if( line.size() == 0 ){
			continue;
		}
		s_command = line[ 0 ];
		transform( s_command.begin(), s_command.end(), s_command.begin(), toupper );
		if( s_command == "REM" ){
			continue;
		}
		if( s_command == "LABEL" ){
			if( line.size() != 2 ){
				fprintf( stderr, "ERROR: Line(%d): The number of arguments in the LABEL instruction is incorrect.\n", line_no );
				continue;
			}
			root_directory.set_volume_label( line[1], line_no );
		}
		else if( s_command == "COPY" ){
			if( line.size() != 3 ){
				fprintf( stderr, "ERROR: Line(%d): The number of arguments in the COPY instruction is incorrect.\n", line_no );
				continue;
			}
			root_directory.append( line[1], line[2], line_no );
		}
		else{
			printf( "ERROR: Illegal command '%s'.", s_command.c_str() );
			break;
		}
	}
	fclose( p_image_txt );

	root_directory.write_image( image, 0 );
	p_output = fopen( p_output_name, "wb" );
	if( p_output == NULL ){
		fprintf( stderr, "ERROR: Cannot create the '%s'.\n", p_output_name );
		return;
	}
	fwrite( image.data(), image.size(), 1, p_output );
	fclose( p_output );
}
