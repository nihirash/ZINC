; CPSUTL.ASM
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
;       Utility routines, pure and impure data.
;
; revision history:
;
;edit 31, 21-Mar-1991 by MF. Implement edit 30 without checking takflg after
;	"r1tch1" as we are **always** TAKEing from a file if we get to that
;	point in the code. Makes for simplicity.
;edit 30, 27-Feb-1991 by MF. When TAKEing characters from a TAKE-file,
;	view semicolons as normal characters (not command separators).
;	This will allow such commands as REMOTE DELETE *.*;* to work
;	properly from TAKE-files without having to revert to old code in
;	cpsrem.asm at "remcl0" to decode Remote command arguments. TAKE-files
;	ought not (in my opinion) to have multiple commands per line anyway.
;edit 29, 30-Jan-1991 by MF. Fix bug in IN1CHR which decremented "chrcnt"
;	once too often after a call to INBUF (which predecrements it
;	already). This, along with a fix in CPSTT.ASM, fixes a bug in the
;	TRANSMIT command wherein certain characters in the file were not
;	being transmitted. This bug was reported to me by Lance Tagliapietra
;	of the University of Wisconsin at Platteville, WI (Email:
;	<TAGLANCE@ucs.UWPLATT.EDU>).
;	(he suggested not predecrementing "chrcnt" in INBUF" but this
;	breaks code in routine "GTCHR" from CPSPK1.ASM so it's better
;	to modify IN1CHR in this module and XMIT in CPSTT.ASM).
;edit 28, 30-Nov-1990 by MF. Modify routine "p20ln" to use "pausit" routine
;	rather than explicitly checking for Console input to eliminate
;	redundant code. Also fix spelling in "p20ln"'s comments.
;edit 27, 9-Sep-90 by MF.  Put RET in routine PAUSIT per CPKERM.BWR.
; edit 26, September, 1987.  Added pause-it routine to wait for a user keysroke.
;
; edit 25, August 19, 1987 by OBSchou.  Fixed a few bugs here and there.
;
; edit 24, April 8, 1987 by OBSchou.  Added routine to return one character
;	from a section of several sectors worth of file.  This routine needed
;	for TRANSMIT.
;
; edit 23, March 11, 1986 by OBSchou for Richard Russell
;	Bug in the TAKE code, such that a new sector was read in after 256
;	bytes, and not the CPM value.  A jnz is now jp in the test to see if 
;	the file buffer has bben exhausted.  Many thanks for finding this 
;	bug.  I have never used TAKE files more than 128 bytes long.
;
; edit 22, January 28, 1986 by OBSchou.
;	split off the data areas from CPSUTL to CPSDAT.ASM  (All in line
;	with keeping individual files relatively small)
;
; edit 21 August, 1986 by OBSchou.  Sorted a few more bugs in printer buffer
;       etc.  Have yet to try this with a real printer  The code, apart from 
;       actually printing works OK.
;
; edit 26  20 August, 1986 by OBSchou for Godfrey Nix:
;       edit 8-Aug-86  by Godfrey N. Nix   [gnn]  Nottingham University
;       Added two extra bytes for storage of the send and receive
;       start-of-packet characters. Used by CP4PKT, and altered
;       by SET option in CP4MIT. Also added message strings for 
;       use by show routines. Added remote filename buffer and length byte.
;
; edit 11: June 20, 1986 by OBSchou.  Added multi-fcbs for the DIR command
;       together with some bug clearing and new routines.  Had to move
;       the overlay to 5000h as we ran out of space...
;
; edit 10: June 16, 1986 OBSchou.  Added a pseudo clock and check for printer
;       ready whenever one enters BDOS...  This may slow things down a little
;       but adds in (hopefully) pseudo background printing...
;
; edit 9 30-May-86 OBSchou.  Added XON/XOFF routines here for the world 
;       at large to use.  Also added two new entries in the overlay tables.  
;       One to give the address of the family of machines using the overlay, 
;       the other to the routine for giving printer status.
;
; edit 8: 27-May-86 OBSchou.  Added code to check BDOS calls for info from
;       the console.  If so, and the take flag (takflg) is set then we 
;       substitute our own characters.  Simple, a little tatty...
;       Also added bits for SET CASE-SENSITIVE and SET FLOW=CONTROL, and 
;       removed the XMIT rubbish.  This is a prelude to better TRANSMIT
;
; edit 7: 22 April, 1986 by OBSchou Lohghborough University
;       Prlude to more changee, this time make overlay address to 4000h
;       May revert back to ($+0ffh) AND 0ff00h as address for overlay.
;       This gives us space to make quite a few modifications to the system
;       dependent part without much fear of having to change this overlay
;       address.  Should also fix the Osborne problem of having to have io 
;       routines ii memory above 16k.  I know I should not be introducing
;       such system dependent rot here, but it wont be too difficult to fill
;       memory to 4000h.
;
; edit 6: February 6, 1985
;       Added a storage location for the port value (PORT, just below
;       SPEED) which is used by the port status routine, and moved the
;       printer copy flag (PRNFLG:) into the communications area so
;       that the machine dependant overlay can toggle it. [Hal Hostetler]
;       Added ffussy flag for filename checking.  Generate the version
;       string from 'verno', which is set in CP4KER, because CP4KER has the
;       list of modules and their edit numbers. [Charles Carvalho]
;
; edit 5: 13-Jan-85 by Vanya J.Cooper Pima Commun. College Tel: 602-884-6809
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
;pcc006 2-jan-85        VJC     modules:cp4cmd,cp4utl
;       Problems with "?" in filespecs.  On reparse, may cause action
;       flag to be reset at wrong point, requiring multiple <CR>'s
;       to terminate the line or other weird stuff.  Also need to
;       check flag and complain if wild-cards illegal.
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
;pcc013 8-Jan-85        vjc     modules:cp4mit,cp4utl,cp4typ
;       Replace CLOSE command to cancel session logging to SET
;       LOGGING ON/OFF.  This seems to fit in with the command
;       structure better.  Default the log file to KERMIT.LOG
;       incase no previous LOG command.  Logging is also enabled
;       by LOG command, as before.
;
; edit 4: September 9, 1984
;       Move command tables and associated help text to CP4MIT.  Add
;       makfil/clofil routines and modify outbuf to write files in big
;       chunks.  Update Kermit's version to 4.03.
;
; edit 3: August 21, 1984
;       Make inbuf read files in big chunks to minimize disk start/stop
;       delays.  Buffer size and address is specified by system-dependent
;       overlay.
;
; edit 2: August 3, 1984
;       move "mover" to CP4SYS to allow use of Z80 block move instruction.
;
; edit 1: July 27, 1984
;       extracted from CP4MIT.M80 edit 2, as part of LASM support.  This is
;       the last file linked for the system-independent code.
;
utlver:	db	'CPSUTL.ASM (31) 21-Mar-1991$'

