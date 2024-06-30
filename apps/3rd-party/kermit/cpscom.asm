; CPSCOM.ASM
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
;       This file contains some of the main loop commands, all SET xxx and
;	status routines.  File split from CPSMIT.ASM as that file 
;	was getting too big.
;
; revision history:
;
;edit 13, 25-Mar-1991 by MF. Require confirmation if a STAY command
;	(code at "noexit") is given and a question-mark is entered.
;edit 12, 21-Mar-1991 by MF.  Change SET COLLISSION REPLACE to
;	SET COLLISION OVERWRITE to conform with C-Kermit. Modify SET COLLISION
;	help text slightly.

;edit 11, 27-Feb-1991 by MF. Show Kermit version in VERSION command
;	("shover").
;edit 10, 12-Feb-1991 by MF. Modified OUTPUT command to get a "confirm"
;	after accepting the string to be output so that the OUTPUT command
;	doesn't immediately execute if a terminator other than <cr> is typed
;	(immediate execution confuses some users new to Kermit). This
;	situation should seldom, if ever, occur, as the OUTPUT command
;	is most likely to be executed in a TAKE-file but one should
;	protect oneself, shouldn't one?
;	Also commented out case-sensivity code as it is unlikely to be used.
;edit 9, 4-Dec-1990 by MF. Add "stautr" routine to display Autoreceive
;	status in SHOW/STATUS/<ESC>S commands.
;edit 8, 30-Nov-1990 by MF. Modify routine "statvt" (terminal status) to
;	display setting of "quiet" switch. Although I presume that Mr.
;	Schou thought the code would accommodate display of QUIET or
;	REGULAR, the code does not in fact allow this since the emulation
;	flag is not involved in the "quiet" setting.
;	Also fix SET TERMINAL's help text a bit.
;edit 7, 8-Nov-1990 by MF.  In SET {RECEIVE/SEND} PACKET-LENGTH routines,
;	call utility routine subbc from CPSUTL.ASM to do 16-bit subtraction
;	rather than doing it in-line to save a few bytes.  Eliminate
;	commented-out instructions.
;edit 6, 1-Nov-1990 by MF.  Changed SET BAUD-RATE to SET SPEED in the quest
;	for uniformity of nomenclature (per request of FDC).
;edit 5, 17-Oct-1990 by MF.  Change SET {RECEIVE SEND} PACKET-SIZE to
;	SET {RECEIVE SEND} PACKET-LENGTH to conform with the nomenclature
;	suggested in Chapter 10 of the 6th edition of the Kermit Protocol
;	Manual.
;edit 4, 14-Sep-1990 by MF.  Implemented SET FILE-COLLISION (SET COLLISION)
;	command (except for SET COLLISION ASK and SET COLLISION APPEND).
;	How one APPENDs to a CP/M file depends upon whether it's ASCII or
;	BINARY -- something we may not know.
;	Also implemented SET INCOMPLETE-FILE command.
;	Let's also restore SET FILE-MODE DEFAULT:  I never use it but if
;	we leave the DEFAULT code, as Version 4.09 does, the user is entitled
;	to be able to select it if he/she wishes (I'd favor getting rid
;	of it altogether but as soon as I did that, someone'd come out
;	of the woodwork and complain vehemently that he/she **likes** 
;	SET FILE-MODE DEFAULT and would the so-and-so who took it out
;	please put it back in.  Such is life.  In any case, the user can
;	always set the file-mode from a take-file.
;edit 3, 9-Sep-1990 by MF.  Implemented setting of packet sizes for
;	packets up thru length 94 characters for SEND and RECEIVE.  Even
;	for standard-length packets, variable sizes are useful.
;	Correct 16-bit subtraction in stspks/strpks to set carry if needed
;	Also corrected bug in routine getnp wherein a JMP KERMIT
;	instruction was left out after trying to parse a confirm, thus
;	skipping loading of number into HL.
;	Fixed bug in PRTSTR wherein BC/HL were not saved under certain
;	conditions, thus causing garbage to appear when PRTSTR was
;	called with QUIETD set.
; edit 2, September 10, 1987, by OBSchou.  Changed SET IBM to reset the 
;	flow control flag.  IBMs use 13h as a turnaround character (so they
;	say) so no flow control.  Anybody willing to add comments etsc, as I 
;	have NO IDEA what IBMs do or need.
;	Also removed the SET FILE-MODE DEFAULT option, as it always causes
;	so much trouble.  Assume the default mode to be ASCII.  Moved a test
;	for key pressed from the status routine to the CPSUTL file.
;
; edit 1, April 8th, 1987.
;	Hived off the SET command etc from CPSMIT.ASM to 
;	make a more manageable file


comver:	db	'CPSCOM.ASM (13) 25-Mar-1991$'	;name, edit no. and date
;
;
; This is the SET command.

setcom:	lxi	d,settab	;Parse a keyword from the set table.
	lxi	h,sethlp
	call	keycmd
	xchg		; Get result (dispatch address) into HL
	pchl		; Dispatch.

settab:	db	26		;[pcc013] 16 entries [Toad Hall] [9], now 17
				;[11] removed XMIT and added CASE and FLOW-CTL
				; Value is address of processing routine.
				;[14] removed SET CASE-SENSITIVE for now
				;[DRJ] Added SET USER. settab = 22
				;[OBS] Added SET AUTORECEIVE. 
				; and SET NO-EXIT.  settab = 24
				;[MF]Added SET COLLISION, settab=25
				;[MF]Added Set Incomplete settab=26
	db	11,	'AUTORECEIVE$'
		dw setaut
	db	16,	'BLOCK-CHECK-TYPE$'
		dw blkset
	db	11,	'BUFFER-SIZE$'
		dw setbuf
;       db      14,	'CASE-SENSITIVE$'   ;[10]
;               dw setcase              ;[10]
	db	9,'COLLISION$'	;[MF]
	dw	setcol		;[MF]
	db	5,	'DEBUG$'
		dw setdbg
	db	12,	'DEFAULT-DISK$'
		dw setdisk
	db	19,	'DIRECTORY-FILE-SIZE$'
		dw hidef
	db	6,	'ESCAPE$'
		dw escape
	db	9,	'FILE-MODE$'
		dw setcpm
	db	12,	'FLOW-CONTROL$'	;[10]
		dw setflo		;[10]
	db	3,	'IBM$'
		dw ibmset
	db	16,'INCOMPLETE-FILES$'
	dw	setinc		;[MF]Set Incomplete
	db	10,	'LOCAL-ECHO$'
		dw locall
	db	7,	'LOGGING$'		;[pcc013]
		dw setlog		;[pcc013]
	db	7,	'NO-EXIT$'
		dw noexit
	db	6,	'PARITY$'
		dw parset
	db	4,	'PORT$'
		dw prtset
	db	7,	'PRINTER$'
		dw setprn
	db	7,	'RECEIVE$'		;[gnn]
		dw setrec		;[gnn]
	db	4,	'SEND$'		;[gnn]
		dw setsnd		;[gnn]
	db	5,	'SPEED$';[MF]
		dw baud
	db	7,	'TACTRAP$'
		dw settac
	db	8,	'TERMINAL$'
		dw vt52em
	db	5,	'TIMER$'
		dw settim
	db	4,	'USER$'		;[DJR]
		dw user		;[DJR]
	db	7,	'WARNING$'
		dw filwar

; help message for SET command. Caps indicate keywords

sethlp:	db	cr,lf,'AUTORECEIVE to automatically re-receive files'
	db	cr,lf,'BLOCK-CHECK-TYPE for error detection'
	db	cr,lf,'BUFFER-SIZE for multi-sector buffering'
;       db      cr,lf,'CASE-SENSITIVE to equate lower and upper case'   ;[10]
	db	cr,lf,'COLLISION to specify action for filename conflicts'
	db	cr,lf,'DEBUG message control'
	db	cr,lf,'DEFAULT-DISK to receive data'
	db	cr,lf,'DIRECTORY-FILE-SIZE when displaying directories'
	db	cr,lf,'ESCAPE character during CONNECT'
	db	cr,lf,'FILE-MODE for outgoing files'
	db	cr,lf,'FLOW-CONTROL to set XON/XOFF flow control'	;[10]
	db	cr,lf,'IBM mode: parity and turn around handling'
	db	cr,lf,'INCOMPLETE-FILE disposition'
	db	cr,lf,'LOCAL-ECHO (half-duplex)'
	db	cr,lf,'LOGGING of terminal sessions'	;[pcc013]
	db	cr,lf,'NO-EXIT to prevent exit to CP/M after a command tail'
	db	cr,lf,'PARITY for communication line'
	db	cr,lf,'PORT to communicate on'
	db	cr,lf,'PRINTER copy control'
	db	cr,lf,'RECEIVE parameters'	;not all currently implemented
	db	cr,lf,'SEND parameters'		;Ditto
	db	cr,lf,'SPEED of communication line'
	db	cr,lf,'TAC interface support'
	db	cr,lf,'TERMINAL to set a terminal type'
	db	cr,lf,'TIMER control'
	db	cr,lf,'USER to set a user number'		;[DJR]
	db	cr,lf,'WARNING for filename conflicts'
	db	'$'

;
; SET AUTORECEIVE on/off command
setaut:	call	onoff		; set it either on or off
	sta	autorc		; and save the flag
	jmp	kermit		; and do next command

;SET BLOCK-CHECK-TYPE command.

blkset:	lxi	d,blktab	;Get the address of the block-check table
	lxi	h,blkhlp	;And the address of the help text
	call	chkkey		;Go check input (val returns in A).
	sta	chktyp		;Save desired checksum type
	jmp	kermit		;Go get another command

blktab:	db	3		;Three entries.
	db	20,	'1-CHARACTER-CHECKSUM$',	'1','1'
	db	20,	'2-CHARACTER-CHECKSUM$',	'2','2'
	db	21,	'3-CHARACTER-CRC-CCITT$',	'3','3'

blkhlp:	db	cr,lf,'1-CHARACTER-CHECKSUM'
	db	cr,lf,'2-CHARACTER-CHECKSUM'
	db	cr,lf,'3-CHARACTER-CRC-CCITT$'

;
;       This is the SET BUFFER-SIZE command.  
;       Sets to maximum number of sectors to use for multiple sector 
;       buffering.  Sorts a lot f problems on some slow disc-access machines..
setbuf:	mvi	a,cmnum		; get a number from the user 
	call	comnd
	jmp	kermit		; error if nothing
	lhld	number		; get the value
	mov	a,h
	ana	a
	jnz	setbu1		; if number greater than 255 then error
	lda	maxbsc		; get maximum no sectors allowed by system
	cmp	l		; set flags from a-l
	jm	setbu1		; if l > a then error
	mov	a,l		; only ls bits used
	sta	bufsec
	jmp	kermit

setbu1:	lxi	d,erms25
	call	prtstr
	jmp	kermit


;SET DEFAULT DISK command

setdisk:lxi	d,fcb
	mvi	a,cmifin	;get "file-spec" silently
	call	comnd
	jmp	setdi1
setdi1:	lda	fcb
	ora	a		;Was a drive specified? (if zero, no)
	jnz	setdi2		;he typed a drive-spec
	lda	curdsk		;he didn't - give him default
setdi2:	sta	curdsk
	mvi	c,inbdos	;reset disks
	call	bdos
	lda	curdsk
	dcr	a		;LOGDSK is relative 0
	mov	e,a
	mvi	c,logdsk
	call	bdos		;and "LOG" it
	jmp	kermit		;all done
;
;SET SEND command.  Sort of supported

setsnd:	lxi	d,stsntb	;Parse a keyword from the set send table.
	lxi	h,stshlp
	call	keycmd
	xchg		; Get dispatch address into HL
	pchl		; Go for it.

stsntb:	db	4		;Two entries.  four entries
	db	8, 'PAD-CHAR$'
		dw stspac
	db	7, 'PADDING$'
		dw stspad
	db	15, 'START-OF-PACKET$'	;[gnn]
		dw stssop		;[gnn]
	db	13,'PACKET-LENGTH$'	;
		dw stspks		;
;	db	9,'CHECKTYPE$'		;
;		dw stsckt		;

stshlp:	db	cr,lf,'PAD-CHAR to define the pad character to use'
	db	cr,lf,'PADDING to define the number of PAD-CHAR to use'
	db	cr,lf,'START-OF-PACKET to define the start of packet character'	;[gnn]
	db	cr,lf,'PACKET-LENGTH for the length of transmitted packet';
;	db	cr,lf,'CHECKTYPE to define the check-type to use';[21]
	db	'$'		;[gnn]

; SET SEND START-OF-PACKET   [gnn]
stssop:	call	cfmcmd
	lxi	d,sopmes
	call	prtstr
	mvi	c,conin
	call	bdos
	sta	sndsop
	jmp	kermit

; SET SEND PADDING command. does nothing.  get value to dspad
stspad:	call	getnp		; get the number of padding characters
	sta	dspad		; save ad default send no. pad characters
	jmp	kermit

; SET SEND PAD-CHAR command. does nothing.  gets char to dspadc
stspac:	call	getpad		; get the character to use
	sta	dspadc		; save as default send pad character
	jmp	kermit

; SET SEND PACKET-LENGTH command.  Max 95, but could be more for long pkts...
stspks:	call	getnp		; get number into hl
	lxi	b,(maxpkt-1)	;[MF] One below upper limit of packet-size
	push	h		;[MF] Save number
	call	subbc		;[MF] Do 16-bit subtraction, even though
				;[MF] getnp puts low-order bits in a,
				;[MF] in case long packets are
				;[MF] implemented
	pop	h		;[MF] Restore number
	lxi	d,erms26	; packet length to long error
	jnc	stspk1
	mov	a,l
	sta	spsiz		;[MF] Save as default send packet length
	jmp	kermit
stspk1:	call	prtstr
	jmp	kermit		; error exit

; SET SEND CHECKTYPE command. Accepts 1,2 or 3
stsckt:	call	getnp		; get a number
	cpi	4		; if more than 3 then error
	jnz	stsck1
stsck2:	lxi	d,erms27	; checktype wrong
	jmp	kermit
stsck1:	cpi	0		; error also for null
	jz	stsck2
	adi	30h		; make it printable
	sta	sdckt		; save as default send checktype
	jmp	kermit


;SET RECEIVE command.   [gnn]
setrec:	lxi	d,strctb	;Parse a keyword from the set rec table.
	lxi	h,stshlp	; use same help for send and receive
	call	keycmd
	xchg		; Get dispatch address into HL
	pchl		; Go for it.

strctb:	db	4		;  Three entries.  four entries
	db	8, 'PAD-CHAR$'
		dw strpac	; use dummy entry of set send
	db	7, 'PADDING$'
		dw strpad	; use dummy entry of set send
	db	15,'START-OF-PACKET$'
		dw strsop
	db	13,'PACKET-LENGTH$'		;
		dw strpks		;
;	db	9,'CHECKTYPE$'		;
;		dw strckt		;

; SET RECEIVE START-OF-PACKET  
strsop:	call	cfmcmd
	lxi	d,sopmes
	call	prtstr
	mvi	c,conin
	call	bdos
	sta	rcvsop
	jmp	kermit

; SET RECEIVE PADDING
strpad:	mvi	a,cmnum		; go parse a number
	call	comnd		; get it
	jmp	kermit		; duff entry, so die
	mvi	a,cmcfm		; ask to confirm
	call	comnd
	lhld	number		; get the number of padding charaters
	mov	a,l		; assume 255 or less
	sta	dspad		; save ad default send no. pad characters

; SET SEND RECEIVE routines
getpad:	call	cfmcmd
	lxi	d,padcms	; tell user we want the pad character
	call	prtstr
	mvi	c,conin		; get it verbatum
	call	bdos
	ret

; SET RECEIVE PAD-CHAR routine
strpac:	call	getpad		; get the character to use
	sta	drpadc		; save it
	jmp	kermit

; SET RECEIVE PACKET-LENGTH.  Max 95, but could be more for long pkts...
strpks:	call	getnp		; get number into hl
	lxi	b,(maxpkt-1)	;[MF] One below upper limit of packet-size
	push	h		;[MF] Save number
	call	subbc		;[MF] Do 16-bit subtraction, even though
				;[MF] getnp puts low-order bits in a,
				;[MF] in case long packets are
				;[MF] implemented
	pop	h		;[MF] Restore number
	lxi	d,erms26	; packet length to long error
	jnc	strpk1
	mov	a,l
	sta	rpsiz		;[MF] Save as default receive packet-length
	jmp	kermit
strpk1:	call	prtstr
	jmp	kermit		; error exit


; SET RECEIVE CHECKTYPE
strckt:	call	getnp		; get a number
	cpi	4		; if more than 3 then error
	jnz	strck1
strck2:	lxi	d,erms27	; checktype wrong
	jmp	kermit
strck1:	cpi	0		; error also for null
	jz	strck2
	adi	30h		; make it printable
	sta	rdckt		; save as default receive checktype
	jmp	kermit

getnp:	mvi	a,cmnum		; go parse a number
	call	comnd		; get it
	jmp	kermit		; duff entry, so die
	mvi	a,cmcfm		; ask to confirm
	call	comnd
	  jmp	kermit		;[MF] Die!
	lhld	number		; get the number of padding charaters
	mov	a,l		; assume 255 or less
	ret		; return to caller


; SET NO-EXIT on/off.  Sets a flag to prevent automatically dropping 
;	back to CPM after a command tail has been "done".  No other use.
noexit:	call	cfmcmd		;[MF]Get a "confirm" in case here via STAY
	xra	a
	sta	nexitf		; no exit to CP/M
	jmp	kermit

;[pcc013]
;       This is the SET LOGGING ON/OFF subcommand

setlog:	call	onoff		;[pcc013] Get on/off
	sta	logflg		;[pcc013] Store flag
	jmp	kermit
;
;       This is the SET ESCAPE character subcommand.

escape:	call	cfmcmd
	lxi	d,escmes	;Get the address of the escape message.
	call	prtstr
	mvi	c,conin		;Get the char.
	call	bdos
	sta	escchr		;Store the new escape character.
	jmp	kermit

;       This is the SET LOCAL-ECHO subcommand.

locall:	call	onoff		;Get on/off setting [Toad Hall]
	sta	ecoflg		;Store local echo flag.
	jmp	kermit

;       This is the SET PRINTER ON/OFF subcommand

setprn:	call	onoff		;Get on/off setting [Toad Hall]
	sta	prnflg		;Store printer flag
	jmp	kermit

;       This is the SET DEBUG ON/OFF subcommand

setdbg:	call	onoff		;Get on/off setting [Toad Hall]
	sta	dbgflg		;Store debug flag
	jmp	kermit

;[jd] this is the SET TIMER subcommand

settim:	call	onoff		;Get on/off setting [Toad Hall]
	sta	timflg		;Store timer flag value
	jmp	kermit

;This is the SET FILE-WARNING subcommand

filwar:	call	onoff		;Get on/off setting [Toad Hall]
	sta	flwflg		;Store file-warning flag.
	jmp	kermit

;[MF]This is the SET COLLISION subcommand
;[MF]First, the requisite tables:
;
coltab:	db	4		;[MF]4 entries
	db	6,'BACKUP$',02h,02h
	db	7,'DISCARD$',03h,03h
	db	9,'OVERWRITE$',00h,00h
	db	6,'RENAME$',01h,01h
;
colhlp:	db	cr,lf,'BACKUP (rename) existing files'
	db	cr,lf,'DISCARD new versions of existing files'
	db	cr,lf,'OVERWRITE existing files'
	db	cr,lf,'RENAME new versions of existing files'
	db	'$'
;
;[MF]Now the routine proper
;
setcol:	lxi	d,coltab	;[MF]Table address
	lxi	h,colhlp	;[MF]Help address
	call	chkkey		;[MF]Get user's answer
	sta	flwflg		;[MF]and remember it
	jmp	kermit		;[MF]Back to main loop

;[10] This is the SET FLOW-CONTROL subcommand.
setflo:	call	onoff		;is it on or off
	sta	floctl		; store flow contol flag
	jmp	kermit

;[10] SET CASE-SENSITIVE on or off
;setcase:	
;	call	onoff		; set it on or off
;	sta	casens		; save it
;	jmp	kermit

; SET FILE-SIZE on or off.  If on, then show file size during DIR
;
hidef:	call	onoff		; see if on or off
	sta	hidefs
	jmp	kermit

;
;       This is the SET IBM command.
;
;	If SET IBM ON, we should do
;		1)  Flow Control = off
;		2)  Parity = mark
;		3)  Local echo = on
;		4)  Timer = on
;
;	If SET IBM OF, we should assume (& do)
;		1)  Flow control = off (default)
;		2)  Parity = none
;		3)  Local Echo = off
;		4)  Timer = off


