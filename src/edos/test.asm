;; Useless file just for testing
    ASSUME ADL=0

    org $0000
    jp init

    ds $F000 - $
    include "core.asm"