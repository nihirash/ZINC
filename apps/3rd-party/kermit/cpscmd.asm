; CPSCMD.ASM
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
;
;       This file provides a user oriented way of parsing commands.
;       It is similar to that of the COMND JSYS in TOPS-20.
;
; revision history (latest first):
;
;edit 13, 17-Jan-1991 by MF. Modified "cmifil" routine to zero the entire
;	fcb (not just the extent) to fix a bug in the COPY command which
;	prevented successive COPY commands from working properly.
;edit 12, 16-Jan-1991 by MF. Modified routine "cmkeyw" to ignore leading
;	spaces/tabs before a keyword. This apparently was the intent in
;	"prompt" and "repars" (at least for command-lines) as the variable 
;	"cmsflg "is set upon command parse and reparse. The intent was ,
;	subverted, however, as "cmkeyw" did not reset the flag to ignore
;	leading white space for each search thru the key tables (even though
;	the buffer pointer to the keyword entered was reset). The fix was
;	to reset the "spaces seen" flag (cmsflg) after "cmkey2" so that
;	it is reset each time a new table entry is compared to the text
;	the user has entered from the keyboard/TAKE-file etc. The upshot
;	of all this is that the kluge code in "cminbf" at "cminb0" designed
;	to force Kermit to ignore leading white space on command-lines in
;	TAKE-files and on the CP/M command-line is no longer needed and,
;	therefore, has been eliminated. Also modify "comnd" to expect leading
;	spaces for functions other than "get keyword".
;edit 11, 26-Dec-1990 by MF. Modified routines to ignore leading white space
;	in lines from TAKE-files as well as during input from the CP/M
;	command-line  (form-feeds are now considered white space under these
;	circumstances).
;edit 10, 8-Sep-1990 by Mike Freeman.  Modified routines to ignore leading
;	spaces/tabs when processing Kermit commands from the CP/M
;	command-line.
;	Added flag CMBFLG to allow initial word on a command-line
;	to be blank (useful for Remote commands such as Remote CWD etc).
;	Added flag cmqflg to prevent character-echoing while entering
;	commands so Remote CWD etc can have nonechoing password entry.
; edit 9, 15 June, 1987 by OBSchou.  Bug fixing to allow a second filename
;	(quiet) be entered as d:<blank>.  Previous revision put the drive name 
;	in first character of FCB, I put that character back to a space.
;
; edit 8, 12 June, 1987 by OBSchou.  Addedin code in cmkeyw to print
;	20 lines of help, then pause for a key from the user befor
;	proceeding with help.
;
; edit 7, 11 March, 1987 by OBSchou for Richard Russell, BBC.  He writes:
;	Bug in cmtext which prevented use of octal characters (\nnn) fixed.
;
; edit 6, 18 June, 1986 by OBSchou, Loughborough University, Leics. UK
;       added code to parse a number from user input.  Added check to make 
;       sure the input command buffer does not overflow the limit.
;
; edit 5a: 7 March, 1986.  OBSchou. Added stuff rom MJ Carter.  He writes:
;       7th May 85, MJ Carter [majoc], Nottingham University
;       Code in cmifil() put one too many spaces in the FCB; this caused 
;       the BDOS of the British Micro Mimi to search for exteny 32,
;       rather than extent 0, so era() always said "can't find file"
;       Puttig a null at the point in question ought to fix 9 it.
;
; edit 5: 6-Feb-85 by Charles Carvalho
;       Make ffussy a runtime (rather than assembly-time) switch, to
;       eliminate conditional assembly in system-independent module.
;       Don't allow _%|()/\ in filenames if ffussy set; my CP/M manual
;       disallows those, too.
;
; edit 4: 13-Jan-85 by Vanya J.Cooper Pima Commun. College Tel: 602-884-6809
;
;pcc006 2-jan-85        VJC     modules:cp4cmd,cp4utl
;       Problems with "?" in filespecs.  On reparse, may cause action
;       flag to be reset at wrong point, requiring multiple <CR>'s
;       to terminate the line or other weird stuff.  Also need to
;       check flag and complain if wild-cards illegal.

;pcc007 2-Jan-85        vjc     modules:cp4def,cp4cmd
;       Cmifil is too fussy about what characters to accept in a
;       filespec.  My CP/M manual says any printable character is ok
;       except <>.,;:?*[], and lower case.  In practice, even those work
;       sometimes.  Kermit itself uses '&' if file warning is on,
;       and then won't let you reference the file.  Allow all
;       printable characters except those above.  Add conditional
;       ffussy, so that if not ffussy, all special characters will be
;       allowed, just convert lower to upper-case.

; edit 3: July 8, 1984 (CJC)
;       integrate Toad Hall changes for LASM compatibility: CP4CPM is linked
;       by CP4WLD, and links CP4UTL.
;       
; edit 2: June 5, 1984 (CJC)
;       formatting and documentation; delete unnecessary code at cminb7; add
;       module version string.
;
; edit 1: May, 1984 (CJC)
;       extracted from CPMBASE.M80 version 3.9; modifications are described in
;       the accompanying .UPD file.

cmdver:	db	'CPSCMD.ASM (13)  17-Jan-1991$'	; name, edit number, date

;       This routine prints the prompt in DE and specifies the reparse
;       address.
;       called by:  kermit

