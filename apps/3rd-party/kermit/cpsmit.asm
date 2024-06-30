; CPSMIT.ASM
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
;       This file contains the system-independent initialization, the main
;       loop, and the commands that don't have any place better to go.
;	All the SET xxx and status routines now in CPSCOM.ASM as CPSMIT.ASM
;	was getting too big.
;
; revision history:
;
;edit 30, 29-Mar-1991 by MF. When looking up a TAKE-file in a TAKE command
;	and the file is not found, complain if it's not the first TAKE of
;	the current program execution (the automatic TAKE of KERMIT.INI)
;edit 29, 25-Mar-1991 by MF. Add STAY command as a synonym for SET NO-EXIT
;	command per Martin J. Carter of Nottingham University in the U.K.
;edit 28, 21-Mar-1991 by MF. Modify code after "inp2a" in INPUT command
;	so a ^C will halt TAKE-file processing
;edit 27, 27-Feb-1991 by MF. Add QUIT as a synonym for EXIT per code of
;	Dr. Martin J. Carter of Nottingham University, U.K. Recognizing QUIT
;	helps those who forget they're not in MS-Kermit, C-Kermit,
;	Kermit-32 etc. Also add commands so that CONNECT, RECEIVE and SEND may
;	be abbreviated to C,  R and S, respectively.
;edit 26, 5-Nov-1990 by MF.  Cosmetic changes to main HELP messages for
;	COPY and RENAME commands.
;edit 25, 1-Nov-1990 by MF.  Made the following command-name changes in the
;	interest of uniformity of nomenclature (per suggestions of FDC):
;	FCOPY to COPY, FRENAME to RENAME and STRING to OUTPUT.
;	This means we'll have to type "CO" for CONNECT and "REC" for 
;	RECEIVE but with REMOTE now with us we have to do the latter anyway.
;edit 24, 18-Sep-1990 by MF.  Implemented FRENAME command to rename a
;	CP/M file.
;edit 23, 9-Sep-1990 by MF.  Implemented commands to be sent to a
;	remote Kermit Server (Remote commands).
;	Implemented setting of packet sizes for RECEIVE and SEND.
;	Put DIRECTORY/STRING help texts in proper alphabetical position.
; edit 22, July 6th, 1987 by OBSchou.  Added a dummy Commandline to be
;	loaded for debugging purposes as DDT destroys any command line at 80H
;	Also fixed a bug or two...
;
; edit 21, April 8th, 1987.
;	Various bits, including more SET SENDRECEIVE options, and make 
;	PADDING and PADCHAR valid options.  Have I wasted my time, or 
;	there still systems that use padding??  Fixed a bug in the INPUT
;	command so we know how many characters there are to check for. Also
;	hived off the SET commands to make a new file, CPSCOM.ASM thereby
;	reducing the size of CPSMIT.ASM.  Also rename COPY command to FCOPY
;	hence retaining a single C to imply connect.
;
; edit 20, March 30, 1987 by OBSchou.  
;	added code for no exit to CPM if a command tail is done (optional)
;	by the SET NO-EXIT command.  Added bits for SET AUTORECEIVE to enable 
;	or inhibit automatic receive of several files (if something is coming 
;	along from the remote side, do a receive. Toss first packet away.)  
;	This is first step to SERVER???
;	Also added back the INPUT command.
;
; edit 19, March 16, 1987.  Moved the code to check for and execute 
;	command tails (See Richard Russells submission below).  
;	Added flags to exit to CP/M after executing a command tail.  
;	The KERMIT.INI file is taken before the command tail is issued.
;
; edit 18, March 11, 1987 by OBSchou.
;	Added in code for TYPE <file> and PRINT <file>.  Hope to add COPY 
;	later on.  Also added in code submitted by Richard Russel, to accept
;	a command tail on entry to kermit (eg KERMIT CONNECT).  This facility
;	if used, will replace the automatic TAKE function on loading Kermit.
;	Unfortunately, you will not be dropped back to CP/M after the command
;	In the future, it may be possible to either accept several commands
;	on the command tail, and possibly accept the automatic TAKE facility
;	as well.  Low on my list of things to do.
;
; edit 17, January 28, 1987 by OBSchou for DJ Roberts of Leicester
;	Also added a couple of fixes [obs]
;
; 	DJR  January 1987  David J. Roberts.
;          USER made a SET option
;          STATUS output placed in alphabetical order
;          Report DEBUG mode and default disk 
;          Name of LOG file on SHOW/STATUS display
;
;
; edit 16 December 1st, OBSchou.  Fixed bug in that if the overlay is not in
;	place or correct then prtstr is not called to print the error message
;	(As prtstr has been moved out of the system independent code)
;
; edit 15 November 10, 1986 by OBSchou.  Re-inserted Pause and Break 
;       commands for release.
;
; edit 14 August 29, 1986.  Removed PAUSE,BREAK,INPUT and SET CASE as 
;       these have not been fully coded or debugged.  (For next 
;       version of Kermit-80...). Also tidied up a bit.
;
; 13 by OBSchou for Godfrey Nix.  He writes:
;       edit August 11,1986      Godfrey Nix, Nottingham University [gnn]
;       To insert code for setting the packet start character on
;       both send and receive packets (default is still 01H)
;       and make GET and RECEIVE to be separate;
;       use with edits to CP4PKT, CP4UTL
;
; edit 12: 19 June, 1986 by OBSchou.  Added PAUSE and BREAK facility.
;       Breaks simulate a call to sysint which tests for a B being passed.
;       Note this is only useful if the system dependent code supports breaks,
;       and an appropriate message is returned if breaks are not possible.
;       Also added is the command entry for INPUT, which waits for a string
;       from the host for a given time.  The time is a very variable counter
;       incremented every BDOS call.  Trial and error will give a reasonable
;       value.  STRING acceps a string from the use and then sends it on 
;       to the host.  These new commands allow a user to (almost) set up auto
;       log on files, where BREAKS/INPUT/STRING/STRING partially emulate a user
;       (AI LURES OK and all that).  Still could do with a test, eg if not a
;       correctly returned string go back n steps.  This would make a fairly 
;       simple TAKE command a lot more complicated.
;
;edit 11: 30 May, 1986 OBSchou.  Added in a couple of more routines and such
;
;edit 10: 27 May, 1986 OBSchou.  Added in support for USER function
;       removed XMIT test and routine, but also added SET FLOW-CONTROL
;       (set for XON/XOFF flow control in both directions) and a 
;       SET CASE-SENSITIVE ON/OFF (if on => a # A, if ON => a=A)
;
;edit 9: 13 May, 1986 OBSchou, Loughborough University, UK
;       Added in code for SET XMIT character to allow setting of the
;       character to wait for from the host during TRANSMIT.  It is
;       a line feed by default.  Also added a TAKE command, to take: commands
;       from a named disk file.  If a file is TAKEn, then all BDOS calls 
;       are trapped and tested for console input.  If so, we substitute a 
;       character (or buffer) from the TAKE file specified.
;       This may also be used in the future for a CPKERMIT.INI 
;       to be evaluated during Kermit initialsation.
;
; edit 8: February 6, 1895
;       Add a PORT status/show routine for those machines that have more
;       than one they can talk to. It also required a port storage variable
;       a la SPEED and the necessary code to handle it in the SET routine.
;       [Hal Hostetler]
;
; edit 7: 13-Jan-85 by Vanya J.Cooper Pima Commun. College Tel: 602-884-6809
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
; edit 6: September 8, 1984
;       Add VERSION command, to display the internal version strings.
;       Move command tables here from CP4UTL, and translate string
;       lengths in them to decimal (how many fingers do YOU got?).
;       Replace some jump tables with dispatch addresses in tables.
;       Make help text for SET command consistent with top level help text.
;
; edit 5: August 21, 1984
;       Add word at 0100H to allow us to exit cleanly from DDT (shifting
;       entry section by two bytes).
;
; edit 4: August 3, 1984 (CJC)
;       Remove "mover" from entry section, as it now lives in CP4SYS.
;
; edit 3: July 27, 1984 (CJC)
;       Merge LASM support from Toad Hall: most of CP4MIT is now in CP4UTL.
;       When assembling with LASM, CP4MIT is linked by CP4DEF; it links to
;       CP4PKT.  Add SET TACTRAP command.  Separate out display routines so
;       we can eventually do "SHOW <parameter>".  Save both bytes of baud
;       rate in speed, and check both bytes when displaying baud rate.  Move
;       header info to CP4KER.ASM.  Add onoff and chkkey routines to simplify
;       SET command (Toad Hall)
;
; edit 2: June 8, 1984
;       formatting and documentation; delete unreferenced variables and some
;       unnecessary labels; move setpar here from cp4pkt; add module version
;       string; make this version 4.01.
;
; edit 1: May, 1984
;       extracted from CPMBASE.M80 version 3.9; modifications are described
;       in the accompanying .UPD file.

;
	ASEG
	ORG	100H

; The CCP invokes programs with a CALL 100H, with the stack pointer set to
; 100H.  When we exit to CP/M, we do so with a RET, avoiding a warm boot.
; Unfortunately, DDT starts programs with a jump, not a call, so when we
; attempt to return to CP/M, we blow the stack and use the word at 100H as
; the new PC.  Put a 0 there so we reboot instead of dying horribly.
; (Fortunately, this happens to be two NOP's).
	dw	0
	jmp	start	; Bypass entry section

;
;       Entry section for system-independent part.  This contains
;       jumps to routines needed by the system support module.
;
entries:
	jmp	kermit		; reentry address
	jmp	nout		; output HL in decimal
entsiz	equ	$-entries	; length of entry section
;
;       End of entry section.  As a consistency check, the expected
;       length of this section is stored by the system-dependent
;       module in the linkage section at the end of Kermit, and
;       tested at initialization.

mitver:	db	'CPSMIT.ASM (30) 29-Mar-1991$'	; name, edit number, date
;
;
;       Initialization
;
start:	lxi	h,0		; Clear out hl pair
	dad	sp		; and fetch the system stack pointer
	shld	oldsp		; and save for later restoral
	lxi	sp,stack	; move in our own stack.
	lxi	d,version	; print Kermit version
	call	prtstx		;  before we do too much (Use fudged prtstr)
	mvi	c,rddrv		;Get our logged in drive
	call	BDOS
	inr	a		;relative 1
	sta	CURDSK		;and save it for later

	lda	vtflg		; [OBS] Hangover from VT52 ems not possible...
	cpi	0ffh		; ... if 0ff stored, assume terminal = off
	mvi	a,vtdefo
	jnz	start0
	sta	vtflg		; if 0ffh make it VT52 off
start0:


IF debug
;vvvvvvvvvvvvvvvv remove this for run time
; OBS edit 22 - add in a dummy command line to 80H
	lxi	h,dcomln	;[22] load up dummy command line
	lxi	d,81h		;[22] where to put it
	lxi	b,endcoml-dcomln
	mov	a,c		; get length to a
	sta	80h		; ... and save as command line length
	call	mover		; ... and save rest of line
	jmp	starta
dcomln:	db	'set baud 4800',semico
	db	'set dir on',semico
	db	'dir'
	db	0,0	; just to make up space
endcoml:
;^^^^^^^^^^^^^^^^ remove this for run time
ENDIF	;debug


starta:
;
;       Make sure the overlay is in place...
;
	lhld	lnkflg
	mov	a,h
	ora	l		; if lnkflg is still zero,
	jz	start1		;  the configuration overlay is missing.
	lxi	d,-lnksiz	; if it's not equal to lnksiz,
	dad	d		;  we've probably got the wrong
	mov	a,h		;  version of the configuration overlay.
	ora	l
	jnz	start2
	lhld	lnkent		; make sure the overlay knows how long
	lxi	d,-entsiz	; our entry section is, so they don't miss.
	dad	d
	mov	a,h
	ora	l
	jnz	start2
				; might be ok.
	lxi	h,bdos		; set xbdos address to bdos trap in our code.
	shld	xbdos+1		; (they may never use it...)
	call	sysinit		; do system-dependent initialization
	lda	bufsec		; get the max no of buffers allowed by system
	sta	maxbsc		; save for SET BUFFER use to compare
	lxi	d,inms26	; offer some advice on getting help
	call	prtstr
	lxi	h,buff		;[19] we copy any potential command tail across
	lxi	d,cbuff
	lxi	b,80h		;[19] copy all 128 bytes.  May use none.
	call	mover
	lda	80h		; see if there is a command tail...

	ana	a



; Remove for runtime use
;	xra	a		; make out there is no command tail
; Runtime => no XRA above

	jz	startz
	dcr	a
	jz	startz		; one character tail...
	lda	takflg		; if more characters, say we are have tail
	ori	10h		; set bit 4
	sta	takflg
	sta	nexitf		; exit back to CP/M after command line
startz:
	mvi	a,0ffh		; when here, system basically initiallised,...
	sta	initflg		; apart from KERMIT.INI, so say initialised.

	call	take1		;[9] take a KERMIT.INI file
	xra	a		;[MF] Say we've done it
	sta	initak		;[MF] ...
	jmp	kermit		; Start main loop.

start1:	lxi	d,erms20	; "Kermit has not been configured"
	call	prtstx		; print error message (Use bodge for prtstr)
	jmp	exit2		;  and exit.

start2:	lxi	d,erms21	; "Consistency check on configuration failed"
	call	prtstx		; print error message
	jmp	exit2		;  and exit.
;
;This is the main KERMIT loop.  It prompts for and gets the users commands.

kermit:	lxi	sp,stack	; get new stack pointer, old one might be bad.
	call	selcon		; make sure console is selected.
	xra	a
	sta	mfflg1		;reset MFNAME
	sta	mfflg2		;ditto
	sta	mfflg3
	sta	getrxflg	; clear the get/receive flag
				;0=> receive, non 0 => get
	sta	cmbflg		;[MF]Initial keyword must not be blank
	sta	cmqflg		;[MF]Allow character-echoing during commands
	sta	remtxt		;[MF] Clear remote-text-to-screen flag
	lda	curdsk		; update the prompt
	adi	'A'-1
	sta	kerm1+2
	call	getun		;[11] get the user number into temp1/2
	lda	temp1+1		;[11] get ms value of user number
	cpi	'0'		;[11] less than 10 => do a space
	jnz	kerm4		;[11] else do MS digit of user number
	mvi	a,' '		;[11]
kerm4:	sta	kerm1		;[11]
	lda	temp1		;[11] get ls digit of user number
	sta	kerm1+1		;[11] save that
	lda	takflg		; are we in TAKE or command line??
	ani	11h		; strip out both bits
	jnz	kerm5		; still in either or both...
	lda	nexitf		; if neither, and no-exit-flag set, we quit.
	ana	a
	jnz	exit		;... back to CP/M, else as you were...
kerm5:
	lxi	d,kerm
	call	prompt		;Prompt the user.

kerm7:	lxi	d,comtab
	lxi	h,tophlp
	call	keycmd		; Get a keyword
	xchg			; Get result (dispatch address) into HL
	pchl			; Dispatch.

;       here from: log, setcom, read, cfmcmd
kermt3:	lxi	d,ermes3	;"Not confirmed"
	call	prtstr
	jmp	kermit		;Do it again.

;       Structure of command table:
;
;       1) Number of entries.
;       2) Each entry is arranged as follows:
;               a) length of command in bytes.
;               b) 'name of command and $-sign'
;               c) address of routine to process command
;
;       ---> Note this command table is in alphabetic order.
;

