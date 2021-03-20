vlib work
vcom ram.vhd
vcom ../vdp_spinforam.vhd
vcom vdp_sprite_old.vhd
vlog ../vdp_sprite_line_buffer.v
vlog ../vdp_sprite.v
vlog tb.sv
pause
vsim -c -t 1ps -do run.do tb
move transcript log.txt