prompt:	pop	h		;Get the return address.
	push	h		;Put it on the stack again.
	shld	cmrprs		;Save it as the address to go to on reparse.
	lxi	h,0		;Clear out hl pair.
	dad	sp		;Get the present stack pointer.
	shld	cmostp		;Save for later restoral.
	xchg			;Save the pointer to the prompt.
	shld	cmprmp
	xchg
	lxi	h,cmdbuf
	shld	cmcptr		;Initialize the command pointer.
	shld	cmdptr
	xra	a
	sta	cmaflg		;Zero the flags.
	sta	cmccnt
;	mvi	a,0FFH		;Try it this way (Daphne.)
;	sta	cmsflg
	call	prcrlf		;Print a CR/LF [Toad Hall]
	jmp	prprmp		;Print the prompt.  [Toad Hall]
;
;       This address is jumped to on reparse.
;       here from:  cmcfrm, cmkeyw, cmifil, cminbf

repars:	lhld	cmostp		;Get the old stack pointer.
	sphl			;Make it the present one.
	lxi	h,cmdbuf
	shld	cmdptr
;	mvi	a,0FFH		;Try it this way (Daphne.)
;	sta	cmsflg
	lhld	cmrprs		;Get the reparse address.
	pchl			;Go there.

;       This address can be jumped to on a parsing error.
;       here from:  cmkeyw, cminbf

prserr:	lhld	cmostp		;Get the old stack pointer.
	sphl			;Make it the present one.
	lxi	h,cmdbuf
	shld	cmcptr		;Initialize the command pointer.
	shld	cmdptr
	xra	a
	sta	cmaflg		;Zero the flags.
	sta	cmccnt
;	mvi	a,0FFH		;Try it this way (Daphne.)
;	sta	cmsflg
	call	prcrlf		;Print a CR/LF  [Toad Hall]
	call	prprmp		;Print the prompt  [Toad Hall]
;* Instead return to before the prompt call.
	lhld	cmrprs
	pchl
;
;       This routine parses the specified function in A.  Any additional
;       information is in DE and HL.
;       Returns +1 on success
;               +4 on failure (assumes a JMP follows the call)
;       called by:  log, setcom, read, send, xmit, dir, era, keycmd, cfmcmd
;	and CPSREM

comnd:	sta	cmstat		;Save what we are presently parsing.
	call	cminbf		;Get chars until an action or a erase char.
	push	psw		;[MF]Save function
	mvi	a,0ffh		;[MF]Expect leading spaces
	sta	cmsflg		;[MF]...
	pop	psw		;[MF]Restore function
	cpi	cmcfm		;Parse a confirm?
	jz	cmcfrm		;Go get one.
	cpi	cmkey		;Parse a keyword?
	jz	cmkeyw		;Try and get one.
	cpi	cmifi		;Parse an input file spec?
	jz	cmifil		;Go get one.
	cpi	cmifin		;Input file-spec silent?
	jz	cmifil		;do as he wishes
	cpi	cmofi		;Output file spec?
	jz	cmofil		;Go get one.
	cpi	cmtxt		;Parse arbitrary text?
	jz	cmtext		;Go do it.
	cpi	cmnum		;[7] Parse a number?
	jz	cmnumb		;[7] go do it
	lxi	d,cmer00	;"?Unrecognized COMND call"
	call	prtstr
	ret
;
;       This routine parses arbitrary text up to a CR.
;       Accepts DE:     address to put text
;       Returns in A:   number of chars in text (may be 0)
;                DE:    updated pointer
;       called by: comnd

cmtext:	xra	a		; clear counters erc for slashes etc
	sta	slshsn		; if we are in a slash sequence
	sta	slashn		; the octal number being entered
	sta	slashc		; number of characters entered

	xchg			;Put the pointer to the dest in HL.
	shld	cmptab		;Save the pointer.
	mvi	b,0		;Init the char count
cmtxt1:	call	cmgtch		;Get a char.
	ora	a		;Terminator?
	jp	cmtx3		;No, put in user space. [rtr] was cmtx5
	ani	7FH		;Turn off minus bit.
	cpi	esc		;An escape?
	jnz	cmtxt2		;No.
	mvi	c,conout
	mvi	e,bell		;Get a bell.
	call	bdos
	xra	a
	sta	cmaflg		;Turn off the action flag.
	lhld	cmcptr		;Move the pointer to before the escape.
	dcx	h
	shld	cmcptr
	shld	cmdptr
	lxi	h,cmccnt	;Get the char count.
	dcr	m		;Decrement it by one.
	jmp	cmtxt1		;Try again.

cmtxt2:	cpi	'?'             ;Is it a question mark?
	jz	cmtxt4		;If so put it in the text. [rtr] was cmtx3
	cpi	ff		;Is it a formfeed?
	cz	clrtop		;If so blank the screen.
	mov	a,b		;Return the count.
	lhld	cmptab		;Return updated pointer in HL.
	xchg
	jmp	rskp		;Return success.

cmtx3:	cpi	'\'             ; slash?
	jnz	cmtx3a		; nope, so try something else
	lda	slshsn		; a slash already entered?
	ana	a
	cma			;[rtr]
	jnz	cmtx3a		; yes, so assume its a valid slash to enter
	sta	slshsn		; make sure the flag is set for next time routnd
	jmp	cmtxt1		; get another character

