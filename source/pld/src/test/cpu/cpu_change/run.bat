vlib work
vcom ../../../cpu/t80_pack.vhd
vcom ../../../cpu/*.vhd
vlog ../../../peripheral/s1990/s1990.v
vlog tb.sv
vsim -c -t 1ps -do run.do tb
pause
