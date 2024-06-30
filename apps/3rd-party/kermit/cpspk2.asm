; CPSPK2.ASM
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
;edit 11, 21-Mar-1991 by MF. After "inchr7", close TAKE-file (if any) so
;	^C will halt all processing (including commands from TAKE-files)
;	and put the user back at Kermit command-level.
;edit 10, 3-Jan-1991 by MF. Modify routine "inchr" after label "inchr5" to
;	not take retry (nonskip) return if ^X/^Z seen on the Console. This
;	will prevent multiple copies of packets being sent if user aborts
;	some files in a stream being sent via ^X and is a better fix to this
;	problem than flushing comm input before sending the "Z" packet
;	requesting the remote Kermit to discard the current file being
;	received (as implemented in CPSPK1.ASM edit of 2-jan-1991).
;edit 9, 14-Dec-1990 by MF. Modified "gofil" routine to allow for
;	specification of a drive in the local filespec for GET and
;	RECEIVE commands. Thus commands such as
;	GET HELLO.TXT B:GOODBYE.TXT
;	and
;	RECEIVE B:GOODBYE.TXT
;	now work as expected.
;edit 8, 22-Oct-1990 by MF.  Fixed bug in completion-message routine
;	"finmes" wherein the completion message was not printed if the
;	terminal was set to QUIET because the message pointer was clobbered
;	by prcrlf.
;edit 7, 14-Sep-1990 by MF.  Add hooks for SET COLLISION command.
;	Eliminate commented-out old file warning rename routine.
;	Clear communication input buffers (call flsmdm) before
;	BYE, FINISH and LOGOUT commands.
;edit 6, 9-Sep-1990 by MF.  Implemented fixes in CPKERM.BWR for
;	garbage printout during quiet transfers and for file existence/
;	rename algorithm.
;	Also implemented hooks for Remote commands.
; edit 5, 18 June 1990 by Russell Lang [rjl@monu1.cc.monash.edu.au]
;	When trying to generate a unique file name on receive, zero
;	the attribute bits between file opening attempts.  This is
;	to fix a bug which caused the unique file name to have the
;	attributes of the already existing file.  If the attribute
;	was R/O, a bdos error occured later when an attempt was made
;	to write to the file.
;
; edit 4, 27 October, 1987 By OBSchou.  Changed the rename routine to 
;	be more like the MSDOS issue.
;
; edit 3, 28 July, by OBSchou.  Added traps to NOT print to screen during
;	file transfers if quietd is non zero (ie we SET TERMINAL QUIET)
;	This hopefully speeds up transfers in systems spending an age
;	updating the screen.
;
; edit 2, 8 April, 1987 by OBSchou.  Minor edit to put drive and user number
;	in the "filename" field on the transfer screen.  This means that the
;	offset on the line foe the file name proper has moved along 4 space.  
;	Also, it writes 15 spaces AFER the xxd: string to clear the field 
;	of any prevous file.  Needed for thos terminals that cannot
;	clear to end of line...
;
; edit 1, 28 January, 1987 by OBSchou.
;	Hived off about 1/2 of CPSPKT.ASM to form two (smaller => easier
;	to handle) files.  
;
;

pk2ver:	db	'CPSPK2.ASM (11)  21-Mar-1991$'     ; name, edit number, date


;
;       Get the file name (including host to micro translation)
;       called by: rfile

gofil:	xra	a
	sta	fcb		;Set the drive to default to current.
	lxi	h,data		;Get the address of the file name.
; allow use of local name if one was given [gnn]
	lda	remlen		;[gnn] 
	ora	a		;[gnn] anything there?
	jz	gofil0		;[gnn]  no, use the one in the data packet
	lxi	h,remnam	;[gnn] yes, use this instead
	lda	remnam+1	;[MF]Get 2nd char of local filename
	cpi	':'		;[MF]Was a drive specified?
	jnz	gofil0		;[MF]No, proceed as of old
	mov	a,m		;[MF]Yes, get drive
	ani	5fh		;[MF]Force uppercase
	sui	'A'-1		;[MF]Make valid drive for fcb
	sta	fcb		;[MF]and store in fcb
	inx	h		;[MF]Skip drive and delimiter
	inx	h		;[MF]...
gofil0:				;[gnn]  continue to set up the file [gnn]
;
	shld	datptr		;Store the address.
	lxi	h,fcb+1		;Address of the FCB.
	shld	fcbptr		;Save it.
	xra	a
	sta	temp1		;Initialize the char count.
	sta	temp2
	mvi	b,' '
gofil1:	mov	m,b		;Blank the FCB.
	inx	h
	inr	a
;       cpi     0CH             ;Twelve?[5a]
	cpi	0BH		; Eleven? [5a]
	jm	gofil1
	mvi	m,0		; [5a] Specify extent 0
gofil2:	lhld	datptr		;Get the NAME field.
	mov	a,m
	cpi	'a'             ;Force upper case
	jm	gofl2a		;
	ani	5FH		;
gofl2a:	inx	h
	cpi	'.'             ;Seperator?
	jnz	gofil3
	shld	datptr		;[jd] update ptr (moved from above)
	lxi	h,fcb+9H
	shld	fcbptr
	lda	temp1
	sta	temp2
	mvi	a,9H
	sta	temp1
	jmp	gofil6

gofil3:	ora	a		;Trailing null?
	jz	gofil7		;Then we're done.
	shld	datptr		;[jd] no, can update ptr now.
	lhld	fcbptr
	mov	m,a
	inx	h
	shld	fcbptr
	lda	temp1		;Get the char count.
	inr	a
	sta	temp1
	cpi	8H		;Are we finished with this field?
	jm	gofil2