cmtx3a:
;	lxi	h,cmaflg	;Point to the action flag.
;	mvi	m,0		;Set it to zero.
	mov	e,a		; save it in case we are interpreting a slash
	lda	slshsn		; slash already entered?
	ana	a		; test flag
	mov	a,e		; restore it in case...
	jz	cmtx5		; not a slash seen, so enter as a normal character
	cpi	'\'
	jnz	cmtx3b		; \\ not detected
	lda	slashn		; else get number
	jmp	cmtx5b		; and enter it ( in the case of \n or \nn)
				; here if an octal number of 1 or 2 digits
				; entered instead of 3, followed by \ again

cmtx3b:
	sui	30h		; else it should be an octal number
	jm	cmtxt6		; if not a digit complain
	cpi	8		; ditto
	jp	cmtxt6		;[rtr] was cmtxt
	mov	e,a		; else add it to the number already entered
	lda	slashn
	add	a
	add	a
	add	a		; multiply by 8
	add	e
	sta	slashn
	lda	slashc		; get the count
	inr	a
	sta	slashc		; plus one.  If three then a number entered
	cpi	3
	lda	slashn		; get the number in case...
	jz	cmtx5
	jmp	cmtxt1		; else loop

cmtxt4:	lhld	cmdptr		;[rtr] Get a pointer into the buffer
	inx	h		;[rtr] Bump past '?'
	shld	cmdptr		;[rtr]
cmtx5:	call	cmtx5c
	jmp	cmtxt1		; put this into a subroutine

cmtx5b:
	call	cmtx5c		; here if we see \n\ or \nn\ rather than \nnn\
	mvi	a,'\'           ; so send slash number to buffer, 
	sta	slshsn		; re-store a slash seen
	jmp	cmtxt1		; try next one

cmtx5c:
	inr	b		;Increment the count.
	lhld	cmptab		;Get the pointer.
	mov	m,a		;Put the char in the array.
	inx	h
	shld	cmptab		;Save the updated pointer.
	xra	a		; clear slash counters etc
	sta	slashc
	sta	slashn
	sta	slshsn
	ret			; and exit

cmtxt6:	lxi	d,cmer05	; complain - not a valid \ parameter
	call	prtstr
	jmp	kermit		; and try another command
	ds	20h		; for debugging
;
;       This routine gets a number from user input.
;       Called by: comnd
;
cmnumb:	lxi	h,0		; make sure the number is zero to start with
	shld	number
cmnum0:	call	cmgtch		; get another character
	ora	a		; if negative then its an action
	jp	cmnum1		; nope, so (possibly) valid input
	ani	7fh		; else lets see what it is...
	cpi	esc		; do not know what to do with this one...
	cpi	' '             ; if it is a space then either a return or more
	jnz	cmnum2		; else
	jmp	rskp		; space is a deliminter
	dw	0		; set three bytes aside for a jump/call
	dw	0		; and then another three just in case...
	dw	0		; making 6 bytes
cmnum2:	cpi	'?'             ; user is curious
	jz	gnum2
	cpi	cr		; end of input?
	jz	cmnumx
gnum1:	jmp	prserr		; did not under stand this, so error
cmnumx:	dw	0
	dw	0
	jmp	rskp		; return ok

gnum2:	lhld	number		; get the number.. if at all entered
	mov	a,l
	ora	h		; if hl = 0 then possibly no number entered
	lxi	d,cmin02	; say confirm...or more on line
	jnz	gnum21		; else say enter a return
	lxi	d,cmin01	; say enter a number
gnum21:	call	prtstr		; say it
	call	prcrlf		; do a lf
	call	prprmp		; another reprompt
	lhld	cmdptr		; get pointer of string already entered
	mvi	m,'$'           ; dollar it to  set end of line
	lhld	cmcptr
	dcx	h		; decrement and save the buffer pointer
	shld	cmcptr
	lxi	d,cmdbuf
	call	prtstr		; print what has already been entered
	xra	a
	sta	cmaflg		; turn the action flag off
	jmp	repars		; and try again

	mvi	a,cmcfm		; parse a confirm
dw	0
dw	0
dw	0
dw	0
dw	0	; some space to patch...
dw	0

cmnum1:	ani	7fh		; here for a (potentially) valid number
	sui	'0'             ; less ascii bias
	jc	gnum3
	cpi	10		; if 10 or more its still bad
	jnc	gnum3
	cmc
	lhld	number		; now multiply number by ten and add the new value
	push	h
	pop	d
	dad	h		; hl = hl * 2
	dad	h		; * 4
	dad	d		; * 5
	dad	h		; * 10
	mvi	d,0
	mov	e,a		; add de to hl...
	dad	d
	shld	number
	jmp	cmnum0
;
gnum3:	lxi	d,cmer04	; invalid number...
	call	prtstr
	jmp	rskp
;

;
;       This routine gets a confirm.
;       called by: comnd

