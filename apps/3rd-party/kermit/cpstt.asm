; CPSTT.ASM
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
;       This file contains the code for the TRANSMIT and CONNECT commands,
;       which communicate with a host which is not running KERMIT.
;
; revision history:
;
;edit 12, 31-Jan-1991 by MF. Delete call to "inbuf" after "xmit1" in
;	the TRANSMIT command. "getfil" initializes various counters so that
;	when "in1chr" is first called, "inbuf" will be called immediately
;	and will read sectors of the file to be transmitted from disk.
;	This, along with a fix to "in1chr" in CPSUTL.ASM, fixes a bug
;	discovered by Lance Tagliapietra of the University of Wisconsin at
;	Platteville wherein the TRANSMIT command was failing to transmit some
;	characters in files over one sector in length. See CPSUTL.ASM,
;	edit 29.
; edit 11, 10 September, a987, by OBSchou.  Modified TRANSMIT command
;	to TRANSMIT <file> <string>
;
; edit 10, 27 August, 1987 by OBSchou.  Fixed bugs in Transmit, but I may
;	be introducing problems for IBM/CMS or half duplex systems.  What
;	does this combination do??
;
; edit 9 30 March, 1987 by OBSchou to replace the TRANSMIT routine.
;	Syntax is now TRANSMIT file after a previous 
;	INPUT <wait time> <string to wait for>
;
; edit 8 19 June, 1986 by OBSchou.  Modified the interupt testing routine
;       to see if the command was a 'D' (Drop the line), in which case also
;       do a 'C', ie disconnect.  This is really a little too much of a
;       system dependent thing.
;       For now, Ill leave it here, and possibly move it later.
;
; edit 7 30 May 1986 OBSchou.  Moved xon/xoff control (ie XON/OFF sent to host)
;       out to CPSUTL so that ther printer routine can use it too.
;
; edit 6 30 April, 1986 by OBSchou.
;       Fixed transmit bug, so as soon as the protocol character is 
;       received from the host is received then another line is sent.
;       added in a comchr (ds 1) to save the character read from the comm 
;       line in prtchr, and is restored in a on return.
;
; edit 5 7 March, 1986 by OBSchou Loughborough University.  
;       Need to save the E register before calling outmdm (in CPSSYS.ASM)
;       if doing Half duplex.  Push/pop DE should sort this problem
;
; edit 4: 13-Jan-85 by Vanya J.Cooper Pima Commun. College Tel: 602-884-6809
;
;pcc002 28-Dec-84       modules:cp4tt,cp4utl
;       Add connect mode <esc>P command to toggle printer on
;       and off.  Conflicts with "official" recommended commands
;       in protocol manual, but I don't think CP/M will ever get
;       a PUSH command.
;
;pcc003-pcc005  2-Jan-85        vjc     modules:cp4mit,cp4tt,cp4utl
;       These edits must all be installed together and change the way
;       logging is handled.  The log file spec is moved to a separate
;       fcb, and not opened until an actual CONNECT command is given.
;       This takes care of a NASTY bug that if you used any other file
;       command between the LOG and CONNECT, the log file would get
;       written over the last file used.  This also allows logging to
;       be "permanently" enabled until an CLOSE (new command) for all
;       CONNECT sessions, like most other kermits do.  If a log file
;       already exists, it will be appended to.  Also add two new
;       CONNECT mode commands <esc>Q to suspend logging and <esc>R to
;       resume.  <esc>R means something else during TRANSMIT, but
;       logging is never on then, so there shouldn't be any conflict.
;       I also changed the write code, so that it can handle one more
;       character after the XOFF is send to stop the host.  This allows
;       a little "slop" for systems that don't stop immediately (such
;       as TOPS10), but it didn't help much.
;
;pcc008 2-Jan-85        vjc     modules:cp4def,cp4tt,cp4utl
;       Keyboard input during CONNECT mode can get locked out if
;       there is enough input from the modem port to keep prtchr
;       busy.  This can happen for example, if the printer is running
;       at the same speed as the modem line, leaving you helpless to
;       turn it off or abort the host.  Add a fairness count, so that
;       at least every prfair characters we look at console input.
;
;pcc012 4-Jan-85        vjc     modules:cp4mit,cp4tt,cp4utl
;       Use the big buffer for the log file.  Move the log file back
;       into the common fcb and only save the drive, name, and
;       extension between connects.  Add new routines to cp4utl to
;       create or append to an existing file, and to conditionally
;       advance buffers only if in memory.  Remove edit pcc003 that
;       allows one more character after the xoff, since it didn't
;       really work very well and does not fit in well with the way
;       the buffer advancing routines are set up.  If someone still
;       thinks this would be useful, it could be put back in with a
;       little more work.
;       
;       While testing this edit, I also noticed another bug that
;       the command parsing routines do not limit or check the
;       length of command lines or file specs, trashing what ever
;       comes after them.  Currently because of where the fcb and
;       command buffer are located, this does not usually cause a
;       problem, but could if an extremely long line was typed in,
;       or in the future multiple fcbs defined elsewhere in memory
;       were used.  Maybe this should be put on the bug list
;       somewhere.
;
; edit 3: July 27, 1984
;       Allow assembly with LASM: to CP4TT is linked by CP4PKT, and links
;       to CP4CPM; remove exclamation points so as not to confuse LASM.
;       Add Toad Hall TACtrap to TRANSMIT command (TAC intercept character
;       is only doubled if it's data; when typed by the user, they're not
;       automatically doubled)
;
; edit 2: June 7, 1984
;       formatting and documentation; add module version number; make sure
;       console is selected when leaving intchr.
;
; edit 1: May, 1984
;       extracted from CPMBASE.M80 version 3.9; modifications are described
;       in the accompanying .UPD file.