comtab:	db	32	; added remote
			;[obs] added in COPY command, now called FCOPY
			;[obs] removed remote simply to issue V4.09
				;[MF]Make FCOPY/FRENAME COPY/RENAME for
				;[MF]Version 4.10
				;[MF]Add QUIT as a synonym for EXIT and
				;[MF]C, R and S as abbreviations for
				;[MF]CONNECT, RECEIVE and SEND, respectively
				;[MF]Add STAY as a synonym for SET NO-EXIT
	db	5, 'BREAK$'
		dw break
	db	3, 'BYE$'
		dw bye
	db	1,'C$'
	dw	telnet		;[MF]Abbreviation for CONNECT
	db	7, 'CONNECT$'
		dw telnet
	db	4,'COPY$'
		dw copy
	db	9, 'DIRECTORY$'
		dw dir
	db	5, 'ERASE$'
		dw era
	db	4, 'EXIT$'
		dw exit
	db	6, 'FINISH$'
		dw finish
	db	3, 'GET$'
		dw read		; [gnn] entry for GET
	db	4, 'HELP$'
		dw help
	db      5, 'INPUT$'
		dw input
	db	3, 'LOG$'
		dw log
	db	6, 'LOGOUT$'
		dw logout
	db	6, 'OUTPUT$'
		dw string
	db	5, 'PAUSE$'
		dw pause
	db	5, 'PRINT$'
		dw printf	;[obs] print a file
	db	4,'QUIT$'
	dw	exit		;[MF]Synonym for EXIT
	db	1,'R$'
	dw	read0		;[MF]Abbreviation for RECEIVE
	db	7, 'RECEIVE$'
		dw read0	; [gnn] not same as GET now
	db	6, 'REMOTE$'
		dw remote
	db	6,'RENAME$'
	dw	rename		;[MF]
	db	1,'S$'
	dw	send		;[MF]Abbreviation for SEND
	db	4, 'SEND$'
		dw send
	db	3, 'SET$'
		dw setcom
	db	4, 'SHOW$'
		dw show
	db	6, 'STATUS$'
		dw status
	db	4,'STAY$'
	dw	noexit		;STAY (SET NO-EXIT)
	db	4, 'TAKE$'			;[9]
		dw take
	db	8, 'TRANSMIT$'
		dw xmit
	db	4, 'TYPE$'
		dw type		;[obs] type a file command
	db	7, 'VERSION$'
		dw shover
