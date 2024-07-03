; CPSPK1.ASM
;       KERMIT - (Celtic for "FREE")
;
;       This is the CP/M-80 implementation of the Columbia University
;       KERMIT file transfer protocol.
;
;       Version 4.0
;
;       Copyright June 1981,1982,1983,1984
;       Columbia University
;
; Originally written by Bill Catchings of the Columbia University Center for
; Computing Activities, 612 W. 115th St., New York, NY 10025.
;
; Contributions by Frank da Cruz, Daphne Tzoar, Bernie Eiben,
; Bruce Tanner, Nick Bush, Greg Small, Kimmo Laaksonen, Jeff Damens, and many
; others. 
;
;       This file contains the (system-independent) routines that implement
;       the KERMIT protocol, and the commands that use them:
;       RECEIVE, SEND, FINISH, and LOGOUT.
;
; revision history:
;
;edit 23, 16-Jan-1991 by MF. The bug of (22) was not fixed (although
;	the error described needed to be corrected). Really fixed the bug this:
;	time. changed "lda 'E'" after "ptch9b" to "mvi a,'E'" -- Zilog
;	mnemonic thinking must've addled my brain!
;edit 22, 14-Jan-1991 by MF. Fix bug in the code which sends an "E" packet
;	to the remote Kermit on encountering "disk full" so that
;	uncontrollified <CR><LF> is not copied to the packet data area (and
;	hence sent to the remote Kermit). This should fix a bug reported
;	by Russell Lang of Monash University in Australia wherein a PC
;	running Kermit in Server mode complained of invalid characters when
;	receiving the "disk full" error packet from CP/M Kermit.
;edit 21 of 3-Jan-1991 by MF. Reverse part of edit 20 which flushes comm
;	input at EOF send: the problem of multiple copies of packets being
;	sent when a stream of files being sent is partially interrupted with
;	^X has been fixed by modifying "inchr" in CPSPK2.ASM.
;edit 20, 2-Jan-1991 by MF. Tightened up code just after "sdata1" and around
;	"sdat14". Added code to flush comm input after user has typed ^X
;	or ^Z to interrupt file sends so that duplicate packets are not
;	sent after the interrupt character (especially ^X) has been typed.
;edit 19, 14-Dec-1990 by MF.  Place "<<>>" around "F" and "X" packets coming
;	as replies to REMOTE commands a la VMS Bliss Kermit.
;	Also type each character of "X" or "F" packet explicitly in case
;	dollar-signs are part of the filename (as in VMS Bliss Kermit
;	when a REMOTE TYPE is given and SET FILE NAMING FULL is in effect).
;	Expanded code is at label rfil3f.
;edit 18, 27-Nov-1990 by MF. Fix bug introduced with edit 17 which resulted
;	in "E" packet being sent twice when receiving file(s) and disk-full
;	occurred. Sorry about that, folks!
;edit 17, 27-Nov-1990 by MF. When receiving files, make the decision as to
;	whether to delete a partially-received file on a "disk full"
;	condition subject to the setting of the SET INCOMPLETE-FILES
;	switch in conformity with the behavior of MSDOS Kermit.
;	An "E" packet is still sent to the remote Kermit. Also try to close
;	any incomplete file whether deleting it or not (labels rdat16 and
;	rdat3a). If keeping incomplete files, try to write outstanding
;	buffers to disk, giving an error if the disk is full.
;edit 16, 23-Nov-1990 by MF. When receiving, cause the file being written
;	to disk to **always** be deleted and an "E" packet to be sent when a
;	"disk full" condition is encountered (per suggestion of
;	RJL@MONU1.CC.MONASH.EDU.AU).
;edit 15, 15-Nov-1990 by MF.  Changed code for the Receive Complete state
;	to always go into RECEIVE if AUTORECEIVE is on.  This will happen
;	most of the time anyway as most mainframe Kermits issue a prompt
;	after a single SEND command (wild-carded or not), thus guaranteeing
;	that the modem status check of Kermit-80 ver. 4.09 would **always**
;	have characters ready for input (the mainframe Kermit's prompt),
;	defeating the status check and the Console input check (originally
;	intended to drop the user out of the loop if he/she typed a key with
;	no comm input present).  Eliminate "any key" message there also.
;	the user can drop out by hitting ^C.
;	Of course, none of the foregoing applies if the Receive Complete
;	state occurs as the result of a "Get" command where Autoreceive
;	is meaningless and we just drop back to Kermit command-level.
;edit 14, 1-Oct-1990 by MF.  Added code to send an "I" packet before an
;	"R" packet in GET command.
;	Modified routine "sinit" to ignore "E" packets when sending an
;	"i" packet (per KPROTO.DOC).
;edit 13, 14-Sep-1990 by MF.  Added code to implement SET FILE COLLISION
;	and SET INCOMPLETE commands.
;edit 12, 9-Sep-1990 by MF.  Added code to prevent packet counts
;	from being displayed during Remote commands.  Fixed
;	AUTORECEIVE 	code, file colision Rename algorithm and eliminated
;	multiple display of initial messages during GET/RECEIVE.
; edit 11, 28 July, 1987 by OBSchou.  Commented out capas etc support
;	(Long packets etc) as this is not worth the effort coding... but
;	I have left what WAS done for any enthusiast.  Also set in a few
;	to NOT write to screen if SET TERMINAL QUIET set.  Hopefully speeds
;	up transfers on systems taking forever to update screens.
;
; edit 10, 8 April, 1987 by OBSchou.  Tarted up all sorts of bits n bobs
;	to cope with all the new aditions for Kermit-80 V 4.09
;	Look for the [10] for most cahnges.  spar and rpar largely replaced
;
; edit 9, March 30th by OBSchou.  Set bits for automatically receiving
;	another file if a remote sender sends files in seperate sessions.
;	The code simply checks the serial line, and if there is some
;	activity, assume its another SEND INIT packet.  As there is no
;	simple way to go to receive with the control-a, just ignore the
;	packet.  Causes one retry on the sender, but so what.  Really 
;	should make it a server gizzmo.
;
; edit 8: January 28, 1987 by OBSchou
;	Two major issues: firstly split CPSPKT.ASM into CPSPK(1 2).ASM
;	making it far easier to handle this file.
;	Second, some mode to the GET routines to correctly print the file
;	name instead of the fireworks.  Trouble was with GET <file> <file>
;	and RECEIVE <file>.  However, new bugs discovered...
;
; edit 7: August 11, 1986    Godfrey N. Nix [gnn] Nottingham University
;       To ignore echoed packets (ie send 'S' receive 'S' before 'A');
;       To allow character other than SOH for packet header (see also
;                       updates to CP4MIT and CP4UTL for other code needed);
;       To permit SEND and RECEIVE to specify a host filename which
;                       is of a different structure to that of CP/M.
;
; edit 6a: [OBSchou] 7 March, 1985.
;       Edited file with additions from MJ Carter.  He writes:
;       25th September 1985, M J Carter [majoc], Nottingham University
;       Code in gofil() amended, for exactly the same reasons to the 
;       alteration to cmifil() in cpscmd.asm.  If there is any deep
;       reason why gofil() has to be used instead of a call to comnd(cmofil), 
;       I can't see it.  The bug (on a British Micro Mimi 803) caused 
;       gofil() to overwrite existing files in GET and RECEIVE, even 
;       with file warning SET ON.
;
;edir 6: November 22, 1984
;       Change SEND's 'Unable to find file' error exit from calling
;       error3 to calling prtstr instead.  I don't know about you, but
;       I greatly dislike having messages dumped into pre-existing
;       junk on the screen where I have to spend lots of time hunting
;       for them.  [Hal Hostetler]
;
; edit 5: September 9, 1984
;       Call flsmdm in init to flush old input when starting transfers.
;       Select console before returning from inpkt.
;       Replace inline code with calls to makfil/clofil to set up for
;       multisector buffering on output.
;       Remove superfluous call to clrlin in error3.
;
; edit 4: August 21, 1984 (CJC)
;       Fix comment in inpkt: packet is terminated by NUL on return, not CR.
;       If debugging, display the outgoing packet before putting the EOL
;       character on, so the dumped packet doesn't get overwritten.
;
; edit 3: July 27, 1984
;       add link directive for LASM.  CP4PKT is linked by CP4MIT, and links
;       to CP4TT.  Add Toad Hall TACtrap to permit operations through a TAC.
;
; edit 2: June 8, 1984
;       formatting and documentation; remove some unused labels; move setpar
;       to cp4mit.m80; add module version string; make all arithmetic on
;       'pktnum' modulo 64; apply defaults correctly for missing parameters
;       in send-init packet (and corresponding ack).
;
; edit 1: May, 1984
;       extracted from CPMBASE.M80 version 3.9; modifications are described
;       in the accompanying .UPD file.
;
pk1ver:	db	'CPSPK1.ASM (23) 16-Jan-1991$'	; name, edit number, date

;       GET command   [gnn]
;       here from: kermit

read:	mvi	a,0ffh		;[obs 8] we are doing a get
	sta	getrxflg	;[obs 8] so set flag
	lxi	d,remdat	;Where to put the text (if any.)
	mvi	a,cmtxt
	call	comnd		;Get either some text or a confirm.
	jmp	kermt3		; Didn't get anything.
	ora	a		;Get any chars?
	jz	kermt3		;[gnn] GET must have a filename
	sta	rdl		;Store the number of chars.
	xchg			;Get pointer into HL.
	mvi	m,'$'		;Put in a dollar sign for printing.
	call	init		;Clear the line and initialize the buffers.
	lda	quietd		; quiet display?
	ana	a
	jz	read01		;[MF]No, go ahead and position cursor
	call	prcrlf		;[MF]Yes, keep from overwriting the prompt
	jmp	read00		;[MF]and write filename
read01:	call	scrfln		;Position cursor [MF]
read00:	lxi	d,remdat	;Print the file name, in either case
	call	prtstr
	jmp	read0a		;[gnn] go get local name if any


; enter here for RECEIVE command  [gnn]
read0:	mvi	a,0		;[gnn]
	sta	rdl		;[gnn][MF] flag entry as receive, not get
	sta	getrxflg	;[obs 8] doing a receive, so reset flag
	call	init		;clear line, initialise buffers
read0a:	lxi	d,remnam	;[gnn] save local name here
	mvi	a,cmtxt		;[gnn]
	call	comnd		;[gnn] read second filename if present
	jmp	kermt3		;[gnn]  error exit
	sta	remlen		;[gnn] save length of name, may be zero
	sta	getrxflg	;[obs 8] May also be receive <fnam> so 
				;[obs 8]pretend get for printing filename
	lda	rdl		;[gnn] look at first name
	ora	a		;[gnn] receive or get?
	jz	read1		;[gnn] receive

	mvi	a,'I'		;[MF]Set state to send "I" packet
	sta	state		;[MF]...

;       jmp     read12		;[obs] [gnn] does not want this

read1:	;call   init		;Clear the line and initialize the buffers.
read12:	xra	a
	sta	czseen		;Clear the ^X/^Z flag initially.
	lxi	h,0
	shld	numpkt		;Set the number of packets to zero.
	shld	numrtr		;Set the number of retries to zero.
	sta	pktnum		;Set the packet number to zero.
	sta	numtry		;Set the number of tries to zero.
	lda	quietd		; quiet display?
	ana	a
	jnz	read13		; yes, so dont write...
	call	scrnrt		;Position cursor
	lxi	h,0
	call	nout		;Write the number of retries.
read13:	lda	rdl		;[MF]Get or receive?
	ora	a		;[MF]...
	jnz	read2		;[MF]Get, don't reset state
	mvi	a,'R'
	sta	state		;Set the state to receive initiate.
	;...
;
;RECEIVE state table switcher.

read2:	lda	quietd		; noisy display?
	ana	a
	jnz	read21		; no, a quiet one
	lda	remtxt		;[MF] In Remote command?
	ora	a
	jnz	read21		;[MF] Yes, don't write to screen
	call	scrnp		;Position cursor
	lhld	numpkt
	call	nout		;Write the current packet number.
read21:	lda	state		;Get the state.
	cpi	'D'		;Are we in the DATA receive state?
	jnz	read22
	call	rdata
	jmp	read2

read22:	cpi	'X'		; F packet but not an F packet?
	jnz	read3		; nope, so try next one
	call	rfile		; 'get' the filename (but dont open it)
	jmp	read2

read3:	cpi	'F'		;Are we in the FILE receive state?
	jnz	read4
	call	rfile		;Call receive file.
	jmp	read2

read4:	cpi	'R'		;Are we in the Receive-Initiate state?
	jnz	read5
	call	rinit
	lda	state		;[jd] get new state
	cpi	'F'		;[jd] went into receive state?
	jnz	read2		;[jd] no
	lxi	d,inms24	;[jd] yes, get receiving... message
	call	finmes		;[jd] go print it
	jmp	read2

read5:	cpi	'C'		;Are we in the Receive-Complete state?
	jnz	read6
	lxi	d,infms3	;Put in "Complete" message.
	lda	czseen		;Or was it interrupted?
	ora	a		; .  .  .
	jz	read5a		;No.
	xra	a		;Yes, clear flag.
	sta	czseen		; ...
	lxi	d,inms13	;Issue "interrupted" message.
read5a:	lda	remtxt		;[MF] Doing a Remote command?
	ora	a
	cz	finmes		;Print completion message in right place if not
;
	lda	rdl		;[MF]Receive or Get?
	ora	a		;[MF]...
	jnz	kermit		;[MF]Get, Autoreceive means nothing.
	lda	autorc		; see if we want autoreceives
	ana	a
	jz	kermit		;[MF]No autoreceives, so drop out
	lxi	d,autmes	;[MF]Yes, tell the user what we're doing
	call	prtstr		;[MF]...
	jmp	read1		;[MF]Try another Receive (we get one
				;[MF]retry from the sender as the ^A is lost)

read6:	cpi	'Y'		;[MF]Simple ack (from remote command)?
	jz	kermit		;[MF]Yes

	cpi	'I'		;[MF]Exchanging parameters via info packet?
	jnz	read7		;[MF]No
	call	sinit		;[MF]Yes, send the packet
	lda	state		;[MF]Now see what happened
	cpi	'X'		;[MF]Did we exchange parameters successfully?
	jz	read6a		;[MF]Yes, go send the filespec
	cpi	'A'		;[MF]No, are we in abort state?
	jnz	read2		;[MF]No, try again
	jmp	kermit		;[MF]Yes, it's a real disaster, we must stop
read6a:	lda	rdl		;[MF]Get length of filespec
	sta	argblk+1	;[MF]as length of packet
	mov	c,a		;[MF]We must copy the filespec
	mvi	b,0		;[MF]...
	lxi	h,remdat	;[MF]from the temporary buffer
	lxi	d,data		;[MF]to the packet data area
	call	mover		;[MF]Do it.
; for GET we must send the name of the file we want [gnn]

	mvi	a,'1'		;Start with single character checksum
	sta	curchk		;Save the type
	xra	a		;Start a packet zero.
	sta	argblk
	mvi	a,'R'		;Receive init packet.
	call	spack		;Send the packet.
	jmp	kermt3		; Die!
	xra	a
	sta	czseen		;Clear the ^X/^Z flag initially.
	lxi	h,0
	shld	numpkt		;Set the number of packets to zero.
	sta	pktnum		;Set the packet number to zero.
	sta	numtry		;Set the number of tries to zero.
	mvi	a,'R'		;[MF]Set state to Receive-Initiate
	sta	state		;[MF]...
	jmp	read21		;[MF]and go around again
				;[MF]without retyping packet-number

read7:	cpi	'A'		;Are we in the Receive-"Abort" state?
	jnz	read8
read8:	lxi	d,infms4	;Anything else is equivalent to "abort".
	call	finmes
	jmp	kermit
;
;       Receive routines

;       Receive init
;       called by: read

rinit:	lda	numtry		;Get the number of tries.
	cpi	imxtry		;Have we reached the maximum number of tries?
	jm	rinit2
	lxi	d,ermes4
	call	error3		;Move cursor and print an error message.
	jmp	abort		;Change the state to abort.

rinit2:	inr	a		;Increment it.
	sta	numtry		;Save the updated number of tries.
	mvi	a,'1'		;Reset block check type to single character
	sta	curchk		;Store as current type for initialization
	call	rpack		;Get a packet.
	jmp	nak		; Trashed packet: nak, retry.
	cpi	'S'		;Is it a send initiate packet?
	jnz	rinit3		;If not see if its an error.
rini2a:	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	xra	a
	sta	numtry		;Reset the number of tries.
	lda	argblk		;Returned packet number.  (Synchronize them.)
	call	countp
	lda	argblk+1	;Get the number of arguments received.
	lxi	h,data		;Get a pointer to the data.
	call	spar		;Get the data into the proper variables.
	lxi	h,data		;Get a pointer to our data block.
	call	rpar		;Set up the receive parameters.
	sta	argblk+1	;Store the returned number of arguments.
	mvi	a,'Y'		;Acknowledge packet.
	call	spack		;Send the packet.
	jmp	abort		; Failed, abort.
	lda	inichk		;Now switch to agreed upon check-type
	sta	curchk		;For all future packets
	mvi	a,'F'		;Set the state to file send.
	sta	state
	ret

rinit3:	cpi	'E'		;Is it an error packet.
	jnz	nak0		;If not NAK whatever it is.
	call	error
	jmp	abort
;
;       Receive file
;       called by: read

rfile:	lda	numtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	rfile1
	lxi	d,ermes5
	call	error3		;Move cursor and print an error message.
	jmp	abort		;Change the state to abort.

rfile1:	inr	a		;Increment it.
	sta	numtry		;Save the updated number of tries.
	call	rpack		;Get a packet.
	jmp	nak		; Trashed packet: nak, retry.
	cpi	'S'		;Is it a send initiate packet?
	jnz	rfile2		; No, try next type.
	lda	oldtry		;Get the number of tries.
	cpi	imxtry		;Have we reached the maximum number of tries?
	jm	rfil12		;If not proceed.
	lxi	d,ermes4
	call	error3		;Move cursor and print an error message.
	jmp	abort		;Change the state to abort.

rfil12:	inr	a		;Increment it.
	sta	oldtry		;Save the updated number of tries.
	lda	pktnum		;Get the present packet number.
	dcr	a		;Decrement
	ani	3FH		; modulo 64
	mov	b,a
	lda	argblk		;Get the packet's number
	cmp	b		;Is the packet's number one less than now?
	jnz	nak0		;No, NAK and try again.
	call	updrtr		;Update the retry count.
	xra	a
	sta	numtry		;Reset the number of tries.
	lxi	h,data		;Get a pointer to our data block.
	call	rpar		;Set up the parameter information.
	sta	argblk+1	;Save the number of arguments.
	mvi	a,'Y'		;Acknowledge packet.
	call	spack		;Send the packet.
	jmp	abort		; Failed, abort.
	ret

rfile2:	cpi	'Z'		;Is it an EOF packet?
	jnz	rfile3		; No, try next type.
	lda	oldtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	rfil21		;If not proceed.
	lxi	d,ermes6
	call	error3		;Move cursor and print an error message.
	jmp	abort		;Change the state to abort.

rfil21:	call	tryagn
	ret

rfile3:	cpi	'F'		;Start of file?
	jnz	rfil3b
	mov	c,a		;[MF]Save packet type
	lda	remtxt		;[MF]Doing a remote server command?
	ora	a		;[MF]...
	mov	a,c		;[MF]Restore packet type
	jnz	rfil3d		;[MF]If yes, same as x packet
	call	compp
	jnz	nak0		;No, NAK it and try again.
	call	countp
	mov	c,a		;[MF]
	lda	remtxt		;[MF]Doing a remote command?
	ora	a		;[MF]...
	mov	a,c		;[MF]
	jnz	rfil3a		;[MF]Yes, don't open a file
	call	gofil		;Get a file to write to, and init output buffer.
	jmp	abort
rfil3a:	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	call	ackp
	mvi	a,'D'		;Set the state to data receive.
	sta	state
	lda	czseen		;Check if we punted a file
	cpi	'Z'		;and didn't want any more
	rz			;If that was the request, keep telling other end
	xra	a		;Otherwise, clear flag (^X is only for one file)
	sta	czseen		;And store the flag back
	ret

rfil3b:	cpi	'X'		;Start of 'file?' , but not a file?
	jnz	rfile4
rfil3d:	call	compp
	jnz	nak0		;No, NAK it and try again.
	call	countp

	call	selcon		;[MF]Select Console
	lda	argblk+1	; get length
	ora	a		;[MF]Anything to write?
	jz	rfil3e		;[MF]No
	push	psw		;[MF]Yes, save character count
	mvi	e,'<'		;[MF]Write "<<" as in VMSKermit
	push	d		;[MF]...
	call	outcon		;[MF]...
	pop	d		;[MF]...
	call	outcon		;[MF]...
	pop	psw		;[MF]Restore character count
	lxi	h,data		; lets write the filename (?) to display
rfil3f:	push	psw		;[MF]Save loop counter
	mov	e,m		;[MF]Get character to write
	inx	h		;[MF]and increment character pointer
	push	h		;[MF]Save the pointer
	call	outcon		;[MF]Write character to display
	pop	h		;[MF]Restore pointer
	pop	psw		;[MF]and loop counter
	dcr	a		;[MF]Decrement the counter
	jnz	rfil3f		;[MF]Display entire filename
	mvi	e,'>'		;[MF]Put in ">>" as in VMSKermit
	push	d		;[MF]...
	call	outcon		;[MF]...
	pop	d		;[MF]...
	call	outcon		;[MF]...
	call	prcrlf		;[MF]New line
rfil3e:	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	call	ackp
	mvi	a,'D'		; expecting a D packet
	sta	state
	lda	czseen		;Check if we punted a file
	cpi	'Z'		;and didn't want any more
	rz			;If that was the request, keep telling other end
	xra	a		;Otherwise, clear flag (^X is only for one file)
	sta	czseen		;And store the flag back
	ret

rfile4:	cpi	'B'		;End of transmission.
	jnz	rfile5
	call	compp
	jnz	nak0		;No, NAK it and try again.
	xra	a		;No data.  (Packet number already in argblk).
	sta	argblk+1
	mvi	a,'Y'		;Acknowledge packet.
	call	spack		;Send the packet.
	jmp	abort
	mvi	a,'C'		;Set the state to complete.
	sta	state
	ret

rfile5:	cpi	'E'		;Is it an error packet.
	jnz	abort
	call	error
	jmp	abort
;
;       Receive data
;       called by: read

rdata:	lda	numtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	rdata1
	lxi	d,erms10
	call	error3		;Display error message.
rdat16:	lda	remtxt		;[MF]Is a Remote command in progress?
	ora	a		;[MF]...
	jnz	abort		;[MF]Yes, don't worry about file disposition
	lda	incflg		;[MF]Are we keeping incomplete files?
	ora	a		;[MF]...
	jnz	rdat17		;[MF]Yes
	lxi	d,fcb		;[MF]No, close the file, ignoring errors
	push	d		;[MF]while protecting the pointer
	mvi	c,closf		;[MF]...
	call	bdos		;[MF]...
	pop	d		;[MF]Now delete the file, ignoring errors
	mvi	c,delf		;[MF]...
	call	bdos		;[MF]...
	jmp	abort		;Change the state to abort.
rdat17:	call	clofil		;[MF]Try to close the file, writing
				;[MF]outstanding buffers to disk
	jmp	rdat37		;[MF]We can't, the disk is full
	jmp	abort		;[MF]Change the state to "abort"

rdata1:	inr	a		;Increment it.
	sta	numtry		;Save the updated number of tries.
	call	rpack		;Get a packet.
	jmp	nak		; Trashed packet: nak, retry.
	cpi	'D'		;Is it a data packet?
	jnz	rdata2		; No, try next type.
	call	compp		;check for correct packet number (zero flag = ok)
	jz	rdat14		;its correct
	lda	oldtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	rdat12		;If not proceed.
	lxi	d,erms10
	call	error3		;Display err msg.
	jmp	rdat16		;[MF]Change the state to abort.

rdat12:	call	tryagn
	ret

rdat14:	call	countp
	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	lda	argblk+1	;Get the length of the data.
	call	ptchr
	jmp	rdat3b		;[MF] Unable to write out chars;abort.
	xra	a
	sta	numtry		;Reset the number of tries.
	sta	argblk+1	;No data.  (Packet number still in argblk.)
	mov	c,a		;Assume no data
	lda	czseen		;Check if control-X typed
	ora	a		; .  .  .
	jz	rdat15		;Zero if not typed
	mov	c,a		;Get the type of character typed
	mvi	a,1		;One data character
	sta	argblk+1	;Save the count
	mov	a,c		;Get the possible data character
	sta	data		;Store in data area
rdat15:	mvi	a,'Y'		;Acknowledge packet.
	call	spack		;Send the packet.
	jmp	rdat16		;[MF]
	ret

rdata2:	cpi	'F'		;Start of file?
	jnz	rdata3		; No, try next type.
	lda	oldtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	rdat21		;If not proceed.
	lxi	d,ermes5
	call	error3		;Display err msg.
	jmp	rdat16		;[MF]Change the state to abort.

rdat21:	call	tryagn
	ret

rdata3:	cpi	'Z'		;Is it a EOF packet?
	jnz	rdata4		;Try and see if its an error.
	call	compp
	jnz	nak0		;No, NAK it and try again.
	call	countp
	lda	argblk+1	;Get the data length
	cpi	1		;Have one item?
	jnz	rdat33		;If not, ignore data
	lda	data		;Yes, get the character
	cpi	'D'		;Is it a 'D' for discard?
	jz	rdat36		;If so, punt file
rdat33:	lda	remtxt		;[MF]Writing text to disk?
	ora	a		;[MF]...
	  jnz	rdat38		;[MF]No, don't close file
	call	clofil		;Finish off the file.
	jmp	rdat37		; Give up if the disk is full.
rdat38:	xra	a		;Since we kept the file,
	sta	czseen		;don't say it was discarded.
	lda	numtry		;Get the number of tries. [MF]
	sta	oldtry		;Save it. [MF]
	call	ackp		;[MF]
	jmp	rdat39		;[MF]and get ready to get more files
rdat36:	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	call	ackp
	lda	remtxt		;[MF]Is a Remote command in progress?
	ora	a		;[MF]...
	jnz	rdat39		;[MF]Yes, don't worry about file disposition
	lda	dscflg		;[MF]Is the file being punted because
	ora	a		;[MF]of a collision?
	jnz	rdat39		;[MF]Yes, don't delete the existing file
	lda	incflg		;[MF]No, are we keeping incomplete files?
	ora	a		;[MF]...
	jnz	rdat3a		;[MF]Yes
	lxi	d,fcb		;[MF]No, close the file,
	mvi	c,closf		;[MF]ignoring errors
	push	d		;[MF]...
	call	bdos		;[MF]...
	pop	d		;[MF]Now delete the file,
	mvi	c,delf		;[MF]ignoring errors
	call	bdos		;[MF]...
	jmp	rdat39		;[MF]and continue
rdat3a:	call	clofil		;[MF]Try to close the file, writing
				;[MF]outstanding buffers to disk
	jmp	rdat37		;[MF]Can't, disk is full
rdat39:	mvi	a,'F'
	sta	state
	ret

rdat37:	call	ptchr9		; Send "?Disk full" on the error line [MF]
				; and to the remote Kermit [MF]
rdat3b:	lda	remtxt		;[MF]Doing a Remote command?
	ora	a		;[MF]...
	jnz	abort		;[MF]Yes, just abort
	lxi	d,fcb		;[MF]Close the file, ignoring errors
	push	d		;[MF]Protect fcb pointer
	mvi	c,closf		;[MF]...
	call	bdos		;[MF]...
	pop	d		;[MF]Restore pointer
	lda	incflg		;[MF]Are we keeping incomplete files?
	ora	a		;[MF]...
	jnz	abort		;[MF]Yes, just abort transfer
	mvi	c,delf		;[MF]No, delete the file, ignoring errors
	call	bdos		;[MF]...
	jmp	abort		;[MF] abort transfer

rdata4:	cpi	'E'		;Is it an error packet.
	jnz	rdat16		;[MF]
	call	error
	jmp	rdat16		;[MF]
;
;       SEND command
;       here from: kermit

send:	mvi	a,cmifi		;Parse an input file spec.
	lxi	d,fcb		;Give the address for the FCB.
	call	comnd
	jmp	kermit		; Give up on bad parse.
;       section to get remote filename [gnn]
	lxi	d,remnam	;[gnn] where to put filename
	mvi	a,cmtxt		;[gnn] 
	call	comnd		;[gnn] get the text to end of the line
	jmp	kermt3		;[gnn] failure in reading buffer
	sta	remlen		;[gnn] save length (may be zero)
;
	xra	a
	sta	mfflg1		; clear flags...
	sta	mfflg2
	sta	mfflg3		;[gnn]
	sta	fcbcnt		;[gnn] clear fcbcount
	lxi	h,fcb0		;[gnn] and fcb pointer
	shld	xfcbptr
;
	call	mfname		;handle (multi) files
	jnc	send14		;got a valid file-name
	lxi	d,erms15
	call	prtstr		;Display error msg. ([hh] where it's visible)
	jmp	kermit

send14:	call	init		;Clear the line and initialize the buffers.
	xra	a
	sta	pktnum		;Set the packet number to zero.
	sta	numtry		;Set the number of tries to zero.
	sta	wrn8		;[jd] we haven't sent the 8-bit-lost warning
	lxi	h,0
	shld	numpkt		;Set the number of packets to zero.
	shld	numrtr		;Set the number of retries to zero.
	lda	quietd		; a quiet display?
	ana	a
	jnz	send15		; yup, dont write
	call	scrnrt		;Position cursor
	lxi	h,0
	call	nout		;Write the number of retries.
send15:	mvi	a,'1'		;Reset to use single character checksum
	sta	curchk		;For startup
	mvi	a,'S'
	sta	state		;Set the state to receive initiate.
	;...
;
;SEND state table switcher

send2:	lda	quietd		; a quiet display?
	ana	a
	jnz	send21		; yes, so dont write
	call	scrnp		;Position cursor
	lhld	numpkt
	call	nout		;Write the packet number.
send21:	lda	state		;Get the state.
	cpi	'D'		;Are we in the data send state?
	jnz	send3
	call	sdata
	jmp	send2

send3:	cpi	'F'		;Are we in the file send state?
	jnz	send4
	call	sfile		;Call send file.
	jmp	send2

send4:	cpi	'Z'		;Are we in the EOF state?
	jnz	send5
	call	seof
	jmp	send2

send5:	cpi	'S'		;Are we in the send initiate state?
	jnz	send6
	call	sinit
	lda	state		;[jd] get state back
	cpi	'F'		;[jd] into file send state yet?
	jnz	send2		;[jd] no
	lxi	d,inms23	;[jd] yes, print sending...
	call	finmes		;[jd] 
	jmp	send2

send6:	cpi	'B'		;Are we in the eot state?
	jnz	send7
	call	seot
	jmp	send2

send7:	cpi	'C'		;Are we in the send complete state?
	jnz	send8		;No...
	lxi	d,infms3	;Yes, write "Complete" message.
	lda	czseen		;Or was it interrupted?
	ora	a		; .  .  .
	jz	send7a		;No.
	lxi	d,inms13	;Yes, then say "Interrupted" instead.
send7a:	call	finmes
	jmp	kermit

send8:	cpi	'A'		;Are we in the send "abort" state?
	jnz	send9
	lxi	d,infms4	;Print  message.
	call	finmes
	jmp	kermit

send9:	lxi	d,infms4	;Anything else is equivalent to "abort".
	call	finmes
	jmp	kermit
;
;       Send routines

;       Send initiate
;       called by: send

sinit:	lda	numtry		;Get the number of tries.
	cpi	imxtry		;Have we reached the maximum number of tries?
	jm	sinit2
	lxi	d,erms14
	call	error3		;Display ermsg
	jmp	abort		;Change the state to abort.

sinit2:	inr	a		;Increment it.
	sta	numtry		;Save the updated number of tries.
	mvi	a,'1'		;Reset to use single character checksum
	sta	curchk		;For startup
	lda	chktyp		;Get our desired block check type
	sta	inichk		;Store so we tell other end
	lxi	h,data		;Get a pointer to our data block.
	call	rpar		;Set up the parameter information.
	sta	argblk+1	;Save the number of arguments.
	lda	numpkt		;Get the packet number.
	sta	argblk
	lda	state		; load state (I or S)

	call	spack		;Send the packet.
	jmp	abort		; Failed, abort.
	call	rpack		;Get a packet.
	jmp	r		; Trashed packet don't change state, retry.
	cpi	'Y'		;ACK?
	jnz	sinit3		;If not try next.
	call	compp		;compare packets. If ok, zero flag set
	rnz			;If not try again.
	call	countp		;increment packet number modulo 64
	lda	argblk+1	;Get the number of pieces of data.
	lxi	h,data		;Pointer to the data.
	call	spar		;Read in the data. (decode what they want)
	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	xra	a
	sta	numtry		;Reset the number of tries.
	lda	state		; se if S or I state
	cpi	'I'		; I state, so set X as next state
	jnz	sinita
sinitb:	mvi	a,'X'
	sta	state
	ret

sinita:	lda	inichk		;Get the agreed upon block check type
	sta	curchk		;Store as type to use for packets now
	mvi	a,'F'		;Set the state to file send. (Assumed)
	sta	state
	call	getfil		;Open the file.
	ret			; assume success; mfname thinks the file exists.

sinit3:	cpi	'N'		;NAK?
	jnz	sinit4		;If not see if its an error.
	call	updrtr		;Update the number of retries.
	lda	pktnum		;Get the present packet number.
	inr	a		;Increment
	ani	3FH		; modulo 64
	mov	b,a
	lda	argblk		;Get the packet's number.
	cmp	b		;Is the packet's number one more than now?
	rnz			;If not assume its for this packet, go again.
	xra	a
	sta	numtry		;Reset number of tries.
	mvi	a,'F'		;Set the state to file send.
	sta	state
	ret

sinit4:	cpi	'E'		;Is it an error packet.
	jnz	abort
	lda	state		;[MF]Get state
	cpi	'I'		;[MF]If an "I" packet was sent,
	jz	sinitb		;[MF]Ignore the error, pretend success
	call	error		;[MF]else display the error info
	jmp	abort		;[MF]and abort
;
;       Send file header
;       called by: send
;[5a] Question [majoc]: Why could not the filename
;     parsing have been done by comnd, like all the rest?

sfile:	lda	numtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	sfile1
	lxi	d,erms14
	call	error3
	jmp	abort		;Change the state to abort.

sfile1:	inr	a		;Increment it.
	sta	numtry		;Save the updated number of tries.
	xra	a		;Clear A
	sta	czseen		;No control-Z or X seen
	lxi	h,data		;Get a pointer to our data block.
	shld	datptr		;Save it.
; use remote name if given, else use local name [gnn]
	lda	remlen		;[gnn] anything given?
	ora	a		;[gnn] 
	jnz	sfile4		;[gnn] use remote name

	lxi	h,fcb+1		;Pointer to the file name in the FCB.
	shld	fcbptr		;Save position in FCB.
	mvi	b,0		;No chars yet.
	mvi	c,0
sfil11:	mov	a,b
	cpi	8H		;Is this the ninth char?
	jnz	sfil12		;If not proceed.
	mvi	a,'.'		;Get a dot.
	lhld	datptr
	mov	m,a		;Put the char in the data packet.
	inx	h
	shld	datptr		;Save position in data packet.
	inr	c
sfil12:	inr	b		;Increment the count.
	mov	a,b
	cpi	0CH		;Twelve? 
	jp	sfil13
	lhld	fcbptr
	mov	a,m
	ani	7fH		;Turn off CP/M 2 or 3's high bits.
	inx	h
	shld	fcbptr		;Save position in FCB.
	cpi	'!'		;Is it a good character?
	jm	sfil11		;If not get the next.
	lhld	datptr
	mov	m,a		;Put the char in the data packet.
	inx	h
	shld	datptr		;Save position in data packet.
	inr	c
	jmp	sfil11		;Get another.

sfil13:	mov	a,c		;Number of char in file name.
	sta	argblk+1
	lhld	datptr
	mvi	a,'$'
	mov	m,a		;Put in a dollar sign for printing.
	lda	quietd		; a quiet display
	ana	a
	jnz	sfi13a		; yes, dont write
	call	scrfln		;Position cursor
sfi13a:	lxi	d,data		;Print the file name though, in either case
	call	prtstr
	lda	pktnum		;Get the packet number.
	sta	argblk
	mvi	a,'F'		;File header packet.
	call	spack		;Send the packet.
	jmp	abort		; Failed, abort.
	call	rpack		;Get a packet.
	jmp	r		; Trashed packet don't change state, retry.
	cpi	'Y'		;ACK?
	jnz	sfile2		;If not try next.
	call	compp
	rnz			;If not hold out for the right one.
sfil14:	call	countp
	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	xra	a
	sta	numtry		;Reset the number of tries.
	sta	bytes		;[10] clear the "bytes transferred" counter
	sta	bytes+1		;[10]
	sta	bytes+2		;[10]
	sta	bytes+3		;[10]
	call	gtchr		;Fill the first data packet
	jmp	sfil16		;Error go see if its EOF.
;                              	;Got the chars, proceed.
	sta	size		;Save the size of the data gotten.
	mvi	a,'D'		;Set the state to data send.
	sta	state
	ret

sfil16:	cpi	0FFH		;Is it EOF?
	jnz	abort		;If not give up.
	mvi	a,'Z'		;Set the state to EOF.
	sta	state
	ret

sfile2:	cpi	'N'		;NAK?
	jnz	sfile3		;Try if error packet.
	call	updrtr		;Update the number of retries.
	lda	pktnum		;Get the present packet number.
	inr	a		;Increment
	ani	3FH		; modulo 64
	mov	b,a
	lda	argblk		;Get the packet's number.
	cmp	b		;Is the packet's number one more than now?
	rnz			;If not go try again.
	jmp	sfil14		;Just as good as a ACK;go to the ACK code.

sfile3:	cpi	'E'		;Is it an error packet.
	jnz	abort
	call	error
	jmp	abort

; copy remote name into packet to send [gnn]
sfile4:	xchg			;[gnn] keep pointer to packet
	lxi	h,remnam	;[gnn] set pointer to name
	mov	c,a		;[gnn] keep count of length
	mov	b,a		;[gnn] and set as loop counter
sfil41:	mov	a,m		;[gnn] get a character
	stax	d		;[gnn] copy it to packet
	inx	h		;[gnn] 
	inx	d		;[gnn] move pointers
	dcr	b		;[gnn] 
	mov	a,b		;[gnn] 
	ora	a		;[gnn] done them all?
	jnz	sfil41		;[gnn] repeat until done
	xchg			;[gnn] get final position
	shld	datptr		;[gnn] and save it
	jmp	sfil13		;[gnn] now go and send packet

;
;       Send data
;       called by: send

sdata:	lda	numtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	sdata1
	lxi	d,erms14
	call	error3
	jmp	abort		;Change the state to abort.

sdata1:	inr	a		;Increment it.
	sta	numtry		;Save the updated number of tries.
	lxi	h, data		;Get a pointer to our data block.
	shld	datptr		;Save it.
	lxi	h,filbuf	;Pointer to chars to be sent.
	shld	cbfptr		;Save position in char buffer.
	mvi	b,1		;First char.
sdat11:	lhld	cbfptr
	mov	a,m
	inx	h
	shld	cbfptr		;Save position in char buffer.
	mov	c,a		;[jd] preserve character temporarily
	lda	quot8		;[jd] doing eighth-bit quoting?
	ora	a		;[jd] 
	mov	a,c		;[jd] restore char
	jnz	sdat4		;[jd] using eighth-bit quoting, no warning
	lda	parity		;[jd] get parity
	cpi	parnon		;[jd] none?
	mov	a,c		;[jd] restore character
	jz	sdat4		;[jd] no parity, leave char alone
	lda	wrn8		;[jd] look at warning flag
	ora	a		;[jd] have we already given the warning?
	jnz	sdat5		;[jd] yes, skip this
	mov	a,c		;[jd] restore character...
	ani	80h		;[jd] examine parity
	jz	sdat5		;[jd] no parity, no warning.
	call	parwrn		;[jd] ...print warning - parity lost
	mvi	a,0ffh		;[jd] remember that we sent the message
	sta	wrn8		;[jd]
sdat5:	mov	a,c		;[jd] restore character again
	ani	7fh		;[jd] strip parity so not checksummed
sdat4:	lhld	datptr
	mov	m,a		;Put the char in the data packet.
	inx	h
	shld	datptr		;Save position in data packet.
	inr	b		;Increment the count.
	lda	size		;Get the number of chars in char buffer.
	cmp	b		;Have we transfered that many?
	jp	sdat11		;If not get another.
	lda	size		;Number of char in char buffer.
	sta	argblk+1
	lda	pktnum		;Get the packet number.
	sta	argblk
	mvi	a,'D'		;Data packet.
	call	spack		;Send the packet.
	jmp	abort		; Failed, abort.
	call	rpack		;Get a packet.
	jmp	r		; Trashed packet don't change state, retry.
	cpi	'Y'		;ACK?
	jnz	sdata2		;If not try next.
	call	compp
	rnz			;If not hold out for the right one.
	lda	argblk		;Get the packet number back
	call	countp
	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	xra	a
	sta	numtry		;Reset the number of tries.
	lda	argblk+1	;Get the data length
	cpi	1		;Check if only 1 character?
	jnz	sdat15		;If not, just continue
	lda	data		;Got one character, get it from data
	cpi	'Z'		;Want to abort entire stream?
	jnz	sdat14		;If not, check for just this file
	sta	czseen		;Yes, remember it
	jmp	sdat16		;[MF] and set EOF state
sdat14:	cpi	'X'		;Desire abort of current file?
	jnz	sdat15		;If not, just continue
	sta	czseen		;Yes, remember that
	jmp	sdat16		;[MF] and set EOF
sdat15:	lda	czseen		;Also get control-Z flag
	ora	a		;Check if either given
	jz	sdat12		;If neither given, continue
sdat16:	mvi	a,'Z'		;Change state to EOF
	sta	state		; .  .  .
	ret			;And return

sdat12:	call	gtchr
	jmp	sdat13		;Error go see if its EOF.
	sta	size		;Save the size of the data gotten.
	ret

sdat13:	cpi	0FFH		;Is it EOF?
	jnz	abort		;If not give up.
	mvi	a,'Z'		;Set the state to EOF.
	sta	state
	ret

sdata2:	cpi	'N'		;NAK?
	jnz	sdata3		;See if is an error packet.
	call	updrtr		;Update the number of retries.
	lda	pktnum		;Get the present packet number.
	inr	a		;Increment
	ani	3FH		; modulo 64
	mov	b,a
	lda	argblk		;Get the packet's number.
	cmp	b		;Is the packet's number one more than now?
	rnz			;If not go try again.
	jmp	sdat12		;Just as good as a ACK;go to the ACK code.

sdata3:	cpi	'E'		;Is it an error packet.
	jnz	abort
	call	error
	jmp	abort
;
;       Send EOF
;       called by: send

seof:	lda	numtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	seof1
	lxi	d,erms14
	call	error3
	jmp	abort		;Change the state to abort.

seof1:	inr	a		;Increment it.
	sta	numtry		;Save the updated number of tries.
	lda	pktnum		;Get the packet number.
	sta	argblk
	xra	a
	sta	argblk+1	;No data.
	lda	czseen		;Check if C-Z or C-X typed
	ora	a		; .  .  .
	jz	seof14		;If not aborted, just keep going
	mvi	a,'D'		;Tell other end to discard packet
	sta	data		;Store in data portion
	mvi	a,1		;One character
	sta	argblk+1	;Store the length
seof14:	mvi	a,'Z'		;EOF packet.
	call	spack		;Send the packet.
	jmp	abort		; Failed, abort.
	call	rpack		;Get a packet.
	jmp	r		; Trashed packet don't change state, retry.
	cpi	'Y'		;ACK?
	jnz	seof2		;If not try next.
	call	compp
	rnz			;If not hold out for the right one.
seof12:	call	countp
	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	xra	a
	sta	numtry		;Reset the number of tries.
	mvi	c,closf		;Close the file.
	lxi	d,fcb
	call	bdos
;* Check if successful
	lda	czseen		;Desire abort of entire stream?
	cpi	'Z'		;Desire abort of entire stream?
	jz	seof13		;If so, just give up now
	call	mfname		;Get the next file.
	jc	seof13		; No more.
	call	getfil		;and open it (assume success)
	xra	a		;Clear A
	sta	czseen		;Since we have not aborted this file
	mvi	a,'F'		;Set the state to file send.
	sta	state
	ret

seof13:	mvi	a,'B'		;Set the state to EOT.
	sta	state
	ret

seof2:	cpi	'N'		;NAK?
	jnz	seof3		;Try and see if its an error packet.
	call	updrtr		;Update the number of retries.
	lda	pktnum		;Get the present packet number.
	inr	a		;Increment
	ani	3FH		; modulo 64
	mov	b,a
	lda	argblk		;Get the packet's number.
	cmp	b		;Is the packet's number one more than now?
	rnz			;If not go try again.
	jmp	seof12		;Just as good as a ACK;go to the ACK code.

seof3:	cpi	'E'		;Is it an error packet.
	jnz	abort
	call	error
	jmp	abort
;
;       Send EOT
;       called by: send

seot:	lda	numtry		;Get the number of tries.
	cpi	maxtry		;Have we reached the maximum number of tries?
	jm	seot1
	lxi	d,erms14
	call	error3
	jmp	abort		;Change the state to abort.

seot1:	inr	a		;Increment it.
	sta	numtry		;Save the updated number of tries.
	lda	pktnum		;Get the packet number.
	sta	argblk
	xra	a
	sta	argblk+1	;No data.
	mvi	a,'B'		;EOF packet.
	call	spack		;Send the packet.
	jmp	abort		; Failed, abort.
	call	rpack		;Get a packet.
	jmp	r		; Trashed packet don't change state, retry.
	cpi	'Y'		;ACK?
	jnz	seot2		;If not try next.
	call	compp
	rnz			;If not hold out for the right one.
seot12:	call	countp
	lda	numtry		;Get the number of tries.
	sta	oldtry		;Save it.
	xra	a
	sta	numtry		;Reset the number of tries.
	mvi	a,'C'		;Set the state to file send.
	sta	state
	ret

seot2:	cpi	'N'		;NAK?
	jnz	seot3		;Is it error.
	call	updrtr		;Update the number of retries.
	lda	pktnum		;Get the present packet number.
	inr	a		;Increment
	ani	3FH		; modulo 64
	mov	b,a
	lda	argblk		;Get the packet's number.
	cmp	b		;Is the packet's number one more than now?
	rnz			;If not go try again.
	jmp	seot12		;Just as good as a ACK;go to the ACK code.

seot3:	cpi	'E'		;Is it an error packet.
	jnz	abort
	call	error
	jmp	abort
;
;       This routine sets up the data for init packet (either the
;       Send_init or ACK packet).
;       called by: rinit, rfile, sinit
;
; Called by rinit, rfile and sinit.  See what WE want from the other fella
;
; [11] by OBS - Stripped out all the new capas code etc and reverted
;	to Good Ol' Basic Kermit again!
;	Those keen should study the followin gode with care, and remove
;	or add semicolons as indicated.
;
; See also SPAR which decodes what comes in.  It also decodes bits in 
;	the "capability" fields.  (Two CAPAS files allowed from remote
;	machines, but we will only send one at max.)  Note that not all 
;	if any of the capability bits will be used.
;
; Definitions - init packet (data section only.. rest of header assumed OK)
;	Byte 0	Maximum length I want to send
;	     1	The Timeout I want you to use
;	     2	Number of PAD characters I want tot use (May be null)
;	     3	The PAD character I want to use (May be Null)
;	     4	The End-of-Line character I will use (Carriage Return)
;	     5	The control character Quote Character I will use (#)
;	     6	The parity bit Quote Character I will use (&)
;	     7	The Checktype I will use
;	     8	The repeat prefix I will use (Null, as we cannot to repeats)
;	     9	Capability Byte 0 (See SPAR for defs)
;	    10	Capability byte 1 ( --- " --- but we will not send it.)
;	    11	The number of packets I will send per window (not used)
;	    12  MAXL1 - Long packet size, ms count
;	    13	MAXL2 - Long packet size, ls count
;
;
; Enter with HL pointing to the "data" part of the packet.

;
; older part of rpar follows...
;
;
rpar:	lda	rpsiz		;Get the receive packet size.
	adi	space		;Add a space to make it printable.
	mov	m,a		;Put it in the packet.
	inx	h		;Point to the next char.
	lda	rtime		;Get the receive packet time out.
	adi	space		;Add a space.
	mov	m,a		;Put it in the packet.
	inx	h
	lda	rpad		;Get the number of padding chars.
	adi	space
	mov	m,a
	inx	h
	lda	rpadch		;Get the padding char.
	adi	100O		;Uncontrol it.
	ani	7FH
	mov	m,a
	inx	h
	lda	reol		;Get the EOL char.
	adi	space
	mov	m,a
	inx	h
	lda	rquote		;Get the quote char.
	mov	m,a
	inx	h
	mvi	m,'Y'		;[jd] we know how to do 8-bit quoting
	lda	parity		;[jd]
	cpi	parnon		;[jd] parity none?
	jz	rpar1		;[jd] yes, keep going
	lda	qbchr		;[jd] no, better request 8-bit quoting
	mov	m,a

rpar1:
	inx	h		;Advance to next
	lda	chktyp		;Get desired block check type
	mov	m,a		;Store it
	inx	h		;Advance pointer

; Comment out the next two lines for capas etc.  WILL require debugging
	mvi	a,8		; this id the older end for this routine.  May be useful.
	ret

; [11] Rest not needed for now, commented out
; [10] (to ret)
; New additions to rpar follows...

;	lda	rcap1		; get the first capability byte
;	ani	3eh		; mask out bit 0, ie only one CAPAS byte
;	adi	space		; tochar it
;	mov	m,a
;	inx	h
;	mvi	m,space		; No windows, ie space to packet
;	inx	h
;	push	h		; we need the HL regs for maths.
;	lhld	rdpkt		; get receive packet length
;	lxi	d,95		; we want hl div 95 and hl mod 95
;	call	divide		; return with divsion in hl, remainder in de
;	mov	a,l		; two sets of bytes
;	pop	h
;	adi	space		; tochar(maxl1)
;	mov	m,a
;	inx	h
;	mov	a,l
;	adi	space		; tochar(maxl2)
;	mov	m,a
;
; done all, set databytes = 12 and return
;	mvi	a,12		; 12 bits of data
;	ret

;[11] End of commented out code for rpar


;
;       This routine reads in all the send_init packet information.
;       called by: rinit, sinit

;[11] As for rpar, restore the "old" kermit code for non-capas Kermit.
;[10] (to ret at end)
;
; SPAR - routine to decode parameters received from the remote end
;
;	Called by rinit,sinit
;
;	Entry:	a: Number of databytes in packet
;		hl: Pointer to "data" part of packet
;
;spar:	sta	temp4		; save for a while
;				; first clear some variables
;	lda	dspsiz		; get default "send" packet length
;	sta	spktl
;	lda	dstime		; get default time-out
;	sta	stimeo
;	xra	a		; set no pad characters by default
;	sta	spad
;	lda	dspadc		; get the default padding character
;	sta	spadc
;	mvi	a,cr		; default end of line character (CR)
;	sta	seol
;	mvi	a,dsquot	; default quote character
;	sta	squote
;	mvi	a,dsbqut	; default binary quote character
;	sta	qbchr
;	mvi	a,dschkt	; set checktype = 1 for inits
;	sta	inichk
;	mvi	a,space		; no repeat prefixing ( otherwise ~)
;	sta	srept
;
; Now follows the "capabilities" bits... 5 bits per capas byte.
;
; 	Note: Before extracting any data bits, apply unchar() to get the 
;	six ls bits.  If bit 0 = 1 the a subsequent capaa byte follows
;
;	Byte0:	Bit 0:	Set to 1 if there are subsequent CAPAS bytes
;		    1:	(Cap. 5) Set to 1 for long packets.  Second byte
;			AFTER the last capas byte has packet length DIV 95
;			and Thire byte has length MOD 95
;		    2:	(Cap. 4) Sliding Windows.  If used, first byte AFTER
;			last capas byte has TOCHAR(no. of packets in window)
;		    3:	(Cap. 3) Ability to accept "A" (attribute packets)
;		    4:	(Cap. 2) Reserved
;		    5:	(Cap. 1) Reserved
;	Byte 2 onward: not used in this implementation. Any capas bytes sent 
;		will be stored, however.
;
;	lda	temp4		; get the number of bytes to test
;	mov	c,a		; to a count register
;	mov	a,m		; get first byte
;	call	decc		; unchar it, and decrement c
;	sta	spsiz		; save a send packet size
;	jz	sparx		; if no more, exit
;
;	mov	a,m		; get timout
;	call	decc
;	sta	stime		; save timeout
;	jz	sparx
;
;	mov	a,m		; get pad characters
;	call	decc	
;	sta	spadc		; save it
;	jz	sparx
;
;	mov	a,m		; get pad character count
;	call	decc
;	sta	spad
;	jz	sparx
;
;	mov	a,m		; get send EOL
;	call	decc
;	sta	seol
;	jz	sparx
;
;	mov	a,m		; get control quote character
;	call	decc
;	sta	squote
;	jz	sparx
;
;	mov	a,m		; get binary (parity) quote char
;	mov	b,a		; this time we actually WANT accumulator
;	cpi	space		; are we doing 8th bit quoteing
;	jz	spar1		; dont know, assume not
;	cpi	'N'		; definately not?
;	jz	spar1
;	cpi	'Y'		; definately - use &
;	jz	spar2
;	sta	squote		; else save the new character
;spar2:	lda	parity		; see if we are using the parity bit
;	cpi	parnon		; no parity => no quoting
;	jz	spar3		; yup, so use the default quote character &
;
;spar1:	xra	a		; save not quoting
;	sta	squote
;spar3:	call	decc		; update counters etc
;	jz	sparx
;
;	mov	a,m		; get repeat prefixing
;	call	decc
;	push	psw		; save flags
;	cpi	space-32	; we want it?
;	jz	spar4
;	sta	srept
;spar4:	pop	psw		; restore flags
;	jz	sparx
;
;	lxi	d,scapas	; point to start of capability byte(s)
;	push	psw		; must do this...
;spar5:	pop	psw		; cos we restore the spack
;	mov	a,m
;	call	decc		; get scap1 (or n)
;	sta	scap1
;	push	psw
;	ani	01		; another byte following?
;	jnz	spar5
;	pop	psw		; see if any other data bytes (Windows etc)
;	jz	sparx
;
;	mov	a,m		; get window size
;	call	decc
;	sta	swindo
;	jz	sparx
;
;	mov	a,m		; get long packets ms bits
;	call	decc		;
;	mov	d,a		; unchared ms bits-ish
;	mov	a,m
;	call	decc		; ls bits-ish
;	push	h		; and we are doing maths
;	push	b		; and an intermediate result in c
;	push	psw		; we want flags  and the ls bits...
;	mvi	b,0
;	mov	c,d		; get ms bits-ish to bc
;	push	b		; get number to hl
;	pop	h
; now multipy by 95
;	dad	h		;*2
;	dad	h		;*4
;	dad	h		;*8
;	dad	h		;*16
;	push	h		; *16 to ...
;	pop	d		; ... de
;	dad	h		;*32
;	dad	d		; *(32+16) = *48
;	dad	h		; *96
;	mov	a,l		; *(96-1)
;	sub	c
;	mov	l,a
;	mov	a,0
;	sbb	h
;	mov	h,a
;	pop	psw		; restore ls bitsish
;	mov	e,a
;	mvi	d,0
;	dad	d		; *95 + ls bits. Phew.
;	shld	sdpkt		; save long packet length
;	pop	b
;	pop	h		; restore regs
;
;sparx:	ret			; if here, (assume) no more data to read in
;[10] routines required follow
;decc:	mov	a,m		; get data byte
;	sui	space		; unchar it
;	inx	h		; increment input pointer
;	dcr	c		; decrement data counter
;	ret			; return
;[10] end or spar replacement

;[11] Restore older spar....
; Older spar follows...
spar:	sta	temp4		;Save the number of arguments.
; Initialize some variables to their required default values, so we use
; the right values even if the remote Kermit doesn't send the full packet:
;                              	; we don't do anything with timeout values yet.
;                              	; no default pad count/pad character?
	mvi	a,cr		; EOL character = carriage-return
	sta	seol
	mvi	a,'#'		; quote character = '#'
	sta	squote
	mvi	a,'&'		; eighth-bit quote character = '&'
	sta	qbchr
	mvi	a,'1'		; block-check = 1-character-checksum
	sta	inichk
; 
	mov	a,m		;Get the max packet size.
	sbi	space		;Subtract a space.
	sta	spsiz		;Save it.
	lda	temp4
	cpi	3		;Fewer than three pieces?
	rm			;If so we are done.
	inx	h
	inx	h		;Increment past the time out info.
	mov	a,m		;Get the number of padding chars.
	sbi	space
	sta	spad
	lda	temp4
	cpi	4		;Fewer than four pieces?
	rm			;If so we are done.
	inx	h
	mov	a,m		;Get the padding char.
	adi	100O		;Re-controlify it.
	ani	7FH
	sta	spadch
	lda	temp4
	cpi	5		;Fewer than five pieces?
	rm			;If so we are done.
	inx	h
	mov	a,m		;Get the EOL char.
	sbi	space
	sta	seol
	lda	temp4
	cpi	6		;Fewer than six pieces?
	rm			;If so we are done.
	inx	h
	mov	a,m		;Get the quote char.
	sta	squote
	lda	temp4		;Get the amount of data supplied
	cpi	7		;Have an 8-bit quote?
	rm			;If not there, all done
	inx	h		;Yes, get the character
	mvi	a,0		;[jd] 
	sta	quot8		;[jd] assume not quoting
	mov	a,m		;Get the supplied character
	cpi	'N'		;[jd] No?
	jz	spar1		;[jd] then don't try to do it
	cpi	space		;[jd] maybe they don't know about it...
	jz	spar1		;[jd] then don't try to do it.
	cpi	'Y'		;[jd] Yes?
	jnz	spar2		;[jd] if not 'Y', assume it's a quote char.
	lda	parity		;[jd] using parity?
	cpi	parnon		;[jd] no, don't need quoting...
	jz	spar1		;[jd] 
	mvi	a,0ffh		;[jd] else turn on...
	sta	quot8		;[jd] ...quote flag
	jmp	spar1

;[11] Note: If capas etc required, beware of the next two lables, as these 
; are used elswhere.

spar2:	sta	qbchr		;[jd] use their quote char (should validate)
	mvi	a,0ffh
	sta	quot8		;[jd] turn quote flag and fall thru...

spar1:	lda	temp4		;Determine if block check type given
	cpi	8		;Is the field there?
	rm			;If not, all done
	inx	h		;Point to the character
	mov	a,m		;Get the value
	mov	b,a		;Copy value
	lda	chktyp		;Get our type
	cmp	b		;Is it our desired type?
	rnz			; If not, use default (1-character-checksum)
	sta	inichk		; Match, store as type to use after init
	ret			; and return
;[10] end of replacement
;[11] end of replacement of replacement (ie back to original code)
;

;       Copy characters from packet to disk (or screen)
;       called by: rdata

ptchr:	sta	temp1		;Save the size.
	lda	remtxt		;[MF]Get remote command flag
	ora	a		;[MF]Remote command in progress?
	jnz	ptchr0		;[MF]Yes, don't check for file collisions
	lda	flwflg		;[MF]Get File Warning (Set Collision) flag
	cpi	3		;[MF]SET COLLISION DISCARD?
	jnz	ptchr0		;[MF]No
	lda	dscflg		;[MF]Yes, get "discard" flag
	ora	a		;[MF]Discarding file?
	jz	ptchr0		;[MF]No
	mvi	a,'X'		;[MF]Yes, simulate a user rejection
	sta	czseen		;[MF]...
	jmp	rskp		;[MF]and pretend success
ptchr0:				;[MF]
	lxi	h,data		;Beginning of received packet data.
	shld	outpnt		;Remember where we are.
	lda	rquote
	mov	b,a		;Keep the quote char in b.
	mvi	c,0		;[jd] assume no 8-bit quote char
	lda	quot8		;[jd] doing 8-bit quoting?
	ora	a
	jz	ptchr1		;[jd] no, keep going
	lda	qbchr		;[jd] else get 8-bit quote char
	mov	c,a		;[jd] keep this in c
ptchr1:	lxi	h,temp1
	dcr	m		;Decrement # of chars in packet.
	jm	rskp		;Return successfully if done.
	lda	remtxt		; to screen only?
	ana	a
	jnz	ptchr2		; dont do any disk stuff
	lxi	h,chrcnt	;Number of chars remaining in dma.
	dcr	m		;Decrement.
	jp	ptchr2		;Continue if space left.
	call	outbuf		;Output it if full.
	jmp	ptchr9		; Error return if disk is full.
ptchr2:	lhld	outpnt		;Get position in output buffer.
	mov	a,m		;Grab a char.
	inx	h
	shld	outpnt		;and bump pointer.
	mvi	e,0		;[jd] assume nothing to OR in.
	cmp	c		;[jd] is it the binary quote char?
	jnz	ptch2a		;[jd] no, keep going
	mvi	e,80h		;[jd] include parity bit
	lda	temp1
	dcr	a
	sta	temp1		;[jd] decrement character count
	mov	a,m		;[jd] get next character
	inx	h
	shld	outpnt
ptch2a:	cmp	b		;Is it the quote char?
	jnz	ptchr3		;[jd] changed to ptchr3 so includes parity
	mov	a,m		;Get the quoted character
	inx	h
	shld	outpnt		;and bump pointer.
	lxi	h,temp1
	dcr	m		;Decrement # of chars in packet.
	mov	d,a		;Save the char.
	ani	80H		;Turn off all but the parity bit.
	ora	e		;[jd] let parity come from either (???)
	mov	e,a		;Save the parity bit.
	mov	a,d		;Get the char.
	ani	7FH		;Turn off the parity bit.
	cmp	b		;Is it the quote char?
	jz	ptchr3		;If so just go write it out.
	cmp	c		;[jd] maybe it's the 8-bit prefix character?
	jz	ptchr3		;[jd] then don't controllify.
	mov	a,d		;Get the char.
	adi	40H		;Make the character a control char again.
	ani	7FH		;Modulo 128.
ptchr3:	ora	e		;Or in the parity bit.
	sta	temp3		; save for a while
	lda	remtxt		; to screen or disk?
	ana	a
	lda	temp3
	jz	ptch31		; to disk
	push	h
	push	d
	push	b
	mov	e,a		; to display
	mvi	c,dconio
	call	bdos
	pop	b
	pop	d
	pop	h
	jmp	ptchr1		; continue

ptch31:	lhld	bufpnt		;Destination buffer.
	mov	m,a		;Store it.
	inx	h
	shld	bufpnt		;Update the pointer
	jmp	ptchr1		;and loop to next char.

ptchr9:	lxi	d,erms11	; "?Disk full"
	push	d		;[MF] Save pointer
	call	error3		; put it on the error line
	pop	d		;[MF] Restore pointer
	lxi	h,data		;[MF] Where to put the message for "e" packet
	lda	argblk		;[MF] Get packet-number
	call	countp		;[MF]Increment it
	sta	argblk		;[MF] as packet to send
	xra	a		;[MF] Zero length of packet data
	sta	temp1		;[MF] ...
ptch9a:	ldax	d		;[MF] Get a character to copy
	cpi	cr		;[MF] No more to copy?
	jz	ptch9b		;[MF] Yes, we can send the packet
	mov	m,a		;[MF] No, copy the character
	inx	d		;[MF] and increment source/dest pointers
	inx	h		;[MF] ...
	lda	temp1		;[MF] Get character count
	inr	a		;[MF] and increment it
	sta	temp1		;[MF] ...
	jmp	ptch9a		;[MF] Copy entire error message
ptch9b:	mvi	m,0		;[MF]Put in a zero
	lda	temp1		;[MF] Get number of characters in the message
	sta	argblk+1	;[MF] and store as number of packet data chars
	mvi	a,'E'		;[MF] Make it an error packet
	call	spack		;[MF] Send the error packet
	nop			;[MF] Don't really care if
	nop			;[MF] the send fails since we're
	nop			;[MF] bombing off anyway
	ret			; take error return.
;
;       Fill a data packet from file
;       called by: sfile, sdata

gtchr:	lda	squote		;Get the quote char.
	mov	c,a		;Keep quote char in c.
	lda	curchk		;Get current block check type
	sui	'1'		;Get the extra overhead
	mov	b,a		;Get a copy
	lda	spsiz		;Get the maximum packet size.
	sui	5		;Subtract the overhead.
	sub	b		;Determine max packet length
	sta	temp1		;This is the number of chars we are to get.
	lxi	h,filbuf	;Where to put the data.
	shld	cbfptr		;Remember where we are.
	mvi	b,0		;No chars.
gtchr1:	lda	temp1
	dcr	a		;Decrement the number of chars left.
	jp	gtchr2		;Go on if there is more than one left.
	mov	a,b		;Return the count in A.
	jmp	rskp

gtchr2:	sta	temp1
	lda	chrcnt		;Space left in the DMA.
	dcr	a
;* Can improve order here.
	jm	gtchr3
	sta	chrcnt
	jmp	gtchr4

gtchr3:	call	inbuf		;Get another buffer full.
	jmp	gtch30		; If no more return what we got.
	jmp	gtchr4		;If we got some, proceed.

gtch30:	mov	a,b		;Return the count in A.
	ora	a		;Get any chars?
	jnz	rskp		;If so return them.
	jmp	gtceof		;If not, say we found the end of the file.

gtchr4:	lhld	bufpnt		;Position in DMA.
	mov	a,m		;Get a char from the file.
	inx	h
	shld	bufpnt
	mov	d,a		;Save the char.
	ani	80H		;Turn off all but parity.
	mov	e,a		;Save the parity bit.
	jz	gtch4a		;[jd] no parity, skip this check...
	lda	quot8		;[jd] doing eighth-bit quoting?
	ora	a
	jz	gtch4a		;[jd] no, just proceed normally
	lda	temp1		;[jd] get space remaining
	cpi	2		;[jd] 3 chrs left (one cnted already)?
	jm	gtchr9		;[jd] no, skip this
	dcr	a		;[jd] decrement space remaining
	sta	temp1		;[jd] put back.
	lhld	cbfptr		;[jd] Position in character buffer.
	lda	qbchr		;[jd] get quote character
	mov	m,a		;]jd] Put the quote char in the buffer.
	inx	h		;[jd] increment destination buffer pointer
	shld	cbfptr		;[jd] store the pointer back
	inr	b		;[jd] Increment the char count.
	mvi	e,0		;[jd] no parity bit to OR in.
;[jd] fall thru...

gtch4a:	mov	a,d		;Restore the char.
	ani	7FH		;Turn off the parity.
	mov	d,a		;[jd] save here for later...
	cpi	space		;Compare to a space.
	jm	gtchr5		;If less then its a control char, handle it.
	cpi	del		;Is the char a delete?
	jz	gtchr5		;Go quote it.
	lda	quot8		; Are we doing 8th-bit quoting?
	ora	a
	jz	gtch4c		; if not, skip this test and restore character.
	lda	qbchr		; get 8th-bit quote character
	cmp	d		; same as current character?
	jz	gtch4b		; yes, have to quote it...
gtch4c:	mov	a,d		; no. get character back again.
	cmp	c		;Is it the quote char?
	jnz	gtchr8		;If not proceed.
gtch4b:	lxi	h,temp1		;[jd] point to char count
	dcr	m		;[jd] decrement (know room for at least one)
	lhld	cbfptr		;Position in character buffer.
	mov	m,c		;Put the (quote) char in the buffer.
	inx	h
	shld	cbfptr
	inr	b		;Increment the char count.
	mov	a,d		;[jd] restore character again
	jmp	gtchr8

gtchr5:	
	;[gnn] ignore parity for checking
;       ora     e		;Turn on the parity bit.

	cpi	('Z'-100O)     	;Is it a ^Z?
	jnz	gtchr7		;If not just proceed.
	lda	cpmflg		;Was the file created by CPM...
	cpi	1		;in ASCII-mode ?
	jz	gtch52		;Control-Z stops text
	cpi	2		;in BINARY mode?
	jz	gtchr6		;Yes, pass the ^Z
;At this point file-mode is DEFAULT.
;If the rest of the record is filled with ^Zs, we're at EOF, otherwise
;its a regular character.
	lhld	bufpnt		;since CHRCNT is ZERO at EOF-time
	lda	chrcnt		;(set by INBUF5 B.G.E)
	mov	d,a		;Get the number of chars left in the DMA.
gtch51:	dcr	d
	mov	a,d
	jp	gtch53		;Any chars left?
gtch52:	xra	a		;If not, get a zero.
	sta	chrcnt		;Say no more chars in buffer.
	mov	a,b		;Return the count in A.
	jmp	rskp

;Scan rest of buffer for non ^Z -- If we find a non ^Z, fall into gtchr6.
;If we get to the end of the buffer before finding a non ^Z, fall into gtch52.
gtch53:	mov	a,m		;Get the next char.
	inx	h		;Move the pointer.
	cpi	('Z'-100O)     	;Is it a ^Z?
	jz	gtch51		;If so see if the rest are.

gtchr6:	mvi	a,('Z'-100O)   	;Restore the ^Z.
gtchr7:	sta	temp2		;Save the char.
	lxi	h,temp1		;Point to the char total remaining.
	dcr	m		;Decrement it.
	lhld	cbfptr		;Position in character buffer.
	mov	m,c		;Put the quote in the buffer.
	inx	h
	shld	cbfptr
	inr	b		;Increment the char count.
	lda	temp2		;Get the control char back.
	adi	40H		;Make the non-control.
	ani	7fH		;Modulo 200 octal.
gtchr8:	lhld	cbfptr		;Position in character buffer.
	ora	e		;Or in the parity bit.
	mov	m,a		;Put the char in the buffer.
	inx	h
	shld	cbfptr
	inr	b		;Increment the char count.
	jmp	gtchr1		;Go around again.

gtchr9:	;[jd] not enough room left in buffer...
	lhld	bufpnt
	dcx	h
	shld	bufpnt		;[jd] back up over last character
	lxi	h,chrcnt	;[jd] point to character count
	inr	m		;[jd] increment it
	mov	a,b		;[jd] count of chars transferred
	jmp	rskp		;[jd] return it

gtceof:	mvi	a,0FFH		;Get a minus one.
	ret
;

; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FRO RELEASE!

;	org ($+100h) AND 0FF00H

IF	lasm
	LINK	CPSPK2		;[obs] Link to part two of the packet file
ENDIF	;lasm
