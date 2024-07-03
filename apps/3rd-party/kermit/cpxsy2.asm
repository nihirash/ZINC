IF NOT lasm
.printx * CPXSY2.ASM *
ENDIF	;NOT lasm
;       KERMIT - (Celtic for "FREE")
;
;       This is the CP/M-80 implementation of the Columbia University
;       KERMIT file transfer protocol.
;
;       Version 4.0
;
;       Copyright June 1981,1982,1983,1984,1985
;       Columbia University
;
; Originally written by Bill Catchings of the Columbia University Center for
; Computing Activities, 612 W. 115th St., New York, NY 10025.
;
; Contributions by Frank da Cruz, Daphne Tzoar, Bernie Eiben,
; Bruce Tanner, Nick Bush, Greg Small, Kimmo Laaksonen, Jeff Damens, and many
; others.
;
;       This file contains the system-dependent code and data for KERMIT.
;       It will be probably be broken into independent files to generate
;       overlays for the various systems, one or more overlay possible
;       from each file.  For now, we will leave it in one piece.
;
; revision history:
;
;
;       This is the system-dependent command to change the baud rate.
;       DE contains the two-byte value from the baud rate table; this
;       value is also stored in 'speed'.
sysspd:


IF px8 ; [29]
        push    d
        call    rsclose        ; baud rate can only be set on opening rs232
        pop     d
        mov     a, e
        sta     px8blk+4       ; set param block
        call    rsopen         ; to set rate
        ret
ENDIF ; px8 [29]

; Set the speed for the Osborne I
IF osbrn1
        mvi     a,osbin1        ;Reset the ACIA
        call    osstst          ;Write the control port
osbs1:  inr     c               ;Waiting loop
        jnz     osbs1
        mov     a,e             ; get the specified speed
        jmp     osstst          ;Write the control reg.
ENDIF;osbrn1

;[hh] set the speed for a lobo MAX-80
IF lobo
        mov     a,e             ;[hh] get the parsed value
setbd:  sta     baudrt          ;[hh] and send it to the baud rate port
        ret                     ;[hh]
ENDIF;lobo

; Set the speed for bigboard I or the delphi or the CPT-85xx
; or Cromemco (TU-ART)
IF delphi OR cpt85xx OR cmemco OR mmate ;[22] [29]
        mov     a,e             ; get the parsed value
        out     baudrt          ; Tell the baud rate generator.
        ret
ENDIF;delphi OR cpt85xx OR cmemco OR mmate [22] [29]

;[22] Set the speed for Acorn BBC
IF bbc
        mov     l,e
        mvi     a,7             ;Set receive baud rate
        call    osbyte          ;*FX7,?e
        mov     l,e
        mvi     a,8             ;Set transmit baud rate
        call    osbyte          ;*FX8,?e
        ret
ENDIF;[22] bbc

;[22] Set speed for RM 380Z
IF rm380z
        mvi     a,4             ;device type (SI/O4) in A
        rst     6               ; EMT
        db      29h             ;     SETLST
        ret
ENDIF;[22] rm380z

; Set the speed for MicroMikko.  DE is baud rate multiplier
IF mikko
        di
        lxi     h,txclk
        mov     m,d             ;LSB first (swapped in memory)
        mov     m,e             ;MSB last
        lxi     h,rxclk
        mov     m,d
        mov     m,e
        mvi     b,0             ;"modifier" for 1 stop bit
        mvi     a,2             ;Test MSB of speed >2 (110 bps or less)
        cmp     e
        jp      miksp1
        mvi     b,00001000B     ;"modifier" for 2 stop bits
miksp1: mvi     a,4             ;Select SIO Reg 4
        lxi     h,sioac
        mov     m,a
        mvi     a,sion4         ;Get values
        ora     b               ;Add modifier
        mov     m,a             ;Set value (stop bits)
        ei
        ret
ENDIF;mikko


; Set the speed for the Decision I
IF mdI
        call    selmdm          ;Let's be absolutely sure, huh?
        mvi     a,dlab+wls1+wls0+stb ;Set data latch access bit
        out     lcr             ;Out to Line Control Register
        lhld    speed           ;Load baudrate multiplier
        xchg
        mov     a,d             ;Get low order byte for baud rate
        out     dlm             ;Out to the MSB divisor port
        mov     a,e             ;...and the high order byte
        out     dll             ;Out to the LSB divisor port
        mvi     a,wls1+wls0+stb ;Enable Divisor Access Latch
        out     lcr             ;Out to ACE Line Control Register
        xra     a               ;Clear A
        out     ier             ;Set no interrupts
        out     lsr             ;Clear status
        in      msr             ;Clear Modem Status Register
        in      lsr             ;Clear Line Status Register
        in      rbr             ;Clear Receiver Buffers
        in      rbr
        ret
ENDIF   ;mdI    [Toad Hall]

IF teletek
	di
	mov	a,e		; first speed byte
	out	baudrt
	mov	a,d		; second speed byte
	out	baudrt
	ei
	ret
ENDIF	;teletek

IF access       ;[29]
        mov     a,e             ;Get the parsed time constant
;The following code is derived from the Access  initialization code
        sta     savspd          ;Save  the time constant
        mvi     a,14h           ;Code for 'monitor' to set channel A baudrate
        call    monitor
        lda     savspd          ;Get the time constant
        call    monitor         ; and send it to the CRT
        ret
savspd: ds      1
monitor:                        ;Routine to do CRT functions
        out     90h             ;Output the data to the CRT
        mvi     a,1             ;Set DRDY true
        out     23h
mon1:   in      0a0h            ;Wait for CACK* true
        rlc
        jc      mon1
        in      80h             ;Read the input data latch
        push    psw             ;Save the input data
        xra     a               ;Set DRDY false
        out     23h
mon2:   in      0a0h            ;Wait for CACK* false
        rlc
        jc      mon2
        pop     psw
        sta     0ee02h          ;Save the input data
        ret
ENDIF;access [29]


