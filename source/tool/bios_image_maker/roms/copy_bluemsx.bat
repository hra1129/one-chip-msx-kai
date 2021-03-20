@echo off
echo ****************************************************************************
echo * Copy the Shared ROM file from the BlueMSX installation folder.           *
echo ****************************************************************************

mkdir ".\BlueMsxRoms"
copy "C:\Program Files (x86)\blueMSX\Machines\Shared Roms\*.*" ".\BlueMsxRoms\"
pause
