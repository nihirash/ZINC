FCB:    equ $5005c ; default FCB placement
BUFF:   equ $50080

;; Prepare FCB on start application
prepare_fcb:
    ld hl, fcb_template

    push hl
    ld de, FCB
    ld bc, 16
    ldir
    pop hl

    ld bc, 16
    ldir
    
    ret    


fcb_template:
    db 0    ; Drive
    db "           "
    db 0, 0, 0, 0

