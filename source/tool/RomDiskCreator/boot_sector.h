// --------------------------------------------------------------------
//	RomDiskCreator
// ====================================================================
//	2020/07/02	t.hara
// --------------------------------------------------------------------

#pragma once

extern unsigned char boot_sector_image[];

static const unsigned int	BPB_BytePerSec	= 0x0200;	//	1[ sector ] = 512[ byte ]
static const unsigned int	BPB_SecPerClus	= 0x01;		//	1[ cluster ] = 1[ sector ]
static const unsigned int	BPB_RsvdSecCnt	= 0x0001;	//	1固定。予約領域のセク多数。
static const unsigned int	BPB_NumFATs		= 0x01;		//	FATは 1個のみ。
static const unsigned int	BPB_RootEntCnt	= 0x0020;	//	ルートディレクトリのエントリ数。32個。
static const unsigned int	BPB_TotSec16	= 0x0800;	//	総セクタ数。1049600[ byte ]のディスクの扱い。
static const unsigned int	BPB_Media		= 0xFF;		//	メディアID, 無意味な値？
static const unsigned int	BPB_FATSz16		= 0x0006;	//	FATは 6[ sector ] で構成。
static const unsigned int	BPB_SecPerTrk	= 0x0800;	//	1トラックのセクタ数。このディスクは 1トラック構成？
