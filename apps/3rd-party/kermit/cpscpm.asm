; CPSCPM.ASM
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
;       This file duplicates the CP/M DIR and ERA functions so we don't have
;       to exit.
;
; revision history:
;
;edit 14, 1-Apr-1991 by MF. Correct a bug which crept in with edit 13 which
;	caused any control-key other than ^Y or ^Z to act like ^X after a key
;	had been depressed to halt output of the TYPE/PRINT commands.
;edit 13, 25-Mar-1991 by MF. Make the TYPE command always abort to Kermit
;	command-level if ^C is entered on the console even if multiple files
;	are being typed via wild-cards. Make ^X typed on the console abort
;	typeout of the current file and begin typeout of the next file,
;	if any, otherwise go back to Kermit command-level.
;	The foregoing also applies to the PRINT command.
;edit 12, 14-Feb-1991 by MF. Call "clrtop" in TYPE command at "type1"
;	rather than sending a <ff> directly to the terminal as some
;	terminals don't respond to <ff> characters. Thus the screen will be
;	cleared (if the terminal allows) before each file is typed.
;	Also use "getfil" rather than the bdos "openf" call to open
;	files for typing (label "type2"). This tightens up the code.
;	Zero "fcbcnt" before starting to type files (label "type0b").
;	This apparently fixes a phantom bug which caused incorrect lookup (and
;	hence garbage typeout) of files occassionally after a new disk
;	was inserted and a SET DEFAULT-DISK was performed to reset the disk
;	system. (It looked like parts of other files were being typed, as
;	if the directory had been misread or had not been reset.)
;edit 11, 8-Feb-1991 by MF. Cause the bdos call for direct console input
;	in "ckchr" **not** to go thru the bdos trap but to call bdos at 0005h
;	directly. This corrects a bug wherein if commands such as INPUT
;	(which check to see if a keyboard key has been pressed) were executed
;	from a TAKE-file, the character following the terminator of such
;	commands was being interpreted as that keyboard input, thus causing
;	the next command in the TAKE-file to be unrecognized since its
;	first character had been eaten as a result of the keyboard check.
;	This bug **may** be the cause of a report received by Dr. Martin
;	J. Carter of Nottingham University in the U.K. in which Kermit
;	was reported to have read a character beyond a command terminator
;	in a TAKE-file, making the subsequent command unrecognizable since
;	its first character was missing.
;edit 10, 29-Jan-1991 by MF. Use the big buffer for TYPE/PRINT commands.
;	Thus, edit 9 has been superseded.
;edit 9, 29-Jan-1991 by MF. Corrected EOF check in TYPE command routine
;	following label "type20". a READF call, if successful, gives A=0
;	(not A=0FFH) and A not zero if failure. Thus the "INR A" instruction
;	checking for EOF was **always** nonzero. The reason the TYPE command
;	worked is that CP/M text files indicate the text end-of-file with a
;	Control-Z, in which case the TYPE routine branched correctly. In
;	other words, this edit is more for aesthetic purposes to satisfy
;	purists than something brought about by dire necessity!
;edit 8, 28-Jan-1991 by MF. Added code courtesy of Dr. Martin J. Carter
;	of Nottingham University, UK, to use the big buffer for the COPY
;	command.
;edit 7, 18-Sep-1990 by MF.  Added RENAME routine to implement the
;	RENAME (FRENAME) command to rename a CP/M file.
;	Modified COPY routine to explicitly reject wild-carded filenames
;	by using COMND function CMOFI rather than functions CMIFI and
;	CMIFIN to get input and output filenames.
;	Modified ERA and COPY routines to not act upon the respective
;	commands until a "confirm" is typed.  This prevents these
;	routines from taking off upon recognition of action characters
;	like "?", which can be quite annoying if one is an inexperienced user.
; edit 6, March 11, 1987 by OBSchou.  Added in the TYPE and PRINT commands
;	Both type to the screen, print also echoes to printer.
;
; edit 5 20 June, 1986.  Added support for multiple file FCB buffering.
;
; edit 4: June 16, 1986 OBSchou at Loughborough University, UK
;       added in a test to prevent a DIR command issued from a TAKE command
;       being interruped by the next character in the take command buffer.
;       Also added code for USER nn. (Well, its OS related,is it not?)
;
; edit 3: July 8, 1984 (CJC)
;       Merge modifications from Toad Hall: support LASM (linked by CPSTT,
;       links to CPSWLD), use prcrlf where appropriate.
;
; edit 2: June 5, 1984 (CJC)
;       documentation and formatting; delete unused code (dir13); add module
;       version string.
;
; edit 1: May, 1984 (CJC)
;       extracted from CPMBASE.M80 version 3.9; modifications are described in
;       the accompanying .UPD file.
;
cpmver:	db	'CPSCPM.ASM (14)  1-Apr-1991$'    ; name, edit number, date

