; =======================================
; Plot LOGO for MSX2+ with antialiasing
; to insert in MSXKANJI.ROM file.
; Binary result: KNOCMKAI.ROM
; Size of logo: 432*71 dots
; Hex Editor Address: $399d - $3fff
; Modified by KdL 2020.01.15
; Coded in TWZ'CA3 w/ TASM80 v3.2ud
; =======================================

    .org    07A00h - 99         ; StartProg - MainProg = 99 bytes               <---------------------
;   .org    0100h               ; KNOCMKAI.COM

MainProg:
;   jp      startProg           ; 3 bytes -> required for KNOCMKAI.COM
;\------------------------------
Line_EX_COM:                    ; 13 bytes
    push    de
    ld  e, 70h                  ; Line Execution Command
loc_7C2F:
    ld  d, 2Eh                  ; R#46 - Command Register
    call    wr_dat2reg
    call    wait_CE
    pop de
    ret
; ==============================
sub_7C3E:                       ; 67 bytes
    ld  a, 0Dh                  ; RTC#13 mode register
    out (0B4h), a
    in  a, (0B5h)
    and 0Ch
    or  2
    out (0B5h), a               ; Select Block 2
    ld  a, 0Bh                  ; Register Color/Title
    out (0B4h), a
    in  a, (0B5h)               ; (Color/Title) -> Code (Color)=0..3
    rlca
;   rlca
    and 06h                     ; 0Ch by default
    ld  c, a
    ld  b, 0
    ld  hl, tab_7CA4            ; Color table
    add hl, bc
    ld  c, (hl)
    inc hl
    ld  b, (hl)
    push    bc
;   inc hl
;   ld  e, (hl)
;   inc hl
;   ld  d, (hl)
;   ex  de, hl
; Set Palette Register address
    ld  de, 1000h               ; 00H -> R#16
    ld  h, e                    ; 0/0/0 -> black
    ld  l, e                    ; 0/0/0 -> black
    call    wr_dat2reg
; Set Palette Register 0...7
    call    sub_7C7A
    pop hl                      ; RED/BLUE/GREEN -> bg color
    call    sub_7C7A
    ld  hl, 0444h               ; 4/4/4 -> gray
    call    sub_7C7A
    ld  hl, 0777h               ; 7/7/7 -> white
; ------------------------------
sub_7C7A:
    push    bc
    ld  c, 9Ah
    out (c), l
    ex  (sp), hl
    ex  (sp), hl
    out (c), h
    pop bc
    ret
; ==============================
; hl=
sub_7A9F:                       ; 19 bytes
    dec hl
    ld  a, l
    srl h
    rra
    rrca
    rrca
    inc a
    and 3Fh
    ld  h, a
    inc l
    ld  a, l
    neg
    and 7
    ld  l, a
    ret
; ==============================
startProg:                      ; 3A00h of MSXKANJI.ROM, 7A00h of MSX memory    <---------------------
    di
    call    sub_7ADA            ; Init
    call    sub_7A09            ; View
    ei
    ret                         ; Exit
loop4DOS:
;   jr      loop4DOS            ; Loop test for KNOCMKAI.COM
;   
; ==============================
; View LOGO
sub_7A09:
    ld  hl, 00FFh               ;
    call    sub_7A9F            ;
;
    ld  e, h
    ld  d, 1Ah                  ; R#26
    call    wr_dat2reg
    ld  e, l
    ld  d, 1Bh                  ; R#27
    call    wr_dat2reg
;
    call    sub_7A83            ; Wait 2 VR
;
    ld  de, 0163h
    call    wr_dat2reg          ; 63h -> R#1
    ld  hl, 00E1h
    ld  de, 0FFF6h
loc_7A2A:
    inc de                      ;
    ld  b, 5
loc_7A2D:
    push    bc
    push    de
    call    sub_7A48
    pop de
    pop bc
    add hl, de
    djnz    loc_7A2D
;\------------------------------
    ld  a, e
    or  a
    jr  nz, loc_7A2A
;\------------------------------
    ld  de, 1900h
    call    wr_dat2reg          ; 00h -> R#25
    ld  de, 21Fh
    call    wr_dat2reg          ; 1Fh -> R#2
    ret
; ==============================
sub_7A48:
    push    hl
    call    sub_7A83            ; Wait 2 VR
    xor a
    sub l
    ld  e, a
    ld  a, 2
    sbc a, h
    ld  d, a
    call    sub_7A9F
    ex  de, hl
    call    sub_7A9F
    ld  bc, 559Bh
loc_7A5D:
    ld  a, 1Ah                  ; Data 1Ah
    out (99h), a
    ld  a, 91h                  ; R#17 - Control register pointer
    out (99h), a
    ex  de, hl
    in  a, (99h)
loc_7A68:
    in  a, (99h)
    and 20h                     ; Bit 5 -
    jr  z, loc_7A68             ; +1 byte free (jp -> jr)
;\------------------------------
    out (c), h
    out (c), l
    djnz    loc_7A5D
;\------------------------------
    pop hl
    ld  de, 1A00h               ; 00h -> R#26
    call    wr_dat2reg
    ld  de, 1B00h               ; 00H -> R#27
    call    wr_dat2reg
    ret
; ==============================
; WAIT 2 Vertical scanning line
sub_7A83:
    ld  a, 2                    ; S#2
    out (99h), a                ; Data = 02H
    ld  a, 8Fh                  ; R#15 - Status register pointer
    out (99h), a
loc_7A8B:
    in  a, (99h)
    and 40h                     ; Bit 6 - Flag VR
    jr  z, loc_7A8B 
;\------------------------------
loc_7A91:
    in  a, (99h)
    and 40h                     ; Bit 6 - Flag VR
    jr  nz, loc_7A91
;\------------------------------
    xor a                       ; S#0
    out (99h), a
    ld  a, 8Fh                  ; R#15 - Status register pointer
    out (99h), a
    ret
; ==============================
; Init SCREEN memory and VDP registers
sub_7ADA:
    call    sub_7A83            ; Wait 2 VR
; Set Mode Register #1
; BL = 0 Screen disabled
; IE0 = 1 Enable IE0
; M1,M2 = 00
; SI = 1 Sprite Size 16x16
; MA = 1 Sprite expansion Enable
;   ld  de, 0123h               ; 23h -> R#1
;   call    wr_dat2reg          ; +6 bytes free
;
; ==============================
init_VDP:                       ; 15 bytes
    ld  b, 8
    ld  hl, tab_7C94            ; 08h -> R#0
loc_7C8A:
    ld  d, (hl)                 ; R#n
    inc hl
    ld  e, (hl)                 ; Data
    inc hl
    call    wr_dat2reg
    djnz    loc_7C8A

;
    ld  a, 55h                  ;
    ld  hl, 0
    ld  c, l
    ld  b, l
    call    wr_VRAM             ; Init VRAM
;
    call    sub_7C3E
; Set Text Color=0/Back drop color=5
    ld  de, 705h        ; 05H -> R#7
    call    wr_dat2reg
;
    ld  hl, 7800h               ; Sprite color table
    ld  bc, 30h
    ld  a, 0FFh                 ; pattern of 1st 8 pixel in left mask ( 0FFh )
    call    wr_VRAM
    ld  hl, 7830h
    ld  bc, 10h
    ld  a, 000h                 ; pattern of 2nd 8 pixel in left mask ( 0F0h )  <---------------------
    call    wr_VRAM
    ld  hl, 7400h
    ld  a, 5
    ld  bc, 200h
    call    wr_VRAM
    ld  hl, tab_7AB2            ;
    ld  de, 7600h
    ld  bc, 28h
    call    sub_7BE5
;
    ld  de, 1903h               ; 03H -> R#25
    call    wr_dat2reg
    ld  de, 023Fh               ; 3FH -> R#2
    call    wr_dat2reg