ibmset:	call	onoff		;Get on/off setting [Toad Hall]
	sta	ibmflg		;Store IBM flag.
	ora	a		;Is it turned on?
	jz	ibmst1		;If not, set parity to the default.
;
; SET IBM ON code
	mvi	a,ibmpar	;Get the IBM parity.
	sta	parity
	mvi	a,1		;Set local echo on.
	sta	ecoflg
	sta	timflg		; also set timer on
	xra	a		; no flow control
	sta	floctl
	jmp	ibmst2		; exit
;
; SET IBM OFF code

ibmst1:	mvi	a,defpar	; set default parity (none)
	sta	parity
	xra	a		;Set local echo off.
	sta	ecoflg
	sta	timflg		;[jd] timer is same as local echo
	sta	floctl		;[obs] set flow control off
ibmst2:	jmp	kermit		; exit from here

;
;       SET FILE-MODE command.
;[OBS] assume only ascii and binary, no default.

setcpm:	lxi	d,typtab
	lxi	h,typhlp
	call	chkkey		;Get and confirm keyword, or die trying
	sta	cpmflg		;Set the CPM flag.
	jmp	kermit

typtab:	db	3		;Three entries, now two entries
				;[MF]Now 3 again!
	db	5, 'ASCII$',	01H,01H
	db	6, 'BINARY$',	02H,02H
	db	7, 'DEFAULT$',	00H,00H	; Default

