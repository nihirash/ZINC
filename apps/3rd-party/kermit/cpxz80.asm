IF NOT LASM
.printx * CPXZ80.ASM *
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
;       This file contains the system-dependent code and data for
;	Kermit-80 emulated on an IBM PC or clone running Z80MU.
;
; revision history (last edit first)
;
; edit 1, 2 December, 1987.  Built code for Z80MU emulation.  Uses BIOS
;	calls to 0FF12-15 to read/write from/to the PC COM1 port.
;

.printx	* Assembling for Z80MU system *

;
;      Family is the string used in VERSION to say which of several 
;       smaller overlay files are used.  These are (will be) derived from 
;       the juge CP4SYS.ASM file, in which case we will never get here.  
;       Just a Dollar, but put a sting in for a family of machines.
;
family:	db	'CPXZ80.ASM  (1)  2-Dec-87$'    ; Used for family versions....



sysxin:		; continuation of system dependent initialisation code
	ret			; return from system-dependent routine
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

conmsg:		; Messages printed when entering transparent (CONNECT) mode:
;
;
;       syscls - system-dependent close routine
;       called when exiting transparent session.
;
syscls:
	ret
;
;       sysinh - help for system-dependent special functions.
;       called in response to <escape>?, after listing all the
;       system-independent escape sequences.
;
sysinh:
	ret

;
;       sysint - system dependent special functions
;       called when transparent escape character has been typed;
;       the second character of the sequence is in A (and in B).
;       returns:
;       non-skip: sequence has been processed
;       skip:   sequence was not recognized
sysint:	ani	137O		; convert lower case to upper, for testing...
	jmp	rskp		; take skip return - command not recognized.


;
;
;       sysflt - system-dependent filter
;       called with character in E.
;       if this character should not be printed, return with A = zero.
;       preserves bc, de, hl.
;       note: <xon>,<xoff>,<del>, and <nul> are always discarded.
sysflt:
	mov	a,e		; get character for testing
	ret

;       mdmflt - modem filter [30]
;       called with character to be sent to printer in E
;       with parity set as appropriate.
;       return with accumulator = 0 do do nothing,
;                               <> 0 to send char in E.
mdmflt:
	mov	a,e		;[30] get character to test
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
	mov	a,e		; [30] get character to test
	ret


;
; system-dependent processing for BYE command.
;  for apmmdm, heath, and lobo, hang up the phone.
sysbye:
	ret
;
;
;       This is the system-dependent command to change the baud rate.
;       DE contains the two-byte value from the baud rate table; this
;       value is also stored in 'speed'.
sysspd:
	ret
;
;
; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
spdtbl	EQU	0		;[hh] SET BAUD not supported.
sphtbl	EQU	0		;[hh] ran out of room above...
;
;
;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:
	ret

prttbl	equ	0		; SET PORT not supported
prhtbl	equ	0
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
selcon:
	ret
;

;       Get character from console, or return zero.
;       result is returned in A.  destroys bc, de, hl.
;
inpcon:
	mvi	c,dconio	;Direct console I/O BDOS call.
	mvi	e,0FFH		;Input.
	call	BDOS
	ret
;

;
;       Output character in E to the console.
;       destroys bc, de, hl
;
outcon:
	mov	c,e		;Console output via BIOS
	jmp	bcnout
;

;
;       outmdm - output a char from E to the modem.
;               the parity bit has been set as necessary.
;       returns nonskip; bc, de, hl preserved.
outmdm:
	mov	c,e		; get char to c
	call	0ff12h		; send to com1 via PC BIOS
	ret
;
;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
;Note: modem port should already be selected for mdI.  [Toad Hall]
	call	0ff15h		;Get the port status into A.
	ana	a		;See if the is non-null.
	ret			; return with character or NULL in A.


;
;       flsmdm - flush comm line.
;       Modem is selected.
;       Currently, just gets characters until none are available.

flsmdm:	call	inpmdm		; Try to get a character
	ora	a		; Got one?
	jnz	flsmdm		; If so, try for another
	ret			; Receiver is drained.  Return.
;

;
;       lptstat - get the printer status. Return a=0ffh if ok, or 0 if not.
lptstat:
	xra	a		; assume it is ok.. this may not be necessary
	ret

;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
	push	d		; save DE in either case
	call	prtflt		; go through printer filter [30]
	ana	a		; if A = 0 do nothing,
	jz	outlp1		; [30] if a=0 do nothing
	mvi	c,lstout
	call	bdos		;Char to printer
outlp1:	pop	d		; restore saved register pair
	ret

;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:
	mvi	e,bs		;get a backspace
	jmp	outcon

; erase the character at the current cursor position
clrspc:	mvi	e,' '
	call	outcon
	mvi	e,bs		;get a backspace
	jmp	outcon

; erase the current line
clrlin:	lxi	d,eralin
	jmp	prtstr

; erase the whole screen, and go home. preserves b (but not c)
clrtop:	lxi	d,erascr
	jmp	prtstr


sysver:	db	'Z80MU on IBM PC $'
IF lasm 
LINK CPXVDU.ASM
ENDIF   ;lasm - m80 will INCLUDE CPXVDU.ASM
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



