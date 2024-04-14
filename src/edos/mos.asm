;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

    macro MOSCALL func
    ld a, func
    rst.lil $08
    endmacro

MOS_GET_KEY:    equ     $00
MOS_SYS_VARS:   equ     $08
MOS_EDIT_LINE:  equ     $09

MOS_OPENDIR:    equ     $91
MOS_CLOSEDIR:   equ     $92
MOS_READDIR:    equ     $93

MOS_CWD:        equ     $9e