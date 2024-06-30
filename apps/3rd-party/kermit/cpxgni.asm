; CPXGNI.ASM
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
;       This file contains the system-dependent code and data for various
;       Genie 3  CPM kermit 
;
; This has the Family name of CPXGNI.ASM.
;
; revision history (last edit first)
; edit 3: 27 October, a987 by OBSchou.  Massaged file to suit V4.09 structure.
;
; Edit 2: Aug 27 1987 GDS Put in code for BREAK and fillited out
;         a lot of unnecessary IF's
;
;Edit 1: Nov. 28, 1986 Geof Smith Clinical Research centre Harrow UK.

.printx * Assembling for Eaca Genie 3 *
;
drtime  EQU     05H     ;Default receive time out interval.
;
; the basics...
;
mnport EQU 0E8H
mnprts EQU 0EDH
output EQU 20H
input  EQU 01H
lctrl  EQU 0EBH
divlsb EQU 0E8H
divmsb EQU 0E9H
z80    EQU TRUE
brkval EQU 40H

defesc EQU ']'-100O ;The default escape character.


;Select initial setting for VT-52 emulation flag.

; default to VT52-EMULATION ON.
;
vtval   EQU     1
;
;

;	Family is the string used in VERSION to say which of several 
;       smaller overlay files are used.  These are (will be) derived from 
;       the huge CP4SYS.ASM file, in which case we will never get here.  
;       Just a Dollar, but put a sting in for a family of machines.
;
family:db      'CPXGNI.ASM  (3)  27-Oct-87$'    ; Used for family versions....



;
;       System-dependent initialization
;       Called once at program start.
sysxin:
;
			;Set up 9600 bd, 8bit words, no parity 1stop bit

	mvi	a,83H		;enable DLAB by setting bit 7
	out	lctrl   	;and outputting to control port
	mvi	a,14H		;get word = 20 decimal
	out	divlsb		;and put it out
	mvi	a,00H		;as two separate
	out	divmsb		;bytes
	lda	pstore		;get parity etc
	out	lctrl		;do it resetting DLAB at same time

	ret			; return from system-dependent routine


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

conmsg:         ; Messages printed when entering transparent (CONNECT) mode:
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
        lxi     d,inhlps        ; we got options...
        call    prtstr          ; print them.
        ret


;additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:

        db      cr,lf,'B  Transmit a BREAK'

        db      '$'                     ;[hh] table terminator

;
;       sysint - system dependent special functions
;       called when transparent escape character has been typed;
;       the second character of the sequence is in A (and in B).
;       returns:
;       non-skip: sequence has been processed
;       skip:   sequence was not recognized
sysint: ani     137O            ; convert lower case to upper, for testing...
        cpi     'B'             ; send break?
        jz      sendbr          ; yes, go do it.  return nonskip when through.

        jmp     rskp            ; take skip return - command not recognized.


;-------------------------------------------------------------------------------
sendbr:
;
;       Ensure that the transmitter has finished sending buffered chars
sndbr1: in      mnprts          ; get UART status
        ani     output         ; everything sent?
        jz      sndbr1          ; no, wait a bit more
;
;       Begin sending a break by setting bit in UART command register
        mvi     a,brkval           ;  SBreak, 
        out     lctrl
;
;       Wait for 250 milliseconds (using hundredths second delay routine)
        mvi     a,25
        call    delay
;
;       Resume normal operation by clearing the SendBreak command bit
        lda pstore                  ;and restoring value from parity store
        out mnprts
;
        ret                     ;done

;
;

;
;       sysflt - system-dependent filter
;       called with character in E.
;       if this character should not be printed, return with A = zero.
;       preserves bc, de, hl.
;       note: <xon>,<xoff>,<del>, and <nul> are always discarded.
sysflt:
        mov     a,e             ; get character for testing
        ret

