;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

;;; This trace placeholder allows detect necessary for applications entrypoints
trace:
    ld a, (fun)
    call num_to_hex
    ld (@fun), de

    ld a, (args + 1)
    call num_to_hex
    ld (@params), de
    
    ld a, (args)
    call num_to_hex
    ld (@params + 2), de
    
    ld hl, @msg
    ld bc, 0
    xor a
    rst.lil $18
    
    xor a
    ld l, a
    ld h, a

    ret
@msg:
    db 13, 10, "[!NOT IMPLEMENTED BDOS CALL!] Called function: "
@fun:
    dw $00
    db " with parameters: "
@params:
    ds 4
    db 13, 10
    db 0


num_to_hex:
    ld c, a
    call @num
    ld e, a
    ld a, c
    call @num2
    ld d, a
    ret
@num:
    rra
    rra
    rra
    rra
@num2:
    or $f0
    daa
    add a, $a0
    adc a, $40
    ret