FCB:    equ $5005c ; default FCB placement
BUFF:   equ $50080

;; Prepare system vars on start application
prepare_vars:
    ld hl, fcb_template

    push hl
    ld de, FCB
    ld bc, 16
    ldir
    pop hl

    ld bc, 16
    ldir

    ld de, BUFF
    xor a 
    ld (de), a
    inc de
    
    ld a, (argc)
    dec a
    ret z

    ld hl, (argv + 3)
    ld de, FCB
    call ascciz_to_fcb

    ld a, (argc)
    dec a
    dec a
    ret z

    ld hl, (argv + 6)
    ld de, FCB + 16
    call ascciz_to_fcb

    ld a, (argc)
    dec a
    ld b, a
    
    ld ix, argv + 3
@copy1:
    ld hl, (ix)
@copy2:
    ld a, (hl)
    or a 
    jr z, @endcopy
    
    call uppercase
    ld (de), a

    push hl
    ld hl, BUFF
    inc (hl)
    pop hl

    inc hl
    inc de
    jr @copy2
@endcopy:
    ld a, ' '
    ld (de), a
    inc de

    push hl
    ld hl, BUFF
    inc (hl)
    pop hl

    inc ix
    inc ix
    inc ix
    djnz @copy1
    dec de
    xor a
    ld (de), a

    ld hl, BUFF
    dec (hl)
    ret    

; Converts ASCIIz to FCB
; HL - ASCIIz name
; DE - fcb ptr
ascciz_to_fcb:
    xor a
    ld (de), a

    inc de
    ld b, 8
@loop_name:
    ld a, (hl)

    and #7f
    jr z, @fill_zeros

    cp '.'
    jr z, @fill_zeros

    cp '*'
    jp z, @fill_mask

    call uppercase
    ld (de), a

    inc hl
    inc de
    djnz @loop_name
@fill_zeros:
    ld a, b
    and a 
    jr z, @ext_copy
    ld a, ' '
@zeros_loop:
    ld (de), a
    inc de
    djnz @zeros_loop
@ext_copy:
    ld a, (hl)
    cp '.'
    jr nz, @do_copy
    inc hl
@do_copy:
    ld b, 3
@ext_loop:
    ld a, (hl)

    and #7f
    jr z, @fin

    cp '*'
    jr z, @fill_mask2

    call uppercase
    ld (de), a
    inc hl
    inc de
    djnz @ext_loop
@fin:
    ld a, b
    and a
    ret z
    ld a, ' '
@fin_loop:
    ld (de), a
    inc de
    djnz @fin_loop
    ret
@fill_mask:
    inc hl
    ld a, b
    or a
    jr z, @ext_copy
    ld a, '?'
@mask_loop:
    ld (de), a
    inc de
    djnz @mask_loop
    jr  @ext_copy

@fill_mask2:
    ld a, b
    or a
    jr z, @ext_copy
    ld a, '?'
@mask_loop2:
    ld (de), a
    inc de
    djnz @mask_loop2
    ret


uppercase:
    cp 'a'
    jr c, @skip
    cp 'z' + 1
    jr nc, @skip
    and %01011111
@skip:
    ret

fcb_template:
    db 0    ; Drive
    db "           "
    db "           "
    db 0, 0, 0, 0

