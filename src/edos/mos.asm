    macro MOSCALL func
    ld a, func
    rst.lil $08
    endmacro

MOS_GET_KEY:    equ     $00
MOS_SYS_VARS:   equ     $08
MOS_EDIT_LINE:  equ     $09