ttver:	db	'CPSTT.ASM  (12) 31-Jan-1991$'

;       This is the TRANSMIT command.  It attempts to send a file, even
;       though there is no KERMIT on the other side.
;       here from: kermit
;
; [OBS] I have replaced the routine, so that TRANSMIT <filename> <wait string>
; will send a line at a time to the host in a manner similar to MSKERMIT
;
;
xmit:	mvi	a,cmofi		;Parse an input file spec (non-wild).
	lxi	d,fcb		;Give the address for the FCB.
	call	comnd
	jmp	kermit		;Give up on bad parse.
;
	lxi	d,stbuff	; where to put the string
	mvi	a,cmtxt		; get text
	call	comnd
	jmp	kermit		; not quite correct...
	sta	strcnt		; string count returned in a
	ana	a		; if its zero, make it 1 character (CR)
	jnz	xmit0
	mvi	a,1
	sta	strcnt
	mvi	a,cr
	sta	stbuff
;
xmit0:	call	cfmcmd
	call	getfil		;Open file.
	cpi	0FFH		;Succeed?
	jnz	xmit1
	lxi	d,erms15
	call	prtstr		;Display error msg.
	jmp	kermit

;
; New TRANSMIT routine - transmit a file, line by line, to a remote host
;	waiting each time for one or more characters to be returned
;	as a remote host prompt.  It could be as simple as a CR or LF
;	character.  Repeat until the complete file has been sent, then
;	close the transmitted file, and drop into the connect state so the
;	user can tidy up at the host end.
;get the file to send, open it up, and read first sector from disk

xmit1:	lxi	d,inms19	; say we are send a file to the host
	call	prtstr

	xra	a
	sta	repcnt		; clear the host prompt chars. counter 
	sta	starc		; clear star count
;[MF][12]Delete the following call to "inbuf" as the call to "getfil"
;[MF][12]above will have initialized counters and flags so that when
;[MF][12]"in1chr" is called, "inbuf" will be called immediately and will
;[MF][12]immediately read from disk. Counters and flags will then be
;[MF][12]properly set up to read all characters of the file to be
;[MF][12]transmitted.
;	call	inbuf		; read one sector from disk
;	jmp	xmtex		; exit if error


xmt10:	xra	a		; clear retransmit flag and count etc
	sta	rexbfl		; retransmit flag (1=> retransmit)
	sta	rexcnt		; character counter

xmt1:	call	xmt1ch		; send a character
	ani	7fh		; strip any parity
	cpi	cr		; have we reached the end of the line
	jnz	xmt1		; nope, loop around again