npl	EQU	04H	;Number of names per line for dir command.

;       This is the DIR command.  Display the name and size of all files
;       matching the filespec.
;       here from: kermit
;
;       Note: This is abstracted from Keith Peterson's DIRF.ASM
;               directory print function.  Thanks again Keith.
;
;
dir:	lxi	d,fcb		;Where to put the data, if any.
	mvi	a,cmifin
	call	comnd		;Parse a full or piece of file-spec
	jmp	dir2		;Didn't get a FULL file-spec
	jmp	dir4		;lets do it
;
;
;Make FCB all '?' to match any file
dir2:	lda	fcb
	cpi	' '             ;CMIFIN leaves that as ' '
	jnz	dir2a		;he typed at least x:
	xra	a
	sta	fcb		;default drive
dir2a:	lxi	h,fcb+1
	mvi	b,11		;FN+FT count.

dir3:	mvi	m,'?'           ;Store '?'s in FCB.
	inx	h
	dcr	b
	jnz	dir3
;Print signon message and drive name
dir4:	call	getun		; get current user number
	lda	fcb
	ora	a		;if not zero, get default
	jnz	dir4a
	lda	curdsk		;get default
dir4a:	adi	'A'-1           ;Asciize it
	sta	dnam14+2	;[4] add in user no, and Save it in message.
	lda	temp1+1		;[4] most sig. user number
	cpi	'0'             ;[4] if zero set space
	jnz	dir4b
	mvi	a,' '           ;[4] space
dir4b:	sta	dnam14		;[4]
	lda	temp1
	sta	dnam14+1	;[4] ls user number digit
	call	prcrlf
	lxi	d,inms14	;Point to message
	call	prtstr
;
;Initialize number of names per line counter
	mvi	a,npl		;Nr. names per line.
	sta	nnams		;Init counter.
	lda	hidefs		; are we doing file size?
	ana	a
	jnz	dir4c		; we are not showing file size,
	lda	nnams
	inr	a
	sta	nnams		; so we can show another name per line

dir4c:	xra	a		; clear the flags ready for multi-sector buffering
	sta	fcbcnt		; clear fcb counter
	sta	mfflg1
	sta	mfflg2
	sta	mfflg3
	lxi	h,fcb0		; reset pointer for fcb save space
	shld	xfcbptr
;
	call	dir26		;Get disk parameters
	xra	a		;[5] say first time round, so no spare fcbs
	sta	fcbcnt		;[5]
dir5:	call	mfname		;get some names
	jnc	dir6		;got one
	jmp	dir17		;got none - do summary

dir6:				;Check for console break
	lda	takflg		;[4] ... but not if issued from TAKE....
	ana	a		;[4]
	jnz	dir6a		;[4] we do the lot regardless.

	mvi	c,consta	;Ck status of kbd.
	call	bdos
	ora	a		;Any key pressed?
	jz	dir6a		;nope, keep going
	mvi	c,conin
	call	bdos		;gobble key
	jmp	dir17		;and print summary only

;Print an entry
dir6a:
	lxi	h,fcb+1		;point to Filename
	mvi	b,8		;File name length.
	call	dir11		;Type filename.
	mvi	a,'.'           ;Period after FN.
	call	dir10
	mvi	b,3		;Get the filetype.
	call	dir11
	call	dir25		;print size
	lxi	h,nnams		;Point to names counter.
	dcr	m		;One less on this line.
	push	psw
	cnz	dir7		;No cr-lf needed, do fence.
	pop	psw
	cz	dir12		;Cr-lf needed.
	jmp	dir5

