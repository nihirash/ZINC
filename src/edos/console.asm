;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

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
    jp CONIN


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
    ret
@err:
    ld a, -1
    ret

