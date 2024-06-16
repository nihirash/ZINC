;; ZINC is Not CP/M
;;
;; CP/M compatibility layer for Agon's MOS
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved


;; This file is entry point from MOS

;; ----------------------------------------------------------------------------

    include "config.asm"
    include "edos/mos.asm"

    ASSUME ADL=1
MAX_ARGS: EQU 15

    org ZINC_BASE
    jp _start
bye_ptr:
    jp exit
    jp termout
    jp termstatus
    jp termin

argc:
    db 0
argv:
    dl 0


    align 64
    db "MOS"    ;; HEADER
    db 0        ;; VERSION
    db 1        ;; ADL 


;; ----------------------------------------------------------------------------

_start:
    push ix
    push iy
    ld (stack_save), sp

    ld ix,argv
    call _parse_args
    ld a,c
    ld (argc), a
    or a 
    jp z, no_args

    ;; building file name for executable
    ld hl, (argv)
    ld de, path_buffer
@copy:
    ld a, (hl)
    or a
    jr z, @ext

    ld (de), a
    inc hl
    inc de

    jr @copy

    ;; Appending '.com' extension
@ext:
    ld hl, ext
    ldi
    ldi
    ldi
    ldi
    ldi

    ;; Cleanup vars area
    xor a 
    ld hl, EDOS_BASE
    ld de, EDOS_BASE + 1
    ld bc, $ff
    ld (hl), a
    ldir

    ;; Loading executable
    ld de, EDOS_TPA
    ld hl, path_buffer
    MOSCALL MOS_LOAD
    or a
    jp nz, open_error

    ;; Forming FCBs and DMA buffer with arguments
    call prepare_vars

    ;; Coping EDOS to selected 64K window  
    ld hl, os
    ld de, EDOS_ORG
    ld bc, end_of_os - os
    ldir

    call close_all
    call term_init

    ;;  Setting base address for legacy mode
    ld a, EDOS_PAGE
    ld mb, a
    ;;  Jumping into EDOS
    jp.sis EDOS_ORG + $3

;; ----------------------------------------------------------------------------

close_all:
    ;; Close all opened files
    ld c, 0
    ld a, 0x0b
    rst.lil $08
    ret

exit:
    call close_all
    di
    xor a
    ld mb, a

    call term_free
    ;; Restoring stack
    ld sp, (stack_save)

    pop iy
    pop ix

    ;; Cause we're in ADL mode - MB should be restored to zero value

    ld hl, exit_msg
    ld bc, 0
    xor a
    rst.lil $18
    
    ;; No errors happens, I wish 
    ld hl, 0
    ei
    ret
exit_msg:
    db 13, 10
    db "Returning to MOS..."
    db 13, 10, 13, 10, 0

no_args:
    ld hl, @msg
    jr error
@msg:
    db 13, 10, "Usage: ", 13, 10
    db "  zinc <executable> <args>", 13, 10, 0

open_error:
    ld hl, @msg
    jr error
@msg:
    db 13, 10, 17, 1
    db "Cannot read executable file!", 17, 15
    db 13, 10, 0

error:
    ld bc, 0
    xor a
    rst.lil $18
    jp exit

_parse_args:
    call _skip_spaces
    ld bc,0
    ld b,MAX_ARGS
_parse1:
    push bc
    push hl
    call _get_token
    ld a,c
    pop de
    pop bc
    and a
    ret z

    ld (ix+0),de
    push hl
    pop de
    call _skip_spaces
    xor a
    ld (de),a
    inc ix
    inc ix
    inc ix
    inc c
    ld a, c
    cp b
    jr c,_parse1
    ret

_get_token:
    ld c,0
@loop:
    ld a,(hl)
    or a
    ret z

    cp 13
    ret z

    cp 32
    ret z

    inc hl
    inc c
    
    jr @loop

_skip_spaces:
    ld a,(hl)
    cp 32
    ret nz
    inc hl
    jr _skip_spaces

ext:
    db ".com",0

path_buffer:
    ds 13

stack_save:  dl 0

    include "cpm-data.asm"
    include "terminal.asm"
    include "uart.asm"

os:
    incbin "edos/edos.bin"
end_of_os:

    include "options.asm"