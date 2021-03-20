// --------------------------------------------------------------------
//  bin2v
// ====================================================================
//  2020/04/21  t.hara
// --------------------------------------------------------------------
#include <iostream>
#include <fstream>
#include <iomanip>

using namespace std;

// --------------------------------------------------------------------
static void usage( const char *p_name ){

	cout << "Usage>" << p_name << " <input.bin> <output.v>" << endl;
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ) {

	cout << "bin2v" << endl;
	cout << "==========================================================" << endl;
	cout << "(C)2020 t.hara" << endl;

	if( argc < 3 ){
		usage( argv[ 0 ] );
		return 1;
	}

	ifstream ifile( argv[ 1 ], ios::binary );
	if( !ifile ){
		cerr << "[ERROR!] Cannot open the '" << argv[ 1 ] << "'." << endl;
		return 1;
	}

	ofstream ofile( argv[ 2 ] );
	if( !ofile ){
		cerr << "[ERROR!] Cannot create the '" << argv[ 2 ] << "'." << endl;
		return 1;
	}

	char d;
	int address = 0;
	for( ;; ){
		ifile.read( &d, 1 );
		if( ifile.eof() ){
			break;
		}
		ofile << "\t\t11'h" << setfill( '0' ) << hex << setw( 3 ) << address << ":\tff_dbi <= 8'h" << setw( 2 ) << ( (int)d & 255 ) << ";" << endl;
		address++;
	}

	ofile.close();
	ifile.close();
}
