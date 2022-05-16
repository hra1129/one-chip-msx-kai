vlib work
vcom ../../sram/ram.vhd
vcom ../keymap.vhd
vcom eseps2_original.vhd

vlog ../matrix_ram.v
vlog ../eseps2.v

vlog tb.sv

pause "[Please check error(s)]"
vsim -c -t 1ps -do run.do tb
move transcript log.txt
pause
