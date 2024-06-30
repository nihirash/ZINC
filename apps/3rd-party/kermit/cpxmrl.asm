IF NOT lasm
.printx * CPXMRL.ASM *
ENDIF	; NOT lasm
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
; CPXMRL.ASM created 16 July, 1987 from submitted code by William Rose.
;
;	Kermit system dependent file for Rair Black Box (British Telecom
;	Merlin, ICL PC etc) originally submitted by William Rose, and
;	modified by OBSchou to work with the Kermit-80 V4.08 and later 
;	files.  Wills original overlay file a stripped down CPXSYS.ASM
;	file.
;
; KERSYS.ASM - version 0.6A dated 17 Jun 87.
;
; Cutdown CP4SYS.ASM for Telecom Merlin M2215 only. (ICL PC, Rair Black Box)
;
; This uses TTY1: only, and cannot alter it's parameters.  It resets the 
; interrupt flag to prevent use of the buffer, and is generally a kludge.
; However it runs at 4800 baud, and tidying the code might get 9600.
;
; Revision History (Last entry first)
;
; edit 2, 22 July by OBSchou to massage frile to fit with CPXCOM.ASM
;
; edit 1, 17 July by OBSchou for Will Rose, to make file suitable for V4.08
;	overlay etc.
;
; Keep module name, edit number, and last revision date in memory.
;
family:	db	'CPXMRL.ASM (2)  22-Jun-87  $'	; Telecom Merlin added

;
; Assembly time message to let me know I'm building the right version.
;

IF m2215
 .printx * Assembling Kermit-80 for Merlin M2215 *
ENDIF

IF m2215	;equates removed because interrupts stopped port access 
;iobase	equ	14h		; base address of TTY1
;mnport	equ	iobase		; rx and tx data ports
;mnprts	equ	iobase+1	; status port
;mnmode	equ	iobase+2	; mode port
;mncmd	equ	iobase+3	; PCI command port
;txrdy	equ	1		; tx ready bit set if free
;output	equ	txrdy
;rxrdy	equ	2		; RX ready bit
;input	equ	rxrdy
z80	equ	false		; For Merlin M2215
ENDIF


sysxin:		; Continue system initialisation fro sysinit

IF FALSE			; unable to penetrate the 8085 interrupts
	in	mncmd		; clear command register counter
	mvi	a,4eh		; 0100$1110 - 1 stop bit, 8 data bits,
				; / by 16 counter
	out	mnmode
	mvi	a,30h+7		; 0011$0000 - select internal rate generator
				; use 1200 baud by default
	out	mnmode
	mvi	a,27h		; 0010$0111 - enable tx and rx, RTS and DTR low
	out	mncmd
	mvi	h, 12
	mvi	l, 12
	shld	speed		; to show its been set up

ENDIF

	ret

porbuf:	ds	3		; original port settings

;
;	system-dependent KERMIT termination processing
;	If we've changed anything, this is our last chance to put it back.
;
sysexit:
	ret

;
;	system-dependent processing for start of CONNECT command
;
syscon:
	ret

conmsg:		; Messages printed when entering transparent (CONNECT) mode:

	db	'$'

;
;	syscls - system-dependent close routine
;	called when exiting transparent session.
;
syscls:
	ret

;
;	sysinh - help for system-dependent special functions.
;	called in response to <escape>?, after listing all the
;	system-independent escape sequences.
;
sysinh:
	 			; still can't pentrate interrupts
	ret

; Additional, system-dependent help for transparent mode
; (two-character escape sequences)
;
inhlps:

IF m2215
	db	cr, lf, 'B  Transmit a BREAK'
ENDIF

	db	'$'			; string terminator

;
;	sysint - system dependent special functions
;	called when transparent escape character has been typed;
;	the second character of the sequence is in A (and in B).
;	returns:
;	non-skip: sequence has been processed
;	skip:	seqence was not recognized
;
sysint:	ani	137O		; convert lower case to upper, for testing...

IF FALSE			; as always
	cpi	'B'		; send break ?
	jz	sendbr
ENDIF
	jmp	rskp		; take skip return - command not recognised

; Actual commands

IF FALSE			;as always
sendbr:
	in	mnprts
	ani	04h		; make sure shift reg is clear
	jz	sendbr

	mvi	a,2fh		; set for a break
	out	mncmd
	mvi	a,100		; wait a bit
	call	delay
	mvi	a,27h		; restore mode
	out	mncmd

	ret
ENDIF

	ret

;
;	sysflt - system-dependent filter
;	called with character in E.
;	if this character should not be printed, return with A = zero.
;	preserves bc, de, hl.
;	note: <xon>,<xoff>,<del>, and <nul> are always discarded.
;
sysflt:
	mov	a,e		; get character for testing
	ret

;
;	mdmflt - modem filter
;	called with character to be sent to printer in E
;	with parity set as appropriate.
;	return with accumulator = 0 do do nothing,
;				<> 0 to send char in E.
mdmflt:
	mov	a,e		; get character to test
	ret

;
;	prtflt - printer filter
;	called with character to be sent to printer in E
;	returns with a = 0 to do nothing
;		     a <> 0 to print it.
;
;	this routine for those printer that automatically insert
;	a lf on cr, or cr for lf.  Should this be shifted to 
;	the system indep. stuff, in say 4.06?
;
prtflt:
	mov	a,e		; get character to test

IF FALSE			; strip out lf from printer stream
	ani	7fh		; make sure it is parity less
	cpi	lf		; is it a line feed?
	rnz			; no, print it