gofil4:	sta	temp2
	lhld	datptr
	mov	a,m
	inx	h
	shld	datptr
	ora	a
	jz	gofil7
	cpi	'.'             ;Is this the terminator?
	jnz	gofil4		;Go until we find it.
gofil6:	lhld	datptr		;Get the TYPE field.
	mov	a,m
	cpi	'a'             ;Force upper case
	jm	gofl6a		;
	ani	5FH		;
gofl6a:	ora	a		;Trailing null?
	jz	gofil7		;Then we're done.
;[jd] move above two lines so we don't increment pointer if char is null
	inx	h
	shld	datptr
	lhld	fcbptr
	mov	m,a
	inx	h
	shld	fcbptr
	lda	temp1		;Get the char count.
	inr	a
	sta	temp1
	cpi	0CH		;Are we finished with this field?
	jm	gofil6
gofil7:	lhld	datptr
	mvi	m,'$'           ;Put in a dollar sign for printing.
	lda	quietd		; quiet display?
	ana	a
	jnz	gofi70		; yes, so skip it.
	call	scrfln		;Position cursor
gofi70:	lxi	d,data		;Print the file name
	lda	getrxflg	;[obs 8] are we doing a get or receive?
	ana	a		;[obs 8]
	jz	gofi7a		;[obs 8] if zero, receive
	lxi	d,remnam	;[obs 8]
gofi7a: 		;[obs 8]

	call	prtstr
gofi7b:	xra	a		;[MF]Zero "discard" flag
	sta	dscflg		;[MF]...
	lda	flwflg		;Is file warning on?
	ora	a
	jz	gofil9		;If not, just proceed.
	mvi	c,openf		;See if the file exists.
	lxi	d,fcb
	call	bdos
	cpi	0FFH		;Does it exist?
	jz	gofil9		;If not create it.
;
	lda	flwflg		;[MF]Get flag again
	cpi	3		;[MF]SET COLLISION DISCARD?
	jnz	gofi7h		;[MF]No
	mvi	a,0ffh		;[MF]Yes, order rejection of the file
	sta	dscflg		;[MF]...
	jmp	rskp		;[MF]and pretend successful open
gofi7h:	push	psw		;[MF]Save Collision status
	lxi	d,infms5
	call	error3
	pop	psw		;[MF]Restore Collision status
	cpi	1		;[MF]SET COLLISION RENAME?
	jz	gofi7i		;[MF]Yes, same as SET WARNING ON
				;[MF]If we come here, SET COLLISION BACKUP
	lxi	h,fcb		;[MF]Copy original fcb to a safe place
	lxi	d,colfcb	;[MF]...
	lxi	b,33		;[MF]...
	call	mover		;[MF]...
				;[MF]and fall into rename code
gofi7i:				;[MF]
;
;	Replacement  file name renamer routine.  Incomming
;	files are renamed in this manner:
;	original file name:	filex.ext
;	first rename:		filex001.ext
;	...		...
;	ninth rename		filex009.ext
;	10th rename		fail - would we really want 10
;				files of the same name??
;
;
;	1)
;	Assume that we need to "rename" the file, so lets make sure
;	that there is a full. 8 character filename. (We make it if 
;	it does not already exist)
;		1a) If full file name, last character is to be replaced
;		by a zero.  This gives us up to no#ine renames.
;	2)open file
;		2a)If exists, increment last character by one
;		2b)if = '9' then abort
;		2c)If does not exist, got 2)
;	3)we have a valid 'renamed' file
;
;Part 1) - fill out filename part 

	mvi	c,8		; max 8 characters to test for
	mvi	a,'0'		; spaces to be replaced by a zero.
	lxi	h,fcb+8		; start at the end
gofi7c:	mov	m,a		; put a zero in here
	dcr	c		; come to the end?
	jz	gofi7d		; should not have, but just in case...
	dcx	h		; previous chararcter
	mov	a,m		; get it
	cpi	' '		; if this character a space as well, zero it
	mvi	a,'0'		; set it to ascii zero just in case...
	jz	gofi7c		;
;
; Part 2) open the file (if success, then it exists)

gofi7d:
;zero the attribute bits.  [rjl@monu1.cc.monash.edu.au]
	lxi	h,fcb+1		;[rjl]
	mvi	c,11		;[rjl]
gofi7z:	mov	a,m		;[rjl]
	ani	07fh		;[rjl]
	mov	m,a		;[rjl]
	inx	h		;[rjl]
	dcr	c		;[rjl]
	jnz	gofi7z		;[rjl]
	lxi	d,fcb
	mvi	c,openf
	call	BDOS
	inr	a		; if 0ffh returned, error (ie does not exist)
	jz	gofi7e
	lda	fcb+8		; get last character
	inr	a
	sta	fcb+8
	cpi	'9'+1		; more than '9' => too far, lets give up.
	jnz	gofi7d		; else try again
;Giving up, so lets exit
	lxi	d,erms16	;
	call	prtstr
	ret		; return to error routine

gofi7e:	lxi	d,fnbuf		; make the file name into a character string
	lxi	h,fcb+1		; point to source file name, less drive name
	mvi	c,8		; 11 characters (8+3) + dot to copy across
;
gofi7f:	mov	a,m		; get character
	stax	d
	inx	h
	inx	d
	dcr	c
	jnz	gofi7f		; loop until all done

	mvi	a,'.'		; then the dot
	stax	d
	inx	d

	mvi	c,3		; then the file extention

