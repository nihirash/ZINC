; CPSREM.ASM
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
;       the REMOTE commands of the KERMIT protocol.
;
; revision history:
;
;edit 13, 21-Mar-1991 by MF. Renamed REMOTE SET FILE COLLISION REPLACE to
;	REMOTE SET FILE COLLISION OVERWRITE and modified the corresponding
;	help text slightly.
;edit 12, 13-Feb-1991 by MF. Simplified code at "remcl0" to get REMOTE
;	command arguments by calling "cmgtch" in order to get command-line
;	characters directly. This means that command-line characters are
;	passed literally (except for prefixingand space-compression) to the
;	remote Kermit and that one need not send "?" or <esc> as "\"-prefixed
;	octal numbers in order to avoid immediate action by CP/M Kermit.
;edit 11, 30-Jan-1991 by MF. Corrected code to always require entry of at least
;	one argument in the REMOTE COPY, REMOTE DELETE (REMOTE ERASE),
;	REMOTE MESSAGE, REMOTE RENAME and REMOTE TYPE commands. This is
;	done by branching to KERMT3 (the "not confirmed" code) if the
;	first argument isn't given. This should correct a bug which occurred
;	in numerous places in which the character immediately following
;	that specifying the flavor of a Generic command was not defined if
;	the first of multiple (at least two) arguments was left blank but
;	subsequent arguments were not. This should correct a problem
;	encountered by Russell Lang of Monash University In Australia when
;	he did a REMOTE MESSAGE command with a blank first argument (the
;	user id) and a nonblank second argument (the message text) from
;	CP/M Kermit to Ms-Kermit in Server mode.
;edit 10, 14-Dec-1990 by MF.  Put "<<>>" around "x" or "F" packet replies
;	to REMOTE commands as in VMS Bliss Kermit and eliminate unnecessary
;	instruction before label remc2d.
;edit 9, 1-Nov-1990 by MF.  Changed REMOTE CWD to REMOTE CD in the quest for
;	uniformity of nomenclature (per request of FDC).
;edit 8, 29-Oct-1990 by MF.  Corrected Remote command code to properly
;	prefix control characters (repeat prefix (~) isn't done in CP/M
;	yet).
;edit 7, 17-Oct-1990 by MF.  Changed verb "REMOTE SEND-MESSAGE" to
;	"REMOTE MESSAGE" to conform with the nomenclature suggested in
;	Chapter 10 of the 6th edition of the Kermit Protocol Manual.
;edit 6, 10-Oct-1990 by MF.  Corrected Remote command code to
;	properly prefix the control-character prefix character and the
;	eighth-bit quotation prefix character.  Remote Set commands
;	now function correctly.
;	Also change the REMOTE SET FILE COLLISION ASK value to 5 per
;	Kermit Digest V12 #6 (though I still have no idea how the local
;	Kermit is supposed to answer).
;edit 5, 5-Oct-1990 by MF.  Coded many Remote Set commands.
;	The commands I have omitted deal with Attribute packets which
;	don't make much sense on a CP/M system.
;	Note also that for those Remote Set commands which take a
;	numeric argument, no range-checking is done here.
;	Also note that, for now, REMOTE SET FILE-COLLISION ASK is
;	equivalent to REMOTE SET FILE-COLLISION DISCARD because
;	(a) that's what the Kermit Digest indicated and (b) no mechanism
;	has been proposed for the Remote Kermit to query the Local Kermit.
;edit 4, 29-Sep-1990 by MF.  Corrected code to ignore error packets in
;	response to sending an "I" packet, per KPROTO.DOC
;edit 3, 9-Sep-1990 by MF.  Extensively revised this file to implement
;	Remote commands except for the following:
;	REMOTE JOURNAL, REMOTE MAIL, REMOTE PRINT, REMOTE PROGRAM,
;	REMOTE SET, REMOTE VARIABLE.
;edit 2 ... MF Dunno where edit 2 went (shown in Version string).
; edit 1: September 8th, 1987.  Created this file from bits of the two packet files.
;	The commands supported by this system are all the REMOTE commands,
;	to allow users to acces remote host systems via Kermit.  Added REMOTE
;	command table and REMOTE DIR command.
;
;
remver:	db	'CPSREM.ASM (13)  21-Mar-1991$'	; name, edit number, date

;
;  REMOTE command - quite similar to the SET command
remote:	call selmdm		;Select modem
	call	flsmdm		;Flush buffers
	call	selcon		;Back to keyboard
	lxi	d,remtab	; remote commands table
	lxi	h,remhlp	; remote help table
	call	keycmd		; get result
	xchg
	pchl		; and do it