;
    ld  de, 2D00h               ; 00H -> R#45
    call    wr_dat2reg
    ld  d, 2Ah                  ; 00H -> R#42
    call    wr_dat2reg
    inc d                       ; 00H -> R#43
    call    wr_dat2reg
    ld  d, 27h                  ; 00H -> R#39
    call    wr_dat2reg
    ld  e, 29h                  ; Y dest of logo image => 20h by default        <---------------------
    ld  hl, tab_7D3B            ; Table Logo Image
    exx
    ld  hl, tab_7CB4            ; Table Antialiasing bits
    exx
;\------------------------------
loc_7B50:
    ld  a, 3
    push    af
    ld  bc, 28h                 ; X dest of logo image => 2Dh by default        <--------- (512-432)/2
    ld  d, 26h                  ; R#38 - Y destination register
    call    wr_dat2reg
;   exx
;   ld  b, 8
;   ld  c, (hl)                 ; tab_7CB4 or
; ; ld  c, 0                    ; Antialiasing disabled
;   inc hl
;   exx
;\------------------------------
loc_7B61:
    call    set_dest_X          ; R#36,37 - Dest X register
    ld  a, (hl)                 ; tab_7D3B
    inc hl
    cp  0FEh                    ; End line ?
    jr  z, loc_7BA1             ; Next Y
;
    push    hl
    push    bc
    ld  bc, 432                ; Logo width => 422 by default                  <---------------------
    jr  nc, loc_7B74            ; a=0FFh Empty line
    ld  b, 0
    ld  c, a
loc_7B74:
    call    set_NDot_X          ; R#40,41 -> Number Dots X
    pop hl
    add hl, bc
    ld  c, l
    ld  b, h
    pop hl
    pop af
    xor 3
    call    set_Color
    push    af
    call    Line_EX_COM
;   exx
;   sla c
;   djnz    loc_7B8F
;   ld  b, 8
;   ld  c, (hl)                 ; tab_7CB4 or
; ; ld  c, 0                    ; Antialiasing disabled
;   inc hl
loc_7B8F:
;   exx
;   jr  nc, loc_7B61
;   dec bc
;   call    set_dest_X          ; R#36,37 - Dest X register
;   inc bc
;   ld  a, 2                    ; set antialias color
;   call    set_Color
;   call    PSET_EX_COM
    jr  loc_7B61
;\------------------------------
loc_7BA1:
    inc e                       ; Next Y
    pop af
    ld  a, (hl)
    cp  0FEh
    jr  nz, loc_7B50
    ret
; ==============================
wr_dat2reg:
    push    af
    ld  a, e                    ; Data
    out (99h), a
    ld  a, d                    ; Register
    or  80h
    out (99h), a
    pop af
    ret
; ==============================
wait_CE:
    ld  a, 2
; ==============================
; Read Status Register (A)
rd_Stat_A:
    out (99h), a
    ld  a, 8Fh                  ; R#15 - Status Register pointer
    out (99h), a
    push    hl
    pop hl
    in  a, (99h)                ; Read (Status Register)
    push    af
    xor a
    out (99h), a
    ld  a, 8Fh
    out (99h), a
    pop af
;
    rrca                        ; Bit 0 (CE) - Command Execution Flag
    jr  c, wait_CE
    rlca
    ret
; ==============================
; Write VRAM
; A - byte
; HL - address
; BC - LEN
wr_VRAM:
    push    af
    call    sub_7BFA            ; Set VRAM access adress
    ld  a, c
    or  a
    jr  z, loc_7BDB
    inc b
loc_7BDB:
    pop af
loc_7BDC:
    out (98h), a
    dec c
    jr  nz, loc_7BDC            ; +1 byte free (jp -> jr)
    djnz    loc_7BDC
;\------------------------------
    ret
; ==============================
sub_7BE5:
    ex  de, hl
    call    sub_7BFA
    ex  de, hl
    ld  a, c
    or  a
    ld  a, b
    ld  b, c
    ld  c, 98h                  ; Port Data VDP
    jr  z, loc_7BF3
    inc a
loc_7BF3:
    otir
    dec a
    jr  nz, loc_7BF3
    ex  de, hl
    ret
