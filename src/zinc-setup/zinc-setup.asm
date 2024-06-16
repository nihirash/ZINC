;; ZINC is Not CP/M
;;
;; CP/M compatibility layer for Agon's MOS
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved


    ASSUME ADL=1

    include "../mos.asm"

    org $B0000
    jp _start

    align 64
    db "MOS"    ;; HEADER
    db 0        ;; VERSION
    db 1        ;; ADL 


;; ----------------------------------------------------------------------------

_start:
    push ix
    push iy

    PRINTZ banner

    ld hl, config_file
    ld de, options
    ld bc, options_end - options
    MOSCALL MOS_LOAD

    call uart_setup

    ld hl, config_file
    MOSCALL MOS_DELETE

    ld hl, config_file
    ld de, options
    ld bc, options_end - options
    MOSCALL MOS_SAVE

    PRINTZ all_done

    ld hl, 0
    pop iy
    pop ix
    ret

yes_no:
    MOSCALL MOS_GET_KEY
    cp 'y'
    jr z, @yes

    cp 'Y'
    jr z, @yes

    cp 'n'
    jr z, @no

    cp 'N'
    jr z, @no

    jr yes_no
@no:
    ld hl, @no_msg
    ld bc, 0
    xor a
    rst.lil $18
    
    xor a
    ret

@yes:
    ld hl, @yes_msg
    ld bc, 0
    xor a
    rst.lil $18

    ld a, 1
    or a
    ret
@yes_msg:
    db "Yes", 13, 10, 0
@no_msg:
    db "No", 13, 10, 0

banner:
    db 13,10
    db "ZINC Setup Utility ", 13, 10
    db "Version built: "
    incbin "../../.version"
    db 13, 10
    db 0

all_done:
    db 13, 10
    db "All done!", 13, 10
    db "Configuration file updated!", 13, 10
    db 0

config_file:
    db "/mos/zinc.cfg", 0

    include "uart-setup.asm"

    include "../zinc/options.asm"