; REMOTE command table.  Works the same way as every other table etc.
;
remtab:	db	19		; nineteen commands so far
	db	2,'CD$'
	dw	remcd		; remote cd command
	db	4,'COPY$'
	dw	remcpy		; remote copy command
	db	6,'DELETE$'
	dw	remdel		; remote delete command
	db	9,'DIRECTORY$'
		dw	remdir	; remote directory command
	db	10,'DISK-USAGE$'
	dw	remdsk		; remote disk-usage command
	db	5,'ERASE$'
	dw	remdel		; remote erase command (same as delete)
	db	6,'FINISH$'
		dw	finish	; same as finish
	db	4,'HELP$'
	dw	remhep		; remote help command
	db	4,'HOST$'
	dw	remhos		; remote host command
	db	6,'KERMIT$'
	dw	remker		; remote Kermit command
	db	5,'LOGIN$'
	dw	remlgi		; remote login
	db	6,'LOGOUT$'
		dw	logout	; same as logout
	db	7,'MESSAGE$'
	dw	remmsg		; remote message command
	db	6,'RENAME$'
	dw	remren		; remote rename
	db	3,'SET$'
	dw	remset		; remote set command
	db	5,'SPACE$'
	dw	remdsk		; remote space command (same as disk-usage)
	db	6,'STATUS$'
	dw	remsta		; remote status (of server) command
	db	4,'TYPE$'
	dw	remtyp		; remote type command
	db	3,'WHO$'
	dw	remwho		; remote who command

remhlp:	db	cr,lf,'CD - change default directory for remote server'
	db	' operations'
	db	cr,lf,'COPY - copy files on a remote system'
	db	cr,lf,'DELETE - delete files on a remote system'
	db	cr,lf,'DIRECTORY - list a directory on a remote system'
	db	cr,lf,'DISK-USAGE - show disk usage on a remote system'
	db	cr,lf,'FINISH - stop a remote server'
	db	cr,lf,'HELP - get help from a remote server'
	db	cr,lf,'HOST - execute a command on a remote system'
	db	cr,lf,'KERMIT - tell a remote server to execute a Kermit '
		db	'command'
	db	cr,lf,'LOGIN - send user-identification to a remote server'
	db	cr,lf,'LOGOUT -  stop and logout a remote server'
	db	cr,lf,'MESSAGE - send a message to a remote system user'
	db	cr,lf,'RENAME - rename files on a remote system'
	db	cr,lf,'SET - set remote server parameters'
	db	cr,lf,'SPACE - show disk-usage on a remote system'
	db	cr,lf,'STATUS - Get status of a remote server'
	db	cr,lf,'TYPE - type files on a remote system'
	db	cr,lf,'WHO - show current users on a remote system'
	db	'$'


;Description of remote commands

;
;  Packets start with an I packet in place of S/R packet.  An X
;	packet is the same as an F (filename) packet except the 'file'
;	is not applicable.  Copy X packet data field to display.  Set
;	options so that no data is written to disk during D packets. 
;	(REMTXT <> 0)
;
;Packets:
;	we	we	comments
;	send	receive
;	I
;		ACK
;	Command packet
;		Ack or
;		Init
;	ACK
;		X	Dummy header.
;	ACK
;		D	listing from remote end
;	ACK		We got it
;	....
;	ACK		last packet received ok
;		Z
;	ACK
;		B
;	ACK		end of transaction.
;
;**Note** If the Remote system gives a simple ack to the command packet,
;that is, a "short reply" is given, the data, if any, in the packet
;is displayed and the transaction ends.  The outline shown above is for a
;"long reply".
;
; Remote commands
;
; Remote Copy - Copy file(s) on remote system
;
remcpy:	lxi	h,newfms	;Second argument prompt
	shld	rprmpt		;...
	mvi	a,'K'		;Generic type
remcp0:	sta	remdat		;into packet
	mvi	a,2		;Packet has at least two characters
	sta	rdl		;...
	mvi	a,'G'		;Generic command
	sta	rcom		;...
	lxi	d,remdat+2	;Point to data buffer
	call	remcli		;Get filespec (if any) from command line
	ora	a		;Anything typed?
	  jz	kermt3		;No, we must have an argument
	mov	b,a		;Save length
	adi	space		;Yes, make encoded field length
	sta	remdat+1		;and store in packet data area
	lda	rdl		;Get packet length so far
	add	b		;Count answer length
	sta	rdl		;and remember new packet size
	lhld	rprmpt		;Point to "new file" prompt
	xchg		;...
	shld	rptr		;Save data pointer
	call	prompt		;Prompt the user
	lhld	rptr		;Get data pointer again
	inx	h		;Skip encoded field-length
	xchg		;...
	call	remcli		;get user's answer
	lhld	rptr		;Restore pointer
	mov	c,a		;Save answer length
	adi	space		;Convert to encoded field length
	mov	m,a		;Put length in packet
	lda	rdl		;Get accumulated data length
	add	c		;plus data length
	adi	1		;plus field length character
	sta	rdl		;and remember it
	jmp	remcom		;and branch to common code
;
; Remote Cd - Change Directory
;
remcd:	lxi	h,pswdms	;Second argument prompt
	shld	rprmpt		;...
	mvi	a,'C'		;Generic cd
