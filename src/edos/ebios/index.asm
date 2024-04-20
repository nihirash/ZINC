;; EBIOS - Emulation BIOS. BIOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

    include "ebios/macro.asm"

;; BIOS have same layout as usual CP/M BIOS
;; It's required cause a lot of applications making direct calls 
;; to BIOS. And this is reason why it should be aligned.

BOOT:	JP	bye		
WBOOT:	JP	bye
CONST:	JP	bios_const
CONIN:	JP	bios_in
CONOUT:	JP	bios_out

LIST:	JP	nothing
PUNCH:	JP	nothing
READER:	JP	nothing

HOME:	JP	nothing
SELDSK:	JP	bios_seldsk
SETTRK:	JP	nothing
SETSEC:	JP	nothing
SETDMA:	JP	bios_dma
READ:	JP	direct      ;; Your app shouldn't call this function directly. NEVER
WRITE:	JP	direct      ;; Your app shouldn't call this function directly. NEVER
PRSTAT:	JP	nothing
SECTRN:	JP	nothing

nothing:
    ld a, $ff
    ret

direct:
    ld hl, @msg
    ld bc, 0
    xor a
    rst.lil $18
    jp bye
@msg:
    db 13, 10
    db "Direct disk reading/writing via BIOS aren't supported!", 13, 10
    db "Execution stopped", 13, 10, 0


init:
    ld sp, $ffff

    call init_dir

    ld hl, banner
    ld bc, 0
    xor a
    rst.lil $18

    MOSCALL MOS_SYS_VARS
    lea.lil hl, ix + 5 ;; ASCII KEYCODE
    ld.lil (keycode_ptr), hl

;; Cleaning last keypress on start - no waiting for key on start of some apps 
    xor a
    ld.lil (hl), a
    ld (TDRIVE), a

    ld a, $c3 ;; JP instruction
    
    ld (0), a
    ld hl, WBOOT
    ld (1), hl

    ld (5), a
    ld hl, entrypoint
    ld (6), hl

    ld bc, $80
    ld (dma_ptr), bc

    ld a, 1
    ld (IOBYTE), a

    call TPA
    jp bye

banner:
    db 13,10, 17, 1
    db "ZINC is Not CP/M", 13, 10, 17, 2
    db "(c) 2024 Aleksandr Sharikhin", 13, 10, 17, 15
    db 13, 10, 0

    include "ebios/console.asm"
    include "ebios/disk.asm"

keycode_ptr:
    dl 0

user_sp_ptr:
    dw $00


