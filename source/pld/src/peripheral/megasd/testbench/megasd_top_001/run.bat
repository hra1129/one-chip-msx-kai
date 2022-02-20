vlib work
vlog ..\..\megasd.v
vcom .\megasd_org.vhd
vlog tb.sv
pause "[Please check error(s)]"
vsim -c -t 1ps -do run.do tb
move transcript log.txt
pause
