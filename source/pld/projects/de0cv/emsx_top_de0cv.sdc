derive_pll_clocks

#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK_50} -period 20 [get_ports CLOCK_50]
#create_clock -period 20 [get_ports CLOCK2_50]
#create_clock -period 20 [get_ports CLOCK3_50]
#create_clock -period 20 [get_ports CLOCK4_50]


#**************************************************************
# Create Generated Clock
#**************************************************************

#create_generated_clock -name {emsx_top:U92|clkdiv[0]} -duty_cycle 50 -multiply_by 1 -divide_by 4 -source {U90|pll_de0cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk} {emsx_top:U92|clkdiv[0]}
#create_generated_clock -name {emsx_top:U92|HardRst_cnt[0]} -duty_cycle 50 -multiply_by 1 -divide_by 16 -source {U90|pll_de0cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk} {emsx_top:U92|HardRst_cnt[0]}



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -max 6.4 [get_ports pMemDat[*]]
set_input_delay -clock [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -min 3.2 [get_ports pMemDat[*]]
set_output_delay -clock [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -max  1.5 [get_ports {pMemDat[*] pMemAdr[*] pMemLdq pMemUdq pMemWe_n pMemCas_n pMemRas_n pMemCs_n}]
set_output_delay -clock [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -min -0.8 [get_ports {pMemDat[*] pMemAdr[*] pMemLdq pMemUdq pMemWe_n pMemCas_n pMemRas_n pMemCs_n}]



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
##**************************************************************

#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -from [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -to [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 2
set_multicycle_path -from [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -to [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 1
set_multicycle_path -from [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -to [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 2
set_multicycle_path -from [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -to [get_clocks {U90|pll_de0cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 1



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************