;Print space, fence character, then space
dir7:	call	dir9
	mvi	a,':'           ;Fence character.
	call	dir10
	jmp	dir9

; dir8 - Print two spaces
; dir9 - Print one space
; dir10 - Type char in A register
dir8:	call	dir9
dir9:	mvi	a,' '
dir10:	push	b
	push	d
	push	h
	mov	e,a		;Char to E for CP/M.
	mvi	c,conout	;Write char to console function.
	call	bdos
	pop	h
	pop	d
	pop	b
	ret

;Type (B) characters from memory (HL)
dir11:	mov	a,m
	ani	7FH		;Remove CP/M 2.x attributes.
	call	dir10
	inx	h
	dcr	b
	jnz	dir11
	ret

;CR-LF routine. HL=NNAMS upon entry
dir12:	push	b
	push	d
	push	h
	call	prcrlf		;Print CR/LF [Toad Hall]
	pop	h		;(did use call to dir10, but slooow)
	pop	d
	pop	b
	mvi	m,npl		;Number of names per line.
	lda	hidefs		; are we showing file size?
	ana	a
	rnz			; no, so all ok
	inr	m		; else show another file per line
	ret

;Exit - All done, return via jmp (as for all main commands)
dir16:	call	prcrlf
	lda	curdsk
	dcr	a		;relative to 0
	mov	e,a
	mvi	c,logdsk
	call	bdos		;back to "logged in" disk
	jmp	kermit		;...and return to kermit.

;
;Determines free space remaining
;
dir17:	xra	a
	sta	mfflg1		;clean up MFNAME
	sta	mfflg2
	lda	fcb		; get drive number from FCB
	ora	a
	jz	dir18		; default?
	dcr	a		; no, make requested drive current drive.
	mov	e,a
	mvi	c,logdsk
	call	bdos
dir18:	call	sysspc		; get space available for current drive
	push	h
	lxi	d,inms15	;"Drive "
	call	prtstr
	lda	fcb		;If no drive, get
	ora	a		;logged in drive
	jnz	dir24
	mvi	c,rddrv
	call	bdos
	inr	a
dir24:	adi	'A'-1
	sta	inms16
	lxi	d,inms16	;"x has "
	call	prtstr
	pop	h		;Get number of bytes available
	call	nout
	lxi	d,inms17	;"K bytes free"
	call	prtstr
	jmp	dir16		;all done

;Compute the size of the file

dir25:	lda	hidefs		; do we show file size?
	ana	a		; if non zero, we dont.
	rz			; so just return
	mvi	c,cflsz		;get file-size
	lxi	d,fcb
	call	bdos
	lda	fcbrno		;shift least sign. part
	lxi	b,0		;init bc
	mov	l,a
	ani	7
	jz	dir250		;even K
	lxi	b,1		;save for later
dir250:	push	b		;save 0 or 1 to add to size
	mvi	b,3		;shift 3 bits
dir25a:	xra	a		;clear sign
	lda	fcbrno+1	;get most sig byte
	rar			;shift right
	sta	fcbrno+1	;put back
	lda	fcbrno		;get least sig part
	rar
	sta	fcbrno
	dcr	b		;loop 3 times
	jnz	dir25a
	mov	l,a		;size in HL
	lda	fcbrno+1
	mov	h,a
	pop	b		;get 0 or 1
	dad	b		;round up to KB used
	lda	bmask		;get (sectors/block)-1
	rrc
	rrc			;get (K/block)-1
	rrc
	ani	1FH
	mov	c,a
	dad	b		;add (K/block)-1 to size to round up
	cma			;make a mask
	ana	l		;truncate after rounding up
	mov	l,a
	push	h
	lxi	b,-10		;subtract 10
	dad	b
	jc	dir25d		;>= 10
	call	dir8		; print a leading space
	jmp	dir25e

dir25d:	pop	h		;get size again
	push	h
	lxi	b,-100		;subtract 100
	dad	b
	jc	dir25e		;>= 100
	call	dir9		; print another leading space
dir25e:	call	dir9		;a space
	pop	h		;get size back
	call	nout		;..go print it
	mvi	a,'k'           ;..and follow with K size
	call	dir10
	ret

