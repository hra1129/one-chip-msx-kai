100 CLEAR 100,&H9FFF:DEFINTA-Z
110 BLOAD"ROMREAD.BIN"
120 DEFUSR0=&HA000:DEFUSR1=&HA03F:WD=&HA085
130 A=USR0(&H4000):GOSUB 220
140 A=USR0(&H4001):GOSUB 220
150 POKE WD, &H23:A=USR1(&H4000)
160 POKE WD, &H34:A=USR1(&H4001)
170 POKE WD, &H1C:A=USR1(&H7FF9):POKE WD, &H12:A=USR1(&H6000)
180 A=USR0(&H4000):GOSUB 220
190 A=USR0(&H4001):GOSUB 220
200 A=USR0(&H7FF0):GOSUB 220
210 END
220 S$=RIGHT$("0"+HEX$(A),2):PRINT S$+" ";:RETURN