remcd0:	sta	remdat		;into packet
	mvi	a,1		;Packet is at least one character long
	sta	rdl		;...
	mvi	a,'G'		;Generic command
	sta	rcom		;...
	lxi	d,remdat+2	;Point to data buffer
	call	remcli		;Get filespec (if any) from command line
	mov	b,a		;Save answer length (may be zero)
	adi	space		;Make encoded field length
	sta	remdat+1		;and store in packet data area
	lda	rdl		;Get length so far
	add	b		;Count answer length
	adi	1		;and field length character
	sta	rdl		;and remember current packet-size
	lda	remdat		;Get generic packet flavor
	cpi	'C'		;Remote CD?
	jnz	remcd1		;No
	mov	a,b		;Get length of possible directory spec
	ora	a		;Did the user give a directory spec?
	jz	remcom		;No, we can process the command immediately
	mvi	a,0ffH		;Yes, password follows, make it not echo
	sta	cmqflg		;...
remcd1:	lhld	rprmpt		;Point to "password" prompt
	xchg		;...
	shld	rptr		;Save data pointer
	mvi	a,0ffH		;Allow blank password
	sta	cmbflg		;...
	call	prompt		;Prompt the user
	lhld	rptr		;Restore data pointer
	xchg		;...
	inx	d		;and increment it
	call	remcli		;Get user's answer
	ora	a		;Password given?
	  jz	remcom		;No, proceed with command
	mov	c,a		;Yes, save answer length
	adi	space		;Convert to encoded field length
	lhld	rptr		;Get data pointer
	mov	m,a		;Put length in packet
	lda	rdl		;Get accumulated data length
	adi	1		;Count encoded field length
	add	c		;plus data length
	sta	rdl		;and remember packet-size
	jmp	remcom		;Branch to common code
;
; Remote Delete (Erase) command
;
remdel:	mvi	a,'E'		;Delete (Erase) command
remdl0:	sta	remdat		;...
	mvi	a,1		;At least one character in packet
	sta	rdl		;...
	mvi	a,'G'		;Generic command
	sta	rcom		;...
	lxi	d,remdat+2	;Point to data field
	call	remcli		;Get filespec
	mov	b,a		;Save length
	lda	remdat		;Get packet type
	cpi	'E'		;If Generic Delete
	jz	remdl1		;We must have an argument
	cpi	'T'		;Ditto for Generic Type
	jz	remdl1		;...
	mov	a,b		;Else get back character count
	ora	a		;Answer typed?
	  jz	remcom		;No, process packet as is
remdl1:	mov	a,b		;Get character count again
	ora	a		;Anything typed?
	jz	kermt3		;No, we must have an argument (Delete/Type)
	adi	space		;Yes, encode field length
	sta	remdat+1		;and put in packet
	lda	rdl		;Get packet length so far
	add	b		;Count length of filespec
	adi	1		;Count field length character
	sta	rdl		;and store packet length
	jmp	remcom		;and do our stuff
;
; Remote Directory command
;
remdir:	mvi	a,'D'		;generic directory command
	jmp	remdl0		;Do common code
;
; Remote Disk-usage (Space) command
;
remdsk:	mvi	a,'U'		;Disk-usage generic command
	jmp	remdl0		;Do common code
;
; Remote Help command
;
remhep:	mvi	a,'H'		;generic help command
	jmp	remdl0		;Do common code
;
; Remote Host command
;
remhos:	mvi	a,'C'		;Remote Host command
remho0:	sta	rcom		;...
	xra	a		;Zero packet length
	sta	rdl		;...
	lxi	d,remdat		;Point to packet data buffer
	call	remcli		;Get host command
	ora	a		;Anything typed?
	jz	kermt3		;No, don't let the user get away with this
	sta	rdl		;Yes, store packet length
	jmp	remcom		;and do the command
;
; Remote Kermit command
;
remker:	mvi	a,'K'		;Remote Kermit command
	jmp	remho0		;Do common code
;
; Remote Login command
;
remlgi:	mvi	a,'G'		;Generic command
	sta	rcom		;...
	mvi	a,'I'		;Generic type
	sta	remdat		;into packet
	mvi	a,1		;At least one character in packet
	sta	rdl		;...
	lxi	d,remdat+2	;Point to data buffer
	call	remcli		;Get userid (if any) from command line
	ora	a		;Userid typed?
	  jz	remcom		;No, nothing more to do
	mov	b,a		;Yes, save length
	adi	space		;Make encoded field length
	sta	remdat+1		;and store in packet data area
	lda	rdl		;Get packet length
	add	b		;Count id length
	adi	1		;and field length character
	sta	rdl		;and remember accumulated length
	xchg		;Save data pointer
	shld	rptr		;...
	mvi	a,0ffH		;Allow blank answers
	sta	cmbflg		;...
	sta	cmqflg		;Passwords don't echo
	lxi	d,pswdms	;Point to "password" prompt
	call	prompt		;Prompt the user
	lhld	rptr		;Get data pointer
	xchg		;Put in DE
	inx	d		;Skip encoded field-length
	call	remcli		;Get password, if any
	ora	a		;Anything typed?
	  jz	remcom		;No, do command immediately
	mov	c,a		;Yes, save answer length
	adi	space		;Convert to encoded field length
	lhld	rptr		;Get pointer
	mov	m,a		;Put length in packet
	lda	rdl		;Get accumulated data length
	adi	1		;Count encoded field length
	add	c		;Count "password" field length
	sta	rdl		;and remember new packet length
	xchg		;Save data pointer
	shld	rptr		;...
	xra	a		;Allow echoing again for "account" field
	sta	cmqflg		;...
	lxi	d,acctms	;Point to "account" prompt
	call	prompt		;Prompt the user
	lhld	rptr		;Get data pointer
	xchg		;into DE
	inx	d		;Skip encoded field length
	call	remcli		;Get "account" field, if any
	ora	a		;Anything typed?
	  jz	remcom		;No, do the command now
	mov	c,a		;Yes, save length of answer
	adi	space		;Convert to encoded field length
	lhld	rptr		;Get data pointer
	mov	m,a		;Put length in packet
	lda	rdl		;Get accumulated data length
	adi	1		;Count encoded field length
	add	c		;plus "account" length
	sta	rdl		;and remember it
	jmp	remcom		;Branch to common code