IF disc ;[29]
; Assuming that parsing of value from speed table puts low order
; byte of time constant in the e register and high byte in d.
        mvi     a,12            ;Register 12
        out     mnprts
        mov     a,e             ;Low order byte of time constant
        out     mnprts
        mvi     a,13            ;Register 13
        out     mnprts
        mov     a,d             ;High order byte of time constant
        out     mnprts
        mvi     a,14            ;Register 14
        out     mnprts
        mvi     a,3             ;Enable baud rate generator
        out     mnprts
        mvi     a,11            ;Register 11
        out     mnprts
        mvi     a,52h           ;no Xtal, tclk=rclk=/trxc out=br gen
        out     mnprts
        ret
ENDIF;disc [29]
;       Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.

;       db      string length,string,divisor (2 identical bytes or 1 word)
; [Toad Hall]

IF delphi OR lobo    ;[hh]
spdtbl: db      10h                     ;16 entries
        db      03h,'110$',     02h,02h
        db      04h,'1200$',    07h,07h
        db      05h,'134.5$',   03h,03h
        db      03h,'150$',     04h,04h
        db      04h,'1800$',    08h,08h
        db      05h,'19200$',   0fh,0fh
        db      04h,'2000$',    09h,09h
        db      04h,'2400$',    0ah,0ah
        db      03h,'300$',     05h,05h
        db      04h,'3600$',    0bh,0bh
        db      04h,'4800$',    0ch,0ch
        db      02h,'50$',      00h,00h
        db      03h,'600$',     06h,06h
        db      04h,'7200$',    0dh,0dh
        db      02h,'75$',      01h,01h
        db      04h,'9600$',    0eh,0eh

sphtbl: db      cr,lf,'   50     75    110    134.5  150    300    600   1200'
        db      cr,lf,' 1800   2000   2400   3600   4800   7200   9600  19200$'
ENDIF;delphi OR lobo    ;[hh]

IF cpt85xx
spdtbl: db      15                      ; 15 entries
        db      03,'110$',      03h,03h
        db      04,'1200$',     09h,09h
        db      05,'134.5$',    04h,04h
        db      03,'150$',      05h,05h
        db      04,'1800$',     0Ah,0Ah
        db      04,'2400$',     0Bh,0Bh
        db      03,'300$',      06h,06h
        db      04,'3600$',     0Ch,0Ch
        db      04,'4800$',     0Dh,0Dh
        db      02,'50$',       01h,01h
        db      03,'600$',      07h,07h
        db      04,'7200$',     0Eh,0Eh
        db      02,'75$',       02h,02h
        db      03,'900$',      08h,08h
        db      04,'9600$',     0Fh,0Fh

sphtbl: db      cr,lf,'   50     75    110    134.5  150    300    600    900'
        db      cr,lf,' 1200   1800   2400   3600   4800   7200   9600$'
ENDIF;cpt85xx

IF bbc          ;[22]
spdtbl: db      8                       ; 8 entries
        db      04,'1200$',     04h,04h
        db      03,'150$',      02h,02h
        db      05,'19200$',    08h,08h
        db      04,'2400$',     05h,05h
        db      03,'300$',      03h,03h
        db      04,'4800$',     06h,06h
        db      02,'75$',       01h,01h
        db      04,'9600$',     07h,07h

sphtbl: db      cr,lf,'   75   150   300   1200   2400   4800   9600   19200$'
ENDIF;[22] bbc

IF rm380z       ;[22]
spdtbl: db      7                       ; 7 entries
        db      03,'110$',      00h,00h
        db      04,'1200$',     03h,03h
        db      04,'2400$',     04h,04h
        db      03,'300$',      01h,01h
        db      04,'4800$',     05h,05h
        db      03,'600$',      02h,02h
        db      04,'9600$',     06h,06h

sphtbl: db      cr,lf,'   110   300   600   1200   2400   4800   9600$'
ENDIF;[22] rm380z

IF px8 ; [29]
spdtbl: db      9                       ; 9 entries
        db      03,'110$',      02h,02h
        db      04,'1200$',     0ah,0ah
        db      03,'150$',      04h,04h
        db      05,'19200$',    0fh,0fh
        db      04,'2400$',     0ch,0ch
        db      03,'300$',      06h,06h
        db      04,'4800$',     0dh,0dh
        db      03,'600$',      08h,08h
        db      04,'9600$',     0eh,0eh
sphtbl: db      cr, lf
        db  '   100   150   300   600   1200   2400   4800   9600   19200$'
ENDIF ; px8 [29]

IF mikko
spdtbl: db      9h                      ;9 entries
        db      03h,'110$'
        dw      0369h
        db      04h,'1200$'
        dw      0050h
        db      03h,'150$'
        dw      0280h
        db      04h,'2400$'
        dw      0028h
        db      03h,'300$'
        dw      0140h
        db      04h,'4800$'
        dw      0014h
        db      03h,'600$'
        dw      00A0H
        db      02h,'75$'
        dw      0500h
        db      04h,'9600$'
        dw      000ah

sphtbl: db      cr,lf,'  75  110  150  300  600  1200  2400  4800  9600$'
ENDIF;mikko

IF osbrn1
spdtbl: db      02h                     ;2 entries
        db      04h,'1200$',    OSBI12,OSBI12
        db      03h,'300$',     OSBI03,OSBI03

sphtbl: db      cr,lf,'  300',cr,lf,' 1200$'
ENDIF;osbrn1


IF mdI
spdtbl: db      0dh                     ; 13 entries
        db      03h,  '110$'
                dw              1047
        db      04h, '1200$'
                dw              96
        db      03h,  '150$'
                dw              768
        db      05h,'19200$'
                dw              6
        db      04h, '2400$'
                dw              48
        db      03h,  '300$'
                dw              384
        db      05h,'38400$'
                dw              3
        db      03h,  '450$'
                dw              288
        db      04h, '4800$'
                dw              24
        db      05h,'56000$'
                dw              2
        db      03h,  '600$'
                dw              192
        db      02h,   '75$'
                dw              1536
        db      04h, '9600$'
                dw              12

