;; ZINC is Not CP/M
;;
;; CP/M compatibility layer for Agon's MOS
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

uart_setup:
    PRINTZ should_setup_uart
    call yes_no
    ret z ;; Don't want setup UART

    PRINTZ uart_speed_msg

speed_conf:
    MOSCALL MOS_GET_KEY
    
    cp '1'
    jr c, speed_conf

    cp '9'
    jr nc, speed_conf

    sub '0'

    cp 1
    ld hl, uart_speed1 + 4
    ld de, 115200
    jp z, @speed_ok

    cp 2
    ld hl, uart_speed2 + 4
    ld de, 57600
    jp z, @speed_ok

    cp 3
    ld hl, uart_speed3 + 4
    ld de, 38400
    jp z, @speed_ok

    cp 4
    ld hl, uart_speed4 + 4
    ld de, 19200
    jp z, @speed_ok

    cp 5
    ld hl, uart_speed5 + 4
    ld de, 9600
    jp z, @speed_ok

    cp 6
    ld hl, uart_speed6 + 4
    ld de, 4800
    jp z, @speed_ok

    cp 7
    ld hl, uart_speed7 + 4
    ld de, 2400
    jp z, @speed_ok

    ld hl, uart_speed8 + 4
    ld de, 1200

@speed_ok:
    ld (serial_speed), de
    ld bc, 0
    ld a, ' '
    rst.lil $18

    PRINTZ uart_bits_msg
bits_conf:
    MOSCALL MOS_GET_KEY
    
    cp '1'
    jr c, bits_conf

    cp '4'
    jr nc, bits_conf

    sub '0'

    cp 1
    ld c, 8
    ld hl, uart_bits1 + 4
    jr z, @bits_ok

    cp 2
    ld c, 7
    ld hl, uart_bits2 + 4
    jr z, @bits_ok

    ld c, 5
    ld hl, uart_bits3 + 4

@bits_ok:
    ld a, c
    ld (serial_bits), a

    ld bc, 0
    ld a, ' '
    rst.lil $18

    PRINTZ uart_stopbits_msg
uart_stopbits_conf:
    MOSCALL MOS_GET_KEY
    
    cp '1'
    jr c, uart_stopbits_conf

    cp '3'
    jr nc, uart_stopbits_conf

    sub '0'

    ld hl, uart_stop_bits1 + 4
    cp 1
    jr z, @uart_stopok

    ld hl, uart_stop_bits2 + 4
@uart_stopok:
    ld (serial_stop_bits), a

    ld bc, 0
    ld a, ' '
    rst.lil $18

    PRINTZ uart_parity_msg
uart_parity_conf:
    MOSCALL MOS_GET_KEY
    
    cp '1'
    jr c, uart_parity_conf

    cp '4'
    jr nc, uart_parity_conf

    sub '1'

    ld hl, uart_parity1 + 4
    or a
    jr z, @parity_ok

    ld hl, uart_parity2 + 4
    cp 1
    jr z, @parity_ok

    ld hl, uart_parity3 + 4

@parity_ok:
    ld (serial_parity_control), a
    
    ld bc, 0
    ld a, ' '
    rst.lil $18

    PRINTZ uart_done

    call yes_no
    ret nz
     
    jp uart_setup
    
should_setup_uart:
    db 13, 10
    db "Do you want configure UART parameters? (Y/N) ", 0

uart_speed_msg:
    db 13, 10
    db "Select UART speed:", 13, 10
uart_speed1:
    db " 1) 115200", 13, 10
uart_speed2:
    db " 2) 57600",  13, 10
uart_speed3:
    db " 3) 38400",  13, 10
uart_speed4:
    db " 4) 19200",  13, 10
uart_speed5:
    db " 5) 9600",   13, 10
uart_speed6:
    db " 6) 4800",   13, 10
uart_speed7:
    db " 7) 2400",   13, 10
uart_speed8:
    db " 8) 1200",   13, 10
    db 13, 10
    db "Selected speed: "
    db 0

uart_bits_msg:
    db 13, 10, 13, 10
    db "Select UART data bits count:", 13, 10
uart_bits1:    
    db " 1) 8", 13, 10
uart_bits2:
    db " 2) 7", 13, 10
uart_bits3:
    db " 3) 5", 13, 10
    db 13, 10
    db "Selected data bits count: "
    db 0


uart_stopbits_msg:
    db 13, 10, 13, 10
    db "Select UART stop bits count: ", 13, 10

uart_stop_bits1:
    db " 1) 1", 13, 10
uart_stop_bits2:
    db " 2) 2", 13, 10

    db 13, 10
    db "Selected stop bits count: "
    db 0

uart_parity_msg:
    db 13, 10, 13, 10
    db "Select UART parity bits count:", 13, 10
uart_parity1:
    db " 1) None", 13, 10
uart_parity2:
    db " 2) Odd", 13, 10
uart_parity3:
    db " 3) Even", 13, 10
    db 13, 10
    db "Selected parity bits count: "
    db 0

uart_done:
    db 13, 10, 13, 10
    db "UART settings was configured!", 13, 10
    db 13, 10
    db "Do you want keep them? (Y/N) "
    db 0