gofi7g:	mov	a,m
	stax	d
	inx	h
	inx	d
	dcr	c
	jnz	gofi7g		; loop until extention copied across

	mvi	a,'$'		; dollar terminate string
	stax	d
	lxi	d,fnbuf		;[MF]Point to string
	call	prtstr		; write string to console

	lda	flwflg		;[MF]Get warning (SET COLLISION) flag
	cpi	2		;[MF]SET COLLISION BACKUP?
	jnz	gofil9		;[MF]No
	lxi	h,fcb		;[MF]Yes, get new filename fcb
	lxi	d,colfcb+16	;[MF]Where to copy to for rename
	lxi	b,16		;[MF]Copy 16 bytes
	call	mover		;[MF]...
	lxi	d,colfcb	;[MF]Point to rename fcb
	mvi	c,renam		;[MF]Rename function
	call	bdos		;[MF]Try to rename original file
	cpi	0ffh		;[MF]Did we win?
	jnz	gofl82		;[MF]Yes
	lxi	d,erms16	;[MF]No, complain and bomb
	jmp	error3		;[MF]...
gofl82:	lxi	h,colfcb	;[MF]Now recopy original filename into fcb
	lxi	d,fcb		;[MF]to create new file with original name
	lxi	b,16		;[MF]...
	call	mover		;[MF]...
;
;
;Now lets make the file (create it)

gofil9:	call	makfil		; Create the file.
	jmp	gofl91		; Disk was full.
	jmp	rskp		; Success.
    
gofl91:	lxi	d,erms11
	call	error3
	ret
;
;       This is the FINISH command.  It tells the remote KERSRV to exit.
;       here from kermit

finish:	call	cfmcmd
	call	selmdm		;[MF]Select modem
	call	flsmdm		;[MF]Flush buffers
	call	selcon		;[MF]Select keyboard again
	xra	a
	sta	numtry		;Inititialize count.
	mvi	a,'1'           ;Reset block check type to single character
	sta	curchk		; .  .  .

finsh1:	lda	numtry		;How many times have we tried?
	cpi	maxtry		;Too many times?
	jm	finsh3		;No, try it.
finsh2:	lxi	d,erms18	;Say we couldn't do it.
	call	prtstr
	jmp	kermit		;Go home.

finsh3:	inr	a		;Increment the number of tries.
	sta	numtry
	xra	a
	sta	argblk		;Make it packet number zero.
	mvi	a,1
	sta	argblk+1	;One piece of data.
	lxi	h,data
	mvi	m,'F'           ;Finish running Kermit.
	mvi	a,'G'           ;Generic command packet.
	call	spack
	jmp	finsh2		; Tell the user and die.
	call	rpack		;Get an acknowledgement.
	jmp	finsh1		; Go try again.
	cpi	'Y'             ;ACK?
	jz	kermit		;Yes, we are done.
	cpi	'E'             ;Is it an error packet?
	jnz	finsh1		;Try sending the packet again.
	call	error1		;Print the error message.
	jmp	kermit
;
;       This is the LOGOUT command.  It tells the remote KERSRV to logout.
;       here from: kermit

logout:	call	cfmcmd
	call	logo		;Send the logout packet.
	jmp	kermit		;Go get another command
	jmp	kermit		; whether we succeed or not.

;       do logout processing.
;       called by: bye, logout

logo:	call	selmdm		;[MF]Select modem
	call	flsmdm		;[MF]Flush buffers
	call	selcon		;[MF]Select keyboard again
	xra	a
	sta	numtry		;Inititialize count.
	mvi	a,'1'           ;Reset block check type to single character
	sta	curchk		; .  .  .

logo1:	lda	numtry		;How many times have we tried?
	cpi	maxtry		;Too many times?
	jm	logo3		;No, try it.
logo2:	lxi	d,erms19	;Say we couldn't do it.
	call	prtstr
	ret		;Finished.

logo3:	inr	a		;Increment the number of tries.
	sta	numtry
	xra	a
	sta	argblk		;Make it packet number zero.
	mvi	a,1
	sta	argblk+1	;One piece of data.
	lxi	h,data
	mvi	m,'L'           ;Logout the remote host.
	mvi	a,'G'           ;Generic command packet.
	call	spack
	jmp	logo2		; Tell the user and die.
	call	rpack		;Get an acknowledgement
	jmp	logo1		; Go try again.
	cpi	'Y'             ;ACK?
	jz	rskp		;Yes, we are done.
	cpi	'E'             ;Is it an error packet?
	jnz	logo1		;Try sending the packet again.
	call	error1		;Print the error message.
	ret		;All done.
;
;       Packet routines

;       Send_Packet
;       This routine assembles a packet from the arguments given and sends it
;       to the host.
;
;       Expects the following:
;               A        - Type of packet (D,Y,N,S,R,E,F,Z,T)
;               ARGBLK   - Packet sequence number
;               ARGBLK+1 - Number of data characters
;       Returns: nonskip if failure
;                skip if success
;       called by: read, rinit, rfile, rdata, sinit, sfile, sdata, seof, seot,
;                  finish, logout, nak, ackp

spack:	sta	argblk+2
	lxi	h,packet	;Get address of the send packet.
	lda	sndsop		;[gnn] send start-of-pkt char.
	mov	m,a		;Put in the packet.
	inx	h		;Point to next char.
	lda	curchk		;Get current checksum type
	sui	'1'             ;Determine extra length of checksum
	mov	b,a		;Copy length
	lda	argblk+1	;Get the number of data chars.
	adi	' '+3           ;Real packet character count made printable.
	add	b		;Determine overall length
	mov	m,a		;Put in the packet.
	inx	h		;Point to next char.
	lxi	b,0		;Zero the checksum AC.
	mov	c,a		;Start the checksum.
	lda	argblk		;Get the packet number.
	adi	' '             ;Add a space so the number is printable.
	mov	m,a		;Put in the packet.
	inx	h		;Point to next char.
	add	c
	mov	c,a		;Add the packet number to the checksum.
	mvi	a,0		;Clear A (Cannot be XRA A, since we can't
				; touch carry flag)
	adc	b		;Get high order portion of checksum
	mov	b,a		;Copy back to B
	lda	argblk+2	;Get the packet type.
	mov	m,a		;Put in the packet.
	inx	h		;Point to next char.
	add	c
	mov	c,a		;Add the packet number to the checksum.
	mvi	a,0		;Clear A
	adc	b		;Get high order portion of checksum
	mov	b,a		;Copy back to B