;	xra	a		; yes, don't.
	
ENDIF

	ret

;
; system-dependent processing for BYE command.
;
sysbye:
	ret

;
;	This is the system-dependent command to change the baud rate.
;	DE contains the two-byte value from the baud rate table; both
;	bytes of this value are also stored in 'speed'.
;
sysspd:

IF FALSE			; as always
	in	mncmd		; clear register counter
	mvi	a,4eh		; set for 1 stop, 8 data bits
	out	mnmode		; save in mode 1 port
	mvi	a,30h		; set bits for rate etc..
	add	e		; add baud rate (bits 0 - 3)
	out	mnmode		; set mode port 2
	mvi	a,27h		; set tx/rx ready, RTS CTS active
	out	mncmd
	ret
ENDIF
	ret			; if routine not supported
;
;	Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.
;
; 	db	string length, string, divisor (2 bytes or 1 word, ab)
;		the data byte a is return in A and E, and b in D
;		only byte 'a' is the key for the table

IF FALSE			; as always
spdtbl:	db	16		; sixteen entries for PCI
	db	3,'110$',	2,2
	db	4,'1200$',	7,7
	db	3,'134$',	3,3
	db	3,'150$',	4,4
	db	4,'1800$',	8,8
	db	5,'19200$',	15,15
	db	4,'2000$',	9,9
	db	4,'2400$',	10,10
	db	3,'300$',	5,5
	db	4,'3600$',	11,11
	db	4,'4800$',	12,12
	db	2,'50$',	0,0
	db	3,'600$',	6,6
	db	4,'7200$',	13,13
	db	2,'75$',	1,1
	db	4,'9600$',	14,14

sphtbl:	db	'     50     75    110    134    150    300    600   1200   '
	db	cr,lf,'1800   2000   2400   3600   4800   7200   9600  19200$'
ENDIF

IF m2215
spdtbl	equ	0		; routine unsupported
sphtbl	equ	0
ENDIF

;
;	This is the system-dependent SET PORT command.
;	HL contains the argument from the command table.
;
sysprt:

IF m2215
prttbl	equ	0		; SET PORT is not supported
prhtbl	equ	0		; Merlin M2215 could, I suppose
ENDIF

;
;	selmdm - select modem port
;	selcon - select console port
;	selmdm is called before using inpmdm or outmdm;
;	selcon is called before using inpcon or outcon.
;	For iobyt systems, diddle the I/O byte to select console or comm port;
;	For the rest, does nothing.
;	preserves bc, de, hl.
;
selmdm:
	ret

selcon:
	ret

;
;	Get character from console, or return zero.
;	result is returned in A.  destroys bc, de, hl.
;
inpcon:
	call	0f55dh		;CONST BIOS vector
	ora	a		;set flags
	rz
	call	0f56eh		;CONIN BIOS vector
	ret

;
;	Output character in E to the console.
;	destroys bc, de, hl
;
outcon:
	mov	c, e
	call	0f57fh		;CONOUT BIOS vector
	ret

;
;	outmdm - output a char from E to the modem.
;		the parity bit has been set as necessary.
;	returns nonskip; bc, de, hl preserved.
;
outmdm:

IF m2215
	push	psw
	push	h
	push	d
	push	b

	mov	c, e
	mvi	a, 1		; ie: tty1:
	mov	d, a
	call	0f6a2h		;PUN BIOS vector

	pop	b
	pop	d
	pop	h
	pop	psw
ENDIF
	
	ret

;
;	for IOBYT systems, the modem port has already been selected.
;	destroys bc, de, hl.
;
inpmdm:

IF m2215
				; check status
	lda	0fa32h		; ie. tty1:
	ora	a
	rz

	mvi	a, 1		; RDR BIOS vector
	mov	d, a
	call	0f651h
;	ani	7fh

	push	a
	di
	mvi	a, 0
	sta	0fa32h		; remove interrupt flag
	sta	0f2d3h		; zero buffer counter
	lda	0f2d4h
	sta	0f2d5h
	ei
	nop
	pop	a

	ret
ENDIF

;
;	flsmdm - flush comm line.
;	Modem is selected.
;	Currently, just gets characters until none are available.
;
flsmdm:

	call	inpmdm		; Try to get a character
	ora	a		; Got one?
	jnz	flsmdm		; If so, try for another
	ret			; Receiver is drained.  Return.


;

;
;       lptstat - get the printer status. Return a=0 if ok, or 0ffh if not.
lptstat:
IF iobyte       ;[33]
        call    bprtst          ; get status
ENDIF   ;iobyte[33]

IF NOT iobyte   ;[33]
        xra     a               ; assume it is ok.. this may not be necessary
ENDIF   ;iobyte [33]
        ret
;
;	outlpt - output character in E to printer
;	console is selected.
;	preserves de.
;
outlpt:
	push	d		; save DE in either case
	call	prtflt		; go through printer filter [30]
	ana	a		; if A = 0 do nothing,
	jz	outlp1		; if a=0 do nothing

outlp1:	pop	d		; restore saved register pair
	ret

; delchr - make delete look like a backspace.  Unless delete is a printing
;	character, we just need to print a backspace. (we'll output clrspc
;	afterwards)
delchr:

	mvi	e,bs		;get a backspace
	jmp	outcon

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


IF m2215
sysver:	db	'BT Merlin M2215, port TTY1:, settings unchanged.$'
ENDIF

tstmsg:	db	'Test message',cr,lf,'$'

IF lasm
LINK CPXVDU.ASM	; link to the Terminal definition tables
ENDIF	;lasm