;	db	4, 'USER$'			; removed [DRJ]
;		dw user				;[10] removed [DRJ]
; top-level help message. Caps indicate keywords.
; this text is also printed by the HELP command.

tophlp:	
	db	cr,lf,'BREAK to send a break to the host'
	db	cr,lf,'BYE to host (LOGOUT) and exit to CP/M'
	db	cr,lf,'CONNECT to host on selected port'
	db	cr,lf,'COPY to copy a CP/M file'
	db	cr,lf,'DIRECTORY of current used Micro-disk'
	db	cr,lf,'ERASE a CP/M file'
	db	cr,lf,'EXIT to CP/M'
	db	cr,lf,'FINISH running Kermit on the host'
	db	cr,lf,'GET a file from the host'
	db	cr,lf,'HELP by giving this message'
	db	cr,lf,'INPUT to make the micro wait for a string from the host'
	db	cr,lf,'LOG the terminal sessions to a file'
	db	cr,lf,'LOGOUT the host'
	db	cr,lf,'OUTPUT to send a specified string to the host'
	db	cr,lf,'PAUSE to wait for a little time'
	db	cr,lf,'PRINT a file to the printer'
	db	cr,lf,'QUIT to CP/M'
	db	cr,lf,'RECEIVE file from host'
	db	cr,lf,'REMOTE to send commands to a remote server'
	db	cr,lf,'RENAME to rename a CP/M file'
	db	cr,lf,'SEND file to host'
	db	cr,lf,'SET a parameter'
	db	cr,lf,'SHOW the parameters'
	db	cr,lf,'STATUS of Kermit'
	db	cr,lf,'STAY at Kermit command-level after a command tail'
	db	cr,lf,'TAKE commands from a file'		;[9]
	db	cr,lf,'TRANSMIT file to host (in connect state)'
	db	cr,lf,'TYPE a file to the console'
	db	cr,lf,'VERSION of Kermit running'		;[pcc005]
