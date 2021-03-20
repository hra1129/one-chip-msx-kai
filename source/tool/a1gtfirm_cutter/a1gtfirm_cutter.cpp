// --------------------------------------------------------------------
//	A1GTFIRM.ROM から必要な部分を切り出すツール
//	A tool to cut out the necessary parts from A1GTFIRM.ROM
// ====================================================================
//	Programmed by 2021 t.hara
// --------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>

unsigned char buffer[ 4 * 1024 * 1024 ];
char key_code = 'G';

// --------------------------------------------------------------------
static void read_firm_ware( void ){
	FILE *p_file;

	p_file = fopen( "A1GTFIRM.ROM", "rb" );
	key_code = 'G';
	if( p_file == NULL ){
		key_code = 'S';
		p_file = fopen( "A1STFIRM.ROM", "rb" );
		if( p_file == NULL ){
			printf( "ERROR: Cannot open the A1GTFIRM.ROM/A1STFIRM.ROM.\n" );
			exit( 1 );
		}
	}

	fread( buffer, sizeof( buffer ), 1, p_file );
	fclose( p_file );
}

// --------------------------------------------------------------------
static void save_firm_ware( const char *p_name, int start_bank, int bank_num ){
	FILE *p_file;

	p_file = fopen( p_name, "wb" );
	if( p_file == NULL ){
		printf( "ERROR: Cannot create the %s.\n", p_name );
		return;
	}

	fwrite( buffer + ( start_bank * 8192 ), 8192, bank_num, p_file );
	fclose( p_file );
	printf( "Saved '%s'\n", p_name );
}

// --------------------------------------------------------------------
static void write_firm_ware( void ){
	char s_name[ 32 ];

	sprintf( s_name, "A1%cTROM0.ROM", key_code );
	save_firm_ware( s_name, 0, 40 );

	sprintf( s_name, "A1%cTROM1.ROM", key_code );
	save_firm_ware( s_name, 44, 4 );

	sprintf( s_name, "A1%cTROM2.ROM", key_code );
	save_firm_ware( s_name, 64, 64 );

	sprintf( s_name, "A1%cTROM3.ROM", key_code );
	save_firm_ware( s_name, 160, 32 );

	sprintf( s_name, "A1%cTROM4.ROM", key_code );
	save_firm_ware( s_name, 256, 64 );
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ){

	printf( "A1GTFIRM.ROM Cutter\n" );
	printf( "==========================================================\n" );
	printf( "Programmed by HRA!\n" );

	read_firm_ware();
	write_firm_ware();
	printf( "Completed.\n" );
	return 0;
}