; ==============================
; Set VRAM Access base adress
sub_7BFA:
    ld  a, h
    and 3Fh
    or  40h
    ex  af, af'
    ld  a, h
    and 0C0h
    rlca
    rlca
    out (99h), a
    ld  a, 8Eh                  ; R#14 - VRAM Access Adress
    out (99h), a
    ld  a, l
    out (99h), a
    ex  af, af'
    out (99h), a
    ex  (sp), hl
    ex  (sp), hl
    ret
; ==============================
set_NDot_X:
    ld  d, 28h                  ; R#40,41 -> Number Dots X (28h by default)
    jr  loc_7C1A
; ==============================
set_dest_X:
    ld  d, 24h                  ; R#36,37 - Dest X register
loc_7C1A:
    push    de
    ld  e, c
    call    wr_dat2reg
    ld  e, b
    inc d
    jr  loc_7C27
; ==============================
set_Color:
    push    de
    ld  e, a
    ld  d, 2Ch                  ; R#44 - Color register
loc_7C27:
    call    wr_dat2reg
    pop de
    ret
; ==============================
PSET_EX_COM:
    push    de
    ld  e, 50h                  ; PSET Execution Command
    jp  loc_7C2F                ; R#46 - Command Register
; ==============================
; TAB init VDP registers
tab_7C94:
    .dw 0800h                   ; 08h -> R#0 Graphic 4 mode
    .dw 2301h                   ; 23h -> R#1
    .dw 2808h                   ; 28H -> R#8
    .dw 0009h                   ; 00h -> R#9
; Pattern name table base address = 7C00h
    .dw 1F02h                   ; 1FH -> R#2
; Sprite attribute table base address = 07780h
    .dw 0EF05h                  ; 0EFH -> R#5
    .dw 000Bh                   ; 00H -> R#11
; Sprite pattern generator table base address = 07800h
    .dw 0F06h                   ; 0FH -> R#6
; ==============================
; TAB PALETTE REGISTERS 0       ; 0..1 by default
tab_7CA4:
;   .dw 0007h                   ; Set Title ,1  (Blue - Black)
;   .dw 0000h
    .dw 0007h                   ; Blue bg
;
;   .dw 0420h                   ; Set Title ,2  (Green - Cyan)
;   .dw 0227h
    .dw 0510h                   ; Green bg
;
;   .dw 0272h                   ; Set Title ,3  (Red - Purple)
;   .dw 0056h
    .dw 0061h                   ; Red bg
;
;   .dw 0570h                   ; Set Title ,4  (Orange - Red)
;   .dw 0070h
    .dw 0470h                   ; Orange bg
; ==============================
; Sprite attribute
tab_7AB2:                       ; Y,X,pattern,0
    .db  1Ch, 0ECh, 0, 0        ; right mask position, X=0E8h by default        <---------------------
    .db  1Ch, 0ECh, 0, 0        ; right mask position                           <---------------------
    .db  3Ch, 0ECh, 0, 0        ; right mask position                           <---------------------
    .db  3Ch, 0ECh, 0, 0        ; right mask position                           <---------------------
    .db  5Ch, 0ECh, 0, 0        ; right mask position                           <---------------------
    .db  5Ch, 0ECh, 0, 0        ; right mask position                           <---------------------
    .db  1Ch,    0, 4, 0        ; left mask position, X=0 by default
    .db  3Ch,    0, 4, 0        ; left mask position
    .db  5Ch,    0, 4, 0        ; left mask position
    .db 0D8h,    0, 0, 0
; ==============================
; Table antialiasing bits
tab_7CB4:                       ; tab_7CB4 is accross to sprite attribute       <---------------------

;   nop                         ; not used