;
; Remote Rename command
;
remren:	lxi	h,newfms	;Second argument prompt
	shld	rprmpt		;...
	mvi	a,'R'		;generic rename
	jmp	remcp0		;Do common code
;
; Remote Message command
;
remmsg:	lxi	h,msgms		;Second argument prompt
	shld	rprmpt		;...
	mvi	a,'M'		;generic message
	jmp	remcp0		;Do common code
;
;Remote Set command
;
remset:	mvi	a,6		;Packet data area has at least six chars
	sta	rdl		;...
	mvi	a,'S'		;Remote Set command
	sta	remdat		;...
	mvi	a,'G'		;It's a generic command
	sta	rcom		;...
	mvi	a,'#'		;Encoded field-length for SET type
	sta	remdat+1	;which is three chars long
	lxi	d,rmstab	;Point to Set command table
	lxi	h,rmshlp	;and the help table
	call	keycmd		;Find out which command is to be executed
	xchg		;Put dispatch address in HL
	pchl		;Go do the command
;
; Common code for Remote Set commands that take an argument
;
remscm:	lxi	d,remdat+6	;We get an argument from the user
	mvi	a,cmtxt		;...
	call	comnd		;...
	jmp	kermt3		;Couldn't get one.
	ora	a		;Did the user give one?
	jz	kermt3		;a blank answer isn't acceptable
	mov	c,a		;Save length of answer
	adi	space		;Convert to encoded field-length
	sta	remdat+5	;and put in packet data area
	lda	rdl		;Get current data length
	add	c		;Count length of answer
	sta	rdl		;and store new data length
	call	cfmcmd		;Get a "confirm"
	jmp	remcom		;Do common Remote command code
;
; Common code for Remote Set commands requiring another table lookup
;
remsc1:	call	chkkey		;Get user's selection
	sta	remdat+6	;and put into the packet data area
	mvi	a,'!'		;Encoded field length for 1 char
	sta	remdat+5	;Put in packet
	lda	rdl		;Get accumulated packet data length
	adi	1		;Count length of answer (1 char)
	sta	rdl		;and store as new packet data length
	jmp	remcom		;Go do common Remote command processing
;
; Remote Status (of server) command
;
remsta:	call	cfmcmd		;Get return
	mvi	a,'Q'		;Command type (Server Status)
	sta	remdat		;...
	mvi	a,'G'		;Generic Kermit command
	sta	rcom		;...
	mvi	a,1		;1 character in packet
	sta	rdl		;...
	jmp	remcom		;Do common code
;
; Remote Type command
;
remtyp:	mvi	a,'T'		;generic type command
	jmp	remdl0		;Do common code
;
; Remote Who command
;
remwho:	lxi	h,optms		;Second argument prompt
	shld	rprmpt		;...
	mvi	a,'W'		;generic who
	jmp	remcd0		;Do common code

; Common code for Remote commands
;
remcom:
	mvi	a,0ffH		; Make sure returned info is sent
	sta	remtxt		;to the user's screen rather than to a file
	lda	rcom		;Get packet-type
	cpi	'G'		;Is it a generic command?
	jnz	remc0e		;No, go clear the screen
	lda	remdat		;Yes, get generic command type
	cpi	'S'		;Is it a Remote Set command?
	jz	remc0f		;Yes, don't clear the screen
remc0e:	call	clrtop		; clear the screen
remc0f:	xra	a
	sta	numtry		; reset retries
	sta	czseen
	sta	pktnum
	lxi	h,0
	shld	numpkt
	shld	numrtr		; clear some variables

	mvi	a,'1'		; reset block check type
	sta	curchk
remcm0:	mvi	a,'I'		; init state
	sta	state
	call	sinit		; do sendinit with I packet (??)
	lda	state		; now see if we are in the 'X' state
	cpi	'X'
	jz	remco0		;Yup, all is in order
	cpi	'A'		;No, in abort state?
	jnz	remcm0		;No, try I-packet again
	jmp	kermit		;Yes, like Danny Boy, we must die.
				;If we get this far, either the "I" packet
				;was understood or the Server couldn't
				;handle it and we ignored the error.
				;In either case, we can proceed.



