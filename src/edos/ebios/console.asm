;; EBIOS - Emulation BIOS. BIOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved


;; Single source of truth is better 
keycode:
    db 0

bios_const:
    ld.lil hl, (keycount_ptr)
    ld.lil a, (hl)
    and a
    ret z

    ld.lil hl, (keydown_ptr)
    ld.lil a, (hl)
    and a
    ret z

    ld.lil hl, (keycode_ptr)
    ld.lil a, (hl)
    and $7f
    ld (keycode), a
    ret z

    ld a, $ff
    ret

bios_in:
;; You shouldn't use application stack(it will broke wordstar, for example)
;; So, using our BIOS-stack for all places where we'll need stack
    LOCALSP
@rep:
    call bios_const
    and a
    jr z, @rep
    
    xor a
    ld.lil hl, (keydown_ptr)
    ld.lil (hl), a

    ld a, (keycode)
    cp $15
    jr nz, @ok

    ld a, CNTRLL

@ok:

    RESTORESP
    ret

bios_out:
    LOCALSP
    ld a, c
    call.lil ZINC_TERMOUT
    RESTORESP
    ret