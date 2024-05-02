;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

;; This file contains internal variables and buffers for ZINC
;; They shouldn't be included in final binary and they all undefined by default

dir:
    ds 128

dos_name:
    ds 12

;; Used for renaming
old_dos_name:
    ds 12

tmp_fcb:
    ds $10

path_buffer:
    ds $7f

DS_LEN: equ 31
dir_struct:
    ds DS_LEN

ffs_file_struct:
ffs_size:   ds  4
ffs_date:   ds  2
ffs_time:   ds  2
ffs_attr:   ds  1
ffs_name:   ds  13
ffs_lfn:    ds  256

    ds 32
bios_stack:

    ds 64
stack: