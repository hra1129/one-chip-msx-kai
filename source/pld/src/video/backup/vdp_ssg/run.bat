vlib work
vlog ../vdp_hvcounter.v
vlog ../vdp_ssg.v
vlog ./vdp_hvcounter_old.v
vcom ../vdp_package.vhd
vcom ./vdp_ssg.vhd
vlog tb.sv
pause "[Please check error(s)]"
vsim -c -t 1ps -do run.do tb
move transcript log.txt
