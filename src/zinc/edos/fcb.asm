;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

;; ----------------------------------------------------------------------------

FCB_CR: equ $20  ; Current record
FCB_RC: equ $0F
FCB_EX: equ $0c  ; Current record extend 
FCB_S2: equ $0e  ; Extend high byte
FCB_S1: equ $0d  ; Reserved :-)
FCB_RN: equ $21

FCB_FP: equ $19

FCB_MAX_CR: equ $81
FCB_MAX_EX: equ $32
FCB_MAX_S2: equ $15

fcb_calc_offset:
    push ix
    ld ix, (args)
    ld h, $80
    ld l, (IX + FCB_CR)
    mlt hl

    ld a, (IX + FCB_EX)
    ld de, $4000
    or a
@check:
    jr z, @exit
    add.lil hl, de
    dec a
    jr @check
    ;; TODO: Calc S2 too
@exit:
    ld e, 0
    pop ix
    ret

calc_random_offset:
    push ix
    ld ix, (args)

    ld l, (IX + FCB_EX)
    ld h, $80
    mlt hl

    ld d, 0
    ld e, (IX + FCB_CR)

    add hl, de

    ld (ix + FCB_RN), hl

    pop ix
    xor a
    ret

; IX - FCB
fcb_next_record:
    push ix
    ld ix, (args)
    ld a, (ix + FCB_CR)
    inc a
    cp FCB_MAX_CR
    jr c, @write_cr

    ld a, 1
@write_cr:
    ld (ix + FCB_CR), a
    jr c, @exit

    ld a, (ix + FCB_EX)
    inc a
    cp FCB_MAX_EX 
    jr c, @write_ex

    xor a
@write_ex:
    ld (ix + FCB_EX), a
    jr c, @exit

    ld a, (ix + FCB_S2)
    inc a
    and FCB_MAX_S2
    ld (ix + FCB_S2), a
@exit:
    pop ix
    ret

; Converts FCB to ASCIIz filename
; HL - FCB pointer
; Output will be in 'dos_name' var
fcb_to_asciiz_name:
    inc hl
    push hl
    ld de, dos_name
    ld b, 8
@loop_name:
    ld a, (hl)
    and #7f
    cp ' '
    jr z, @ext
    ld (de), a
    inc hl
    inc de
    djnz @loop_name
@ext:
    pop hl
    ld bc, 8
    add hl, bc

    ld a, (hl)
    and #7f
    jr z, @fin
    
    ld a, '.'
    ld (de), a
    inc de
    ld b, 3
@loop_ext:
    ld a, (hl)
    and #7f
    cp ' '
    jr z, @fin
    ld (de), a
    inc hl
    inc de
    djnz @loop_ext
@fin:
    xor a
    ld (de), a
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

uppercase:
    cp 'a'
    jr c, @skip
    
    cp 'z' + 1
    jr nc, @skip

    and %01011111
@skip:
    ret