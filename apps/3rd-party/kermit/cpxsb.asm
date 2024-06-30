IF NOT lasm
.printx * CPXSB.ASM *
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
;	This file created 16 July, 1987 by OBSchou from code submitted
;	by William Rose for the Micromint SB180 systems (as featured in
;	BYTE magazine, 1986).  This file has been modified to fit in with
;	Kermit-80 V4.08 etc.  His file KERSYS.ASM is a stripped down version
;	of CPXSYS.ASM (formerly CP4SYS.ASM).
;
; revision history:
; KERSYS.ASM - version 0.8 dated 13 Jul 87.
;
; Cutdown CP4SYS.ASM for SB-180/Ampro 230.
;
;
; While this is a single CPU version (to ease editing) the assembler
; conditionals have been kept to identify machine specific code.
;
; Note that the baud setting routine also sets parity, but this does not
; change the parity given by Kermit's 'stat' command.  I assume that the
; main body of the program does its own parity check.
;
; Revision history (last entry first)
;
; edit 2, 22 July by OBSchou to massage file to fit with CPXCOM.ASM.
;
; edit 1, 15 July, 1987 by OBSchou for William Rose who submitted
;	the code for Kermit-80 V 4.05.  Modified code as appropriate 
;	for 4.08 compatability.
;

delfac	EQU	150	; Delay factor in SB-180 input loop - a fudge

;
; Keep module name, edit number, and last revision date in memory.
;
;sysedt:	db	'KERSYS.ASM (03) 12-FEB-87 $'	; last SB-180 revision
;sysedt:	db	'KERSYS.ASM (04) 12-APR-87 $'	; Telecom Merlin added
;sysedt:	db	'KERSYS.ASM (5)  9-May-87 $'	; Minor tidying
;sysedt:	db	'KERSYS.ASM (6A) 17-Jun-87 $'	; BT Merlin M2215 only
;sysedt:	db	'KERSYS.ASM (7)  19-Jun-87 $'	; SB-180 only
;sysedt:	db	'KERSYS.ASM (8)  13-Jul-87 $'	; 6/9 MHz version
family:	db	'CPXSB.ASM (2)  22-Jul-87$'	; First entry for V4.08/9

;
; Assembly time message to let me know I'm building the right version.
;

IF sb180
.printx * Assembling Kermit-80 for Micromint SB-180 *
ENDIF


IF sb180
mnctrla	EQU	000H	;Modem control port - CNTLA0
mnctrlb	EQU	002H	;Modem control port - CNTLB0
mnstat	EQU	004H	;Modem status port - STAT0
mntxdat	EQU	006H	;Modem output port - TDR0
mnrddat	EQU	008H	;Modem input port - RDR0
output	EQU	002H	;Transmit data register empty mask - TDRE
input	EQU	080H	;Receive data register full mask - RDRF
z80	EQU	TRUE	;This one's an HD64180, but Z80 will do 
ENDIF


sysxin:		; continuation of system initialisation from sysinit

IF sb180
	lxi	h, porbuf	; park the original settings
	db	0EDh, 038h, mnctrla	; HD64180 code IN0 g,(m)
	mov	m, a
	inx	h
	db	0EDh, 038h, mnctrlb
	mov	m, a
	inx	h
	db	0EDh, 038h, mnstat
	mov	m, a
ENDIF
				; re-initialise for KERMIT
IF sb6
	mvi	h, 08h		; 0000$1001 - 9600 baud, (even) parity
	mvi	l, 08h		; 'speed' is two bytes
ENDIF

IF sb9
	mvi	h, 21h		; 0010$0001 - 9600 baud, (even) parity
	mvi	l, 21h		; 'speed' is two bytes
ENDIF

IF sb180
	shld	speed
	lxi	h, parind
	mvi	m, 8		; index for 8 bits, no parity, 2 stop
	call	setpor
ENDIF

	ret

porbuf:	ds	3		; original port settings
   
;
;	system-dependent KERMIT termination processing
;	If we've changed anything, this is our last chance to put it back.
;
sysexit:

IF sb180
	lxi	h, porbuf
	mov	a, m		; output parity
	db	0EDh, 039h, mnctrla	; HD64180 code OUT0 (m),g
	inx	h
	mov	a, m		; output baud rate
	db	0EDh, 039h, mnctrlb
	inx	h
	mov	a, m		; output to clear error flags 
	db	0EDh, 039h, mnstat
				; read twice to reset DCD0 ?
	db	0EDh, 038h, mnstat
	db	0EDh, 038h, mnstat
ENDIF

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

IF sb180 
	lxi	d, inhlps
	call	prtstr
ENDIF

	ret

; Additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:

