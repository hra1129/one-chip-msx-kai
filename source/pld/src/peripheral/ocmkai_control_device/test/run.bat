vlib work
vlog ../ocmkai_control_device.v
vlog tb.sv
pause "[Please check error(s)]"

vsim -c -t 1ps -do run.do tb
move transcript log.txt
