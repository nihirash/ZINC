; CPXLNK.ASM
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
;       This file describes the areas used to communicate between KERMIT
;       and the customizing overlay.  It is included by the overlay.
;       This file should be changed only to reflect changes in the
;       system-independent portion of Kermit (enhancements, I hope).
;
; revision history:
;edit 8, 14-Sep-1990 by MF.  Added variable "incflg" to hold incomplete-
;	file status for SET INCOMPLETE-FILES command.
; edit 7: 8 April, 1987 by OBSchou.  Added a new entry EXTERN to leap off to
;	code written by the user to emulate any terminal they want.  All 
;	characters are sent here in stead of conout during connect state.  
;	In due course, Ill trap all prtstrs and dconio as well.
;
; edit 6: May 30, 1986 by OBSchou.  Added two more entries to the link area:
;       first to point to a "family" string giving the family name of the 
;       system.  If the older CP4SYS.ASM still has the code, then the 
;       string is null.  Secondly, a JMP to give printer status (should be 
;       a BIOS function).  If 0 then printer is ready, if 0ffh then printer 
;       busy.  This makes version 4.07 incompatable with 4.05
;
; edit 5: February 6, 1985
;       Added a storage variable, "PORT", for the port-in-use value 
;       required for the port status routine (same purpose as SPEED).
;       Also moved the printer copy flag (PRNFLG:) into the commun-
;       ications storage area so machine dependant overlay can access it.
;       [Hal Hostetler]
;       Also, replace assembly-time conditional "ffussy" with run-time
;       switch (CJC).
;
; edit 4: August 21, 1984 (CJC)
;       Define a use for the third word of the linkage section: it points
;       to the version string for CP4SYS.ASM.  Add flsmdm, to flush comm line
;       on startup.  Add bufadr and bufsec for multiple-sector buffer support.
;       Shift the entry section up two bytes so we can exit cleanly from DDT.
;
; edit 3: August 3, 1984 (CJC)
;       put "mover" in CP4SYS, so we can do a Z80 block move if so inclined.
;
; edit 2: July 10, 1984 (CJC)
;       integrate Toad Hall changes for LASM compatibility: CP4LNK is linked
;       by CP4DEF, and links CP4SYS.
;
; edit 1: May, 1984 (CJC)
;       extracted from CPMBASE.M80 version 3.9; modifications are described
;       in the accompanying .UPD file.
;

;       Define the entry section.  These addresses contain jumps to
;       useful routines in KERMIT.  To show we know what we're doing,
;       we store the length of this section (entsiz) in our linkage
;       section.  I didn't use ORG and DS because I don't want zeroes
;       generated for all the space between here and the actual start
;       of cp4sys.
entry	equ	105H	; start of entry section
kermit	equ	entry+0	; reentry address
nout	equ	entry+3	; output HL in decimal
entsiz	equ	2*3	; 2 entries, so far.
;
;       End of entry section.
;
;       Linkage section.  This block (through the definition of lnksiz)
;       is used by Kermit to reach the routines and data in the overlay.
;       The section length is stored at the beginning of the overlay
;       area so Kermit can verify that the overlay section is (a) present,
;       (b) in the right place, and (c) the same size as (and therefore
;       presumably the same as) the linkage section Kermit is expecting.
;
	ASEG
	ORG	OVLADR
;
lnkflg:	dw	lnksiz	; linkage information for consistency check.
	dw	entsiz	; length of entry table, for same.
	dw	swtver	; address of switcher.  CPXSYS now a family
	dw	family	;*NEW* for V4.08. Address of the family string
;
;       hooks for system-dependent routines:
;
; Input/output routines. 
;
	jmp	selmdm	; select modem for I/O
	jmp	outmdm	; output character in E to modem
	jmp	inpmdm	; read character from modem. return character or 0 in A.
	jmp	flsmdm	; flush pending input from modem
	jmp	selcon	; select console for I/O
	jmp	outcon	; output character in E to console
	jmp	inpcon	; read char from console. return character or 0 in A
	jmp	outlpt	; output character in E to printer
	jmp	lptstat	;*NEW*  get the status for the printer. 
			; 0=>ok, 0ffh=> not ok
	jmp	0	;*NEW for 4.09* Terminal Emulation code (optional)
			; If terminal is set to EXTERNAL and this address
			; has been filled, then user uses their own code.
xbdos:	jmp	0	;*NEW* Address of the BDOS trap in the independent 
			; code. Use this enty for BDOS calls if you want 
			; the printer handler to work properly.

