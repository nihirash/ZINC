IF NOT lasm
.printx * CPXBBI.ASM *
ENDIF	;NOT lasm
;       KERMIT - (Celtic for "FREE")
;
;       This is the CP/M-80 implementation of the Columbia University
;       KERMIT file transfer protocol.
;
;       Version 4.08
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
;
;
; revision history:
;
;edit 4, 7-Jan-1991 by MF. Added code to support the Ampro Little Board.
;	The code was contributed by Jay S. Rouman; 913 North Drive;
;	Mt. Pleasant, MI 48858 (voice (517)773-7887).
; edit 3, 23 July by OBSchou to massage file to suit CPXCOM.ASM
;
; edit 2 23 May 1987 by C.J.MILES@UMRCC.
;	Reorganised file to be similar in structure to that
;	of the Amstrad sys-dep file. Added hangup in clear
;	screen options in CONNECT mode.
;
; edit 1 10 May 1987 by Chris Miles (C.J.MILES@UMRCC)
;        Removed Kaypro, Xerox and Big Board from CPXSYS.ASM
;        and grouped them into this file as CPXBBI.ASM.
;
;
;
; Original code broken off and modified by:
;
; Chris Miles
; 344, Claremont Road,
; Rusholme,
; MANCHESTER,
; M14 6WB.
;
; Tel: (061) 226 7839
;

;
; 		*** MAIN CODE START ***
;
;
; Keep module name, edit number, and last revision date in memory.

sysedt: db      'CPXSYS.ASM (35) 01-Dec-86$'
family: db	'CPXBBI.ASM (4)  7-Jan-1991$'


; Assembly time message announcing which version we're building

IF kpii
.printx * Assembling Kaypro II KERMIT-80 *
ENDIF

IF xer820
.printx * Assembling Xerox 820 KERMIT-80 *
ENDIF

IF bbII
.printx * Assembling BigBoard II KERMIT-80 *
ENDIF

IF ampro
.printx * Assembling Ampro Little Board KERMIT-80 *
ENDIF

z80	EQU	TRUE	; They all use Z80s

IF xer820
defesc  EQU     ']'-100O        ;The default escape character for Xerox
ENDIF;xer820

IF kpII
defesc  EQU     '\'-100O        ;The default escape character for Kaypro
ENDIF;kpII

; If one of the above, default to VT52-EMULATION ON.
IF kpII OR xer820
vtval   EQU     1
ENDIF;kpII OR xer820


;
; Specific machine hardware information
;
IF bbI
mnport  equ     04h             ; Modem data port
mnprts  equ     06h             ; Modem status port
output  equ     04h             ; Transmit buffer empty
input   equ     01h             ; Receive data available
baudrt  equ     00h             ; Baud rate port for channel A
ENDIF;bbI


IF bbII
mnport  equ     80h             ; Modem data port (SIO channel A)
mnprts  equ     81h             ; Modem status port
output  equ     04h             ; Transmit buffer empty
input   equ     01h             ; Receive data available
baudrt  equ     89h             ; Baud rate port for channel A
ENDIF;bbII

IF ampro
mnport  equ     88h             ; Modem data port (SIO channel B)
mnprts  equ     8Ch             ; Modem status port
output  equ     04h             ; Transmit buffer empty
input   equ     01h             ; Receive data available
baudrt  equ     50h             ; Baud rate port for channel B
ENDIF;ampro
;

sysxin:		;continuation of system initialisation code
        lxi     d,siotbl        ; Load the address of the status able
        mvi     c,siolen        ; Length of status table
siolup: 			; Loop back here for each command byte
        ldax    d               ; Load the first byte into A
        inx     d               ; Index the pointer
        out     mnprts          ; Send it to the status port
        dcr     c               ; Decrement the byte counter
        jnz     siolup          ; Jump back for more commands
        ret                     ; return from system-dependent routine

; List of commands to set up SIO channel A for asynchronous operation.