sphtbl: db      cr,lf,'   75    110    150    300    450    600   1200'
        db      cr,lf,' 2400   4800   9600  19200  38400  56000$'

;(Lord knows what you'll be communicating with at 56000 baud, but the
;Multi-I/O board literature says it'll do it, so what the heck....
;might as well throw it in here just to show off...sure hope the
;port don't melt...)

ENDIF   ;mdI    [Toad Hall]

IF cmemco                       ;[25]
spdtbl: db      7               ; 7 entries
        db      3,'110$',       01H,01H
        db      4,'1200$',      88H,88H
        db      3,'150$',       82H,82H
        db      4,'2400$',      90H,90H
        db      3,'300$',       84H,84H
        db      4,'4800$',      0A0H,0A0H
        db      4,'9600$',      0C0H,0C0H

sphtbl: db      cr,lf
        db      '   110   150   300  1200  2400  4800  9600$'
ENDIF;cmemco

IF access ;Similar to bbI with different values [29]
spdtbl: db      6h                      ;6 entries
        db      04h,'1200$',    28h,28h
        db      04h,'2400$',    14h,14h
        db      03h,'300$',     0a0h,0a0h
        db      04h,'4800$',    0ah,0ah
        db      03h,'600$',     50h,50h
        db      04h,'9600$',    5,5

sphtbl: db      cr,lf,'  300  600  1200  2400  4800  9600$'
ENDIF;access [29]

IF mmate        ;[29]
spdtbl: db      10h                     ;16 entries
        db      03h,'110$',     0e2h,0e2h
        db      04h,'1200$',    0e7h,0e7h
        db      05h,'134.5$',   0e3h,0e3h
        db      03h,'150$',     0e4h,0e4h
        db      04h,'1800$',    0e8h,0e8h
        db      05h,'19200$',   0efh,0efh
        db      04h,'2000$',    0e9h,0e9h
        db      04h,'2400$',    0eah,0eah
        db      03h,'300$',     0e5h,0e5h
        db      04h,'3600$',    0ebh,0ebh
        db      04h,'4800$',    0ech,0ech
        db      02h,'50$',      0e0h,0e0h
        db      03h,'600$',     0e6h,0e6h
        db      04h,'7200$',    0edh,0edh
        db      02h,'75$',      0e1h,0e1h
        db      04h,'9600$',    0eeh,0eeh

sphtbl: db      cr,lf,'   50  75    110    134.5  150    300    600   1200'
        db      cr,lf,' 1800   2000   2400   3600   4800   7200   9600  19200$'
ENDIF;mmate [29]

IF disc ;[29]
; Similar to mikko table but with different time constant values
spdtbl: db      9h                      ;9 entries
        db      03h,'110$'
        dw      1134
        db      04h,'1200$'
        dw      102h
        db      03h,'150$'
        dw      831
        db      04h,'2400$'
        dw      50
        db      03h,'300$'
        dw      415
        db      04h,'4800$'
        dw      24
        db      03h,'600$'
        dw      206
        db      02h,'75$'
        dw      1665
        db      04h,'9600$'
        dw      11

sphtbl: db      cr,lf,'  75  110  150  300  600  1200  2400  4800  9600$'
ENDIF;disc      [29]

IF teletek
spdtbl:	db	7		; 7 entries
	db	4, '1200$',	47h,40h
	db	5,'19200$',	47h,04h
	db	4, '2400$',	47h,20h
	db	3,  '300$',	47h,00h
	db	4, '4800$',	47h,10h
	db	3,  '600$',	47h,80h
	db	4, '9600$',	47h,08h

sphtbl:	db	cr,lf
	db      '   300   600  1200   2400   4800   9600  19200$'
ENDIF	;teletk


; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
IF robin OR gener OR dmII OR vector OR trs80;[32]
spdtbl  equ     0               ; SET BAUD not supported.
sphtbl  equ     0
ENDIF;robin OR gener OR dmII OR vector OR trs80 
;
IF mmdI OR osi OR cpm3 OR S1008 ; [29]
spdtbl  EQU     0               ;[hh] SET BAUD not supported.
sphtbl  EQU     0               ;[hh] ran out of room above...
ENDIF;mmdI OR osi OR cpm3 OR S1008 [29]
;
IF hp125			;[MF]
spdtbl  equ     0               ; SET BAUD not supported.
sphtbl  equ     0
ENDIF;hp125 [MF]
;
;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:
IF lobo ;[hh]
        mov     a,l             ;[hh] get the data port value and store at
        sta     outmd3+1        ;[hh] the two places we use...
        sta     inpmd2+1        ;[hh] MNPORT in the overlay
        sta     port            ;[hh] inform program of the change in ports
        inr     a               ;[hh] status port = data port + 1 in the Lobo
        sta     outmd1+1        ;[hh] store it at the three places...
        sta     inpmd1+1        ;[hh] we use MNPRTS...
        sta     outctl+1        ;[hh] in the overlay
        mov     a,h             ;[hh] now get the baud rate port value
        sta     getbd+1         ;[hh] store it in the two places we use...
        sta     setbd+1         ;[hh] BAUDRT in the overlay
        sta     port+1          ;[hh] don't need to, but keeps it consistant
getbd:  lda     baudrt          ;[hh] get baud rate value from port
        sta     speed           ;[hh] tell STAT. baud rate for each port
                                ;[hh] is independant of the other
ENDIF   ;lobo

IF iobyt
        mov     a,m             ;Get the I/O byte
        sta     prtiob          ;Save the desired IO byte for this port
        inx     h               ;Point at next entry
        mov     a,m             ;Get the output function
        sta     prtfun          ;Save it
ENDIF;iobyt

IF iobyt AND robin
        inx     h               ;Point at next entry
        mov     a,m             ;Get the hardware address for the port
        sta     prtadr          ;Store it
ENDIF;iobyt AND robin
;
IF hp125			;[MF]
	push	psw
	push	b
	push	d
	push	h
	xchg			;Put port connect sequence address in DE
	call	prtstr		;Connect proper port
	pop	h
	pop	d
	pop	b
	pop	psw
ENDIF;hp125 [MF]
;
        ret
;
;       Port tables for Lobo MAX-80
IF lobo ;[hh]
; help text
prhtbl: db      cr,lf,'RS-232 port A or B$'
;
; command table
prttbl: db      02H                     ;[hh] two entries
        db      01H,'A$',0E4H,0D0H
        db      01H,'B$',0E6H,0D4H
ENDIF   ;lobo
;
;       Port tables for GENERIC CPM 2.2
IF gener
; help text
prhtbl: db      cr,lf,'CRT device'
        db      cr,lf,'PTR device'
        db      cr,lf,'TTY device'
        db      cr,lf,'UC1 device'
        db      cr,lf,'UR1 device'
        db      cr,lf,'UR2 device$'

; command table
prttbl: db      06H             ;Six devices to choose from
        db      03H,'CRT$'
                dw      crtptb
        db      03H,'PTR$'
                dw      ptrptb
        db      03H,'TTY$'
                dw      ttyptb
        db      03H,'UC1$'
                dw      uc1ptb
        db      03H,'UR1$'
                dw      ur1ptb
        db      03H,'UR2$'
                dw      ur2ptb

; port entry table
; table entries are:
;       db      iobyte-value, BDOS output function, reserved
crtptb: db      crtio,conout,0
ptrptb: db      ptrio,punout,0
ttyptb: db      ttyio,conout,0
uc1ptb: db      uc1io,conout,0
ur1ptb: db      ur1io,punout,0
ur2ptb: db      ur2io,punout,0
ENDIF;gener

;
;       Port tables for DECmate II or MicroMikko or Acorn BBC
;
IF dmII OR mikko OR bbc ;[22]
; help text
prhtbl: db      cr,lf,'COMMUNICATIONS port$'

; command table
prttbl: db      01H             ;Only one port known at this point
        db      0EH,'COMMUNICATIONS$'
                dw      comptb  ;address of info

; port entry table
; table entries are:
;       db      iobyte-value, BDOS output function, reserved
comptb: db      batio,punout,0

ENDIF;[22] dmII OR mikko OR bbc
;
;       Port tables for Robin
;
IF robin
; help text
prhtbl: db      cr,lf,'COMMUNICATIONS port'
        db      cr,lf,'GENERAL purpose port'
        db      cr,lf,'PRINTER port$'

; command table
prttbl: db      03H             ;Three entries
        db      0EH,'COMMUNICATIONS$'
                dw      comptb
        db      07H,'GENERAL$'
                dw      gppptb
        db      07H,'PRINTER$'
                dw      prnptb

; port entry table
; table entries are:
;       db      iobyte-value, BDOS output function, hardware port address
;                                                   (control/status)
;
;At present, the hardware port address is only used for sending a break.
comptb: db      batio,punout,comtst
gppptb: db      gppio,conout,gentst
prnptb: db      lptio,conout,prntst

prtadr: db      comtst          ;space for current hardware port address
ENDIF;robin

IF iobyt
prtfun: db      punout          ;Function to use for output to comm port
prtiob: db      batio           ;I/O byte to use for communicating
coniob: db      defio           ;I/O byte to use for console
ENDIF;iobyt
;
IF hp125			;[MF]
; Help table
prhtbl:	db	cr,lf,'Communications port'
	db	cr,lf,'Printer port$'
; command table
prttbl:	db	02H		;2 entries
	db	0eH,'COMMUNICATIONS$'
	dw	mapon1
	db	07H,'PRINTER$'
	dw	mapon2
;Port table entries are the addresses of the escape sequences to connect
;the ports.
;
ENDIF;hp125 [MF]

IF NOT (iobyt OR lobo OR hp125)          ;[hh] [MF]
prttbl  equ     0               ; SET PORT is not supported
prhtbl  equ     0
ENDIF;NOT iobyt OR lobo OR hp125 [MF]
;
;       selmdm - select modem port
;       selcon - select console port
;       selmdm is called before using inpmdm or outmdm;
;       selcon is called before using inpcon or outcon.
;       For iobyt systems, diddle the I/O byte to select console or comm port;
;       For Decision I, switches Multi I/O board to console or modem serial
;       port.  [Toad Hall]
;       For the rest, does nothing.
;       preserves bc, de, hl.
selmdm:
IF iobyt
	lda     prtiob          ;Set up for output to go to the comm port
        sta     iobyte          ;Switch byte directly
ENDIF;iobyt

IF mdI
        lda     group
        ori     mdmgrp          ;Mask modem serial port
        out     grpsel
ENDIF;mdI  [Toad Hall]

        ret

selcon:
IF iobyt
        lda     coniob          ;Set up for output to go to the console port
        sta     iobyte          ;Switch directly
ENDIF;iobyt

IF mdI
        lda     group
        ori     congrp          ;Mask console serial port (1)
        out     grpsel
ENDIF;mdI  [Toad Hall]

        ret
;       Get character from console, or return zero.
;       result is returned in A.  destroys bc, de, hl.
;
inpcon:
IF NOT iobyt
        mvi     c,dconio        ;Direct console I/O BDOS call.
        mvi     e,0FFH          ;Input.
        call    BDOS
ENDIF;NOT iobyt

IF iobyt
        call    bconst          ;Get the status
        ora     a               ;Anything there?
        rz                      ;No, forget it
        call    bconin          ;Yes, get the character
ENDIF;iobyt
        ret
;
;       Output character in E to the console.
;       destroys bc, de, hl
;
outcon:

IF rm380z       ;[22]
        mov     a,e
        cpi     cr              ;cr produces cr + lf
        jnz     outcn1
        mvi     e,'N'-100O      ;Control-N produces cr only
outcn1:                         ;continue
ENDIF;[22] rm380z

IF NOT iobyt
        mvi     c,dconio        ;Console output bdos call.
        call    bdos            ;Output the char to the console.
ENDIF;NOT iobyt

IF iobyt
        mov     c,e             ;Character
        call    bcnout          ;to Console
ENDIF;iobyt
        ret
;
;       outmdm - output a char from E to the modem.
;               the parity bit has been set as necessary.
;       returns nonskip; bc, de, hl preserved.
outmdm:
IF osi OR lobo         ;[hh]
        push    h
outmd1: lxi     h,mnprts        ;address of the port status register
outmd2: mov     a,m             ; get port status in A
        ani     output          ;Loop till ready.
        jz      outmd2
outmd3: lxi     h,mnport        ;address of port data register
        mov     m,e             ; write the character
        pop     h
        ret
ENDIF;osi OR lobo

IF osbrn1
        call    osldst          ;Read the status port
        ani     output          ;Loop till ready.
        jz      outmdm
        mov     a,e
        jmp     osstda          ;Write to the data port
ENDIF;osbrn1

IF px8 ; [29]
        push    h
        push    b
        push    d
outmd1: call    rsoutst         ; get the output status
        ora     a
        jz      outmd1          ; check if output enabled
        pop     d
        mov     c, e            ; char in C
        push    d
        call    rsput
        pop     d
        pop     b
        pop     h
        ret
ENDIF; px8 [29]

IF inout
        in      mnprts          ;Get the output done flag.
        ani     output          ;Is it set?
        jz      outmdm          ;If not, loop until it is.
        mov     a,e
        out     mnport          ;Output it.
        ret
ENDIF;inout

IF iobyt
;**** Note that we enter from outpkt with the I/O byte already set up for
;  output to go to the comm port
        push    h
        push    b
        lda     prtfun          ;Get the output function
        mov     c,a             ;Into C
        call    bdos            ;And output the character
        pop     b
        pop     h
        ret
ENDIF;iobyt

IF cpm3 OR hp125 ;[MF]
        push    h
        push    b
        mvi     c,auxout        ;Output to the aux output device
        call    bdos
        pop     b
        pop     h
        ret
ENDIF;cpm3 OR hp125 [MF]

;org	$+100h AND 0FF00h	; get rid of phase error

;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
IF iobyt
        call    bconst          ;Is Char at COMM-Port?
        ora     a               ;something there?
        rz                      ; return if nothing there
        call    bconin          ; data present. read data.
ENDIF;iobyt

IF cpm3
        mvi     c,auxist
        call    bdos            ;is char at auxin?
        ora     a               ;something there?
        rz                      ;no
        mvi     c,auxin
        call    bdos            ;read char from auxin
ENDIF;cpm3
;
IF hp125			;[MF]
	lxi	b,70ffh		;SEt subfunction to get RDR (auxin) status
        call    bdos            ;is char at RDR?
        ora     a               ;something there?
        rz                      ;no
        mvi     c,auxin
        call    bdos            ;read char from RDR
ENDIF;hp125 [MF]

IF osi OR lobo         ;[hh]
inpmd1: lda     mnprts          ;Get the port status into A.
        ani     input           ;See if the input ready bit is on.
        rz                      ;If not then return.
inpmd2: lda     mnport          ;If so, get the char.
ENDIF;osi OR lobo 

IF osbrn1
        call    osldst          ;Read the status port
        ani     input           ;Something there?
        rz                      ;Nope
        call    osldda          ;Read the data port
ENDIF;osbrn1

IF inout
;Note: modem port should already be selected for mdI.  [Toad Hall]
        in      mnprts          ;Get the port status into A.
        ani     input           ;See if the input ready bit is on.
        rz                      ;If not then return.
        in      mnport          ;If so, get the char.
ENDIF;inout

IF px8 ; [29]
        call    rserst          ; check error status
        ani     64h             ; this assumes 'not open' cannot occur
        jnz     inpmd1          ; error has occurred!
        call    rsinst          ; any chars outstanding?
        ora     a
        rz                      ; exit if none
        call    rsget           ; get char in A
        ret
; return the 'no char outstanding' indication on error
inpmd1: mvi     a, 0
ENDIF; px8 [29]

	ret                     ; return with character in A


;
;       flsmdm - flush comm line.
;       Modem is selected.
;       Currently, just gets characters until none are available.

flsmdm: call    inpmdm          ; Try to get a character
        ora     a               ; Got one?
        jnz     flsmdm          ; If so, try for another
        ret                     ; Receiver is drained.  Return.
;
;       lptstat - get the printer status. Return a=0ffh if ok, or 0 if not.
lptstat:
IF iobyt                        ;[33]
        call    bprtst          ;
call    bprtst          ; get status
ENDIF   ;iobyt[33]
IF NOT iobyt    ;[33]
        xra     a               ; assume it is ok.. this may not be necessary
ENDIF   ;iobyt [33]
        ret

;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
        push    d               ; save DE in either case
        call    prtflt          ; go through printer filter [30]
        ana     a               ; if A = 0 do nothing,
        jz      outlp1          ; [30] if a=0 do nothing

IF NOT iobyt
        mvi     c,lstout
        call    bdos            ;Char to printer
ENDIF;NOT iobyt
IF iobyt
        mov     c,e
        call    blsout
ENDIF;iobyt

outlp1: pop     d               ; restore saved register pair
        ret
;
;       Screen manipulation routines
;       csrpos - move to row B, column C
;
;       csrpos for terminals that use a leadin sequence followed
;        by (row + 31.) and (column + 31.)
;
IF NOT (robin OR dmII OR osi OR vector OR termin OR hp125)
				;[MF] Terminals code in CPXVDU
csrpos: push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; restore coordinates
        mov     a,h             ; get row
        adi     (' '-1)         ; space is row one
        mov     e,a
        push    h
        call    outcon          ; output row
        pop     h
        mov     a,l             ; get column
        adi     (' '-1)         ; space is column one
        mov     e,a
        jmp     outcon          ; output it and return
ENDIF;NOT (robin OR dmII OR osi OR vector OR termin OR hp125)[MF]
;
;
;
;       csrpos for ANSI terminals
;
IF robin OR dmII 
csrpos: push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; peek at coordinates
        push    h               ;  then save away again
        mov     l,h             ; l = row
        mvi     h,0             ; hl = row
        call    nout            ; output in decimal
        mvi     e,';'           ; follow with semicolon
        call    outcon          ; print it
        pop     h               ; restore column
        mvi     h,0             ; hl = column
        call    nout
        mvi     e,'H'           ; terminate with 'move cursor' command
        jmp     outcon          ; output it and return
ENDIF;robin OR dmII 
;
;       csrpos for the HP-125 [MF]
;
IF hp125				;[MF]
csrpos:	dcr	b		;HP-125 uses zero-based addressing
	dcr	c		;...
 push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; peek at coordinates
        push    h               ;  then save away again
        mov     l,h             ; l = row
        mvi     h,0             ; hl = row
        call    nout            ; output in decimal
        mvi     e,'R'+20h	;Say it was a row
        call    outcon          ; print it
        pop     h               ; restore column
        mvi     h,0             ; hl = column
        call    nout
        mvi     e,'C'           ; terminate with 'move cursor' command
        jmp     outcon          ; output it and return
ENDIF;hp125 [MF]
;
;       csrpos for the Vector General.  It's weird.
;
IF vector
csrpos: dcr     b               ; vector uses zero-based addressing?
        dcr     c
        push    b               ; save coordinates
        mvi     e,esc           ; print an escape
        call    outcon
        pop     d               ; peek at coordinates
        push    d
        call    outcon          ; output column
        pop     d
        mov     e,d             ; get row
        jmp     outcon          ; output and return
ENDIF;vector

IF osi 				; systems without cursor positioning
csrpos: ret                     ; dummy routine referenced by linkage section
ENDIF;osi


;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:

IF vector OR osbrn1 OR lobo
        lxi     d,delstr
        jmp     prtstr
ENDIF	;vector OR osbrn1 OR lobo

IF bbc OR rm380z      ;[22]
        ret
ENDIF;bbc OR rm380z

IF NOT (vector OR osbrn1 OR bbc OR rm380z);[22]
        mvi     e,bs            ;get a backspace
        jmp     outcon
ENDIF;NOT (vector OR osbrn1 OR bbc OR rm380z [22]

; erase the character at the current cursor position
clrspc: mvi     e,' '
        call    outcon
        mvi     e,bs            ;get a backspace
        jmp     outcon

; erase the current line
clrlin: lxi     d,eralin
        jmp     prtstr

; erase the whole screen, and go home. preserves b (but not c)
clrtop: lxi     d,erascr
        jmp     prtstr


IF robin
sysver:	db	'VT180 Robin$'
ENDIF;robin

IF dmII
sysver:	db	'DECmate II CP/M-80$'
ENDIF;dmII

IF delphi	; [7] new system
sysver:	db	'Digicomp Delphi 100$'
endif;delphi

IF access
sysver:	db	'Actrix CP/M$'
endif;

IF teletek
sysver:	db	'Teletek SYSTEMASTER CP/M-80$'
ENDIF	;teletek

IF cpt85xx
sysver:	db	'CPT-85xx under CompuPak CP/M$'
ENDIF;cpt85xx

IF mdI
sysver:	db	'Morrow Decision I$'
ENDIF;mdI  [Toad Hall]

IF mmdI
sysver:	db	'MicroDecision I$'
ENDIF;mmdI

IF osi
sysver:	db	'Ohio Scientific$'
ENDIF;osi

IF mmate	;[29]
sysver:	db	'PMC Micromate using port I/O$'
ENDIF;mmate [29]

IF disc		;[29]
sysver:	db	'Discovery using 83U board port B$'
ENDIF  ;disc [29]

IF s1008	;[29]
sysver:	db 'U. S. MicroSales using printer port$'
ENDIF ;s1008 [29]

IF cmemco	;[25]
sysver:	db	'Cromemco (TU-ART)$'
ENDIF;cmemco
;
IF robin OR dmII
; Note that we cannot support Graphics Mode or the H19 erase-screen command
; (<esc>E), because the sequences are more than three bytes.
defesc	EQU	'\'-100O        ;Still Control-\ (just ran out of room...)
vtval	EQU	0		; we probably don't want VT52 emulation
outlin:	db	esc,3CH,esc,'[H',esc,'[J',cr,lf,tab,tab,'$'
erascr:	db	esc,'[H',esc,'[J$'      ;Clear screen and go home.
eralin:	db	cr,esc,'[K$'            ;Clear line.
curldn:	db	esc,'[$'                ; Cursor leadin
ttab:
ta:	db	esc,'[A$'               ; Cursor up.
tb:	db	esc,'[B$'               ; Cursor down.
tc:	db	esc,'[C$'               ; Cursor right.
td:	db	esc,'[D$'               ; Cursor left
te:	db	'$',0,0,0               ; (can't) Clear display
tf:	db	'$',0,0,0               ; (don't) Enter Graphics Mode
tg:	db	'$',0,0,0               ; (don't) Exit Graphics mode
th:	db	esc,'[H$'               ; Cursor home.
ti:	db	esc,'M$',0              ; Reverse linefeed.
tj:	db	esc,'[J$'               ; Clear to end of screen.
tk:	db	esc,'[K$'               ; Clear to end of line.
ENDIF;robin OR dmII

IF mikko
sysver:	db	'MikroMikko$'
outlin:	db	subt,cr,lf,tab,'$'
erascr:	db	subt,'$'                ;Clear screen and go home.
eralin:	db	cr,1CH,'$'              ;Clear line.
curldn:	db	esc,'=$'                ;cursor leadin
ttab:					;Table start location.
ta:	db	0BH,'$',0,0             ;Cursor up.
tb:	db	0AH,'$',0,0             ;Cursor down.
tc:	db	0CH,'$',0,0             ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left
te:	db	subt,'$',0,0            ;Clear display
tf:	db	'$',0,0,0               ;(can't) Enter Graphics Mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1EH,'$',0,0             ;Cursor home.
ti:	db	'$',0,0,0               ;(can't) Reverse linefeed.
tj:	db	1cH,'$',0,0             ;Clear to end of screen.
tk:	db	1cH,'$',0,0             ;Clear to end of line.
ENDIF;mikko
;
IF bbc		;[22]
sysver:	db	'BBC (Z80)$'
outlin:	db	0CH,esc,'=',21H,30H,'$'
erascr:	db	0CH,'$'                 ;Clear screen and go home.
eralin:	db	cr,esc,'@$'             ;Clear line.
curldn:	db	esc,'=$'                ;cursor leadin
ttab:					;Table start location.
ta:	db	0BH,'$',0,0             ;Cursor up.
tb:	db	0AH,'$',0,0             ;Cursor down.
tc:	db	tab,'$',0,0             ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left
te:	db	0CH,'$',0,0             ;Clear display
tf:	db	'$',0,0,0               ;(can't) Enter Graphics Mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1EH,'$',0,0             ;Cursor home.
ti:	db	'$',0,0,0               ;(can't) Reverse linefeed.
tj:	db	esc,'?$',0,0            ;Clear to end of screen.
tk:	db	esc,'@$',0,0            ;Clear to end of line.
ENDIF;[22] bbc
;
IF rm380z	;[22]
sysver:	db	'Research Machines 380Z$'
outlin:	db	1FH,cr,tab,'$'
erascr:	db	1FH,'$'                 ;Clear screen and go home.
eralin:	db	0EH,19H,'$'             ;Clear line.
curldn:	db	16H,'$'                 ;cursor leadin
ttab:					;Table start location.
ta:	db	0BH,'$',0,0             ;Cursor up.
tb:	db	0AH,'$',0,0             ;Cursor down.
tc:	db	18H,'$',0,0             ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left
te:	db	1FH,'$',0,0             ;Clear display
tf:	db	'$',0,0,0               ;(can't) Enter Graphics Mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1DH,'$',0,0             ;Cursor home.
ti:	db	'$',0,0,0               ;(can't) Reverse linefeed.
tj:	db	1EH,'$',0,0             ;Clear to end of screen.
tk:	db	19H,'$',0,0             ;Clear to end of line.
ENDIF;[22] rm380z

IF lobo	;[hh]
sysver:	db	'Lobo MAX-80$'
outlin:	db	esc,'*',cr,lf,tab,tab,'$'
erascr:	db	esc,'*$'                ;[hh] clear screen and home cursor
eralin:	db	cr,esc,'R$'             ;[hh] clear line
curldn:	db	esc,'=$'                ;[hh] cursor lead-in string
delstr:	db	bs,' ',bs,bs,'$'        ;[hh] ??adjust for echoing delete
ttab:					;[hh] table start location
ta:	db	0BH,'$',0,0             ;[hh] cursor up
tb:	db	0AH,'$',0,0             ;[hh] cursor down
tc:	db	0CH,'$',0,0             ;[hh] cursor right
td:	db	08H,'$',0,0             ;[hh] cursor left
te:	db	esc,'*$',0              ;[hh] clear display (homes cursor)
tf:	db	'$',0,0,0               ;[hh] (can't) enter graphics mode
tg:	db	'$',0,0,0               ;[hh] (can't) exit graphics mode
th:	db	01EH,'$',0,0            ;[hh] home cursor
ti:	db	esc,'E$',0              ;[hh] reverse linefeed (insert line)
tj:	db	esc,'Y$',0              ;[hh] clear to end of screen
tk:	db	esc,'T$',0              ;[hh] clear to end of line
ENDIF	;lobo

IF px8 ; [29]
sysver:	db	'Epson PX-8$'
outlin:	db	esc,'*$'
erascr:	db	esc,'*$'    ; clear screen and home
eralin:	db	cr,esc,'T$' ; clear line
curldn:	db	esc,'=$'    ; cursor lead in
ttab:			    ; table start location
ta:	db	30,'$',0,0  ; cursor up
tb:	db	31,'$',0,0  ; cursor down
tc:	db	28,'$',0,0  ; cursor right
td:	db	29,'$',0,0  ; cursor left
te:	db	esc,'*$',0  ; clear display
tf:	db	'$',0,0,0   ; can't enter graphics graphics mode
tg:	db	'$',0,0,0   ; can't exit graphics mode
th:	db	11,'$',0,0  ; home cursor
ti:	db	30,'$',0,0  ; reverse linefeed
tj:	db	esc,'Y$',0  ; erase to end of screen
tk:	db	esc,'T$',0  ; erase to end of line
ENDIF ; px8 [29]

;
IF osbrn1
sysver:	db	'Osborne 1$'
outlin:	db	1AH,cr,lf,tab,'$'       ;(Clear screen, home cursor)
erascr:	db	1AH,'$'                 ;Clear screen and go home.
eralin:	db	cr,esc,'T$'             ;Clear line.
delstr:	db	bs,bs,'$'               ; Adjust for delete
curldn:	db	esc,'=$'                ;Cursor lead-in
ttab:					;Table start location.
ta:	db	('K'-100O),'$',0,0      ;Cursor up.
tb:	db	12O,'$',0,0             ;Cursor down.
tc:	db	('L'-100O),'$',0,0      ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left.
te:	db	subt,'$',0,0            ;Clear screen.
tf:	db	'$',0,0,0               ;(can't) Enter graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit graphics mode
th:	db	('^'-100O),'$',0,0      ;Cursor home.
ti:	db	('K'-100O),'$',0,0      ;Reverse linefeed.
tj:	db	esc,'T$',0              ;(can't) Clear to end of screen.
tk:	db	esc,'T$',0              ;Clear to end of line.
ENDIF;osbrn1
;
IF vector
sysver:	db	'Vector Graphics$'
outlin:	db	('D'-100O),cr,lf,tab,tab,'$'
erascr:	db	('D'-100O),'$'          ;Clear screen and go home.
eralin:	db	cr,('Q'-100O),'$'       ;Clear line.
delstr:	db	bs,' ',bs,bs,'$'        ; adjust for echoing delete character
ttab:					;Table start location.
ta:	db	('U'-100O),'$',0,0      ;Cursor up.
tb:	db	12O,'$',0,0             ;Cursor down.
tc:	db	('Z'-100O),'$',0,0      ;Cursor right.
td:	db	'$',0,0,0               ;(can't) Cursor left
te:	db	'$',0,0,0               ;(can't) Clear display
tf:	db	'$',0,0,0               ;(can't) Enter graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit graphics mode
th:	db	('B'-100O),'$',0,0      ;Cursor home.
ti:	db	('U'-100O),'$',0,0      ;Reverse linefeed.
tj:	db	('P'-100O),'$',0,0      ;Clear to end of screen.
tk:	db	('Q'-100O),'$',0,0      ;Clear to end of line.
ENDIF;vector

IF trs80lb
sysver:	db	'TRS-80 II Lifeboat CP/M$'
outlin:	db	esc,':',cr,lf,tab,tab,'$'
erascr:	db	esc,':$'                ;Clear screen and go home.
eralin:	db	cr,esc,'T$'             ;Clear line.
curldn:	db	esc,'=$'                ;Cursor lead-in
ttab:					;Table start location.
ta:	db	0BH,'$',0,0             ;Cursor up.
tb:	db	0AH,'$',0,0             ;Cursor down.
tc:	db	0CH,'$',0,0             ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left
te:	db	esc,':$',0              ;Clear display
tf:	db	'$',0,0,0               ;(can't) Enter Graphics Mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1EH,'$',0,0             ;Cursor home.
ti:	db	0BH,'$',0,0             ;Reverse linefeed.
tj:	db	esc,'Y$',0              ;Clear to end of screen.
tk:	db	esc,'T$',0              ;Clear to end of line.
ENDIF;trs80lb
;
IF trs80pt
sysver:	db	'TRS-80 II P+T CP/M$'
outlin:	db	0CH,cr,lf,tab,tab,'$'
erascr:	db	0CH,'$'                 ;Clear screen and go home.
eralin:	db	cr,01H,'$'              ;Clear line.
curldn:	db	esc,'Y$'                ;Cursor lead-in
ttab:	;Table start location           ;Must be 4 bytes each
ta:	db	1EH,'$',0,0             ;Cursor up.
tb:	db	1FH,'$',0,0             ;Cursor down.
tc:	db	1DH,'$',0,0             ;Cursor right.
td:	db	1CH,'$',0,0             ;Cursor left
te:	db	0CH,'$',0,0             ;Clear display
tf:	db	11H,'$',0,0             ;Enter Graphics Mode
tg:	db	14H,'$',0,0             ;Exit Graphics mode
th:	db	06H,'$',0,0             ;Cursor home.
ti:	db	1EH,'$',0,0             ;Reverse linefeed.
tj:	db	02H,'$',0,0             ;Clear to end of screen.
tk:	db	01H,'$',0,0             ;Clear to end of line.
ENDIF;trs80pt

IF osi
outlin:	db	cr,lf,'Starting ...$'
erascr	equ	crlf			;"Home & clear" (best we can do).
eralin:	db	'^U',cr,lf,'$'          ;Clear line.
prpack:	db	cr,lf,'RPack: $'
pspack:	db	cr,lf,'SPack: $'
ttab	equ	0			; no VT52 table
ENDIF;osi
;
IF hp125			;[MF]
defesc	EQU	'\'-100O        ;Still Control-\ (just ran out of room...)
vtval	EQU	0		; we probably don't want VT52 emulation
;
sysver:	db	'HP-125 Series 100$'
;
outlin:	db	esc,'H',esc,'J',cr,lf,tab,tab,'$'
erascr:	db	esc,'H',esc,'J$' 	;Clear screen and go home.
eralin:	db	cr,esc,'K$'		;Clear line.
curldn:	db	esc,'&a$'		;Cursor leadin
ttab:					;Table start location.
ta:	db	esc,'A$',0		;Cursor up.
tb:	db	esc,'B$',0		;Cursor down.
tc:	db	esc,'C$',0		;Cursor right.
td:	db	esc,'D$',0		;Cursor left
te:	db	esc,'J$',0		;Clear display
tf:	db	'$',0,0,0		;[hh] (can't) enter graphics mode
tg:	db	'$',0,0,0		;[hh] (can't) exit graphics mode
th:	db	esc,'H$',0		;Cursor home.
ti:	db	esc,'M$',0		;Reverse linefeed.
tj:	db	esc,'J$',0		;Clear to end of screen.
tk:	db	esc,'K$',0		;Clear to end of line.
;
;
; Escape sequences to map CP/M Reader/Punch to Data Comm input/output,
;	respectively and to turn off these mappings
;
mapon1:	db	esc,'&i10s18d9M'
	db	esc,'&i2s25d9M'
	db	esc,'&i10s16d2M'
	db	esc,'&i0s25d2M$';Esc. sequences to turn off DAtacomm2/turn
				;on Data Comm 1
mapon2:	db	esc,'&i10s16d9M'
	db	esc,'&i0s25d9M'
	db	esc,'&i10s18d2M'
	db	esc,'&i2s25d2M$';Esc. sequences to turn off Datacomm1/turn
				;on Datacomm 2
mapoff:	db	esc,'&i0s25d9M'
	db	esc,'&i10s16d9M'
	db	esc,'&i2s25d9M'
	db	esc,'&i10s18d9M$'
;
readin:	call	$-$		;Read character into b
	mov	a,b		;Get 8-bit character
	ret			;and return
;
jbuf:	db	7		;bios dispatch table vector argument block
	db	0		;to read RDR routine address
	db	0c3h		;...
	dw	0		;...
;
ENDIF;hp125 ;[MF]

IF lasm and termin	; if no terminal, no need to link
LINK CPXVDU.ASM
ENDIF	; lasm and termin

ovlend	EQU	$

IF lasm
	END	; If m80 then this ignored
ENDIF	; lasm