dir26:	mvi	c,gtdpar	;current DISK PARAMETER BLOCK
	call	bdos
	inx	h
	inx	h
	mov	a,m		;Get Block Shift Factor
	sta	bshiftf
	inx	h		;Bump to Block Mask
	mov	a,m		;get it
	sta	bmask
	inx	h
	inx	h
	mov	e,m		;Get Max Block number
	inx	h
	mov	d,m
	xchg
	shld	bmax		;Put it away
	ret
;
;       ERA command - erase a CP/M file
;       here from: kermit

era:	mvi	a,cmifi		;Parse a file-spec
	lxi	d,fcb		;into FCB
	call	comnd
	jmp	kermit		;bad parse
	mvi	a,cmcfm		;[MF]Get a confirm from the user
	call	comnd		;[MF]...
	jmp	kermit		;[MF]NO? try another command
	lxi	d,fcb
	mvi	c,sfirst	;check if valid
	call	bdos
	inr	a		;0 if FILE not found
	jnz	era1		;found at least one
	lxi	d,erms15	;"unable to find file"
	call	prtstr
	jmp	kermit

era1:	lxi	d,fcb
	mvi	c,delf
	call	bdos
	lxi	d,inms18	;" File(s) erased"
	call	prtstr
	jmp	kermit

; USER - select a new user.  This is an unusual routine in that the user 
;       enters a number.  The others take on/off or filename (except
;       set escape
;
user:	mvi	a,cmnum		; go parse a number
	call	comnd
	jmp	kermit		; if we can not do it, quit to command loop
	mvi	a,cmcfm	; get a confirm from the user
	call	comnd
	jmp	kermit		; if no, then try another command
	lhld	number		; else get the number...
	xchg			; until a non valid digit is typed (eg cr)
	lxi	h,-32		; if a carry, then ok
	dad	d		; ... else its above 32
	jc	user1
	xchg			; restor number in hl again
	mov	a,l		; Lets save it
	sta	curusr		; as current user number
	mov	e,l		; get user no to e...
	mvi	c,usrcod
	call	bdos
	call	getun		; get user number to temp1 and temp2
	lda	temp2
	cpi	'0'
	jnz	user0		; dont do ms digit if a zero
	mvi	a,' '
user0:	sta	kerm1		; save into string etc
	sta	dnam14		; also for dir command
	lda	temp1
	sta	kerm1+1
	sta	dnam14+1	; also for dir command
	jmp	kermit

user1:	lxi	d,erms23	; tell user sorry
	call	prtstr
	jmp	kermit


;
;	TYPE - type a file or files to the console.  
;
; This utility also used by print, where the characters printed to 
; the console are also copied to the printer if the prnfl flag 
; is non-zero.  Uses mfname to type (print) multiple names.  
; Each file is preceeded with a formfeed character (usually clears 
; the screen on a VDU)
;

type:	mvi	a,cmifi		; parse a file name
	lxi	d,fcb		; let the parser know where the FCB is
	call	comnd
	jmp	type02		; if error say so

type0b:
	xra	a		; clear some flags for mfname
	sta	mfflg1
	sta	mfflg2
	sta	mfflg3
	sta	fcbcnt		;[12]...
	lxi	h,fcb0		; reset the fcb pointers etc
	shld	fcbptr
	call	mfname
	jc	type02		; match not found

;[MF][10]The following code to type a file using a 1-sector buffer has
;[MF][10]been replaced by code to use the "big buffer" -- 30-Jan-1991
;type1:	lxi	d,buff		; point to the default DMA address
;	mvi	c,setdma
;	call	bdos		; tell bdos where to put the dma address
;	mvi	a,ff		; do a form feed
;	call	typit
;	xra	a		; clear the character count
;	sta	chrcnt
;
;type2:	mvi	c,openf		; open the file for reading
;	lxi	d,fcb
;	xra	a		; but first clear bits of fcb...
;	sta	fcb+12
;	sta	fcb+14
;	sta	fcb+15
;	sta	fcb+32
;	call	bdos		; NOW open the file
;
;type20:	mvi	c,readf		; open up the file and read first sector
;	lxi	d,fcb
;	call	bdos
;;[MF][9]Correct EOF test below (next two instructions)
;;	inr	a		; if 0ffh returned, error. Assume EOF
;;	jz	typex		; so exit from here
;	ora	a		;[MF][9]If error, assume EOF
;	jnz	typex		;[MF][9]so exit
;	lxi	h,0		; else clear the pointer into the file
;	shld	typptr
;
;
;type2a:	lxi	d,buff		;ok, so lets get the byte to print
;	lhld	typptr
;	dad	d		; add offset to the DMA base
;	mov	a,m		; and get character to type (print)
;	ani	7fh		; make sure it is printable
;	cpi	20h		; is it a control character?
;	jp	type3
;	cpi	09h		; if its a tab, then expand it
;	jnz	type2b
;
;type2c:	mvi	a,' '		; send a space
;	call	typit		; type it
;	lda	chrcnt		; get the number of chrs so far
;	ani	7h		; see of an 8th pos?
;	jnz	type2c		; loop until all spaces done, then exit
;	jmp	type4
;
;type2b:	cpi	cr		; is it a cr or lf?
;	jnz	type2d
;	call	typit		; do a cr
;	xra	a
;	sta	chrcnt		; cr of lf => clear character count
;	jmp	type4		; and exit
;
;type2d:	cpi	lf
;	jnz	type2e
;	call	typit		; print the character
;	xra	a
;	sta	chrcnt		; cr or lf clears the character count
;	jmp	type4
;
;type2e:	cpi	cntlz		; is it end of file?
;	jnz	type2f
;	jmp	typex		; yes, so close and try for another file
;
;type2f:	push	psw		; control char - save the character
;	mvi	a,'^'		; send control chars as ^A, for ex.
;	call	typit
;	pop	psw
;
;type3:	call	typit
;	
;
;type4:	lhld	typptr		; get the pointer
;	inx	h
;	shld	typptr		; up it by one character, and save it.
;	mov	a,l		; lets see if the sector has been typed
;	ana	a
;	jm	type20		; if 80h => read new sector
;	jmp	type2a		; else just continue along

;[MF][10]The following code uses the "big buffer" to read the file
;[MF][10]which is to be typed
;[12]Clear the screen explicitly as some terminals don't respond
;[12]to the <ff> character.
;type1:	mvi	a,ff		; do a form feed
;	call	typit
type1:	call	clrtop		;[12] Clear the screen
	xra	a		; clear the character count
	sta	temp1		;[MF]alias column counter

type2:
;[12]Eliminate call to openf in favor of call to "getfil"
;	mvi	c,openf		; open the file for reading
	lxi	d,fcb
;	xra	a		; but first clear bits of fcb...
;	sta	fcb+12
;	sta	fcb+14
;	sta	fcb+15
;	sta	fcb+32
;	call	bdos		; NOW open the file
	call	getfil		;[12] NOW open the file

type20:	call	inbuf		;[MF]Fill input buffers
	jmp	typex		;[MF]Tru end-of-file reached
	jmp	type21		;[MF]Begin typing/printing characters

type2a:	lda	chrcnt		;[MF]Get buffer character counter
	dcr	a		;[MF]and decrement it
	jm	type20		;[MF]Get more characters if needed
type21:	sta	chrcnt		;[MF]else remember new buffer character counter
	lhld	bufpnt		;[MF]Now get character pointer
	mov	a,m		; and get character to type (print)
	inx	h		;[MF]Increment the pointer
	shld	bufpnt		;[MF]and remember it
	ani	7fh		; make sure character is printable
	cpi	20h		; is it a control character?
	jp	type3
	cpi	09h		; if its a tab, then expand it
	jnz	type2b

type2c:	mvi	a,' '		; send a space
	call	typit		; type it
	lda	temp1		;[MF]Get the number of characters so far
	ani	7h		; see if an 8th pos?
	jnz	type2c		; loop until all spaces done, then exit
	jmp	type2a		;[MF]and continue

type2b:	cpi	cr		; is it a cr or lf?
	jnz	type2d
	call	typit		; do a cr
	xra	a
	sta	temp1		; cr or lf => clear character count
	jmp	type2a		;[MF]and continue

type2d:	cpi	lf
	jnz	type2e
	call	typit		; print the character
	xra	a
	sta	temp1		; cr or lf clears the character count
	jmp	type2a		;[MF]and continue

type2e:	cpi	cntlz		; is it end of file?
	jnz	type2f
	jmp	typex		; yes, so close and try for another file

type2f:	push	psw		; control char - save the character
	mvi	a,'^'		; send control chars as ^A, for ex.
	call	typit
	pop	psw

type3:	call	typit
	jmp	type2a		; and continue along

typex:	mvi	c,closf
	lxi	d,fcb
	call	bdos		; close the file
	mvi	a,cr		; send cr lf to screen/printer to clear buffers
	call	typit
	mvi	a,lf
	call	typit
	call	mfname		; and see if there are other files to type
	jnc	type1		; yup, so go do it
	xra	a		; make sure the flag is reset
	sta	prnfl
	jmp	kermit		; then exit.

typex0:	mvi	c,closf		;[MF]Close the file
	lxi	d,fcb		;[MF]...
	call	bdos		;[MF]...
	mvi	a,cr		;[MF]Clear buffers
	call	typit		;[MF]...
	mvi	a,lf		;[MF]...
	call	typit		;[MF]...
	xra	a		;[MF]Clear flag
	sta	prnfl		;[MF]...
	lda	takflg		;[MF]See if we're TAKEing commands
	ani	1		;[MF]from a file
	cnz	closet		;[MF]If we are, abort TAKE-file processing
	jmp	kermit		;[MF]Back to Kermit command-level

; error for file not found for type
type02:	lxi	d,nofile	; say no file name (its invalid)
	call	prtstr
	xra	a
	sta	prnfl		; clear the flag
	jmp	kermit		; so abort


typit:	mov	e,a
	call	ckqtyp		; see if a cntl-c or other character from user
	jmp	typit2		;[MF] Control-C entered, abort
	jc	typit1		; CNTL-X entered, so abort file [MF]
	push	d		; save for a bit
	call	outcon		; send it to the console
	lda	temp1		; update the number of characters sent[MF]
	inr	a
	sta	temp1		;[MF]
	pop	d
	lda	prnfl		; see if we have to print it too
	ana	a
	rz
	call	outprn		; send character to printer (buffer)
	ret

typit1:	pop	d		; adjust stack again
	jmp	typex		; and say we are done (for this file)

typit2:	pop	d		;[MF] Adjust the stack
	jmp	typex0		;[MF] and abort file typeout completely


; CKQTYP - CHeck for requested Quiet TYPe (ie hang on a second)
;	Routine sees if the user has typed ANY key.  If a key HAS been pressed
;	see if its a Control-c.  If so, flag for an abort, else wait for 
;	a second entry from the user. If its a Control C, flag an abort
;	else continue with the print.
;	note: only the DE  registers maintained.  All others destroyed.
;	**NOTE** CKQTYP now gives a nonskip return if Control-C is typed,
;	a skip-return with carry set if a Control-X is typed and a skip-return
;	with carry clear if any other character is typed as the second
;	character.

ckqtyp:	push	d		; save the character to be printed
	call	ckchr		; see if user entered a character
	ani	7fh		; strip parity etc
	jz	ckqty3		; nothing entered, so go on as usual (See below)
	cpi	ctrlc		; control c?
	jz	ckqt1a		;[MF] Yup, give nonskip return
	cpi	'X'-100o	;[MF] If Control-X,
	jz	ckqty1		; yup, set carry and exit
ckqty2:	call	ckchr		; another character to wait for (ie pause)
	ani	7fh
	jz	ckqty2		; wait until some input
	cpi	ctrlc		; if control c, abort
	jz	ckqt1a		;[MF] ...
	cpi	'X'-100o	;[MF] Control-X?
	jz	ckqty1		; yuss, so flag abort file [MF]
ckqty3:	pop	d		; else restore the character to be typed [MF]
;	ret			; no, so continue with type/print
	stc			;[MF]Set carry
	cmc			;[MF]Then clear it
	jmp	rskp		;[MF] Continue with type/print (skip ret)

ckqty1:	pop	d		; restore stack again
	stc			; set carry and return
;	ret
	jmp	rskp		;[MF] ...

ckqt1a:	pop	d		;[MF] Adjust stack
	ret			;[MF] and return

;[MF][14]No longer need these lines
;ckqty3:	pop	d		; restore stack again
;;	ret
;	stc			;[MF] Clear carry
;	cmc			;[MF] ...
;	jmp	rskp		;[MF] and give skip return

ckchr:	call	selcon		; make sure we are talking to the console
	mvi	e,0ffh		; see if user has any input for us
	mvi	c,dconio
;	call	bdos		;[11]Don't go thru bdos trap
	call	0005h		;[11]Call bdos directly
	ret			; This routine does not care what comes back

	
;
; COPY - routine to copy from a source file to a destination file 
;	from the Kermit command state.
;
;	Note.  This could be tricky, as there are several forms of copy
;		copy d:source.ext d:dest.ext	(Easy one)
;		copy d:source.ext d:		(File to another drive)
;		copy d:source.??? d:		(several files)
;		copy d:*.* d:			(Several files)
;
;	Initially, lets make it top one, and see how we go, ok?
;
;
;Things to do for copy:
;	1) get source name
;	2) get target name
;	3) if both source and destination = abort
;	4) if source does not exist abort
;	5) attempt to delete destination file if it exists
;	6) open source and destination files
;	7) copy file across
;	8) close all files
;	9) return to command mode
;
copy:			; Here goes...
;	1) get source file name
	mvi	a,cmofi		; go parse a file name
				;[MF]Nonwild
	lxi	d,cfcbs		; use the source for copy FCB (Allows copy
	call	comnd		; from a TAKE file etc)
	jmp	kermit		; if error, abort