; Now wait for a string back from the host.  Compare with STRING buffer
;
	xra	a		; clear the character count
	sta	rexcnt
;
	call	selcon		; sent a line, send a star to console
	mvi	e,'*'
	call	outcon
	lda	starc		; update star count
	inr	a
	sta	starc
	cpi	60		; sent 60 stars?
	jnz	xmt1a		; nope...
	xra	a
	sta	starc
	call	prcrlf
xmt1a:

xmt3:	lda	eoflag		; have we hit end of file?
	ana	a
	jnz	xmtex		; yup, so quit.
	xra	a
	sta	repcnt		; clear the host prompt chars.counter
xmt2:	call	rd1chl		; read a character from the line
	ani	7fh		; set flags
	jnz	xmt4		; Not zero => we have a character from host
	call	ckchr		; see if *WE* have a character from console
	push	psw		; restore to modem
	call	selmdm
	pop	psw
	ani	7fh		; stip parity (should not be there)
	jnz	xmt2a		; if a null, try again
	lda	strcnt		; if the string length is zero, dont wait.
	ana	a
	jz	xmt1		; so loop back again
	jmp	xmt4		; else test for xon/off and incomming string

xmt2a:	cpi	cntlc		; do we want to abort?
	jz	xmtex		; in which case drop through to connect mode
	cpi	cntlz		; if control z exit back to command loop
	jnz	xmt2b		; else try for other characters
	lxi	d,fcb		; close file before exiting to command loop
	mvi	c,closf
	call	bdos
	jmp	kermit

xmt2b:	cpi	cr		; a cr => resend last line
	jnz	xmt2		; nope, then ignore it
	mvi	a,1
	sta	rexbfl		; else we want to resend the line.
	jmp	xmt1

xmt4:	jmp	xmt6		; skit xoff test for now...*****************

	cpi	xoff		; xoff from host?
	jnz	xmt6
xmt5:	call	rd1chl		; else see if XOFF comming
	ani	7fh
	jnz	xmt6		; assume an xoff
	call	ckchr		; anything at console?
	push	psw
	call	selmdm
	pop	psw
	ani	7fh
	cpi	cntlc		; control-c == abort & play terminal
	jz	xmtex
	ana	a		; anything else?
	jz	xmt5		;loop again

xmt6:	mov	e,a		; save it for a while
	lda	repcnt		; see if this character matches with one in buffer
	lxi	h,stbuff	; point to string buffer
	add	l		; make hl = hl + a
	mov	l,a
	mvi	a,0
	adc	h
	mov	h,a		; not using xra, as that clears the Carry flag
	mov	a,e		; get the character back again
	cmp	m		; is it = to what we expect?
	jnz	xmt3		; no, clear counter and try again
	lda	repcnt		; yes, then update the pointer, and ...
	inr	a		; ... see if we have received all ...
	sta	repcnt		; ... we should have received
	mov	e,a		; save length into E again
	lda	strcnt		; get the length to compare
	sub	e		; if (e) > string length, we have it
	jz	xmt10		; so send next line (clear counters etc)
	jmp	xmt2		; else wait for a little longer


;
; Routine below sends a character to the line.  It sends up to a CR, and then
;	it waits for a reply.  This routine is called from xmt1, so if at 
;	end of file, return.  Then XMT1 will drop through
;	to connect.
xmt1ch:	; send a character from the xmtbuf to the line
	call	selmdm		; just in case it uses it
	lda	eoflag		; have we hit end of file
	ana	a		; set flags
	jnz	xmt1c1		; no, so dont...
	mvi	a,cr		; load up a carriage return
xmt1c1:	call	get1xc		; get the character to send
	cpi	lf		; dont send line feeds
;	jz	xmt1c1
	cpi	cntlz		; if control z, then we are at end of the file
	jz	xmtex		; so close the file and drop into telcon
	cpi	20h		; control character?
	jp	xmt11		; no, so ok
	cpi	cr		; cr, and tabs ok to send
	jz	xmt11
	cpi	tab
	jz	xmt11
	jmp	xmt1c1		; else try for another character

