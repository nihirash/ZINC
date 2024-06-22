;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

;; Works similar to real BDOS
console_in:
    call CONIN
    ld l, a

    call check
    ret c

    push af
    ld c, a
    call CONOUT
    pop af
    
    ret

check:
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


console_status:
    call CONST
    and a
    jr z, @exit

    CALL CONIN

    cp CNTRLC
    ld a, $ff
    jr nz, @exit

    ld hl, @msg
    ld bc, 0
    xor a
    rst.lil $18

    jp bye
@msg:
    db 13, 10, "CTRL-C pressed, aborting execution", 13, 10, 0

@exit:
    xor a
    ld b, a
    ret

raw_io:
    ld a, (args)
    inc a
    jr nz, @out

    call CONST
    or a
    ret z

    jp CONIN
@out:
    ld a, (args)
    ld c, a
    call CONOUT

    xor a 
    ld b, a
    ret

get_io_byte:
    ld a, (IOBYTE)
    ret

set_io_byte:
    ld a, c
    ld (IOBYTE), a
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

;; Using MOS routines for line editing 
read_buf:
    ld a, d
    or e
    jr nz, @read

    ld de, (dma_ptr)
@read: 
    ex de, hl
    ld a, (hl)

    ld bc, 2
    add hl, bc
    
    ld b, 0
    ld c, a

    ld e, 1
    MOSCALL MOS_EDIT_LINE
    cp 27
    jr z, @err
    
    push hl
    ld a, CR
    rst.lil $10
    pop hl

    push hl
    ld e, 0
@strlen:
    ld a, (hl)
    or a
    jr z, @done
    inc e
    inc hl
    jr @strlen
@done:
    ld a, e
    pop hl

    dec hl
    ld (hl), a
    
    ld d, 0
    xor a
    ld b, a
    ret
@err:
    ld a, -1
    ret