siotbl: DB      18H             ; Channel reset
        DB      18H             ; another, in case register 0 wasn't selected
        DB      04H             ; Select register 4
        DB      44H             ; 1 stop bit, clock*16
        DB      01H             ; Select register 1
        DB      00H             ; No interrupts enabled
        DB      03H             ; Select register 3
        DB      0C1H            ; Rx enable, 8 bit Rx character
        DB      05H             ; Select register 5
        DB      0EAH            ; Tx enable, 8 bit Tx character,
                                ;  raise DTR and RTS
siolen  equ     $-siotbl        ; length of command list


;
; sysexit - System-dependent termination processing
; 	    if we've changed anything, this is our last
;	    chance to put it back.
;
sysexit:
        ret

;
; syscon - System-dependent processing for start
;	   of CONNECT command.
;
syscon:
	lxi	d,conmsg
	call	prtstr
        ret

conmsg:         ; Messages printed when entering transparent (CONNECT) mode:
	db	cr,lf,'$'
;
; syscls - system-dependent close routine
;          called when exiting transparent session.
;
syscls:
        ret
;
; sysinh - help for system-dependent special functions.
;          called in response to <escape>?, after listing
;          all the system-independent escape sequences.
;
sysinh:
        lxi     d,inhlps        ; we got options...
        call    prtstr          ; print them.
        ret


; additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:
        db      cr,lf,'B  Transmit a BREAK'
	db	cr,lf,'H  Hangup using DTR'
	db	cr,lf,'W  Wipe screen clear'
	db	'$'

; sysint - system dependent special functions
;          called when transparent escape character has been typed;
;          the second character of the sequence is in A (and in B).
;          returns:-
;                non-skip: sequence has been processed
;                skip    : sequence was not recognized
;
sysint: ani     137O            ; convert lower case to upper, for testing...
        cpi     'B'             ; send break ?
        jz      sendbr          ; then jump to send break routine
	cpi	'H'		; hang up ?
	jz	hangup		; then jump to hangup routine
	cpi	'W'		; clear screen ?
	jz	clrtop		; then jump to clear screen routine
        jmp     rskp            ; take skip return - command not recognized.

;
; Hangup and Break routines
;
hangup:
	mvi	d,0ah		; set up hangup bit mask
	mvi	e,255		; time for hangup is 2 1/2 secs
	jmp	setbit		; skip Tx empty test

sendbr:
	mvi	d,9ah		; set up break bit mask
	mvi	e,30		; time for break is 300 ms

sndbr1: mvi     a,1             ; select Read Register 1
        out     mnprts
        in      mnprts          ; read the contents
        ani     1               ; test "all done" flag
        jz      sndbr1          ; loop until it's nonzero.
;
; Next, set the break or DTR bit on the SIO
;
setbit:	
	mvi     a,5		; select Write Register 5
        out     mnprts
        mvi     a,6ah		; Tx enable, 8 bit Tx character,
	ora	d		; OR with appropriate bit mask
	out     mnprts          ; 
;
;       Now, delay for duration of hangup or break
        mov     a,e		; delay count
        call    delay
;
;       Time's up. Put transmitter back in normal state and return.
        mvi     a,5             ; select Write Register 5
        out     mnprts
        mvi     a,0eah		; Tx enable, 8 bit Tx character,
        out     mnprts          ;.
        ret                     ; done.

; sysflt - system-dependent filter
;          called with character in E.
;          if this character should not be printed, return with A = zero.
;          preserves bc, de, hl.
;          note: <xon>,<xoff>,<del>, and <nul> are always discarded.
;
sysflt:
        mov     a,e             ; get character for testing
	ret

;
; sysbye - system-dependent processing for BYE command.
;
sysbye:
        ret
;
; This is the system-dependent command to change the baud rate.
; DE contains the two-byte value from the baud rate table; this
; value is also stored in 'speed'.
;
sysspd:

; Set the speed for bigboard II
IF bbII
        di                      ; don't let anything between the data bytes
        mvi     a,01000111b     ; get the command byte (load time constant)
        out     baudrt          ; output it to CTC
        mov     a,e             ; Get the parsed value.
        out     baudrt          ; Tell the baud rate generator.
        ei                      ; end of critical section
        ret
ENDIF;bbII


