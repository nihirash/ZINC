    ASSUME ADL=0

    org $0000
    jp init

    ds $F500 - $
    include "core.asm"