;	db	cr,lf,'USER to set a different user number' ;removed [DJR]
	db	'$'		;[obs] added it here to allow for expansion

;
;       This is the BREAK command.  It sends a 'B' to the system dependent
;       interrupt routines (test for escape-cokebottle xxx) and do a break
;       if the overlay can.  Else, we tell user not to be so silly.
break:	call	cfmcmd		; get return
	mvi	a,'B'		; were gonna do a break if the overlay can
	call	sysint		; try doing it..
	jmp	kermit		; if we can do it, else
	lxi	d,inms12	;... say not implemented
	jmp	kermit

;
;
;       This is the BYE command.  It tells the remote KERSRV to logout,
;       then exits.

bye:	call	cfmcmd
	call	logo		;Tell the main frame to logout.
	jmp	kermit		;If it fails, don't exit.
	call	sysbye		; success. do system-dependent cleanup
	jmp	exit1		;Exit Kermit.

;       This is the EXIT command.  It leaves KERMIT and returns to CP/M.
;       alternate entries: exit1, from BYE command;
;       exit2, from initialization (if it fails)

exit:	call	cfmcmd		; confirm...
exit1:	call	sysexit		; do system-dependent termination
exit2:	
	jmp	0		; return to CP/M via JUMP instead of RET.
	
;	lhld	oldsp		;Get back the system stack
;	sphl			;and restore it.
;	ret			;Then return to system.