;       Set the parity for a character in A.
;       called by: spack, rexmit, logit, vt52, conchr, intchr

setpar:	push	h		;Save HL.
	push	b
	lxi	h,parity
	mov	c,m		;Get the parity routine.
	mvi	b,0
	lxi	h,parjmp	;Get the first address.
	dad	b
	pchl

parjmp:	jmp	even
	jmp	mark
	jmp	none
	jmp	odd
	jmp	spacep

none:	jmp	parret		;Don't touch the parity bit.

even:	ani	7FH		;Strip parity.
	jpe	parret		;Already even, leave it.
	ori	80H		;Make it even parity.
	jmp	parret

mark:	ori	80H		;Turn on the parity bit.
	jmp	parret

odd:	ani	7FH		;Strip parity.
	jpo	parret		;Already odd, leave it.
	ori	80H		;Make it odd parity.
	jmp	parret

spacep:	ani	7FH		;Turn off the parity bit.
	jmp	parret

parret:	pop	b
	pop	h		;Restore HL.
	ret
;
;       Print the escape char.
;       called by: stat01, telnet, intchr

escpr:	lda	escchr		;Get the escape char.
escpr1:	cpi	' '             ;Is it a control char?
	jp	escpr2
	push	psw		; save the character
	lxi	d,inms10	;Output "Control-".
	call	prtstr
	pop	psw		; restore the character
	ori	100O		;De-controlify.
escpr2:	mvi	c,conout	;Output the char
	mov	e,a
	call	bdos
	ret

;       fetch keyword; if unsuccessful, return to command level.
;       called by: kermit, setcom

keycmd:	mvi	a,cmkey
	call	comnd
	jmp	keycm2		;no match
	ret

keycm2:	lxi	d,ermes1	;"Unrecognized Command"
	call	prtstr
	jmp	kermit		;Do it again.

;       request confirmation; if unsuccessful, return to command level
;       called by: bye, exit, help, log, setcom, show, status, send,
;               finish, logout, telnet

cfmcmd:	mvi	a,cmcfm
	call	comnd
	jmp	kermt3		;"Not confirmed"
	ret
;

;       This routine prints the number in HL on the screen in decimal.
;       Uses all ACs.
;       called by: cp4sys, read, send, updrtr, dir, user

nout:	mvi	a,'0'           ; fill tempx with zeros
	call	filltmp

	lxi	b,-10		;Get some useful constants.
nout1:	lxi	d,-1

nout2:	dad	b		;Subtract as many 10s as possible.
	inx	d		;Count them.
	jc	nout2		;If some left keep going.
	push	h		;save remainder - 10
	xchg		;Swap the remainder and the quotient.
	mov	a,h		;Get the number of 10s found.
	ora	l		;check for quotient non zero
	cnz	nout1		;If non zero, recurse.
	pop	h		;Get the remainder - 10
	mov	a,l		;in a
	adi	'0'+10          ;Make the number printable and add the 10 back
	call	shiftmp		; cycle temp registers
	sta	temp1		; and save digit
	mov	e,a		;Output the digit.
	lda	nquiet		; are we to be quiet?
	ana	a
	rnz		; yup, so return here rather than frm bdos
	mvi	c,conout
	jmp	bdos

; prcrlf - print a CR/LF.  (Saves no registers.) [Toad Hall]
; prtstr - print string pointed to by DE (now in overlay section.. see prtstx)
;       called by: lots of places.
prcrlf:	lxi	d,crlf		;Point to the CR/LF
	jmp	prtstr		; Use the one in the overlay

; prtstx is funtionally the same as prtstr in the overaly but is here as 
;	we may need a print a string routine in case the overlay is
;	either incorrect version or simply not present.
prtstx:				; PRTSTR moved to overlay, but we do need the
				; same function for writing the sign-on
				; message and error message if the overlay
				;is not present.  Thence prtstx
	mvi	c,prstr		; output string
	jmp	bdos		;a CALL followed by a RET becomes a JMP