remco0:	xra	a
	sta	numtry		; reset retries
	sta	czseen
	sta	pktnum
	lxi	h,0
	shld	numpkt
	shld	numrtr		; clear some variables
	mvi	a,'1'		;Make sure we use
	sta	curchk		;1-character checksum
	lda	rdl		;Get packet-length (number of bytes to copy)
	ora	a		;Anything to copy?
	  jz	remcm1		;No
	sta	temp1		;Yes, save loop counter
	lda	spsiz		;Get max packet size
	sui	5		;less overhead
	sta	temp2		;gives max chars we can send
	lxi	d,remdat		;Copy from private buffer
	lxi	h,data		;to packet data area
	lda	qbchr		;Get eightgh-bit quoting prefix char
	mov	b,a		;Save it
	lda	squote		;Get control-char quoting char
	mov	c,a		;and save it
remc0a:	lda	temp2		;Get characters to go in packet
	dcr	a		;and decrement it
	sta	temp2		;...
	jm	remc0x		;We can't copy any more
	ldax	d		;Get a packet data character
	cpi	space		;Is it a control char?
	jm	remc0b		;Yes, quote it
	cmp	c		;Is it the control-char prefix?
	jz	remc0b		;Yes, quote it
	lda	quot8		;No, is eighth-bit quoting in effect?
	ora	a		;...
	jz	remc0c		;No, just copy the character
	ldax	d		;Get character again
	cmp	b		;Is it the eighth-bit quote char?
	jnz	remc0d		;No, just copy it
remc0b:	mov	m,c		;Yes, quote the character
	inx	h		;Increment the dest. pointer
	lda	temp2		;Get chars to go
	dcr	a		;Decrement
	sta	temp2		;...
	jm	remc0x		;Can't copy any more
	lda	rdl		;Count quote prefix
	inr	a		;...
	sta	rdl		;...
remc0c:	ldax	d		;Get character again
	cpi	space		;If not a control char,
	jp	remc0d		;just copy the character, else
	adi	40H		;Convert to printing character
	ani	7fH		;modulo 128
remc0d:	mov	m,a		;Copy the character
	inx	h		;Increment the pointers
	inx	d		;...
remc0x:	lda	temp1		;Get loop counter
	dcr	a		;and decrement it
	sta	temp1		;...
	jnz	remc0a		;Copy entire packet data area
;
remcm1:	xra	a
	sta	argblk		; set packet no zero
	lda	rdl		;Number of bytes in packet
	sta	argblk+1	;into argument block
	lda	rcom		;Remote command
	call	spack		;Send the packet
	jmp	kermt3		;Nogo, die!
	jmp	remco2		;Try to get an answer

remco1:	call	nak0		;Nak packet
;

remco2:	lda	numtry		;Get number of retries
	inr	a		; update retries
	cpi	maxtry		;To many retries?
	jm	remc2a		;No
	lxi	d,erms28	;Yes, complain
	call	prtstr		;...
	jmp	kermit		;and abort

remc2a:	sta	numtry
	call	rpack		;Get a packet
	jmp	remco1		;Couldn't get one.
	cpi	'E'		;Error packet?
	jnz	remc2b		;No
	lda	rcom		;What kind of packet did we send?
	cpi	'G'		;If it wasn't generic,
	jnz	remc2f		;there is no need to start a new message line
	lda	remdat		;Packet was generic
	cpi	'S'		;Was it a Remote Set?
	cz	prcrlf		;Yes, start a new line since the screen
				;isn't blank and we would clobber the command-
				;line otherwise
remc2f:	call	error0		;Yes, inform the user
	jmp	kermit		;and abort to main command loop
remc2b:	cpi	'S'		;Send-init?
	jnz	remc2c		;No
	call	rini2a		;Initialize parameters
	lda	state		;Get state
	cpi	'A'		;If abort,
	jz	kermit		;Go back to main command loop
	mvi	a,'X'		;Set state to text-display
	sta	state		;...
	jmp	read2		;Get more packets
remc2c:	cpi	'N'		;Nacked packet?
	jz	remco2		;Yes, try again
	sta	state		;Save packet type
	call	selcon		;Select Console
	lxi	h,data		;Point to data
	lda	argblk+1	;Anything in packet data?
	ora	a		;...
	jz	remco6		;No
	push	h		;Yes, save pointer
	push	psw		;and character count
	mvi	e,'<'		;Type "<<" as in VMSKermit
	push	d		;...
	call	outcon		;...
	pop	d		;...
	call	outcon		;...
	pop	psw		;Restore character counter
	pop	h		;and data pointer
remc2d:	ora	a		;...
	jz	remc2e		;No more characters
	dcr	a		;Decrement loop counter
mov	e,m		;Get character
	inx	h		;Increment pointer
	push	psw		;Save loop counter
	push	h		;Save data pointer
	call	outcon		;Type on Console
	pop	h		;Restore pointer
	pop	psw		;Restore loop counter
	jmp	remc2d		;Type all packet data
remc2e:	mvi	e,'>'		;Type ">>" as in VMSKermit
	push	d		;...
	call	outcon		;...
	pop	d		;...
	call	outcon		;...
	call	prcrlf		;End the line