cmcfrm:	call	cmgtch		;Get a char.
	ora	a		;Is it negative (a terminator;a space or
				;a tab will not be returned here as they
				;will be seen as leading white space.)
	rp			;If not, return failure.
	ani	7FH		;Turn off the minus bit.
	cpi	esc		;Is it an escape?
	jnz	cmcfr2
	mvi	c,conout
	mvi	e,bell		;Get a bell.
	call	bdos
	xra	a
	sta	cmaflg		;Turn off the action flag.
	lhld	cmcptr		;Move the pointer to before the escape.
	dcx	h
	shld	cmcptr
	shld	cmdptr
	lxi	h,cmccnt	;Get the char count.
	dcr	m		;Decrement it by one.
	jmp	cmcfrm		;Try again.

cmcfr2:	cpi	'?'             ;Curious?
	jnz	cmcfr3
	lxi	d,cmin00	;Print something useful.
	call	prtstr
	call	prcrlf		;Print a crlf.  [Toad Hall]
	call	prprmp		;Reprint the prompt  [Toad Hall]
	lhld	cmdptr		;Get the pointer into the buffer.
	mvi	a,'$'           ;Put a $ there for printing.
	mov	m,a
	lhld	cmcptr
	dcx	h		;Decrement and save the buffer pointer.
	shld	cmcptr
	lxi	d,cmdbuf
	call	prtstr
	xra	a		;Turn off the action flag.
	sta	cmaflg
	jmp	repars		;Reparse everything.

cmcfr3:	cpi	ff		;Is it a form feed?
	cz	clrtop		;If so blank the screen.
	jmp	rskp
;
;       This routine parses a keyword from the table pointed
;       to in DE.  The format of the table is as follows:
;
;       addr:   db      n       ;Where n is the # of entries in the table.
;               db      m       ;M is the size of the keyword.
;               db      'string$' ;Where string is the keyword.
;               db      a,b     ;Where a & b are pieces of data
;                               ;to be returned.  (Must be two of them.)
;
;       The keywords must be in alphabetical order.
;**** Note:  The data value a is returned in registers A and E.  The
;****   data value b is returned in register D.  This allows the two data
;       bytes to be stored as:
;               dw      xxx
;       and result in a correctly formatted 16-bit value in register pair
;       DE.
;       called by: comnd

cmkeyw:	shld	cmhlp		;Save the help.
	xchg			;Get the address of the table.
	shld	cmptab		;Save the beginning of keyword tab for '?'.
	mov	b,m		;Get the number of entries in the table.
	inx	h
	shld	cmkptr
	lhld	cmdptr		;Save the command pointer.
	shld	cmsptr
cmkey2:	mov	a,b		;Get the number of entries left.
	ora	a		;Any left?
	rz			;If not we failed.
	mvi	a,0ffh		;[MF]Make sure we ignore leading spaces
	sta	cmsflg		;[MF]...
	lhld	cmkptr
	mov	e,m		;Get the length of the keyword.
	inx	h
cmkey3:	dcr	e		;Decrement the number of chars left.
	mov	a,e
	cpi	0FFH		;Have we passed the end?
	jm	cmkey5		;If so go to the next.
	call	cmgtch		;Get a char.
	ora	a		;Is it a terminator?
	jp	cmkey4		;If positive, it is not.
	ani	7FH		;Turn off the minus bit.
	cpi	'?'
	jnz	cmky31
	xra	a
	sta	cmaflg		;Turn off the action flag.
	lxi	h,cmccnt	;Decrement the char count.
	dcr	m
;* Must go through the keyword table and print them.
	lhld	cmhlp		;For now print the help text.
	xchg
	call	p20ln		;[8] print at most 20 lines then pause
;	call	prtstr
	call	prcrlf		;Print a crlf  [Toad Hall]
	call	prprmp		;Reprint the prompt  [Toad Hall]
	lhld	cmdptr		;Get the pointer into the buffer.
	mvi	a,'$'           ;Put a $ there for printing.
	mov	m,a
	lhld	cmcptr
	dcx	h		;Decrement and save the buffer pointer.
	shld	cmcptr
	lxi	d,cmdbuf
	call	prtstr
	jmp	repars		;Reparse everything.

cmky31:	cpi	esc		;Is it an escape?
	jnz	cmky35
	xra	a
	sta	cmaflg		;Turn off the action flag.
	push	d
	push	b
	push	h
	call	cmambg
	jmp	cmky32		;Not ambiguous.
	mvi	c,conout
	mvi	e,bell
	call	bdos		;Ring the bell.
	lhld	cmcptr		;Move the pointer to before the escape.
	dcx	h
	shld	cmcptr
	shld	cmdptr
	lxi	h,cmccnt	;Get the char count.
	dcr	m		;Decrement it by one.
	pop	h
	pop	b
	pop	d
	inr	e		;Increment the left to parse char count.
	jmp	cmkey3

cmky32:	lhld	cmcptr		;Pointer into buffer.
	dcx	h		;Backup to the escape.
	xchg
	pop	h
	push	h
cmky33:	mov	a,m		;Get the next char.
	cpi	'$'             ;Finished?
	jz	cmky34
	inx	h
	xchg
	mov	m,a		;Move it into the buffer.
	inx	h
	xchg
	lda	cmccnt		;Increment the char count.
	inr	a
	sta	cmccnt
	jmp	cmky33

