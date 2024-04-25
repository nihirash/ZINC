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
MOS_DELETE:     equ     $05
MOS_SYS_VARS:   equ     $08
MOS_EDIT_LINE:  equ     $09
MOS_FOPEN:      equ     $0a
MOS_FCLOSE:     equ     $0b
MOS_FREAD:      equ     $1a
MOS_FWRITE:     equ     $1b
MOS_FSEEK:      equ     $1c


MOS_OPENDIR:    equ     $91
MOS_CLOSEDIR:   equ     $92
MOS_READDIR:    equ     $93

MOS_CWD:        equ     $9e

;; File Modes
FA_READ:        equ     $01
FA_WRITE:       equ     $02
FA_CREATE:      equ     $04