;       Jumping to this location is like retskp.  It assumes the instruction
;       after the call is a jmp addr.
;       here from: many places.
rskp:	pop	h		;Get the return address.
	inx	h		;Increment by three.
	inx	h
	inx	h
	pchl

;       Jumping here is the same as a ret.  'jmp r' is used after routines
;       that have skip returns, where the non-skip instruction must be 3 bytes.
;       here from: many places.
r:	ret

; Pause-it routine.  Informs the user to press any key to continue
;	and then waits for a key input.  Called by the any routine 
;	with more than, say, 20 lines of output.

pausit:	lxi	d,anymes	; ask user to press any key to continue
	call	prtstr
pausi1:	call	ckcon		; see if a key typed
	ana	a
	jz	pausi1		; loop until a key has been pressed.

	ret

;
;       Open a file for reading (with inbuf).  The filename is already
;       in fcb; upon return, the end of file flag is cleared and chrcnt
;       is set to zero, so inbuf will be called to get a buffer when we
;       next attempt to get a character.
;       called by: sinit, seof

getfil:	xra	a
	sta	chrcnt		;Buffer is empty.
	sta	seccnt		;No sectors buffered.
	sta	eoflag		;Not the end of file.
	sta	endsts		;No EOF/error pending.
	sta	fcb+0CH		;Zero the extent.
	sta	fcb+0EH		;Must be zero for MAKEF or OPENF.
	sta	fcb+20H		;Zero the current record.
	mvi	c,openf		;Open the file.
	lxi	d,fcb
	call	bdos
	ret

;       Get next sector.  If necessary, read some more from disk.
;       preserves bc, de, hl
;       returns nonskip if EOF or error;
;       returns skip with chrcnt and bufpnt updated if success.
;       called by: gtchr, get1xc (from xmt/transmit)

inbuf:	lda	eoflag		;Have we reached the end?
	ora	a
	rnz		;Return if so.
	push	b
	push	d
	push	h
inbuf1:	lda	seccnt		; Do we have any sectors left?
	ora	a
	jz	inbuf3		; If not, go get some more.
inbuf2:	lhld	nxtbuf		; Yes.  Get address of next sector
	shld	bufpnt		; Update current buffer pointer
	lxi	b,bufsiz	; Get number of bytes in sector
	dad	b		; Update HL to point to next sector
	shld	nxtbuf		; Save for next time
	dcr	a		; Decrement count of buffered sectors
	sta	seccnt		; Put it back
	mvi	a,bufsiz-1	; Number of bytes in buffer (pre-decremented)
	sta	chrcnt		; Store for our caller
	pop	h
	pop	d
	pop	b
	jmp	rskp		; Return success

; We don't have any sectors buffered.  If we've already hit an error or
; EOF, return that status to the user.

inbuf3:	lda	endsts		; Check status from previous read
	ora	a
	jz	inbuf4		; It was OK.  Get some more sectors.
	sta	eoflag		; End of file or error.  Set the flag.
	xra	a
	sta	chrcnt		; Say no characters in buffer.
	pop	h
	pop	d
	pop	b
	ret		; Return failure

; Read sectors until we fill the buffer or get an error or EOF, then return
; the first buffer to the user.  (seccnt is zero)

inbuf4:	lhld	bufadr		; Get address of big buffer
	shld	nxtbuf		; Store as next buffer address to give user
inbuf5:	shld	bufpnt		; Store as next buffer address to read into
	xchg		; Move buffer address to DE
	mvi	c,setdma	; Tell CP/M where to put the data
	call	bdos		;  ...
	mvi	c,readf		; Read a record.
	lxi	d,fcb
	call	bdos
	sta	endsts		; Save ending status
	ora	a		; 00H => read O.K
	jnz	inbuf6		; EOF/error: stop reading.
	lxi	h,seccnt	; Success.  Get addr of sector count
	inr	m		; Bump sector count by one
	lda	bufsec		; Get max number of sectors in buffer
	cmp	m		; Are we there yet?
	jz	inbuf7		; Yes, can't read any more.
	lhld	bufpnt		; No, try for another.  Get buffer address,
	lxi	d,bufsiz	;  and size of sector,
	dad	d		;  giving next buffer address in HL
	jmp	inbuf5		; Go read another sector.

; We hit EOF or got an error.  Put the DMA address back where it belongs,
; then go see if we have any sectors (before the one that got the error)
; to return to the caller.  Nxtbuf points to the first good sector, if
; any; seccnt contains the count of good sectors.

inbuf6:	call	rstdma
	jmp	inbuf1		; Go see if we have some data to return

; We've filled the big buffer.  Reset the DMA address, then go return a
; sector to the caller.  nxtbuf points to the beginning of the buffer;
; seccnt contains the number of sectors successfully read (except that
; if we've read 256 sectors, seccnt contains zero, so we can't just go
; to inbuf1).

inbuf7:	call	rstdma		;[pcc012]
	lda	seccnt		; Get sector count again.
	jmp	inbuf2		; Return a sector.

; IN1CHR - get a single character from the file.  Taken code from old
;	TRANSMIT routine.
in1chr:
	lda	eoflag		;EOF encountered?
	ora	a
	rnz		; Yes, finish.
	lxi	d,cmdbuf	; Use comnd buffer as line buffer.
	lhld	bufpnt		; Get current buffer pointer.
	lda	chrcnt		; Get current byte count
	mov	b,a		;  in B
