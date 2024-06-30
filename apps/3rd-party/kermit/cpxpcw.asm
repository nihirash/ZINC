IF NOT lasm
.printx * CPXPCW.ASM *
ENDIF	;NOT lasm
;
; KERMIT - (Celtic for "FREE")
;
; This is the CP/M-80 implementation of the Columbia University
; KERMIT file transfer protocol.
;
; Version 4.08
;
; Copyright June 1981,1982,1983,1984,1985
; Columbia University
;
; Originally written by Bill Catchings of the Columbia University Center for
; Computing Activities, 612 W. 115th St., New York, NY 10025.
;
; This file contains the system-dependent code and data for KERMIT
; on the Amstrad range of personal computers.
;
;
; Revision history:
;
;edit 9, 22-Jan-1991 by MF. Added "sysinit" code at "init04" from Kermit
;	version 4.08 which had been left out of version 4.09 to reserve
;	space for the Amstrad's I/O buffers. Amstrad Kermit now stores
;	files correctly (version 4.09 had garbled files). Again,
;	this fix comes from Mr. D. P. Arnot of the Scottish Agricultural
;	College in the UK.
;edit 8, 16-Jan-1991 by MF. Added a "bs" left out of "delstr" per
;	instruction from David P. Arnot of Scottish Agricultural
;	College, Auchincruive, Ayr, UK.
;	E-mail:  <D.P.Arnot@edinburgh.ac.uk>
; edit 7, 22 July 1987 by OBSchou to massage code to fit with CPXCOM.ASM
;	Had to rename bcnout to bcnot as the former label clashed with
;	one of the same name in CPXCOM.ASM.  Sorry, folks.
;
; edit 6, 14th July, 1987 by OBSchou for Phillip Wade, Hull University
;	Computer Centre.  Change to delchr routine for PCW machines, 
;	as character 127 decimal is a printing character on 
;	the Amstrad PCW.  The routine has been replaced 
;	by a bs,space,bs,bs string. (OBS Comment - why a total of THREE bs?)
;
; edit 5 9 May 1987 by C.J.MILES@UK.AC.UMRCC
;	Hangup phone and clear screen options added to
;	terminal mode.
;
; edit 4 23 March 1987 by C.J.MILES@UK.AC.UMRCC
;	Use direct input drom SIO for CPC machines instead
;	of using BDOS. Improvement reduces time for file
;	transfer to 65% of time used by BDOS method.
;	Add reverse Prestel baud rate.
;
; edit 3 20 March 1987 by Chris Miles (C.J.MILES@UK.AC.UMRCC)
;	(Greater Manchester Archaeological Unit, Manchester Univ.).
;	Added support for Amstrad CPC CP/M Plus machines,
;	Added 31250 baud rate option,
;	Bug fixed in sending BREAK,
;	Bug fixed in 1200/75 baud setup
;	Machine and CP/M version checks added.
;
; edit 2 11 Febuary, 1987 by OBSchou for Ian Young.
;	Changes to the send break routine to change two lines of code from
;		ori	018h		; send break, Tx enable
;	and	ori	0008h		; Tx enable 
;
;	to	ori	01ah		; send break, Tx enable, RTS
;	and	ori	00ah		; Tx enable, RTS
;
;	This is a bug fix to hopefully keep RTS actve during breaks.
;
; [Ed. (OBSchou) 21/1/87.
; This file linked FROM cpxsys.asm, so do NOT rename this
; file.  The diffculty of needing a HUGE CPXSYS.ASM file on your floppy
; only to act as a switcher remains, but hopefully will be better in 
; the future.  If you ARE stuck, then rename this CPXSYS.ASM but add the
; label SYSEDT: to the FAMILY label.  A bit messy.]
;
;
; The "author" of this system-dependent file is:
;
;  Ian A. Young
;  Lattice Logic Ltd
;  9 Wemyss Place
;  Edinburgh
;
; Some other addresses:
;
;  ian@latlog.uucp
;  ...seismo!mcvax!ukc!latlog!ian
; or c/o OBSchou@uk.ac.lut.multics
;
; ... although much of the code concerned was written by others.
;


