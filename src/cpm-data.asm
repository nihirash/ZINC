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

    ld b, a
    
    ld ix, argv + 3
@copy1:
    ld hl, (ix)
@copy2:
    ld a, (hl)
    or a 
    jr z, @endcopy
    
    cp 'a'
    jr c, @skip
    
    cp 'z' + 1
    jr nc, @skip

    and %01011111

@skip:
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


fcb_template:
    db 0    ; Drive
    db "           "
    db 0, 0, 0, 0