cmky34:	lda	cmccnt		;Get the character count.
	inr	a		;Increment and save it.
	sta	cmccnt
	xchg			;Put the command buffer pointer in HL.
	mvi	a,' '           ;Get a blank.
	mov	m,a		;Put it in the command buffer.
	inx	h		;Increment the pointer
	shld	cmcptr		;Save the updated pointer.
	shld	cmdptr
	pop	h
	push	h
	xchg
	call	prtstr		;Print the rest of the keyword.
	mvi	c,conout
	mvi	e,' '
	call	bdos		;Print a blank.
	pop	h
	pop	b
	pop	d
	jmp	cmky37

cmky35:	push	h
	push	d
	call	cmambg
	jmp	cmky36
	lxi	d,cmer01
	call	prtstr		;Say its ambiguous.
	jmp	prserr		;Give up.

cmky36:	pop	d
	pop	h
cmky37:	inr	e		;Add one incase it is negative.
	mvi	d,0
	dad	d		;Increment past the keyword.
	inx	h		;Past the $.
	mov	e,m		;Get the data.
	inx	h
	mov	d,m
	mov	a,e
	jmp	rskp

cmkey4:	cpi	'a'             ;Is it less than a?
	jm	cmky41		;If so don't capitalize it.
	cpi	'z'+1           ;Is it more than z?
	jp	cmky41		;If so don't capitalize it.
	ani	137O		;Capitalize it.
cmky41:	mov	d,m		;Get the next char of the keyword.
	inx	h
	cmp	d		;Match?
	jz	cmkey3		;If so get the next letter.

cmkey5:	mvi	d,0
	mov	a,e		;Get the number of chars left.
	ora	a		;Is it negative?
	jp	cmky51
	mvi	d,0FFH		;If so, sign extend.
cmky51:	dad	d		;Increment past the keyword.
	lxi	d,0003H		;Plus the $ and data.
	dad	d
	shld	cmkptr
	dcr	b		;Decrement the number of entries left.
	lhld	cmsptr		;Get the old cmdptr.
	shld	cmdptr		;Restore it.
;* check so we don't pass it.
	jmp	cmkey2		;Go check the next keyword.
;
;       Test keyword for ambiguity.
;       returns: nonskip if ambiguous, skip if OK.
;       called by: cmkeyw

cmambg:	dcr	b		;Decrement the number of entries left.
	rm			;If none left then it is not ambiguous.
	inr	e		;This is off by one;adjust.
	mov	c,e		;Save the char count.
	mov	a,e
	ora	a		;Any chars left?
	rz			;No, it can't be ambiguous.
	mvi	d,0
	dad	d		;Increment past the keyword.
	mvi	e,3		;Plus the $ and data.
	dad	d
	mov	b,m		;Get the length of the keyword.
	inx	h
	xchg
	lhld	cmkptr		;Get pointer to keyword entry.
	mov	a,m		;Get the length of the keyword.
	sub	c		;Subtract how many left.
	mov	c,a		;Save the count.
	cmp	b
	jz	cmamb0
	rp			;If larger than the new word then not amb.
cmamb0:	lhld	cmsptr		;Get the pointer to what parsed.
cmamb1:	dcr	c		;Decrement the count.
	jm	rskp		;If we are done then it is ambiguous.
	xchg			;Exchange the pointers.
	mov	b,m		;Get the next char of the keyword
	inx	h
	xchg			;Exchange the pointers.
	mov	a,m		;Get the next parsed char.
	inx	h
	cpi	'a'             ;Is it less than a?
	jm	cmamb2		;If so don't capitalize it.
	cpi	'z'+1           ;Is it more than z?
	jp	cmamb2		;If so don't capitalize it.
	ani	137O
cmamb2:	cmp	b		;Are they equal?
	rnz			;If not then its not ambiguous.
	jmp	cmamb1		;Check the next char.
;
;       cmofil - parse output filespec
;       cmifil - parse input filespec
;       here from: comnd

cmofil:	mvi	a,0		;Don't allow wildcards.
;       jmp     cmifil          ;For now, the same as CMIFI.
cmifil:	sta	cmfwld		;Set wildcard flag
	xchg			;Get the fcb address.
	shld	cmfcb		;Save it.
	mvi	e,0		;Initialize char count.
	mvi	m,0		;Set the drive to default to current.
	inx	h
	shld	cmfcb2
	xra	a		;Initialize counter.
cmifi0:	mvi	m,' '           ;Blank the FCB.
	inx	h
	inr	a
;       cpi     0CH             ;Twelve? [5a dont use this]
	cpi	0Bh		; [majoc 850585] Eleven?
	jm	cmifi0
cmif0a:				;[MF]Zero entire fcb, not just the extent
	mvi	m,0		; [majoc 850507] Specify extent 0
	inx	h		;[MF]Increment fcb byte pointer
	inr	a		;[MF]Increment fcb byte count
	cpi	32		;[MF]Done with fcb?
	jm	cmif0a		;[MF]No, zero until done
cmifi1:	call	cmgtch		;Get another char.
	ora	a		;Is it an action character?
	jp	cmifi2
	ani	7FH		;Turn off the action bit.
	cpi	'?'             ;A question mark?
	jnz	cmif12
	lda	cmfwld		;[pcc006] Wildcards allowed?
	ora	a		;[pcc006]
	jz	cmif11		;[pcc006] complain if not
	lhld	cmdptr		;[jd] Increment buffer pointer
	inx	h		;[jd] that was decremented in cmgtch
	shld	cmdptr		;[jd] since we want this chr
	lda	cmcptr		;[pcc006] get lsb of real input pointer
	cmp	l		;[pcc006] is this the last chr input?
	jnz	cmif1a		;[pcc006] no, don't reset action flag
	xra	a		;[pcc006] yes, reset action flag
	sta	cmaflg		;[pcc006] 
