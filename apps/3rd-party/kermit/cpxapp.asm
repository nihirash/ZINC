IF NOT lasm
.printx * CPXAPP.ASM *
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
; edit 2, 22 July, 1987 by OBSchou.  Massaged code to work with CPXCOM.ASM
;
; edit 1, 2nd June, 1987 by OBSchou.  Extracted all Apple related code.
;
;
;      Family is the string used in VERSION to say which of several 
;       smaller overlay files are used.  These are (will be) derived from 
;       the juge CPXSYS.ASM file, in which case we will never get here.  
;       Just a Dollar, but put a sting in for a family of machines.
;
family:	db      'CPXAPP.ASM (2)  22-jul-87$'    ; Used for family versions....
;
	
IF apple
.printx	* Assembling KERMIT-80 for the Apple ][	*
ENDIF;apple
IF apmmdm
.printx	*   with Z80 Softcard &	Micromodem II	*
ENDIF;apmmdm
IF ap6551
.printx	*     with Z80 Softcard	& 6551 ACIA	*
ENDIF;ap6551
IF ap6850;[32]
.printx	*     with Z80 Softcard	& 6850 ACIA	*
ENDIF;ap6850 [32]
IF apcps;[22]
.printx	*     with Softcard & CPS Multifunction	card	 *
ENDIF;apcps

;

IF ap6551 OR ap6850 OR apcps;[9] [14]
				;jb eg. Apple SSC, Videx PSIO, Basis 108
apslot	EQU	2		;jb set equal to slot containing serial card
				;jb  set to 1 for Basis built-in port
ENDIF;jb ap6551 [9] apcps ap6850 [14]
IF ap6850	;[14] offset in slot I/O space for ACIA registers
		;e.g. PACT=00,01: AIO-I=05,04: AIO-II=0D,0C: Aristocard=0B,0A
apdat	EQU	0DH		;data reg.=0E080h+apslot*10h*apdat
apstat	EQU	0CH		;comm/stat reg.=0E080h+apslot*10h+apstat
ENDIF;ap6850


IF apmmdm
;APPLE Slot 2 contains Micromodem II.
MNPORT	EQU	0E0A7H	;Communications Port.
mnprts	EQU	0E0A6H	;Communications Port Status.
mnmodm	EQU	0E0A5H	;Modem Control Port.
orgmod	EQU	8EH	;Modem Originate Mode.
OUTPUT	EQU	02H	;Output Buffer Empty.
INPUT	EQU	01H	;Input Register Full.
apinc1	EQU	03H	;First Init Character for 6850 ACIA (Reset)
apinc2	EQU	11H	;Second Init Character for ACIA (8-bits)
apoffh	EQU	80H	;Set if OFFHOOK
AP300	EQU	1	;300 Baud
z80	EQU	TRUE	;Z80 Softcard
ENDIF;apmmdm

IF ap6551		;jb
mnport	EQU	0E088H+(10H*apslot)	;jb Communications Port.
mnprts	EQU	0E089H+(10H*apslot)	;jb Communications Port Status.
mnprtc	EQU	0E08BH+(10H*apslot)	;jb Communications Control
mnprtm	EQU	0E08AH+(10H*apslot)	;jb Communications Master (command)
output	EQU	10H		;jb Output Buffer Empty.
input	EQU	08H		;jb Input Register Full.
mncinb	EQU	18H		;jb Control Port Initialization Byte
				;jb  (8-bit, no parity, 1-stop, 1200 baud)
mnminb	EQU	0BH		;jb Master Port Initialization Byte
				;jb  (DTR, RTS, no interrupts)
z80	EQU	TRUE		;Z80 Softcard
ENDIF;ap6551

IF ap6850 ;[32]
mnport	EQU	0E080H+(10H*apslot)+apdat	;Communications Port.
mnprts	EQU	0E080H+(10H*apslot)+apstat	;Communications Port Status.
OUTPUT	EQU	02H		;Output Buffer Empty.
INPUT	EQU	01H		;Input Register Full.
apinc1	EQU	03H		;First Init Character for 6850 ACIA (Reset)
apinc2	EQU	15H		;Second Init Character for ACIA (8 data, 1 stop bit)
z80	EQU	TRUE		;Z80 Softcard
ENDIF;[32] ap6850

IF apcps		;[22]
mnport	EQU	0E0FAH+(100H*apslot)	; Communications Port.
mnprts	EQU	0E0FBH+(100H*apslot)	; Communications Port Status.
mnprtc	EQU	0E0FEH+(100H*apslot)	; Communications Control
output	EQU	1		; Output Buffer Empty.
input	EQU	2		; Input Register Full.
TxEmpty	EQU	04h		; Transmitter empty flag
apmod1	EQU	4EH		; Mode Byte 1 (1 stop, no parity,8-bit, 16x)
				; Mode Byte 2 is speed control byte
apcmd	EQU	37H		; Command Byte (RTS,Error reset,RxE,DTR,TxE)
z80	EQU	TRUE		;Z80 Softcard
ENDIF;[22] apcps

IF apple 
defesc	EQU	']'-100O        ;The default escape character.
ENDIF;apple 


; default to VT52-EMULATION ON.

vtval	EQU	1



sysxin:		; continuation of systemm dependent initialisation code

IF ap6551
	lda	mnprtc		; read control port
	ani	0fH		; extract low order nybble
	sta	speed		; store as comm line speed
	sta	speed+1		;  (16 bits, to match speed table entries)
	mvi	a,mnminb	;jb initialization routine
	sta	mnprts		;jb
	sta	mnprtm		;jb initialize master (command) port
	mvi	a,mncinb	;jb
	sta	mnprtc		;jb initialize control port
ENDIF;ap6551

IF ap6850 ;[32]
	mvi	a,apinc1	;Init ACIA
	sta	mnprts
	mvi	a,apinc2	;Set ACIA bits per character
	sta	mnprts
ENDIF;[32] ap6850

IF apcps		;[22]
	lxi	h,3737h		;Default 1200 baud
	shld	speed		;Store as port speed
	xchg
	call	sysspd		;Initialise the port
ENDIF;[22] apcps

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
IF apmmdm
	call	ckdial		;See if dialing is required.
	 jmp	kermit		;Go to command loop if aborted.
ENDIF;apmmdm

	ret

conmsg:		; Messages printed when entering transparent (CONNECT) mode:
;

IF apmmdm
;This code was mostly taken from
;       APMODEM.ASM V2.1
;       Based on MODEM.ASM by Ward Christensen
;       Modified for the Apple ][ by Gordon Banks 1-Jan-81
;       Micromodem ][ dialer option by Dav Holle  2-Feb-81
;       Code modified for KERMIT by Scott Robinson 14-Oct-82
;
;Come here to see if we need to dial a number.
;
ckdial:	lda	mnport		;access the data port
	lda	mnprts		;check status
	ani	4		;do we already have carrier?
	jz	rskp		;Yes, just continue
	xra	a		;Hangup Phone for starters
	sta	mnmodm
	lxi	b,1000		;Delay for a second
	call	delay
	mvi	a,8FH		;orgmod+ap300+apoffh
	sta	holdd		;storing mode for after dialing
	mvi	A,8DH		;Go Offhook to start dialing sequence
	sta	mnmodm
	mvi	a,apinc1	;Init ACIA
	sta	mnport
	mvi	a,apinc2	;Set ACIA bits per character
	sta	mnport

	lxi	b,2500		;wait 2.5 seconds for dial tone
	call	delay
	lxi	d,dialms	;Ask the user for the number
	call	prtstr
;
gtdial:	mvi	c,conin		;Get a character
	call	bdos
	push	psw		;save it
	cpi	30H		;is it big enough to dial?
	jc	dialed		;no
	cpi	3AH		;is it too big to dial?
	jnc	dialed		;yes
	ani	0FH		;ok, it's a digit, get its value
	jnz	dialnz		;dial nonzero digits as-is
	mvi	A,10		;dial zero as ten
;
dialnz:	mov	e,a		;count pulses in E-reg
dopuls:	mvi	a,0DH		;put it on-hook
	sta	mnmodm
	lxi	b,61		;61-millisec pulse
	call	delay
	mvi	a,8DH		;take it off-hook again...
	sta	mnmodm
	lxi	b,39		;39-millisec delay between pulses
	call	delay
	dcr	e		;any more pulses to do?
	jnz	dopuls		;yep, do 'em
	lxi	b,600		;delay 600 msecs between digits
	call	delay
;
dialed:	pop	psw		;get back the char
	cpi	cr		;do we have a CR (done dialing)?
	jnz	gtdial		;no, keep on dialin'
	lxi	d,dialm2
	call	prtstr

tictoc:	mvi	c,dconio	;Direct console input.
	mvi	e,0FFH
	call	bdos
	ora	a		;Have a charcter?
	jnz	nodial		;If so we abort
	lda	mnport		;access the data port
	lda	mnprts		;get modem status
	ani	4		;carrier?
	jnz	tictoc		;No
;
	lda	holdd		;get the old modem control byte
	sta	mnmodm		;turn our carrier on

	lxi	d,dialm3
	call	prtstr
	jmp	rskp
nodial:	xra	a		;Hangup the modem.
	sta	mnmodm
	ret			;Return to abort the command.
;
holdd:	db	0		;Modem setup code
dialms:	DB	'Number to Dial: $'
dialm2:	DB	CR,LF,'Awaiting Carrier....(any key aborts)$'
dialm3:	DB	cr,lf,'Connected.',CR,LF,'$'
;
;DELAY wait for the number of millisecs in B,C
;
delay:	push	b		;save B,C
	push	d		;save D,E
	inr	b		;bump B for later DCR
;
delay1:	mvi	e,126		;delay count for 1 millisec (Apple Z80
				;clock=2.041MHz)
;
delay2:	dcr	e		;count
	jnz	delay2		;down
;
	dcr	c		;more millisecs?
	jnz	delay1		;yes
	dcr	b		;no - more in hi byte?
	jnz	delay1		;yes
	pop	d		;no,    restore D,E
	pop	b		;       restore B,C
	ret
ENDIF;apmmdm
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
IF apmmdm OR apcps OR ap6850 ;
	lxi	d,inhlps	; we got options...
	call	prtstr		; print them.
ENDIF	;apmmdm OR apcps OR ap6850

	ret


;additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:

IF apcps OR ap6850
	db	cr,lf,'B  Transmit a BREAK'
ENDIF;apcps OR ap6850

IF apmmdm 
	db	cr,lf,'D  Drop the line'
ENDIF;apmmdm 

	db	'$'                     ;[hh] table terminator

;
;       sysint - system dependent special functions
;       called when transparent escape character has been typed;
;       the second character of the sequence is in A (and in B).
;       returns:
;       non-skip: sequence has been processed
;       skip:   sequence was not recognized
sysint:	ani	137O		; convert lower case to upper, for testing...
IF apmmdm
	cpi	'D'             ;Disconnect Modem?
	jnz	intc00		;No.
	xra	a		;Yes, hangup the modem
	sta	mnmodm
	ret			; command has been executed
intc00:
ENDIF;apmmdm

IF ap6850 OR apcps		; [22] [25] ... some more
	cpi	'B'             ; send break?
	jz	sendbr		; yes, go do it.  return nonskip when through.
ENDIF;[22] ap6850 OR apcps 

	jmp	rskp		; take skip return - command not recognized.


;

IF ap6850 ;[32]
sendbr:
;
;       Ensure that the transmitter has finished sending buffered chars
sndbr1:	lda	mnprts		; get UART status
	ani	output		; everything sent?
	jz	sndbr1		; no, wait a bit more
;
; Begin sending a break
	mvi	a,apinc2
	ori	60h		;transmit break level, CTS high
	sta	mnprts
;
; Wait for 250 milliseconds (using hundredths second delay routine)
	mvi	a,25
	call	delay
;
; Resume normal operation
	mvi	a,apinc2
	sta	mnprts
;
	ret			;done
ENDIF;[32] ap6850

IF apcps		;[22]
sendbr:
;
;       Ensure that the transmitter has finished sending buffered chars
sndbr1:	lda	mnprts		; get UART status
	ani	TxEmpty		; everything sent?
	jz	sndbr1		; no, wait a bit more
;
;       Unmask command register
	mvi	a,80h
	sta	mnprtc
;
;       Begin sending a break by setting bit in UART command register
	mvi	a,3Fh		; Set TxEna, DTR, RxEna, SBreak, ErrRst, RTS
	sta	mnprts
;
;       Wait for 250 milliseconds (using hundredths second delay routine)
	mvi	a,25
	call	delay
;
;       Resume normal operation by clearing the SendBreak command bit
	mvi	a,37h		;Set TxEna, DTR, RxEna, ErrRst, RTS
	sta	mnprts
;
;       Remask command register
	mvi	a,0
	sta	mnprtc
;
	ret			;done
ENDIF;[22] apcps

;

;
;       sysflt - system-dependent filter
;       called with character in E.
;       if this character should not be printed, return with A = zero.
;       preserves bc, de, hl.
;       note: <xon>,<xoff>,<del>, and <nul> are always discarded.
sysflt:
	mov	a,e		; get character for testing

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
IF apmmdm
	xra	a		;Hangup our end, too.
	sta	mnmodm
ENDIF;apmmdm

	ret
;

;       This is the system-dependent command to change the baud rate.
;       DE contains the two-byte value from the baud rate table; this
;       value is also stored in 'speed'.
sysspd:

; Set the speed for Apple with 6551 ACIA
IF ap6551
	lda	mnprtc		;jb read control port
	ani	0F0H		;jb zap low order nybble
	ora	e		;jb put rate in low order nybble
	sta	mnprtc		;jb send to control port
	ret
ENDIF;ap6551

; Set the speed for Apple with CPS Multifunction card
IF apcps		;[22]
	mvi	a,80h
	sta	mnprtc
	lda	mnprts		;read command register to reset 2651
	mvi	a,apmod1	;first mode byte
	sta	mnport
	mvi	a,4		;waste some time before sending second byte
spdwt:	dcr	a		; 4 T-states
	jnz	spdwt		; 10 T-states
	mov	a,e		;second mode byte is speed byte
	sta	mnport
	mvi	a,apcmd		;command byte
	sta	mnprts
	xra	a
	sta	mnprtc
	ret
ENDIF;[22] apcps


IF ap6551					;jb
spdtbl:	db	0DH				;jb 13 entries
	db	03H,'110$',     03H,03H ;jb
	db	04H,'1200$',    08H,08H ;jb
	db	05H,'134.5$',   04H,04H ;jb
	db	03H,'150$',     05H,05H ;jb
	db	04H,'1800$',    09H,09H ;jb
	db	05H,'19200$',   0FH,0FH ;jb
	db	04H,'2400$',    0AH,0AH ;jb
	db	03H,'300$',     06H,06H ;jb
	db	04H,'3600$',    0BH,0BH ;jb
	db	04H,'4800$',    0CH,0CH ;jb
	db	03H,'600$',     07H,07H ;jb
	db	04H,'7200$',    0DH,0DH ;jb
	db	04H,'9600$',    0EH,0EH ;jb

sphtbl:	db	cr,lf,'  110    134.5  150    300    600   1200   1800'
	db	cr,lf,' 2400   3600   4800   7200   9600  19200$'
ENDIF;ap6551

IF apcps		;[22]
spdtbl:	db	10H				; 16 entries
	db	03H,'110$',     32h,32h
	db	04H,'1200$',    37h,37h
	db	05H,'134.5$',   33h,33h
	db	03H,'150$',     34h,34h
	db	04H,'1800$',    38h,38h
	db	05H,'19200$',   3fh,3fh
	db	04H,'2000$',    39h,39h
	db	04H,'2400$',    3ah,3ah
	db	03H,'300$',     35h,35h
	db	04H,'3600$',    3bh,3bh
	db	04H,'4800$',    3ch,3ch
	db	02H,'50$',      30h,30h
	db	03H,'600$',     36h,36h
	db	04H,'7200$',    3dh,3dh
	db	02H,'75$',      31h,31h
	db	04H,'9600$',    3eh,3eh

sphtbl:	db	cr,lf,'   50    75   110    134.5  150    300    600   1200'
	db	cr,lf,' 1800  2000  2400   3600   4800   7200   9600  19200$'
ENDIF;[22] apcps



; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
IF apmmdm OR ap6850 ;[32]
spdtbl	equ	0		; SET BAUD not supported.
sphtbl	equ	0
ENDIF;appmdm OR ap6850 [32]
;
;
;       no ports available for Apple
prttbl	EQU	0		;SET PORT not supported
prhtbl	EQU	0

;
;

;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:

	ret
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
	ret

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
	ret
;

;
;       outmdm - output a char from E to the modem.
;               the parity bit has been set as necessary.
;       returns nonskip; bc, de, hl preserved.
outmdm:
IF apple 
	push	h
outmd1:	lxi	h,mnprts	;address of the port status register
outmd2:	mov	a,m		; get port status in A
	ani	output		;Loop till ready.
	jz	outmd2
outmd3:	lxi	h,mnport	;address of port data register
	mov	m,e		; write the character
	pop	h
	ret
ENDIF;apple 




;

;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
IF apple 
inpmd1:	lda	mnprts		;Get the port status into A.
	ani	input		;See if the input ready bit is on.
	rz			;If not then return.
inpmd2:	lda	mnport		;If so, get the char.
ENDIF;apple


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
	xra	a
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

;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:

	lxi	d,delstr
	jmp	prtstr

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

IF apple
sysver:	db	'Apple II CP/M$'
outlin:	db	('^'-100O),esc,'Y',cr,lf,'  $'
erascr:	db	('^'-100O),esc,'Y$'     ;Clear screen and go home.
eralin:	db	cr,esc,'T$'             ;Clear line.
delstr:	db	bs,bs,'$'               ; Adjust for delete
curldn:	db	esc,'=$'                ;Cursor lead-in
ttab:					;Table start location.
ta:	db	('K'-100O),'$',0,0      ;Cursor up.
tb:	db	12O,'$',0,0             ;Cursor down.
tc:	db	('F'-100O),'$',0,0      ;Cursor right.
td:	db	'$',0,0,0               ;(can't) Cursor left
te:	db	'$',0,0,0               ;(can't) Clear display
tf:	db	'$',0,0,0               ;(can't) Enter graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit graphics mode
th:	db	('^'-100O),'$',0,0      ;Cursor home.
ti:	db	('K'-100O),'$',0,0      ;Reverse linefeed.
tj:	db	esc,'Y$',0              ;Clear to end of screen.
tk:	db	esc,'T$',0              ;Clear to end of line.
ENDIF;apple

ovlend	equ	$	; End of overlay

	END
