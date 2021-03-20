vlib work
vlog ../emsx_sdram_controller.v
vlog tb.sv
pause "[Please check error(s)]"

vsim -c -t 1ps -do run.do tb
move transcript log.txt