typhlp:	db	cr,lf,'ASCII	BINARY	DEFAULT'
	db	'$'
;
;setinc - Set Incomplete-file [MF]
;
setinc:	lxi	d,inctab	;[MF]Point to tables
	lxi	h,inchlp	;[MF]...
	call	chkkey		;[MF]Get user's answer or croak
	sta	incflg		;[MF]Remember the answer
	jmp	kermit		;[MF]We are done.
;
inctab:	db	2		;two entries
	db	7,'DISCARD$'
	db	00h,00h		;Discard incomplete files
	db	4,'KEEP$'
	db	01h,01h		;Keep incomplete files
;
inchlp:	db	cr,lf,'DISCARD	KEEP'
	db	'$'

;       This is the SET PARITY subcommand.

parset:	lxi	d,partab
	lxi	h,parhlp
	call	chkkey		;Get and confirm keyword, or die trying
	sta	parity		;Set the parity flag.
	jmp	kermit

partab:	db	5		;Five entries.
	db	4, 'EVEN$',	parevn,parevn
	db	4, 'MARK$',	parmrk,parmrk
	db	4, 'NONE$',	parnon,parnon
	db	3, 'ODD$',	parodd,parodd
	db	5, 'SPACE$',	parspc,parspc

parhlp:	db	cr,lf,'EVEN	MARK	NONE	ODD	SPACE$'

