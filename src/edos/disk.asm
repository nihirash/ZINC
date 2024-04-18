;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

get_drives:
    ld hl,1
    ret

get_drive:
    xor a
    ret

set_dma:
    ld (dma_ptr), de
    ret

get_dpb:
    ld hl, dpb
    ret

catalog_get_first:
    ld hl, mask
    ex de, hl
    ld bc, 12
    ldir

    ld hl, dir_struct
    MOSCALL MOS_CLOSEDIR

    call init_dir
catalog_scan_next:
    ld hl, dir_struct
    ld de, ffs_file_struct
    MOSCALL MOS_READDIR

    ld a, (ffs_lfn)
    or a
    jp z, nope

    ld a, (ffs_attr)
    and $10 ;; ATTR_DIR
    jr nz, catalog_scan_next

    ld hl, mask
    ld a, (hl)
    cp '?'
    jr z, scan_ok
    
    ld de, tmp_fcb
    ld hl, ffs_lfn
    call ascciz_to_fcb

    ;; Mask check
    ld hl, mask + 1
    ld de, tmp_fcb + 1

    ld b, 11
@chk_msk:
    ld a, (hl)
    and $7f
    cp '?'
    jr z, @masked

    ld c, a
    ld a, (de)
    cp c

    jr nz, catalog_scan_next
@masked:
    inc hl
    inc de
    djnz @chk_msk

    jr scan_ok

nope:
    ld a, $ff
    ret

scan_ok:
    ld de, (dma_ptr)
    ld hl, ffs_lfn
    call ascciz_to_fcb

;; Routine for calcing EX/RC
;; Looks like working :) 
;; Without promises
    xor a
    ld b, a
    
    ld ix, (dma_ptr)

    ld hl, (ffs_size)

    ld a, h
    and $3f ;; Limit with 16k 
    ld h, a

    add hl, hl
    ld a, h

    and $7f
    
    ld (ix + $0f), a
    

    ld hl, (ffs_size + 1)
    ld a, (ffs_size)
    add a, a
    adc hl, hl

    add a, a
    adc hl, hl

    ld a, h
    and 31
    ld (ix + $0C), a

    xor a
    ret

mask:
    ds 12, '?'

init_dir:
    ld hl, path_buffer
    ld bc, $7f
    MOSCALL MOS_CWD

    ld hl, dir_struct
    ld de, dir_struct + 1
    ld bc, DS_LEN - 1
    xor a 
    ld (hl), a
    ldir

    ld hl, dir_struct
    ld de, path_buffer
    MOSCALL MOS_OPENDIR
    ret

fopen:
    ex de, hl
    push hl
    call fcb_to_asciiz_name
    ld hl, dos_name
    ld c, FA_READ + FA_WRITE
    MOSCALL MOS_FOPEN

    or a
    jr z, @err
    pop hl
    ld de, FCB_S1
    add hl, de
    ld (hl), a

    xor a
    ret
@err:
    pop hl
    ld a, #ff
    ret


fcreate:
    ex de, hl
    push hl
    call fcb_to_asciiz_name
    ld hl, dos_name
    ld c, FA_READ + FA_WRITE + FA_CREATE
    MOSCALL MOS_FOPEN

    or a
    jr z, @err
    pop hl
    ld de, FCB_S1
    add hl, de
    ld (hl), a

    xor a
    ret
@err:
    pop hl
    ld a, #ff
    ret

fclose:
    ld hl, FCB_S1
    add hl, de
    ld a, (hl)
    ld c, a
    MOSCALL MOS_FCLOSE
    ret

fdelete:
    ex de, hl
    call fcb_to_asciiz_name
    ld hl, dos_name
    MOSCALL MOS_DELETE
    ret

fwrite:
    ld hl, FCB_S1
    add hl, de
    ld a, (hl)
    ld c, a

    ld.lil hl, ($50000 + dma_ptr)
    ld de, 128
    MOSCALL MOS_FWRITE
    
    ld hl, (args)
    ld bc, FCB_CR
    add hl, bc
    inc (hl)

    xor a
    ret

fread:
    ld hl, FCB_S1
    add hl, de
    ld a, (hl)
    ld c, a

    ld.lil hl, ($50000 + dma_ptr)
    ld de, 128
    MOSCALL MOS_FREAD

    ld a, d
    or e
    ld a, 1
    ret z
@ok:
    ld hl, (args)
    ld bc, FCB_CR
    add hl, bc
    inc (hl)

    xor a
    ret