in1ch1:	dcr	b		; Assume there's a character there
	jp	in1ch2		; If there was, proceed.
	call	inbuf		; There wasn't.  Try for another buffer.
	jmp	in1che		; End of file.
	lhld	bufpnt		; Got another buffer.  Get new pointer in HL
	lda	chrcnt		;  and new byte count
	mov	b,a		;  in B
;[MF]The modification below was made 30-Jan-1991 per report from
;[MF]Lance Tagliapietra from the University of Wisconsin at Platteville
;[MF]The following instruction should not be executed as the character counter
;[MF]has already been decremented by INBUF.
;	dcr	b		; we are reading in a character, so less one
in1ch2:	mov	a,b		; save new count
	sta	chrcnt
	mov	a,m		; Get a character from disk buffer.
	inx	h
	shld	bufpnt		; save new pointer
	ani	7FH		; Mask 7 bits.
	jz	in1ch1		; Skip nulls.
	ret		; character in a


in1che:	mvi	a,0ffh		; dubious about this one...
	sta	eoflag
	ret		; set end of file flag...?????

;;[pcc012]
;   appfil - Create or append to an existing file.  File name is in FCB.
;       Non-skip return if could not be done.  Skip return with file
;       open and bufpnt pointing to end of file.
;       called by logopn
appfil:	xra	a		;[pcc012] zero out stuff for open
	sta	fcb+0CH		;[pcc012] extent
	sta	fcb+0EH		;[pcc012] Must be zero for MAKEF or OPENF.
	sta	fcb+20H		;[pcc012] Zero the current record.
	mvi	c,openf		;[pcc012] Try to open the file
	lxi	d,fcb		;[pcc012]
	call	bdos		;[pcc012]
	cpi	0FFH		;[pcc012] Did we find it?
	jz	makfi1		;[pcc012] If not, go create it
	mvi	c,cflsz		;[pcc012] Compute the file size
	lxi	d,fcb		;[pcc012]
	call	bdos		;[pcc012]
	lhld	fcb+21H		;[pcc012] random record pointer
	mov	a,h		;[pcc012] See if zero length file
	ora	l		;[pcc012]
	jz	makfi2		;[pcc012] set up pointers if null file
	dcx	h		;[pcc012] backup to last record written
	shld	fcb+21H		;[pcc012] store rec ptr back
	lhld	bufadr		;[pcc012] get buffer address
	xchg		;[pcc012] to DE
	mvi	c,setdma	;[pcc012] set dma address
	call	bdos		;[pcc012] for read
	mvi	c,rrand		;[pcc012] read the last block
	lxi	d,fcb		;[pcc012]
	call	bdos		;[pcc012]
	ora	a		;[pcc012] check results
	jnz	rstdma		;[pcc012] reset dma and return if error
	lhld	bufadr		;[pcc012] get address again
	lxi	d,bufsiz	;[pcc012] and and size
	mvi	a,'Z'-40H       ;[pcc012] control-Z for comparison
appcz:	cmp	m		;[pcc012] Is this the EOF?
	jz	appxit		;[pcc012] Jump if yes
	inx	h		;[pcc012] no, bump
	dcr	e		;[pcc012] and grind
	jnz	appcz		;[pcc012] until find or buffer empty
appxit:	shld	bufpnt		;[pcc012] store buffer pointer
	dad	d		;[pcc012] compute next buffer adr
	shld	nxtbuf		;[pcc012] and store
	mov	a,e		;[pcc012] updated chr count
	sta	chrcnt		;[pcc012]
	xra	a		;[pcc012] reset sector count
	sta	seccnt		;[pcc012]
	call	rstdma		;[pcc012] reset normal dma
	jmp	rskp		;[pcc012] and give good return

;       Create a file, deleting any previous version.  The filename is in
;       fcb.
;       Returns nonskip if file could not be created.
;       If successful, takes skip return with bufpnt and chrcnt initialized
;       for output; buffers should be output via outbuf.
;       called by: gofil
makfil:	mvi	c,delf		; delete the file if it exists.
	lxi	d,fcb
	call	bdos
	xra	a
	sta	fcb+0CH		; zero the extent.
	sta	fcb+0EH		; must be zero for MAKEF or OPENF.
	sta	fcb+20H		; zero the current record.
;[pcc012] here from appfil above if file does not exist
makfi1:	mvi	c,makef		;[pcc012] now create it.
	lxi	d,fcb
	call	bdos
	cpi	0FFH		; is the disk full?
	rz		; take error return if so.
; success. set up pointers and counters for multisector buffering.
;[pcc012] also here from appfil if found zero length file
makfi2:	lhld	bufadr		;[pcc012] find beginning of buffer space.
	shld	bufpnt		; make it current buffer.
	lxi	d,bufsiz	; get sector size.
	dad	d		; find beginning of next buffer.
	shld	nxtbuf		; store for later.
	mov	a,e		; store buffer size
	sta	chrcnt		;  for caller.
	xra	a
	sta	seccnt		; no sectors stored yet.
	jmp	rskp		; take success return.

;[pcc012]
;   outadv - conditionally advance output buffer if disk write not needed.
;       preserves BC
;       skip return with with next output buffer set up
;       non-skip return if memory buffer full and must write to disk.
;       called by:logit

