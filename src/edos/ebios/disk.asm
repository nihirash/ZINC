bios_seldsk:
    ld hl, dph
    ret

bios_dma:
    ld (dma_ptr), bc
    ret

dph:
    dw 0
    dw 0, 0, 0
    dw dir
    dw dpb
    dw 0
    dw 0

dpb:
    dw 64
    db 4
    db 15
    dw $ffff
    dw $1023
    db $ff, 0
    db 0, 0, 0, 0


dir:
    ds 128