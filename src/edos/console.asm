;; Works similar to real BDOS
console_in:
    call CONIN
    call check_char
    ret c          ;; Do not echo some symbols

    push af
    ld c,a
    call console_out
    pop af
    
    ret

check_char:
    cp CR
    ret z
    cp LF
    ret z
    cp TAB
    ret z
    cp BS
    ret z
    cp ' '
    ret

;; I think we can here skip a bit complex things
console_out:
    jp CONOUT

raw_io:
    ld a, c
    inc a
    jr z, @input
    inc a
    jp z, CONST
    jp CONOUT
@input:
    call CONST
    or a
    ret z

    call CONIN
    ret


get_io_byte:
    ld a, (IOBYTE)
    ret

set_io_byte:
    ld a, c
    ld (IOBYTE),a
    ret

;; Why not use MOS function?
;; Cause IOBYTE - this function can be used for UART too
write_str:
    ld b, d
    ld c, e
@w:
    ld a, (bc)
    cp '$'
    ret z
    inc bc

    push bc
    ld c,a
    call console_out
    pop bc
    
    jr @w