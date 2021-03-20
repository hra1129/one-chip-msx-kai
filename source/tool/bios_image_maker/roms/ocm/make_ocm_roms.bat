ocm_bios_converter.exe

copy /B ocm_megasdhc_0.rom+ocm_megasdhc_1.rom+ocm_megasdhc_2.rom+ocm_megasdhc_3.rom ocm_megasdhc.rom
copy /B ocm_msx2_kanji_0.rom+ocm_msx2_kanji_1.rom+ocm_msx2_kanji_2.rom+ocm_msx2_kanji_3.rom+ocm_msx2_kanji_4.rom+ocm_msx2_kanji_5.rom+ocm_msx2_kanji_6.rom+ocm_msx2_kanji_7.rom ocm_msx2_kanji.rom
copy /B ocm_msx2_main_0.rom+ocm_msx2_main_1.rom ocm_msx2_main.rom

del ocm_megasdhc_?.rom
del ocm_msx2_kanji_?.rom
del ocm_msx2_main_?.rom
pause
