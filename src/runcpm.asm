;; ZINC is Not CP/M
;;
;; CP/M compatibility layer for Agon's MOS
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

    ASSUME ADL=1
;; Why? Because I can
MAX_ARGS: EQU 15

    org $40000
    jp _start
bye_ptr:
    jp exit

argc:
    db 0
argv:
    dl 0


    align 64
    db "MOS"    ;; HEADER
    db 0        ;; VERSION
    db 1        ;; ADL 

_start:
    push ix
    push iy
    ld (stack_save), sp

    ld ix,argv
	call _parse_args
	ld a,c
	ld (argc),a
    or a 
    jr z, no_args

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
@ext:
    ld hl, ext
    ldi
    ldi
    ldi
    ldi
    ldi


    ld de, $50100
    ld hl, path_buffer
    ld a, $01 ; mos_load
    rst.lil $08
    or a
    jp nz, open_error

    call prepare_vars

;;  emulation layer
    ld a, $5
    ld mb, a
    jp.sis $0

exit:
    ld sp, (stack_save)

    pop iy
    pop ix

    xor a
    ld mb, a

    ld hl, exit_msg
    ld bc, 4
    rst.lil $18

    xor a
    ld hl, 0
    ret
exit_msg:
    db 13, 10, 13, 10

no_args:
    ld hl, @msg
    jr error
@msg:
    db 13, 10, "Usage: ", 13, 10
    db "  runcpm <executable> <args>", 13, 10, 0

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

    align $10000
    incbin "edos/test.bin"