; Keep module name, edit number, and last revision date in memory.

;sysedt:	db	'CPXSYS.ASM (36) 20-Mar-87$'
family:	db	'CPXPCW.ASM (9)  22-Jan-1991$'


;
; Assembly-time message announcing which version we are building
;

IF pcw
.printx	* Assembling Amstrad PCW Kermit-80 *
ENDIF

IF cpc
.printx	* Assembling Amstrad CPC Kermit-80 *
ENDIF

;
; Miscellany of parameter settings
;
z80	EQU	TRUE 		; all Amstrads have a Z80.
defesc	EQU	'\'-100O	; The default escape character.
vtval	EQU	0 		; we don't need VT52 emulation

;
; Amstrad CPC machines use 16 bit I/O address decoding and therefore
; the Z80 instructions OUT (C),A and IN A,(C) must be defined.
;
outc	EQU	79edh		; IN	A,(C)
inpc	EQU	78edh		; OUT	(C),A

;
; hardware information
;
; There is a Z80-DART (Mostek/SGS 8470) at I/O addresses E0..E3 (PCW)
; and FADC..FADD (CPC), and a 8253 programmable divider running it at
; E4..E7 (PCW) and FBDC..FBDF (CPC)
;

input	EQU	01h		; input data available
output	EQU	04h		; output buffer ready

IF pcw
mnport	EQU	0E0h		; data register for SIO
mnprts	EQU	0E1h		; control register for SIO
ctc0	EQU	0E4h		; 8253 load counter 0
ctc1	EQU	0E5h		; 8253 load counter 1
ctcmod	EQU	0E7h		; 8253 write mode word
ENDIF

IF cpc
mnport	EQU	0FADCh		; data register for SIO
mnprts	EQU	0FADDh		; control register for SIO
ctc0	EQU	0FBDCh		; 8253 load counter 0
ctc1	EQU	0FBDDh		; 8253 load counter 1
ctcmod	EQU	0FBDFh		; 8253 write mode word
ENDIF

;
; SIO input buffering
;
siosz	EQU	4096		; size of SIO input buffer
siomsk	EQU	4095		; mask for wrapping buffer round

;
; Extended BIOS jump-block addresses; reached through USERF
;
sainit	EQU	00B6h		; initialise SIO
sabaud	EQU	00B9h		; set baud rate
saparm	EQU	00BCh		; fetch SIO parameters
teask	EQU	00BFh		; find out cursor position
cdvers	EQU	00E3h		; get version numbers
cdinfo	EQU	00E6h		; get BIOS system information

;
; System-dependent initialization
; Called once at program start.
sysxin:		; continuation of system initialzation 
;
; check for correct CP/M version
;
	mvi	c,12		; get CP/M version BDOS call
	call	bdos
	mov	a,l		; check if CP/M Plus
	cpi	31h
	jz	init08
	lxi	d,wrong2	; point to error message
	call	prtstr
	mvi	c,0		; warm boot
	call	bdos
;
init08:		;[OBS] Moved the Cinfigured for message out as
		;[OBS]   it is in CPXCOM.ASM
;
; get addresses of BIOS routines
;
; BIOS USERF is used to get to extended BIOS routines
;
	lhld	1		; warm boot vector
	lxi	d,87		; offset to USERF vector
	dad	d		; DE now has USERF vector address
	shld	userf+1		; ready for jumping to...
