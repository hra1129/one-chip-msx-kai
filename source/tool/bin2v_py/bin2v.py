#!/usr/bin/env python3
# coding=utf-8

import sys

# ------------------------------------------------
def usage( p_name ):
    print( "Usage> %s <input.bin> <output.v>" % p_name )

# ------------------------------------------------
def main():
	print( "bin2v" )
	print( "==========================================================" )
	print( "(C)2023 t.hara" )

	if( len(sys.argv) < 3 ):
		usage( sys.argv[0] )
		exit(1)

	with open( sys.argv[1], "rb" ) as ifile:
		datas = ifile.read()

	with open( sys.argv[2], "w" ) as ofile:
		address = 0
		for d in datas:
			ofile.write( "\t\t11'h%03x:\tff_dbi <= 8'h%02x;\n" % ( address, d ) )
			address = address + 1

if __name__ == "__main__":
	main()