remco6:	lda	state		;Get packet type again
	cpi	'Y'		;If simple ack,
	jz	kermit		;Done, else
	call	ackp		;Acknoledge the packet
	call	countp		;Count the packet
	mvi	a,'D'		;Set to data-receive
	sta	state		;...
	jmp	read2		; do the same as read a file, but echo
				; to the screen.. Dont close non-open files.
;
;
;REMCLI - Get command-line for Remote commands
;
remcli:	xra	a		;Zero accumulated length
	sta	rcl		;...
	mov	b,a		;[12]...
;
;[MF][12]Eliminate following code which calls "comnd" in favor of code which
;[MF][12]calls "cmgtch" directly so that characters are sent without
;[MF][12]alteration or inadvertent action ("?" or <esc>). The only thing
;[MF][12]lost is the ability to produce any ASCII character via
;[MF][12]octal numbers prefixed with "\" but this isn't used much in remote
;[MF][12]commands anyway.
;
;remcl0:	mvi	a,cmtxt		;We get arbitrary text
;	call	comnd		;from the command-line
;	jmp	kermt3		;We couldn't get any.
;	ora	a		;Anything given?
;	jz	remcl1		;No, done
;	push	b		;Save BC
;	mov	c,a		;Save length
;	lda	rcl		;Get accumulated length
;	add	c		;plus current word length
;	adi	1		;plus a space
;	sta	rcl		;and save accumulated length
;	mvi	a,space		;Put in a space separator
;	stax	d		;...
;	inx	d		;Increment pointer
;	pop	b		;Restore BC
;	jmp	remcl0		;Get text to end-of-line
;remcl1:	lda	rcl		;Get accumulated length
;	ora	a		;Anything typed?
;	rz		;No
;	dcr	a		;Yes, don't count final space
;	push	psw		;Save count
;	dcx	d		;Point to final space
;	xra	a		;Zap it
;	stax	d		;...
;	pop	psw		;Restore count
;
;[MF][12]Simplified code follows
;
remcl0:	call	cmgtch		;[12]Get a character from the user
	ani	7fh		;[12]Turn off minus bit
	cpi	cr		;[12]If end-of-line,
	jz	remclx		;[12]We're done
	cpi	lf		;[12]...
	jz	remclx		;[12]...
	stax	d		;[12]else store the character
	inr	b		;[12]and count it
	inx	d		;[12]Increment character buffer pointer
	cpi	esc		;[12]is character an <esc>?
	jz	remcl2		;[12]Yes
	cpi	ff		;[12]an <ff>?
	jz	remcl1		;[12]Yes, diddle command buffer pointer
	cpi	'?'		;[12]a "?"?
	jnz	remcl0		;[12]No, just get more characters
remcl1:	push	h		;[12]Protect HL
	lhld	cmdptr		;[12]get "cmgtch"'s character pointer
	inx	h		;[12]and reverse the action at "cmgtc4"
				;[12]since we don't need a "confirm" and
				;[12]infinite loops are beaucoup bad news
	shld	cmdptr		;[12]...
	pop	h		;[12]Restore HL
remcl2:	push	psw		;[12]Save the character
	xra	a		;[12]Zero the action flag so we get input
	sta	cmaflg		;[12]to end-of-line without special action
	pop	psw		;[12]Restore the character
	jmp	remcl0		;[12]Get more characters
remclx:	mov	a,b		;[12]Get accumulated text length
	sta	rcl		;[12]and remember it
;
	ret		;Return
;
;Remote set values
;
;  REMOTE SET FILE TYPE                    300   0 = TEXT, 1 = BINARY
;  REMOTE SET FILE NAMES                   301   0 = CONVERTED, 1 = LITERAL
;  REMOTE SET FILE COLLISION               302   0 = RENAME,  1 = OVERWRITE,
;                                                2 = BACKUP,  3 = APPEND,
;                                                4 = DISCARD, 5 = ASK
;  REMOTE SET FILE REPLACE                 303   0 = PRESERVE, 1 = DEFAULT
;  REMOTE SET FILE INCOMPLETE              310   0 = DISCARD, 1 = KEEP
;  REMOTE SET INCOMPLETE (same as above)
;  REMOTE SET BLOCK-CHECK                  400   number (1, 2, or 3)
;  REMOTE SET RECEIVE PACKET-LENGTH        401   number (10-9024)
;  REMOTE SET RECEIVE TIMEOUT              402   number (any, 0 = no timeout)
;  REMOTE SET RETRY                        403   number (any, 0 = no limit)
;  REMOTE SET SERVER TIMEOUT               404   number (any, 0 = no timeout)
;REMOTE SET FILE BLOCKSIZE       311  number
;REMOTE SET FILE RECORD-LENGTH   312  number
;REMOTE SET FILE RECORD-FORMAT   313  F (fixed), V (variable), etc...
;This is just for the record, to assign these numbers to these commands
;for somebody who needed them.  Details to be filled in later.
;
;Remote Set command table
;
rmstab:	db	7		;seven entries
	db	16,'BLOCK-CHECK-TYPE$'
	dw	remsbc		;Remote Set Block Check
	db	4,'FILE$'
	dw	remsfl		;Remote Set File
	db	10,'INCOMPLETE$'
	dw	remsfi		;Remote Set (file) Incomplete
	db	7,'RECEIVE$'
	dw	remsrc		;Remote Set Receive
	db	7,'REPLACE$'
	dw	remsfr		;Remote Set (file) Replace
	db	5,'RETRY$'
	dw	remsry		;Remote Set Retry
	db	14,'SERVER-TIMEOUT$'
	dw	remsst		;Remote Set Server Timeout