xmt11:	call	setpar		; else set parity etc
	push	psw		; we want to keep this for a while
	mov	e,a		; we need character in e
	call	outmdm
	pop	psw		; restore the character we sent
	mov	e,a		; now, if a TAC is set on..
	lda	tacflg
	ana	a		
	mov	a,e		; (return must have sent character in a)
	jz	xmt1c2		; test for xon/off
	lda	tacchr		;... get the tac character
	cmp	e		; do we send it again?
	jnz	xmt1c2		; test for xon/off
	push	psw		; save character for return. Already set E...
	call	outmdm
	pop	psw

xmt1c2:	ret

get1xc:	; get a character from the sector or re-transmit buffer read 
;	into a.  Read a new sector if we run out.
;
; First, see if we do a retransmit
	lda	rexbfl
	ana	a		; if zero, a genuine line
	jz	get1x1
; have to retransmit a line
	lxi	h,rexbuf
	lda	rexcnt		; add counter to buffer base
	mvi	d,0
	mov	e,a
	dad	d
	inr	a		; update pointer
	sta	rexcnt
	mov	a,m		; get next character to send
	ret			; and exit

get1x1:	call	in1chr		; get a character from the file. 
	mov	c,a		; save it to the retransmit buffer
	lda	rexcnt
	mov	e,a
	mvi	d,0
	lxi	h,rexbuf
	dad	d		; point to next position
	inr	a
	sta	rexcnt		; update the character pointer
	mov	a,c		; restore character to a
	mov	m,c		; get character to c
	ret



; read a character from the line.
rd1chl:	
	call	selmdm		; select the modem
	call	inpmdm		; get input from the modem
	ani	7fh		; strip parity
				; may UPPERCASE-ify if case sensitivity off
	ret			; return to caller

;  End of transmit routine.  Close input file name, and say we are dropping
;  throught to telnet.  Note that if eof not found, it is assumed that
;  this is the ABORT exit.

xmtex:
	lxi	d,fcb		; close the transmitted file
	mvi	c,closf
	call	bdos
	call	selcon		; make sure we are talking to the console

	lda	eoflag		; end of file or abort exit?
	lxi	d,inms22	; assume eof...
	ana	a
	jz	xmtex1
	lxi	d,inms29	; we were wrong, its an abort.
xmtex1:	jmp	telnt1		; and drop through to connect mode
				; telnet does the printing



;
;   telnet - the CONNECT command.
;       here from: kermit
;   telnt1 - entry to connect mode from TRANSMIT command
;       here from: xend

telnet:	call	cfmcmd
	lxi	d,infms7	;Output start of message
; enter here from TRANSMIT command.
telnt1:	call	prtstr
	call	escpr		;Print the escape char.
	lxi	d,infms8	;Output some more of the message
	call	prtstr
	call	escpr		;Print the escape char again.
	lxi	d,inms8a	;Print the remainder of the message
	call	prtstr
	call	syscon		;do system-dependent stuff
	lda	logflg		;[pcc005] Want a log?
	ora	a		;[pcc005]
	cnz	logopn		;[pcc005] Open if so

chrlup:	call	prtchr		;See if char at port (send to console).
	call	conchr		;See if char at console (send to port).
	jmp	kermit		;requested to end session - go to command loop.
	jmp	chrlup		;Go do it again.
;
;
;       prtchr - copy characters from comm line to console
;       returns: nonskip, console selected.
;       called by: xnext, rexmit, telnet
;

prtchr:	call	selmdm		; select modem port
	call	inpmdm		; try to get a character from it
	push	psw		; restore to console
	call	selcon		; select console
	pop	psw		; restore the (possible character) read
	ora	a		; test character
	jnz	prtch0		; if non-zero, process it.
	sta	prtcnt		;[pcc008] zero out prt fairness count
	ret			; return.

