onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tb/ff_line_no
add wave -noupdate -radix unsigned /tb/ff_test_state
add wave -noupdate /tb/u_eseps2/clk21m
add wave -noupdate /tb/u_eseps2/reset
add wave -noupdate /tb/u_eseps2/clkena
add wave -noupdate /tb/u_eseps2/Kmap
add wave -noupdate /tb/u_eseps2/Caps
add wave -noupdate /tb/u_eseps2/Kana
add wave -noupdate /tb/u_eseps2/Paus
add wave -noupdate /tb/u_eseps2/Scro
add wave -noupdate /tb/u_eseps2/Reso
add wave -noupdate /tb/u_eseps2/Fkeys
add wave -noupdate /tb/u_eseps2/pPs2Clk
add wave -noupdate /tb/u_eseps2/pPs2Dat
add wave -noupdate /tb/u_eseps2/PpiPortC
add wave -noupdate /tb/u_eseps2/pKeyX
add wave -noupdate /tb/u_eseps2/CmtScro
add wave -noupdate /tb/u_eseps2/ff_div
add wave -noupdate /tb/u_eseps2/w_clkena
add wave -noupdate /tb/u_eseps2/ff_timer
add wave -noupdate /tb/u_eseps2/w_timeout
add wave -noupdate -expand /tb/u_eseps2/ff_ps2_rcv_dat
add wave -noupdate /tb/u_eseps2/ff_f0_detect
add wave -noupdate /tb/u_eseps2/ff_e0_detect
add wave -noupdate /tb/u_eseps2/ff_e1_detect
add wave -noupdate /tb/u_eseps2/ff_ps2_send
add wave -noupdate /tb/u_eseps2/ff_ps2_clk_delay
add wave -noupdate -radix unsigned /tb/u_eseps2/ff_ps2_state
add wave -noupdate -radix unsigned /tb/u_eseps2/ff_ps2_sub_state
add wave -noupdate /tb/u_eseps2/w_ps2_host_phase
add wave -noupdate /tb/u_eseps2/w_ps2_device_phase
add wave -noupdate /tb/u_eseps2/w_ps2_rise_edge
add wave -noupdate /tb/u_eseps2/w_ps2_fall_edge
add wave -noupdate /tb/u_eseps2/w_ps2_led_change
add wave -noupdate /tb/u_eseps2/ff_ps2_clk
add wave -noupdate /tb/u_eseps2/ff_ps2_virtual_shift
add wave -noupdate /tb/u_eseps2/ff_shift_key
add wave -noupdate /tb/u_eseps2/ff_control_key
add wave -noupdate /tb/u_eseps2/ff_numlk_key
add wave -noupdate /tb/u_eseps2/ff_pause_toggle_key
add wave -noupdate /tb/u_eseps2/ff_reso_toggle_key
add wave -noupdate /tb/u_eseps2/ff_scrlk_toggle_key
add wave -noupdate /tb/u_eseps2/ff_ps2_dat
add wave -noupdate /tb/u_eseps2/ff_ps2_snd_dat
add wave -noupdate /tb/u_eseps2/ff_led_caps_lock
add wave -noupdate /tb/u_eseps2/ff_led_kana_lock
add wave -noupdate /tb/u_eseps2/ff_led_scroll_lock
add wave -noupdate /tb/u_eseps2/ff_led_num_lock
add wave -noupdate /tb/u_eseps2/ff_matupd_state
add wave -noupdate /tb/u_eseps2/ff_matupd_we
add wave -noupdate /tb/u_eseps2/ff_matupd_rows
add wave -noupdate /tb/u_eseps2/ff_matupd_keys
add wave -noupdate /tb/u_eseps2/ff_keymap_index
add wave -noupdate /tb/u_eseps2/ff_key_unpress
add wave -noupdate /tb/u_eseps2/ff_key_bits
add wave -noupdate /tb/u_eseps2/w_keymap_dat
add wave -noupdate /tb/u_eseps2/ff_key_x
add wave -noupdate /tb/u_eseps2/w_mask
add wave -noupdate /tb/u_eseps2/w_matrix
add wave -noupdate /tb/u_eseps2/ff_func_keys
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {155428033939 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 218
configure wave -valuecolwidth 100
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
WaveRestoreZoom {154659927955 ps} {156196139923 ps}
