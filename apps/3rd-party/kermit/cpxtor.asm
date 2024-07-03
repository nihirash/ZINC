IF NOT lasm
.printx * CPXTOR.ASM *
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
;       This file contains the system dependent part for Torch, Superbrains, 
;       PCI2651 (Loughborough 8" Standard CP/M system) and Cifer computers.
;
;       This is the first attempt to break the huge CPXSYS.ASM file
;       into smaller system dependent files.  To start with I will bunch
;       several micros to one class.
;
;       Please name system dependent files in the form CPXxxx.ASM where
;       xxx is a three letter abbrev. for the system you are adding.
;
; revision history:
;
;edit 5, 10-Jan-1991 by MF. Removed references to assembly switch ker09.
; edit 4, 21 July, 1987 by OBSchou.  Removed routines no in CPXCOM.ASM
;
; edit 3, 8 April, 1987 by OBSchou.  Moved the VDU declarations for the
;	Torch, superbrain and Cifer from CPXVDU.ASM.  Also added code to
;	see if the MCP/CCCP ROM versions on the Torch is less or grater than
;	1.  Less than 1 => poor screen control.  Finally adjusted the 
;	positioning of the filename to cope with a user number and drive 
;	in the filename field
;
;
; edit 2, 20 March, 1987 by C.J.MILES@UK.AC.UMRCC.  Added support for 
;	NCR Decision Mate V (2651 USART)
;
; edit 1, 22 April, 1986, OBSchou.  Start on splitting off individual 
;       systems from this huge file.  It is done using the LINK facility 
;       LASM.  We link to a collection of systems under CPXxxx.ASM.
;       I have started with the systems I know, the Torch, Cifer and 
;       pci2651.  These will all be held under CPXTOR.ASM
;
;
; Keep module name, edit number, and last revision date in memory.
family: db      'CPXTOR.ASM (5)  10-Jan-1991  $'
;
; Assembly time message to let me know I'm building the right version.
; LASM generates an 'S' error along with the message, which is messy, but
; better than trying to put everything inside a IF m80 OR mac80 conditional,
; because LASM doesn't like nested IF's, either.

IF ncrdmv
.printx * Assembling KERMIT-80 for the N.C.R. Decision Mate V *
ENDIF

IF brain
.printx * Assembling KERMIT-80 for the Intertec Superbrain *
ENDIF

IF brainm
.printx * With main port selected
ENDIF
IF braina
.printx * With Aux port
ENDIF

IF pci2651      ;
.printx * assembling Kermit-80 for 2651 PCI as comms device *
ENDIF

IF torch
.printx * Assembling Kermit-80 for Torch Unicorn 5 *
ENDIF
; *******This should be in the original CPXSYS.ASM file
;
;=========================================================================
;       I/O Byte assignments (2-bit fields for 4 devices at loc 3)
;
;bits 6+7               LIST field
;       0               LIST is Teletype device (TTY:)
;       1               LIST is CRT device (CRT:)
;       2               LIST is Lineprinter (LPT:)
;       3               LIST is user defined (UL1:)
;
;bits 4+5               PUNCH field
;       0               PUNCH is Teletype device (TTY:)
;       1               PUNCH is high speed punch (PUN:)
;       2               PUNCH is user defined #1 (UP1:)
;       3               PUNCH is user defined #2 (UP2:)
;
;bits 2+3               READER field
;       0               READER is Teletype device (TTY:)
;       1               READER is high speed reader (RDR:)
;       2               READER is user defined #1 (UR1:)
;       3               READER is user defined #2 (UR2:)
;
;bits 0+1               CONSOLE field
;       0               CONSOLE is console printer (TTY:)
;       1               CONSOLE is CRT device (CRT:)
;       2               CONSOLE is in Batch-mode (BAT:);READER = Input,
;                       LIST = Output
;       3               CONSOLE is user defined (UC1:)
;
;=========================================================================

iobyte  EQU     03H     ;Location of I/O byte


; [13] modifed to use either main or aux port.  Should really
;       be selected by set port, but this is urgent, so no frills
IF brain
baudst  EQU     60H     ;
baudrt  EQU     0EF00H  ;Memory location where baud rates are stored.
output  EQU     01H     ;Transmitter ready
input   EQU     02H     ;Input data available
TxEmpty EQU     04h     ;Transmitter empty
z80     SET     TRUE    ;I don't know...
ENDIF;brain
IF brainm               ; Superbrain and main ports
mnport  EQU     58H     ;Modem data port
mnprts  EQU     59H     ;Modem status port
ENDIF   ;brainm
IF braina               ; Superbrain and aux port
mnport  EQU     40H     ;Modem data port
mnprts  EQU     41H     ;Modem status port
ENDIF   ;braina [13]

IF ncrdmv
iobase	equ	70h		; base address of PCI device
modrx	equ	70h		; Rx data port
mnprts	equ	71h		; status port
mnmodr	equ	72h		; mode register read
mncmdr	equ	73h		; command register read
modtx	equ	74h		; Tx data port
mnmodw	equ	76h		; mode register write
mncmdw	equ	77h		; command register write
txrdy	equ	1
output	equ	txrdy
rxrdy	equ	2
input	equ	rxrdy
baudini	equ	0ah		; initial baud to 2400
z80	SET	true
cpuspd	SET	40
ENDIF

IF pci2651                      ;[28]
iobase  equ     04h             ; base address of PCI device
mnport  equ     iobase          ; rx and tx data ports
mnprts  equ     iobase+1        ; status port
mnmode  equ     iobase+2        ; mode port
mncmd   equ     iobase+3        ; PCI command port

txrdy   equ     1               ; tx ready bit set if free
output  equ     txrdy
rxrdy   equ     2               ; RX ready bit
input   equ     rxrdy
baudini equ     7               ; 7 => 1200 baud by default
z80     SET     true            ; For Ithica intersystems it is
cpuspd  SET     40              ; and running at four megs
ENDIF                           ;[28]

IF torch        ;[13]
z80     SET     TRUE
;                       [32] baudini removed as now read current baud rate
;               settings from base processor.

;baudini        equ     707h    ; Initial Baud rate = 1200 baud
                        ; Entry to be of form x0xh where x is
                        ; the value x in the FX 7,x and FX 8,x
                        ; funtion calls.  4= 1200 baud, 7 = 9600
                        ; 2 = 300 baud.
ENDIF

IF brain OR torch
defesc  EQU     ']'-100O        ;The default escape character.
ENDIF;brain OR torch

; If none of the above, default to VT52-EMULATION ON.
IF NOT crt 
vtval   EQU     1
ENDIF;NOT crt


sysxin:

IF brainm                       ;[25]
        lda     baudrt          ; fetch current baud rate
        ani     0F0H            ; extract left nibble
        rrc                     ; shift right 4 places
        rrc
        rrc
        rrc
        sta     speed           ; store as comm port speed
        sta     speed+1         ;  (16 bits, to match speed table entries)
ENDIF;brainm

IF braina                       ;[25]
        lda     baudrt          ; fetch current baud rate
        ani     00FH            ; extract right nibble
        sta     speed           ; store as comm port speed
        sta     speed+1         ;  (16 bits, to match speed table entries)
ENDIF;braina

IF torch                        ; [13] [32]
        push    h
        mvi     a,0f2h          ; nick code from BBC initialisation
        lxi     h,0ff00h
        call    osbyte          ; Read current speed setting
        mov     a,l
        ani     7
        xri     7               ; Store as two's complement
        inr     a
        sta     speed
        sta     speed+1
        mov     e,a
        call    sysspd          ; Make sure they are both the same!
        mvi     a,15            ; Flush all internal buffers [32]
        mvi     l,0
;       call    osbyte
        mvi     a,3
        lxi     h,0100h         ; *FX 3,0,1 Enable RS423
        call    osbyte
        mvi     a,2             ; Select keyboard, Enable RS423 input
        mvi     l,2
        call    osbyte
        mvi     a,5             ; Select serial printer [32]
        mvi     l,2
        call    osbyte          ; [30]
        mvi     a,6             ; Must be able to send LF [30]
        mvi     l,0
        call    osbyte          ; [30]
	mvi	a,202		; FX 202,255 set lower case on
	mvi	l,255
	call	osbyte
        pop     h

; Now see what version of MCP CCP roms.  Assume >1, else copy a few of the 
;	older Torch VDU declares over the new ones.
;
;	lda	0ffffh		; Address 0ffffh has single byte Version no.
;	push	psw		; save for a rainy day
;	ani	0F0h		; get ms digit of MCP version
;	rra			; move right 4 places
;	rra
;	rra
;	rra
;	ani	0fh
;	adi	30h		; make it a number
;	sta	mcpver
;	pop	psw		; its raining...
;	push	psw		; ... its pouring...
;	ani	0fh		; get ls digit
;	adi	30h		; make it ascii number
;	sta	mcpver+2
;	pop	psw		; restore psw
;	cpi	10h		; Version 1.00 or less?
;	jp	init2		; yes, so skip next bit
;	lxi	h,ooutli	; from old string table
;	lxi	d,ttab		; to new ttab
;	lxi	b,60		; 60 bytes to move
;	call	mover
init2:	

IF ncrdmv
	mvi	a,00		; clear out command register
	out	mncmdw
	mvi	a,4eh		; 1 stop bit, 8 data bits, / by 16 counter
	out	mnmodw
	mvi	a,70h+baudini	; baud rate and select internal rate gen.
	out	mnmodw
	mvi	a,27h		; enable tx and rx, RTS and DTR low
	out	mncmdw
ENDIF	; ncrdmv

IF pci2651              ;[28]
        in      mncmd           ; clearw command reg counter
        mvi     a,4eh           ; 1 stop bit, 8 data bits, / by 16 counter
        out     mnmode
        mvi     a,30h+baudini   ; baud rate and select internal rate gen.
        out     mnmode
        mvi     a,27h           ; enable tx and rx, RTS and DTR low
        out     mncmd
ENDIF   ; pci2651 [28]

        ret                     ; return from system-dependent routine

;
;
;       system-dependent termination processing
;       If we've changed anything, this is our last chance to put it back.
sysexit:
        ret

;
;       system-dependent processing for start of CONNECT command
;
syscon:
        ret

conmsg:         ; Messages printed when entering transparent (CONNECT) mode:
;
;
;       syscls - system-dependent close routine
;       called when exiting transparent session.
;
syscls:
        ret
;
;
;       sysinh - help for system-dependent special functions.
;       called in response to <escape>?, after listing all the
;       system-independent escape sequences.
;
sysinh:
IF torch OR brain OR pci2651 OR ncrdmv
        lxi     d,inhlps        ; we got options...
        call    prtstr          ; print them.
ENDIF;torch OR brain OR pci2651 OR ncrdmv

        ret


;additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:

; [16] [18] have added super brain and Torch to the list of Breaking machines.

IF pci2651 OR brain OR torch OR ncrdmv
        db      cr,lf,'B  Transmit a BREAK'
ENDIF   ;pci2651 OR brain OR torch OR ncrdmv

IF torch ; added this simply to debug the escape cokebottle D for the apple
        db      cr,lf,'D  Disconnect the modem (Test purposes only)'
ENDIF;Torch

        db      '$'                     ;[hh] table terminator

;
;       sysint - system dependent special functions
;       called when transparent escape character has been typed;
;       the second character of the sequence is in A (and in B).
;       returns:
;       non-skip: sequence has been processed
;       skip:   sequence was not recognized
sysint: ani     137O            ; convert lower case to upper, for testing...

; [19] have added superbrain and torch to the list

IF brain OR pci2651 OR torch OR ncrdmv
        cpi     'B'             ; send break?
        jz      sendbr          ; yes, go do it.  return nonskip when through.
ENDIF   ;brain OR pci2651 OR torch OR ncrdmv

IF Torch; added bit for doing a D...
        cpi     'D'             ;drop the line...
        jz      dropln
ENDIF ;torch

        jmp     rskp            ; take skip return - command not recognized.


IF torch
dropln: lxi     d,dropm         ; tell user line is dropped..
        call    prtstr
        xra     a               ; destroy A
        ret
dropm:  db      bell,cr,lf,'Testing line dropped ',cr,lf,bell
        db      '$'
ENDIF ;torch and dropping them there lines..

;

IF brain 
sendbr:
;
;       Ensure that the transmitter has finished sending buffered chars
sndbr1: in      mnprts          ; get UART status
        ani     TxEmpty         ; everything sent?
        jz      sndbr1          ; no, wait a bit more
;
;       Begin sending a break by setting bit in UART command register
        mvi     a,3Fh           ; Set TxEna, DTR, RxEna, SBreak, ErrRst, RTS
        out     mnprts
;
;       Wait for 250 milliseconds (using hundredths second delay routine)
        mvi     a,25
        call    delay
;
;       Resume normal operation by clearing the SendBreak command bit
        mvi     a,37h           ;Set TxEna, DTR, RxEna, ErrRst, RTS
        out     mnprts
;
        ret                     ;done
ENDIF;brain 

IF torch ; [18] [27] [30] [32]
; Send a break.  
;
; [30]  Dumping of 6502 code not yet used, but may be for later versions of 
; the Torch CCCP Rom in the BBC.  This works, so I leave it for now.

sendbr:
        push    h               ;save for a monsoon
        mvi     a,0e8h
        lxi     h,0             ; turn interrupts off
        call    osbyte
        push    h
;
        mvi     a,9ch           ; OSBYTE call 9c is read/write 6850 cntl prt
        lxi     h,0077h         ; H = 6502 Y reg, L = 6502 X reg
        call    osbyte          ; returned new val. = (old value AND Y)XOR X
        push    h               ; save it for return
;
        mvi     a,30
        call    delay           ; do a delay
;
; now clear rx register
;
        mvi     a,96h           ; do a read sheila address 08h
        mvi     l,8
        mvi     h,0
        call    osbyte          ; read sheila 08h = 6850 rx reg
;
; restore 6850 regs...
;
        pop     h               ; restore previous cntl reg
                                ; old x reg in l, so leave it there
;       mov     l,h
        mvi     h,0
        mvi     a,9ch           ; write previous value to 6850
        call    osbyte
;
; and Beebs interrupt mask
;
        pop     h               ; get interrupt mask
                                ; Once again, old X in L so leave it alone
;       mov     l,h
        mvi     h,0
        mvi     a,0e8h
        call    osbyte          ; restore interrupts mask
;
        pop     h
        ret                     ; its raining again, so exit
ENDIF   ; torch [18] [32]

IF ncrdmv
sendbr:	in	mnprts		; get status
	ani	04h		; make sure shift register is empty
	jz	sendbr

	mvi	a,2fh		; force a break
	out	mncmdw
	mvi	a,100		; set delay period
	call	delay
	mvi	a,27h		; restore command register
	out	mncmdw
	ret
ENDIF	; ncrdmv

IF pci2651      ;[28]
sendbr: in      mnprts
        ani     04h             ; make sure shift reg is clear
        jz      sendbr

        mvi     a,2fh           ; set foe a break
        out     mncmd
        mvi     a,100           ; wait a bit
        call    delay
        mvi     a,27h           ; restore mode
        out     mncmd
        ret
ENDIF   ;pci2651 [28]

;
;       sysflt - system-dependent filter
;       called with character in E.
;       if this character should not be printed, return with A = zero.
;       preserves bc, de, hl.
;       note: <xon>,<xoff>,<del>, and <nul> are always discarded.
sysflt:
        mov     a,e             ; get character for testing
        ret

;       mdmflt - modem filter [30]
;       called with character to be sent to printer in E
;       with parity set as appropriate.
;       return with accumulator = 0 do do nothing,
;                               <> 0 to send char in E.
mdmflt:
        mov     a,e             ;[30] get character to test
IF torch        ;[30] map del to bs,space,bs
        ani     7fh             ; strip parity
        cpi     7fh             ; is it the delete character
        rnz                     ; no, then a <> 0 so print it
        mvi     e,bs            ; else load a backspace
        call    outmdm          ; little recursion...
        mvi     e,' '           ; then a space
        call    outmdm          ; backspace, space, now another...
        mvi     e,bs            ; backspace
        call    outmdm          ;
        xra     a               ; clear a => on return do nowt.
ENDIF   ;torch [30]
        ret



;       prtflt - printer filter [30]
;       called with character to be sent to printer in E
;       returns with a = 0 to do nothing
;                    a <> 0 to print it.
;
;       this routine for those printer that automatically insert
;       a lf on cr, or cr for lf.  Should this be shifted to 
;       the system indep. stuff, in say 4.06?
prtflt:
        mov     a,e             ; [30] get character to test
IF torch        ; strip out lf from printer stream
        ani     7fh             ; make sure it is parity less
        cpi     lf              ; is it a line feed?
        rnz                     ; no, print it
;       xra     a               ; yes, don't.
        
ENDIF   ;torch [30]
        ret


;
;
; system-dependent processing for BYE command.
;  for apmmdm, heath, and lobo, hang up the phone.
sysbye:
        ret
;
;       This is the system-dependent command to change the baud rate.
;       DE contains the two-byte value from the baud rate table; this
;       value is also stored in 'speed'.
sysspd:

; Set the speed for the Brain (Main Port)
IF brainm                       ;[25]
        lda     baudrt          ;Get the present baud rates.
        ani     0fH             ;turn off the left
        mov     d,a             ;Set it aside.
        mov     a,e             ;Get the new baud rate.
        rlc                     ;Shift left 4 places.
        rlc
        rlc
        rlc
        ora     d               ; combine with the old baud rate
        sta     baudrt          ;Store the new baud rates.
        out     baudst          ;Set the baud rates.
        ret
ENDIF;brainm

; Set the speed for the Brain (Aux Port)
IF braina                       ;[25]
        lda     baudrt          ;Get the present baud rates.
        ani     0f0H            ;turn off the right
        ora     e               ; combine with the new baud rate
        sta     baudrt          ;Store the new baud rates.
        out     baudst          ;Set the baud rates.
        ret
ENDIF;braina

If torch        ; Set speed for Torch [14] [32]
        mvi     a,7             ; Osbyte call to set rx rate
        mov     l,e
        call    osbyte          ; 
        mvi     a,8             ; set up for tx rate to be set
        mov     l,e
        call    osbyte
        ret                     ; and now, all rates should be different

ENDIF   ;torch  [14] [32]

IF ncrdmv	; Set baud rate for NCR Decision Mate V
	mvi	a,00		; clear command register
	out	mncmdw
	mvi	a,4eh		; set for 1 stop, 8 data bits
        out     mnmodw		; save in mode 1 port
        mvi     a,70h		; set bits for rate etc..
        add     e		; add baud rate (bits 0 - 3)
        out     mnmodw		; set mode port 2
        mvi     a,27h		; set tx/rx ready, RTS CTS active
        out     mncmdw
        ret
ENDIF   ; ncrdmv


IF pci2651      ; Set baud for PCI [28]
        in      mncmd           ; Clear register counter
        mvi     a,4eh           ; set for 1 stop, 8 data bits
        out     mnmode          ; save in mode 1 port
        mvi     a,30h           ; set bits for rate etc..
        add     e               ; add baud rate (bits 0 - 3)
        out     mnmode          ; set mode port 2
        mvi     a,27h           ; set tx/rx ready, RTS CTS active
        out     mncmd
        ret
ENDIF   ;pci2651 [28]

;
;       Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.

;       db      string length,string,divisor (2 identical bytes or 1 word)
; [Toad Hall]

IF brain OR pci2651 OR ncrdmv
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
ENDIF;brain OR pci2651 OR ncrdmv

IF torch        ;[17]
spdtbl: db      8               ; 8 entries
        db      4,'1200$',      4,4
        db      3,'150$',       2,2
        db      5,'19200$',     8,8
        db      4,'2400$',      5,5
        db      3,'300$',       3,3
        db      4,'4800$',      6,6
        db      2,'75$',        1,1
        db      4,'9600$',      7,7

sphtbl: db      cr,lf,'    75    150    300  1200  2400  4800  9600 19200$'
ENDIF;torch [17]


; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
;
;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:
IF iobyt
        mov     a,m             ;Get the I/O byte
        sta     prtiob          ;Save the desired IO byte for this port
        inx     h               ;Point at next entry
        mov     a,m             ;Get the output function
        sta     prtfun          ;Save it
ENDIF;iobyt

        ret
;
;
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
;
IF iobyt
prtfun: db      punout          ;Function to use for output to comm port
prtiob: db      batio           ;I/O byte to use for communicating
coniob: db      defio           ;I/O byte to use for console
ENDIF;iobyt

IF NOT iobyt
prttbl  equ     0               ; SET PORT is not supported
prhtbl  equ     0
ENDIF;NOT iobyt
;
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
        ret

selcon:
IF iobyt
        lda     coniob          ;Set up for output to go to the console port
        sta     iobyte          ;Switch directly
ENDIF;iobyt

        ret
;
;       Get character from console, or return zero.
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
;
;       Output character in E to the console.
;       destroys bc, de, hl
;
outcon:

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
;
;       outmdm - output a char from E to the modem.
;               the parity bit has been set as necessary.
;       returns nonskip; bc, de, hl preserved.
outmdm:
IF inout AND NOT ncrdmv
        in      mnprts          ;Get the output done flag.
        ani     output          ;Is it set?
        jz      outmdm          ;If not, loop until it is.
        mov     a,e
        out     mnport          ;Output it.
        ret
ENDIF;inout AND NOT ncrdmv

IF inout AND ncrdmv
	in	mnprts		;Get the output done flag
	ani	output		;Set ?
	jz	outmdm		;Loop until it is
	mov	a,e
	out	modtx		;output char
	ret
ENDIF;inout AND ncrdmv

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


IF torch        ; [32] [13] Torch stuff.  Requires some bit bashing
                ; via the BBC host computer (io computer)
                ; see also decription of osbyte later on
outdat:
        lda     prinuse         ; get the printer in use flag
        ana     a               ; if set, then must use traditional osbyte,
        jnz     outda2          ; else...
        push    b
        push    h               ; Preserve registers [32]
        call    tx
        db      1               ; MCP send to printer command
        mov     c,e             ; Byte to send is in E [32]
        call    txbyte
        pop     h
        pop     b
        ret

outda2:                         ; Preserve registers [32]
        push    h
        mvi     a,138           ; Osbyte insert byte into buffer
        mvi     l,2
        mov     h,e             ; get the byte to be sent s-l-o-w-l-y
        call    osbyte
        pop     h               ; Restore registers and exit
        ret

ENDIF   ;[13]

;
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

IF inout AND NOT ncrdmv
;Note: modem port should already be selected for mdI.  [Toad Hall]
        in      mnprts          ;Get the port status into A.
        ani     input           ;See if the input ready bit is on.
        rz                      ;If not then return.
        in      mnport          ;If so, get the char.
ENDIF;inout AND NOT ncrdmv

IF inout AND ncrdmv
	in	mnprts		;Get input port status
	ani	input		;Mask input RDY bit
	rz			;return if no char
	in	modrx		;get the char
ENDIF;inout AND ncrdmv
IF torch                        ; [32] [13] torch input
indat:
        push    h
        mvi     a,128
        lxi     h,0fffeh        ; Read buffer status
        call    osbyte
        mov     a,h             ; HL has number of characters
        ora     l               ; in the buffer
        jz      indatq          ; None, so skip fetch 
        mvi     a,145           ; Get character from input buffer [32]
        lxi     h,1
        call    osbyte          ; Result returned in 'Y', rather H
        mov     a,h
indatq:
        pop     h
        ani     7fh
        ret                     ; rx data in A
ENDIF ;torch [13] [32]

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
;
;       lptstat - get the printer status. Return a=0 if ok, or 0ffh if not.
lptstat:
IF torch
	mvi	a,80h		; read chars remaining in printer buffer
	mvi	l,252		; do osbyte 80H, X=252 (printer buffer)
	mvi	h,0ffh
	call	osbyte
	mov	a,h
	cpi	10		; 10 characters left?
	mvi	a,0		; if pos, yes r better
	rp
	mvi	a,0ffh
	ret
ENDIF	;torch

IF torch
	mvi	a,5		; got to select the real printer (par. port)
	mvi	l,1		; ie FX 5,1
	call	osbyte
ENDIF	;torch

IF iobyte       ;[33]
        call    bprtst          ; get status
ENDIF   ;iobyte[33]

IF torch
	push	psw
	mvi	a,5		; restore serial line = printer
	mvi	l,2		; ie FX 5,2
	call	osbyte
	pop	psw		; return with code in a
ENDIF	;torch


IF NOT iobyte   ;[33]
        xra     a               ; assume it is ok.. this may not be necessary
ENDIF   ;iobyte [33]
        ret
;
;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
        push    d               ; save DE in either case
        call    prtflt          ; go through printer filter [30]
        ana     a               ; if A = 0 do nothing,
        jz      outlp1          ; [30] if a=0 do nothing

IF torch        ;[30] Must set printer routed to par port
        mvi     a,5             ; fx 5,1 (parallel port selected for printer)
        mvi     l,1             ; Modified for new osbyte form [32]
        call    osbyte
ENDIF   ;torch [30]

IF NOT iobyt
        mvi     c,lstout
        call    bdos            ;Char to printer
ENDIF;NOT iobyt
IF iobyt
        mov     c,e
        call    blsout
ENDIF;iobyt
IF torch        ; re-route printer to serial port => faster tx bytes to line [30]
        mvi     a,5             ; Modified for new Osbyte form [32]
        mvi     l,2             ;fx 5,2
        call    osbyte
        mvi     a,6
        mvi     l,0             ;fx 6,0
        call    osbyte
ENDIF   ;torch [30]

outlp1: pop     d               ; restore saved register pair
        ret
;
;
;       Screen manipulation routines
;       csrpos - move to row B, column C
;
;       csrpos for terminals that use a leadin sequence followed
;        by (row + 31.) and (column + 31.)
;
IF brain
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
ENDIF;brain
;
;
IF torch
csrpos: push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; restore coordinates
        mov     a,l             ; [obs] get column
        adi     0ffh            ; NULL is column one
        mov     e,a
        push    h
        call    outcon          ; output row
        pop     h
        mov     a,h             ; [obs] get row
        adi     0ffh            ; NULL (ie decrement) is row one
        mov     e,a
        jmp     outcon          ; output it and return
ENDIF;torch 
;
;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:


IF NOT torch ;[22]
        mvi     e,bs            ;get a backspace
        jmp     outcon
ENDIF;NOT torch

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


IF torch        ;[13]
;
; OSBYTE call from Torch to BBC Base Processor.
;
;               A register has osbyte type
;               H register has equivalent Y register of 6502
;               L register has equivalent X register of 6502
;
;               Results (X and Y) are returned in HL respectively
;
;

usrimm  equ     0ffc0h          ; MCP user function [32]
tx      equ     0ffc3h          ; tx routine to talk to base board proc.
rx      equ     0ffc6h          ; rx ditto
txbyte  equ     0ffc9h          ; send C to base processor [32]

osbyte:                         ; Osbyte rewritten [32]
        push    b               ; Keep these
        mov     b,a             ; Local copy - use in a moment
        call    usrimm          ; MCP osbyte function
        db      15
        mov     c,b             ; Osbyte function
        call    txbyte
        mov     c,l             ; 6502 X register
        call    txbyte
        mov     c,h             ; 6502 Y register
        call    txbyte
        call    rx              ; fetch results
        mov     l,a             ; X returned
        sta     xx              ; save just in case...
        call    rx
        mov     h,a             ; Y returned
        sta     yy
        mov     a,b             ; return A as called
        pop     b
        ret                     

xx:     db      0
yy:     db      0               ; temporary space

prinuse:db      0               ; 0=> fast tx, <>0 => slow tx to serial pt. [30]

ENDIF   ;torch [13]

IF pci2651	; whatever version
sysver:	db	'Ithaca Intersystems S100$'
ENDIF	;pci2651

IF ncrdmv	; whatever version
sysver:	db	'NCR DecisionMate V$'
ENDIF	;ncrdmv

IF torch	; whatever version
ttytyp:
sysver:	db	'Torch Unicorn 5 '
	db	'$'	; stop here for now, otherwise say..
	db	' MCP version '
	db	'1.00   $'	; or whatever...
ENDIF	;torch

; Assume MCP - CCCP ROMS greater than 1
;mcpver:	db	'x.x $'
;outlin:	db	esc,'*',cr,lf,tab,'$'
;eralin:	db	cr,esc,'&$'		;Clear to end of line.
;erascr:	db	esc,'*$'	 	;Clear screen and go home.
;curldn:	db	esc,'=$'		;Cursor lead-in
;ttab:					;Table start location.
;ta:	
	db	esc,'!$',0		;Cursor up.
;tb:	db	0ah,'$',0,0		;Cursor down.
;tc:	db	esc,'+$',0		;Cursor right.
;td:	db	08h,'$',0,0		;Cursor left.
;te:	db	esc,'*$',0		;Clear screen and home cursor
;tf:	db	'$',0,0,0		;(can't) Enter Graphics mode
;tg:	db	'$',0,0,0		;(can't) Exit Graphics mode
;th:	db	esc,'>$',0		;Cursor home.
;ti:	db	'$',0,0,0		;(Can't) reverse linefeed
;tj:	db	esc,'%$',0		; Clear to end of screen
;tk:	db	esc,'&$',0		; Clear to end of line.


;Older message for MCP - CCCP verstion less than 1
;ooutli:	db	0ch,cr,lf,tab,tab,'$';
;oerali:	db	'$',0,0,0               ;Clear to end of line.
;oerasc:	db	0ch,'$',0               ;Clear screen and go home.
;ocurld:	db	1fh,'$',0               ;Cursor lead-in
;ottab:					;Table start location.
;	db	0bh,'$',0,0             ;Cursor up.
;	db	0ah,'$',0,0             ;Cursor down.
;	db	09h,'$',0,0             ;Cursor right.
;	db	08h,'$',0,0             ;Cursor left.
;	db	0ch,'$',0,0             ;Clear screen and home cursor
;	db	'$',0,0,0               ;(can't) Enter Graphics mode
;	db	'$',0,0,0               ;(can't) Exit Graphics mode
;	db	1eh,'$',0,0             ;Cursor home.
;	db	0bh,'$',0,0             ;reverse linfeed
;	db	'$',0,0,0               ;(Can't) Clear to end of screen
;	db	'$',0,0,0               ;(Can't) Clear to end of line.
;
;Specials
;spac15:	db	'               '
;	db	bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,'$';
;spac80:	db	cr
;	db	'                                        '
;	db	'                                        '
;	db	bs,cr,'$'       ;80 spaces, bs and then back to line start
;

IF torch	; Should be IF ker08 AND torch...
	db	'$'			; to terminate the ID string
outlin:	db	0ch,cr,lf,tab,tab,'$'
eralin:	db	'$',0,0,0               ;Clear to end of line.
erascr:	db	0ch,'$',0               ;Clear screen and go home.
curldn:	db	1fh,'$',0               ;Cursor lead-in
ttab:					;Table start location.
ta:	db	0bh,'$',0,0             ;Cursor up.
tb:	db	0ah,'$',0,0             ;Cursor down.
tc:	db	09h,'$',0,0             ;Cursor right.
td:	db	08h,'$',0,0             ;Cursor left.
te:	db	0ch,'$',0,0             ;Clear screen and home cursor
tf:	db	'$',0,0,0               ;(can't) Enter Graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1eh,'$',0,0             ;Cursor home.
ti:	db	0bh,'$',0,0             ;reverse linfeed
tj:	db	'$',0,0,0               ;(Can't) Clear to end of screen
tk:	db	'$',0,0,0               ;(Can't) Clear to end of line.

;Specials
spac15:	db	'               '
	db	bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,bs,'$';
spac80:	db	cr
	db	'                                        '
	db	'                                        '
	db	bs,cr,'$'       ;80 spaces, bs and then back to line start

ENDIF;ker08 AND torch     [13]

IF brain
sysver:	db	'Intertec SuperBrain$'
outlin:	db	('A'-100O),esc,'~k',cr,lf,tab,tab,'$'
erascr:	db	('A'-100O),esc,'~k$'    ;Clear screen and go home.
eralin:	db	cr,esc,'~K$'            ;Clear line.
curldn:	db	esc,'Y$'                ; leadin for cursor positioning
ttab:					;Table start location.
ta:	db	('K'-100O),'$',0,0      ;Cursor up.
tb:	db	12O,'$',0,0             ;Cursor down.
tc:	db	('F'-100O),'$',0,0      ;Cursor right.
td:	db	'$',0,0,0               ;(can't) Cursor left
te:	db	'$',0,0,0               ;(can't) Clear display
tf:	db	'$',0,0,0               ;(can't) Enter graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit graphics mode
th:	db	('A'-100O),'$',0,0      ;Cursor home.
ti:	db	('K'-100O),'$',0,0      ;Reverse linefeed.
tj:	db	esc,'~k$',0             ;Clear to end of screen.
tk:	db	esc,'~K$',0             ;Clear to end of line.
ENDIF;brain

IF lasm and not termin	; we dont want CPXVDU
ovlend	equ	$		;Overlay end - start buffer
	end
ENDIF	;lasm and not termin

IF lasm; we want a terminal
LINK CPXVDU.ASM
ENDIF	;lasm

