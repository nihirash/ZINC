IF NOT LASM
.printx * CPXNOR.ASM *
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
;       This file contains the system-dependent code and data for various
;       NorthStar KERMITs.  This has the Family name of CPXNOR.ASM.
;
; revision history (last edit first)
;
;edit 4, 16-Jan-1991 by MF. Fixed a bug in OUTCON wherein the final RET
;	was missing (bug reported by David P. Arnot of Scottish
;	Agricultural College).
;edit 3, 12-Oct-1990 by MF.  Added a semicolon before the comment
;	beginning "Family is the string so we don't get errors
; edit 2, 23 July, 1987 by OBSchou to massage file to suit CPXCOM.ASM.
;
; edit 1:  1 June, 1986 by OBSchou, Loughborogh University, UK.
;       Hived off northstar and Comart system dependent modules from 
;       CPXSYS.ASM.  This assembles ok, but I cannot test it.  Any comments?


IF norths
.printx	* Assembling for NorthStar Horizon with	HSIO-4 board *
ENDIF;norths

IF horizon	;[25]
.printx	* Assembling KERMIT-80 for the NorthStar Horizon *
ENDIF;horizon

IF advant	;[22]
.printx	* Assembling kermit-80 for North Star Advantage	*
ENDIF	;[22]

IF basicns	;[29]
.printx	* Assembling KERMIT-80 for the Northstar Horizon using printer port *
ENDIF	;basicns [29]

IF comart
.printx	* Assembling KERMIT-80 for Comart Communicator *
ENDIF ; comart

; the basics...
IF norths ;The basic Northstar Horizon BIOS does not access ports 2-5
port0d	equ	02h		;Port 0 data (console)
port0s	equ	03h		;Port 0 status
port1d	equ	04h		;Port 1 data (printer)
port1s	equ	05h		;Port 1 status

port2b	equ	10h		;Port 2 baud
port2i	equ	11h		;Port 2 interrupt mask
port2d	equ	12h		;Port 2 data
port2s	equ	13h		;Port 2 status

port3b	equ	14h		;Port 3 baud
port3i	equ	15h		;Port 3 interrupt mask
port3d	equ	16h		;Port 3 data
port3s	equ	17h		;Port 3 status

port4b	equ	18h		;Port 4 baud
port4i	equ	19h		;Port 4 interrupt mask
port4d	equ	1Ah		;Port 4 data
port4s	equ	1Bh		;Port 4 status

port5b	equ	1Ch		;Port 5 baud
port5i	equ	1Dh		;Port 5 interrupt mask
port5d	equ	1Eh		;Port 5 data
port5s	equ	1Fh		;Port 5 status

NS19K2	EQU	00H		;19.2 kilobaud
NS9600	EQU	01H		;9600 baud
NS4800	EQU	02H		;4800 baud
NS2400	EQU	03H		;2400 baud
NS1200	EQU	04H		;1200 baud
NS0600	EQU	05H		; 600 baud
NS0300	EQU	06H		; 300 baud
NS0110	EQU	07H		; 110 baud
;; Set to use port 5 at 1200 baud
mnport	equ	port5d		;Data port
mnprts	equ	port5s		;Status port
baudrt	equ	port5b		;Baud rate port
baudini	equ	ns1200		;Initial baud rate
output	EQU	1		;Bit of UART status for transmitter ready
input	EQU	2		;Bit of UART status for receiver ready
z80	EQU	TRUE		;This one's a Z80.
ENDIF;norths

IF basicns	;[29]
mnport	equ	04h		;printer port data
mnprts	equ	05h		; printer port status
output	equ	1		;transmitter ready
input	equ	2		;receiver ready
z80	equ	FALSE		; not important
ENDIF	;basicns [29]

IF horizon		;[25]
mnport	EQU	004H	;Modem data port
mnprts	EQU	005H	;Modem status port
output	EQU	01H	;Transmitter empty
input	EQU	02H	;Input data available
TxEmpty	EQU	04h	;Transmitter empty
;Note:  Needs terminal definition (vt100, vt52, tvi925, adm3a or crt above)
z80	EQU	TRUE	;This one's a Z80.
ENDIF;horizon