;
rmshlp:	db	cr,lf,'BLOCK-CHECK-TYPE for a remote server'
	db	cr,lf,'FILE parameters for a remote server'
	db	cr,lf,'INCOMPLETE file disposition for a remote server'
	db	cr,lf,'RECEIVE parameters for a remote server'
	db	cr,lf,'REPLACE file attribute handling for a remote server'
	db	cr,lf,'RETRY maximum for a remote server'
	db	cr,lf,'SERVER-TIMEOUT interval for a remote server'
	db	'$'
;
;Remote Set File tables
;
rsftab:	db	8		;eight entries
	db	10,'BLOCK-SIZE$'
	dw	remsbs		;Remote Set File Block-size command
	db	9,'COLLISION$'
	dw	remsfc		;Remote Set File Collision command
	db	10,'INCOMPLETE$'
	dw	remsfi		;Remote Set File Incomplete command
	db	5,'NAMES$'
	dw	remsfn		;Remote Set File Names command
	db	13,'RECORD-FORMAT$'
	dw	remsrf		;Remote Set File Record-format
	db	13,'RECORD-LENGTH$'
	dw	remsrl		;Remote Set File Record-length
	db	7,'REPLACE$'
	dw	remsfr		;Remote Set File Replace command
	db	4,'TYPE$'
	dw	remsft		;Remote Set File Type command
;
rsfhlp:	db	cr,lf,'BLOCK-SIZE of files for a remote server'
	db	cr,lf,'COLLISION action on filename conflicts for a remote'
	db	' server'
	db	cr,lf,'INCOMPLETE file disposition for a remote server'
	db	cr,lf,'NAMES translation of files for a remote server'
	db	cr,lf,'RECORD-FORMAT of files for a remote server'
	db	cr,lf,'RECORD-LENGTH for a remote server'
	db	cr,lf,'REPLACE file attribute handling for a remote server'
	db	cr,lf,'TYPE of files for a remote server'
	db	'$'
;
;Remote Set File Record-format tables
;
rcftab:	db	2		;two entries
	db	5,'FIXED$'
	db	'F','F'		;Remote Set File Record-format Fixed command
	db	8,'VARIABLE$'
	db	'V','V'		;Remote Set File Record-format Variable cmd
;
rcfhlp:	db	cr,lf,'FIXED	VARIABLE'
	db	'$'
;
;Remote Set Receive tables
;
rrctab:	db	2		;two entries
	db	13,'PACKET-LENGTH$'
	dw	remrpl		;Remote Set Receive Packet-length command
	db	7,'TIMEOUT$'
	dw	remsrt		;Remote Set Receive Timeout command
;
rrchlp:	db	cr,lf,'PACKET-length	TIMEOUT'
	db	'$'
;
;Remote Set File-collision table
;
rfctab:	db	6		;six entries
	db	6,'APPEND$'
	db	'3','3'		;Set collision append
	db	3,'ASK$'
	db	'5','5'		;Set collision ask
	db	6,'BACKUP$'
	db	'2','2'		;Set collision backup
	db	7,'DISCARD$'
	db	'4','4'		;Set collision discard
	db	9,'OVERWRITE$'
	db	'1','1'		;Set collision overwrite
	db	6,'RENAME$'
	db	'0','0'		;Set collision rename
;
rfchlp:	db	cr,lf,'ASK about existing files on a remote system'
	db	cr,lf,'APPEND to existing files on a remote system'
	db	cr,lf,'BACKUP (rename) existing files on a remote system'
	db	cr,lf,'DISCARD new versions of existing files on a'
	db	' remote system'
	db	cr,lf,'OVERWRITE existing files on a remote system'
	db	cr,lf,'RENAME new versions of existing files on a'
	db	' remote system'
	db	'$'
;
;Remote Set File-Incomplete tables
;
rfitab:	db	2		;2 entries
	db	7,'DISCARD$'
	db	'0','0'		;Remote Set File Incomplete Discard
	db	4,'KEEP$'
	db	'1','1'		;Remote Set File Incomplete Keep
;
rfihlp:	db	cr,lf,'DISCARD	KEEP'
	db	'$'
;
;Remote Set File-Names tables
;
rfntab:	db	2		;two entries
	db	9,'CONVERTED$'
	db	'0','0'		;Remote Set File Names Converted
	db	7,'LITERAL$'
	db	'1','1'		;Remote Set File Names Literal
;
rfnhlp:	db	cr,lf,'CONVERTED	LITERAL'
	db	'$'
;
;Remote Set File Replace tables
;
rfrtab:	db	2		;two entries
	db	8,'PRESERVE$'
	db	'0','0'		;Remote Set File Replace Preserve
	db	7,'DEFAULT$'
	db	'1','1'		;Remote Set File Replace Default