prtch0:	ani	7FH		; drop parity bit.
	sta	comchr		;[6] save it in case we need it again
	lda	vtflg		;[9] get the vt52 emulation flag
	cpi	vtdefe		;[9] are we doing external emulation?
	lda	comchr		;[9] collect character again
	jz	extern		;[9] jup, go do it.

	ana	a		; set flags.  it may be a null
	jz	prtchr		; ignore null (filler)
	cpi	del		; ignore delete, too
	jz	prtchr
	cpi	xon		;Is it an XON?
	jz	prtxon		;yes
	cpi	xoff		;Is it an XOFF?
	jz	prtxof		;yes
	mov	e,a		;Set the char aside.
	lda	vtflg		;Get the VT52 emulation flag.
	cpi	vtdefv		;Is the flag set for VT52 (ie 1)
				;0 = none
				;1 = VT52
				;2 = external
				;3 = dumb (traps non printing chars)
				;0ffh not possible by local code (Will change)
	jnz	prtch1		;If not, don't do this stuff.
	lda	escflg		;Get the escape flag.
	ora	a		;Are we working on an escape sequence?
	jz	prtch2		;If not, continue.
	call	vt52		;If so, work on it some more
	jmp	prtchr		;try for more characters.

prtch2:	mov	a,e		;normal text.
	cpi	esc		;Is the char an escape?
	jnz	prtch1		;If not skip on.
	mvi	a,1
	sta	escflg		;Set the escape flag: escape seen.
	jmp	prtchr		;Get another char...

prtch1:	cpi	vtdefe		; are we doing external emulation?
	jnz	prtch3		; assume we continue on
	lxi	h,extern+1	; get address of external emulator
	mov	a,h		; se if address = 0 (not implemented)
	ora	l
	jz	prtch3		; not external, assume we just carry on
	pchl			; go do external emulation.  RET back to caller

prtch3:	cpi	vtdefd		; are we trapping all non printing characters?
	jnz	prtch4		; nope, something else
	lda	comchr		; Dumb terminal.  Lets test the character
	cpi	cr		; cr then ok
	jz 	prtch4		; its ok
	cpi	lf		; lf then ok
	jz	prtch4
	cpi	tab
	jz	prtch4		; assume tabs are expanded
	cpi	space		; if less than 20H ignore it
	rm			; return if a control character

prtch4:	call	sysflt		; ok to print this character (in E)?
	ora	a
	jz	prtchr		; no, skip it.
	lda	logflg		;Get the log flag.
	cpi	81H		;[pcc003] Are we logging
	cz	logit		;[pcc003] Do so if needed
	call	selcon		; select console
	lda	prnflg		;Get Print parallel flag
	ora	a
	cnz	outlpt		; output to printer if flag set
	call	outcon		; output to console.
	lxi	h,prtcnt	;[pcc008] point to prt fairness count
	inr	m		;[pcc008] bump
	mov	a,m		;[pcc008] get it in a
	cpi	prfair+1	;[pcc008] time to be fair?
	jm	prtchr		;[pcc008] no, go around again.
	mvi	m,0		;[pcc008] reset count
	lda	comchr		;[6] restore that character read from comm line
	ret			;[pcc008] and return

; I don't think we want to print xon/xoff - this should be
; flow control only across the link between us and the host.
; (besides, IBM host xon's don't make sense to most micros)
; remember xon/xoff state in xofflg (zero = xon, non-zero = xoff)
prtxon:	xra	a		;Yes, reset XOFF flag
prtxof:	sta	xofflg
	jmp	prtchr		; look for another character
;;[pcc005] Log file routines

;[pcc005]
;    logopn - open the log file
;       Open the log file and append to it if it already exists
;       or create one if not.

logopn:	
	mvi	a,ctrlz		;[9] ignore control-z in log files
	cmp	e		;[9] well, was it?
	rz			;[9] yes, to ignore it.
	lxi	h,lognam	;[pcc012] copy name
	lxi	d,fcb		;[pcc012] to fcb
	lxi	b,12		;[pcc012] 12 bytes
	call	mover		;[pcc012] copy it
	call	appfil		;[pcc012] open file for appending
	jmp	logerr		;[pcc012] error
	lxi	h,logflg	;[pcc005] point to log flag
	mvi	a,80H		;[pcc005] file open flag
	ora	m		;[pcc005] or in contents of logflg
	mov	m,a		;[pcc005] and store back
	lxi	d,inms28	;[pcc005] assume logging is on
	cpi	81H		;[pcc005] check
	jz	prtstr		;[pcc005] print msg if true
	lxi	d,inms27	;[pcc005] no, must be suspended
	jmp	prtstr		;[pcc005] print and return