IF sb180
	db	cr, lf, 'V  Cycle port parameters'
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
sysint:
;	ani	137O		; convert lower case to upper, for testing...
				; does this work?
IF sb180
	cpi	'V'		; cycle port ?
	jz pcycl
	cpi	'v'
	jz pcycl
ENDIF

	jmp	rskp		; take skip return - command not recognised

; Actual commands

IF sb180
pcycl:
	lxi	h, parind	; increment parval, modulo 12
	mov	a, m
	adi	1
	cpi	13
	jnz	pcy1
	mvi	a, 1
pcy1:	mov	m, a		; update the storage
				; get index of name in parstr
	ora	a		; clear flags
	dcr	a
	rlc
	rlc
	mov	c, a
	mvi	b, 0
	lxi	h, parstr
	inx	h
	dad	b
	push	h
	lxi	d, cgmsg1
	call	prtstr
	pop	d
	call	prtstr
	lxi	d, cgmsg2
	call	prtstr
	call	setpor		; reset the port

	ret

cgmsg1:	db	'<$'
cgmsg2: db	'>$'
ENDIF

	ret

;
;	Delay routine.  Called with time (hundredths of seconds) in A.
;	The inner loop delays 1001 T-states, assuming no wait states are
;	inserted; this is repeated CPUSPD times, for a total delay of just
;	over 0.01 second. (CPUSPD should be set to the system clock rate,
;	in units of 100KHz: for an unmodified Kaypro II, that's 25 for
;	2.5 MHz.  Some enterprising soul could determine whether or not the
;	Kaypro actually inserts a wait state on instruction fetch (a common
;	practice); if so, the magic number at delay2 needs to be decreased.
;	(We also neglect to consider time spent at interrupt level).
;
;	called by: sendbr
;	destroys BC
;
;delay:	mvi	c,cpuspd	; Number of times to wait 1000 T-states to
;				;  make .01 second delay
;delay2:	mvi	b,70		; Number of times to execute inner loop to
;				;  make 1000 T-state delay
;delay3:	dcr	b		; 4 T-states (* 70 * cpuspd)
;	jnz	delay3		; 10 T-states (* 70 * cpuspd)
;	dcr	c		; 4 T-states (* cpuspd)
;	jnz	delay2		; 10 T-states (* cpuspd)
;				; total delay: ((14 * 70) + 14) * cpuspd
;				;  = 1001 * cpuspd
;	dcr	a		; 4 T-states
;	jnz	delay		; 10 T-states
;
;	ret			; grand total: ((1001 * cpuspd) + 14) * a

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

IF sb180
	lxi	d, prtmsg	; ask for variables
	call	prtstr

	lxi	d, tbuf		; get suitable string
	mvi	c, 10
	call	bdos

	lxi	h, tbuf1
	mov	a, m
	ora	a
	jz	setpor		; leave unchanged if string zero length

	cpi	3		; check given length
	jnz	spd1		; error - wrong length
	inx	h
	inx	h
	mov	a, m
	ani	137O		; convert parity code to upper case
	mov	m, a

	lxi	d, tbuf1	; get index of given parameter
	lxi	h, parstr
	call	sposn
	ora	a
	jnz	spd2		; or fall through if error
spd1:	lxi	d, invmsg	; invalid input - try again
	call	prtstr
	jmp	sysspd

spd2:	adi	3		; get index to parval table
	rrc			; by dividing by 4 
	rrc
	ani	15		; mask out high bits
	lxi	h, parind
	mov	m, a		; and store it
	call	setpor		; set up port iaw index and speed bytes

	ret

prtmsg:	db	cr,lf,'Enter bit/char, parity, and stop bits required.'
	db	cr,lf,'(Bit 7/8   Parity N/O/E   Stop 1/2  - CR same) : $'
invmsg: db	cr,lf,'Invalid parameters$'

parind:	db	8		; default <8N2> index
parstr:	db	48,'7N1$7N2$7O1$7O2$7E1$7E2$'
	db	   '8N1$8N2$8O1$8O2$8E1$8E2$'
parval:	db	0,1,16+2,16+3,2,3
	db	4,5,16+6,16+7,6,7
tbuf	db	6
tbuf1	db	3,'8N2','$$$$'

;
; Set up the port using the table index in parind and the speed byte
;
setpor:
	lxi	h, parind
	mov	a, m
	dcr	a
	lxi	h, parval	; table base
	mvi	b, 0
	mov	c, a
	dad	b		; HL points at parameter value
	mov	a, m
	mov	b, a		; park parval

	ani	16		; the parity switch bit
	lxi	h, speed
	add	m		; this is now the baud rate byte
	mov	c, a		; park it

	mov	a, b		; sort out the parameter byte
	ani	7		; b/p/s only wanted
	adi	96		; RE, TE enable
	db	0EDh,039h,mnctrla	; output parity etc.
	mov	a, c
	db	0EDh,039h,mnctrlb	; output baud rate
	mvi	a, 0
	db	0EDh,039h,mnstat	; clear status
	db	0EDh,038h,mnstat	; read twice to reset DCD0
	db	0EDh,038h,mnstat
	ret

;
; Find substring position - Leventhal page 293, modified
; enter with subtring in DE and string in HL
; returns index in A or 0 for failure
;
sposn:
	mov	a, m		; exit if either string length zero
	ora 	a
	jz	notfnd
	sta	slen
	mov	b, a
	inx	h
	shld	string
	xchg
	mov	a, m
	ora 	a
	jz	notfnd
	sta	sublen
	mov	c, a
	inx	h
	shld	substg
	mov	a, b

; no of searches = stringlen - substrlen + 1
; if substr longer than string quit immediately

	sub	c
	jc	notfnd
	inr	a
	mov	c, a
	xra	a
	sta	index

; search until remaining string shorter than substring

slp1:	lxi	h, index
	inr	m
	lda	sublen
	mov	b, a
	lhld	substg
	xchg
	lhld	string

; try to match substring starting at index

cmplp:	ldax	d
	cmp	m
	jnz	slp2
	dcr	b
	jz	found
	inx	h
	inx	d
	jmp	cmplp

; arrive here if match fails

slp2:	dcr	c
	jz	notfnd
	lhld	string
	inx	h
	shld	string
	jmp	slp1

; found, return index

found:	lda	index
	ret

; not found, return zero

notfnd:	sub	a
	ret

string:	ds	2
substg:	ds	2
slen:	ds	1
sublen:	ds	1
index:	ds	1
ENDIF

	ret

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

IF sb6
spdtbl:	db	9			; 9 entries
	db	04h,'1200$',	0Bh,0Bh
	db	03h,'150$',	0Eh,0Eh
	db	05h,'19200$',	01h,01h
	db	04h,'2400$',	0Ah,0Ah
	db	03h,'300$',	0Dh,0Dh
	db	05h,'38400$',	00h,00h
	db	04h,'4800$',	09h,09h
	db	03h,'600$',	0Ch,0Ch
	db	04h,'9600$',	08h,08h

sphtbl: db	cr,lf
	db '   150  300  600  1200  2400  4800  9600  19200  38400$'
ENDIF

IF sb9
spdtbl:	db	7			; 7 entries
	db	04h,'1200$',	24h,24h
	db	05h,'19200$',	20h,20h
	db	04h,'2400$',	23h,23h
	db	03h,'300$',	26h,26h
	db	04h,'4800$',	22h,22h
	db	03h,'600$',	25h,25h
	db	04h,'9600$',	21h,21h

sphtbl: db	cr,lf
	db '   300  600  1200  2400  4800  9600  19200$'
ENDIF


;
;	This is the system-dependent SET PORT command.
;	HL contains the argument from the command table.
;
sysprt:
	ret

IF sb180
prttbl EQU	0		; SET PORT is not supported
prhtbl EQU	0
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
	mvi	c,dconio	;Direct console I/O BDOS call.
	mvi	e,0FFH		;Input.
	call	BDOS

	ret

;
;	Output character in E to the console.
;	destroys bc, de, hl
;
outcon:
	mvi	c,dconio	;Console output bdos call.
	call	bdos		;Output the char to the console.

	ret

;
;	outmdm - output a char from E to the modem.
;		the parity bit has been set as necessary.
;	returns nonskip; bc, de, hl preserved.
;
outmdm:

IF sb180
	db	0EDh,038h,mnstat
	ani	output		; check status
	jz	outmdm		; wait until port is available
	mov	a, e
	db	0EDh,039h,mntxdat	; transmit
ENDIF

	ret

;
;	get character from modem; return zero if none available.
;	for IOBYT systems, the modem port has already been selected.
;	destroys bc, de, hl.
;
inpmdm:

IF sb180
	lxi	h, delfac	; loops to give delay
inpm1:	db	0EDh,038h,mnstat
	ani	input		; check status	
	jz	inpm2
	db	0EDh,038h,mnrddat	; get a byte
	ret

inpm2:	dcx	h		; no data
	mov	h, a
	ora	l
	jnz	inpm1		; still tries left
	ret			; with zero in A
ENDIF

	ret

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

IF sb180
sysver:	db	'MicroMint SB 180 '
ENDIF

IF sb6
	db	' (6 MHz)'
ENDIF

IF sb9
	db	' (9 MHz)'
ENDIF
	db	'$'

IF lasm
LINK CPXVDU.ASM		; get terminal defs etc
ENDIF	;lasm