;       This is the SET TACTRAP subcommand.
;       options are ON, OFF, or CHARACTER.  (for CHARACTER, we request the
;       new TAC Intercept character, and turn the TACtrap on)

settac:	lxi	d,tactab
	lxi	h,tachlp
	call	chkkey		;Get and confirm keyword
	ora	a		;Was it "OFF" (zero)?
	jz	settc2		;If so, go disable TACtrap.
	cpi	1		;Was it "ON"?
	jz	settc1		;If so, go enable TACtrap.
	lxi	d,tacmes	;"CHARACTER". request new TAC Intercept char.
	call	prtstr
	mvi	c,conin		;Get the char.
	call	bdos
	sta	tacchr		;Store the new TAC Intercept character.
settc1:	lda	tacchr		;Copy tacchr to tacflg to enable TACtrap.
settc2:	sta	tacflg		;Enable/disable TACtrap
	jmp	kermit

tactab:	db	3		;Three entries.
	db	9,	'CHARACTER$',	02H,02H
	db	3,	'OFF$',		00H,00H
	db	2,	'ON$',		01H,01H

tachlp:	db	cr,lf,'ON to enable TAC trap'
	db	cr,lf,'OFF to disable TAC trap'
	db	cr,lf,'CHARACTER to enable TAC trap and'
	db	' specify intercept character$'

;       This is the SET VT52-EMULATION subcommand.
; Now SET TERMINAL xxx
;vt52em:	lda	vtflg		;get the flag value
;	cpi	0ffH		;0ffH means not allowed -
;	jz	notimp		; say it's not implemented.
;	call	onoff		;Get keyword (ON or OFF)
;	sta	vtflg		;Set the VT52 emulation flag.
;	jmp	kermit
vt52em:	lxi	d,sttert	; set terminal type
	lxi	h,stterh	; help table
	call	chkkey		; get it
	mov	a,d		; value returned in DE
	cpi	vtdefe		; was it selecting an external terminal?
	jnz	vt52e1		; no, so save new value
	lhld	extern+1	; if external, lets see if one is in place
	mov	a,h
	ora	l
	mvi	a,vtdefe	; restore external flag
	jnz	vt52e1		; we have one, so we can save value
	call	prcrlf
	lxi	d,inms11	; load up sorry message
	call	prtstr
	jmp	kermit

vt52e1:	cpi	40h		; are we to have a quiet display?
	jnz	vt52e2
	sta	quietd		; store it
	jmp	kermit

