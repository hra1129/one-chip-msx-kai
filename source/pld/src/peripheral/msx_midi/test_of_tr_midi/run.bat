vlib work
vlog ../../i8251/*.v
vlog ../../i8253/*.v
vlog ../tr_midi.v
vlog tb.sv
pause "[Please check error(s)]"
vsim -c -t 1ps -do run.do tb
move transcript log.txt
