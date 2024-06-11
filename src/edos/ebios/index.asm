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

LIST:	JP	list
PUNCH:	JP	nothing
READER:	JP	reader

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

list:
    LOCALSP
    
    ld a, c
    ld (@char), a
    ld hl, @vdu
    ld bc, 4
    rst.lil $18

    RESTORESP
    ret
@vdu:
    db 2, 1
@char:
    db 0
    db 3

reader:
    ld a, 26
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

    ld bc, DEFDMA
    ld (dma_ptr), bc

    ld a, 1
    ld (IOBYTE), a

    call TPA
    jp bye

banner:
    db 4
    db 13,10, 17, 1
    db "ZINC is Not CP/M", 13, 10, 17, 2
    db "(c) 2024 Aleksandr Sharikhin", 13, 10, 17, 15
    db "This version was built: "
    incbin "../../.version"
    db 13, 10, 0

    include "ebios/console.asm"
    include "ebios/disk.asm"


user_sp_ptr:
    dw $00


