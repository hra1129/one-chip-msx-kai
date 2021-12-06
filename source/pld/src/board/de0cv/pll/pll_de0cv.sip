set_global_assignment -entity "pll_de0cv" -library "lib_pll_de0cv" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_de0cv" -library "lib_pll_de0cv" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "pll_de0cv" -library "lib_pll_de0cv" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_de0cv" -name SPD_FILE [file join $::quartus(sip_path) "pll_de0cv.spd"]

set_global_assignment -library "lib_pll_de0cv" -name MISC_FILE [file join $::quartus(sip_path) "pll_de0cv_sim/pll_de0cv.vho"]
