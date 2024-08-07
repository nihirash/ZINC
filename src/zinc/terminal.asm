;; ZINC is Not CP/M
;;
;; CP/M compatibility layer for Agon's MOS
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

;; Terminal emulation layer

;; Emulates simple ADM-3a like terminal
;; It's good enough and fast

TERM_HOME:   equ $01
TERM_BELL:   equ $07
TERM_LEFT:   equ $08
TERM_FF:     equ $0C
TERM_UP:     equ $14
TERM_LEFT2:  equ $16
TERM_RIGHT:  equ $17
TERM_CLINE:  equ $18
TERM_CLS2:   equ $1A
TERM_ESC:    equ $1B
TERM_RS:     equ $1E

TERM_COORDS: equ '='
TERM_SWITCH: equ $ff
TERM_FG:     equ 'f'
TERM_BG:     equ 'b'

    macro VDU byte
    ld a, byte
    rst.lil $10
    endmacro

;; Little preparation for work - setting variables and other things
term_init:
    MOSCALL MOS_SYS_VARS

    lea hl, ix + VAR_CURSORX
    ld (term_pos), hl

    lea hl, ix + VAR_SCRWIDTH
    ld (term_size), hl

    lea hl, ix + VAR_VDP_DONE
    ld (cmd_done), hl

    lea hl, ix + VAR_KEYASCII ;; ASCII KEYCODE
    ld (keycode_ptr), hl

    lea hl, ix + VAR_KEYDOWN ;; VKEYDOWN
    ld (keydown_ptr), hl

    lea hl, ix + VAR_VKEYCOUNT ;; VKEYCOUNT
    ld (keycount_ptr), hl

    ld hl, @cmd
    ld bc, 4
    rst.lil $18

    jp uart_init
@cmd:
    db 23, 0, $98, 0


term_free:
    MOSCALL MOS_UCLOSE

    ld hl, @cmd
    ld bc, @end - @cmd
    rst.lil $18
    
    ret
@cmd:
    db 23, 0, $98, 1
@end:

termstatus:
    ld a, (IOBYTE + EDOS_BASE)
    and 3
    jp z, uart_status
console_status:
    ld hl, (keycount_ptr)
    ld a, (hl)
    and a
    ret.lil z

    ld hl, (keydown_ptr)
    ld a, (hl)
    and a
    ret.lil z

    ld hl, (keycode_ptr)
    ld a, (hl)
    and $7f
    ld (keycode), a
    ret.lil z

    ld a, $ff
    ret.lil

termin:
    ld a, (IOBYTE + EDOS_BASE)
    and 3
    jp z, uart_in
console_in:
@rep:
    ld hl, (keycount_ptr)
    ld a, (hl)
    and a
    jr z, @rep

    ld hl, (keydown_ptr)
    ld a, (hl)
    and a
    jr z, @rep

    ld hl, (keycode_ptr)
    ld a, (hl)
    and $7f
    ld (keycode), a
    jr z, @rep
    
    xor a
    ld hl, (keydown_ptr)
    ld (hl), a

    ld a, (keycode)
    cp $15
    jr nz, @ok
    ld a, CNTRLL

@ok:
    ret.lil

termout:
    ld a, (IOBYTE + EDOS_BASE)
    and 3
    ld a, c
    jp z, uart_out
console_out:
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

_bell:
    VDU 7
    ret

_esc:
;; Load coordinates
    cp TERM_COORDS
    jr z, @load_coords

;; Disable terminal emulation routine
    cp TERM_SWITCH
    jr z, @term_switch
;; Load foreground color
    cp TERM_FG
    jr z, @term_fg
;; Load background color
    cp TERM_BG
    jr z, @term_bg

;; You can add some ESC codes here
    jp exit_fsm
@load_coords:
    ld hl, _loadx 
    ld (term_fsm), hl
    ret
@term_switch:
    ld hl, _vdp
    ld (term_fsm), hl
    ret
@term_fg:
    ld hl, _fg
    ld (term_fsm), hl
    ret
@term_bg:
    ld hl, _bg
    ld (term_fsm), hl
    ret


_fg:
    and 63
    jr set_color

    jp exit_fsm

_bg:
    and 63
    xor $80
set_color:
    ld c, a

    ld a, 17
    rst.lil $10

    ld a, c 
    rst.lil $10

    jp exit_fsm
_vdp:
    cp TERM_ESC
    jr z, @vpd_esc

    rst.lil $10
    ret
@vpd_esc:
    ld hl, _vdp_esc
    ld (term_fsm), hl
    ret

_vdp_esc:
    cp TERM_SWITCH
    jr z, @back_to_emul

    push af
    ld a, TERM_ESC
    rst.lil $10
    pop af
    rst.lil $10

    ld hl, _vdp
    ld (term_fsm), hl
    ret
@back_to_emul:
    ld hl, _putc
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
    cp TERM_FF
    jp z, _right

    cp ' '
    jr nc, @draw

    cp TAB
    jp z, _tab

    cp CR
    jr z, @draw

    cp LF
    jr z, @draw

    cp TERM_BELL
    jp z, _bell

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
    cp TERM_RS
    jp z, _home

;; Clear screen    
    cp TERM_CLS2
    jp z, _cls

    cp TERM_CLINE
    jp z, _clear_line

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

_tab:
    xor a
    ld mb, a

    call load_pos
    ld hl, (term_pos)
    ld a, (hl)
@loop:
    and 15
    jr z, @exit
    push af
    VDU ' '
    pop af
    inc a
    jr @loop

@exit:
    ld a, EDOS_PAGE
    ld mb, a
    ret 


;; Clear current line. Mostly cause KayPro - many softwares except that this command is implemented
;; Even if original ADM-3A haven't it
_clear_line:
    xor a 
    ld mb, a

    call load_pos
    call load_size

    ld hl, (term_pos)
    ld a, (hl)
    ld (@coords), a
    inc hl
    ld a, (hl)
    ld (@coords + 1), a

    ld hl, @cmd
    ld bc, 3
    rst.lil $18

    ld hl, (term_size)
    ld a, (hl)
    ld c, a
    ld a, (@coords)
    ld b, a
    ld a, c
    sub b
    ld b, a
@loop:
    push bc
    VDU ' '
    pop bc
    djnz @loop

    ld hl, @cmd
    ld bc, 3
    rst.lil $18    

    ld a, EDOS_PAGE
    ld mb, a
    ret
@cmd:
    db 31
@coords:
    db 0
    db 0
;; It's more robust way be sure that our fetch command was executed
cmd_result:
    ld hl, (cmd_done)
@wait:
    ld a, (hl)
    and a 
    jr z, @wait
    ret


load_size:
    ld hl, (cmd_done)
    xor a
    ld (hl), a

    ld hl, @cmd
    ld bc, 3
    rst.lil $18
    jr cmd_result
@cmd:
    db 23, 0, $86

load_pos:
    ld hl, (cmd_done)
    xor a
    ld (hl), a

    ld hl, @cmd
    ld bc, 3
    rst.lil $18
    jr cmd_result
@cmd:
    db 23, 0, $82

set_pos_cmd:
    db 31
term_y:
    db 0
term_x:
    db 0

cmd_done:
    dl 0
term_pos:
    dl 0
term_size:
    dl 0


keycount_ptr:
    dl 0
keydown_ptr:
    dl 0
keycode_ptr:
    dl 0
keycode:
    db 0