; ==============================
; Table LOGO
; 0FFh - Empty line
; 0FEh - New line
; 0FEh,0FEh - End LOGO
; Width line = 432 dots
tab_7D3B:                       ;                                               <---------------------
      .db 255, 254
      .db 255, 254
      .db 255, 254
      .db 30, 6, 12, 8, 10, 6, 8, 6, 5, 6, 5, 18, 253, 0, 59, 254
      .db 27, 9, 9, 14, 7, 6, 8, 6, 5, 6, 5, 20, 253, 0, 57, 254
      .db 25, 11, 7, 18, 5, 6, 8, 6, 5, 6, 5, 6, 7, 7, 253, 0, 57, 254
      .db 25, 11, 6, 8, 5, 6, 5, 6, 8, 6, 5, 6, 5, 6, 8, 6, 253, 0, 57, 254
      .db 30, 6, 6, 6, 18, 6, 8, 6, 5, 6, 5, 6, 8, 6, 253, 0, 57, 254
      .db 30, 6, 5, 6, 19, 20, 5, 6, 5, 6, 7, 7, 253, 0, 57, 254
      .db 30, 6, 5, 6, 19, 20, 5, 6, 5, 20, 253, 0, 57, 254
      .db 30, 6, 5, 6, 19, 6, 8, 6, 2, 2, 1, 6, 2, 2, 1, 18, 4, 23, 37, 86, 36, 32, 94, 254
      .db 30, 6, 6, 6, 18, 6, 8, 6, 2, 2, 1, 6, 2, 2, 1, 6, 16, 24, 31, 92, 34, 31, 96, 254
      .db 30, 6, 6, 8, 5, 6, 5, 6, 6, 1, 1, 6, 2, 2, 1, 6, 2, 2, 1, 6, 15, 25, 28, 97, 30, 32, 97, 254
      .db 30, 6, 7, 18, 5, 6, 6, 1, 1, 6, 2, 2, 1, 6, 2, 2, 1, 6, 15, 26, 24, 101, 28, 31, 99, 254
      .db 30, 6, 9, 14, 7, 6, 6, 1, 1, 6, 2, 2, 1, 6, 2, 2, 1, 6, 14, 27, 22, 104, 26, 31, 100, 254
      .db 30, 6, 12, 8, 10, 6, 5, 2, 1, 6, 2, 2, 1, 6, 2, 2, 1, 6, 14, 28, 19, 108, 22, 31, 102, 254
      .db 77, 2, 9, 2, 9, 2, 20, 29, 17, 111, 20, 31, 103, 254
      .db 76, 31, 14, 30, 15, 114, 16, 31, 105, 254
      .db 76, 31, 13, 31, 14, 116, 14, 31, 106, 254
      .db 75, 33, 12, 32, 12, 118, 12, 30, 108, 254
      .db 75, 33, 11, 33, 11, 121, 8, 31, 109, 254
      .db 74, 35, 10, 34, 9, 123, 6, 30, 111, 254
      .db 74, 35, 9, 35, 9, 125, 2, 31, 112, 254
      .db 73, 37, 8, 36, 7, 32, 65, 60, 114, 254
      .db 73, 37, 7, 37, 7, 29, 69, 58, 115, 254
      .db 72, 39, 6, 38, 6, 27, 73, 54, 117, 254
      .db 72, 39, 5, 39, 6, 27, 74, 52, 70, 5, 43, 254
      .db 71, 41, 4, 40, 5, 29, 74, 48, 67, 14, 39, 254
      .db 71, 41, 3, 41, 5, 32, 72, 46, 64, 20, 37, 254
      .db 70, 43, 2, 42, 5, 60, 45, 42, 72, 15, 36, 254
      .db 70, 43, 1, 43, 5, 65, 41, 40, 75, 13, 36, 254
      .db 69, 89, 5, 67, 40, 36, 78, 12, 36, 254
      .db 69, 89, 6, 69, 38, 34, 78, 12, 37, 254
      .db 68, 91, 6, 70, 38, 30, 50, 7, 22, 12, 38, 254
      .db 68, 91, 7, 71, 37, 28, 44, 17, 17, 14, 38, 254
      .db 67, 93, 7, 72, 34, 30, 39, 22, 15, 14, 39, 254
      .db 67, 93, 9, 71, 31, 34, 33, 26, 14, 14, 5, 6, 29, 254
      .db 66, 95, 10, 70, 29, 36, 29, 29, 12, 15, 4, 11, 26, 254
      .db 66, 95, 12, 69, 26, 40, 43, 13, 11, 32, 25, 254
      .db 65, 26, 1, 43, 1, 26, 14, 67, 24, 42, 42, 12, 10, 33, 26, 254
      .db 65, 26, 2, 42, 2, 25, 17, 64, 22, 46, 38, 13, 9, 32, 29, 254
      .db 64, 26, 3, 41, 3, 26, 21, 60, 20, 48, 35, 14, 9, 29, 33, 254
      .db 64, 26, 4, 40, 4, 25, 50, 31, 18, 52, 26, 3, 2, 15, 10, 25, 37, 254
      .db 63, 26, 5, 39, 5, 26, 52, 28, 17, 54, 24, 20, 11, 23, 39, 254
      .db 63, 26, 6, 38, 6, 25, 54, 26, 15, 58, 21, 19, 14, 21, 40, 254
      .db 62, 26, 7, 37, 7, 26, 53, 26, 14, 60, 19, 18, 18, 9, 4, 7, 39, 254
      .db 62, 26, 8, 36, 8, 25, 51, 28, 12, 31, 2, 31, 16, 13, 40, 7, 36, 254
      .db 61, 26, 9, 35, 9, 26, 47, 31, 11, 30, 6, 30, 14, 10, 14, 1, 31, 8, 33, 254
      .db 61, 26, 10, 34, 10, 103, 9, 31, 8, 31, 12, 8, 15, 2, 33, 8, 31, 254
      .db 60, 26, 11, 33, 11, 102, 9, 30, 12, 30, 10, 7, 16, 3, 34, 7, 31, 254
      .db 60, 26, 12, 32, 12, 101, 7, 31, 14, 31, 8, 7, 15, 3, 34, 8, 31, 254
      .db 59, 26, 13, 31, 13, 100, 7, 31, 16, 31, 6, 7, 15, 4, 33, 9, 31, 254
      .db 59, 26, 14, 30, 14, 98, 6, 31, 20, 31, 4, 7, 13, 5, 8, 15, 9, 10, 32, 254
      .db 58, 26, 15, 29, 15, 97, 6, 31, 22, 31, 3, 7, 11, 7, 12, 15, 3, 11, 33, 254
      .db 58, 26, 16, 28, 16, 95, 5, 31, 26, 29, 2, 7, 10, 8, 19, 21, 35, 254
      .db 57, 26, 17, 27, 17, 93, 6, 31, 28, 28, 2, 7, 8, 10, 24, 15, 36, 254
      .db 57, 26, 18, 26, 18, 90, 6, 32, 30, 27, 2, 7, 6, 11, 28, 11, 37, 254
      .db 56, 26, 19, 25, 19, 88, 7, 31, 34, 25, 2, 7, 4, 12, 28, 13, 36, 254
      .db 56, 26, 20, 24, 20, 84, 8, 32, 36, 24, 2, 8, 2, 13, 25, 18, 34, 254
      .db 55, 26, 21, 23, 21, 81, 10, 31, 40, 23, 2, 24, 20, 24, 31, 254
      .db 55, 26, 22, 22, 22, 75, 13, 32, 42, 22, 2, 20, 2, 5, 10, 19, 3, 12, 28, 254
      .db 200, 0, 134, 18, 4, 30, 7, 14, 25, 254
      .db 200, 0, 135, 15, 8, 24, 13, 15, 22, 254
      .db 200, 0, 136, 12, 12, 19, 17, 17, 19, 254
      .db 200, 0, 137, 9, 17, 10, 25, 18, 16, 254
      .db 200, 0, 139, 5, 56, 19, 13, 254
      .db 200, 0, 203, 19, 10, 254
      .db 200, 0, 207, 19, 6, 254
      .db 255, 254
      .db 255, 254
      .db 255, 254
      .db 254
; ==============================
end_logo:                       ; fillers -> file lenght will be 1.635 bytes    <---------------------
      .db 0FFh, 0FFh, 0FFh, 0FFh
;\------------------------------
    .end

