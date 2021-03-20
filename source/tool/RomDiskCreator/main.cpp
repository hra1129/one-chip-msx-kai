// --------------------------------------------------------------------
//	ROM Disk Creator
// ====================================================================
//	2020/07/01	t.hara
// --------------------------------------------------------------------

#include <cstdio>
#include "RomDiskCreator.h"

// --------------------------------------------------------------------
void usage( const char *p_name ) {

	printf( "Usage> %s <image.txt> <output.bin\n", p_name );
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ){
	printf( "RomDiskCreator v1.0.0\n" );
	printf( "==========================================================\n" );
	printf( "Programmed by t.hara\n" );

	if( argc != 3 ) {
		usage( argv[0] );
		return 1;
	}

	rom_disk_creator( argv[1], argv[2] );
	return 0;
}