outadv:	push	b		;[pcc012] save BC as advertised
	lxi	h,seccnt	;[pcc012] point to sectors buffered
	inr	m		;[pcc012] count this one
	lda	bufsec		;[pcc012] how many we can hold
	cmp	m		;[pcc012] check if full
	jnz	outbf2		;[pcc012] continue if not
	dcr	m		;[pcc012] full, un-advance sector count
	pop	b		;[pcc012] restore bc
	ret		;[pcc012] and give non-skip return

;       get a fresh output buffer, flushing big buffer if necessary.
;       returns nonskip if disk full.
;       if successful, returns skip with bufpnt and chrcnt updated.  Note
;       that chrcnt holds one less than the buffer size.
;       preserves BC.
;       called by: ptchr,logwrt

outbuf:	push	b
	lxi	h,seccnt	; count another buffered sector
	inr	m		;  ...
	lda	bufsec		; get number of sectors we can hold
	cmp	m		; full?
	jnz	outbf2		; if not, set up pointers and return
	call	outmbf		; flush the big buffer
	jmp	outbf9		; disk error.
;[pcc012] also here from outadv to advance buffer
outbf2:	lhld	nxtbuf		; get pointer to fresh buffer
	shld	bufpnt		; store for caller
	lxi	d,bufsiz	; advance our pointer to next buffer
	dad	d
	shld	nxtbuf
	mvi	a,bufsiz-1	; get buffer size (pre-decremented)
	sta	chrcnt		; store for caller
	pop	b
	jmp	rskp		; return success.

outbf9:	pop	b		; clean up stack
	ret		; and take error return.

;       flush incore output buffers.
;       returns nonskip if disk full.
;       if successful, returns skip with nxtbuf reset to start of buffer and
;       seccnt zero.
;       destroys all ac's.
;       called by: outbuf, clofil.

outmbf:	lhld	bufadr		; get start of buffer
	shld	nxtbuf		; store for next fill cycle
	shld	bufpnt		; store for empty loop
outmb2:	lhld	bufpnt		; get address of current sector
	xchg		;  into DE
	lxi	h,bufsiz	; advance HL to next sector
	dad	d		;  ...
	shld	bufpnt		;  and store for later
	mvi	c,setdma
	call	bdos		; point CP/M at current sector
	lxi	d,fcb
	mvi	c,writef
	call	bdos		; output the sector
	ora	a		; test for error (A non-zero)
	jnz	rstdma		;[pcc012] reset dma and take nonskip return if so
	lxi	h,seccnt
	dcr	m		; count down buffered sectors
	jnz	outmb2		; loop if more saved
	call	rstdma		;[pcc012] restore normal dma
	jmp	rskp		; return success.

;       output current buffer, flush incore buffers, and close output file.
;       returns nonskip if disk full; skip if successful.
;       called by: rdata

clofil:
	lda	chrcnt		; get the number of chars left in the buffer.
	cpi	bufsiz		; Virgin buffer?
	jz	clofl3		; yes, don't output it.
	lhld	bufpnt		; get the buffer pointer.
clofl1:	dcr	a		; lower the count.
	jm	clofl2		; if full then stop.
	mvi	m,'Z'-100O      ; put in a ^Z for EOF.
	inx	h		; point to the next space.
	jmp	clofl1

clofl2:	call	outbuf		; output the last buffer.
	jmp	r		; give up if the disk is full.
clofl3:	lda	seccnt		; any sectors buffered in memory?
	ora	a
	jz	clofl4		; if not, don't try to flush.
	call	outmbf		; flush buffers
	jmp	r		; disk full.
clofl4:	mvi	c,closf		; close up the file.
	lxi	d,fcb
	call	bdos
	jmp	rskp		; return success.


; Reset DMA address to the default buffer
; called from inbuf,appfil,outmbf
rstdma:	lxi	d,buff		;[pcc012]
	mvi	c,setdma	;[pcc012]
	jmp	bdos		;[pcc012]

; [8] Intercept BDOS calls to check for console input
; This leads to simple trapping for input from disk rather than from the
; keyboard, alowing commands to be stored in a TAKE file.
; Printer is tested for readiness, and the second fuzzy clock is updated.
bdos:	;call	print		; print a character to the printer if needed
	;call	clock		; update the clock
	push	psw		; we will need this register
	lda	takflg		; are we taking from a 
	ana	a		; file or from command line
	jz	notake		; no, so do usual BDOS stuff
	mov	a,c		; get bdos function
	cpi	conin		; is it console in?
	jz	bd1in		; get a single character
	cpi	dconio		; direct console in or out?
	jz	bd1io		; test further for inpu or output
	cpi	rdstr		; read the console buffer?
	jz	bdcbuf		; then do it
	cpi	consta		; get the console status?
	jz	bdcst		; anything left in buffer?
notake:	pop	psw		; else we have a kosher BDOS call
	jmp	0005h		; Absolute address = BDOS entry point
;
bd1in:	; get a single character from take file
	pop	psw		; restore stack
	call	r1tchr		; read a single take character
	ret		; and return.  We dont expand tabs, 
				; check for xon/off or backspaces.  
				;Make sure the take file is error free?
;
bd1io:	;get or put a single character from/to console
	mov	a,e		; get e.  If 0ffh then input else output
	inr	a		; if 0 then input
	jnz	notake		; its for output, so let notake restore stack
	pop	psw		; otherwise we do it
	call	r1tchr		; read a single take character
	ret		; and return from out BDOS
;
bdcbuf:	; read a line of edited (?) input from the console
	pop	psw		; restore stack
	inx	d		; point to nc