cmif1a:	mvi	a,'?'           ;[pcc006] get it back in A
	jmp	cmifi8		;Treat like any other character

cmif12:	cpi	esc		;An escape?
	jnz	cmif13
;Try to recognize file-spec a'la TOPS-20
	xra	a
	sta	cmaflg		;Turn off the action flag.
	lhld	cmcptr		;Move the pointer to before the escape.
	dcx	h
	shld	cmcptr
	shld	cmdptr
	lxi	h,cmccnt	;Get the char count.
	dcr	m		;Decrement it by one.
	mov	a,e		;Save character count up to now.
	sta	temp1
	cpi	9		;Past '.'?
	jm	cmfrec		;No.
	dcr	a		;Yes, don't count point.
cmfrec:	lhld	cmfcb2		;Fill the rest with CP/M wildcards.
cmfrc1:	cpi	11		;Done?
	jp	cmfrc2		;Yes.
	mvi	m,'?'
	inx	h
	inr	a
	jmp	cmfrc1

cmfrc2:	mvi	c,sfirst	;Find first matching file?
	lhld	cmfcb
	xchg
	call	bdos
	cpi	0FFH
	jz	cmfrc9		;No, lose.
	lxi	h,fcbblk	;Copy first file spec.
	call	fspcop
	lxi	h,fcbblk+10H	;Get another copy (in case not ambiguous).
	call	fspcop
	mvi	c,snext		;More matching specs?
	lhld	cmfcb
	xchg
	call	bdos
	cpi	0FFH
	jz	cmfrc3		;Only one.
	lxi	h,fcbblk+10H	;Copy second file spec.
	call	fspcop
cmfrc3:	lxi	d,fcbblk	;Start comparing file names.
	lxi	h,fcbblk+10H
	lda	temp1		;Bypass characters typed.
	cpi	9		;Past '.'?
	jm	cmfrc4		;No.
	dcr	a		;Yes, don't count point.
cmfrc4:	mvi	c,0
cmfrl1:	cmp	c		;Bypassed?
	jz	cmfrl2		;Yes.
	inx	d
	inx	h
	inr	c
	jmp	cmfrl1		;Repeat.

cmfrl2:	mov	a,c		;Get file name characters processed.
	cpi	11		;All done?
	jz	cmfrc5		;Yes.
	cpi	8		;End of file name?
	jnz	cmfrl3		;No.
	lda	temp1		;Exactly at point?
	cpi	9
	jz	cmfrl3		;Yes, don't output a second point.
	mvi	a,'.'           ;Output separator.
	call	cmfput
cmfrl3:	ldax	d		;Get a character from first file spec.
	inx	d
	mov	b,m		;Get from second file spec.
	inx	h
	cmp	b		;Compare.
	jnz	cmfrc5		;Ambiguous.
	inr	c		;Same, count.
	cpi	' '             ;Blank?
	jz	cmfrl2		;Yes, don't output.
	call	cmfput		;Put character into buffer.
	jmp	cmfrl2		;Repeat.

cmfrc5:	mov	a,c		;Get count of characters processed.
	sta	temp1		;Save it.
	mvi	a,'$'           ;Get terminator.
	call	cmfput		;Put it into buffer.
	lhld	cmdptr		;Output recognized characters.
	xchg
	mvi	c,prstr
	call	bdos
	lhld	cmcptr		;Remove terminator from buffer.
	dcx	h
	shld	cmcptr
	lxi	h,cmccnt
	dcr	m
	lda	temp1		;Characters processed.
	cpi	11		;Complete file name.
	jz	repars		;Yes, don't beep.

cmfrc9:	mvi	c,conout
	mvi	e,bell
	call	bdos		;Ring the bell.
	jmp	repars
;
;       Continue file spec parsing.

cmif13:	mov	a,e		;It must be a terminator.
	ora	a		;Test the length of the file name.
	jz	cmifi9		;If zero complain.
	cpi	0DH
	jp	cmifi9		;If too long complain.
	jmp	rskp		;Otherwise we have succeeded.

cmifi2:	cpi	'.'
	jnz	cmifi3
	inr	e
	mov	a,e
	cpi	1H		;Any chars yet?
	jz	cmifi9		;No, give error.
	cpi	0AH		;Tenth char?
	jp	cmifi9		;Past it, give an error.
	mvi	c,9H
	mvi	b,0
	lhld	cmfcb
	dad	b		;Point to file type field.
	shld	cmfcb2
	mvi	e,9H		;Say we've gotten nine.
	jmp	cmifi1		;Get the next char.

cmifi3:	cpi	':'
	jnz	cmifi4
	inr	e
	mov	a,e
	cpi	2H		;Is it in the right place for a drive?
	jnz	cmifi9		;If not, complain.
	lhld	cmfcb2
	dcx	h		;Point to previous character.
	mov	a,m		;Get the drive name.
	sui	'@'             ;Get the drive number.
	shld	cmfcb2		;Save pointer to beginning of name field.
	mvi	m,space		;[obs] restore a space in FCB
	dcx	h		;Point to drive number.
	mov	m,a		;Put it in the fcb.
	mvi	e,0		;Start character count over.
	jmp	cmifi1