vt52e2:	cpi	80h		; are we to be a noisy display?
	jnz	vt52e3
	xra	a
	sta	quietd
	jmp	kermit

vt52e3:	sta	vtflg		; else save new set parameter..
	jmp	kermit		; and exit

; tabe with string entry, and the returned value as two identical bytes.
sttert:	db	6		; six types
	db	4,'DUMB$',vtdefd,vtdefd		; assume our terminal is thick
	db	8,'EXTERNAL$',vtdefe,vtdefe	; assume off, but terminal is in dep. code
	db	5,'QUIET$',40h,40h		; display quiet
	db	7,'REGULAR$',80h,80h		; display loud
	db	3,'OFF$',vtdefo,vtdefo		; assume our terminal does everything
	db	4,'VT52$',vtdefv,vtdefv		; VT52 as before

stterh:	db	cr,lf,'DUMB - only printable characters passed to terminal'
	db	cr,lf,'EXTERNAL - with emulation code system specific'
	db	cr,lf,'OFF - all characters passed to terminal'
	db	cr,lf,'QUIET - display nothing during transfers'
	db	cr,lf,'REGULAR - normal display for transfers'
	db	cr,lf,'VT52 - assume Kermit can emulate a VT52'
	db	'$'

;
;       Note:  For the SET BAUD and SET PORT commands, which might not be
;       supported for the current system, the command tables are stored in
;       the overlay.  We locate them through pointers in the linkage area:
;       spdtab for SET BAUD, prttab for SET PORT.  The contents of spdtab
;       (or prttab) is the address of the beginning of the table (the table
;       does NOT begin at spdtab).  If the address is zero, the command is
;       not supported.  If the table address is nonzero, then there is a
;       corresponding help message pointed to by (NOT starting at) spdhlp
;       or prthlp.

;       This is the SET BAUD command

baud:	lhld	spdtab		; get pointer to speed table
	mov	a,h
	ora	l		; test for NULL (zero)
	jz	notimp		; if so, say it's not implemented
	xchg		; move speed table address to DE
	lhld	spdhlp		; get pointer to speed help text
	call	keycmd
	push	d		; save selected speed
	call	cfmcmd		; confirm...
	pop	h		; restore speed to HL
	shld	speed		; save all 16 bits of speed value
	xchg		; move speed to DE
	call	sysspd		; do system-dependent speed setting.
	jmp	kermit		; return to command level

;       This is the SET PORT command

prtset:	lhld	prttab		; get pointer to port table
	mov	a,h
	ora	l		; test for NULL
	jz	notimp		; not supported if pointer was null.
	xchg		; move port table address to DE
	lhld	prthlp		; get pointer to port help text
	call	keycmd
	push	d		; save selected port entry
	call	cfmcmd		; confirm...
	pop	h		; restore table address to HL
	shld	port		;[hh] save all 16 bits of port value
	call	sysprt		; go do port stuff
	jmp	kermit
;
;       Subroutines for SET subcommands

;       ontab - command table for onoff.
;       onhlp - help text for onoff.
;       onoff - accept "ON" or "OFF" keyword.
;       returns:
;          success: value in A (non-zero = ON)
;          error: no return to caller. print error message and return to
;               main loop.
ontab:	db	2		;Two entries.
	db	3, 'OFF$',	00H,00H
	db	2, 'ON$',	01H,01H

onhlp:	db	cr,lf,'OFF	ON$'

onoff:	lxi	d,ontab
	lxi	h,onhlp
	;Fall through to check input.  [Toad Hall]