bdosc1:	call	r1tchr		; get a character
	cpi	cr		; if a cr then return
	jz	nomore
	cpi	lf		; ignore line feeds
	jz	bdosc1		; so get another character
	push	psw		; we will want it later
	mvi	h,0
	ldax	d		; get nc, the no of characters in buffer
	mov	l,a		; now use as index from  de+2
	mvi	h,0
	inx	d		; de is now de + 2
	dad	d
	pop	psw		; Told you we will want this
	mov	m,a
	dcx	d		; point again to nc
	xchg		; make hl point to memory
	inr	m		; update pointer nc
	xchg		; restore it
	jmp	bdosc1
nomore:	dcx	d		; restore de to point to buffer
	ret

bdcst:	; get the console status.  Returns a 00 if at eof
	pop	psw
	push	h		; now save de, hl for return
	push	d		;
	lxi	d,takdma	; make a point to next byte...
	lhld	takptr		; pointer from dma address.  There will always
	dad	d		; be at least one byte, as the buffer is 
	mov	a,m		; ...
	pop	d		; filled only if a read empties it.
	pop	h		; restore hl, de
	cpi	cntlz		; end of file?
	mvi	a,0ffh		; say there is
	rnz		; if it is not a cntl z
	jmp	closet		; otherwise, close take file etc

r1tchr:		; read a single character from the take file or command line
	push	h
	push	d		; save in case of return
	lda	takflg		; see if character is to come from file or line
	ani	1		; if bit zero set, from take file
	jz	r1lchr		; get character from the command line
	lxi	d,takdma
	lhld	takptr		; get next data byte
	dad	d
	mov	a,m
	lhld	takptr		; cos it's destroyed with dad
	inx	h
	shld	takptr		; update pointer
	call	p1tchr		; print it (so the user sees it)
	push	psw		; save the read data for a while
	mov	a,l		; if l = 0 then read another sector
	ana	a
	jp	r1tch1		;[23] was jnz. jp => 128 byte sectors
	call	rnsect		;read next sector
r1tch1:	pop	psw		; now, is this a cntl-z.. in whic case
	pop	d		; also these...
	pop	h
	cpi	lf		; skip if a line feed
	jz	r1tchr		;
;[MF][31][30]Following lines commented out so semicolons are not considered
;[MF][31][30]command separators and thus are considered part of the command
;[MF][31][30]so commands like REMOTE DELETE *.*;* work correctly.
;	cpi	semico		; see if its a semicolon
;	jnz	r1tch2		; no, ignore it
;	mvi	a,cr		; else say its a cr (in case of command lines)
r1tch2:	cpi	cntlz		; end of file??
	rnz


c1tchr:	call	closet		; close file etc, then
	mvi	a,cr		; fake a carriage return chr 
				;       ( => clears kermit comnd line)
c1tch1:	ret		; and hope that editing etc not required.

r1lchr:		; read a single character from the command line
	lxi	d,cbuff		; point to buffer
	lda	cbptr		; get pointer for next character
	mov	l,a
	lda	cbuff		; get total number of characters there
	cmp	l		; ... less current character
	jp	r1lch1		; if positive, we have more characters
	lda	takflg		; no more, so reset command line bit (bit 4)
	ani	0efh
	sta	takflg
	mvi	a,cntlz		; fudge an end of file
	push	psw		; save for common exit (r1tch1)
	jmp	r1tch1
;
r1lch1:	mov	a,l		; get count back again
	mvi	h,0
	dad	d		; get offset to character
	inr	a
	sta	cbptr
	mov	a,m		; get next character
	cpi	semico		; if a semicolon, make it a carriage return
	jnz	r1lch2
	mvi	a,cr
r1lch2:	call	p1tchr		; send a copy to the console
	push	psw		; save it for r1tch1
	jmp	r1tch1		; common exit


; rnsect - read the next take sector from disk to the take dma address
; if there is no more then close the file too
rnsect:	push	b
	push	d
	push	h		; save in case we need these later
	mvi	c,setdma
	lxi	d,takdma	; set a next read from disk
	call	bdos		; recursive...
	mvi	c,readf
	lxi	d,takfcb
	call	bdos
	ana	a
	cnz	closet		; if returned value not zero, assume eof
	lxi	h,0
	shld	takptr		; pointer restored
	call	rstdma		; reset the dma address for fussy routines (this one)
	pop	h
	pop	d
	pop	b
	ret

; closet - close the take file and set the take flag to 0 (ie no takes)
;
closet:	lda	takflg		; reset the take file bit (bit 0)
	ani	0feh
	sta	takflg		; close the take file, and restore the flag
	mvi	c,closf
	lxi	d,takfcb
	call	bdos
	call	rstdma		; in case we did not do it above, reset dma
	ret

;
; clock - is a 32 bit counter incremented every BDOS call.  It serves as a
;       timer of sorts and allows a background clock to tick away..
clock:	push	psw		; we need flags and hl
	push	h
	lhld	clkbit		; get the counter
	inx	h		;
	shld	clkbit
	mov	a,h
	ora	l		; do we need to update the next lot of clock bits?
	jnz	clockx
	lhld	clkbit+2	; if carry up the top 16 bits
	inx	h
	shld	clkbit+2
clockx:	pop	h
	pop	psw
	ret

;       p1tchr - print a character in accumulator directly to the console
;       bypassing the bdos trap above.