;	2) get target name
	mvi	a,cmofi		; go parse a target file name
				;[MF]Again, nonwild
	lxi	d,cfcbd		; use destination fcb
	call	comnd		; get it
	jmp	kermit		;[MF]Couldn't.
	mvi	a,cmcfm		;[MF]Get a confirm from the user
	call	comnd		;[MF]...
	jmp	kermit		;[MF]No? try another command

;	3) see if both target and source are equal
copy0:	mvi	b,12		; we are gonna test drive, file and extention
	lxi	d,cfcbs		; from source file name...
	lxi	h,cfcbd		; to destination file name
	xra	a		; clear flag for difference found
	sta	equflg
copy1:	ldax	d		; get source file name character
	cmp	m		; test with targer file name
	jz	copy2		; if equal, do nothing
	lda	equflg		; else update flage (ie files are different)
	inr	a
	sta	equflg
copy2:	inx	h
	inx	d
	dcr	b
	jnz	copy1		; up pointers and test for next char

	lda	equflg		; if still null, then its a daft thing to do
	ana	a
	jnz	copy3		; its not a daft thing to do
	lxi	d,samems	; load up "File source and destination the same"
	call	prtstr		; tell user
	jmp	kermit		; and try again

;	4) If source does not exist, abort.  Assume we have a full file name.
copy3:
	lxi	d,cfcbs		; load up source fcb
	mvi	c,openf		; open file
	call	bdos
	inr	a		; error on open?
	jnz	copy4
	lxi	d,nofile	; assume file not found
	call	prtstr
	jmp	kermit		; and die

