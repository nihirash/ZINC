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
    ld (dma_ptr),de
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

    ld a, (ffs_attr)
    and $10
    jr nz, catalog_scan_next
    
    ld a, (ffs_lfn)
    or a
    jp z, nope

    ld a, (mask)
    cp '?'
    jr z, scan_ok
    ;; TODO scan mask check
    jp scan_ok

nope:
    ld a, $ff
    ret

scan_ok:
    ld de, (dma_ptr)
    ld hl, ffs_lfn
    call ascciz_to_fcb

    xor a
    ret

mask:
    ds 12

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

path_buffer:
    ds $7f

DS_LEN: equ 4+4+4+3+12+4
dir_struct:
    ds DS_LEN

ffs_file_struct:
ffs_size:   ds  4
ffs_date:   ds  2
ffs_time:   ds  2
ffs_attr:   ds  1
ffs_name:   ds  13
ffs_lfn:    ds  256