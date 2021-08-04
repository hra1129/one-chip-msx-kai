カートリッジスロットを 20MHz で 5MSa サンプリングした波形データです。

波形データは下記のツールで閲覧できます。
http://www.qdkingst.com/en
	KingstVIS

----------------------------------------------------------------
slot_signal_A1GT_R800_RDWRTEST.kvdat
	A1GT R800モード

slot_signal_A1GT_Z80_RDWRTEST.kvdat
	A1GT Z80モード

slot_signal_SX-2_3.58MHz_RDWRTEST.kvdat
	SX-2 3.58MHzモード, OCM-PLD 3.9 beta (スロット信号は OCM-PLD 3.8.1相当)

slot_signal_SX-2_8.06MHz_RDWRTEST.kvdat
	SX-2 8.06MHzモード, OCM-PLD 3.9 beta (スロット信号は OCM-PLD 3.8.1相当)

slot_signal_SX-2_3.58MHz_RDWRTEST2.kvdat
	SX-2 3.58MHzモード, OCM-PLD 3.9 beta2 (スロット信号は下記の改修をしたもの)
	
		---- Modified by t.hara in 4th/Aug/2021
		--    BusDir_o    <=  '0' when( pSltRd_n = '1' )else
		--                    '1' when( pSltIorq_n = '0' and BusDir    = '1' )else
		--                    '1' when( pSltMerq_n = '0' and PriSltNum = "00" )else
		--                    '1' when( pSltMerq_n = '0' and PriSltNum = "11" )else
		--                    '1' when( pSltMerq_n = '0' and PriSltNum = "01" and Scc1Type /= "00" )else
		--                    '1' when( pSltMerq_n = '0' and PriSltNum = "10" and Slot2Mode /= "00" )else
		--                    '0';

		---- Modified by t.hara in 4th/Aug/2021
		    BusDir_o    <=  '0' when( pSltRd_n = '1' )else
		                    '1' when( pSltIorq_n = '0' and BusDir    = '1' )else
		                    '1' when( pSltMerq_n = '0' )else
		                    '0';
