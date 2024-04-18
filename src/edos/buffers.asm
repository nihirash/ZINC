;; I wish I'll have possibility doesn't include this part to final binary :-)

dir:
    ds 128

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

    ds 16
bios_stack:
    ds 32
stack: