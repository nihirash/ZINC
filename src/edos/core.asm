;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin

;; CP/M 2.2 is $22
;; Personal CP/M-80 is $28
;; Let be ZINC is $29. 
;; Cause compatibility target will be 2.x line but it's totally new version
DOSVER:     equ $29

TDRIVE:     equ $04
IOBYTE:     equ $03
TFCB:       equ $5c


NFUNC:      equ 40

TPA:        equ $100

CNTRLC:     equ $03
CNTRLE:     equ $05
BS:         equ $08
TAB:        equ $09
LF:         equ $0A
CR:         equ $0D
    
    include "mos.asm"

;; "BDOS" entrypoint - routing functions 
entrypoint:
    ld a, c
    ld (fun), a
    cp NFUNC
    ret nc

    di
    ld (user_stk), sp
    ld sp, stack
    ei

    ld hl, bdos_return
    push hl

    ld (args), de

    ld b, 0 
    ld hl, fun_table
    add hl, bc
    add hl, bc

    ld e, (hl)
    inc hl
    ld d, (hl)

    ld hl, (args)
    ex de, hl
    
    ld c, e
    jp (hl)


bdos_return:
    di
    ld sp, (user_stk)
    ei
    ret

fun_table:
    dw bye                  ; 00  Reset
    dw console_in           ; 01  Console in
    dw console_out          ; 02  Console out
    dw trace                ; 03  Aux read
    dw trace                ; 04  Aux write
    dw trace                ; 05  Printer write
    dw raw_io               ; 06  Raw IO
    dw get_io_byte          ; 07  Get IO Byte
    dw set_io_byte          ; 08  Set IO Byte
    dw write_str            ; 09  PrintStr$
    dw read_buf             ; 10  Buffered read
    dw CONST                ; 11  Console status
    dw dos_ver              ; 12  CP/M Version
    dw do_nothing           ; 13  Reset disks
    dw do_nothing           ; 14  Set drive
    dw trace                ; 15  fopen
    dw trace                ; 16  fclose
    dw catalog_get_first    ; 17  First in directory
    dw catalog_scan_next    ; 18  Next record in directory
    dw trace                ; 19  Delete file
    dw trace                ; 20  fread
    dw trace                ; 21  fwrite
    dw trace                ; 22  fcreate
    dw trace                ; 23  frename
    dw get_drives           ; 24  bitmap of drives
    dw get_drive            ; 25  current drive
    dw set_dma              ; 26  set DMA
    dw do_nothing           ; 27  Get alloc bitmap
    dw do_nothing           ; 28  Write protect drive
    dw do_nothing           ; 29  Get read only drives vector
    dw do_nothing           ; 30  Set file attributes
    dw get_dpb              ; 31  Get DPB address
    dw do_nothing           ; 32  Get user area
    dw trace                ; 33  Random read
    dw trace                ; 34  Random write
    dw trace                ; 35  Compute file size
    dw trace                ; 36  Update random access pointer
    dw do_nothing           ; 37  reset selected disks
    dw do_nothing           ; 38  not used in CP/M 2.2
    dw do_nothing           ; 39  not used in CP/M 2.2
    dw trace                ; 40  fill random access block with zeros
    dw do_nothing           ; 41

bye:
    jp.lil $40004

do_nothing:
    xor a
    ld hl, 0
    ret

dos_ver:
    xor a
    ld h, a
    ld b, a
    ld a, DOSVER
    ld l, a
    ld c, a
    ret

    include "console.asm"
    include "trace.asm"
    include "fcb.asm"
    include "disk.asm"

fun:        db $00
args:       dw $00
dma_ptr:    dw $00
user_stk:   dw $00

    align $100
    include "ebios/index.asm"

    ds $100
stack: