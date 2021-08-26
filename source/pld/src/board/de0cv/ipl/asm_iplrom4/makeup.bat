..\..\..\..\..\..\tool\assembler\zma.exe ocm_iplrom4.asm ocm_iplrom4.bin
bin2v ocm_iplrom4.bin ocm_iplrom4_code.v 12
copy ocm_iplrom4_header.v+ocm_iplrom4_code.v+ocm_iplrom4_footer.v ..\ocm_iplrom4.v
pause