IF advant	;[22]
vtval	EQU	1		; we do emulation of VT52s
slot	EQU	1		;SIO card slot
mnport	EQU	(6-slot)*16	;Modem data port
mnprts	EQU	mnport+1	;Modem status port
baudrt	EQU	mnport+8	;Baud rate register
output	EQU	01H		;Transmitter buffer empty
input	EQU	02H		;Input data available
TxEmpty	EQU	04h		;Transmitter empty flag
z80	EQU	TRUE
ENDIF;[22] advant

IF comart		;[25]
mnport	EQU	002H	;Modem data port
mnprts	EQU	003H	;Modem status port
output	EQU	01H	;Transmitter empty
input	EQU	02H	;Input data available
TxEmpty	EQU	04h	;Transmitter empty
;Note:  Needs terminal definition (vt100, vt52, tvi925, adm3a or crt above)
z80	EQU	TRUE	;This one's a Z80.
ENDIF;comart


IF advant
defesc	EQU	'\'-100O
ENDIF;advant

;
;      Family is the string used in VERSION to say which of several 
;       smaller overlay files are used.  These are (will be) derived from 
;       the juge CP4SYS.ASM file, in which case we will never get here.  
;       Just a Dollar, but put a sting in for a family of machines.
;
family:	db	'CPXNOR.ASM  (4)  16-Jan-1991$'    ; Used for family versions....



sysxin:		; continuation of system dependent initialisation code
IF advant	;[22]
	mvi	a,40h
	out	mnprts		; Reset USART
	lxi	h,7070h		; Default to 1200 baud
	shld	speed		; store current speed
	xchg
	call	sysspd		; set default baud rate
	mvi	a,4Eh		; Set UART mode to async 16x clock, 8 data
	out	mnprts		;    bits, no parity, and 1 stop bit
	mvi	a,37h		; Set command to Tx enable, DTR on, Rx enable,
	out	mnprts		;    break off, error reset, and RTS on
ENDIF;[22] advant

IF norths
	mvi	a,baudini	;Get initial speed
	out	baudrt
	sta	speed		;save for status display
	sta	speed+1
ENDIF;norths

IF comart OR horizon		;[25]
; The PD8251/PD8251A is reset by three successive 00 Hex or two
; successive 80 Hex command instructions followed by a software
; reset command instruction (40 Hex).
	mvi	a,80h		; Send UART reset
	out	mnprts
	mvi	a,80h
	out	mnprts
	mvi	a,40h
	out	mnprts
	mvi	a,4Eh		; Set UART mode to async 16x clock, 8 data
	out	mnprts		;    bits, no parity, and 1 stop bit
	mvi	a,37h		; Set command to Tx enable, DTR on, Rx enable,
	out	mnprts		;    break off, error reset, and RTS on
ENDIF;comart OR horizon


	ret			; return from system-dependent routine
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

conmsg:		; Messages printed when entering transparent (CONNECT) mode:
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
IF advant OR comart OR horizon ; some more
	lxi	d,inhlps	; we got options...
	call	prtstr		; print them.
ENDIF;[22] advant OR comart OR horizon [29]

	ret


;additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:

; [16] [18] have added super brain and Torch to the list of Breaking machines.
IF advant OR comart OR horizon ; ... some more
	db	cr,lf,'B  Transmit a BREAK'
ENDIF;[22] advant OR comart OR horizon

	db	'$'                     ;[hh] table terminator

;
;       sysint - system dependent special functions
;       called when transparent escape character has been typed;
;       the second character of the sequence is in A (and in B).
;       returns:
;       non-skip: sequence has been processed
;       skip:   sequence was not recognized
sysint:	ani	137O		; convert lower case to upper, for testing...
IF advant OR comart OR horizon	; [22] [25] ... some more
	cpi	'B'             ; send break?
	jz	sendbr		; yes, go do it.  return nonskip when through.