cmifi4:	cpi	'*'
	jnz	cmifi7
	lda	cmfwld		;Wildcards allowed?
	cpi	0
	jz	cmif11		;No,complain
	mov	a,e
	cpi	8H		;Is this in the name or type field?
	jz	cmifi9		;If its where the dot should be give up.
	jp	cmifi5		;Type.
	mvi	b,8H		;Eight chars.
	jmp	cmifi6

cmifi5:	mvi	b,0CH		;Three chars.
cmifi6:	lhld	cmfcb2		;Get a pointer into the FCB.
	mvi	a,'?'
	mov	m,a		;Put a question mark in.
	inx	h
	shld	cmfcb2
	inr	e
	mov	a,e
	cmp	b
	jm	cmifi6		;Go fill in another.
	jmp	cmifi1		;Get the next char.

cmifi7:	cpi	'!'             ;[pcc007] control chr or space?
	jm	cmifi9		;[pcc007] yes, illegal
	mov	h,a		;[5] stash input char for a bit
	lda	ffussy		;[5]  while we check the fussy flag
	ora	a		;[5] set the flags accordingly
	mov	a,h		;[5] restore the input character
	jz	cmif7a		;[5] if ffussy=0, allow <>.,;:?*[]
;[5] So far, we've eliminated "action characters" (including question),
;[5] period, colon, asterisk, control characters, and space.
;[5] That leaves us %(),/;<=>[\]_| to check for.
	cpi	'%'             ;[5]
	jz	cmifi9		;[5]
	cpi	'('             ;[5]
	jz	cmifi9		;[5]
	cpi	')'             ;[5]
	jz	cmifi9		;[5]
	cpi	','             ;[pcc007] weed out comma
	jz	cmifi9		;[pcc007]
	cpi	'/'             ;[5]
	jz	cmifi9		;[5]
	cpi	'9'+1           ;[pcc007] anything else 21H-39H is ok
	jm	cmifi8		;[pcc007] except '*' never gets here
	cpi	'@'             ;[pcc007] all of 3AH-3FH is illegal
	jm	cmifi9		;[pcc007]
	cpi	'['             ;[pcc007] [\] also illegal
	jm	cmifi8		;[pcc007]
	cpi	']'+1           ;[pcc007]
	jm	cmifi9		;[pcc007]
	cpi	'_'             ;[5]
	jz	cmifi9		;[5] (If I was doing CP/M, I would have
	cpi	'|'             ;[5]  just eliminated all them funny chars
	jz	cmifi9		;[5]  instead of a random selection)
cmif7a:				;[5]
	cpi	'a'             ;[pcc007] if not lower case its ok
	jm	cmifi8		;[pcc007] (DEL never gets here)
	cpi	'z'+1           ;[pcc007] only convert letters
	jp	cmifi8		;[pcc007]
	ani	137O		;Capitalize.
cmifi8:	lhld	cmfcb2		;Get the pointer into the FCB.
	mov	m,a		;Put the char there.
	inx	h
	shld	cmfcb2
	inr	e
	jmp	cmifi1

cmifi9:	lda	cmstat
	cpi	cmifin		;"silent"?
	jz	r		;Yes,let him go w/o check
	lxi	d,cmer02
cmif10:	mvi	c,prstr
	call	bdos
	ret

cmif11:	lxi	d,cmer03	;Complain about wildcards.
	jmp	cmif10

;

;       copy filename from buffer
;       called with HL = destination, A = position (0-3) in buffer
;       called by: cmifil

fspcop:	push	psw		;Save A.
	lxi	d,buff		;Get the right offset in the buffer.
	rlc
	rlc
	rlc
	rlc
	rlc
	add	e
	inr	a		;Bypass drive spec.
	mov	e,a
	mvi	b,11		;Copy file name.
fspcp1:	ldax	d
	inx	d
	mov	m,a
	inx	h
	dcr	b
	jnz	fspcp1
	pop	psw		;Restore A.
	ret

;       append character in A to command buffer
;       called by: cmifil

cmfput:	push	h		;Save H.
	lhld	cmcptr		;Get buffer pointer.
	mov	m,a		;Store in buffer.
	inx	h
	shld	cmcptr
	lxi	h,cmccnt	;Count it.
	inr	m
	pop	h		;Restore H.
	ret
;
;       Read characters from the command buffer.
;       called by:  cmtext, cmcfrm, cmkeyw, cmifil

cmgtch:	push	h
	push	b
cmgtc1:	lda	cmaflg
	ora	a		;Is it set.
	cz	cminbf		;If the action char flag is not set get more.
	lhld	cmdptr		;Get a pointer into the buffer.
	mov	a,m		;Get the next char.
	inx	h
	shld	cmdptr
	cpi	' '             ;Is it a space?
	jz	cmgtc2
	cpi	tab		;Or a tab?
	jnz	cmgtc3
cmgtc2:	lda	cmsflg		;Get the space flag.
	ora	a		;Was the last char a space?
	jnz	cmgtc1		;Yes, get another char.
	mvi	a,0FFH		;Set the space flag.
	sta	cmsflg
	mvi	a,' '
	pop	b
	pop	h
	jmp	cmgtc5