copy4:	lxi	d,cfcbd		; load up destination fcb
	mvi	c,delf		; destroy target name if it exists
	call	bdos		; ignore error messages
	lxi	d,cfcbd		; load up destination fcb
	mvi	c,makef		; make a file
	call	bdos
	inr	a		; make error?
	jnz	copy4a
	lxi	d,erms12	; no directory space
	call	prtstr
	jmp	copy7		; close source file

copy4a:	lxi	d,cfcbd		; load up destination fcb...
	mvi	c,openf		; for open
	call	bdos
	inr	a		; error on open?
	jnz	copy5		; could do with better error detection...
	lxi	d,erms15	;... but assume its a disk full
	call	prtstr
	jmp	copy7		; close source file and jmp kermit

;copy5:	lxi	d,buff		; set default dma address to 80h
;	mvi	c,setdma
;	call	bdos
;
;copy6:	lxi	d,cfcbs		; copy routine proper.. get a sector
;	mvi	c,readf
;	call	bdos
;	ana	a		; error reading the file?
;	jnz	copy8		; yes, then cope with it (could be EOF)
; [MaJoC 910128] The above code, which reads single logical sectors,
; is grossly inefficient with systems (most of them) with larger physical
; disk blocks and a single shared read/write buffer.  Use of INBUF below
; is functionally equivalent at this level, but does actual disk reads
; by the Big Buffer-ful.
copy5:
	xra	a		; Initialise INBUF, to force reading of
	sta	seccnt		;  the first Big Buffer-ful.  Redundant
	sta	endsts		;  if file opened by GETFIL (or variant).
	sta	eoflag		;[MF]...
	lxi	h,cfcbs		;[MF]Copy source fcb to default fcb
	lxi	d,fcb		;[MF]since INBUF uses the default fcb
	lxi	b,33		;[MF]...
	call	mover		;[MF]...
