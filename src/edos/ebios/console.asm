;; EBIOS - Emulation BIOS. BIOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

bios_const:
    ld.lil hl, (keycode_ptr)
    ld.lil a, (hl)
    or a 
    ret z

    ld a, $ff
    ret


bios_in:
;; You shouldn't use application stack(it will broke wordstar, for example)
;; So, using our BIOS-stack for all places where we'll need stack
    LOCALSP
@rep:
    MOSCALL MOS_GET_KEY
    or a
    jr z, @rep
    
    ld c, a
    
    xor a 
    ld.lil hl, (keycode_ptr)
    ld.lil (hl), a

    ld a, c
    RESTORESP
    ret

bios_out:
    LOCALSP
    ld a, c
    rst.lil $10
    RESTORESP
    ret