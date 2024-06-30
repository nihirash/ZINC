; CPSKER.ASM
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
;
; This is the header for the system-independent portion of KERMIT, which
; consists of the following files (in this order):
;
;       CPSKER.ASM - this file
;       CPSDEF.ASM - definitions for both KERMIT and KERSYS
;       CPSMIT.ASM - \initialization, main loop, miscellaneous commands 
;	CPSCOM.ASM - /(BYE, EXIT, LOG, SET, SHOW, and STATUS) (Part1 of 2)
;       CPSPK1.ASM - \the KERMIT protocol handler (SEND, RECEIVE, LOGOUT,
;       CPSPK2.ASM - / and FINISH commands) (In two parts)
;	CPSREM.ASM - REMOTE commands etc
;	CPSSER.ASM - SERVER commands etc (Empty as yet)
;       CPSTT.ASM  - the transparent commands (TRANSMIT, CONNECT)
;       CPSCPM.ASM - CP/M commands (DIR, ERA)
;       CPSWLD.ASM - the wildcard handler
;       CPSCMD.ASM - the command parser
;       CPSUTL.ASM - utility routines
;       CPSDAT.ASM - Data space and the overlay link space
;
; When building the system-independent part with M80 or MAC80, CPSKER
; INCLUDEs the other files; when building with LASM, each file LINKs to
; the next file.
;
; For now, the system-dependent routines are all in CPSSYS.ASM, with
; the actual configuration defined in CPSTYP.ASM.
;
; revision history (latest first):
;
;	Begin CP/M Kermit-80 version 4.11.
;edit 32, 1-Apr-1991 by MF. Official release of work to date as CP/M Kermit
;	(Kermit-80) Version 4.11.
;	Modified edit level of cpscpm.asm to reflect a bug fix for the TYPE
;	command introduced with edit 13.
;edit 31, 29-Mar-1991 by MF. Modified edit levels of cpsker.asm,
;	cpscom.asm and cpsdat.asm to reflect rename of parameter vermin to
;	revno (revision level) and change of SET COLLISION REPLACE to
;	SET COLLISION OVERWRITE to conform with C-Kermit. Modified
;	edit level of cpsrem.asm to reflect change from REMOTE SET FILE
;	COLLISION REPLACE to REMOTE SET FILE COLLISION OVERWRITE.
;	Modified edit level of cpsutl.asm to reflect code tightening and
;	edit levels of cpsmit.asm and cpspk2.asm to close any open TAKE-file
;	and abort take-file processing if ^C is typed from the console
;	Also corrected ^Z test in cpsmit.asm in INPUT command ("inp2b")
;	Implement "file not found" complaint if a TAKE command can't find
;	the TAKE-file and it's not the initial TAKE (KERMIT.INI)
;	Modified edit level of cpscpm.asm to reflect modification of the
;	TYPE and PRINT commands to cancel file typeout/printout completely
;	if ^C is entered on the console (either immediately or after a key
;	has been pressed to induce a pause) and to immediately begin
;	typeout/printout of the next file (if the filespec was wild-carded)
;	if ^X is entered (either immediately or after a key has been pressed
;	to induce a pause).
;	Modified edit levels of cpsmit.asm and cpscom.asm to reflect addition
;	of the STAY command as a synonym for SET NO-EXIT.
;edit 30, 27-Feb-1991 by MF. Modified edit levels of cpscom.asm,
;	cpsmit.asm, cpsutl.asm and cpsdat.asm to reflect provision for
;	a "revision level" field (1-26=A-Z), addition of QUIT as a synonym
;	for the EXIT command, recognition of C, R and S as abbreviations
;	for the CONNECT, RECEIVE and SEND commands, respectively, display
;	of Kermit version in the VERSION command and a fix to the TAKE-file
;	input routine "r1tchr" to prevent semicolons from being interpreted
;	as command separators during TAKE-file execution. This last fix
;	allows such commands as REMOTE DELETE *.*;* to Kermit-32 to
;	operate as expected.
;edit 29, 14-Feb-1991 by MF. Updated edit levels of cpscom.asm,
;	cpscpm.asm, cpsdat.asm and cpsrem.asm to reflect bug fixes,
;	code tightening and simplified routine "remcli" (in cpsrem.asm)
;	which gets text to be passed on to a remote Kermit in REMOTE
;	Kermit commands.
;edit 28, 8-Feb-1991 by MF. Changed edit level of cpscpm.asm to reflect
;	a bug fix to make TAKE-files work properly with commands such as
;	INPUT which check the keyboard for input.
;edit 27, 30-Jan-1991 by MF. Changed edit levels of cpscpm.asm, cpsrem.asm,
;	cpstt.asm and cpsutl.asm to reflect bug fixes and enhancements
;edit 26, 17-Jan-1991 by MF. Changed edit level of cpscmd.asm to
;	reflect fixes to allow leading spaces/tabs to be ignored when
;	parsing keywords (this was the intent but the code never worked
;	correctly) and to blank the entire fcb in "cmifil" to allow successive
;	COPY commands to function properly. Also changed edit level of
;	cpspk1.asm to reflect further work on "disk full" error reporting.
;edit 25, 14-Jan-1991 by MF. Incremented edit level of cpspk1.asm to
;	reflect bug fix to "disk full" error reporting code so <cr><lf>
;	is not sent directly to the Remote Kermit. This per a report from
;	Russell Lang of Australia's Monash University.
;edit 24, 10-Jan-1991 by MF. Modified edit level of cpxtyp.asm to
;	reflect addition of "terminal required" message for some.
;	machines.
;edit 23, 7-Jan-1991 by MF. Modified edit levels of cpxtyp.asm, cpxswt.asm,
;	cpxbbi.asm to reflect addition of Ampro Little Board support.
;edit 22, 3-Jan-1991 by MF. Incremented edit levels of cpspk1.asm/cpspk2.asm
;	to reflect further mods to "sdata" and "inchr" routines.
;edit 21, 2-Jan-1991 by MF. Incremented edit level of cpspk1.asm to reflect
;	code cleanup in "sdata" routine.
;edit 20, 26-Dec-1990 by MF. Modified edit level of CPSCMD.ASM to reflect
;	fix to allow leading white space to be skipped in lines from
;	TAKE-files as well as from the CP/M command-line tail; this per a
;	phoned-in bug-report to Dr. Martin J. Carter of Nottingham
;	University in the U.K. (PPZMAJOC@vax.ccc.nottingham.ac.uk)
;edit 19, 14-Dec-1990 by MF.  Modified edit level of cpspk2.asm to reflect
;	modification to "gofil" to allow drive specifications in 2nd
;	filename of GET and RECEIVE commands; also modified edit levels of
;	cpspk1.asm and cpsrem.asm to reflect addition of "<<>>" around
;	"X" or "F" packets coming as a reply to a REMOTE command and
;	deletion of an unnecessary instruction before label remc2d
;	in cpsrem.asm.
;edit 18, 9-Dec-1990 by MF. Modified edit levels for Version 4.10
;	yet another time to reflect changes in CPSDAT.ASM to clarify
;	"File size on DIR" status message.
;edit 17, 4-Dec-1990 by MF. Adjusted edit levels of cpscom.asm/cpsdat.asm
;	to reflect addition of Autoreceive status to SHOW/STATUS display.
;edit 16, 30-Nov-1990 by MF. Adjusted edit levels of cpscom.asm/cpsdat.asm
;	to reflect fix to SHOW/STATUS routines to show terminal display
;	mode (quiet/regular). Also adjusted edit level of cpsutl.asm to reflect
;	change to routine "p20ln" to use "pausit" to save code space.
;	Adjusted edit level of cpsdef.asm to reflect change in "fairness"
;	counter prfair from 100 to 50 to make terminal a bit more responsive
;	during CONNECTs.
;edit 15, 27-Nov-1990 by MF. Adjusted edit level of cpspk1.asm to reflect
;	a bug fix.
;edit 14, 27-Nov-1990 by MF. Again adjusted edit level of cpspk1.asm to
;	reflect modifications of "disk-full"and SET INCOMPLETE-FILES behavior.
;edit 13, 23 Nov-1990 by MF.  Adjusted edit level of cpspk1.asm to reflect
;	code changes for "disk full" processing.
;edit 12, 8-Nov-1990 by MF.
;	Adjusted edit levels shown for cpscom.asm/cpspk1.asm/cpsdat.asm to
;	reflect bug fixes and code revisions.
;edit 11, 5-Nov-1990 by MF.
;	Cosmetic changes for main help text for COPY and RENAME commands.
;	Begin CP/M Kermit-80 version 4.10.
;edit 10, 2-Nov-1990 by MF.  Moved Overlay address to 7000H (cpsdat.asm).
;edit 9, 1-Nov-1990 by Mike Freeman (BPA).  Cosmetic changes (command-name
;	changes:  SET BAUD-RATE==>SET SPEED, FCOPY==>COPY, FRENAME==>RENAME,
;	STRING==>OUTPUT, REMOTE CWD==>REMOTE CD per suggestions of FDC
;	to aid in uniformity of nomenclature for various Kermits.
;edit 8, 30-Oct-1990 by Michael Freeman; 301 N.E. 107th Street;
;	Vancouver, WA 98685 USA; Telephone (206)574-8221.
;	Work:  Bonneville Power Administration
;	P.O. Box 491 M/S MORF
;	Vancouver, WA USA 98666
;	Telephone (206)690-2307
;	Implemented FRENAME command to rename a CP/M file.
;	Implemented many Remote commands, variable-length packets up thru
;	94 characters in length.  Fixed a bug in CPSCOM.ASM in the
;	routine "getnp" and a bug in CPSCOM.ASM which caused garbage to appear
;	on the screen when PRTSTR was called with QUIETD flag set.
;	Modified code in module CPSCMD.ASM to skip leading spaces and tabs
;	when getting Kermit commands from the CP/M command line.  This also
;	obviates the necessity to type a leading semicolon to separate the
;	Kermit command from the Kermit commands on the CP/M command line.
;	Fixed code in CPSPK2.ASM which handles file collision detection
;	and resulting file rename per my entries in CPKERM.BWR.
;	and included fix by Russell Lang of Dept. of Electrical and Computer
;	Engineering, Monash University, Australia, to prevent renamed
;	files with SET WARNING ON from having the attributes (e.g., R/O)
;	copied from original file.  Mr. Lang's E-mail address is:
;	Russell Lang    Email: rjl@monu1.cc.monash.edu.au  Phone: (03) 565 3460
;	Department of Electrical and Computer Systems Engineering
;	Monash University, Australia
;	Also fixed a bug in CPSPK2.ASM which prevented completion messages
;	from being displayed if terminal was set to QUIET.
;	Implemented most proposed SET FILE-COLLISION (COLLISION) commands.
;	Implemented SET INCOMPLETE file disposition command.
;	Implemented a few of the proposed REMOTE SET commands.
;	Implemented other fixes suggested in CPKERM.BWR.
;	Moved overlay address to 6C00H.
;	Changed location of .printx in this file so LASM doesn't complain.
;	In system-dependent modules, included HP-125 support.
;	Also modified Telcon Zorba code in CPXHEA.ASM to enable setting
;	of baud-rates and sending of a break.
;	Included Russell Lang of Monash Univ. Australia's implementation
;	for the Microbee series of computers (CPXBEE.ASM).
;	Fixed COMPUPRO version of Kermit to compile correctly and to
;	conform to current syntax for setting baud-rate.
; edit 7, September, 1987.  Added files for SERVER and REMOTE 
;	modules (CPSSER/CPSREM).  SERVER is still empty, and may be 
;	only wishfull thinking.  I have ideas, but I dont think I 
;	will have the time to implement it.
;
; edit 6: 30 March, 1987 by OBSchou.  Start Kermit-80 V4.09 with the 
;	overlay address at 6000h.  Also adjusted the INCLUDEs to allow
;	M80 to assmeble these files.
;
; edit 5: 20 June, 1986.  Have added so much code etc that the overlay had to 
;       be moved again.. give it to 5000h.  This starts off Kermit-80 V4.08
;
; edit 4 22 April 1986
;       Start work on 4.06.  This should clear up a couple of bugs, add in
;       a few features, and split the system dependent stuff into 
;       smaller units.
;
; edit 3a 7 March 86 OBSchou Loughborough england.  Minor additions
;       to cpsker.asm, cpscmd.asm and cpspkt.asm.
;
; edit 3: February 10, 1985 (CJC)
;       Update for v4.05; add "verno" so CPSUTL doesn't have to change
;       just because some other module did.
;
; edit 2: September 10, 1984 (CJC)
;       Update for v4.03.
;
; edit 1: July 27, 1984 (CJC)
;       Created to allow assembly of Kermit by LASM as well as MAC80 and M80.

verno	EQU	11		; minor version number
revno	EQU	0		;[MF]Revision level
				;[MF]0-26 yields A-Z
	
; Version 4.10 of Kermit consists of the following edit levels:
;       cpsker.asm edit 32
;       cpsdef.asm edit 9
;       cpsmit.asm edit 30
;       cpscom.asm edit 13
;       cpspk1.asm edit 23
;       cpspk2.asm edit 11
;       cpsrem.asm edit 13
;       cpsser.asm edit 1
;       cpstt.asm  edit 12
;       cpscpm.asm edit 14
;       cpswld.asm edit 4
;       cpscmd.asm edit 13
;       cpsutl.asm edit 30
;	cpsdat.asm edit 19
;       cpxlnk.asm edit 8 (cpslnk.asm is not assembled with cpsker, but it
;               defines the linkage area expected by cpsker, and so must
;               match the description in cpsutl.asm)
;	cpxswt.asm edit 10
;
; Version 4.10 of Kermit has been tested with the following edit levels of
; the system-dependent files:
;       cpxtyp.asm edit 34
;       cpxsys.asm edit 40
;	cpxhea.asm edit 4
;	cpxtor.asm edit 4
;	cpxbbi.asm edit 4 (Ampro Little Board)
;
; Version 4.10 of Kermit is still to be tested fully against all known systems
; so far included in the system dependent overlays.
;


FALSE	equ	0
TRUE	equ	NOT FALSE

cpsker	equ	TRUE	; building system-independent part
debug	equ	FALSE	; set false for running system.  True => does some
			; unusual or unexpected things.
;
; Assembler type.  Define the appropriate one TRUE, the rest FALSE.  (We can't
; use ASM, because it cannot handle multiple input files)
mac80	EQU	FALSE		; For assembly via MAC80 cross-assembler.
m80	EQU	false		; For assembly via Microsoft's M80.
lasm	EQU	true		; For assembly via LASM, a public-domain
				; assembler.
;
;       Get the other modules...

IF lasm				; If we're linking, go on to the next file.
	LINK	CPSDEF
ENDIF;lasm

; If we're still here, we must be using M80 or MAC80.  M80 doesn't
; like ENDs inside conditionals, but the END statement has to be
; in CPSUTL for LASM (otherwise, we'd need a file containing just an
; END statement).  So, we leave off the IF m80 OR mac80 conditional
; that ought to be around these INCLUDEs.  No problem until the next
; incompatible assembler comes along...
; Let's first say where we are:
;
.printx	* CPSKER.ASM (or nearest offer)	*
;
.printx	* CPSDEF.ASM *
	INCLUDE	CPSDEF.ASM	; definitions
.printx	* CPSMIT.ASM *
	INCLUDE	CPSMIT.ASM	; initialization, main loop, some commands
.printx * CPSCOM.ASM *
	INCLUDE CPSCOM.ASM	; part of command/status/set etc
.printx	* CPSPK1.ASM *
	INCLUDE	CPSPK1.ASM	; KERMIT protocol handler (Part 1)
.printx	* CPSPK2.ASM *
	INCLUDE	CPSPK2.ASM	; KERMIT protocol handler (Part 2)
.printx * CPSREM.ASM *
	INCLUDE CPSREM.ASM	; Kermit REMOTE code (little in it, as yet)
.printx * CPSSER.ASM *
	INCLUDE CPSSER.ASM	; Kermit SERVER code (As yet, empty)
.printx	* CPSTT.ASM *
	INCLUDE	CPSTT.ASM	; transparent communication handler
.printx	* CPSCPM.ASM *
	INCLUDE	CPSCPM.ASM	; CP/M command support (DIR, ERA)
.printx	* CPSWLD.ASM *
	INCLUDE	CPSWLD.ASM	; wildcard handler
.printx	* CPSCMD.ASM *
	INCLUDE	CPSCMD.ASM	; command parser
.printx	* CPSUTL.ASM *
	INCLUDE	CPSUTL.ASM	; Various utilities and data, and END [ToadHall]
.printx * CPSDAT.ASM *
	INCLUDE CPSDAT.ASM
	END			; MAC80 ignores END's in included files...