; screen formatting routines
	jmp	clrlin	; erase current line
	jmp	clrspc	; erase current position (after backspace)
	jmp	delchr	; make delete look like backspace
	jmp	clrtop	; erase screen and go home
;
; these routines are called to display a field on the screen.
	jmp	scrend	; move to prompt field
	jmp	screrr	; move to error message field
	jmp	scrfln	; move to filename field
	jmp	scrnp	; move to packet count field
	jmp	scrnrt	; move to retry count field
	jmp	scrst	; move to status field
	jmp	rppos	; move to receive packet field (debug)
	jmp	sppos	; move to send packet field (debug)
;
	jmp	sysinit	; program initialization
	jmp	sysexit	; program termination
	jmp	syscon	; remote session initialization
	jmp	syscls	; return to local command level
	jmp	sysinh	; help text for interrupt (escape) extensions
	jmp	sysint	; interrupt (escape) extensions, including break
	jmp	sysflt	; filter for incoming characters.
			;  called with character in E.
	jmp	sysbye	; terminate remote session
	jmp	sysspd	; baud rate change routine.
			; called with value from table in DE
	jmp	sysprt	; port change routine.
			; called with value from table in HL
	jmp	sysscr	; screen setup for file transfer
			; called with Kermit's version string in DE
	jmp	csrpos	; move cursor to row B, column C
	jmp	sysspc	; calculate free space for current drive
	jmp	mover	; do block move
	jmp	prtstr	; *** NEW *** Link from system indep equivalent
;
;       Local parameter values
;
pttab:	dw	ttab	; points to local equivalents to VT52 escape sequences
spdtab:	dw	spdtbl	; address of baud rate command table, or zero
spdhlp:	dw	sphtbl	; address of baud rate help table, or zero
prttab:	dw	prttbl	; address of port command table, or zero
prthlp:	dw	prhtbl	; address of port help table, or zero
timout:	dw	fuzval	; Fuzzy timeout.
vtflg:	db	vtval	; VT52 emulation flag
escchr:	db	defesc	; Storage for the escape character.
speed:	dw	0FFFFH	; storage for the baud rate (initially unknown)
port:	dw	0FFFFH	; storage for port value (initially unknown) [hh]
prnflg:	db	0	; printer copy flag [hh]
dbgflg:	db	0	; debugging flag
ecoflg:	db	0	; Local echo flag (default off).
flwflg:	db	1	; File warning flag (default on).
ibmflg:	db	0	; IBM flag (default off).
cpmflg:	db	0	;[bt] file-mode flag (default is DEFAULT)
incflg:	db	0		;[MF]incomplete-file flag (default is DISCARD)
parity:	db	defpar	; Parity.
spsiz:	db	dspsiz	; Send packet size.
rpsiz:	db	drpsiz	; Receive packet size.
stime:	db	dstime	; Send time out.
rtime:	db	drtime	; Receive time out.
spad:	db	dspad	; Send padding.
rpad:	db	drpad	; Receive padding.
spadch:	db	dspadc	; Send padding char.
rpadch:	db	drpadc	; Receive padding char.
seol:	db	dseol	; Send EOL char.
reol:	db	dreol	; Receive EOL char.
squote:	db	dsquot	; Send quote char.
rquote:	db	drquot	; Receive quote char.
chktyp:	db	dschkt	; Checksum type desired
tacflg:			; TACtrap status:
IF	tac
	db	tacval	; when non-zero, is current TAC intercept character;
ENDIF;tac
IF	NOT tac
	db	0	; when zero, TACtrap is off.
ENDIF;tac
tacchr:	db	tacval	; Desired TAC intercept character (even when off)
bufadr:	dw	buff	; Address of possibly multi-sector buffer for I/O
bufsec:	db	1	; Number of sectors big buffer can hold (0 means 256)
ffussy:	db	1	; if nonzero, don't permit <>.,;?*[] in CP/M filespec.
; space used by directory command; here because space calculation is
;  (operating) system-dependent
bmax:	ds	2	; highest block number on drive
bmask:	ds	1	; (records/block)-1
bshiftf: ds	1	; number of shifts to multiply by rec/block
nnams:	ds	1	; counter for filenames per line

lnksiz	equ	$-lnkflg ; length of linkage section, for consistency check.

IF lasm			; If we're assembling with LASM,
	LINK	CPXCOM	;  get the next section.
ENDIF;lasm