;       mdmflt - modem filter [30]
;       called with character to be sent to modem in E
;       with parity set as appropriate.
;       return with accumulator = 0 do do nothing,
;                               <> 0 to send char in E.
mdmflt:	mov	a,e		; get character to a
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

			;Set up baud rate 8bit words, no parity 1stop bit
     mvi a,83H     ;enable DLAB by setting bit 7
     out lctrl     ;and outputting to control port
     mov a,d         ;get LSB
     out divlsb     ;and put it out
     mov a,e       ;get MSB
     out divmsb     ;output it as well
     lda pstore     ;get parity etc
     out lctrl     ;do it resetting DLAB at same time
     ret

pstore:     db 03H  ;Default value for parity word length and stop bits

spdtbl: db    11h               ;17 entries
     db     03h,'110$',     06H,0D1H
     db     04h,'1200$',     00H,0A0H
     db     05h,'134.5$',     05H,94H
     db     03h,'150$',     05H,00H
     db     04h,'1800$',     00H,6BH
     db     05h,'19200$',     00H,0AH
     db     04h,'2000$',     00H,60H
     db     04h,'2400$',     00H,50H
     db     03h,'300$',     02H,80H
     db     04h,'3600$',     00H,35H
     db     05h,'38400$',    00H,05H
     db     04h,'4800$',     00H,28H
     db     02h,'50$',     0FH,00H
     db     03h,'600$',     01H,40H
     db     04h,'7200$',     00H,1BH
     db     02h,'75$',     0AH,00H
     db     04h,'9600$',     00H,14H

sphtbl: db     cr,lf,'   50      75    110    134.5  150    300    600   1200'
     db     cr,lf,' 1800   2000   2400   3600   4800   7200   9600  19200  38400$'

;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:

        ret
;
prttbl  equ     0               ; SET PORT not supported
prhtbl  equ     0

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

        in      mnprts          ;Get the output done flag.
        ani     output          ;Is it set?
        jz      outmdm          ;If not, loop until it is.
        mov     a,e
        out     mnport          ;Output it.
        ret

;--------------------------------------------------------------------------
;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
;Note: modem port should already be selected for mdI.  [Toad Hall]
        in      mnprts          ;Get the port status into A.
        ani     input           ;See if the input ready bit is on.
        rz                      ;If not then return.
        in      mnport          ;If so, get the char.
        ret                     ; return with character in A


;
;       flsmdm - flush comm line.
;       Modem is selected.
;       Currently, just gets characters until none are available.

flsmdm: call    inpmdm          ; Try to get a character
        ora     a               ; Got one?
        jnz     flsmdm          ; If so, try for another
        ret                     ; Receiver is drained.  Return.
;-----------------------------------------------------------------------------
;
;       lptstat - get the printer status. Return a=0 if ok, or 0ffh if not.
lptstat:
        xra     a               ; assume it is ok.. this may not be necessary
        ret

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
;------------------------------------------------------------------------------
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

;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:

        mvi     e,bs            ;get a backspace
        jmp     outcon

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

;[2] I see no real saving in having all screens in separate file and
;therefore have included screen definition here and commented out
;the link to VDU file
;
;Specific definitions for the Genie III screen
;
sysver: db 'Eaca Genie III$'
outlin: db 1aH,cr,lf,'            $'
erascr: db 1AH,'$'
eralin: db cr,18H,'$'
curldn: db esc,'=$'
ttab:
ta:     db 0BH,'$',0,0                    ;Cursor up
tb:     db 0AH,'$',0,0                    ;Cursor down
tc:     db 0CH,'$',0,0                    ;Cursor right
td:     db 08H,'$',0,0                    ;Cursor left
te:     db 1AH,'$',0,0                    ;Clear display
tf:     db esc,'R$',0                    ;Reverse on
tg:     db esc,'S$',0                    ;Reverse off
th:     db 1EH,'$',0,0                    ;Cursor home
ti:     db 0BH,'$',0,0                    ;Reverse linefeed
tj:     db 19H,'$',0,0                    ;Clear to end of screen
tk:     db 18H,'$',0,0                    ;Clear to end of line

ovlend equ $           ;End of overlay

END





