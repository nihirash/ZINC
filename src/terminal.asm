;; ZINC is Not CP/M
;;
;; CP/M compatibility layer for Agon's MOS
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

;; Terminal emulation layer

;; Emulates simple ADM-3a like terminal
;; It's good enough and fast

TERM_HOME:  equ $01
TERM_LEFT:  equ $08
TERM_CLS:   equ $0C
TERM_UP:    equ $14
TERM_LEFT2: equ $16
TERM_RIGHT: equ $17
TERM_CLINE: equ $18
TERM_CLS2:  equ $1A
TERM_ESC:   equ $1B

    macro VDU byte
    ld a, byte
    rst.lil $10
    endmacro

termout:
    call _putc
term_fsm: equ $ - 3

    ret.lil

_cls:
    VDU 12
    ret

_home:
    VDU 30
    ret

_left:
    VDU 8
    ret
_up:
    VDU 11
    ret
_right:
    VDU 9
    ret

_esc:
    cp '='
    jr z, @load_coords
;; You can add some ESC codes here

    jr exit_fsm
@load_coords:
    ld hl, _loadx 
    ld (term_fsm), hl
    ret

_loadx:
    sub 32
    ld (term_x), a

    ld hl, _loady
    ld (term_fsm), hl
    ret

_loady:
    sub 32
    ld (term_y), a

    xor a 
    ld mb, a

    ld hl, set_pos_cmd
    ld bc, 3
    rst.lil $18

    ld a, EDOS_PAGE
    ld mb, a

exit_fsm:
    ld hl, _putc
    ld (term_fsm), hl
    ret

_putc:
    and $7f

    cp ' '
    jr nc, @draw

    cp 13
    jr z, @draw

    cp 10
    jr z, @draw

;; Move cursor
    cp TERM_LEFT
    jp z, _left
    cp TERM_LEFT2
    jp z, _left
    cp TERM_UP
    jp z, _up
    cp TERM_RIGHT
    jp z, _right

;; Home cursor
    cp TERM_HOME
    jp z, _home
;; Clear screen
    cp TERM_CLS
    jp z, _cls
    cp TERM_CLS2
    jp z, _cls

;; ESC control sequences 
    cp TERM_ESC
    jr z, @set_esc

;; Isolate rest things
    ret 

@draw:
    rst.lil $10
    ret

@set_esc:
    ld hl, _esc
    ld (term_fsm), hl
    ret

set_pos_cmd:
    db 31
term_y:
    db 0
term_x:
    db 0

    dl 0