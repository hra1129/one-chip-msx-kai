BlueMSX に付いている FS-A1GT BIOSダンププログラム(FSA1GT.BAS)を使って、
FS-A1GT実機からダンプしたファイルをここに配置する。
大量に出てくる A1GTFIRM.XXX は、merge.bat で連結して下記のような構成にする。

  Length Name          
  ------ ----          
   32768 A1GTBIOS.ROM  
   65536 A1GTDOS.ROM   
   16384 A1GTEXT.ROM   
 1048576 A1GTFRM1.ROM  
 1048576 A1GTFRM2.ROM  
 1048576 A1GTFRM3.ROM  
 1048576 A1GTFRM4.ROM  
   32768 A1GTKDR.ROM   
  262144 A1GTKFN.ROM   
   16384 A1GTMUS.ROM   
   16384 A1GTOPT.ROM   