spack2:	lda	argblk+1	;Get the packet size.
	ora	a		;Are there any chars of data?
	jz	spack3		; No, finish up.
	dcr	a		;Decrement the char count.
	sta	argblk+1	;Put it back.
	mov	a,m		;Get the next char.
	inx	h		;Point to next char.
	add	c
	mov	c,a		;Add the packet number to the checksum.
	mvi	a,0		;Clear A
	adc	b		;Get high order portion of checksum
	mov	b,a		;Copy back to B
	jmp	spack2		;Go try again.

spack3:	lda	curchk		;Get the current checksum type
	cpi	'2'             ;Two character?
	jz	spack4		;Yes, go handle it
	jnc	spack5		;No, go handle CRC if '3'
	mov	a,c		;Get the character total.
	ani	0C0H		;Turn off all but the two high order bits.
				;Shift them into the low order position.
	rlc		;Two left rotates same as 6 rights
	rlc		; .  .  .
	add	c		;Add it to the old bits.
	ani	3FH		;Turn off the two high order bits.  (MOD 64)
	adi	' '             ;Add a space so the number is printable.
	mov	m,a		;Put in the packet.
	inx	h		;Point to next char.
	jmp	spack7		;Go store eol character

;Here for 3 character CRC-CCITT

spack5:	mvi	m,0		;Store a null for current end
	push	h		;Save H
	lxi	h,packet+1	;Point to first checksumed character
	call	crcclc		;Calculate the CRC
	pop	h		;Restore the pointer
	mov	c,e		;Get low order half for later
	mov	b,d		;Copy the high order
	mov	a,d		;Get the high order portion
	rlc		;Shift off low 4 bits
	rlc		; .  .  .
	rlc		; .  .  .
	rlc		; .  .  .
	ani	0FH		;Keep only low 4 bits
	adi	' '             ;Put into printing range
	mov	m,a		;Store the character
	inx	h		;Point to next position

;Here for two character checksum

spack4:	mov	a,b		;Get high order portion
	ani	0FH		;Only keep last four bits
	rlc		;Shift up two bits
	rlc		; . .  .
	mov	b,a		;Copy back into safe place
	mov	a,c		;Get low order half
	rlc		;Shift  high two bits
	rlc		;to low two bits
	ani	03H		;Keep only two low bits
	ora	b		;Get high order portion in
	adi	' '             ;Convert to printing character range
	mov	m,a		;Store the character
	inx	h		;Point to next character
	mov	a,c		;get low order portion
	ani	3FH		;Keep only six bits
	adi	' '             ;Convert to printing range
	mov	m,a		;Store it
	inx	h		;Bump the pointer

spack7:	lda	dbgflg
	ora	a		; is debugging enabled?
	jz	spack8
	push	h		; yes. save address of end of packet
	mvi	m,0		; null-terminate the packet for display
	lda	quietd		; a quiet display?
	ana	a
	jnz	spac7a		; so dont say a thing
	call	sppos		; position cursor
	lxi	h,packet+1	; print the packet
	call	dmptxt
	lda	prnflg		; is the printer on too?
	ana	a
	jz	spac7a
	lxi	h,sstatm		; print state
	call	printm		; dumptext but to printer
	lda	state
	mov	e,a
	call	outprn
	lxi	h,princr	; cr lf to printer
	call	printm
	lxi	h,spackm
	call	printm
	lxi	h,packet+1
	call	printm
	lxi	h,princr
	call	printm
	lxi	h,princr
	call	printm

spac7a:	pop	h		; restore address of end of packet
spack8:	lda	seol		;Get the EOL the other host wants.
	mov	m,a		;Put in the packet.
	inx	h		;Point to next char.
	xra	a		;Get a null.
	mov	m,a		;Put in the packet.
;       Write out the packet.
outpkt:	call	selmdm		; Set up for output to comm port if iobyt
	lda	spad		;Get the number of padding chars.
	sta	temp1
outpk2:	lda	temp1		;Get the count.
	dcr	a
	ora	a
	jm	outpk6		;If none left proceed.
	sta	temp1
	lda	spadch		;Get the padding char.
	call	setpar		;Set parity appropriately
	mov	e,a		;Put the char in right AC.
	call	outmdm		;Output it.
	jmp	outpk2

outpk6:	lxi	h,packet	; Point to the packet.
outlup:	mov	a,m		; Get the next character.
	ora	a		; Is it a null?
	jz	outlud		; If so return success.
	call	setpar		; Set parity for the character
	mov	e,a		; Put it in right AC
	call	outmdm		; and output it.
