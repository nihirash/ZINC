UART_LSR_ETX:	EQU $40
UART_LSR_ETH:	EQU $20
UART_LSR_RDY:	EQU $01

UART_STATUS_REG:    EQU     $D5
UART_DATA_REG:      EQU     $D0

uart_init:
	ld ix, serial_cfg
	MOSCALL MOS_UOPEN
    ret

uart_status:
	in0 a, (UART_STATUS_REG)
	and UART_LSR_RDY
	ld l, a
	ret.lil z
    
	ld a, $ff
	ld l, a
	ret.lil    

uart_in:
	in0 a, (UART_STATUS_REG)
	and UART_LSR_RDY
	jr z, uart_in

	in0 a, (UART_DATA_REG)
    ret.lil

uart_out:
    in0 a, (UART_STATUS_REG)
	and UART_LSR_ETX
	jr z, uart_out

	ld a, c
	out0 (UART_DATA_REG), a

	xor a
	ret.lil

