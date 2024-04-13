;; EBIOS - Emulation BIOS. BIOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

    include "ebios/macro.asm"

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
READ:	JP	direct
WRITE:	JP	direct
PRSTAT:	JP	nothing
SECTRN:	JP	nothing

nothing:
    ld a, $ff
    ret

direct:
    LOCALSP
    ld hl, @msg
    ld bc, 0
    xor a
    rst.lil $18
    xor a
    RESTORESP
    ret
@msg:
    db 13, 10, "Unsupported direct BIOS call happens", 13, 10, 0


init:
    ld sp, $ffff

    ld hl, banner
    ld bc, 0
    xor a
    rst.lil $18

    MOSCALL MOS_SYS_VARS
    lea.lil hl, ix + 5 ;; ASCII KEYCODE
    ld.lil (keycode_ptr+$50000), hl

    xor a
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
    jp.lil $40004

banner:
    db 13,10
    db "ZINC is Not CP/M", 13, 10
    db "(c) 2024 Aleksandr Sharikhin", 13, 10
    db 13, 10, 0

    include "ebios/console.asm"
    include "ebios/disk.asm"

keycode_ptr:
    ds 3

user_sp_ptr:
    dw $00

    ds 64
bios_stack:

