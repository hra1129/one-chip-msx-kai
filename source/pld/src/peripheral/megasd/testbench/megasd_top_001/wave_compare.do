onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb/u_megasd/req
add wave -noupdate -radix hexadecimal /tb/u_megasd/wrt
add wave -noupdate /tb/u_megasd/w_req
add wave -noupdate /tb/u_megasd/w_wrt
add wave -noupdate -radix hexadecimal /tb/u_megasd/adr
add wave -noupdate -radix hexadecimal /tb/u_megasd/dbo
add wave -noupdate -radix hexadecimal /tb/ramreq
add wave -noupdate -radix hexadecimal /tb/ramreq_org
add wave -noupdate -radix hexadecimal /tb/ramwrt
add wave -noupdate -radix hexadecimal /tb/ramwrt_org
add wave -noupdate -radix hexadecimal /tb/ramadr
add wave -noupdate -radix hexadecimal /tb/ramadr_org
add wave -noupdate -radix hexadecimal /tb/mmcdbi
add wave -noupdate -radix hexadecimal /tb/mmcdbi_org
add wave -noupdate -radix hexadecimal /tb/mmcena
add wave -noupdate -radix hexadecimal /tb/mmcena_org
add wave -noupdate -radix hexadecimal /tb/mmcact
add wave -noupdate -radix hexadecimal /tb/mmcact_org
add wave -noupdate /tb/u_megasd/ff_data_active
add wave -noupdate /tb/u_megasd/w_clk_enable
add wave -noupdate -radix hexadecimal /tb/mmc_ck
add wave -noupdate -radix hexadecimal /tb/mmc_ck_org
add wave -noupdate -radix hexadecimal /tb/mmc_cs
add wave -noupdate -radix hexadecimal /tb/mmc_cs_org
add wave -noupdate -radix hexadecimal /tb/mmc_di
add wave -noupdate -radix hexadecimal /tb/mmc_di_org
add wave -noupdate -radix unsigned /tb/u_megasd/ff_data_seq
add wave -noupdate -radix hexadecimal /tb/mmc_do
add wave -noupdate -radix hexadecimal /tb/epc_ck
add wave -noupdate -radix hexadecimal /tb/epc_ck_org
add wave -noupdate -radix hexadecimal /tb/epc_cs
add wave -noupdate -radix hexadecimal /tb/epc_cs_org
add wave -noupdate -radix hexadecimal /tb/epc_oe
add wave -noupdate -radix hexadecimal /tb/epc_oe_org
add wave -noupdate -radix hexadecimal /tb/epc_di
add wave -noupdate -radix hexadecimal /tb/epc_di_org
add wave -noupdate -radix hexadecimal /tb/epc_do
add wave -noupdate /tb/u_megasd/ff_low_speed_mode
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {32234570056 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 223
configure wave -valuecolwidth 60
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {32253846852 ps} {32287060708 ps}
