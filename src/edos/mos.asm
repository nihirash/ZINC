;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

    macro MOSCALL func
    ld a, func
    rst.lil $08
    endmacro

;; API CALLS
MOS_GET_KEY:    equ     $00
MOS_LOAD:       equ     $01
MOS_DELETE:     equ     $05
MOS_RENAME:     equ     $06
MOS_SYS_VARS:   equ     $08
MOS_EDIT_LINE:  equ     $09
MOS_FOPEN:      equ     $0a
MOS_FCLOSE:     equ     $0b
MOS_UOPEN:      equ     $15
MOS_UCLOSE:     equ     $16
MOS_UGETC:      equ     $17
MOS_UPUTC:      equ     $18
MOS_GETFIL:     equ     $19
MOS_FREAD:      equ     $1a
MOS_FWRITE:     equ     $1b
MOS_FSEEK:      equ     $1c


MOS_OPENDIR:    equ     $91
MOS_CLOSEDIR:   equ     $92
MOS_READDIR:    equ     $93

MOS_FSTAT:      equ     $96

MOS_CWD:        equ     $9e

;; File Modes
FA_READ:        equ     $01
FA_WRITE:       equ     $02
FA_CREATE:      equ     $04
FA_CREATE_ALW:  equ     $08
FA_OPEN_ALW:    equ     $10

VAR_VDP_DONE:  equ $04
VAR_KEYASCII:  equ $05
VAR_CURSORX:   equ $07
VAR_CURSORY:   equ $08
VAR_SCRWIDTH:  equ $13
VAR_KEYDOWN:   equ $18
VAR_VKEYCOUNT: equ $19