;       Input command.  Syntax:
;               INPUT [Wait period] [string]
;       where
;               Wait period is a time period to wat for
;               string is a string to expect back from the host.  Control
;                       characters are entered as \ and an octal number.
;
;       I can see uses for this command from other routines...
;
input:	mvi	a,cmnum		; first get the number
	call	comnd		; get it
	jmp	kermit		; if we dont understand it...
	lhld	number
	shld	waitp		; and save as the wait period
	lxi	d,stbuff	; where to put the string
	mvi	a,cmtxt		; get text
	call	comnd
	jmp	kermit		; not quite correct...
	sta	strcnt		; string count returned in a
	call	cfmcmd		; get a confirm

	lhld	waitp		; multiply the number by
	dad	h
	dad	h		; ... 4
	dad	h		; ... 8
	inx	h		; but make sure it is at least 1
	shld	waitp		; and save it away again
	shld	waitp1		; save in case we need to reset counter

; Right, now wait for characters comming from the line, within the
;	time allowed (very fuzzy).  Compare with STRING buffer
;
inp1:	xra	a
	sta	repcnt		; clear the host prompt chars.counter
inp2:	lhld	waitp		; have we waited long enough
	dcx	h
	shld	waitp		; count less one
	mov	a,h		; test to see if both zero
	ora	l
	jnz	inp20		; nope
	mvi	a,3		; error is three ie total failure
	sta	errorc
	jmp	inp5		; take error exit

