IF NOT lasm
.printx * CPXPRO.ASM *
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
; revision history:
;
;edit 2, 16-Oct-1990 by MF.  Reformatted speed tables according to
;	current usage and reworked sysspd routine accordingly.
;	Also eliminated cursor-positioning routines as we now link to
;	cpxvdu.asm.  Reworked version message according to current usage.
;edit 1, 17 November, 1987, by OBSchou.  Extracted Compupro code
;	from CPMPRO.ASM	and massaged fort CP/M kermit V4.09
;
; Modifications to KERMIT-80 for use with Compupro Interfacer 3/4 "[gv]"
;
; Guy Valiquette, M.D.
; Black Bldg. Rm 322
; Dept. of Neurology
; College of Physicians & Surgeons
; Columbia University
; 630 W. 168th Street
; New York, NY 10032
; (212) 694-3965
;
; I/O routines for Interfacer 3/4 board
; Allow sending break with <ESC> B while CONNECTed
; Terminal control sequences for Wyse Technology WY-100
; Add calls to "hangup" subroutine in EXIT and BYE to hang-up phone if
;	using a smart modem by disabling UART (and withdrawing DTR signal)
;
;
; Using KERMIT with Compupro Interfacer 3/4:
;	- Set compro below to TRUE, all other to FALSE
;	- Select the ABSOLUTE USER number you want with the user EQUate
;	- Select the terminal control string set needed (or write your
;	  own if not there)
;	- Note that I had to use a kludge to get the signon message right.
;	  Code in KERMIT as I found it did not, nor could it, work.  Search
;	  for the section of code under:  IF compro AND wy100  and imitate.
;	- If you have a smart modem, CONNECT puts you in contact with your
;	  modem.  Use your usual "wake-up" character sequence to dial out.
;	  You can CONNECT and return to KERMIT repeateadly without hanging up
;	  UNLESS you change the baud rate, execute the BYE command or EXIT.
;	- Baud rate set up in code to use 1200 baud as default. Can easily
;	  be changed to 300 (or whatever). The byte defined at label "baudrt"
;	  is the mode register 2 used to initialize the UART on first CONNECT.
;	  The low order nibble of this byte is the baud rate.  Refer to the
;	  Compupro manual to set whatever default baud rate desired by changing
;	  this low nibble at  baudrt db 0011$xxxxb.
;
; Note: "Wrapup" work (outlined below) to clean up code not done since
;	new version of KERMIT is due out in a few weeks (says fdc)
; 
; WRAPUP:
;	- outchri modification done for IF inout ONLY
;	- stchr routine implemented for IF inout ONLY
;	  and used by outchr only
;
;
; Keep module name, edit number, and last revision date in memory.
family: db      'CPXPRO.ASM (2)  16-Oct-1990 $'
;
; Assembly time message to let me know I'm building the right version.
; LASM generates an 'S' error along with the message, which is messy, but
; better than trying to put everything inside a IF m80 OR mac80 conditional,
; because LASM doesn't like nested IF's, either.

IF compro
.printx * Assembling Kermit-80 for Compupro Interfacer 4 (or 3) *
ENDIF

iobyte  EQU     03H     ;Location of I/O byte

IF compro
if4	EQU	10H		;standard base address of Interfacer 4/3 board
datap	EQU	if4+0		;data port (read/write)
stat	EQU	if4+1		;status port (read/write)
mode	EQU	if4+2		;mode registers (read/write)
command	EQU	if4+3		;command register (read/write)
txint	EQU	if4+4		;transmit interrupts status/mask (read/write)
rxint	EQU	if4+5		;receive interrupts status/mask (read/write)
;		if4+6		 not used
usersel	EQU	if4+7		;absolute user number select register
output	EQU	1
input	EQU	2
; Note: tested with CP/M Ver2.2, and Racal-Vadic Auto Dial VA212 modem
;	and USRobotics Password modems. [gv]
user	EQU	7		;ABSOLUTE user number on IF4 or IF3
; Also remember to select a terminal!!!
ENDIF;compro
;

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

	db	cr,lf,'D - drop the line'
	db	cr,lf,'B - send a break'
	db	cr,lf
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

	cpi	'D'		;Disconnect modem?
	jnz	intc00		;no
hangup:	xra	a		;get a null byte
	out	command		;disable UART
	sta	ckdialf		;pull down flag to reinitialize UART
	ret			;most smart modems will hang up on loosing DTR
intc00:
	cpi	'B'		; Send a reak?
	jz	sendbr
        ret


;send a break
sendbr:	mvi	a,user		;select our UART
	di			;quiet
	out	usersel		;select it
	in	command		;get current command byte
	ori	00001000b	;set "send break" bit
	out	command		;send to UART
	ei

		;now for 300 msec timing loop (at 4 MHz, 0 wait state)
	mvi	a,30		;[obs] call delay for 300 ms
	call	delay

	mvi	a,user		;now, go back to UART
	di			;quiet
	out 	usersel
	in	command		;get current command
	ani	11110111b	;reset "send break" bit
	ori	00010000b	;and set "reset errors" command bit (in case)
	out	command		;send back to UART
	ei
	jmp	rskp


ckdial:
	lda	ckdialf		;check flag that forces reinitialization
	ora	a		;test it
	jz	ckdial0		;must redo it
	mvi	a,user		;user number
	di
	out	usersel		;select it
	in	command		;get current command register
	ei
	ani	00000111b	;mask for normal operating mode
				;(DTR on, RX and TX both enabled)
	cpi	00000111b	;is it?
	jz	rskp		;UART is on, start terminal emulation