;       chkkey - parse and confirm keyword.
;       called with:
;          DE/ address of keyword table
;          HL/ address of help text
;       returns:
;          success: low byte of keyword value (from table) in A.
;          error: no return to caller.  print error message and return to
;               main loop.  (Since the main loop reloads the stack pointer,
;               we don't have to attempt to clean up the stack here)

chkkey:	call	keycmd		; Parse a keyword (might not return)
	sta	temp1		; Save the parsed value
	call	cfmcmd		; Request confirmation (might not return)
	lda	temp1		; Get saved value
	ret		; Return

;[hh]   fndkyw - find a keyword string from a table using 
;               it's associated value
;       called with:
;          HL/ address of keyword table
;           A/ value associated with keyword string
;       returns:
;          success: HL points to first byte of keyword string
;                   CY flag is cleared
;          error:   HL points to error string (?Not found)
;                   CY flag is set

fndkyw:	mov	d,m		;get count of entries
	inx	h		;advance over count value
fndkw1:	mov	b,m		;get string length
	inr	b		;account for $
	inx	h		;advance over length value
	shld	temp1		;save string pointer
fndkw2:	inx	h		;loop over string
	dcr	b
	jnz	fndkw2
	mov	c,m		;get keyword value from table
	cmp	c		;do they match?
	jz	fndkw3		;Yup
	inx	h		;bump to next keyword
	inx	h		;
	dcr	d		;decrement entry count
	jnz	fndkw1		;check the remaining keywords
	lxi	h,kywdnf	;point to not found message
	stc		;give calling routine a not found flag
	ret
fndkw3:	ora	a		;clear CY to tell caller we succeeded
	lhld	temp1		;restore the saved string pointer
	ret

kywdnf:	db	cr,lf,'?Not found$'	;not found message

;
;       This is the SHOW command.

show:	call	cfmcmd
;* Reconcile this and status.
	call	clrtop		;[hh] Clear screen first
	call	stat01		;For now just cop out.
	jmp	kermit

;       This is the STATUS command.

status:	call	cfmcmd
	call	clrtop		;[hh] Clear screen first
	call	stat01
	jmp	kermit

;       processor for SHOW, STATUS and <escape>S commands
;       called by: show, status, intchr

stat01:	lda	fileio		;Are we in transmit?
	ora	a
	jz	sta01b		;No
	lxi	d,xmtst		;Yes,say so
	call	prtstr

;       The following block of code - down to RET - re-ordered by  [DJR]
;       DJR January 1987 to get SHOW/STATUS output in the same     [DJR]
;       (alphabetical) order as SET's HELP.                        [DJR]
sta01b:
	call	stautr		;[MF]Show AUTORECEIVE state
        call    stabcc          ; Tell current block check type
        call    stabsz          ; Tell user about multi-sector buffers
	call	stacol		;[MF]COLLISION state
        call    stadbg          ; [DJR] Debug mode
        call    stacurd         ; [DJR] Current disk
        call    stahfs          ; Tell user if file sizez are hidden during DIR
        call    staesc          ; Tell current escape character
        call    stafil          ; Tell about file type
        call    staflo          ;[10] Tell about flow control
        call    staibm          ; Tell about IBM flag
	call	stainc		;[MF]Tell about incomplete file disposition
;
; Ask user to press a key before continuing
;
	call	pausit		; wait for a while till user presses a key
;
        call    staeco          ; Tell about local echo flag
        call    stalog          ; [pcc003] Tell about log file status
	call    stapar          ; Tell about parity
        lhld    prttab          ;[hh] Got a port table? (is pointer nonzero?)
        mov     a,h             ;[hh]
        ora     l               ;[hh]
        cnz     stapor          ;[hh] If so, tell which port we're using
        call    stalpt          ; Tell about printer copy flag
	call	starps		;[MF]Show receive packet length
        call    starsp          ;[gnn] tell rec. start-of-pkt char
	call	stasps		;[MF]Show send packet length
        call    stassp          ;[gnn] tell send start-of-pkt char
        lhld    spdtab          ; Got a speed table? (is pointer nonzero?)
        mov     a,h
        ora     l
        cnz     staspd          ; If so, tell what speed we're running.
        call    statac          ; Tell about TAC flag/intercept character.
        call    statim		; Tell about timer flag
        call	stusr		;[7] Tell about user
        call	statvt		; Tell about what emulation we are doing
        call    stawrn          ; Tell about file-warning flag
        ret

;	stautr - Show Autoreceive setting [MF]
;
stautr:	lxi	d,autrst	;[MF]Point to "Autoreceive" string
	call	prtstr		;[MF]and print it
	lda	autorc		;[MF]Get Autoreceive flag
	jmp	staton		;[MF]Say "on" or "off" and return

;       Show the value of the LOCAL-ECHO flag (On or Off).

staeco:	lxi	d,locst		;Get the address of the local echo string.
	call	prtstr
	lda	ecoflg		;Get the local echo flag.
	jmp	staton		;Say ON or OFF, and return

;       Show the value of the VT52-EMULATION flag (On, Off, or Not Supported).
;	Also show terminal display mode (regular, quiet)

statvt:	lxi	d,vtdpst	;[MF]Get address of terminal display string
	call	prtstr		;[MF]Print it
	lxi	d,vtdpsr	;[MF]Assume a regular (loud) display
	lda	quietd		;[MF]Get "quiet" flag
	ora	a		;[MF]a quiet display?
	jz	statva		;[MF]No, print "regular" message
	lxi	d,vtdpsq	;[MF]Yes, point to "quiet" string
statva:	call	prtstr		;[MF]and print it
	lxi	d,vtemst	; Get the address of the VT52 emulation string.
	call	prtstr
	lda	vtflg		; Get the VT52 emulation flag.
	cpi	0ffh		; isterminal emulation possible?
	jnz	statv0		; yes, maybe
	lxi	h,inms11	; ... no, load up not implemented message ...
	jmp	prvtv		; so tell user


statv0:	mov	c,a		; save it to C
	lxi	h,sttert	; get table listing what we can do
	mov	b,m		; get number of terminal types to b
statv1:	inx	h		; point to first entry
	mov	e,m		; get length of entry
	mvi	d,0
	inx	h		; point to text part of entry
	xchg		; save address in de
	dad	d		; start + length
	inx	h		;... + 1 for the dollar...
	inx	h		; plus point to seconcd copy of ter. type value
	cmp	m		; is it the one we want?
	jz	prvtv		; yes, then print the terminal type value
	dcr	b		; have we completed?
	rz		; yes, then just exit back to status
	jmp	statv1		; else try next entry.  HL points to next -1

prvtv:	jmp	prtstr		; print string from DE
				;[MF]and return

;       Show the value of the FILE-MODE flag (ASCII, Binary, or Default).

stafil:	lxi	d,cpmst		; Get the address of the file mode message.
	call	prtstr
	lda	cpmflg		; Get the file mode flag.
	lxi	d,defstr	; Assume Default (0).
	ora	a		; Is it?
	jz	prtstr		; If so, say so, and return.
	lxi	d,ascstr	; Not default, assume ASCII
	cpi	1		; Is it ASCII?
	jz	prtstr		; Say ASCII, and return
	lxi	d,binstr	; Not default or ASCII, must be binary
	jmp	prtstr		; Print type, and return.
;
;Show current disposition for incomplete files [MF]
;
stainc:	lxi	d,incst		;[MF]Announce what's to be shown
	call	prtstr		;[MF]...
	lxi	d,dscstr	;[MF]Assume "discard"
	lda	incflg		;[MF]Get flag
	ora	a		;[MF]Really discarding incomplete files?
	jz	prtstr		;[MF]Yes, say so and return
	lxi	d,kepstr	;[MF]No, say we're keeping incomplete files
	jmp	prtstr		;[MF]and return

;       show if file sizes are hidden during DIR (Would have thought this
;       obvious, but its in for completeness
stahfs:	lxi	d,hfsod		; get hide file size on dir
	call	prtstr
	lda	hidefs
	jmp	staton		; say if on or off

;       Show the value of the IBM-MODE flag (On or Off).

staibm:	lxi	d,ibmst		;IBM string.
	call	prtstr
	lda	ibmflg		; Get IBM flag.
	jmp	staton		; Print its value and return

;       Show the value of the FILE-WARNING flag (On or Off).

stawrn:	lxi	d,filst		; File warning string.
	call	prtstr
	lda	flwflg		; File warning flag.
	jmp	staton		; Say ON or OFF

;       Show the value of the PRINTER flag (On or Off).

stalpt:	lxi	d,prst		;Printer copy string
	call	prtstr
	lda	prnflg		;Printer ON/OFF flag
	jmp	staton		; Say ON or OFF


;       Show status of log file
stalog: lxi     d,logst         ;[pcc003] Logging lead-in message
        call    prtstr          ;[pcc003]
;       name of logging file
;   Code derived from [JD's] code for GET, and uses his FNBUF  [DJR]
        lxi    d,fnbuf         ;[DJR] point to destination
        lxi    h,lognam        ;[DJR] source of filespec
        mov    a,m             ;[DJR] get drive byte
        ora    a               ;[DJR] zero = default disc
        jnz    stalg1          ;[DJR] if drive has been specified
        lda    curdsk          ;[DJR]  otherwise get the default
stalg1: adi    'A'-1           ;[DJR] make it printable
        stax   d               ;[DJR] into dest block
        inx    d               ;[DJR]
        mvi    a,':'           ;[DJR] colon after drive
        stax   d               ;[DJR] 
        inx    d               ;[DJR] 

        mvi    c,8             ;[DJR] length of name part
        lxi    h,lognam+1      ;[DJR] start of name
        mvi    b,0             ;[DJR] first-time-thru flag
stalga: mov    a,m             ;[DJR] get a char from the name
        inx    h               ;[DJR] pass it
        cpi    ' '             ;[DJR] end of this part of name?
        jz     stalgb          ;[DJR] yes, skip rest...
        stax   d               ;[DJR] else drop char into dest
        inx    d               ;[DJR] increment dest ptr
        dcr    c               ;[DJR] decrement count
        jnz    stalga          ;[DJR] and continue if more to go

stalgb: mov    a,b             ;[DJR]
        ora    a               ;[DJR] first time thru?
        jnz    stalgc          ;[DJR] no, no period
        mvi    a,'.'           ;[DJR] period between parts
        stax   d               ;[DJR] 
        inx    d               ;[DJR] 
        mvi    b,0ffh          ;[DJR] not first time thru anymore
        mvi    c,3             ;[DJR] length of ext part
        lxi    h,lognam+9      ;[DJR] start of extension
        jmp    stalga          ;[DJR] keep copying

stalgc: mvi    a,'$'
        stax   d               ;[DJR] end the name string
        lxi    d,fnbuf         ;[DJR] Print the file name
        call   prtstr          ;[DJR]

	lxi    d,logst2        ;[DJR] second part of message
        call   prtstr          ;[DJR]

;	Show status of logging
	lda	logflg		;[pcc003] get the flag
	ani	7FH		;[pcc003] ignore open flag
	cpi	2		;[pcc003] is it suspended?
	jnz	staton		;[pcc003] no, must be on or off
	lxi	d,susstr	;[pcc003] suspended
	jp	prtstr		;[pcc003] print and return

;       Show the value of the PARITY flag (Odd, Even, Mark, Space, or None).

stapar:	lxi	d,parst		;Parity string.
	call	prtstr
	lda	parity		;Get the parity setting.
	lxi	d,pnonst	;Assume parity is NONE
	cpi	parnon		;Were we right?
	jz	prtstr		;Yep, go say None, and return
	lxi	d,pmrkst	;Get ready to say Mark
	cpi	parmrk		;Is it mark?
	jz	prtstr		;Yep, go say Mark, and return
	lxi	d,pspcst	;Get ready to say Space
	cpi	parspc		;Is it space?
	jz	prtstr		;Yep, go say Space, and return
	lxi	d,poddst	;Get ready to say Odd
	cpi	parodd		;Is it odd?
	jz	prtstr		;Yep, go say Odd, and return
	lxi	d,pevnst	;Must be Even.
	jmp	prtstr		;Say Even, and return.

; [gnn] Show start of packet characters
stassp:	lxi	d,sspmsg	;message of send s-o-p
	call	prtstr
	lda	sndsop
	adi	'A'-1		;convert to printable character
	mov	e,a
	mvi	c,conout
	jmp	bdos		;and print it
starsp:	lxi	d,rspmsg	;rec. s-o-p message
	call	prtstr
	lda	rcvsop
	adi	'A'-1		;convert to printable character
	mov	e,a
	mvi	c,conout
	jmp	bdos		;and print it
;
;[MF]Show receive packet length
;
starps:	lxi	d,rpsmsg	;[MF]Point to message
	call	prtstr		;[MF]and print it
	lda	rpsiz		;[MF]Get receive packet length
	mov	l,a		;[MF]Put in HL
	mvi	h,0		;[MF]...
	jmp	nout		;[MF]Print receive packet length in decimal
;
;[MF]stasps - Print send packet length
;
stasps:	lxi	d,spsmsg	;[MF]Point to message
	call	prtstr		;[MF]and print it
	lda	spsiz		;[MF]Get send packet length
	mov	l,a		;[MF]into HL
	mvi	h,0		;[MF]...
	jmp	nout		;[MF]and print in decimal

;[hh]   Show the current port (if known).

stapor:	lxi	d,porst		;[hh]
	call	prtstr		;[hh]
	lda	port		;[hh] Get current port value
	lxi	h,spdust	;[hh] Assume undefined (this error msg is fine)
	cpi	0FFH		;[hh] Is it?
	jz	stat73		;[hh] Yup. Say so
	lhld	prttab		;[hh] Address of port keyword table
	call	fndkyw		;[hh] Look for correct keyword string
	jnc	stpr1		;[hh] Found a match
	lxi	h,spdust	;[hh] No match found - say it's undefined
stpr1:	jmp	stat73		;[hh] Print it and return

;       Show the current line speed (if known).

staspd:	lxi	d,spdst
	call	prtstr
	lda	speed		;Get current speed.
	lxi	h,spdust	;Assume undefined.
	cpi	0FFH		;Is it?
	jz	stat73		;Yes.
	lhld	spdtab		;Start scanning keyword table.
	mov	d,m		; get count of entries
	inx	h		; advance over it.
stat70:	mov	b,m		;Get string length.
	inr	b		;Account for $.
	inx	h
	shld	temp1		;Save string pointer.
stat71:	inx	h		;Loop over string.
	dcr	b
	jnz	stat71
	mov	c,m		;Get speed value
	cmp	c		;Match?
	jz	stat72		;Yes.
	inx	h		;Bump to next keyword.
	inx	h
	dcr	d		; decrement entry count
	jnz	stat70		; if more left, check them.
	lxi	h,spdust	; can't find it. say it's undefined.
	jmp	stat73		; print the message.

stat72:	lhld	temp1		;Restore saved string pointer.
	xchg		;[MF] Set into DE for display
	call	prtstr		;[MF] Print speed
	lxi	h,spdst2	;[MF] Point to "bps" message
stat73:	xchg		;Set into DE for display.
	jmp	prtstr		; print it, and return.

;       Show the current BLOCK-CHECK-TYPE (1-, 2-, or 3-character).

stabcc:	lxi	d,bckst		;Get the string
	call	prtstr		;Print "Block check type: "
	lda	chktyp		;Get the type (character 1, 2, or 3)
	mov	e,a		;Put into E
	mvi	c,conout	;Want to print it
	call	BDOS		;Do so
	lxi	d,bckst1	;Get rest of text ("-character")
	jmp	prtstr		;Print it and return
;
;[MF]stacol - Print "SET COLLISION" state
;
stacol:	lxi	d,collst	;[MF]Get message
	call	prtstr		;[MF]Print it
	lxi	h,coltab	;[MF]Point to COLLISION keywords
	lda	flwflg		;[MF]Get COLLISION state
	call	fndkyw		;[MF]Get COLLISION state
				;[MF](Since user doesn't control flwflg
				;[MF]directly, no need to check for errors
	xchg		;[MF]Prepare for printing
	jmp	prtstr		;[MF]Print COLLISION state and return

;       Print the current escape character

staesc:	lxi	d,escst		;Escape string.
	call	prtstr
	call	escpr		;Print the escape char.
;	jmp	prcrlf		;removed [DJR] Print CR/LF and return  [Toad Hall]
	ret		;[DJR] added

;       Show number proportion of buffers used in multiple sector buffering
stabsz:	lxi	d,bufsz1
	call	prtstr		; do first bit of string
	lxi	h,0
	lda	bufsec
	mov	l,a		; get size used...
	call	nout		;... to screen
	lxi	d,bufsz2	; and then say max value
	call	prtstr
	lxi	h,0
	lda	maxbsc		; get max for this system
	mov	l,a
	call	nout		;.. thence to screen
;	jmp	prcrlf		; removed [DJR] cr lf and out
	ret		;[DJR]

;
;       Show the value of the TIMER flag
statim:	lxi	d,timmsg	;[jd] 
	call	prtstr		;[jd] 
	lda	timflg
	jmp	staton		;Tell whether it's on or off.

;       Show internal versions (edit strings)
shover:	call	cfmcmd
	call	prcrlf
	lxi	d,version	;[MF]Point to Kermit version
	call	prtstr		;[MF]and show it
	lxi	d,modmsg	;[MF]Continue the message
	call	prtstr		;[MF]...
	call	prcrlf		;[MF]End the line
	lxi	h,vertab	; Get address of version list
shovr1:	mov	e,m		; Get next word from list
	inx	h
	mov	d,m		; Next version string is in DE
	inx	h
	mov	a,d		; Test for zero (end of list)
	ora	e
	jz	shovr2		; Done with list if zero
	push	h		; Save position in list
	call	prtstr		; Not zero.  Print it.
	call	prcrlf		; Follow with crlf
	pop	h		; Restore position in list
	jmp	shovr1		;  and go see if there are any more.

shovr2:	lhld	ovlver		; Get overlay version string
	xchg		;  into DE
	call	prtstr		; Print it
	call	prcrlf		; Output crlf
	lhld	family		;[11] New entry in overlay.  Get string of 
	xchg		;[11]  family of machines (eg apple) and  print
	call	prtstr		;[11]  it.  For "common" m/c do a $ only.
	jmp	kermit		; Return to main loop.

; table of pointers to version strings.
vertab:	dw	mitver		; CPSMIT
	dw	comver		; CPSCOM
	dw	pk1ver		; CPSPK1
	dw	pk2ver		; CPSPK2
	dw	remver		; CPSREM
	dw	server		; CPSSER
	dw	ttver		; CPSTT
	dw	cpmver		; CPSCPM
	dw	wldver		; CPSWLD
	dw	cmdver		; CPSCMD
	dw	utlver		; CPSUTL
	dw	datver		; CPSDAT
	dw	0		; end of list

;       Show TACTrap status (On or Off, and intercept character)
statac:	lxi	d,tacst		;"Current TACTrap status/char: "
	call	prtstr
	lxi	d,offstr	;Assume set off
	lda	tacflg		;Get the TACTrap char/flag
	ora	a		;Is it off?
	jz	prtstr		;Yep, go print OFF...
	mvi	c,conout	;Display...
	mov	e,a		;...the current intercept char
	call	bdos
	jmp	prcrlf

;       Show if flow control is set on or off
staflo:	lxi	d,flost		; Flow control string
	call	prtstr
	lda	floctl		; get the flag
	jmp	staton

;       Show if Case sensitvity is on or off
;stasens:
;	lxi	d,senst		; case sensitivity string
;	call	prtstr		;
;	lda	casens
;	jmp	staton		; say if its on or off


;       Show the current user. (Should do this under directory...)
stusr:
	mvi	c,usrcod
	mvi	e,0ffh		;[9] get the current user
	call	bdos
	mov	l,a		;[9] print hl as a number...
	mvi	h,0
	push	h		;[9] got the user number
	lxi	d,usrst		;[9] tell the user number
	call	prtstr
	pop	h		;[9] now do number
	call	nout		;[6] using routine for writing packet nos.
	ret

;
;
;       [DJR] Show debug mode
stadbg:
        lxi     d,dbgst         ;[DJR] Display string
        call    prtstr          ;[DJR]
        lda     dbgflg          ;[DJR] load flag
        jmp     staton          ;[DJR]


;       [DJR] Show default disk
stacurd:
        lxi     d,curdst        ;[DJR]
        call    prtstr          ;[DJR]
        lda     curdsk          ;[DJR]
        adi     'A'-1           ;[DJR]
        mov     e,a             ;[DJR]
        mvi     c,conout        ;[DJR]
        jmp     bdos            ;[DJR]

;
;       Display current state of a boolean flag.
;       called with A/ value (zero = Off, non-zero = On)

staton:	lxi	d,onstr		; Assume it's on.
	ora	a		; Is it on?
	jnz	prtstr		; If so, say so, then return.
	lxi	d,offstr	; No, say off.
	jmp	prtstr		; Print the string, then return.

;       STRING command
;       get a string from the user and send it to the host.
string:	mvi	a,cmtxt		; get the text
	lxi	d,stbuff	; where to put it
	call	comnd
	jmp	kermit		; if we cannot do it, then back to command level
	sta	strcnt		; save the string count
	ana	a		; if it is zero, then do nowt
	jz	kermit
	call	cfmcmd		;[MF]Otherwise, get a "confirm"
	call	selmdm		; then select the modem
	lxi	d,stbuff	; where to get the string
stlop:	ldax	d		; get byte
	inx	d		; pointer plus one
	push	d		; update pointer, and save de, and the character
	call	setpar		; set whatever parity
	mov	e,a		; outmdm wants character in e
	call	outmdm		; send character in a to line
	pop	d
	lda	strcnt		; get the count
	dcr	a
	sta	strcnt		; less one
	jnz	stlop		; else still looping
	call	selcon		; re-select the console
	jmp	kermit

;       Print "(not implemented)".
;       here from vt52em, baud, prtset, stavt

notimp:	lxi	d,inms12	; Say it's not implemented.
	call	prtstr
	jmp	kermit		; Return to main loop.

; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FRO RELEASE!

;	org ($+100h) AND 0FF00H

IF lasm				; If using LASM, chain to the next file.
	LINK	CPSPK1		;[obs] break down them big files...
ENDIF;lasm
