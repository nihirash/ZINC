IF NOT lasm
.printx * CPXSYO.ASM *
ENDIF	;NOT lasm
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
;       This file contains the system dependent part for Sanyo MBC 1100
;	systems, and has been extracted from the CPMSYO.ASM code (kermit
;	version 3.5)
;
; revision history:
;
; edit 1, 27 October, 1987, by OBSchou.  Extracted Sanyo code from CPMSYO.ASM
;	and massaged fort CP/M kermit V4.09
;
; Keep module name, edit number, and last revision date in memory.
family: db      'CPXSYO.ASM (1)  27-Oct-87 $'
;

; Assembly time message to let me know I'm building the right version.
; LASM generates an 'S' error along with the message, which is messy, but
; better than trying to put everything inside a IF m80 OR mac80 conditional,
; because LASM doesn't like nested IF's, either.

IF sanyo
.printx * Assembling Kermit-80 for Sanyo MBC 1100 *
ENDIF

iobyte  EQU     03H     ;Location of I/O byte

if sanyo
baudrt	EQU	0DAH	;BAUD RATE MEMORY LOCATION
MNPORT	EQU	0DCH	;COMMUNICATIONS PORT
MNPRTS	EQU	0DDH	;COMMUNICATIONS PORT STATUS
OUTPUT	EQU	01H	;OUTPUT READY BIT
INPUT	EQU	02H	;INPUT READY BIT
ENDIF;SANYO

defesc	EQU 	'\'-100O        ;The default escape character.

; Select initial setting for VT-52 emulation flag.
vtval   EQU	1


sysxin:	;system initialisation not covered by sysinit
        ret                     ; return from system-dependent routine

;

;
;       system-dependent termination processing
;       If we've changed anything, this is our last chance to put it back.
sysexit:
        ret

;
;       system-dependent processing for start of CONNECT command
;
syscon:
        ret

;

;
;       syscls - system-dependent close routine
;       called when exiting transparent session.
;
syscls:
        ret
;

;
;       sysinh - help for system-dependent special functions.
;       called in response to <escape>?, after listing all the
;       system-independent escape sequences.
;
sysinh:	
	lxi	d,inhlps	; we got options...
	call	prtstr		; print them.
        ret
inhlps:
        db      '$'                     ;[hh] table terminator

;
;       sysint - system dependent special functions
;       called when transparent escape character has been typed;
;       the second character of the sequence is in A (and in B).
;       returns:
;       non-skip: sequence has been processed
;       skip:   sequence was not recognized
sysint:
	ani     137O            ; convert lower case to upper, for testing...
        ret

;	sysflt - system-dependent filter.
;	called with the character in E.
;       preserves bc, de, hl.
;       note: <xon>,<xoff>,<del>, and <nul> are always discarded.
sysflt:
        mov     a,e             ; get character for testing
        ret

;       mdmflt - modem filter [30]
;       called with character to be sent to printer in E
;       with parity set as appropriate.
;       return with accumulator = 0 do do nothing,
;                               <> 0 to send char in E.
mdmflt:
        mov     a,e             ;[30] get character to test
        ret


;       prtflt - printer filter [30]
;       called with character to be sent to printer in E
;       returns with a = 0 to do nothing
;                    a <> 0 to print it.
;
;       this routine for those printer that automatically insert
;       a lf on cr, or cr for lf.  Should this be shifted to 
;       the system indep. stuff, in say 4.06?
prtflt:
        mov     a,e             ; [30] get character to test
        ret


;

;
; system-dependent processing for BYE command.
;  for apmmdm, heath, and lobo, hang up the phone.
sysbye:
        ret
;

;       This is the system-dependent command to change the baud rate.
;       DE contains the two-byte value from the baud rate table; this
;       value is also stored in 'speed'.
sysspd:
        ret

;

;       Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.

;       db      string length,string,divisor (2 identical bytes or 1 word)
; [Toad Hall]

IF sanyo	
spdtbl	EQU	0	; No speed table for the Sanyo
sphtbl	EQU	0	; ditto help for speed.

; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
;

;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:
        ret
;

;
;	Port table not applicable tot he Sanyo...
prttbl   EQU     0
prhtbl   EQU     0               ;

;

;
;       selmdm - select modem port
;       selcon - select console port
;       selmdm is called before using inpmdm or outmdm;
;       selcon is called before using inpcon or outcon.
;       For iobyt systems, diddle the I/O byte to select console or comm port;
;       For Decision I, switches Multi I/O board to console or modem serial
;       port.  [Toad Hall]
;       For the rest, does nothing.
;       preserves bc, de, hl.
selmdm:
        ret

selcon:
        ret
;

;       Get character from console, or return zero.
;       result is returned in A.  destroys bc, de, hl.
;
inpcon:
        mvi     c,dconio        ;Direct console I/O BDOS call.
        mvi     e,0FFH          ;Input.
        call    BDOS
        ret
;