; Set the speed for bigboard I
IF bbI
        mov     a,e             ; get the parsed value
        out     baudrt          ; Tell the baud rate generator.
        ret
ENDIF;bbI

; set the speed for the Ampro Little Board
if ampro
	mvi	e,3fh		; offset to port b ctc 3f hex bytes
	call	getbios
	mvi	a,47h		; counter mode,ctc reset,value follows
	mov	m,a		; store value
	lda	speed+1		; get ctc divisor
	inx	h		; location of ctc divisor
	mov	m,a		; store new divisor
;
; set up wr4 clock divisor according to mspeed
;
	mvi	e,50h		; offset to dart wr4
	call	getbios
	mvi	a,3fh		; mask for wr4 clock bits
	ana	m		; mask off bits
	mov	m,a		; and save to wr4
	lda	speed		; get clock flag
	ora	a		; set flags, zero = 300 bps
	mvi	a,80h		; x32 clock bit
	jz	lbps		; setup wr4 for 300 bps x32 clock
;
;  set up wr4 value for 1200 bps x16 clock 'hl' has wr4 loc
;
hbps:	mvi	a,40h		; x16 clock
;
;  setup wr4 value for 300 bps x32 clock 'hl' has wr4 loc
;
lbps:	ora	m		; set clock bits saving parity
	mov	m,a		; store new clock divisor to wr4 value
;
;  initialize sio/dart
;
intsio:	lxi	h,intend
	push	h		; set up for return
	mvi	e,36h		; offset to ioinit
	call	getbios
	pchl			; we pushed return address
intend:	ret

;
;  return bios location in 'hl' called with offset in 'e'
;
getbios:
	lhld	1		; get bios location
	mvi	d,0		; clear 'd'
	dad	d
	ret
;
ENDIF;ampro

;
;       Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.

;       db      string length,string,divisor (2 identical bytes or 1 word)
; [Toad Hall]

IF bbI
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
ENDIF;bbI

IF bbII
spdtbl: db      8                       ; 8 entries
        db      04h,'1200$',    20h,20h
        db      05h,'19200$',   02h,02h
        db      04h,'2400$',    10h,10h
        db      03h,'300$',     80h,80h
        db      05h,'38400$',   01h,01h
        db      04h,'4800$',    08h,08h
        db      03h,'600$',     40h,40h
        db      04h,'9600$',    04h,04h

sphtbl: db      cr,lf,'   300   600  1200  2400  4800  9600 19200 38400$'
ENDIF;bbII


IF ampro
spdtbl: db      6                       ; 6 entries
        db      04h,'1200$',    1,104
        db      04h,'2400$',    1,52
        db      03h,'300$',     0,208
        db      04h,'4800$',    1,26
        db      03h,'600$',     1,208
        db      04h,'9600$',    1,13

sphtbl: db      cr,lf,'   300  600  1200  2400  4800  9600$'
ENDIF;ampro

; This is the system-dependent SET PORT command.
; HL contains the argument from the command table.
;
sysprt:
        ret
;

prttbl  equ     0               ; SET PORT is not supported
prhtbl  equ     0

;
; selmdm - select modem port
; selcon - select console port
; selmdm is called before using inpmdm or outmdm;
; selcon is called before using inpcon or outcon.
; preserves BC, DE, HL.
;
selmdm:
selcon:
        ret
;
; Get character from console, or return zero.
; result is returned in A.  destroys bc, de, hl.
;
inpcon:
        mvi     c,dconio        ;Direct console I/O BDOS call.
        mvi     e,0FFH          ;Input.
        call    BDOS
        ret
;
;
;       Output character in E to the console.
;       destroys bc, de, hl
;
outcon:

        mvi     c,dconio        ;Console output bdos call.
        call    bdos            ;Output the char to the console.

        ret
;
;
;       outmdm - output a char from E to the modem.
;               the parity bit has been set as necessary.
;       returns nonskip; bc, de, hl preserved.
outmdm:
        in      mnprts          ;Get the output done flag.
        ani     output          ;Is it set?
        jz      outmdm          ;If not, loop until it is.
        mov     a,e
        out     mnport          ;Output it.
        ret


