IF NOT lasm
.printx * CPXBEE.ASM *
ENDIF	;NOT lasm
;       KERMIT - (Celtic for "FREE")
;
;       This is the CP/M-80 implementation of the Columbia University
;       KERMIT file transfer protocol.
;
;       Version 4.09
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
; edit 1,  1st September 1990 
;	Original version by Russell Lang <rjl@monu1.cc.monash.edu.au>
;       The 'microbee' is designed and manufactured in Australia
;       by Microbee Systems Ltd (previously Applied Technology).
;	The microprocessor is a Z80 at 3.375MHz.
;	The video screen is memory mapped from 0F000h to 0F7FFh, 
;	with Programmable Characters 80-FF from 0F800h to 0FFFFh.  
;	The serial and parallel ports are implemented using a Z80 PIO.
;	The early model microbees were ROM-Basic computers with up
;	to 32k of battery backed RAM.  Later models dropped the
;	ROM-Basic and added disk drives and CP/M.  The disk systems
;	include the 56k (64k) APC (5.25" drives), 64k Computer-In-A-Book 
;	(3.5"), 128k Dynamic (5.25" or 3.5"), 256TC (3.5").
;	
;	This version of kermit was developed on a 56k APC.
;	It has been tested on 56k, 64k, 128k and 256k Microbees.
;
; 	The serial port is implemented in software NOT hardware.
;	A special transmit routine allows simultaneous receiving
;	for all speeds except 75/1200, 1200/75, 4800, 9600.
;	The receive routine is interrupt driven with a 2 kbyte buffer.
;	The 9600 bit/s speed is marginal on receive - if the transmitter
;	is slightly fast (more than about 1%), the serial routine will 
;	not have enough time to put the character in the buffer before 
;	the next character arrives.


;
; 		*** MAIN CODE START ***
;
;
; Keep module name, edit number, and last revision date in memory.

sysedt: db      'CPXSYS.ASM (35) 01-Dec-86$'
family: db	'CPXBEE.ASM (1)  01-Sep-90$'


; Assembly time message announcing which version we're building

.printx * Assembling Microbee Kermit-80 *

z80	EQU	TRUE	; They all use Z80s

defesc  EQU     ']'-100O        ;The default escape character for Microbee

vtval	EQU	0	; use default emulation which is adm3a superset

;
sysxin:		;continuation of system initialisation code
	; set up baud rate
	lxi	h,t300
	shld	speed
	xchg
	call	setbaud
	; change the interrupt vector so that we intercept rs232 input
	db	0EDh,57h	;ld	a,i	;get old interrupt reg
	sta	oldint
	mvi	a,int		;new value
	db	0EDh,47h	;ld	i,a
        ret                     ; return from system-dependent routine


;
; sysexit - System-dependent termination processing
; 	    if we've changed anything, this is our last
;	    chance to put it back.
;
sysexit:
	lda	oldint	  	;restore old interrupt reg
	db	0EDh,47h	;ld	i,a
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
        db      cr,lf,'B  Transmit a BREAK (0.3s)'
	db	cr,lf,'L  Transmit a LONG BREAK (1.8s)'
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
	cpi	'L'		; long break ?
	jz	longbr		; then jump to long break routine
	cpi	'W'		; clear screen ?
	jz	clrtop		; then jump to clear screen routine
        jmp     rskp            ; take skip return - command not recognized.

;
; Break routines
;
longbr:
	mvi	e,180		; time for long break is 1800 ms
	jmp	setbit

sendbr:
	mvi	e,30		; time for break is 300 ms

setbit:	
	in	portb
	ani	0dfh		; mask with tx bit
	out 	portb
;
;       Now, delay for duration of hangup or break
        mov     a,e		; delay count
        call    delay
;
;       Time's up. Put transmitter back in normal state and return.
	in	portb
	ori	20h		; mask with tx bit
	out 	portb
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
	call	setbaud
	ret

;
;       Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.

;       db      string length,string,divisor (2 identical bytes or 1 word)
; [Toad Hall]

spdtbl:	db	11			;11 entries
	db	03h,'110$'
	dw	t110
	db	04h,'1200$'
	dw	t1200
	db	07h,'1200/75$'
	dw	t1275
	db	03h,'150$'
	dw	t150
	db	04h,'2400$'
	dw	t2400
	db	03h,'300$'
	dw	t300
	db	04h,'4800$'
	dw	t4800
	db	03h,'600$'
	dw	t600
	db	02h,'75$'
	dw	t75
	db	07h,'75/1200$'
	dw	t7512
	db	04h,'9600$'
	dw	t9600

sphtbl:	db	cr,lf,'75  75/1200  110  150  300  600  1200  1200/75'
	db	' 2400 4800 9600$'


;
;	This is the system-dependent SET PORT command.
sysprt:
	ret

prttbl	equ	0		; SET PORT is not supported
prhtbl	equ	0


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
;
	push	psw
	push	b
	push	d
	push	h
	mov	a,e
	lxi	h,outm2	; return address
	push	h
	lhld	txcall
	pchl		; send to rs232 port
outm2:	pop	h
	pop	d
	pop	b
	pop	psw
	ret


;
;       get character from modem; return zero if none available.
;       bc, de, hl preserved.
inpmdm:
	call	rsin	; get char if available
	ret			; return with character in A


;
;       flsmdm - flush comm line.
;       Modem is selected.
;       Currently, just gets characters until none are available.
flsmdm: call    inpmdm          ; Try to get a character
        ora     a               ; Got one?
        jnz     flsmdm          ; If so, try for another
        ret                     ; Receiver is drained.  Return.

;
;       lptstat - get the printer status. Return a=0 if ok, or 0ffh if not.
lptstat:
	lda	pflag
        ret

;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
        push    d               ; save DE in either case
        ana     a               ; if A = 0 do nothing,
        jz      outlp1          ; [30] if a=0 do nothing
	mov	a,e
	call	parout
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

;
; delchr - make delete look like a backspace.  Unless delete is a
;          printing character, we just need to print a backspace
;          (we'll output clrsp afterwards)
delchr:
        lxi     d,delstr
        jmp     prtstr


; erase the character at the current cursor position
clrspc: mvi     e,' '
        call    outcon
        mvi     e,bs            ;get a backspace
        jmp     outcon

; erase the current line
clrlin: lxi     d,eralin
        jmp     prtstr

; erase the whole screen, and go home
clrtop: lxi     d,erascr
        jmp     prtstr


sysver:	db	'Microbee$'
outlin:	db	1AH,cr,lf,tab,'$'	;(Clear screen, home cursor)
erascr:	db	1AH,'$'			;Clear screen and go home.
eralin:	db	cr,esc,'T$'		;Clear line.
delstr:	db	bs,'$'			; Adjust for delete
curldn:	db	esc,'=$'		;Cursor lead-in
ttab:					;Table start location.
ta:	db	('K'-100O),'$',0,0	;Cursor up.
tb:	db	12O,'$',0,0		;Cursor down.
tc:	db	('L'-100O),'$',0,0	;Cursor right.
td:	db	bs,'$',0,0		;Cursor left.
te:	db	subt,'$',0,0		;Clear screen.
tf:	db	'$',0,0,0		;(can't) Enter graphics mode
tg:	db	'$',0,0,0		;(can't) Exit graphics mode
th:	db	('^'-100O),'$',0,0	;Cursor home.
ti:	db	('K'-100O),'$',0,0	;Reverse linefeed.
tj:	db	esc,'Y$',0		;Clear to end of screen.
tk:	db	esc,'T$',0		;Clear to end of line.


;Microbee software serial port routines
porta	equ	0
portb	equ	2


; interrupt vectors
; We change the Z80 Interrupt register to point to these vectors.
; Instead of trying to identify a particular Microbee system, 
; we just put vectors here for all systems.
;
; known vectors are:
;  48h : 56k (64k apc) - tested 19-Jun-1990
;  48k : 64k           - tested 01-Sep-1990
;  50h : dreamdisk (3rd party disk for Microbee)
;  e0h : 128k          - tested 19-Jun-1990
;  e0h : 256k          - tested 01-Sep-1990

	org	($ and 0ff00h) + 100h
int	equ	$/256	; byte for interrupt register

	dw	inta	; printer vector
	dw	intb	; rs232 vector
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	dw	inta
	dw	intb
	

; tables for baud rates
t75:	db	124,13	; full delay
	db	55,7	; semi delay
	db	168,255	; txrx delay
	dw	trout	; address of subroutine to transmit char
t7512:	db	124,13	; 75R/1200T
	db	55,7
	db	194,1	; txout delay
	dw	txout
t110:	db	129,9
	db	55,5
	db	5,217	
	dw	trout
t150:	db	59,7
	db	23,4
	db	2,158
	dw	trout
t300:	db	26,4
	db	134,2
	db	3,75
	dw	trout
t600:	db	139,2
	db	191,1
	db	2,34
	dw	trout
t1200:	db	195,1
	db	90,1
	db	3,13
	dw	trout
t1275:	db	195,1	; 1200R/75T
	db	90,1
	db	124,13
	dw	txout
t2400:	db	94,1
	db	40,1
	db	2,3
	dw	trout
t4800:	db	44,1
	db	15,1
	db	44,1
	dw	txout
t9600:	db	19,1
	db	1,1
	db	19,1
	dw	txout


; copy table entries to locations used by serial routines
setbaud:
	lxi	h,fulldel
	mvi	b,8
setb2:	ldax	d
	mov	m,a
	inx	h
	inx	d
	dcr	b
	jnz	setb2
	ret


;transmit character in E
; destroys all regs
txout:	mvi	b,ntotal	;total number of bits to send
	di
	in	portb		;c = portb with tx bit zeroed
	ani	0dfh
	mov	c,a
	ora	a		;carry=0 (start bit)
txout2:	mov	a,c		; 4T
	jnc	txout4		;10T skip if space
	ori	20h		; 3T (average)   set mark
txout4:	out	portb		;11T
	lhld	txrxdel		;16T
txout6:	dcr	l		;delay
	jnz	txout6
	dcr	h
	jnz	txout6		;  14*L + 14*H + 3584*(H-1)
	stc			; 4T carry=1 (stop bit)
	mov	a,e		; 4T shift next bit to carry
	rar			; 4T
	mov	e,a		; 4T
	dcr	b		; 4T
	jnz	txout2		;10T
				;loop = 74T + (delay loop)
	ei
	ret

	
;
;transmit character in E
;simultaneous receive char if necessary
trout:	mov	a,e
	mvi	b,ndata
	lxi	h,0
tro2:	rrc		;shift tx char to hl
	mov	c,a
	mov	a,l
	ral
	mov	l,a
	mov	a,h
	ral
	mov	h,a
	mov	a,c	;recover
	dcr	b
	jnz	tro2
tro10:	mvi	b,tqfudge ;adjust char in hl to align with
			  ;tx bit of portb
tro12:	stc		; pad out
	mov	a,l
	ral
	mov	l,a
	mov	a,h
	ral
	mov	h,a
	dcr	b
	jnz	tro12
	mvi	a,0ffh	;flag to say we are not receiving
	sta	trtemp	;save it
	mvi	d,tqbit	;total number of qtr bits to send
	in	portb	;b = portb with tx bit zeroed
	ani	0dfh
	mov	b,a
	mvi	e,0	;we are not receiving yet
tro14:	in	portb
	ori	8h	;test CTS
	jz	tro14	;loop till Clear To Send
	out	09h	;Color Wait OFF
	di
	call	qbit
	lda	trtemp	;are we receiving
	ora	a
	jnz	tro22	;skip if not
	in	portb	;is last bit a mark?
	ori	10h
	jz	tro18	;skip if mark (don't wait for stop)
	lhld	fulldel ;delay to stop bit
tro16:	dcr	l
	jnz	tro16
	dcr	h
	jnz	tro16
tro18:	lhld	wptr		; check buffer
	xchg
	lhld	rptr
	dcx	d		; decrement queue pointer
	mov	a,d
	ora	e
	jnz	tro20		; skip if no queue wrap around
	lxi	d,maxque-1	; wrap around
tro20:	mov	a,l		; sub hl,de
	sub	e
	mov	l,a
	mov	a,h
	sbb	d
	mov	h,a
	ora	l		; check for zero
	jz	tro22		; skip if buffer full
	xchg
	shld	wptr		; update queue
	lxi 	d,rqueue
	dad	d
	mov	m,c		; put char in queue
tro22:	ei
	ret			;ret


; routine for quarter bit timing
; for transmit and simultaneous receive
; total execution time is 223T + L*14T + H*34T
qbit:	call	txrx	;17T + 162T
	lda	txrxdel	;13T
qbit2:	dcr	a	; 4T
	jnz	qbit2	;10T
	lda   txrxdel+1 ;13T
qbit4:	dcr	a	; 4T
	nop		; 4T
	nop		; 4T
	nop		; 4T
	nop		; 4T
	nop		; 4T
	jnz	qbit4	;10T
	mov	a,d	; 4T Check if still sending or receiving
	ora	e	; 4T
	jnz	qbit	;10T
	ret


;simultaneous transmit/receive
;do next quarter bit
; regs: b = portb with tx bit zeroed
;	c = character being received
;	d = number of qtr bits remaining to send
;	e = number of qtr bits remaining to receive (0 if not receiving)
;	hl = character being transmitted
;this subroutine always executes in 162T (or 163T)
txrx:	mov	a,d	; 4T qtr bits remaining to send
	ora	a	; 4T
	jz	txrx12	;10T skip if no bits remaining (may be receiving)
	ani	03h	; 7T a complete bit?
	jnz	txrx10	;10T skip if not
	dad	h	;11T shift tx bit to bit 5 of h
	mov	a,h	; 4T
	ani	20h	; 7T extract tx bit
	ora	b	; 4T combine with portb
	out	portb	;11T send it
txrx2:	dcr	d	; 4T one less qtr bit to send
			;76T total
;now receive part
txrx4:	mov	a,e	; 4T qtr bits remaining to receive
	ora	a	; 4T
	jz	txrx16	;10T skip if not receiving
	ani	3h	; 7T a complete bit?
	jnz	txrx14	;10T skip if not
	in	portb	;11T get input
	ani	10h	; 7T extract rx bit
	sui	1	; 7T bit to carry
	mov	a,c	; 4T bit to c
	rar		; 4T
	mov	c,a	; 4T
txrx6:	dcr	e	; 4T one less qtr bit to receive
txrx8:	ret		;10T
			;86T total

;come here if transmitting, but not a complete bit
;delay to match up execution times
txrx10:
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ori	00h	; 7T
	jmp	txrx2	;10T

;come here if not sending (but still receiving)
;delay to match up execution times
txrx12:	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	jmp	txrx4	;10T

;come here if receiving (but not a complete bit)
;delay to match up execution time
txrx14:	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ori	00h	; 7T
	jmp	txrx6	;10T

;come here if not receiving
txrx16:	in	portb	;11T check if start bit
	ani	10h	; 7T
	jz	txrx18	;10T skip if mark
	mvi	e,rqbit ; 7T get quarter bit count for receive
	xra	a	; 4T
	sta	trtemp	;13T store flag to say we are receiving
	ori	a	; 7T delay (should be 6T)
	ret		;10T
	
txrx18:	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	ora	a	; 4T
	jmp	txrx8	;10T




; RS232 input interrupt routine
; stores received character in queue
;				;semi delay starts here
intb:				;20T (approx.) for interrupt
	push	psw		;11T
	push	b		;11T
	push	d		;11T
	push	h		;11T
	in	portb		;11T
	ani	10h		; 7T test input for start bit
	jz	intb16		;10T skip if no start bit.
	out	09h		;11T
	lhld	semidel		;16T half bit delay
intb2:	dcr	l		; 4T
	jnz	intb2		;10T  inner loop 14T*L
	dcr	h		; 4T
	jnz	intb2		;10T  outer loop (14*H + 256*14*(H-1))T
	mvi	e,8		; 6T number of data bits
				;semi delay ends here (125T + delay loop)
				;full delay starts here
intb4:	lhld	fulldel		;16T  full bit delay
intb6:	dcr	l
	jnz	intb6
	dcr	h
	jnz	intb6		;  14*L + 14*H + 3584*(H-1)
	in	portb		;11T test input
	ani	10h		; 7T
	sui	1		; 7T input bit to carry
	mov	a,c		; 4T
	rar			; 4T
	mov	c,a		; 4T and then to C
	dcr	e		; 4T bit count
	jnz	intb4		;10T  loop till all data bits collected
				;full delay ends here (67T + delay loop)
	in	portb
	ani	10h
	jz	intb12		; skip if mark
	lhld	fulldel		; wait for stop bit
intb10:	dcr	l
	jnz	intb10
	dcr	h
	jnz	intb10
intb12:	lhld	wptr		; check buffer
	xchg
	lhld	rptr
	dcx	d		; decrement queue pointer
	mov	a,d
	ora	e
	jnz	intb14		; skip if no queue wrap around
	lxi	d,maxque-1	; wrap around
intb14:	mov	a,l		; sub hl,de
	sub	e
	mov	l,a
	mov	a,h
	sbb	d
	mov	h,a
	ora	l		; check for zero
	jz	intb16		; skip if buffer full
	xchg
	shld	wptr		; update queue
	lxi	d,rqueue
	dad	d
	mov	m,c		; put char in queue
intb16:	pop	h
	pop	d
	pop	b
	pop	psw
	ei
	db	0EDh,4Dh	;reti

;
; get char from serial port buffer.
; exit:  A=char  or  Z if no char
rsin:	push	d
	push	h
	lhld	rptr
	xchg
	lhld	wptr
	mov	a,l		;sub hl,de
	sub	e
	mov	l,a
	mov	a,h
	sbb	d
	mov	h,a
	ora	l		;check for zero
	jnz	rsi4		;get char
rsi2:	pop	h
	pop	d
	ret

rsi4:	push	psw
 	dcx	d		; decrement queue pointer
	mov	a,d
	ora	e
	jnz	rsi6		; skip if no queue wrap around
	lxi	d,maxque-1	; wrap around
rsi6:	pop	psw
	xchg
	shld	rptr
	lxi	d,rqueue
	dad	d
	mov	e,m	;get char from queue
	ori	0ffh	;set NZ
	mov	a,e
	jmp	rsi2

; printer routines

inta:	sta	ptemp
	mvi	a,0
	sta	pflag
	lda	ptemp
	ei
	db	0EDh,4Dh	;reti

parout:	push	h
	lxi	h,pflag
par2:	db	0CBh,46h	;bit	0,(hl)
	jnz	par2
	mvi	m,0ffh
	out	porta
	pop	h
	ret

; data storage

oldint:		db	0	; storage for old i reg
trtemp:		db	0
ptemp:		db	0	;temp storage used by inta interrupt
pflag:		db	0	;0ffh if waiting for printer. 00h if ready

;receive queue pointers
maxque		equ	2048	; receiver queue size
rptr:		dw	maxque-1
wptr:		dw	maxque-1

;transmit
ndata	equ	8	; 8 data bits
nstrt	equ	1	; 1 start bit
nstop	equ	1	; 1 stop bit
ntotal	equ	nstrt+ndata+nstop
rqbit	equ	4*(nstrt+ndata)		;number of quarter bits to receive
tqbit	equ	4*(nstrt+ndata+nstop)	;number of quarter bits to transmit
tqfudge	equ	13-nstrt-ndata

;H=0 or L=0 behave as 256
;receive delays.
fulldel:	dw	0	; 3584(H-1) + 14H + 14L + 67 cycles
semidel:	dw	0	; 3584(H-1) + 14H + 14L + 125 cycles
;1/4 bit transmit and simultaneous tx/rx delay  34H + 14L + 223 cycles
;or full bit delay  3584(H-1) + 14H + 14L + 74 cycles
txrxdel:	dw	0	;
txcall:		dw	trout	; address of subroutine to transmit char

; receiver queue
rqueue:		ds	maxque


ovlend	equ	$	; End of overlay

IF lasm
	END
ENDIF