; TAC trap: If this character is the TAC intercept character, and the TAC
; trap is enabled, we have to output it twice.  If the TAC trap is enabled,
; tacflg contains the intercept character.  (The current character cannot
; be NUL, so we don't have to worry about doubling nulls in the message)
	lda	tacflg		; get current intercept character, or zero.
	cmp	m		; compare against current data character.
	jnz	outpk8		; if different, do nothing.
	call	setpar		; match. set appropriate parity,
	mov	e,a		;  put it in the right register,
	call	outmdm		;  and output it a second time.
outpk8:
	inx	h		; Increment the char pointer.
	jmp	outlup

outlud:	call	selcon		; select console
	jmp	rskp		; and return success
;
;       Receive_Packet
;       This routine waits for a packet to arrive from the host.  It reads
;       characters until it finds a SOH.  It then reads the packet into packet.
;
;       Returns:  nonskip if failure (checksum wrong or packet trashed)
;          skip if success, with
;               A        - message type
;               ARGBLK   - message number
;               ARGBLK+1 - length of data
;       called by: rinit, rfile, rdata,
;                  sinit, sfile, sdata, seof, seot, finish, logout

rpack:	call	inpkt		;Read up to the end-of-line character
	jmp	r		; Return bad.
rpack0:	call	getchr		;Get a character.
	jmp	rpack		; Hit eol;null line;just start over.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jnz	rpack0		; No, go until it is.
rpack1:	call	getchr		;Get a character.
	jmp	r		; Hit end of line, return bad.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jz	rpack1		; Yes, then go start over.
	sta	packet+1	;Store in packet also
	mov	c,a		;Start the checksum.
	lda	curchk		;Get block check type
	sui	'1'             ;Determine extra length of block check
	mov	b,a		;Get a copy
	mov	a,c		;Get back length character
	sui	' '+3           ;Get the real data count.
	sub	b		;Get total length
	sta	argblk+1
	mvi	b,0		;Clear high order half of checksum
	call	getchr		;Get a character.
	jmp	r		; Hit end of line, return bad.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jz	rpack1		; Yes, then go start over.
	sta	argblk
	sta	packet+2	;Save also in packet
	add	c
	mov	c,a		;Add the character to the checksum.
	mvi	a,0		;Clear A
	adc	b		;Get high order portion of checksum
	mov	b,a		;Copy back to B
	lda	argblk
	sui	' '             ;Get the real packet number.
	sta	argblk
	call	getchr		;Get a character.
	jmp	r		; Hit end of line, return bad.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jz	rpack1		; Yes, then go start over.
	sta	temp1		;Save the message type.
	sta	packet+3	;Save in packet
	add	c
	mov	c,a		;Add the character to the checksum.
	mvi	a,0		;Clear A
	adc	b		;Get high order portion of checksum
	mov	b,a		;Copy back to B
	lda	argblk+1	;Get the number of data characters.
	sta	temp2
	lxi	h,data		;Point to the data buffer.
	shld	datptr
rpack2:	lda	temp2
	sui	1		;Any data characters?
	jm	rpack3		; If not go get the checksum.
	sta	temp2
	call	getchr		;Get a character.
	jmp	r		; Hit end of line, return bad.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jz	rpack1		; Yes, then go start over.
	lhld	datptr
	mov	m,a		;Put the char into the packet.
	inx	h		;Point to the next character.
	shld	datptr
	add	c
	mov	c,a		;Add the character to the checksum.
	mvi	a,0		;Clear A
	adc	b		;Get high order portion of checksum
	mov	b,a		;Copy back to B
	jmp	rpack2		;Go get another.

rpack3:	call	getchr		;Get a character.
	jmp	r		; Hit end of line, return bad.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jz	rpack1		; Yes, then go start over.
	sui	' '             ;Turn the char back into a number.
	sta	temp3
;Determine type of checksum

	lda	curchk		;Get the current checksum type
	cpi	'2'             ;1, 2 or 3 character?
	jz	rpack4		;If zero, 2 character
	jnc	rpack5		;Go handle 3 character
	mov	a,c		;Get the character total.
	ani	0C0H		;Turn off all but the two high order bits.
				;Shift them into the low order position.
	rlc		;Two left rotates same as six rights
	rlc		; .  .  .
	add	c		;Add it to the old bits.
	ani	3FH		;Turn off the two high order bits.  (MOD 64)
	mov	b,a
	lda	temp3		;Get the real received checksum.
	cmp	b		;Are they equal?
	jz	rpack7		;If so, proceed.
rpack9:	call	updrtr		;If not, update the number of retries.
	ret		;Return error.

;Here for three character CRC-CCITT

rpack5:	lhld	datptr		;Get the address of the data
	mvi	m,0		;Store a zero in the buffer to terminate packet
	lxi	h,packet+1	;Point at start of checksummed region
	call	crcclc		;Calculate the CRC
	mov	c,e		;Save low order half for later
	mov	b,d		;Also copy high order
	mov	a,d		;Get high byte
	rlc		;Want high four bits
	rlc		; .  .  .
	rlc		;And shift two more
	rlc		; .  .  .
	ani	0FH		;Keep only 4 bits
	mov	d,a		;Back into D
	lda	temp3		;Get first value back
	cmp	d		;Correct?
	jnz	rpack9		;No, punt
	call	getchr		;Get a character.
	jmp	r		; Hit end of line, return bad.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jz	rpack1		; Yes, then go start over.
	sui	' '             ;Remove space offset
	sta	temp3		;Store for later check
	;...

;Here for a two character checksum and last two characters of CRC

rpack4:	mov	a,b		;Get high order portion
	ani	0FH		;Only four bits
	rlc		;Shift up two bits
	rlc		; .  .  .
	mov	b,a		;Save back in B
	mov	a,c		;Get low order
	rlc		;move two high bits to low bits
	rlc		; .  .  .
	ani	03H		;Save only low two bits
	ora	b		;Get other 4 bits
	mov	b,a		;Save back in B
	lda	temp3		;Get this portion of checksum
	cmp	b		;Check first half
	jnz	rpack9		;If bad, go give up
	call	getchr		;Get a character.
	jmp	r		; Hit end of line, return bad.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jz	rpack1		; Yes, then go start over.
	sui	' '             ;Remove space offset
	mov	b,a		;Save in safe place
	mov	a,c		;Get low 8 bits of checksum
	ani	3FH		;Keep only 6 bits
	cmp	b		;Correct value
	jnz	rpack9		;Bad, give up
rpack7:	lhld	datptr
	mvi	m,0		;Put a null at the end of the data.
	lda	temp1		;Get the type.
	jmp	rskp
;
;       inpkt - receive and buffer packet
;       returns: nonskip if error (timeout)
;               skip if success; packet starts at recpkt (which holds the SOH)
;               and is terminated by a null.
;               console is selected in either case.
;       called by: rpack

inpkt:	lxi	h,recpkt	;Point to the beginning of the packet.
	shld	pktptr
inpkt1:	call	inchr		;Get first character
	jmp	r		;Return failure
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jnz	inpkt1		;if not, ignore leading junk
	jmp	inpkt3		;else go put it in packet

inpkt2:	call	inchr		;Get a character.
	jmp	r		; Return failure.
	lxi	h,rcvsop	;[gnn] Is it receive start-of-pkt char.
	cmp	m		;[gnn]
	jnz	inpkt3		;if not continue
	lxi	h,recpkt	;else throw away what we've got so far
	shld	pktptr		;
inpkt3:	lhld	pktptr		;
	mov	m,a		;Put the char in the packet.
	inx	h
	shld	pktptr
	mov	b,a
	lxi	d,-recpkx	;Start over if packet buffer overflow
	dad	d		;
	jc	inpkt		;buffer overflow
	lda	reol		;Get the EOL char.
	cmp	b
	jnz	inpkt2		;If not loop for another.
;[gnn]                  ***  added by Godfrey Nix   Nottingham University ***
;[gnn]                  to allow Kermit server to echo our packets back
	lxi	h,recpkt+3	;[gnn] point to packet type
	lda	packet+3	;[gnn] get the one we sent
	cmp	m		;[gnn] are they the same?
	jz	inpkt		;[gnn] yes, get another packet
;[gnn]                  *** end of patch *****
 ;...
	;...

;Begin IBM change/fdc
;This moved from OUTPK7 -- it appears that waiting until we're
;ready to send a packet before looking for turnaround character
;is long enough for it to get lost.  Better to look now.

	lda	ibmflg		;Is this the IBM?
	ora	a
	jz	inpkt6		;If not then proceed.
	lda	state		;Check if this is the Send-Init packet.
	cpi	'S'
	jz	inpkt6		;If so don't wait for the XON.
inpkt5:	call	inchr		;Wait for the turn around char.
	jmp	inpkt6
	cpi	xon		;Is it the IBM turn around character?
	jnz	inpkt5		;If not, go until it is.
inpkt6:	lhld	pktptr		;Reload packet pointer
;End IBM change/fdc.
	dcx	h		;Back up to end of line character
	mvi	m,0		;Replace it with a null to stop rpack:
	call	selcon		;We've got the packet. Return to console.

	lda	dbgflg		; Is debugging enabled?
	ora	a
	jz	inpkt7
	inx	h		; Point to next char.
	lda	quietd		; a quiet display?
	ana	a
	jnz	inpkt7		; so dont say a thing
	call	rppos		; position cursor
	lxi	h,recpkt+1	; print the packet
	call	dmptxt

	lda	prnflg		; is the printer on too?
	ana	a
	jz	inpkt7
	lxi	h,rstatm		; print state
	call	printm		; dumptext but to printer
	lda	state
	mov	e,a
	call	outprn
	lxi	h,princr	; cr lf to printer
	call	printm
	lxi	h,rpackm
	call	printm
	lxi	h,recpkt+1
	call	printm
	lxi	h,princr
	call	printm
	lxi	h,princr
	call	printm


inpkt7:	lxi	h,recpkt
	shld	pktptr		;Save the packet pointer.
	jmp	rskp		;If so we are done.

;       getchr - get next character from buffered packet.
;       returns nonskip at end of packet.
;       called by: rpack

getchr:	lhld	pktptr		;Get the packet pointer.
	mov	a,m		;Get the char.
	inx	h
	shld	pktptr
	ora	a		;Is it the null we put at the end of the packet?
	jnz	rskp		;If not return retskp.
	ret		;If so return failure.
;
;
;       inchr - character input loop for file transfer
;       returns: nonskip if timeout or character typed on console
;                       (console selected)
;               skip with character from modem in A (parity stripped
;                       if necessary; modem selected)
;               preserves bc, de, hl in either case.
;       called by: inpkt

inchr:	push	h		; save hl and bc
	push	b
	lhld	timout		;Get initial value for timeout
	shld	timval		;[jd] 
inchr0:	call	selmdm		;select modem
	call	inpmdm		;Try to get a character from the modem
	ora	a
	jz	inchr2		;if zero, nothing there.
	mov	b,a
	lda	parity		;Is the parity none?
	cpi	parnon
	mov	a,b
	jz	inchr1		;If so just return.
	ani	7FH		;Turn off the parity bit.
inchr1:	pop	b		;restore registers
	pop	h
	jmp	rskp		;take skip return, character in A

inchr2:	call	selcon		;select console
	call	inpcon		; Try to get a character from the console
	ora	a
	jz	inchr6		;If not go do timer thing
	cpi	cr		;Is it a carriage return?
	jz	inchr4		;If so return
	cpi	('Z'-100O)      ;Control-Z?
	jz	inchr5		;Yes, go flag it
	cpi	('C'-100O)      ;Control-C?
	jz	inchr7		;re-enter, he wants to get out
	cpi	('X'-100O)      ;Control-X?
	jnz	inchr6		;No, ignore it. do timer thing.
inchr5:	adi	100O		;Convert to printing range
	sta	czseen		;Flag we saw a control-Z
	jmp	inchr6		;[MF] and do timer thing
inchr4:	pop	b		; restore registers
	pop	h
	ret		;And return

inchr6:	lda	timflg		;[jd] pick up timer flag
	ora	a		;[jd] are we allowed to use timer?
	jz	inchr0		;[jd] no, don't time out
	lhld	timval		; decrement fuzzy time-out
	dcx	h		;
	shld	timval		;((timout-1) * loop time)
	mov	a,h		;(Retry if not time-out)
	ora	l		;
	jnz	inchr0		;
	call	updrtr		;Count as retry (?)
	pop	b		;restore registers
	pop	h
	ret		;and return to do retry

inchr7:	call	clrtop		;[hh] clear screen and home cursor
	lda	takflg		;[MF]Take-file in progress?
	ani	1		;[MF]...
	cnz	closet		;[MF]Yes, close it and reset TAKE-flag
				;[MF]so all processing is halted
	jmp	kermit		;[hh] then re-enter kermit

;
;       CRCCLC - Routine to calculate a CRC-CCITT for a string.
;
;       This routine will calculate a CRC using the CCITT polynomial for
;       a string.
;
;       call with: HL/ Address of null-terminated string
;       16-bit CRC value is returned in DE.
;       Registers BC and HL are preserved.
;
;       called by: spack, rpack

crcclc:	push	h		;Save HL
	push	b		;And BC
	lxi	d,0		;Initial CRC value is 0

crccl0:	mov	a,m		;Get a character
	ora	a		;Check if zero
	jz	crccl1		;If so, all done
	push	h		;Save the pointer
	xra	e		;Add in with previous value
	mov	e,a		;Get a copy
	ani	0FH		;Get last 4 bits of combined value
	mov	c,a		;Get into C
	mvi	b,0		;And make high order zero
	lxi	h,crctb2	;Point at low order table
	dad	b		;Point to correct entry
	dad	b		; .  .  .
	push	h		;Save the address
	mov	a,e		;Get combined value back again
	rrc		;Shift over to make index
	rrc		; .  .  .
	rrc		; .  .  .
	ani	1EH		;Keep only 4 bits
	mov	c,a		;Set up to offset table
	lxi	h,crctab	;Point at high order table
	dad	b		;Correct entry
	mov	a,m		;Get low order portion of entry
	xra	d		;XOR with previous high order half
	inx	h		;Point to high order byte
	mov	d,m		;Get into D
	pop	h		;Get back pointer to other table entry
	xra	m		;Include with new high order half
	mov	e,a		;Copy new low order portion
	inx	h		;Point to other portion
	mov	a,m		;Get the other portion of the table entry
	xra	d		;Include with other high order portion
	mov	d,a		;Move back into D

	pop	h		;And H
	inx	h		;Point to next character
	jmp	crccl0		;Go get next character

crccl1:	pop	b		;Restore B
	pop	h		;And HL

	ret		;And return, DE=CRC-CCITT

CRCTAB:	DW	00000H
	DW	01081H
	DW	02102H
	DW	03183H
	DW	04204H
	DW	05285H
	DW	06306H
	DW	07387H
	DW	08408H
	DW	09489H
	DW	0A50AH
	DW	0B58BH
	DW	0C60CH
	DW	0D68DH
	DW	0E70EH
	DW	0F78FH

CRCTB2:	DW	00000H
	DW	01189H
	DW	02312H
	DW	0329BH
	DW	04624H
	DW	057ADH
	DW	06536H
	DW	074BFH
	DW	08C48H
	DW	09DC1H
	DW	0AF5AH
	DW	0BED3H
	DW	0CA6CH
	DW	0DBE5H
	DW	0E97EH
	DW	0F8F7H
;
;       This is where we go if we get an error during a protocol communication.
;       error prints the error packet on line 6 or so, and aborts the
;       transfer.
;         called by: rinit, rfile, rdata, sinit, sfile, sdata, seof, seot
;       error1 print CRLF followed by the error packet.
;         called by: finish, logout
;       error2 just prints the error packet.
;       error3 positions cursor and prints error message specified in DE.
;         called by: rinit, rfile, rdata, sinit, sfile, sdata, seof,
;                    seot, parwrn, gofil, outbuf

error:	lda	quietd		; a quiet display?
	ana	a
	jnz	error0		; so dont say a thing
	lda	remtxt		;[MF]Doing a remote command?
	ora	a		;[MF]...
	jnz	error0		;[MF]Yes, don't position cursor
	call	screrr		;Position the cursor.
error0:	mvi	a,'A'           ;Set the state to abort.
	sta	state
	jmp	error2

error1:	lxi	d,crlf		;Print a CRLF.
	lda	quietd		; a quiet display?
	ana	a
	jnz	error2		; so dont say a thing
		call	prtstr
error2:	lda	argblk+1	;Get the length of the data.
	mov	c,a
	mvi	b,0		;Put it into BC
	lxi	h,data		;Get the address of the data.
	dad	b		;Get to the end of the string.
	mvi	m,'$'           ;Put a dollar sign at the end.
	lxi	d,data		;Print error message
	lda	remtxt		;[MF]Doing a remote command?
	ora	a		;[MF]...
	jnz	errr2a		;[MF]Yes, print message, quiet or not!
	lda	quietd		; a quiet display?
	ana	a
	rnz		; so dont say a thing
errr2a:	call	prtstr
	ret

error3:	lda	quietd		; a quiet display?
	ana	a
	rnz		; so dont say a thing
	lda	remtxt		;[MF]Doing a remote command?
	ora	a		;[MF]...
	jnz	err3a		;[MF]Yes, don't position cursor
	push	d		;Save the pointer to the message.
	call	screrr		;Position the cursor.
	pop	d		;Get the pointer back.
err3a:	call	prtstr		;Print error message
	ret
;
;       Set up for file transfer.
;       called by read, send.

init:	lxi	d,version	; point at Kermit's version string
	lda	quietd		; a quiet display?
	ana	a
	jnz	init1		; so dont say a thing
	call	sysscr		; fix up screen
init1:	call	selmdm		; select modem
	call	flsmdm		; purge any pending data
	call	selcon		; select console again.
	ret

;       Set state to ABORT
;       called by: rinit, rfile, rdata, sinit, sfile, sdata, seof, seot,
;                  nak, ackp

abort:	mvi	a,'A'           ;Otherwise abort.
	sta	state
	ret

;       nak - send NAK packet
;       here from: rinit, rfile, rdata
;       nak0 - update retry count and send NAK packet
;       here from: rinit, rfile, rdata, tryagn

nak0:	call	updrtr		;Update number of retries.
nak:	lda	pktnum		;Get the packet number we're waiting for.
	sta	argblk
	xra	a		;No data.
	sta	argblk+1
	mvi	a,'N'           ;NAK that packet.
	call	spack
	jmp	abort		; Give up.
	ret		;Go around again.

;       increment and display retry count
;       called by: rfile, sinit, sfile, sdata, seof, seot,
;                  nak, rpack, inchr, tryagn

updrtr:	lhld	numrtr
	inx	h		;Increment the number of retries
	shld	numrtr
	lda	remtxt		;[MF]Doing a remote server command?
	ora	a		;[MF]...
	rnz		;[MF]Yes, keep mum
	lda	quietd		; a quiet display?
	ana	a
	rnz		; so dont say a thing
	call	scrnrt		;Position cursor
	lhld	numrtr		;[MF]
call	nout		;Write the number of retries.
	ret

;       [jd] this routine prints parity warnings.  All registers are
;       saved except for a.
;       called by: sdata

parwrn:	push	b
	push	d
	push	h
	lxi	d,inms25
	call	error3
	pop	h
	pop	d
	pop	b
	ret
;[jd] end of addition

;       print message in status field.  address of message is in DE.
;       called by: read, send

finmes:	lda	quietd		; a quiet display?
	ana	a
	jz	finme0		; so do usual stuff
	push	d		;[MF]Save pointer to completion message
	call	prcrlf		; best do a new line
	pop	d		;[MF]Restore completion message pointer
	call	prtstr		; and send message
	mvi	e,space		; send a space or two
	mvi	c,dconio
	push	b
	push	d
	call	bdos
	pop	d
	pop	b
	call	bdos
	ret		; and exit back
;
;else for screaming screens...

finme0:	push	d		;Save message.
	call	scrst		;Position cursor
	pop	d		;Print the termination message
	call	prtstr
	ret		; may not want this **************

	mvi	c,4		;[2] copy across user no and drive
	lxi	h,kerm1		;[2] as we have the text already
finme1:	mov	e,m
	push	h		;[2] conout probably destroys these
	push	b
	call	conout
	pop	b
	pop	h
	inx	h		;[2] next character
	dcr	c		;[2] ah, but have we done?
	jnz	finme1		;[2] nope
	lxi	d,spac15	;[2] send 15 spaces (clears previous filename)
	call	prtstr		;[2]
	call	scrend		;Position cursor for prompt
	ret

;       Compare expected packet number against received packet number.
;       return with flags set (Z = packet number valid)
;       called by: rfile, rdata, sinit, sfile, sdata, seof, seot

compp:	lda	pktnum		;Get the packet Nr.
	mov	b,a
	lda	argblk
	cmp	b
	ret

;       Increment the packet number, modulo 64.
;       called by: rinit, rfile, rdata, sinit, sfile, sdata, seof, seot

countp:	inr	a		;Increment packet Nr.
	ani	3FH		;Turn off the two high order bits
	sta	pktnum		;Save modulo 64 of number
	lhld	numpkt
	inx	h		;Increment Nr. of packets
	shld	numpkt
	ret

;       Send an ACK-packet
;       called by: rfile, rdata, tryagn

ackp:	xra	a
	sta	numtry		;Reset number of retries
	sta	argblk+1	;No data. (The packet number is in argblk)
	mvi	a,'Y'           ;Acknowledge packet
	call	spack		;Send packet
	jmp	abort
	ret

;       ?
;       called with A/ current retry count
;       called by: rfile, rdata

tryagn:	inr	a		;Increment it.
	sta	oldtry		;Save the updated number of tries.
	lda	pktnum		;Get the present packet number.
	dcr	a		;Decrement
	ani	3FH		; modulo 64
	mov	b,a
	lda	argblk		;Get the packet's number
	cmp	b		;Is the packet's number one less than now?
	jnz	nak0		;No, NAK it and try again.
	call	updrtr		;Update the number of retries.
	call	ackp
	ret

;       Output a null-terminated string to the console.  We assume that the
;       console has been selected.  Called with HL = address of string.
;       called by: spack, inpkt

dmptxt:	mov	a,m		; get character from string
	ora	a
	rz		; done if null
	push	h		; save string address
	mov	e,a		; move character to E for outcon
	call	outcon		; output character to console
	pop	h		; restore string address
	inx	h		; point past printed character
	jmp	dmptxt		; go output rest of string


;       Output a null-terminated string to the PRINTER  We assume that the
;       console has been selected.  Called with HL = address of string.
;       called by: spack, inpkt

printm:	mov	a,m		; get character from string
	ora	a
	rz		; done if null
	push	h		; save string address
	mov	e,a		; move character to E for outcon
	call	outprn		; output character to printer
	pop	h		; restore string address
	inx	h		; point past printed character
	jmp	printm		; go output rest of string


;
;       test if character in A is the start of header character.  We get
;       the start of packet character from sohchr, which can be SET
tstsoh:	push	b		; save these registers for a bit
	mov	c,a		; we have to test if this is the character
	lda	sohchr
	cmp	c		; if zero, then it is
	mov	a,c		; restore accumulator but not flags
	pop	b
	ret		; return with flags set
;


; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FRO RELEASE!

;	org ($+100h) AND 0FF00H


IF lasm
	LINK	CPSREM
ENDIF;lasm