ENDIF;advant OR comart OR horizon [32]

	jmp	rskp		; take skip return - command not recognized.


;

IF advant OR comart OR horizon	;[lmj] 
sendbr:
;
;       Ensure that the transmitter has finished sending buffered chars
sndbr1:	in	mnprts		; get UART status
	ani	TxEmpty		; everything sent?
	jz	sndbr1		; no, wait a bit more
;
;       Begin sending a break by setting bit in UART command register
	mvi	a,3Fh		; Set TxEna, DTR, RxEna, SBreak, ErrRst, RTS
	out	mnprts
;
;       Wait for 250 milliseconds (using hundredths second delay routine)
	mvi	a,25
	call	delay
;
;       Resume normal operation by clearing the SendBreak command bit
	mvi	a,37h		;Set TxEna, DTR, RxEna, ErrRst, RTS
	out	mnprts
;
	ret			;done
ENDIF;advant OR comart OR horizon

;

;
;       sysflt - system-dependent filter
;       called with character in E.
;       if this character should not be printed, return with A = zero.
;       preserves bc, de, hl.
;       note: <xon>,<xoff>,<del>, and <nul> are always discarded.
sysflt:
	mov	a,e		; get character for testing
IF advant	;[22]
	cpi	'D'-100O        ;Control-D's reset video
	rnz			; if not control-D, it's ok.
	xra	a		; don't allow control-D out.
ENDIF;[22] advant
	ret

;       mdmflt - modem filter [30]
;       called with character to be sent to printer in E
;       with parity set as appropriate.
;       return with accumulator = 0 do do nothing,
;                               <> 0 to send char in E.
mdmflt:
	mov	a,e		;[30] get character to test
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
	mov	a,e		; [30] get character to test
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
IF norths OR advant ;
	mov	a,e		; get the parsed value
	out	baudrt		; Tell the baud rate generator.
	ret
ENDIF;norths OR advant 

IF advant	;[22]
spdtbl:	db	6			; 6 entries
	db	04,'1200$',     70h,70h
	db	04,'2400$',     78h,78h
	db	03,'300$',      40h,40h
	db	04,'4800$',     7Ch,7Ch
	db	03,'600$',      60h,60h
	db	04,'9600$',     7Eh,7Eh

sphtbl:	db	cr,lf,'   300    600    1200    2400    4800    9600$'
ENDIF;[22] advant


IF norths
spdtbl:	db	8		; 8 entries
	db	3,'110$',       07H,07H
	db	4,'1200$',      04H,04H
	db	5,'19200$',     00H,00H
	db	4,'2400$',      03H,03H
	db	3,'300$',       06H,06H
	db	4,'4800$',      02H,02H
	db	3,'600$',       05H,05H
	db	4,'9600$',      01H,01H


sphtbl:	db	cr,lf
	db	'   110   300   600  12000  2400  4800  9600 19200$'
ENDIF;norths

; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
IF NOT (advant OR norths)
spdtbl	EQU	0		;[hh] SET BAUD not supported.
sphtbl	EQU	0		;[hh] ran out of room above...
ENDIF	;NOT (advant OR norths)
;
;

;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:
	ret

prttbl	equ	0		; SET PORT not supported
prhtbl	equ	0
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
selcon:
	ret
;

;       Get character from console, or return zero.
;       result is returned in A.  destroys bc, de, hl.
;
inpcon:
	mvi	c,dconio	;Direct console I/O BDOS call.
	mvi	e,0FFH		;Input.
	call	BDOS
	ret
;

;
;       Output character in E to the console.
;       destroys bc, de, hl
;
outcon:
	mvi	c,dconio	;Console output bdos call.
	call	bdos		;Output the char to the console.
	ret			;[MF]per David P. Arnot
;

;
;       outmdm - output a char from E to the modem.
;               the parity bit has been set as necessary.
;       returns nonskip; bc, de, hl preserved.
outmdm:
	in	mnprts		;Get the output done flag.
	ani	output		;Is it set?
	jz	outmdm		;If not, loop until it is.
	mov	a,e
	out	mnport		;Output it.
	ret