copy6:
; INBUF returns a pointer to the next logical bufferful via bufpnt, filling
; the Big Buffer as necessary, with skip return for success and nonskip on
; error or EOF.
	call	inbuf		; Start of copy proper: get bufferful.
	jmp	copy8		; Nonskip return: treat as EOF.
	lhld	bufpnt		; Skip return => OK: pick up buffer pointer.
	xchg
	mvi	c, setdma	; Tell system where to write from.
	call	bdos
; [majoc 910128: end]
	lxi	d,cfcbd		; send sector to destination
	mvi	c,writef
	call	bdos
	ana	a		; error on write (disk full?)
	jz	copy6		; no error, so do another sector.
	lxi	d,erms17	; say disk is full
	call	prtstr
	lxi	d,cfcbd		; close the output file...
	mvi	c,closf
	call	bdos
	lxi	d,cfcbd		; ... and then delete it
	mvi	c,delf
	call	bdos		; ... and then drop through to...

copy7:	lxi	d,cfcbs		; here to close the source FCB
	mvi	c,closf
	call	bdos
	jmp	kermit

copy8:	lxi	d,cfcbd		; orderly close of destination file
	mvi	c,closf
	call	bdos
	jmp	copy7		; now close the source file as well.

;
;[MF]RENAME - Rename a file
;
rename:	mvi	a,cmofi		;[MF]Get nonwild filename
	lxi	d,cfcbs		;[MF]Use "COPY" fcb's
	call	comnd		;[MF]...
	jmp	kermit		;[MF]Couldn't get it.
	mvi	a,cmofi	;[MF]Get filespec to rename it to
	lxi	d,cfcbd		;[MF]...
	call	comnd		;[MF]...
	jmp	kermit		;[MF]Couldn't.
