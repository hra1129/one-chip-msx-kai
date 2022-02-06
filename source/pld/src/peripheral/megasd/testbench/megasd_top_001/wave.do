onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb/u_megasd/clk21m
add wave -noupdate -radix hexadecimal /tb/u_megasd/reset
add wave -noupdate -radix hexadecimal /tb/u_megasd/req
add wave -noupdate -radix hexadecimal /tb/u_megasd/wrt
add wave -noupdate -radix hexadecimal /tb/u_megasd/adr
add wave -noupdate -radix hexadecimal /tb/u_megasd/dbo
add wave -noupdate -radix hexadecimal /tb/u_megasd/ramreq
add wave -noupdate -radix hexadecimal /tb/u_megasd/ramwrt
add wave -noupdate -radix hexadecimal /tb/u_megasd/ramadr
add wave -noupdate -radix hexadecimal /tb/u_megasd/ramdbo
add wave -noupdate -radix hexadecimal /tb/u_megasd/mmcdbi
add wave -noupdate -radix hexadecimal /tb/u_megasd/mmcena
add wave -noupdate -radix hexadecimal /tb/u_megasd/mmcact
add wave -noupdate -radix hexadecimal /tb/u_megasd/mmc_ck
add wave -noupdate -radix hexadecimal /tb/u_megasd/mmc_cs
add wave -noupdate -radix hexadecimal /tb/u_megasd/mmc_di
add wave -noupdate -radix hexadecimal /tb/u_megasd/mmc_do
add wave -noupdate -radix hexadecimal /tb/u_megasd/epc_ck
add wave -noupdate -radix hexadecimal /tb/u_megasd/epc_cs
add wave -noupdate -radix hexadecimal /tb/u_megasd/epc_oe
add wave -noupdate -radix hexadecimal /tb/u_megasd/epc_di
add wave -noupdate -radix hexadecimal /tb/u_megasd/epc_do
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_bank0
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_bank1
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_bank2
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_bank3
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_divider
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_10m
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_336k
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_clk_10m
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_clk_336k
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_clk
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_clk_enable
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_req
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_wrt
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_req
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_wrt
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_data_seq
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_data_active
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_data_send
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_data_dec
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_data_seq_stop
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_data
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_rcv_bit
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_data_lsb
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_low_speed_mode
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_data_en
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_epc_mode
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_mmc_cs
add wave -noupdate -radix hexadecimal /tb/u_megasd/ff_epc_cs
add wave -noupdate -radix hexadecimal /tb/u_megasd/w_is_mmc_bank
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {782735679 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 197
configure wave -valuecolwidth 40
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
WaveRestoreZoom {781735971 ps} {784986968 ps}