;
rfrhlp:	db	cr,lf,'PRESERVE	DEFAULT'
	db	'$'
;
;Remote Set File Type tables
;
rfttab:	db	2		;two entries
	db	6,'BINARY$'
	db	'1','1'		;Remote Set File Type Binary
	db	4,'TEXT$'
	db	'0','0'		;Remote Set File Type Text
;
rfthlp:	db	cr,lf,'BINARY	TEXT'
	db	'$'
;
; Remote Set Block-check
;
remsbc:
IF lasm
	lxi	h,'40'		;1st 2 chars of "400"
ENDIF ;lasm
IF NOT lasm
	lxi	h,'04'
ENDIF ;NOT lasm
	shld	remdat+2	;Store in correct order
	mvi	a,'0'		;Put last char of type in buffer
	sta	remdat+4	;...
	lxi	d,blktab	;Point to block-check table
	lxi	h,blkhlp	;and help table
	jmp	remsc1		;Do common code
;
;Remote Set File command
;
remsfl:	lxi	d,rsftab	;Point to Remote Set File tables
	lxi	h,rsfhlp	;...
remsf0:	call	keycmd		;Get user's selection
	xchg		;Put dispatch address in HL
	pchl		;and obey the user's most fervent desires
;
;Remote Set Receive command
;
remsrc:	lxi	d,rrctab	;Point to the appropriate tables
	lxi	h,rrchlp	;...
	jmp	remsf0		;and do command
;
;Remote Set Block-size command
;
remsbs:
IF lasm
	lxi	h,'31'		;1st 2 chars of Set code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'13'
ENDIF ;NOT lasm
	shld	remdat+2	;Store chars in correct order
	mvi	a,'1'		;Put last char in buffer
	sta	remdat+4	;...
	jmp	remscm		;and do common Remote Set code
;
;Remote Set File-collision command
;
remsfc:
IF lasm
	lxi	h,'30'		;Put set type code in buffer
ENDIF ;lasm
IF NOT lasm
	lxi	h,'03'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'2'		;...
	sta	remdat+4		;...
	lxi	d,rfctab	;Point to tables
	lxi	h,rfchlp	;...
	jmp	remsc1		;and do common code
;
;Remote Set File Incomplete command
;
remsfi:
IF lasm
	lxi	h,'31'		;Establish command keyword code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'13'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'0'		;...
	sta	remdat+4	;...
	lxi	d,rfitab	;Point to tables
	lxi	h,rfihlp	;...
	jmp	remsc1		;and do common code
;
;Remote Set File-Names command
;
remsfn:
IF lasm
	lxi	h,'30'		;Set command code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'03'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'1'		;...
	sta	remdat+4	;...
	lxi	d,rfntab	;Point to the appropriate tables
	lxi	h,rfnhlp	;...
	jmp	remsc1		;and do common code
;
;Remote Set File Record Format command
;
remsrf:
IF lasm
	lxi	h,'31'		;Set command code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'13'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'3'		;...
	sta	remdat+4	;...
	lxi	d,rcftab	;Point to proper tables
	lxi	h,rcfhlp	;...
	jmp	remsc1		;and do common code
;
;Remote Set File Record Length command
;
remsrl:
IF lasm
	lxi	h,'31'		;Set command code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'13'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'2'		;...
	sta	remdat+4	;...
	jmp	remscm		;and do common code
;
;Remote Set File Replace command
;
remsfr:
IF lasm
	lxi	h,'30'		;Set command code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'03'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'3'		;...
	sta	remdat+4	;...
	lxi	d,rfrtab	;Point to tables
	lxi	h,rfrhlp	;...
	jmp	remsc1		;and do common code
;
;Remote Set File Type command
;
remsft:
IF lasm
	lxi	h,'30'		;Set command code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'03'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'0'		;...
	sta	remdat+4	;...
	lxi	d,rfttab	;Point to tables
	lxi	h,rfthlp	;...
	jmp	remsc1		;and go to common code
;
;Remote Set Receive Packet-length command
;
remrpl:
IF lasm
	lxi	h,'40'		;Set command code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'04'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'1'		;...
	sta	remdat+4	;...
	jmp	remscm		;and do common code
;
;Remote Set Receive Timeout command
;
remsrt:
IF lasm
	lxi	h,'40'		;Set code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'04'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'2'		;...
	sta	remdat+4	;...
	jmp	remscm		;and do common code
;
;Remote Set Retry command
;
remsry:
IF lasm
	lxi	h,'40'		;Set code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'04'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'3'		;...
	sta	remdat+4	;...
	jmp	remscm		;Go to common code
;
;Remote Set Server Timeout command
;
remsst:
IF lasm
	lxi	h,'40'		;Set code
ENDIF ;lasm
IF NOT lasm
	lxi	h,'04'
ENDIF ;NOT lasm
	shld	remdat+2	;...
	mvi	a,'4'		;...
	sta	remdat+4	;...
	jmp	remscm		;Do common code





; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FOR RELEASE

;	ORG	($+100H) AND 0FF00H


IF lasm
	LINK	CPSSER		
ENDIF	;lasm