renam0:	lxi	d,cfcbs		;[MF]See if file to be renamed exists
	mvi	c,openf		;[MF]by trying to open it
	call	bdos		;[MF]...
	inr	a		;[MF]Does the file exist?
	jnz	renam1		;[MF]Yes
	lxi	d,nofile	;[MF]No, inform the user
	call	prtstr		;[MF]...
	jmp	kermit		;[MF]and bomb
renam1:	lxi	d,cfcbd		;[MF]Point to rename filespec
	mvi	c,openf		;[MF]Set function code to
	call	bdos		;[MF]See if rename file exists
	inr	a		;[MF]Does it?
	jz	renam2		;[MF]No
	lxi	d,erms31	;[MF]Yes, complain
	call	prtstr		;[MF]...
	jmp	kermit		;[MF]and depart with tail between legs
renam2:	lxi	h,cfcbd		;[MF]Now get rename filespec again
	lxi	d,cfcbs+16	;[MF]and where to copy it to
	lxi	b,16		;[MF]We copy drive, filename, filetype, extent
	call	mover		;[MF]...
	lxi	d,cfcbs		;[MF]Point to fcb for rename
	mvi	c,renam	;[MF]Get rename function
	call	bdos		;[MF]Try to rename the file
	inr	a		;[MF]Did we succeed?
	jnz	kermit		;[MF]Yes, done
	lxi	d,erms16	;[MF]No, complain
	call	prtstr		;[MF]...
	jmp	kermit		;[MF]and start over


IF lasm
	LINK	CPSWLD
ENDIF;lasm  [Toad Hall]