;
;       get character from modem; return zero if none available.
;       destroys bc, de, hl.
inpmdm:
        in      mnprts          ;Get the port status into A.
        ani     input           ;See if the input ready bit is on.
        rz                      ;If not then return.
        in      mnport          ;If so, get the char.

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
        xra     a               ; assume it is ok.. this may not be necessary
        ret

;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
        push    d               ; save DE in either case
        ana     a               ; if A = 0 do nothing,
        jz      outlp1          ; [30] if a=0 do nothing
        mvi     c,lstout
        call    bdos            ;Char to printer
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
IF NOT (bbII OR ampro)			;[obs I think ]
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
ENDIF	; NOT bbII OR ampro

;
; delchr - make delete look like a backspace.  Unless delete is a
;          printing character, we just need to print a backspace
;          (we'll output clrsp afterwards)
delchr:

IF bbI
        lxi     d,delstr
        jmp     prtstr
ENDIF;bbI


IF NOT bbI
        mvi     e,bs            ;get a backspace
        jmp     outcon
ENDIF;NOT bbI

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

; If its a BigBoard or Ampro, we need a terminal, so link to CPXVDU.ASM
IF bbII
sysver:	db	'Big Board II$'
ENDIF;bbII

IF ampro
sysver:	db	'Ampro Little Board$'
ENDIF;ampro

IF (bbII AND lasm)	; we need a terminal as well
LINK CPXVDU.ASM
ENDIF	;(bbII AND lasm)

IF (ampro AND lasm)	; we need a terminal as well
LINK CPXVDU.ASM
ENDIF	;(ampro AND lasm)

;If here, we are Kaypro or Xerox 820, or if from M80, we should skip
; a few lines if Bigboard.

IF kpii
sysver:
ttytyp:	db	'Kaypro II$'
outlin:	db	subt,cr,lf,tab,tab,'$'
erascr:	db	subt,'$'                ;Clear screen and home.
eralin:	db	cr,18H,'$'              ;Clear line.
curldn:	db	esc,'=$'                ;Cursor lead-in
delstr:	db	bs,' ',bs,bs,'$'        ; adjust for echoing delete character
ttab:					;Table start location.
ta:	db	0BH,'$',0,0             ;Cursor up.
tb:	db	0AH,'$',0,0             ;Cursor down.
tc:	db	0CH,'$',0,0             ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left
te:	db	subt,'$',0,0            ;Clear display
tf:	db	esc,'G$',0              ; Enter Graphics Mode (select Greek)
tg:	db	esc,'A$',0              ; Exit Graphics mode (select ASCII)
th:	db	1EH,'$',0,0             ; Cursor home.          [UTK016]
ti:	db	esc,'E','$',0           ; Reverse linefeed. (insert line)
tj:	db	'W'-100O,'$',0,0        ; Clear to end of screen.
tk:	db	'X'-100O,'$',0,0        ; Clear to end of line.
ENDIF ; kpii
;

IF xer820
ttytyp:
sysver:	db	'Xerox 820$'
outlin:	db	subt,cr,lf,tab,tab,'$'
erascr:	db	subt,'$'                ;Clear screen and home.
eralin:	db	cr,18H,'$'              ;Clear line.
curldn:	db	esc,'=$'                ;Cursor lead-in
delstr:	db	bs,' ',bs,bs,'$'        ; adjust for echoing delete character
ttab:					;Table start location.
ta:	db	0BH,'$',0,0             ;Cursor up.
tb:	db	0AH,'$',0,0             ;Cursor down.
tc:	db	0CH,'$',0,0             ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left
te:	db	subt,'$',0,0            ;Clear display
tf:	db	'$',0,0,0               ; Enter Graphics Mode (can't)
tg:	db	'$',0,0,0               ; Exit Graphics mode (can't)
th:	db	1EH,'$',0,0             ; Cursor home.          [UTK016]
ti:	db	0BH,'$',0,0             ; Reverse linefeed. (cursor up)
tj:	db	11H,'$',0,0             ; Clear to end of screen.
tk:	db	18H,'$',0,0             ; Clear to end of line.
ENDIF ; xer820
ovlend	equ	$	; End of overlay

	END