inp20:	call	rd1chl		; read a character from the line
	ani	7fh		; set flags
	jnz	inp4		; Not zero => we have a character from host
	call	ckchr		; see if *WE* have a character from console
	push	psw		; restore to modem
	call	selmdm		; reselect the modem port
	pop	psw
	ani	7fh		; strip parity (should not be there)
	jnz	inp2a		; if a null, try again
	lda	strcnt		; if the string length is zero, dont wait.
	ana	a
	jnz	inp2		; so loop back again
	jmp	kermit		; else drop out

inp2a:	cpi	cntlc		; do we want to abort?
;[MF]Change following line
;	jz	kermit		; in which case exit back to command loop
	jnz	inp2b		;[MF] No
	lda	takflg		;[MF] Yes, are we TAKEing
	ani	1		;[MF] commands from a file?
	cnz	closet		;[MF] Yes, close and reset to get
				;[MF] commands from the command-line
	jmp	kermit		;[MF] and exit back to command loop
inp2b:	cpi	cntlz		; if control z exit back to command loop
	jz	kermit		; else try for other characters [MF]
	jmp	inp2

inp4:	mov	e,a		; save it for a while
	lda	repcnt		; see if this character matches with one in buffer
	lxi	h,stbuff	; point to string buffer
	add	l		; make hl = hl + a
	mov	l,a
	mvi	a,0		; ie make hl = hl + character count
	adc	h
	mov	h,a		; not using xra, as that clears the Carry flag
	mov	a,e		; get the character back again
	cmp	m		; is it = to what we expect?
	jnz	inp1		; no, clear counter and try again
	lda	repcnt		; yes, then update the pointer, and ...
	inr	a		; ... see if we have received all ...
	sta	repcnt		; ... we should have received
	lhld	waitp1		; get original counter
	shld	waitp		; and reset the loop (timer) counter
	mov	e,a		; save length into E again
	lda	strcnt		; get the length to compare
	sub	e		; if (e) > string length, we have it
	jnz	inp2		; else wait for a little longer

	xra	a		; no errors
	sta	errorc
	jmp	kermit		; so say nothing
;else if error...

inp5:	lxi	d,erms30	; say message not receive in time...
	call	prtstr
	jmp	kermit		; have string, so exit

;
;

;       This is the HELP command.  It gives a list of the commands.

help:	call	cfmcmd
	lxi	d,tophlp	;The address of the help message.
	call	p20ln		;Print at most 20 lines then pause
;	call	prtstr
	jmp	kermit
;
;       This is the LOG command.  It logs a session to a file.

log:	mvi	a,cmofi		;[pcc005] Parse an output file spec.
	lxi	d,fcb		;[pcc012] where to put it
	call	comnd
	jmp	kermt3
	call	cfmcmd
	lxi	h,fcb		;[pcc012] copy file name and ext
	lxi	d,lognam	;[pcc012] to a safe place
	lxi	b,12		;[pcc012] 12 bytes
	call	mover		;[pcc012] zap ...
	mvi	a,1		;[pcc005] set flag for logging
	sta	logflg		;[pcc005]
	jmp	kermit		;[pcc005]

;
;       PAUSE [Wait period]. Just wait for a couple of tics...
pause:	mvi	a,cmnum		; get the number of the wait period
	call	comnd		; get it
	jmp	kermit		; we canna do it, so get next command
	lhld	number
	xchg			; move to d
	lhld	clkbit+1	; get clock bits 8 to 23
	mov	a,h		; strip ms bit so we have space for a possible carry
	ani	7fh
	mov	h,a
	dad	d		; add the number (ie get the number to wait to
	shld	number		; save it somewhere
;
;       Now, wait for time to be equal to newer NUMBER with Carry
ploop:	
	call	clock		; increment clock
	lda	takflg		; test if keyboard interrupt.. not for takes
	ana	a
	jnz	ploop1		; do nothing for take command files
	mvi	c,dconio	; get status from console
	mvi	e,0ffh		; just get the character
	call	bdos
	ana	a		; if non zero return, then quit
	jnz	kermit		; we got something, so quit
ploop1:	lhld	number
	xchg
	lhld	clkbit+1	; get bits 8 to 23
	mov	a,h
	ani	7fh		; make it 15 bits for a carry...
	mov	h,a
	mov	a,e		; now, do (DE with carry) - HL
	sub	l
	mov	e,a
	mov	a,d
	sbb	h
	ora	e		; a = OR of result
	jnz	ploop
	jmp	kermit		; otherwise we are done.

; PRINT - Print a file to the console and printer.  
;	This command is active only from the command level, and not 
;	from the connect state.  Unfortunately, the print command is 
;	not going to be a background utility.
printf:	mvi	a,0ffh		; set the print flag on
typent:	sta 	prnfl		; Type file entry.  Common for PRINT and TYPE
	call	type		; and do the rest of the print via type
	xra	a
	sta	prnfl		; next clear the print flag
	jmp	kermit

; TYPE - Type a file to the console.
;	This command is really the same as the print command, but the output
;	is not copied to the printer.
typef:	xra	a		; we want to clear the printer on flag
	jmp	typent		; go to the type entry in printfile above


;
;       This is the TAKE command.  It take input from a file.
;       TAKE1 is the entry for automatically TAKE-ing KERMIT.INI (or whatever
;       the file name at taknam is) from the default drive
;	[18] code added to accept command tails.  See note [18] above
;
take:	mvi	a,cmifi		;[9] Get filename from user
	lxi	d,takfcb	;[9] Take file fcb space
	call	comnd		;[9] get the file spec
	jmp	kermit		;[9] User failed to specify a good file spec
	call	take2		;[MF] Now TAKE the file
	jmp	kermit		;[MF] Go back to main Kermit command loop
;
take1:	lxi	b,12		;[9] copy default drive and file name to take fcb
	lxi	d,takfcb
	lxi	h,taknam
	call	mover		;[9] and do it (all other extents etc are zero)
;[MF][30]No longer need the following line
;	jmp	take2		; got the file name, now take it.
;
				;[9] get the file name, now lets open it 
;
take2:
	lda	takflg		; check to see we have not tak-take
	ani	1		; if set, we are in a take already
;[MF]We can do the following test/call more efficiently
;	jz	take21
;	call	closet		; so close current take file
	cnz	closet		;[MF] So close current take file
take21:
	mvi	c,setdma
	lxi	d,takdma	;[9] tell bdos where to send data
	call	BDOS
	xra	a		;[9] clear all these extents etc
	sta	takfcb+14
	sta	takfcb+32
	lxi	d,takfcb	;[9] open the file
	mvi	c,openf		;[9] open the file
	call	BDOS
	inr	a		;[9] if FF returned, problems
;[MF]Complain if failure and not seeking KERMIT.INI
;	jz	kermit		;[9] for now, say nowt if no ini file. Else..
       jz      ntake           ;[9] We'll say file not found
				;[MF] unless the initial TAKE (KERMIT.INI)
;	jmp	take3		; a test
;	mvi	c,readf		;[9] read first bytes from file
;	lxi	d,takfcb	;[9]
;	call	BDOS

take3:	lxi	h,0
	shld	takptr		;[9] point to first byte of take file
	lda	takflg		; get current flag
	ori	1		;[9] and set flag to tell Kermit we're taking
	sta	takflg
;[MF][30]Redo next lines so can flag initial TAKE of KERMIT.INI
;	call	rnsect		;[9] read a sector
;	jmp	kermit		;(Should use a ret, but this will do)
	jmp	rnsect		;[9] read a sector and return

ntake:	lda	initak		;[MF]Is this the initial TAKE (KERMIT.INI)?
	ora	a		;[MF]...
	rnz			;[MF]Yes, don't complain
	lxi	d,erms15	;[9] Say file not found
	call	prtstr
;[MF][30]Make next line a "jmp" since we've called TAKE2
;	call	rstdma		;[9] reset the DMA addres for other files
;	jmp	kermit
	jmp	rstdma		;[9] reset the DMA addres for other files
				;[MF] and return


; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FRO RELEASE!

;	org ($+100h) AND 0FF00H

IF lasm
	LINK CPSCOM
ENDIF ;lasm