;
;       logit - output character in E to log file.
;       we assume the host recognizes xon/xoff. (we probably shouldn't)
;       modem port is selected.
;       preserves de
;       called by: prtchr

logit:	lxi	h,chrcnt	;[pcc012] point to buffer count
	dcr	m		;[pcc012] and decrement
	jp	logit1		;[pcc012] continue if ok
	push	d		;[pcc012] save de
	call	outadv		;[pcc012] advance buffer if in memory
	call	logwrt		;[pcc012] sigh, time to write to disk
	pop	d		;[pcc012] restore de
	lda	logflg		;[pcc012] get logging flag
	ora	a		;[pcc012] Did we quit because of an error
	rz			;[pcc012] return now if so
logit1:	lhld	bufpnt		;[pcc012] get buffer pointer
	mov	m,e		;Store the char.
	inx	h
	shld	bufpnt
	ret			;[pcc012] and return

;[pcc012]
;  logwrt - write to log file with XON/XOFF since it may take a while.

logwrt:	call	sndxoff		;[7] send and xoff to host
	call	outbuf		;[pcc012] output the buffer and advance
	call	logerr		;[pcc005] quit if error
	call	sndxon		;[send an xon to host
	ret			;[pcc012]

;[pcc005]
;       logcls - Close the log file and reset the flag

logcls:	lxi	d,infms6	;[pcc005] Tell user we are closing file.
	call	prtstr		;[pcc005]
	call	clofil		;[pcc012] and do it
	jmp	logerr		;[pcc005] jump if error
	lxi	h,logflg	;[pcc005] point to flag
	mov	a,m		;[pcc005] get it
	ani	7FH		;[pcc005] clear the open bit
	mov	m,a		;[pcc005] and store back
	ret			;[pcc005]

;[pcc005]
;    logerr - here on a variety of logging errors
;       just close the file and disable logging
;       called from logopn,logptr,logcls

logerr:	lxi	d,erms22	;[pcc005] Error message
	call	prtstr		;[pcc005] print it
	mvi	c,closf		;[pcc005] Close the file.
	lxi	d,fcb		;[pcc012]
	call	bdos		;[pcc005] 
	xra	a		;[pcc005] clear logflg
	sta	logflg		;[pcc005] so don't try again
	ret			;[pcc005]
;
;
;       VT52 emulation.
;       called by: prtchr
;       A/ contents of escflg (guaranteed non-zero)
;       E/ current character
;       modem is selected.
;
vt52:	cpi	1		; first character after escape?
	jnz	vt52y		; no, must be doing cursor positioning.
;
;       E contains the character that followed the escape.
;       valid characters are:
;       A - cursor up
;       B - cursor down
;       C - cursor right
;       D - cursor left
;       F - enter graphics mode (hard to do on a non-vt52)
;       G - exit graphics mode
;       H - home
;       I - reverse linefeed
;       J - erase to end of screen
;       K - erase to end of line
;       Y - cursor positioning leadin
;       Z - identify terminal as VT52
;       [ - enter hold-screen mode (not supported)
;       \ - exit hold-screen mode (not supported)
;       > - enter alternate-keypad mode? (not supported)
;       = - exit alternate-keypad mode? (not supported)
;
;       Invalid sequences are handled as the VT52 does - the escape and
;       the following character are swallowed, never to be seen again.
;       For <esc>E, the translation table may contain just '$' (no action),
;       or may be used as clear-and-home, as in the Heath/Zenith H19.
;
	mov	a,e		; get the second character of the sequence.
	cpi	'Y'             ; if cursor lead-in handle it.
	jnz	vt52a		; if not, go on.
	mvi	a,2		; state = 2: row follows.
	sta	escflg		; update the flag.
	ret			; back for another character

vt52a:	cpi	'Z'             ; VT52 ID query?
	jz	vt52id		; yes. claim to be one.
	cpi	'A'             ;Less than an 'A'?
	jm	vtig		;Yes - ignore.
	cpi	'K'+1           ;Greater than 'K'?
	jp	vtig		;Yes - ignore.
	sui	'A'             ;Else make into index.
	rlc			;Multiply by four.
	rlc			;(Shift left twice.)
	lhld	pttab		;Load base addr of table.
	mov	e,a		;Move a into de pair.
	mvi	d,00H		;Zero out high byte.
	dad	d		;Double add index+offset.
	xchg			;Exchange de with hl.
	call	selcon		; select console
	call	prtstr		;and syscall.
vtig:				;Ignore escape sequence.
	xra	a		;Reset the ol' escape flag.
	sta	escflg
	ret			;Return home.

; here for <esc>Z.  Tell the host we're a VT52. (Sure we are...)
vt52id:	mvi	a,esc		; response is escape...
	call	setpar		; (need correct parity)
	mov	e,a
	call	outmdm		; (console already selected)
	mvi	a,'/'           ; ... slash ...
	call	setpar		; (with parity)
	mov	e,a
	call	outmdm
	mvi	a,'K'           ; ... K.
	call	setpar
	mov	e,a
	call	outmdm
	jmp	vtig		; clear escape-sequence flag and return.

; here when escflg isn't 0 or 1 - processing cursor positioning sequence.
vt52y:	cpi	2		; looking for row? (y-coordinate)
	jnz	vt52x		; no, must be column.
	mov	a,e		; yes. get coordinate
	sui	(' '-1)         ; convert from ascii (1 = top line)
	sta	vtyval		; store for later
	mvi	a,3		; advance to next state (x coord)
	sta	escflg		; store it
	ret			; try for another character

; here when escflag isn't 0, 1, or 2 - it must be 3. (right?)
; E holds the last character of the cursor positioning sequence.
vt52x:	xra	a		; end of escape sequence, reset state.
	sta	escflg
	mov	a,e		; get column (' ' is left margin)
	sui	(' '-1)         ; make left margin be one
	mov	c,a		; stash column in c
	lda	vtyval		; get row number
	mov	b,a		;  in b
	call	selcon		; select console
	call	csrpos		; call system-dependent cursor positioner
	ret			; all through.
;
;
;       conchr - copy character from console to comm line, processing
;       (kermit's) escape sequences.
;       Enter and exit with console selected.
;       nonskip return: transparent mode terminated.
;       skip return:    still in transparent mode.
;       called by: rexmit, telnet

conchr:	call	inpcon		;Try to get a character from the console
	ani	07FH		;Keep only 7 bits
	jz	rskp		;Null means nothing there.
	mov	e,a		;Move the char for comparison.
	sta	lstchr		;Save it
	lda	escchr		;Get the escape char.
	cmp	e		;Is it an escape char?
	jz	intchr		;If so go process it.
	call	selmdm		; select the modem
	mov	a,e		;Get the char.
	call	setpar		;Set parity (if any).
	mov	e,a		;Restore it.
	push	d		; need to save e in case we are half dplx [5]
	call	outmdm		;Output the char to the port.
	pop	d		; Just in case we are half dplx [5]
	call	selcon		; reselect console
	lda	ecoflg		;Get the echo flag.
	ora	a		;Is it turned on?
	jz	rskp		;If not we're done here.
	mov	a,e		;Get the char.
	ani	7FH		;Turn off the parity bit.
	mov	e,a
	call	outcon		; echo the character.
	jmp	rskp		; use skip return
;
;       transparent escape character has been typed. dispatch on second
;       character. (console is still selected)
;       here from: conchr

intchr:	call	inpcon		; get another character from the console
	ora	a		; zero means no character available yet.
	jz	intchr		; If so, loop until we get a char.
	mov	b,a		;Save the actual char.
	cpi	ctrlc		;is it Control-C?
	jz	contc		;yes
	ani	137O		;Convert to upper case.
	cpi	'C'             ;Is it close?
	jnz	intch0		;If not proceed.
contc:	lxi	d,infms9	;Say we are back.
	call	prtstr
	call	syscls		; call system-dependent close routine
	lda	logflg		;Get the log flag.
	ora	a		;[pcc005] Check if open
	cm	logcls		;[pcc005] Close if needed
	ret

;Here if not a 'C' or '^C'

intch0:	cpi	'S'             ;Is it status?
	jnz	inch01		;If not, proceed.
	call	stat01		;Print out the status stuff.
	call	prcrlf		;[pcc011] add a crlf
	jmp	rskp		;return from conchr

inch01:
inch03:	mov	a,b		;Get the char.
	cpi	'?'             ;Is it a help request?
	jnz	intch1		;If not, go to the next check.
inch3a:	lda	logflg		;[pcc003] Logging flag
	ora	a		;[pcc003] see if active
	jp	inch04		;[pcc005] jump if no file open
	lxi	d,loghlp	;[pcc003] yes, tell about R AND Q
	call	prtstr		;[pcc003]
inch04:	lxi	d,inthlp	;If so, get the address of the help message.
	call	prtstr
	call	sysinh		; print system-dependent help message
	lxi	d,inhlp1	; Tell about doubling the escape character
	call	prtstr
	call	escpr		;Print escape character
	lxi	d,inhlp2	;Print the rest
	call	prtstr
	jmp	intchr		;Get another char.

intch1:	mov	a,b		;Get the character.
	cpi	'0'             ;Is it '0', to send a null?
	jnz	intch3		;No.
	xra	a		;Yes, send an ASCII zero.
	call	setpar		; with the correct parity
	mov	e,a
	call	selmdm		; (to the modem...)
	call	outmdm
	call	selcon		; return with console selected
	jmp	rskp

intch3:	lda	escchr		;Get the escape char.
	cmp	b		;Is it the escape char?
	jnz	intch4		;[pcc002] jump if not
	mov	a,b		;Get the char.
	call	setpar
	mov	e,a		;Restore it.
	call	selmdm
	call	outmdm		;Output it.
	call	selcon		;We promised console would be selected...
	jmp	rskp		;Return, we are done here.
intch4:	mov	a,b		;[pcc002] get it again
	ani	137o		;[pcc002] in upper case
	cpi	'P'             ;[pcc002] toggle printer?
	jnz	intch5		;[pcc003] nope
	lda	prnflg		;[pcc002] get printer flag
	xri	01h		;[pcc002] complement it
	sta	prnflg		;[pcc002] and put back
	jmp	rskp		;[pcc002]
intch5:	lda	logflg		;[pcc003] get log flag
	ora	a		;[pcc003] See if open
	jp	intch7		;[pcc003] no, skip R and Q
	mov	a,b		;[pcc003] get back chr
	ani	137o		;[pcc003] make upper case
	cpi	'R'             ;[pcc003] Is it R
	jnz	intch6		;[pcc003] Jump if not
	mvi	a,81H		;[pcc003] set flag for logging
	sta	logflg		;[pcc003] put it back
	lxi	d,inms28	;[pcc003] message
	call	prtstr		;[pcc003]
	jmp	rskp		;[pcc003] done
intch6:	cpi	'Q'             ;[pcc003] Quit logging?
	jnz	intch7		;[pcc003] no
	mvi	a,82H		;[pcc003] flag for open, but suspended
	sta	logflg		;[pcc003] store away
	lxi	d,inms27	;[pcc003] keep them informed
	call	prtstr		;[pcc003]
	jmp	rskp		;[pcc003]
intch7:				;[pcc003]

intchz:	mov	a,b		; not recognized. get saved copy back.
	push	psw		;[8] save as we will want to test for 'D'
	call	sysint		; interpret system-dependent sequences
	jmp	intchy		;  done. [10] Now see if D.  If so, do a C.
	pop	psw		;[10] tidy stack
	mvi	e,'G'-100O      ;Otherwise send a beep.
	call	outcon		; to the console.
	jmp	rskp

intchy:	pop	psw		;[10] adjust stack
	ani	5fh		;[10] strip parity, make it upper case
	cpi	'D'             ;[10] was it a D?
	jz	contc		;[10] yup, so to the equivalent of an escape-C
	jmp	rskp
;
; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FOR RELEASE!

;	org ($+100h) AND 0FF00H
IF lasm
	LINK	CPSCPM
ENDIF;lasm