;
;       Output character in E to the console.
;       destroys bc, de, hl
;
outcon:
        mvi     c,dconio        ;Console output bdos call.
        call    bdos            ;Output the char to the console.
        ret
;

;
;       outmdm - output a char from E to the modem.
;               the parity bit has been set as necessary.
;       returns nonskip; bc, de, hl preserved.
outmdm:
IF inout
        in      mnprts          ;Get the output done flag.
        ani     output          ;Is it set?
        jz      outmdm          ;If not, loop until it is.
        mov     a,e
        out     mnport          ;Output it.
        ret
ENDIF;inout

;

;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
IF inout
;Note: modem port should already be selected for mdI.  [Toad Hall]
        in      mnprts          ;Get the port status into A.
        ani     input           ;See if the input ready bit is on.
        rz                      ;If not then return.
        in      mnport          ;If so, get the char.
ENDIF;inout
	ret                     ; return with character in A


;
;       flsmdm - flush comm line.
;       Modem is selected.
;       Currently, just gets characters until none are available.

flsmdm: call    inpmdm          ; Try to get a character
        ora     a               ; Got one?
        jnz     flsmdm          ; If so, try for another
        ret                     ; Receiver is drained.  Return.


;

;
;       lptstat - get the printer status. Return a=0 if ok, or 0ffh if not.
lptstat:
        xra     a               ; assume it is ok.. this may not be necessary
        ret
;

;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
        push    d               ; save DE in either case
        call    prtflt          ; go through printer filter [30]
        ana     a               ; if A = 0 do nothing,
        jz      outlp1          ; [30] if a=0 do nothing
        mvi     c,lstout
        call    bdos            ;Char to printer
outlp1: pop     d               ; restore saved register pair
        ret
;

;
;       Screen manipulation routines
;       csrpos - move to row B, column C
;
;       csrpos for terminals that use a leadin sequence followed
;        by (row + 31.) and (column + 31.)
;
csrpos: push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; restore coordinates
        mov     a,h             ; get row
        adi     (' '-1)         ; space is row one
        mov     e,a
        push    h
        call    outcon          ; output row
        pop     h
        mov     a,l             ; get column
        adi     (' '-1)         ; space is column one
        mov     e,a
        jmp     outcon          ; output it and return
ENDIF;NOT (robin OR dmII OR osi OR vector OR termin)

	ret		; Can the Sany do cursor opsitioning??

;
;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:
	mvi	e,bs
	call	outcon

; erase the character at the current cursor position
clrspc: mvi     e,' '
        call    outcon
        mvi     e,bs            ;get a backspace
        jmp     outcon

; erase the current line
clrlin: lxi     d,eralin
        jmp     prtstr

; erase the whole screen, and go home. preserves b (but not c)
clrtop: lxi     d,erascr
        jmp     prtstr



IF SANYO
outlin:	DB	ESC,'E',ESC,'H',CR,LF,TAB	;WHATEVER
sysver:	DB	'KERMIT-80 V3.9 [SANYO MBC-1100]',CR,LF,'$' ;VERSION HEADING
DELSTR:	DB	ESC,'K','$'			;WHATS A STRING?
eralin:	DB	ESC,'P','$'			;CLEAR SPACE
;CLRLIN:	DB	ESC,'K','$'			;CLEAR LINE
erascr:	DB	ESC,'E',ESC,'H','$'		;CLEAR SCREEN AND CURSOR HOME
curldn:	db	esc,'=','$',0			;cursor lead in
;SCRNP:		DB	ESC,'=',24H,25H,'$'		;SPOT FOR SCREEN PACKETS
;SCRNRT:	DB	ESC,'=',25H,25H,'$'		;SPOT FOR # OF RETRIES
;SCRFLN:	DB	ESC,'=',26H,25H,'$'		;SPOT FOR FILE NAME
;SCRST:		DB	ESC,'=',28H,25H,'$'		;SPOT FOR STATUS
;SCREND:	DB	ESC,'=',2AH,25H,'$'		;SPOT FOR PROMPT
;SCRERR:	DB	ESC,'=',2DH,25H,'$'		;SPOT FOR ERRORS
ttab:						;NO TRANSLATION TABLE
ta:	DB	ESC,'A',0,0			;CURSOR UP
tb:	DB	ESC,'B',0,0			;CURSOR DOWN
tc:	DB	ESC,'D',0,0			;CURSOR RIGHT
td:	DB	ESC,'C',0,0			;CURSOR LEFT
te:	DB	ESC,'E',0,0			;CLEAR SCREEN
tf:	DB	0,0,0,0				;WHAT???
tg:	DB	0,0,0,0				;WHAT???
th:	DB	ESC,'H',0,0			;CURSOR HOME
ti:	DB	ESC,'A',ESC,'C',0,0		;REVERSE LINEFEED??
tj:	DB	ESC,'J',0,0			;CLEAR TO END OF SCREEN
tk:	DB	ESC,'K',0,0			;CLEAR TO END OF LINE
ENDIF;SANYO

ovlend	equ	$	; End of overlay

	END















