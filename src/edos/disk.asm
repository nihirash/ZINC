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

;; Calculation file lenght 
;; Routine works not very correct, but many CP/M emulators skip this step
;; Honestly, not most necessary part of this project :-)
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
    
    ld (ix + FCB_RC), a

    ld hl, (ffs_size + 1)
    ld a, (ffs_size)
    add a, a
    adc hl, hl

    add a, a
    adc hl, hl

    ld a, h
    and 31
    ld (ix + FCB_EX), a

    xor a
    ret

mask:
    db "????????????"

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
    ld hl, (args)
    ld de, FCB_FP
    add hl, de
    ld a, (hl)

    or a
    jr z, @skip
    call fclose
@skip:

    ld hl, (args)
    call fcb_to_asciiz_name

    ld hl, dos_name
    ld c, FA_READ + FA_WRITE
    MOSCALL MOS_FOPEN

    or a
    jr z, @err

    ld hl, (args)
    ld de, FCB_FP
    add hl, de
    ld (hl), a

    xor a
    ret
@err:
    ld a, #ff
    ret

frename:
    ld hl, (args)
    call fcb_to_asciiz_name
    
    ld hl, dos_name
    ld de, old_dos_name
    ld bc, 12
    ldir

    ld hl, (args)
    ld de, 16
    add hl, de
    call fcb_to_asciiz_name

    ld.lil hl, old_dos_name
    ld.lil de, dos_name
    MOSCALL MOS_RENAME     
    or a 
    ret z

    ld a, #ff
    ret

fcreate:
    ld hl, (args)
    ld de, FCB_FP
    add hl, de
    ld a, (hl)

    or a
    jr z, @skip
    call fclose
@skip:
    ld hl, (args)

    call fcb_to_asciiz_name
    
    ld hl, dos_name
    ld c, FA_READ + FA_WRITE + FA_CREATE
    MOSCALL MOS_FOPEN

    or a
    jr z, @err

    ld hl, (args)
    ld de, FCB_FP
    add hl, de
    ld (hl), a

    xor a
    ret
@err:
    ld a, #ff
    ret

fclose:
    ld de, (args)
    ld hl, FCB_FP
    add hl, de
    ld a, (hl)
    or a 
    ret z

    ld c, a
    MOSCALL MOS_FCLOSE
    
    xor a
    ld (hl), a
    ret

fdelete:
    ex de, hl
    call fcb_to_asciiz_name
    ld hl, dos_name
    MOSCALL MOS_DELETE
    ret

;; Random write
fwrite_rnd:
    call set_rnd_offset
    jr do_write

;; Sequental write
fwrite:
    ld hl, FCB_FP
    add hl, de
    ld a, (hl)
    ld c, a

    call fcb_calc_offset
do_write:
    MOSCALL MOS_FSEEK

    ld.lil hl, (dma_ptr)
    ld de, $80
    MOSCALL MOS_FWRITE

    call fcb_next_record

    ld hl, 0
    ld bc, 0
    xor a
    ret

clean_dma:
    ld de, (dma_ptr)
    ld hl, 1
    add hl, de
    ex de, hl    

    ld bc, $7f
    ld a, $1a
    ld (hl), a
    ldir

    ret

set_rnd_offset:
    ld de, (args)
    ld hl, FCB_FP
    add hl, de
    ld a, (hl)
    ld c, a

    ld de, (args)
    ld hl, FCB_RN
    add hl, de
    ld hl, (hl)

    add.lil hl, hl ; *2
    add.lil hl, hl ; *4
    add.lil hl, hl ; *8
    add.lil hl, hl ; *16
    add.lil hl, hl ; *32
    add.lil hl, hl ; *64
    add.lil hl, hl ; *128
    ld de, 0
    ret

;; Random read
fread_rnd:
    call clean_dma
    call set_rnd_offset

    jr read_offset

;; Sequental read
fread:
    call clean_dma
    
    ld de, (args)
    ld hl, FCB_FP
    add hl, de
    ld a, (hl)
    ld c, a

    call fcb_calc_offset
read_offset:
    MOSCALL MOS_FSEEK

    ld.lil hl, (dma_ptr)
    ld de, $80
    MOSCALL MOS_FREAD

    ld a, d
    or e
    ld a, $1
    ret z

    call fcb_next_record
    xor a
    ret

;; DE - FCB
calc_size:
    ex de, hl
    call fcb_to_asciiz_name

    ld.lil de, dos_name
    ld.lil hl, ffs_file_struct
    MOSCALL MOS_FSTAT
    or a
    jr nz, @nope

    ld.lil hl, (ffs_size)
    add.lil hl, hl
    
    ld a, l
    and $7f
    jr z, @skip

    ld de, $100
    add.lil hl, de
@skip:
    ld.lil (@buff), hl

    ld hl, (args)
    ld de, FCB_RN
    add hl, de

    ld de, (@buff + 1)
    ld (hl), de 
    xor a
    ret
@nope:    
    ld a, $ff
    ret
@buff:
    dl 0