;

;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
;Note: modem port should already be selected for mdI.  [Toad Hall]
	in	mnprts		;Get the port status into A.
	ani	input		;See if the input ready bit is on.
	rz			;If not then return.
	in	mnport		;If so, get the char.
	ret			; return with character in A


;
;       flsmdm - flush comm line.
;       Modem is selected.
;       Currently, just gets characters until none are available.

flsmdm:	call	inpmdm		; Try to get a character
	ora	a		; Got one?
	jnz	flsmdm		; If so, try for another
	ret			; Receiver is drained.  Return.
;

;
;       lptstat - get the printer status. Return a=0ffh if ok, or 0 if not.
lptstat:
	xra	a		; assume it is ok.. this may not be necessary
	ret

;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
	push	d		; save DE in either case
	call	prtflt		; go through printer filter [30]
	ana	a		; if A = 0 do nothing,
	jz	outlp1		; [30] if a=0 do nothing
	mvi	c,lstout
	call	bdos		;Char to printer
outlp1:	pop	d		; restore saved register pair
	ret
IF advant	; all others require terminals
;

;
;       Screen manipulation routines
;       csrpos - move to row B, column C
;
;       csrpos for terminals that use a leadin sequence followed
;        by (row + 31.) and (column + 31.)
;
csrpos:	push	b		; save coordinates
	lxi	d,curldn	; get cursor leadin sequence
	call	prtstr		; print it
	pop	h		; restore coordinates
	mov	a,h		; get row
	adi	(' '-1)         ; space is row one
	mov	e,a
	push	h
	call	outcon		; output row
	pop	h
	mov	a,l		; get column
	adi	(' '-1)         ; space is column one
	mov	e,a
	jmp	outcon		; output it and return
ENDIF	;advant

;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:
IF advant		;[22]
	ret
ENDIF;advant 
IF NOT (advant );[22]
	mvi	e,bs		;get a backspace
	jmp	outcon
ENDIF;NOT (advant) [22]

; erase the character at the current cursor position
clrspc:	mvi	e,' '
	call	outcon
	mvi	e,bs		;get a backspace
	jmp	outcon

; erase the current line
clrlin:	lxi	d,eralin
	jmp	prtstr

; erase the whole screen, and go home. preserves b (but not c)
clrtop:	lxi	d,erascr
	jmp	prtstr


IF norths
sysver:	db	'Northstar Horizon$'
ENDIF;norths

IF basicns	;[29]
sysver:	db	'Northstar using printer port$'
ENDIF	;basicns [29]

IF comart	;[25]
sysver:	db	'Comart Communicator$'
ENDIF;comart

IF horizon	;[25]
sysver:	db	'Northstar Horizon$'
ENDIF;horizon

IF advant	;[22]
sysver:	db	'North Star Advantage$'
outlin:	db	04H,cr,lf,tab,'$'
erascr:	db	04H,'$'                 ;Clear screen and go home.
eralin:	db	cr,0EH,'$'              ;Clear line.
curldn:	db	esc,'=$'                ;cursor leadin
ttab:					;Table start location.
ta:	db	0BH,'$',0,0             ;Cursor up.
tb:	db	0AH,'$',0,0             ;Cursor down.
tc:	db	0CH,'$',0,0             ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left
te:	db	04H,'$',0,0             ;Clear display
tf:	db	12H,'$',0,0             ;Enter Graphics Mode
tg:	db	13H,'$',0,0             ;Exit Graphics mode
th:	db	1EH,'$',0,0             ;Cursor home.
ti:	db	0BH,'$',0,0             ;Reverse linefeed.
tj:	db	0FH,'$',0,0             ;Clear to end of screen.
tk:	db	0EH,'$',0,0             ;Clear to end of line.
ENDIF;[22] advant
IF lasm AND (NOT advant)
LINK CPXVDU.ASM
ENDIF   ;lasm - m80 will INCLUDE CPXVDU.ASM

IF lasm	; here if not a terminal selected and in LASM
ovlend	equ	$
	END
ENDIF	;lasm