p1tchr:	cpi	lf		; if a lf ignore it
	jz	p1tchx
	cpi	cr		; ditto carriage returns
	jz	p1tchx
	cpi	cntlz		; control z
	jz	p1tchx		; then dont write it out
	push	psw		; we do not want to loose it, do we?
	push	b
	push	d
	push	h		; 'cos you never know what bdos does...
	mov	e,a
	mvi	c,conout	; direct console io
	call	5		; absolute address as we skip the trap
	pop	h
	pop	d
	pop	b		; ... and we need some of these regs.
	pop	psw		; 
p1tchx:	ret		; and return



; outprn - This routine sends charactes to the printer if the latter is ready,
;       or to a buffer if the printer is not ready.  If the buffer is nearly
;       full, an XOFF is sent to the host, asking it to be quiet.  The buffer
;       is emptied by a series of calls in the connect state only.   
;       If the buffer is made nearly empty, then an XON is sent to the host.
;
outprn:	mov	a,e		; get the character to send back to a
	sta	prntmp		; we need all registers.
	jmp	outprx		; -testing-testing-testing- avoid buffer
;
outp0:	call	tstfree		; see how many spaces free
	cpi	2		; (free spaces in a on return)
	jp	outp1		; enough free spaces, so keep going
	call	print		; else see if we can print summat
	jmp	outp0		; and try again
;
outp1:	cpi	4		; common test - if three or less then send xoff
	cm	sndxoff
outpr2:	mov	a,b		; inc ptr and check for wrap around
	call	wrapt
	mov	b,a		; input pointer to b
	sta	prnbuf+1	; save the new pointer away
	lxi	h,prnbuf+2	; point to first real data entry in buffer
	call	inchl		; add offset in a to hl
	lda	prntmp		; get th character to save away
	mov	m,a		; save the data away
	ret

; outprx - send character in a to the printer. (We have checked to see if
;       the printer is ready)
;       called by outprn, print
outprx:	mov	e,a		; character has to be in e register
	call	outlpt		; send it to printer
	ret		; assume we print it

; TSTFREE - see how many free spacse there are in the buffer
;        - returns with free space in a, ip pointer in b, op pointer in c
szecyc	equ	127		; 128 bytes in buffer (less for debugging)
;
tstfree:
	lda	prnbuf		; get output pointer
	mov	c,a		;.. to c
	lda	prnbuf+1	; and input pointer ...
	mov	b,a		; ... to b
;
;
; Now comes the tricky bit.  We must establish whether there is less than 
;   three characters left in the buffer.  There are two conditions to test for
;   1)  the input pointer is a higher value than the output pointer
;   2)  the input pointer has been wrapped round and is less than the output pointer
; ie
;         |-------|-------|---------------------------------------------|
; Buffer  |o/p ptr|i/p ptr|  Buffer proper filling --->                 |
;         |-------|-------|------|-------------|-----------|------------|
;                              i/p2          o/p         i/p1
;
;  If ip = ip1 then if 
;                       (size of buffer - ip ptr + op ptr) < 3 send xoff
;  If ip = ip2 then if 
;                       (op ptr - input ptr ) < 3 send xoff
;
; First decide whice one applies

	mov	a,b		; get ip ptr 
	sub	c		; see if op ptr > ip ptr (case 2)
	jm	outp2		; yup, so do case two
	mvi	a,szecyc	; else do buffer - ip + op
	sub	b
	add	c
	jmp	outpx		; do common test
outp2:	mov	a,c		; get op pointer
	sub	b		; less input pointer
outpx:	ret		; with free space in a
;
;
;
; print - get a character from the buffer and print it if the printer 
;       is ready for it.  If the buffer clears more than 3 spare characters
;       and an xoff has been sent, then send an xon again.
print:	push	h		; save for rainy days
	push	d
	push	b
	push	psw		; .. as we may need flags etc....
	lda	initflg		; First check if the system has initialised
	ana	a
	jz	printx		; If system not set up then skip
;       nop
;       nop
;       nop                     ; debugging only...
	call	ckprtr		; check to see if printer is ready...
	ana	a		; not zero => ok
	jz	printx		; else skipit.
;       nop
;       nop
;       nop                     ; skip the jump for debugging
	lxi	h,prnbuf
	mov	a,m		; get input pointer
	inx	h		; test against output pointer
	cmp	m		; if = then buffer empty
	jz	printx		; so quit
	dcx	h		;pointer to output pointer
	call	wrapt		; check for wrap around
	sta	prnbuf		; save new pointer
	inx	h
	inx	h		;
	call	inchl		; add output pointer to hl
	mov	c,m		; get byte
	lda	hosths		; have we told host to be quiet?
	cpi	xoff		; if = xoff then we have
	jnz	print1		; nope, so just print it.. 
	push	b		; save the character to print
	call	tstfree		; see how many free bytes in buffer
	pop	b
	cpi	4		; 3 characters left?
	jz	printx
	push	b
	call	sndxon		; send an xon to host and wake it up.
	pop	b
print1:	mov	a,c		; we are gonna print a character, so ...
	call	outprx		; get it to a (as required by outprx) and print it
printx:
	pop	psw
	pop	b
	pop	d
	pop	h		; restore regs.
	ret

;
; Utilities for the cyclical buffer.  Returns a 0ffh if printer ready, 
;       else 0h.  Called by outprn, print

ckprtr:	
	call	lptstat		; no registers saved
;       mvi     a,0             ; FOR DEBUGGING PURPOSES
;       nop
	ret
;

