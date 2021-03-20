onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tb/test_item_index
add wave -noupdate -radix unsigned /tb/clk
add wave -noupdate -radix unsigned /tb/reset
add wave -noupdate -radix unsigned /tb/clk0_en
add wave -noupdate /tb/clk0
add wave -noupdate -radix unsigned /tb/gate0
add wave -noupdate -radix unsigned /tb/out0
add wave -noupdate -radix unsigned /tb/load_counter
add wave -noupdate -radix hexadecimal /tb/counter0
add wave -noupdate -radix unsigned /tb/start
add wave -noupdate -radix unsigned /tb/load_high
add wave -noupdate -radix unsigned /tb/load_low
add wave -noupdate -radix unsigned /tb/mode0
add wave -noupdate -radix unsigned /tb/mode1
add wave -noupdate -radix unsigned /tb/mode2
add wave -noupdate -radix unsigned /tb/mode3
add wave -noupdate -radix unsigned /tb/mode4
add wave -noupdate -radix unsigned /tb/mode5
add wave -noupdate -radix unsigned /tb/bcd
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 149
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ps} {1795 ps}