;
; BIOS routines for fast character I/O
;
	lhld	1		; warm boot vector (#1)
	lxi	d,3
	dad	d		; next is #2, CONST
	shld	bcnst+1
	dad	d		; next is #3, CONIN
	shld	bcnin+1
	dad	d		; next is #4, CONOUT
	shld	bcnot+1		;[obs] Was bcnout, but this conflicts
				;[obs] with a label in CPXCOM.ASM
	dad	d		; next is #5, LIST
	shld	blist+1
	dad	d		; next is #6, AUXOUT
	dad	d		; next is #7, AUXIN
	shld	baxin+1
	lhld	1		; warm boot vector again
	lxi	d,002Ah		; offset to LISTST (#15)
	dad	d
	shld	lptstat+1
	lhld	1		; warm boot vector again
	lxi	d,0033h		; offset to AUXIST (#18)
	dad	d
	shld	baxist+1
;
; check if running on correct Amstrad
;
	call	userf
	dw	cdvers
IF pcw
	cpi	0
ENDIF
IF cpc
	cpi	1
ENDIF
	jnz	init06
	lxi	d,wrong1	; point to error message
	call	prtstr
	mvi	c,0
	call	bdos
;
; verify presence of SIO board by asking the BIOS.
;
init06:	call	userf		; C gets 00 if not fitted
	dw	cdinfo
	xra	a		; a <- 0
	ora	c		; zero => no serial port
	jnz	init03		; non-zero => OK
	lxi	d,nosio		; snooty message...
	call	prtstr
	mvi	c,0		; warm boot out of here
	call	bdos
init03:
;
; find initial baud rate and other information
;
	call	userf		; gives B=rx baud, C=tx baud, D=stop bits,
				; E=parity, H=rx bits, L=tx bits.
	dw	saparm		; get SIO parameters
	push	h		; save bit settings
	mov	a,b		; if TX and RX speeds same, they are OK
	cmp	c
	jz	init01
	cpi	8		; rx=1200?
	jnz	init02		; no, can't be Prestel
	mov	a,c
	cpi	2		; tx=75?
	jnz	init02		; no, can't be Prestel
	lxi	b,0		; otherwise 1200/75 comes out as 0s.
init01:	push	b		; assign value to SPEED
	pop	h
	shld	speed
init02:				; here if we leave it as is
	pop	h		; get bit settings
	mov	a,l		; no of TX data bits set
	sui	5		; make into 00, 01, 10, 11.
	rrc
	rrc
	rrc
	sta	txbits		; we may need it later
;
; set handshake mode: there are two parts to this, interrupts and
; hardware handshake. The MODE byte used by the firmware expresses
; this combination as -(int*2 + hand*1).  Thus, both options on would
; be (-3) or 0FDh.
;
; Here, we set the interrupt part of the mode on; it helps the BIOS cope.
; Unfortunately, >sigh<, according to Soft971, this will only work
; if you have BIOS V1.4 or higher.  I have no idea what would happen
; if we tried random hanshake mode flags with lower versions, so we
; just skip over if it would be dangerous...
;
	call	userf		; fetch all parameters
	dw	saparm
	sta	orgmode		; remember original mode for later

	call	userf		; get BIOS version to B,C
	dw	cdvers
	mov	a,b		; BIOS major version number (eg 1)
	ora	a		; if zero, too low...
	jz	init04
	cpi	1		; if not 1, definitely OK
	jnz	init05
	mov	a,c		; otherwise, its 1.X; want >= 4
	cpi	4
	jm	init04		; <4 => too low

init05:	call	userf		; get the original flags back
	dw	saparm
	xri	0FFh		; make mode into bit mask
	inr	a
	ori	2		; set interrupt mode
	xri	0FFh		; turn back into mode value
	inr	a
	call	userf		; feed change back to BIOS
	dw	sainit
init04:				; come here if not setting mode

; Locate large buffers for multi-sector I/O and SIO input buffering.
; Space above ovlend is available for buffers; we have pretty well the machine
; to ourselves in an Amstrad PCW because they all gave 61K TPAs. We don't even
; bother to perform any checking.
; We don't want to use more than maxsec for disk buffers because
; if we use too many, the remote end could time out while we're
; writing to disk.  maxsec is system-dependent, but for now we'll just
; use 8Kbytes.  If you get retransmissions and other protocol errors after
; transferring the first maxsec sectors, lower maxsec.
;
maxsec  EQU     (8*1024)/bufsiz ; 8K / number of bytes per sector

        lxi     h,ovlend+siosz  ; get start of buffer
        shld    bufadr          ; store in linkage section
        mvi     a,maxsec        ; get size of buffer, in sectors
        sta     bufsec          ; store that, too.


        ret                     ; return from system-dependent routine

;
; message complaining about wrong Amstrad machine
;
wrong1:	db	'Error -   This Kermit will only run on the Amstrad '
IF pcw
	db	'PCW 8256/8512'
ENDIF
IF cpc
	db	'CPC 464/664/6128'
ENDIF
	db	cr,lf,'$'
;
; message complaining about version of CP/M being used
;
wrong2:	db	'Error - Incorrect CP/M version, needs CP/M 3.x'
	db	cr,lf,'$' 
;
; message complaining of no SIO board
;
nosio:	db	'Error -   No SIO option fitted to this machine'
	db	cr,	lf, '$'

;
; jumps to BIOS character I/O routines.
; Addresses filled in by initialisation code above.
;
bcnst:	jmp	$-$		; console status
bcnin:	jmp	$-$		; console input
bcnot:	jmp	$-$		; console output [obs - was bcnout]
blist:	jmp	$-$		; printer output
baxin:	jmp	$-$		; aux port input
baxist:	jmp	$-$		; aux port status
lptstat:jmp	$-$		; printer status

;
; Other BIOS routines
;
userf:	jmp	$-$		; call extended BIOS function

;
; saved value of some original parameters
;
orgmode:ds	1
txbits:	ds	1

;
; system-dependent termination processing
; If we've changed anything, this is our last chance to put it back.
sysexit:
	call	userf		; fetch firmware parameters
	dw	saparm
	lda	orgmode		; replace with original mode
	call	userf		; inform BIOS
	dw	sainit
	ret

;
; system-dependent processing for start of CONNECT command
;
syscon:
	lxi	d,conmsg	; how to get escape char message
	call	prtstr
	ret

conmsg:		; Messages printed when entering transparent (CONNECT) mode:
IF pcw
	db	'(Use boxed minus key next to space bar to generate a Control-\)'
ENDIF
	db	cr,lf,'$'

;
; syscls - system-dependent close routine
; called when exiting transparent session.
;
syscls:
	ret

;
; sysinh - help for system-dependent special functions.
; called in response to <escape>?, after listing all the
; system-independent escape sequences.
;
sysinh:
	lxi	d,inhlps	; we got options...
	call	prtstr		; print them.
	ret

;
; additional, system-dependent help for transparent mode
; (two-character escape sequences)
;
inhlps:
	db	cr,lf,'B  Transmit a BREAK'
	db	cr,lf,'H  Hangup using DTR'
	db	cr,lf,'W  Wipe screen clear'
	db	'$'			;[hh] table terminator

;
; sysint - system dependent special functions
; called when transparent escape character has been typed;
; the second character of the sequence is in A (and in B).
; returns:
;         non-skip: sequence has been processed
;         skip    : sequence was not recognized
;
sysint:	ani	137O		; convert lower case to upper, for testing...
	cpi	'B'		; send break ?
	jz	sendbr		; yes, go do it.  return nonskip when through.
	cpi	'H'		; hang up ?
	jz	hangup
	cpi	'W'		; clear screen ?
	jz	clrtop
	jmp	rskp		; take skip return - command not recognized.

;
; Hangup (drop DTR) and Break send routine
;

hangup:
	mvi	d,0ah		; set up hangup bit mask
	mvi	e,255		; time for hangup is 2 1/2 secs
	jmp	setbit		; skip Tx empty test

sendbr:
	mvi	d,9ah		; set up break bit mask
	mvi	e,30		; time for break is 300 ms

sndbr1:	mvi	a,1		; select Read Register 1

IF pcw	; allow 8 bit I/O instructions
	out	mnprts
	in	mnprts		; read the contents
ENDIF

IF cpc	; use 16 bit I/O instructions
	lxi	b,mnprts
	dw	outc		; OUT	(C),A
	dw	inpc		; IN	A,(C)
ENDIF

	ani	1		; test "all done" flag
	jz	sndbr1		; loop until it's nonzero.
;
; Next, set the break or hangup bit on the SIO.
;
setbit:
	mvi	a,5		; select Write Register 5
IF pcw
	out	mnprts
ENDIF
IF cpc
	dw	outc		; OUT	(C),A
ENDIF
	lda	txbits		; get txbits (already in correct bit positions)
	ora	d		; send break, Tx Enable, RTS
IF pcw
	out	mnprts
ENDIF
IF cpc
	dw	outc		; OUT	(C),A
ENDIF

;
; Now, delay for duration of hangup or break
;
	mov	a,e		; delay count
	call	delay
;
; Time's up. Put transmitter back in normal state and return.
;
	mvi	a,5		; select Write Register 5
IF pcw
	out	mnprts
ENDIF
IF cpc
	lxi	b,mnprts
	dw	outc		; OUT	(C),A
ENDIF
	lda	txbits		; get txbits again
	ori	8ah		; Reset break, Tx Enable, RTS
IF pcw
	out	mnprts
ENDIF
IF cpc	
	dw	outc		; OUT	(C),A
ENDIF
	ret			; done.

;
; sysflt - system-dependent filter
; called with character in E.
; if this character should not be printed, return with A = zero.
; preserves bc, de, hl.
; note: <xon>,<xoff>,<del>, and <nul> are always discarded.
;
sysflt:
	mov	a,e		; get character for testing
	ret
;
; system-dependent processing for BYE command.
;
sysbye:
	ret

;
; This is the system-dependent command to change the baud rate.
; DE contains the two-byte value from the baud rate table; this
; value is also stored in 'speed'.
;
sysspd:
	push	d		; move to HL for firmware
	pop	h
	mov	a,h		; if h=0 then Prestel rates
	ora	a
	jnz	spd01		; if not 1200/75 then skip
	lxi	h,0802H		; else set 1200/75 into HL
	jmp	spd03		; jump to normal setup

spd01:	cpi	11h		; if h=11h then reverse Prestel
	jnz	spd02		; if not 75/1200 then skip
	lxi	h,0208h		; else set 75/1200 into HL
	jmp	spd03		; jump to normal setup

spd02:	cpi	10h		; if h=10h then 31250 baud
	jnz	spd03		; if not 31250 then skip to normal setup
	mvi	a,36h		; set 8253 for mode 2 binary count
	lxi	b,ctcmod	; output to CTC mode register
	dw	outc
	lxi	b,ctc0		; select transmit clock
	mov	a,4		; timer value for 31250 (04h)
	dw	outc
	mov	a,0		; timer value for 31250 (04h)
	dw	outc
	lxi	b,ctc0		; select receive clock
	mov	a,4		; timer value for 31250 (04h)
	dw	outc
	mov	a,0		; timer value for 31250 (04h)
	dw	outc
	ret

spd03:	call	userf		; set whatever we have now...
	dw	sabaud		; using BIOS routine
	ret

;
; Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.
;
; db string length,string,divisor (2 identical bytes or 1 word)
;
spdtbl:	db	12h			;18 entries
	db	03h,'110$', 03h,03h
	db	04h,'1200$', 08h,08h
	db	07h,'1200/75$', 00h,00h	; real values faked up when required
	db	05h,'134.5$', 04h,04h
	db	03h,'150$', 05h,05h
	db	04h,'1800$', 09h,09h
	db	05h,'19200$', 0fh,0fh
	db	04h,'2400$', 0ah,0ah
	db	03h,'300$', 06h,06h
	db	05h,'31250$',10h,10h	; flag to direct setup routine
	db	04h,'3600$', 0bh,0bh
	db	04h,'4800$', 0ch,0ch
	db	02h,'50$', 01h,01h
	db	03h,'600$', 07h,07h
	db	04h,'7200$', 0dh,0dh
	db	02h,'75$', 02h,02h
	db	07h,'75/1200$',11h,11h	; real values faked up when required
	db	04h,'9600$', 0eh,0eh

sphtbl:	db	cr,lf,lf
	db	'Normal rates: 50    75    110   134.5 150   300   600'
	db	cr,lf
	db	'              1200  1800  2400  3600  4800  7200  9600  19200'
	db	cr,lf,lf
	db	'High speed  : 31250 (only between Amstrads)'
	db	cr,lf,lf
	db	'Split rates : 1200/75 (Rx=1200, Tx=  75)'
	db	cr,lf
	db	'              75/1200 (Rx=  75, Tx=1200)'
	db	cr,lf,'$'

;
; This is the system-dependent SET PORT command.
; HL contains the argument from the command table.
;
sysprt:
	ret

prttbl	equ	0		; SET PORT is not supported
prhtbl	equ	0

;
; selmdm - select modem port
; selcon - select console port
; selmdm is called before using inpmdm or outmdm;
; selcon is called before using inpcon or outcon.
; preserves bc, de, hl.
;
selmdm:
selcon:
	ret

;
; Get character from console, or return zero.
; result is returned in A.  destroys bc, de, hl.
;
inpcon:
	call	bcnst		; get console status
	ora	a		; anything there?
	rz			; no, forget it
	jmp	bcnin		; yes, get the character

;
; Output character in E to the console.
; destroys bc, de, hl
;
outcon:
	mov	a,e		; TAB?
	cpi	tab
	jz	out001
	mov	c,e		; set correct arg register
	jmp	bcnot		; output to console via BIOS [obs was bcnout]

;
; perform tab expansion ourselves
;
out001:	call	userf		; get column in L
	dw	teask
	mov	a,l		; a <- column 0..n
	ani	7		; column 0..7
	xri	0FFh		; not(col 0..7)
	adi	9		; a is 8-(colf7)
out002:	ora	a		; any left?
	rz			; return if not
	dcr	a		; one less now, anyhow
	push	psw		; save over BIOS call (just in case)
	mvi	c,' '		; print one space
	call	bcnot		;[obs was bcnout]
	call	suck		; in case any stuff coming in
	pop	psw		; fetch count back
	jmp	out002		; and go round again

;
; outmdm - output a char from E to the modem.
;  the parity bit has been set as necessary.
; returns nonskip; bc, de, hl preserved.
outmdm:
IF cpc
	push	b		; save BC for CPC 16 bit I/O
ENDIF
outmd1:
	call	xsuck		; keep checking for incoming characters
IF pcw
	in	mnprts		; get the output done flag.
ENDIF
IF cpc
	lxi	b,mnprts
	dw	inpc		; IN	A,(C)
ENDIF
	ani	output		; is it set?
	jz	outmd1		; if not, loop until it is.
	mov	a,e
IF pcw
	out	mnport		; output it.
ENDIF
IF cpc
	lxi	b,mnport
	dw	outc		; OUT	(C),A
	pop	b		; restore BC
ENDIF
	ret

;
; get character from modem; return zero if none available.
; destroys bc, de, hl.
;
inpmdm:
	call	suck		; get any characters pending
	lhld	sioct		; count of chars in buffer
	mov	a,h		; or together to get result
	ora	l
	rz			; not got any, return now

	dcx	h		; down count
	shld	sioct

	lhld	siord		; read pointer
	mov	c,m		; fetch character ** NB TO C FOR NOW **

	lxi	d,1-ovlend	; bump pointer, subtract base
	dad	d
	mov	a,h		; mask high byte of offset
	ani	siomsk/256
	mov	h,a
	lxi	d,ovlend	; add in base again
	dad	d
	shld	siord

	mov	a,c		; get to proper register
	ret

;
; flsmdm - flush comm line.
; Modem is selected.
; Currently, just gets characters until none are available.

flsmdm:	call	inpmdm		; Try to get a character
	ora	a		; Got one?
	jnz	flsmdm		; If so, try for another
	ret			; Receiver is drained.  Return.

;
; SIO input buffer handling.  The buffer pointers are held as pointers into
; the buffer. The read pointer
; is to the next unused character, the write pointer to the next unused space.
;
siord:	dw	ovlend		; next char to read
siowr:	dw	ovlend		; next char to write
sioct:	dw	0		; number in buffer

xsuck:	push	d		; save regs version of suck
	push	b
	push	h
	call	suck
	pop	h
	pop	b
	pop	d
	ret

;
; suck
;
; this routine is called whenever it would be possible that some
; characters might be available in the SIO device; they are all
; transferred (there may be up to 4 pending) to the buffer.
;
; all registers are destroyed
;
suck:
IF pcw
	call	baxist		; check input status via BDOS
	ora	a		; check if zero
ENDIF
IF cpc
	lxi	b,mnprts	; get input status directly
	dw	inpc		; IN A,(C)
	ani	input		; mask for Rx ready
ENDIF
	rz			; return if no

IF pcw
	call	baxin		; fetch character via BDOS
ENDIF
IF cpc
	lxi	b,mnport	; fetch character directly from SIO
	dw	inpc		; IN A,(C)
ENDIF

	lhld	siowr		; write pointer
	mov	m,a		; put character

	lxi	d,1-ovlend	; take off base, bump pointer
	dad	d
	mov	a,h		; top byte of offset
	ani	siomsk/256	; masked off
	mov	h,a
	lxi	d,ovlend	; add on base again
	dad	d
	shld	siowr		; replace pointer

	lhld	sioct		; bump count in buffer
	inx	h
	shld	sioct

	jmp	suck		; go round in case any more

;
; outlpt - output character in E to printer
; console is selected.
; preserves de.
outlpt:
	push	d		; save DE in either case
	mov	c,e		; correct arg register
	call	blist
	pop	d		; restore saved register pair
	ret

;
; Screen manipulation routines
; csrpos - move to row B, column C
;
; csrpos for terminals that use a leadin sequence followed
;  by (row + 31.) and (column + 31.)
;  or (row) and (column)
;
csrpos:	push	b		; save coordinates
	lxi	d,curldn	; get cursor leadin sequence
	call	prtstr		; print it
	pop	h		; restore coordinates
	mov	a,h		; get row
	adi	(' '-1)		; space is row one
	mov	e,a
	push	h
	call	outcon		; output row
	pop	h
	mov	a,l		; get column
	adi	(' '-1)		; space is column one
	mov	e,a
	jmp	outcon		; output it and return

;
; delchr - make delete look like a backspace.  Unless delete is a printing
; character, we just need to print a backspace. (we'll output clrspc
; afterwards)
; For Kaypro and Vector General, delete puts a blotch on the screen.
; For Apple and Osborne 1, delete moves but doesn't print.
delchr:
IF pcw	;[6] OBS for Phillip Wade
	lxi	d,delstr	;[5] send a string rather than a single character
	call	prtstr

delstr:	db	bs,' ',bs,'$'	;[OBS] Was bs,space,bs,bs
ENDIF	;pcw

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


IF pcw
sysver:	db	'Amstrad PCW with SIO option$'
ENDIF
IF cpc
sysver:	db	'Amstrad CPC with CP/M Plus$'
ENDIF

outlin:	db	esc,'H',esc,'J',cr,lf,'                $'

erascr:	db	esc,'H',esc,'J$'	;Clear screen and go home.
eralin:	db	cr,esc,'K$'		;Clear line.
curldn:	db	esc,'Y$'		;cursor leadin
ttab:					;Table start location.
ta:	db	esc,'A$',0		;Cursor up.
tb:	db	esc,'B$',0		;Cursor down.
tc:	db	esc,'C$',0		;Cursor right.
td:	db	esc,'D$',0		;Cursor left
te:	db	esc,'E$',0		;Clear display
tf:	db	'$',0,0,0		;Enter Graphics Mode
tg:	db	'$',0,0,0		;Exit Graphics mode
th:	db	esc,'H$',0		;Cursor home.
ti:	db	esc,'I$',0		;Reverse linefeed.
tj:	db	esc,'J$',0		;Clear to end of screen.
tk:	db	esc,'K$',0		;Clear to end of line.

ovlend	equ	$	; End of overlay

	END