inchl:	push	psw		; we do maths through this register
	add	l
	mov	l,a
	mvi	a,0
	adc	h
	mov	h,a
	pop	psw		; hl = a + hl
	ret

; wrapt - checks the offset in a with the limits of the buffer.
;       returns next address or if wrap around then 0 (start of buffer)
wrapt:	push	b
	inr	a
	mov	b,a		; save new a into b for now
	mvi	a,szecyc	; test for size of buffer
	sub	b
	mov	a,b
	pop	b		; restore bc regs again
	rnz
	xra	a		; if wrap around, then reset pointer
	ret		; return with next address pointer to in a

; sndxoff - send an xoff to the host and save the xoff character in hosths
;      saves all regs.  is called by logwrt, outprn
sndxoff:
	push	psw
	push	b
	push	d
	push	h		; some calling routines may be sensitive...
	lda	floctl		; are we doing flow control?
	ana	a
	jz	sndxf		; no, so dont bother.
	mvi	a,xoff		;^S to stop the host while we write the buffer.
	sta	hosths		; save it so we know we have sent it
	call	setpar		; set correct parity...
	mov	e,a
	call	outmdm		; output it.
	lxi	d,ofsnt		; say we have sent an xoff
	call	prtstr
sndxf:	pop	h
	pop	d
	pop	b
	pop	psw		; some routines touchy
	ret
ofsnt:	db	cr,lf,'[XOFF sent to host]',cr,lf,'$'

; sndxon - send an xon to the host and clear the hosths flag.  saves everything
;       called by logwrt, print
sndxon:	push	psw
	push	b
	push	d
	push	h
	lda	floctl		; are we doing flow control?
	ana	a
	jz	sndxn
	xra	a
	sta	hosths		; no xoff to hos any more
	mvi	a,xon		;^Q to restart the host
	call	setpar		; set appropriate parity
	mov	e,a
	call	outmdm		; send it.
	lxi	d,onsnt
	call	prtstr		; say xon sent to host...
sndxn:	pop	h
	pop	d
	pop	b
	pop	psw
	ret		; shame we dont do a pushall/popall subroutine...
onsnt:	db	cr,lf,'[XON sent to host]',cr,lf,'$'
;
;       Routines to clear (or rather fill) TEMPnnn space with the data in A
;       and to shift it all along one (filltmp an shiftmp respectively)
filltmp:
	push	b
	push	d
	push	h		; save all
	lxi	h,temp1
	mvi	b,10		; ten locations to fill
fillp:	mov	m,a
	inx	h
	dcr	b		; loop til all done
	jnz	fillp
	pop	h
	pop	d
	pop	b		; restore all
	ret

shiftmp:
	push	psw		; save all again
	push	b
	push	d
	push	h
	lxi	d,temp9
	lxi	h,temp10
	mvi	b,9		; shift nine times
shiftl:	ldax	d		; from tempx
	mov	m,a		; to tempx+1
	dcx	d
	dcx	h		; mover does not work as that increments
	dcr	b
	jnz	shiftl
	pop	h
	pop	d
	pop	b
	pop	psw
	ret		; else all done

;       getun - get the user number to temp1 (lsd) and temp2 (msd)
;
getun:	mvi	a,0ffh		; tell nout to be quiet
	sta	nquiet
	mvi	c,usrcod
	mvi	e,0ffh		; get current user from bdos
	call	bdos
	mov	l,a		; put into hl
	mvi	h,0
	call	nout		; decimalise it (decimalise???)
	xra	a
	sta	nquiet		; let nout print again
	ret

;	ckcon - Do a direct console IO (read) to see if there is any input
;	returns with a=0 (no input) or character (input received)
;	Assume that all regs may be destroy.
ckcon:	mvi	e,0ffh		; direct console input
	mvi	c,dconio
	call	bdos
	ret		; and return with wahtever returned in a



;
; subbc - Subtract the unsigned number in bc from the unsigned number
;	in HL with the answer in HL.  Flags altered, all 
;	other registers left intact.
subbc:	sta	temp1		; hl = hl - bc.. we need the accumulator
	mov	a,l
	sub	c
	mov	l,a
	mov	a,h
	sbb	b
	mov	h,a
	lda	temp1		; restore loop counter but not flags
	ret

; P20LN - Routine to print a string at (DE) and count the number of
;	line feeds. Pause after 20 lines printed.
p20ln:	xra	a		; clear the line counter
	sta	lincnt
p20ln1:	ldax	d		; get character to print
	inx	d
	cpi	'$'		; if a dollar we have done
	rz
	push	d
	push	psw		; save pointer and character to print
	mov	e,a
	call	outcon		; send character
	pop	psw
	pop	d		; restore pointers etc
	cpi	lf		; was that last character a line feed?
	jnz	p20ln1		; no, so carry on
	lda	lincnt		; yup, so update counter
	inr	a
	sta	lincnt
	cpi	20		; 20 lines printed?
	jnz	p20ln1		; not yet
	push	d		; we need DE
;	lxi	d,anymes	; pause a while [MF]removed
;	call	prtstr		; write the message [MF]
;p20ln2:	call	ckcon		; wait for any input [MF]
;	ana	a		;[MF]
;	jz	p20ln2		;[MF]
	call	pausit		;[MF] pause a while
	pop	d
	jmp	p20ln		; and continue


; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FOR RELEASE!

;	org ($+100h) AND 0FF00H

; link to the data area (was part of CPSUTL.ASM)

IF lasm
	LINK	CPSDAT
ENDIF	;lasm