cmgtc3:	push	psw
	xra	a
	sta	cmsflg		;Zero the space flag.
	pop	psw
	pop	b
	pop	h
	cpi	esc
	jz	cmgtc5
	cpi	'?'             ;Is the user curious?
	jz	cmgtc4
	cpi	cr
	jz	cmgtc4
	cpi	lf
	jz	cmgtc4
	cpi	ff
	rnz			;Not an action char, just return.
cmgtc4:	push	h
	lhld	cmdptr
	dcx	h
	shld	cmdptr
	pop	h
cmgtc5:	ori	80H		;Make the char negative to indicate it is
	ret			;a terminator.
;
;       Read characters from console into command buffer, processing
;       editing characters (^H, ^M, ^J, ^L, ^U, ^X, ?, del).
;       called by: comnd, cmgtch

cminbf:	push	psw
	push	d
	push	h
	lda	cmaflg		;Is the action char flag set?
	ora	a
	jnz	cminb9		;If so get no more chars.
cminb1:	lxi	h,cmccnt	;Increment the char count.
	inr	m
	mvi	c,conin		;Get a char.
	lda	cmqflg		;[MF]but do we want it echoed?
	ora	a		;[MF]...
	jz	cmin1b		;[MF]Yup, proceed normally
cmin1c:	mvi	e,0ffH		;[MF]Nope, do it with Direct
	mvi	c,dconio	;[MF]Console I/O
	call	bdos		;[MF]...
	ora	a		;[MF]Did the user type anything?
	jz	cmin1c		;[MF]No, don't go on until he/she does.
	jmp	cmin1a		;[MF]We got a character
cmin1b:	call	bdos
cmin1a:	lhld	cmcptr		;Get the pointer into the buffer.
	mov	m,a		;Put it in the buffer.
	inx	h
	shld	cmcptr
	cpi	25O		;Is it a ^U?
	jz	cmnb12		;Yes.
	cpi	30O		;Is it a ^X?
	jnz	cminb2
cmnb12:	call	clrlin		;Clear the line.
	call	prprmp		;Print the prompt  [Toad Hall]
	lxi	h,cmdbuf
	shld	cmcptr		;Reset the point to the start.
	lxi	h,cmccnt	;Zero the count.
	mvi	m,0
	jmp	repars		;Go start over.

cminb2:	cpi	10O		;Backspace?
	jz	cminb3
	cpi	del		;or Delete?
	jnz	cminb4
	lda	cmqflg		;[MF]If we are echoing characters,
	ora	a		;[MF]...
	cz	delchr		;Print the delete string. [MF]
cminb3:	lda	cmccnt		;Decrement the char count by two.
	dcr	a
	dcr	a
	ora	a		;Have we gone too far?
	jp	cmnb32		;If not proceed.
	mvi	c,conout	;Ring the bell.
	mvi	e,bell
	call	bdos
	jmp	cmnb12		;Go reprint prompt and reparse.

cmnb32:	sta	cmccnt		;Save the new char count.
	lda	cmqflg		;[MF]Echoing characters?
	ora	a		;[MF]If we are, then
	cz	clrspc		;Erase the character. [MF]
	lhld	cmcptr		;Get the pointer into the buffer.
	dcx	h		;Back up in the buffer.
	dcx	h
	shld	cmcptr
	jmp	repars		;Go reparse everything.

cminb4:	cpi	'?'             ;Is it a question mark.
	jz	cminb6
	cpi	esc		;Is it an escape?
	jz	cminb6
	cpi	cr		;Is it a carriage return?
	jz	cminb5
	cpi	lf		;Is it a line feed?
	jz	cminb5
	cpi	ff		;Is it a formfeed?
	jnz	cminb8		;no - just store it and 
				;test if buffer overflowing, else get another character.
	call	clrtop
cminb5:	lda	cmbflg		;[MF]Allowing initial blank word (<cr>)?
	ora	a		;[MF]...
	jnz	cminb6		;[MF]Yes
	lda	cmccnt		;Have we parsed any chars yet?
	cpi	1
	jz	prserr		;If not, just start over.
cminb6:	mvi	a,0FFH		;Set the action flag.
	sta	cmaflg
	jmp	cminb9

cminb8:
	lda	cmccnt		; get the command character count
	cpi	cmbufl		; check for comand buffer length
	jm	cminb1		; if less, then all ok
	mvi	e,bell		; else beep at user
	call	outcon		; send it to the console
	lda	cmccnt		; back up one character
	dcr	a
	sta	cmccnt
	lhld	cmcptr		; ditto pointer
	dcx	h
	shld	cmcptr		; save it again
	jmp	cminb1		; and try again

cminb9:	pop	h
	pop	d
	pop	psw
	ret
;
;Little utility to print the prompt.  (We do a LOT of these.)  [Toad Hall]
;Enters with nothing.
;Destroys HL (and I suppose B and DE and A).
 
prprmp:	mvi	e,cr		; do a cr first
	mvi	c,dconio
	call	bdos
	lhld	cmprmp		;Get the prompt.
	xchg
	call	prtstr
	ret

; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FOR RELEASE!

;	org ($+100h) AND 0FF00H


IF	lasm
LINK	CPSUTL
ENDIF	;lasm  [Toad Hall]