; else initialize UART...
ckdial0:di
	mvi	a,user		;select user
	out	usersel
	mvi	a,0001$0000b	;reset errors command
	out	command		;send to command register
	out	command
	out	command		;...make sure it got it
	in	command		;confirm
	lda	moderg1		;get mode register 1
	out	mode		;send it
	lda	moderg2		;get mode register 2
	out	mode		;send it
	mvi	a,0011$0111b	;command register to start things
	out	command		;send it
	ei			;turn interrupts back on
	mvi	a,0ffh		;get a non-zero byte
	sta	ckdialf		;pull down flag
;
	jmp	rskp		;start terminal emulation


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

	call	hangup
        ret
;
;       This is the system-dependent command to change the baud rate.
;       DE contains the two-byte value from the baud rate table; this
;       value is also stored in 'speed'.
sysspd:


IF compro
	lda	speed		;[MF]Get requested baud-rate
        mov     b,a             ;Save the number.
	lxi	h,baudrt	;point to current baud rate
	mov	a,m		;get it
	ani	0f0h		;keep high nibble
	ora	b		;merge back baud rate
	mov	m,a		;store back
	xra	a		;clear A
	sta	ckdialf		;put up flag to force reinitialization
	ret			;...at next connect

ENDIF;compro


;

;       Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.

;       db      string length,string,divisor (2 identical bytes or 1 word)
; [Toad Hall]

spdtbl:	db	8		;[MF]8 entries in speed table
	db	3,'110$'
	db	02h,02h		;[MF]110 baud
	db	4,'1200$'
	db	07h,07h		;[MF]1200 baud
	db	5,'134.5$'
	db	03h,03h		;[MF]134.5 baud
	db	3,'150$'
	db	04h,04h		;[MF]150 baud
	db	4,'1800$'
	db	08h,08h		;[MF]1800 baud
	db	5,'19200$'
	db	0fh,0fh		;[MF]19200 baud
	db	4,'2000$'
	db	09h,09h		;[MF]2000 baud
	db	4,'2400$'
	db	0ah,0ah		;[MF]2400 baud
	db	3,'300$'
	db	05h,05h		;[MF]300 baud
	db	4,'3600$'
	db	0bh,0bh		;[MF]3600 baud
	db	4,'4800$'
	db	0ch,0ch		;[MF]4800 baud
	db	2,'50$'
	db	00h,00h		;[MF]50 baud
	db	3,'600$'
	db	06h,06h		;[MF]600 baud
	db	4,'7200$'
	db	0dh,0dh		;[MF]7200 baud
	db	2,'75$'
	db	01h,01h		;[MF]75 baud
	db	4,'9600$'
	db	0eh,0eh		;[MF]9600 baud

sphtbl:	db	cr,lf,'50  75  110  134   150  300  600  1200'
	db	cr,lf,'1800  2000  2400  3600  4800  7200  9600  19200$'

ckdialf:db	0			;force UART initialization on entry
baudrt:	db	0011$0111b	;default baud rate: 1200 baud
moderg1:db	0100$1110b	;default mode register 1:
				; -asynch, 8 data bits, 1 stop bit,
				; -parity odd, disabled
moderg2	EQU	baudrt
ENDIF;compro
;

;
; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:
        ret
;
;
;	Port table not applicable
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
;************************System Dependent****************************
;
; Addition by [gv], 16/7/84
;	Return the status of the modem port:
;		Z flag set if NO input available
;		C flag set in NOT output ready
;	Destroys A and flags, preserves all other registers
;
stchr:
	di
	mvi	a,user
	out	usersel
	in	stat
	ani	output
	in	stat
	ei
	jz	outmdm		;not output ready, try again
; else...
	di			;no interrupts
	mvi	a,user
	out	usersel
	mov	a,e		;get back character
	out	datap
	ei
	ret

;

;
;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
;
	di
	mvi	a,user
	out	usersel
	in	stat
	ei
	ani	input		;test for input status (C flag reset by ANI n)
	rz			; no input available
;
;************************System Dependent****************************
;
; Addition by [gv], 16/7/84
;	get a character "raw" (i.e. just get it in A)
;
; Note: MUST have character ready before call, use stchr
	mvi	a,user
	di
	out	usersel
	in	datap
	ei
	ret
;
;

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



IF inout
prtout:
ENDIF ;inout
IF compro AND inout
	di
	mvi	a,user
	out	usersel
	in	stat
	ei
ENDIF;compro AND inout
IF (NOT compro) AND inout
        in      mnprts          ;Get the output ready flag.
ENDIF;(NOT compro) AND inout
IF inout
        ani     output          ;Is it set?
        jz      prtout          ;If so, loop until it isn't.
ENDIF ;inout
IF compro AND inout
	di
	mvi	a,user
	out	usersel
	mov	a,e
	out	datap
	ei
ENDIF;compro AND inout
IF (NOT compro) AND inout
        mov     a,e             ;Get the char to output.
prtou2: out     mnport          ;Output it.
ENDIF;(NOT compro) AND inout
        ret


;

;
;       Screen manipulation routines
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


IF compro; [gv]
sysver:	db	'[Compupro IF4-',user+'0',']$'
ENDIF;compro

IF lasm
LINK	CPXVDU.ASM
ENDIF ;lasm
